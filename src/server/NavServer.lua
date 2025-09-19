-- v0.9.7 P1-3 Nav 集約：DecideNext を唯一線に（保存廃止 / 次ステージロック可）
-- 追加修正:
--  - ラン終了時に StageResult を強制クローズ通知（残存モーダル対策）
--  - 次回スタートを強制NEWさせるフラグ s._forceNewOnNextStart = true を付与
--  - "home" は “このランを終了” として扱い、保留結果やスナップを全消去
--  - Round.resetRun() は呼ばず state を直接クリア（春スナップ生成を防止）
--  - HomeOpen は hasSave=false を必ず返す（常に New Game になる）
--  - "save" は受け取っても即 "home" に変換（保存ボタン廃止の保険）
--  - 次のステージは開発中ロックをフラグで制御（LOCAL_DEV_NEXT_LOCKED）

local RS  = game:GetService("ReplicatedStorage")

-- ===== 開発用トグル ===============================================
-- true : つねに「次のステージ」をロック（押してもHOMEに倒す）
-- false: 既存どおり「通算3回クリアで解禁」
local LOCAL_DEV_NEXT_LOCKED = true
-- ================================================================

-- Logger
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("NavServer")

local function ensureRemote(name: string)
	local rem = RS:FindFirstChild("Remotes")
	if not rem then
		rem = Instance.new("Folder")
		rem.Name = "Remotes"
		rem.Parent = RS
	end
	local e = rem:FindFirstChild(name)
	if not e then
		e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = rem
	end
	return e
end

local Remotes = {
	HomeOpen    = ensureRemote("HomeOpen"),
	DecideNext  = ensureRemote("DecideNext"),
	StageResult = ensureRemote("StageResult"), -- ★ 追加: 強制クローズ用
}

local function normLang(v:string?): string
	v = tostring(v or ""):lower()
	if v == "ja" or v == "jp" then return "ja" end
	if v == "en" then return "en" end
	return "en"
end

local NavServer = {}
NavServer.__index = NavServer

export type Deps = {
	StateHub: any,
	Round: any,
	ShopService: any?,
	SaveService: any?,
	HomeOpen: RemoteEvent?,      -- （任意）外から渡されたものを優先
	DecideNext: RemoteEvent?,    -- （任意）外から渡されたものを優先
}

function NavServer.init(deps: Deps)
	local self = setmetatable({ deps = deps or {}, _conns = {} }, NavServer)

	-- 外部から Remotes をもらえたら差し替え
	if deps.HomeOpen then Remotes.HomeOpen = deps.HomeOpen end
	if deps.DecideNext then Remotes.DecideNext = deps.DecideNext end

	-- 統一入口
	table.insert(self._conns, Remotes.DecideNext.OnServerEvent:Connect(function(plr, op)
		self:handle(plr, tostring(op or ""))
	end))

	LOG.info("ready (DecideNext unified)")
	return self
end

-- ★ “ランを終了”させるハードリセット（春スナップを新規生成しない）
local function endRunAndClean(StateHub, SaveService, plr: Player)
	local s = StateHub and StateHub.get and StateHub.get(plr)
	if not s then return end

	-- ラン関連・結果保留・遷移ロックを全て破棄
	s.phase         = "home"
	s.run           = nil
	s.shop          = nil
	s.ops           = nil
	s.options       = nil
	s.resultPending = nil
	s.stageResult   = nil
	s.decideLocks   = nil
	s.mult          = 1.0
	-- 念のため季節関連も切る（サーバ復元やUIの誤判定を防止）
	s.season        = nil
	s.round         = nil

	-- 次回開始は必ずNEW（GameInit.startGameAuto で見る）
	s._forceNewOnNextStart = true

	-- 「続き」用スナップも破棄（DataStore側）
	if SaveService and typeof(SaveService.clearActiveRun) == "function" then
		pcall(function() SaveService.clearActiveRun(plr) end)
	end

	-- クライアントの結果モーダルを明示的に閉じさせる（残存対策）
	-- Client側は {close=true} を受け取ったらモーダルを閉じる実装にしておく
	pcall(function()
		Remotes.StageResult:FireClient(plr, { close = true })
	end)

	-- クライアントへ最新 state を押し出して視覚的にも“切る”
	if StateHub and StateHub.pushState then
		pcall(function() StateHub.pushState(plr) end)
	end
end

function NavServer:handle(plr: Player, op: string)
	local StateHub    = self.deps.StateHub
	local Round       = self.deps.Round         -- 参照は残すが "home" では使わない
	local ShopService = self.deps.ShopService
	local SaveService = self.deps.SaveService

	local s = StateHub and StateHub.get and StateHub.get(plr)
	if not s then
		LOG.warn("state missing | user=%s op=%s", tostring(plr and plr.Name or "?"), tostring(op))
		return
	end

	-- 冬以外では想定外（クライアントから来ても無視）
	if (s.season or 1) ~= 4 then
		LOG.debug("DecideNext ignored (not winter) | user=%s op=%s season=%s", tostring(plr and plr.Name or "?"), tostring(op), tostring(s.season))
		return
	end

	-- 互換: "save" を送ってきてもすべて "home" として扱う（保存機能は廃止）
	if op == "save" then
		op = "home"
	end

	-- 共通初期化
	s.mult = 1.0

	-- 解禁判定（既定: 3クリアで "next" 許可）
	local clears   = tonumber(s.totalClears or 0) or 0
	local unlocked = (not LOCAL_DEV_NEXT_LOCKED) and (clears >= 3) or false

	if op ~= "home" and not unlocked then
		-- ロック中に "next" を送ってきても HOME へ倒す（改造クライアント対策）
		op = "home"
	end

	LOG.info(
		"handle | user=%s op=%s unlocked=%s clears=%d",
		tostring(plr and plr.Name or "?"), tostring(op), tostring(unlocked), clears
	)

	if op == "home" then
		-- ★ ランを終了（続き無し）→ Home
		endRunAndClean(StateHub, SaveService, plr)

		Remotes.HomeOpen:FireClient(plr, {
			hasSave = false, -- ★常に New Game
			bank    = s.bank or 0,
			year    = s.year or 0,
			clears  = s.totalClears or 0,
			lang    = normLang(SaveService and SaveService.getLang and SaveService.getLang(plr)),
		})
		LOG.info(
			"→ HOME(end-run) | user=%s hasSave=false bank=%d year=%d clears=%d",
			plr.Name, s.bank or 0, s.year or 0, s.totalClears or 0
		)
		return

	elseif op == "next" then
		-- 次の年へ（解禁済のみ到達）
		s.year = (s.year or 0) + 25
		if SaveService and typeof(SaveService.bumpYear) == "function" then
			SaveService.bumpYear(plr, 25)
		elseif SaveService and typeof(SaveService.setYear) == "function" then
			SaveService.setYear(plr, s.year)
		end
		s.phase = "shop"
		if ShopService and typeof(ShopService.open) == "function" then
			ShopService.open(plr, s, { reason = "after_winter" })
			LOG.info("→ NEXT (open shop) | user=%s newYear=%d", plr.Name, s.year or 0)
		else
			if StateHub and StateHub.pushState then StateHub.pushState(plr) end
			LOG.info("→ NEXT (push state only) | user=%s newYear=%d", plr.Name, s.year or 0)
		end
		return
	end

	LOG.warn("unknown op | user=%s op=%s", tostring(plr and plr.Name or "?"), tostring(op))
end

return NavServer
