-- StarterPlayerScripts/UI/ClientMain.client.lua
-- v0.9.6-P1-3 Router＋Remote結線（NavClient注入／Logger導入／vararg不使用）
-- 仕様メモ:
--   * <ShopOpen> は **ClientMainのみ** で受信し、Router.show("shop", payload) に一本化。
--   * 言語コードは外部公開を "ja"/"en" に統一（"jp" を受信した場合は "ja" へ正規化して警告）
--   * print/warn を共通 Logger に置換（公開時は閾値で抑止可能）

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes")

--========================
-- Logger
--========================
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("ClientMain")  -- ★ for → scope に変更

-- 公開ビルドで抑止したい場合は INFO/WARN へ（Studioは Logger.DEBUG にしてもOK）
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

-- 共通ユーティリティ（jp→ja / 不明は nil）
local LocaleUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("LocaleUtil"))

--========================
-- NavClient
--========================
local NavClient = require(RS:WaitForChild("SharedModules"):WaitForChild("NavClient"))

--========================
-- S→C
--========================
local HomeOpen    = Remotes:WaitForChild("HomeOpen")
local ShopOpen    = Remotes:WaitForChild("ShopOpen")
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
local BuyItem        = Remotes:WaitForChild("BuyItem")
local ShopReroll     = Remotes:WaitForChild("ShopReroll")
local ReqPick        = Remotes:WaitForChild("ReqPick")
local ReqSyncUI      = Remotes:WaitForChild("ReqSyncUI")
local DecideNext     = Remotes:WaitForChild("DecideNext")
local ReqSetLang     = Remotes:WaitForChild("ReqSetLang")

-- DEV
local DevGrantRyo  = Remotes:FindFirstChild("DevGrantRyo")
local DevGrantRole = Remotes:FindFirstChild("DevGrantRole")

-- ▼ レガシー（任意）：存在すれば Nav のバックアップ経路に使う
local GoHome   = Remotes:FindFirstChild("GoHome")
local GoNext   = Remotes:FindFirstChild("GoNext")
local SaveQuit = Remotes:FindFirstChild("SaveQuit")

-- ▼ Nav の生成（正準は DecideNext、レガシーは互換のみ）
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
	mod.init    = (type(mod.init)    == "function") and mod.init    or function(_) end
	mod.setDeps = (type(mod.setDeps) == "function") and mod.setDeps or function(_) end
	mod.show    = (type(mod.show)    == "function") and mod.show    or function(_) end
	mod.call    = (type(mod.call)    == "function") and mod.call    or function() end
	Router = mod
end

local Screens = {
	home   = require(ScreensFolder:WaitForChild("HomeScreen")),
	run    = require(ScreensFolder:WaitForChild("RunScreen")),
	shop   = require(ScreensFolder:WaitForChild("ShopScreen")),
	shrine = require(ScreensFolder:WaitForChild("ShrineScreen")),
}
Router.init(Screens)

Router.setDeps({
	playerGui = Players.LocalPlayer:WaitForChild("PlayerGui"),
	Confirm=Confirm, ReqPick=ReqPick, ReqRerollAll=ReqRerollAll, ReqRerollHand=ReqRerollHand,
	ShopDone=ShopDone, BuyItem=BuyItem, ShopReroll=ShopReroll,
	ReqStartNewRun=ReqStartNewRun, ReqContinueRun=ReqContinueRun, ReqSyncUI=ReqSyncUI,
	DecideNext=DecideNext, ReqSetLang=ReqSetLang,
	HandPush=HandPush, FieldPush=FieldPush, TakenPush=TakenPush, ScorePush=ScorePush, StatePush=StatePush,
	StageResult=StageResult,

	-- ▼ 追加：UI層へ Nav を配布（ResultModal → Nav.next("home"|"next"|"save")）
	Nav = Nav,

	-- ★ P0-7: トーストタイトルをロケールで切替（"jp" は受けたら "ja" として扱う）
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

	-- 参考：既存 remotes マップ（互換のためそのまま維持）
	remotes = {
		Confirm=Confirm, ReqPick=ReqPick, ReqRerollAll=ReqRerollAll, ReqRerollHand=ReqRerollHand,
		ShopDone=ShopDone, BuyItem=BuyItem, ShopReroll=ShopReroll,
		ReqStartNewRun=ReqStartNewRun, ReqContinueRun=ReqContinueRun, ReqSyncUI=ReqSyncUI,
		HandPush=HandPush, FieldPush=FieldPush, TakenPush=TakenPush, ScorePush=ScorePush, StatePush=StatePush,
		StageResult=StageResult, DecideNext=DecideNext, ReqSetLang=ReqSetLang,
		DevGrantRyo=DevGrantRyo, DevGrantRole=DevGrantRole,
		-- （必要なら）Nav もここへ見せたい場合は次行を有効化
		-- Nav = Nav,
	},
})

--========================================
-- S→C 配線（P0-5: ShopOpenはここだけ）
--========================================
HomeOpen.OnClientEvent:Connect(function(payload)
	if payload and payload.lang and type(Locale.setGlobal)=="function" then
		local nl = LocaleUtil.norm(payload.lang) or payload.lang
		Locale.setGlobal(nl)
	end
	Router.show("home", payload)
	LOG.info("Router.show -> home")
end)

ShopOpen.OnClientEvent:Connect(function(payload)
	-- P0-5: ClientMain が唯一の <ShopOpen> 受口
	local p = payload or {}
	-- 言語が来ていない場合は共有言語、"jp" が来たら "ja" に正規化
	if p.lang == nil then
		p.lang = (Locale.getGlobal and Locale.getGlobal()) or "en"
	end
	local nl = LocaleUtil.norm(p.lang)
	if nl and nl ~= p.lang then p.lang = nl end
	Router.show("shop", p)
	LOG.info("<ShopOpen> routed once | lang=%s", tostring(p.lang))
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
