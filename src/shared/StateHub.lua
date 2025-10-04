-- ReplicatedStorage/SharedModules/StateHub.lua
-- サーバ専用：プレイヤー状態を一元管理し、Remotes経由でクライアントへ送信する
-- 12-month版：StatePushは month/goal を正とし、season/seasonStr は送信しない
-- ★ Reroll 統一（SSOT）：rerollFieldLeft / rerollHandLeft を唯一の真実とする
--    旧フィールド（handsLeft / rerollsLeft）には一切依存しない・送らない

local RS = game:GetService("ReplicatedStorage")

local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("StateHub")

local Scoring     = require(RS:WaitForChild("SharedModules"):WaitForChild("Scoring"))
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))

-- Balance は存在しない環境でも動作するようフォールバック
local Balance do
	local ok, mod = pcall(function()
		return require(RS:WaitForChild("Config"):WaitForChild("Balance"))
	end)
	Balance = ok and mod or {
		STAGE_START_MONTH = 1,
		getGoalForMonth = function(_) return 1 end,
	}
end

local StateHub = {}

--========================
-- 内部状態（Server専用）
--========================
export type PlrState = {
	deck: {any}?, hand: {any}?, board: {any}?, taken: {any}?, dump: {any}?,

	-- ▼ 新：場/手で明確に分離（唯一の真実）
	rerollFieldLeft: number?,    -- 全体/場リロール残数（正）
	rerollHandLeft:  number?,    -- 手札リロール残数（正）

	seasonSum: number?,  -- UI表示用の合計
	chainCount: number?, -- 連続役数（倍率表示用）
	mult: number?,       -- 表示用倍率

	bank: number?,       -- 両（周回通貨）
	mon: number?,        -- 文（季節通貨）

	phase: string?,      -- "play" / "shop" / "result" / "home"
	year: number?,       -- 周回年数
	homeReturns: number?,-- 「ホームへ戻る」回数

	lang: string?,       -- "ja"/"en"
	lastScore: any?,     -- 任意デバッグ

	run: any?,           -- { month=number, reroll={field,hand}, talisman=?, ... }
	goal: number?,       -- 月ごとの目標（数値）
}

local stateByPlr : {[Player]: PlrState} = {}

--========================
-- Remotes（Server→Client）
--========================
local Remotes : {
	StatePush: RemoteEvent?, ScorePush: RemoteEvent?,
	HandPush:  RemoteEvent?, FieldPush: RemoteEvent?, TakenPush: RemoteEvent?,
} | nil = nil

--========================
-- 共通ユーティリティ
--========================
local function chainMult(n: number?): number
	local x = tonumber(n) or 0
	if x <= 1 then return 1.0
	elseif x == 2 then return 1.5
	elseif x == 3 then return 2.0
	else return 3.0 + (x - 4) * 0.5
	end
end

local function monthName(n:number?): string
	local m = tonumber(n) or 0
	if m < 1 then m = 1 end
	if m > 12 then m = 12 end
	return tostring(m) .. "月"
end

local function goalForMonth(s: PlrState): number
	local m = (s.run and s.run.month) or Balance.STAGE_START_MONTH or 1
	if s.goal and type(s.goal)=="number" then return s.goal end
	if Balance.getGoalForMonth then
		return Balance.getGoalForMonth(m)
	end
	if Balance.GOAL_BY_MONTH then
		return Balance.GOAL_BY_MONTH[m] or Balance.GOAL_BY_MONTH[1] or 1
	end
	return 1
end

--========================
-- 初期化（Remotes 注入）
--========================
function StateHub.init(remotesTable:any)
	Remotes = remotesTable
	LOG.info("initialized | remotes: State=%s Score=%s Hand=%s Field=%s Taken=%s",
		Remotes and tostring(Remotes.StatePush ~= nil) or "nil",
		Remotes and tostring(Remotes.ScorePush ~= nil) or "nil",
		Remotes and tostring(Remotes.HandPush  ~= nil) or "nil",
		Remotes and tostring(Remotes.FieldPush ~= nil) or "nil",
		Remotes and tostring(Remotes.TakenPush ~= nil) or "nil"
	)
end

--========================
-- 基本API
--========================
function StateHub.get(plr: Player): PlrState? return stateByPlr[plr] end
function StateHub.set(plr: Player, s: PlrState) stateByPlr[plr] = s end
function StateHub.clear(plr: Player) stateByPlr[plr] = nil end
function StateHub.exists(plr: Player): boolean return stateByPlr[plr] ~= nil end

--========================================
-- リロール補完：run.reroll から新フィールドを復元
--========================================
local function ensureRerollFields(s: PlrState)
	-- run.reroll から補完（SSOTを守る：旧 handsLeft/rerollsLeft には触れない）
	if s.run and typeof(s.run.reroll)=="table" then
		local rr = s.run.reroll
		if s.rerollFieldLeft == nil and type(rr.field)=="number" then
			s.rerollFieldLeft = rr.field
		end
		if s.rerollHandLeft == nil and type(rr.hand)=="number" then
			s.rerollHandLeft = rr.hand
		end
	end

	-- 既定値（0 クランプ）
	s.rerollFieldLeft = tonumber(s.rerollFieldLeft or 0) or 0
	s.rerollHandLeft  = tonumber(s.rerollHandLeft  or 0) or 0

	-- run.reroll にも正の数値を反映（保存系がこちらを読む想定）
	s.run = s.run or {}
	s.run.reroll = s.run.reroll or {}
	s.run.reroll.field = s.rerollFieldLeft
	s.run.reroll.hand  = s.rerollHandLeft
end

-- サーバ内ユーティリティ：欠損プロパティの安全な既定値
local function ensureDefaults(s: PlrState)
	-- リロール（SSOT）を最初に整える
	ensureRerollFields(s)

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
	s.run         = s.run or {}
	s.run.month   = s.run.month or Balance.STAGE_START_MONTH or 1
	-- goal は getGoalForMonth を優先（Balance 側で月別設定を吸収）
	s.goal        = s.goal or goalForMonth(s)
end

local function safeLen(t:any) return (typeof(t) == "table") and #t or 0 end

--========================
-- クライアント送信（状態/得点/札）
--========================
function StateHub.pushState(plr: Player)
	local tAll0 = os.clock()
	if not Remotes then
		LOG.warn("pushState: Remotes table missing (skip) | u=%s", plr and plr.Name or "?")
		return
	end
	local s = stateByPlr[plr]
	if not s then
		LOG.warn("pushState: state missing (skip) | u=%s", plr and plr.Name or "?")
		return
	end

	ensureDefaults(s)

	local deckN  = safeLen(s.deck)
	local handN  = safeLen(s.hand)
	local boardN = safeLen(s.board)
	local takenN = safeLen(s.taken)

	local m = (s.run and s.run.month) or Balance.STAGE_START_MONTH or 1
	local g = goalForMonth(s)

	LOG.info("pushState.begin u=%s phase=%s month=%d goal=%s deck=%d hand=%d board=%d taken=%d mon=%s bank=%s",
		plr and plr.Name or "?", tostring(s.phase), m, tostring(g),
		deckN, handN, boardN, takenN, tostring(s.mon), tostring(s.bank)
	)

	-- サマリー算出（例外安全）
	local score_t0 = os.clock()
	local okScore, total, roles, detail = pcall(function()
		local takenCards = s.taken or {}
		return Scoring.evaluate(takenCards, s) -- detail={mon,pts}
	end)
	local score_ms = (os.clock() - score_t0) * 1000.0
	if not okScore then
		LOG.warn("pushState: Scoring.evaluate threw: %s", tostring(total))
		total, roles, detail = 0, {}, { mon = s.mon or 0, pts = 0 }
	else
		LOG.debug("ScorePush types: %s %s %s (in %.2fms)", typeof(total), typeof(roles), typeof(detail), score_ms)
	end

	-- 祭事レベル（UI用）
	local mats_t0 = os.clock()
	local okM, matsuriLevels = pcall(function()
		return RunDeckUtil.getMatsuriLevels(s) or {}
	end)
	local mats_ms = (os.clock() - mats_t0) * 1000.0
	if not okM then
		LOG.warn("pushState: RunDeckUtil.getMatsuriLevels threw: %s", tostring(matsuriLevels))
		matsuriLevels = {}
	end

	--========================
	-- 状態（HUD/UI用）
	--========================
	if Remotes.StatePush then
		local t0 = os.clock()
		local okSend, err = pcall(function()
			Remotes.StatePush:FireClient(plr, {
				-- ★ 送るのは month/goal が正。season は送らない。
				month       = m,
				monthStr    = monthName(m),
				goal        = g,
				target      = g, -- 旧互換が必要なら同値を置く（UI側で未使用なら無視）

				-- ▼ 残り系（SSOT：新キーのみ）
				rerollFieldLeft = s.rerollFieldLeft or 0,
				rerollHandLeft  = s.rerollHandLeft  or 0,

				sum         = s.seasonSum or 0,
				mult        = s.mult or 1.0,
				bank        = s.bank or 0,
				mon         = s.mon or 0,

				-- 進行/年数
				phase       = s.phase or "play",
				year        = s.year or 1,
				homeReturns = s.homeReturns or 0,

				lang        = s.lang,
				matsuri     = matsuriLevels,

				-- Run 側のスナップショット（護符ボード等のUI用）
				run         = {
					talisman = (s.run and s.run.talisman) or nil,
					reroll   = {
						field = s.rerollFieldLeft or 0,
						hand  = s.rerollHandLeft  or 0,
					},
				},

				-- 山/手の残枚数（UIの安全表示用）
				deckLeft    = deckN,
				handLeft    = handN,
			})
		end)
		local ms = (os.clock() - t0) * 1000.0
		if okSend then
			LOG.info("pushState.StatePush u=%s month=%d goal=%s phase=%s sent in %.2fms (mats#=%d)",
				plr and plr.Name or "?", m, tostring(g), tostring(s.phase),
				ms, (typeof(matsuriLevels)=="table" and #matsuriLevels or -1)
			)
		else
			LOG.warn("pushState.StatePush send failed u=%s err=%s", plr and plr.Name or "?", tostring(err))
		end
	else
		LOG.warn("pushState: StatePush remote missing")
	end

	--========================
	-- スコア（リスト/直近役表示）
	--========================
	if Remotes.ScorePush then
		local t0 = os.clock()
		local okSend, err = pcall(function()
			Remotes.ScorePush:FireClient(plr, total, roles, detail) -- detail={mon,pts}
		end)
		local ms = (os.clock() - t0) * 1000.0
		if okSend then
			LOG.debug("pushState.ScorePush u=%s in %.2fms (score=%s, pts=%s, mon=%s)",
				plr and plr.Name or "?", ms,
				tostring(total),
				(detail and tostring(detail.pts) or "?"),
				(detail and tostring(detail.mon) or "?")
			)
		else
			LOG.warn("pushState.ScorePush send failed u=%s err=%s", plr and plr.Name or "?", tostring(err))
		end
	else
		LOG.warn("pushState: ScorePush remote missing")
	end

	--========================
	-- 札（手/場/取り）— 各送信を個別計測
	--========================
	if Remotes.HandPush then
		local t0 = os.clock()
		local okSend, err = pcall(function() Remotes.HandPush:FireClient(plr, s.hand or {}) end)
		local ms = (os.clock() - t0) * 1000.0
		if okSend then
			LOG.debug("pushState.HandPush u=%s hand=%d in %.2fms", plr and plr.Name or "?", handN, ms)
		else
			LOG.warn("pushState.HandPush send failed u=%s err=%s", plr and plr.Name or "?", tostring(err))
		end
	else
		LOG.warn("pushState: HandPush remote missing")
	end

	if Remotes.FieldPush then
		local t0 = os.clock()
		local okSend, err = pcall(function() Remotes.FieldPush:FireClient(plr, s.board or {}) end)
		local ms = (os.clock() - t0) * 1000.0
		if okSend then
			LOG.debug("pushState.FieldPush u=%s board=%d in %.2fms", plr and plr.Name or "?", boardN, ms)
		else
			LOG.warn("pushState.FieldPush send failed u=%s err=%s", plr and plr.Name or "?", tostring(err))
		end
	else
		LOG.warn("pushState: FieldPush remote missing")
	end

	if Remotes.TakenPush then
		local t0 = os.clock()
		local okSend, err = pcall(function() Remotes.TakenPush:FireClient(plr, s.taken or {}) end)
		local ms = (os.clock() - t0) * 1000.0
		if okSend then
			LOG.debug("pushState.TakenPush u=%s taken=%d in %.2fms", plr and plr.Name or "?", takenN, ms)
		else
			LOG.warn("pushState.TakenPush send failed u=%s err=%s", plr and plr.Name or "?", tostring(err))
		end
	else
		LOG.warn("pushState: TakenPush remote missing")
	end

	LOG.info("pushState.end   u=%s in %.2fms | score(ms)=%.2f mats(ms)=%.2f",
		plr and plr.Name or "?", (os.clock()-tAll0)*1000.0, score_ms, mats_ms
	)
end

--========================
-- 共有ユーティリティ（他モジュールから利用）
--========================
StateHub.chainMult    = chainMult
StateHub.goalForMonth = function(s) return goalForMonth(s) end

return StateHub
