-- ServerScriptService/NavServer.lua
-- v0.9.9  DecideNext 12-month対応：final-month は HOME 強制
-- 変更点：
--  - 月12の result 中は、どの操作（koikoi/home/その他）でも HOME 一択に強制
--  - サーバ側で StageResult を明示クローズし、HomeOpen を即発火
--  - 12月クリア時の +2 両はスコア側で加算済みのため、ここでは追加しない（重複防止）

local RS  = game:GetService("ReplicatedStorage")

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
	StageResult = ensureRemote("StageResult"), -- クライアント結果モーダルの明示クローズ用
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

	LOG.info("ready (DecideNext unified / 12-month 2-choice)")
	return self
end

-- ★ ラン終了のハードリセット（春スナップを新規生成しない）
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
	-- 季節系も切ってUIの誤判定を防止
	s.season        = nil
	s.round         = nil

	-- 次回開始は必ずNEW（GameInit.startGameAuto で参照）
	s._forceNewOnNextStart = true

	-- 「続き」用スナップも破棄（DataStore側）
	if SaveService and typeof(SaveService.clearActiveRun) == "function" then
		pcall(function() SaveService.clearActiveRun(plr) end)
	end

	-- クライアントの結果モーダルを明示的に閉じる
	pcall(function()
		Remotes.StageResult:FireClient(plr, { close = true })
	end)

	-- クライアントへ最新 state を押し出し視覚的にも終了させる
	if StateHub and StateHub.pushState then
		pcall(function() StateHub.pushState(plr) end)
	end
end

local function getMonth(s:any): number
	return tonumber(s and s.run and s.run.month) or 1
end

function NavServer:handle(plr: Player, op: string)
	local StateHub    = self.deps.StateHub
	local Round       = self.deps.Round         -- 参照は残すがここでは newRound は呼ばない
	local ShopService = self.deps.ShopService
	local SaveService = self.deps.SaveService

	local s = StateHub and StateHub.get and StateHub.get(plr)
	if not s then
		LOG.warn("state missing | user=%s op=%s", tostring(plr and plr.Name or "?"), tostring(op))
		return
	end

	local op0 = string.lower(tostring(op or ""))
	local m   = getMonth(s)

	-- =========================
	-- ★ final-month ガード：月12の result 中は「HOME 一択」
	-- =========================
	if s.phase == "result" and m >= 12 then
		LOG.info("handle: %s | user=%s month=%d phase=%s → force HOME (final month)",
			tostring(op0), tostring(plr and plr.Name or "?"), m, tostring(s.phase))

		endRunAndClean(StateHub, SaveService, plr)

		Remotes.HomeOpen:FireClient(plr, {
			hasSave = false, -- NEW GAME を強制
			bank    = s.bank or 0,
			year    = s.year or 0,
			clears  = s.totalClears or 0,
			lang    = normLang(SaveService and SaveService.getLang and SaveService.getLang(plr)),
		})
		LOG.info("→ HOME(end-run final) | user=%s hasSave=false bank=%d year=%d clears=%d",
			tostring(plr and plr.Name or "?"), s.bank or 0, s.year or 0, s.totalClears or 0)
		return
	end

	-- =========================
	-- いつでも有効："abandon"（即終了）
	-- =========================
	if op0 == "abandon" then
		LOG.info("handle: ABANDON | user=%s phase=%s month=%s", tostring(plr and plr.Name or "?"), tostring(s.phase), tostring(s.run and s.run.month))
		endRunAndClean(StateHub, SaveService, plr)

		Remotes.HomeOpen:FireClient(plr, {
			hasSave = false, -- NEW GAME を強制
			bank    = s.bank or 0,
			year    = s.year or 0,
			clears  = s.totalClears or 0,
			lang    = normLang(SaveService and SaveService.getLang and SaveService.getLang(plr)),
		})
		LOG.info("→ HOME(abandon) | user=%s bank=%d year=%d clears=%d", plr.Name, s.bank or 0, s.year or 0, s.totalClears or 0)
		return
	end

	-- =========================
	-- 2択：home / koikoi
	-- ※ 季節や解禁の条件は撤廃。9/10/11月などのクリア通知から直接来る想定。
	-- =========================
	if op0 == "home" then
		-- ラン終了→Home
		LOG.info("handle: HOME | user=%s month=%s phase=%s", tostring(plr and plr.Name or "?"), tostring(s.run and s.run.month), tostring(s.phase))
		endRunAndClean(StateHub, SaveService, plr)

		Remotes.HomeOpen:FireClient(plr, {
			hasSave = false,
			bank    = s.bank or 0,
			year    = s.year or 0,
			clears  = s.totalClears or 0,
			lang    = normLang(SaveService and SaveService.getLang and SaveService.getLang(plr)),
		})
		LOG.info("→ HOME(end-run) | user=%s hasSave=false bank=%d year=%d clears=%d", plr.Name, s.bank or 0, s.year or 0, s.totalClears or 0)
		return

	elseif op0 == "koikoi" or op0 == "continue" then
		-- 続行：結果モーダルを閉じて屋台を開く（EXへ）
		LOG.info("handle: KOIKOI | user=%s month=%s phase=%s", tostring(plr and plr.Name or "?"), tostring(s.run and s.run.month), tostring(s.phase))

		-- まずクライアント側の結果モーダルを閉じる
		pcall(function()
			Remotes.StageResult:FireClient(plr, { close = true })
		end)

		-- 次は屋台へ。ShopService が無い場合は state push のみ。
		s.phase = "shop"
		if ShopService and typeof(ShopService.open) == "function" then
			ShopService.open(plr, s, { reason = "after_clear_month" })
			LOG.info("→ SHOP(open) | user=%s month=%s", plr.Name, tostring(s.run and s.run.month))
		else
			if StateHub and StateHub.pushState then StateHub.pushState(plr) end
			LOG.info("→ SHOP(push only) | user=%s month=%s", plr.Name, tostring(s.run and s.run.month))
		end
		return
	end

	LOG.warn("unknown op | user=%s op=%s", tostring(plr and plr.Name or "?"), tostring(op0))
end

return NavServer
