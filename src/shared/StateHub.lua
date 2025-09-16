-- ReplicatedStorage/SharedModules/StateHub.lua
-- サーバ専用：プレイヤー状態を一元管理し、Remotes経由でクライアントへ送信する
-- P0-11: StatePush の payload に goal:number を追加（UI側の文字列パース依存を排除）

local RS = game:GetService("ReplicatedStorage")

-- 依存モジュール
local Scoring     = require(RS:WaitForChild("SharedModules"):WaitForChild("Scoring"))
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil")) -- ★追加

local StateHub = {}

--========================
-- 内部状態（Server専用）
--========================
type PlrState = {
	deck: {any}?,
	hand: {any}?,
	board: {any}?,
	taken: {any}?,
	dump: {any}?,

	season: number?,        -- 1=春, 2=夏, 3=秋, 4=冬
	handsLeft: number?,
	rerollsLeft: number?,

	seasonSum: number?,     -- 今季の合計(表示用)
	chainCount: number?,    -- 連続役数
	mult: number?,          -- 表示用倍率

	bank: number?,          -- 両（周回通貨）
	mon: number?,           -- 文（季節通貨）

	phase: string?,         -- "play" / "shop" / "result"(冬後)
	year: number?,          -- 周回年数（25年進行で+25）
	homeReturns: number?,   -- 「ホームへ戻る」回数（アンロック条件用）

	lang: string?,          -- ★任意：言語（"ja"/"en"）
	lastScore: any?,        -- 任意：デバッグ/結果表示

	run: any?,              -- RunDeckUtil が内部で利用（meta/matsuriLevels 等）
}

local stateByPlr : {[Player]: PlrState} = {}

--========================
-- 季節/目標/倍率
--========================
local SEASON_NAMES = { [1]="春", [2]="夏", [3]="秋", [4]="冬" }
local MULT   = {1, 2, 4, 8} -- 春→夏→秋→冬の目標倍率
local X_BASE = 1            -- 目標の基準値

local Remotes : {
	StatePush: RemoteEvent?,
	ScorePush: RemoteEvent?,
	HandPush:  RemoteEvent?,
	FieldPush: RemoteEvent?,
	TakenPush: RemoteEvent?,
} | nil = nil

local function targetForSeason(season:number?): number
	local idx = tonumber(season) or 1
	return (MULT[idx] or MULT[#MULT]) * X_BASE
end

local function seasonName(n:number?): string
	return SEASON_NAMES[tonumber(n) or 0] or "?"
end

local function chainMult(n: number?): number
	local x = tonumber(n) or 0
	if x <= 1 then return 1.0
	elseif x == 2 then return 1.5
	elseif x == 3 then return 2.0
	else return 3.0 + (x - 4) * 0.5
	end
end

--========================
-- 初期化（Remotes 注入）
--========================
function StateHub.init(remotesTable:any)
	Remotes = remotesTable
end

--========================
-- 基本API
--========================
function StateHub.get(plr: Player): PlrState?
	return stateByPlr[plr]
end

function StateHub.set(plr: Player, s: PlrState)
	stateByPlr[plr] = s
end

function StateHub.clear(plr: Player)
	stateByPlr[plr] = nil
end

--（任意）存在チェック／デバッグ用
function StateHub.exists(plr: Player): boolean
	return stateByPlr[plr] ~= nil
end

-- サーバ内ユーティリティ：欠損プロパティの安全な既定値
local function ensureDefaults(s: PlrState)
	s.season      = s.season or 1
	s.handsLeft   = s.handsLeft or 0
	s.rerollsLeft = s.rerollsLeft or 0
	s.seasonSum   = s.seasonSum or 0
	s.chainCount  = s.chainCount or 0
	s.mult        = s.mult or 1.0
	s.bank        = s.bank or 0
	s.mon         = s.mon or 0
	s.phase       = s.phase or "play"
	s.year        = s.year or 1
	s.homeReturns = s.homeReturns or 0
	s.deck        = s.deck or {}
	s.hand        = s.hand or {}
	s.board       = s.board or {}
	s.taken       = s.taken or {}
	-- lang / run は任意
end

--========================
-- クライアント送信（状態/得点/札）
--========================
function StateHub.pushState(plr: Player)
	if not Remotes then return end
	local s = stateByPlr[plr]; if not s then return end
	ensureDefaults(s)

	-- サマリー算出（Scoring は state（=s）内の祭事レベルも参照可能）
	local takenCards = s.taken or {}
	local total, roles, detail = Scoring.evaluate(takenCards, s) -- detail={mon,pts}

	-- 祭事レベル（UI用にフラットで同梱）
	local matsuriLevels = RunDeckUtil.getMatsuriLevels(s) or {} -- ★追加

	-- 状態（HUD/UI用）
	if Remotes.StatePush then
		local goalVal = targetForSeason(s.season) -- ★P0-11: 数値ゴールを一度だけ算出
		Remotes.StatePush:FireClient(plr, {
			-- 基本
			season      = s.season,
			seasonStr   = seasonName(s.season),       -- 仕様に沿って季節名も送る
			target      = goalVal,                    -- 既存フィールド（互換維持）
			goal        = goalVal,                    -- ★追加：UIが直接参照する数値ゴール

			-- 残り系
			hands       = s.handsLeft or 0,
			rerolls     = s.rerollsLeft or 0,

			-- 経済/表示
			sum         = s.seasonSum or 0,
			mult        = s.mult or 1.0,
			bank        = s.bank or 0,
			mon         = s.mon or 0,

			-- 進行/年数
			phase       = s.phase or "play",
			year        = s.year or 1,
			homeReturns = s.homeReturns or 0,

			-- 言語（UIで利用）
			lang        = s.lang,                     -- ★任意

			-- 祭事レベル（YakuPanel 等のUIで利用）
			matsuri     = matsuriLevels,              -- ★追加（{ [fid]=lv }）

			-- 山/手の残枚数（UIの安全表示用）
			deckLeft    = #(s.deck or {}),
			handLeft    = #(s.hand or {}),
		})
	end

	-- スコア（リスト/直近役表示）
	if Remotes.ScorePush then
		print("[StateHub] ScorePush types:", typeof(total), typeof(roles), typeof(detail))
		Remotes.ScorePush:FireClient(plr, total, roles, detail) -- detail={mon,pts}
	end

	-- 札（手/場/取り）
	if Remotes.HandPush  then Remotes.HandPush:FireClient(plr, s.hand  or {}) end
	if Remotes.FieldPush then Remotes.FieldPush:FireClient(plr, s.board or {}) end
	if Remotes.TakenPush then Remotes.TakenPush:FireClient(plr, s.taken or {}) end
end

--========================
-- 共有ユーティリティ（他モジュールから利用）
--========================
StateHub.targetForSeason = targetForSeason
StateHub.seasonName      = seasonName
StateHub.chainMult       = chainMult

return StateHub
