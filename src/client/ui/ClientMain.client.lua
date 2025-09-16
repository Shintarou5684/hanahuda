-- v0.9.3 Router＋Remote結線（NavClient注入／vararg不使用）
print("[ClientMain] boot")

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes")

-- Locale
local okLocale, Locale = pcall(function()
	return require(RS:WaitForChild("Config"):WaitForChild("Locale"))
end)
if not okLocale or type(Locale) ~= "table" then
	warn("[ClientMain] Locale missing; fallback")
	local _g = "en"
	Locale = {}
	function Locale.getGlobal() return _g end
	function Locale.setGlobal(v) _g = (v=="ja" or v=="jp") and "jp" or "en" end
end

-- ▼ 追加：NavClient
local NavClient = require(RS:WaitForChild("SharedModules"):WaitForChild("NavClient"))

-- S→C
local HomeOpen    = Remotes:WaitForChild("HomeOpen")
local ShopOpen    = Remotes:WaitForChild("ShopOpen")
local StatePush   = Remotes:WaitForChild("StatePush")
local HandPush    = Remotes:WaitForChild("HandPush")
local FieldPush   = Remotes:WaitForChild("FieldPush")
local TakenPush   = Remotes:WaitForChild("TakenPush")
local ScorePush   = Remotes:WaitForChild("ScorePush")
local RoundReady  = Remotes:WaitForChild("RoundReady")
local StageResult = Remotes:WaitForChild("StageResult")

-- C→S
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

local uiRoot = script.Parent:FindFirstChild("UI") or script.Parent
local ScreenRouterModule = uiRoot:FindFirstChild("ScreenRouter") or uiRoot:WaitForChild("ScreenRouter")
local ScreensFolder      = uiRoot:FindFirstChild("screens")      or uiRoot:WaitForChild("screens")

local Router
do
	local ok, mod = pcall(require, ScreenRouterModule)
	if not ok then
		warn("[ClientMain] require(ScreenRouter) failed; stub:", mod)
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

	toast = function(msg, dur)
		pcall(function()
			game.StarterGui:SetCore("SendNotification", { Title = "通知", Text = msg, Duration = dur or 2 })
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

HomeOpen.OnClientEvent:Connect(function(payload)
	if payload and payload.lang and type(Locale.setGlobal)=="function" then
		Locale.setGlobal(payload.lang)
	end
	Router.show("home", payload)
end)

ShopOpen.OnClientEvent:Connect(function(payload)
	local p = payload or {}
	if p.lang == nil then p.lang = Locale.getGlobal and Locale.getGlobal() or "en" end
	Router.show("shop", p)
end)

RoundReady.OnClientEvent:Connect(function()
	local lang = (type(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
	Router.show("run")
	if Router and type(Router.call)=="function" then
		Router.call("run", "setLang", lang)
		Router.call("run", "requestSync")
	end
end)

StatePush.OnClientEvent:Connect(function(st)
	if st and st.lang and type(Locale.setGlobal)=="function" then
		local l = tostring(st.lang)
		if l == "ja" or l == "jp" or l == "en" then Locale.setGlobal(l) end
	end
	if Router and type(Router.call)=="function" then Router.call("run", "onState", st) end
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

print("[ClientMain] ready")
