-- StarterPlayerScripts/UI/ClientMain.client.lua
-- v0.9.6-P1-8 Router＋Remote結線（NavClient注入／Logger導入／vararg不使用）
-- - ShopOpen の受信は撤去し、代わりに ShopWires.init に一任（フェーズ4：Wires 単一路線化）
-- - ShopResult は存在しない環境もあるため FindFirstChild に変更（Infinite yield 回避）
-- - kitoPick 前面時の裏更新などの分岐も Wires 側に委譲
-- - Router の安全スタブ ensure/active/register は従来どおり

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

--========================
-- NavClient
--========================
local NavClient = require(RS:WaitForChild("SharedModules"):WaitForChild("NavClient"))

--========================
-- S→C
--========================
local HomeOpen    = Remotes:WaitForChild("HomeOpen")
local ShopOpen    = Remotes:WaitForChild("ShopOpen")           -- ← Wires 側で購読
local ShopResult  = Remotes:FindFirstChild("ShopResult")       -- ← 存在しない環境あり。WaitForChild を使わない
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
local ShopDone       = Remotes:WaitForChild("ShopDone")
local BuyItem        = Remotes:WaitForChild("BuyItem")         -- ← Wires 側で送信
local ShopReroll     = Remotes:WaitForChild("ShopReroll")      -- ← Wires 側で送信
local ReqPick        = Remotes:WaitForChild("ReqPick")
local ReqSyncUI      = Remotes:WaitForChild("ReqSyncUI")
local DecideNext     = Remotes:WaitForChild("DecideNext")
local ReqSetLang     = Remotes:WaitForChild("ReqSetLang")

-- DEV
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
	-- ensure/active/register を安全に生やす
	mod.ensure   = (type(mod.ensure)   == "function") and mod.ensure   or function() end
	mod.active   = (type(mod.active)   == "function") and mod.active   or function() return nil end
	mod.register = (type(mod.register) == "function") and mod.register or function() end
	Router = mod
end

--========================
-- 画面定義（shop は ShopView）
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
-- 依存性配布（Router → UI）
--========================
Router.setDeps({
	playerGui = Players.LocalPlayer:WaitForChild("PlayerGui"),
	Confirm=Confirm, ReqPick=ReqPick, ReqRerollAll=ReqRerollAll, ReqRerollHand=ReqRerollHand,
	ShopDone=ShopDone, BuyItem=BuyItem, ShopReroll=ShopReroll,
	ReqStartNewRun=ReqStartNewRun, ReqContinueRun=ReqContinueRun, ReqSyncUI=ReqSyncUI,
	DecideNext=DecideNext, ReqSetLang=ReqSetLang,
	HandPush=HandPush, FieldPush=FieldPush, TakenPush=TakenPush, ScorePush=ScorePush, StatePush=StatePush,
	StageResult=StageResult,

	-- UI層へ Nav を配布
	Nav = Nav,

	-- トースト
	toast = function(msg, dur)
		pcall(function()
			local gl   = (type(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
			local lang = LocaleUtil.norm(gl) or "en"
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
		ShopDone=ShopDone, BuyItem=BuyItem, ShopReroll=ShopReroll,
		ReqStartNewRun=ReqStartNewRun, ReqContinueRun=ReqContinueRun, ReqSyncUI=ReqSyncUI,
		HandPush=HandPush, FieldPush=FieldPush, TakenPush=TakenPush, ScorePush=ScorePush, StatePush=StatePush,
		StageResult=StageResult, DecideNext=DecideNext, ReqSetLang=ReqSetLang,
		DevGrantRyo=DevGrantRyo, DevGrantRole=DevGrantRole,
	},
})

--========================
-- Wires 単一路線化：ShopWires.init
--========================
local componentsFolder = uiRoot:WaitForChild("components")
local ShopWires     = require(componentsFolder:WaitForChild("controllers"):WaitForChild("ShopWires"))
local ClientSignals = require(componentsFolder:WaitForChild("controllers"):WaitForChild("ClientSignals"))

-- ShopOpen/（任意）ShopResult の購読、および Buy/Reroll/Close の送信は ShopWires に集約
ShopWires.init({
	Router = Router,
	Locale = Locale,
	LocaleUtil = LocaleUtil,
	Logger = Logger,
	signals = ClientSignals,
	remotes = {
		ShopOpen   = ShopOpen,
		ShopResult = ShopResult,   -- ← nil の可能性あり。ShopWires 側で nil チェックすること
		BuyItem    = BuyItem,
		ShopReroll = ShopReroll,
		ShopDone   = ShopDone,
		ReqSetLang = ReqSetLang,
		StatePush  = StatePush,
	},
	toast = function(msg, dur)
		pcall(function()
			local gl   = (type(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
			local lang = LocaleUtil.norm(gl) or "en"
			local title = (type(Locale.t)=="function" and Locale.t(lang, "TOAST_TITLE"))
			              or ((lang=="ja") and "通知" or "Notice")
			game.StarterGui:SetCore("SendNotification", {
				Title    = title,
				Text     = msg,
				Duration = dur or 2,
			})
		end)
	end,
})
if not ShopResult then
	LOG.warn("ShopResult remote not found; Wires will operate with ShopOpen only")
end
LOG.info("wired: ShopWires.init (ShopOpen/ShopResult by Wires)")

--========================================
-- S→C 配線（ShopOpen は撤去済み：Wires に委譲）
--========================================

HomeOpen.OnClientEvent:Connect(function(payload)
	if payload and payload.lang and type(Locale.setGlobal)=="function" then
		local nl = LocaleUtil.norm(payload.lang) or payload.lang
		Locale.setGlobal(nl)
	end
	Router.show("home", payload)
	LOG.info("Router.show -> home")
end)

RoundReady.OnClientEvent:Connect(function()
	local gl   = (type(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
	local lang = LocaleUtil.norm(gl) or "en"
	Router.show("run")
	if Router and type(Router.call)=="function" then
		Router.call("run", "setLang", lang)
		Router.call("run", "requestSync")
	end
	LOG.info("RoundReady → run | lang=%s", lang)
end)

StatePush.OnClientEvent:Connect(function(st)
	if st and st.lang and type(Locale.setGlobal)=="function" then
		local l = LocaleUtil.norm(st.lang)
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
