-- StarterPlayerScripts/UI/ClientMain.client.lua
-- v0.10.0-A Route-centralized (ClientMain listens ShopOpen/ShopResult; Wires = send-only)
-- - ShopOpen/ShopResult の受信を ClientMain に集約（kitoPick 前面時は「裏更新のみ」）
-- - ShopWires は Buy/Reroll/Close など送信専任（Remote 直叩きは UI/Renderer で禁止）
-- - Router の ensure/active/show/call は安全スタブで維持
-- - Router.setDeps から BuyItem / ShopReroll / ShopDone は除外

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes")

--========================
-- Logger
--========================
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("ClientMain")

Logger.configure({
	level = Logger.INFO,
	timePrefix = true,
	dupWindowSec = 0.5,
})

LOG.info("boot")

--========================
-- Locale / LocaleUtil
--========================
local okLocale, Locale = pcall(function()
	return require(RS:WaitForChild("Config"):WaitForChild("Locale"))
end)
if not okLocale or type(Locale) ~= "table" then
	LOG.warn("Locale missing; using fallback")
	local _g = "en"
	Locale = {}
	function Locale.getGlobal() return _g end
	function Locale.setGlobal(v) _g = (v=="ja" or v=="jp") and "ja" or "en" end
	function Locale.t(_, key)
		if key == "TOAST_TITLE" then
			return (_g == "ja") and "通知" or "Notice"
		end
		return key
	end
end

local LocaleUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("LocaleUtil"))
local function _normLang(lang)
	return (type(LocaleUtil.norm)=="function" and LocaleUtil.norm(lang)) or lang or "en"
end

--========================
-- NavClient
--========================
local NavClient = require(RS:WaitForChild("SharedModules"):WaitForChild("NavClient"))

--========================
-- S→C
--========================
local HomeOpen    = Remotes:WaitForChild("HomeOpen")
local ShopOpen    = Remotes:WaitForChild("ShopOpen")           -- ★ ClientMain が購読
local ShopResult  = Remotes:FindFirstChild("ShopResult")       -- 任意（nil可）
local StatePush   = Remotes:WaitForChild("StatePush")
local HandPush    = Remotes:WaitForChild("HandPush")
local FieldPush   = Remotes:WaitForChild("FieldPush")
local TakenPush   = Remotes:WaitForChild("TakenPush")
local ScorePush   = Remotes:WaitForChild("ScorePush")
local RoundReady  = Remotes:WaitForChild("RoundReady")
local StageResult = Remotes:WaitForChild("StageResult")

--========================
-- C→S
--========================
local ReqStartNewRun = Remotes:WaitForChild("ReqStartNewRun")
local ReqContinueRun = Remotes:WaitForChild("ReqContinueRun")
local Confirm        = Remotes:WaitForChild("Confirm")
local ReqRerollAll   = Remotes:WaitForChild("ReqRerollAll")
local ReqRerollHand  = Remotes:WaitForChild("ReqRerollHand")
local ShopDone       = Remotes:WaitForChild("ShopDone")        -- 送信は Wires 側
local BuyItem        = Remotes:WaitForChild("BuyItem")         -- 送信は Wires 側
local ShopReroll     = Remotes:WaitForChild("ShopReroll")      -- 送信は Wires 側
local ReqPick        = Remotes:WaitForChild("ReqPick")
local ReqSyncUI      = Remotes:WaitForChild("ReqSyncUI")
local DecideNext     = Remotes:WaitForChild("DecideNext")
local ReqSetLang     = Remotes:WaitForChild("ReqSetLang")

-- DEV（任意）
local DevGrantRyo  = Remotes:FindFirstChild("DevGrantRyo")
local DevGrantRole = Remotes:FindFirstChild("DevGrantRole")

-- レガシー（任意）
local GoHome   = Remotes:FindFirstChild("GoHome")
local GoNext   = Remotes:FindFirstChild("GoNext")
local SaveQuit = Remotes:FindFirstChild("SaveQuit")

-- Nav
local Nav = NavClient.new(DecideNext, {
	GoHome   = GoHome,
	GoNext   = GoNext,
	SaveQuit = SaveQuit,
})

--========================
-- Router 準備
--========================
local uiRoot = script.Parent:FindFirstChild("UI") or script.Parent
local ScreenRouterModule = uiRoot:FindFirstChild("ScreenRouter") or uiRoot:WaitForChild("ScreenRouter")
local ScreensFolder      = uiRoot:FindFirstChild("screens")      or uiRoot:WaitForChild("screens")

local Router
do
	local ok, mod = pcall(require, ScreenRouterModule)
	if not ok then
		LOG.warn("require(ScreenRouter) failed; stub used: %s", tostring(mod))
		mod = {}
	end
	if type(mod) ~= "table" then mod = {} end
	mod.init     = (type(mod.init)     == "function") and mod.init     or function(_) end
	mod.setDeps  = (type(mod.setDeps)  == "function") and mod.setDeps  or function(_) end
	mod.show     = (type(mod.show)     == "function") and mod.show     or function(_) end
	mod.call     = (type(mod.call)     == "function") and mod.call     or function() end
	mod.ensure   = (type(mod.ensure)   == "function") and mod.ensure   or function() end
	mod.active   = (type(mod.active)   == "function") and mod.active   or function() return nil end
	mod.register = (type(mod.register) == "function") and mod.register or function() end
	Router = mod
end

--========================
-- 画面定義
--========================
local Screens = {
	home     = require(ScreensFolder:WaitForChild("HomeScreen")),
	run      = require(ScreensFolder:WaitForChild("RunScreen")),
	shop     = require(ScreensFolder:WaitForChild("ShopView")),
	shrine   = require(ScreensFolder:WaitForChild("ShrineScreen")),
	kitoPick = require(ScreensFolder:WaitForChild("KitoPickView")),
}
Router.init(Screens)

--========================
-- Router → UI 依存注入
--  ※ BuyItem / ShopReroll / ShopDone は配布しない（Wires専任）
--========================
Router.setDeps({
	playerGui = Players.LocalPlayer:WaitForChild("PlayerGui"),
	Confirm=Confirm, ReqPick=ReqPick, ReqRerollAll=ReqRerollAll, ReqRerollHand=ReqRerollHand,
	ReqStartNewRun=ReqStartNewRun, ReqContinueRun=ReqContinueRun, ReqSyncUI=ReqSyncUI,
	DecideNext=DecideNext, ReqSetLang=ReqSetLang,
	HandPush=HandPush, FieldPush=FieldPush, TakenPush=TakenPush, ScorePush=ScorePush, StatePush=StatePush,
	StageResult=StageResult,
	Nav = Nav,

	toast = function(msg, dur)
		pcall(function()
			local gl   = (type(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
			local lang = _normLang(gl)
			local title = (type(Locale.t)=="function" and Locale.t(lang, "TOAST_TITLE"))
			              or ((lang=="ja") and "通知" or "Notice")
			game.StarterGui:SetCore("SendNotification", {
				Title    = title,
				Text     = msg,
				Duration = dur or 2,
			})
		end)
	end,

	remotes = {
		Confirm=Confirm, ReqPick=ReqPick, ReqRerollAll=ReqRerollAll, ReqRerollHand=ReqRerollHand,
		ReqStartNewRun=ReqStartNewRun, ReqContinueRun=ReqContinueRun, ReqSyncUI=ReqSyncUI,
		HandPush=HandPush, FieldPush=FieldPush, TakenPush=TakenPush, ScorePush=ScorePush, StatePush=StatePush,
		StageResult=StageResult, DecideNext=DecideNext, ReqSetLang=ReqSetLang,
		DevGrantRyo=DevGrantRyo, DevGrantRole=DevGrantRole,
	},
})

--========================
-- Wires（送信専任）
--========================
local componentsFolder = uiRoot:WaitForChild("components")
local ShopWires     = require(componentsFolder:WaitForChild("controllers"):WaitForChild("ShopWires"))
local ClientSignals = require(componentsFolder:WaitForChild("controllers"):WaitForChild("ClientSignals"))

ShopWires.init({
	Router = Router,
	Locale = Locale,
	LocaleUtil = LocaleUtil,
	Logger = Logger,
	signals = ClientSignals, -- Buy/Reroll/Close は Signals → Wires → Remote
	remotes = {
		BuyItem    = BuyItem,
		ShopReroll = ShopReroll,
		ShopDone   = ShopDone,
		ReqSetLang = ReqSetLang,
		StatePush  = StatePush,
	},
	toast = function(msg, dur)
		pcall(function()
			local gl   = (type(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
			local lang = _normLang(gl)
			local title = (type(Locale.t)=="function" and Locale.t(lang, "TOAST_TITLE"))
			              or ((lang=="ja") and "通知" or "Notice")
			game.StarterGui:SetCore("SendNotification", {
				Title    = title,
				Text     = msg,
				Duration = dur or 2,
			})
		end)
	end,
	-- ※ ShopWires 側の「ShopOpen/ShopResult購読」は無効化しておくこと（送信専任）
})

LOG.info("wired: ShopWires.init (send-only)")

--========================================
-- S→C 配線（ClientMain が ShopOpen/ShopResult を受信）
--========================================
HomeOpen.OnClientEvent:Connect(function(payload)
	if payload and payload.lang and type(Locale.setGlobal)=="function" then
		local nl = _normLang(payload.lang)
		Locale.setGlobal(nl)
	end
	Router.show("home", payload)
	LOG.info("Router.show -> home")
end)

RoundReady.OnClientEvent:Connect(function()
	local gl   = (type(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
	local lang = _normLang(gl)
	Router.show("run")
	if Router and type(Router.call)=="function" then
		Router.call("run", "setLang", lang)
		Router.call("run", "requestSync")
	end
	LOG.info("RoundReady → run | lang=%s", lang)
end)

-- ★ ShopOpen：kitoPick 前面時は「背景更新のみ」、それ以外は遷移
ShopOpen.OnClientEvent:Connect(function(payload)
	payload = payload or {}

	-- 言語補完：未指定ならグローバル→既定へ、指定ありなら正規化＋グローバル反映
	if payload.lang == nil then
		local g = (type(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
		payload.lang = _normLang(g)
	else
		local nl = _normLang(payload.lang)
		payload.lang = nl
		if type(Locale.setGlobal)=="function" then Locale.setGlobal(nl) end
	end

	local active = (Router and type(Router.active)=="function") and Router.active() or nil
	if active == "kitoPick" then
		local ok, shopInst = pcall(function() return Router.ensure("shop") end)
		if ok and shopInst then
			if type(shopInst.setData)=="function" then pcall(function() shopInst:setData(payload) end) end
			if type(shopInst.update)=="function" then pcall(function() shopInst:update(payload) end) end
			LOG.info("<ShopOpen> background update (kitoPick active) | lang=%s", tostring(payload.lang))
		else
			Router.show("shop", payload)
			LOG.info("<ShopOpen> routed (fallback) | lang=%s", tostring(payload.lang))
		end
	else
		Router.show("shop", payload)
		LOG.info("<ShopOpen> routed | lang=%s", tostring(payload.lang))
	end

	-- ローカルバス（他UIが必要なら購読可能）
	if ClientSignals and ClientSignals.ShopIncoming and typeof(ClientSignals.ShopIncoming.Fire)=="function" then
		ClientSignals.ShopIncoming:Fire(payload)
	end
end)

-- 任意：ShopResult をローカルバスへ中継（存在する環境のみ）
if ShopResult and ShopResult.OnClientEvent then
	ShopResult.OnClientEvent:Connect(function(res)
		if ClientSignals and ClientSignals.ShopResult and typeof(ClientSignals.ShopResult.Fire)=="function" then
			ClientSignals.ShopResult:Fire(res)
		end
		LOG.info("<ShopResult> relayed to ClientSignals")
	end)
else
	LOG.warn("ShopResult remote not found; proceeding without it")
end

-- そのほかの Push 群
StatePush.OnClientEvent:Connect(function(st)
	if st and st.lang and type(Locale.setGlobal)=="function" then
		local l = _normLang(st.lang)
		if l then Locale.setGlobal(l) end
	end
	if Router and type(Router.call)=="function" then
		Router.call("run", "onState", st)
	end
end)

HandPush.OnClientEvent:Connect(function(hand)
	if Router and type(Router.call)=="function" then Router.call("run", "onHand", hand) end
end)

FieldPush.OnClientEvent:Connect(function(field)
	if Router and type(Router.call)=="function" then Router.call("run", "onField", field) end
end)

TakenPush.OnClientEvent:Connect(function(taken)
	if Router and type(Router.call)=="function" then Router.call("run", "onTaken", taken) end
end)

ScorePush.OnClientEvent:Connect(function(total, roles, dtl)
	if Router and type(Router.call)=="function" then Router.call("run", "onScore", total, roles, dtl) end
end)

StageResult.OnClientEvent:Connect(function(payload)
	if Router and type(Router.call)=="function" then Router.call("run", "onStageResult", payload) end
end)

LOG.info("ready")
