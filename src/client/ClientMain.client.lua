-- ClientMain.client.lua  v0.8r (UIフォルダ有無どちらも対応 / 自動開始なし)
print("[ClientMain] boot")

--==================================================
-- Services / Remotes
--==================================================
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes")

-- S→C
local HomeOpen   = Remotes:WaitForChild("HomeOpen")
local ShopOpen   = Remotes:WaitForChild("ShopOpen")
local StatePush  = Remotes:WaitForChild("StatePush")
local HandPush   = Remotes:WaitForChild("HandPush")
local FieldPush  = Remotes:WaitForChild("FieldPush")
local TakenPush  = Remotes:WaitForChild("TakenPush")
local ScorePush  = Remotes:WaitForChild("ScorePush")
local RoundReady = Remotes:WaitForChild("RoundReady")

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

-- DEV（Studio）
local DevGrantRyo  = Remotes:FindFirstChild("DevGrantRyo")
local DevGrantRole = Remotes:FindFirstChild("DevGrantRole")

--==================================================
-- 画面モジュールの場所を解決（UI/ が無くてもOK）
--==================================================
local root = script:FindFirstAncestor("UI") or script.Parent          -- UI/ClientMain or StarterPlayerScripts
local screensFolder = root:FindFirstChild("screens") or script.Parent:WaitForChild("screens")
local ScreenRouter  = root:FindFirstChild("ScreenRouter") and require(root.ScreenRouter)
                    or require(script.Parent:WaitForChild("ScreenRouter"))

local Screens = {
	home   = require(screensFolder:WaitForChild("HomeScreen")),
	run    = require(screensFolder:WaitForChild("RunScreen")),
	shop   = require(screensFolder:WaitForChild("ShopScreen")),
	shrine = require(screensFolder:WaitForChild("ShrineScreen")),
}

ScreenRouter.init(Screens)

ScreenRouter.setDeps({
	playerGui = Players.LocalPlayer:WaitForChild("PlayerGui"),

	-- C→S
	Confirm=Confirm, ReqPick=ReqPick, ReqRerollAll=ReqRerollAll, ReqRerollHand=ReqRerollHand,
	ShopDone=ShopDone, BuyItem=BuyItem, ShopReroll=ShopReroll,
	ReqStartNewRun=ReqStartNewRun, ReqContinueRun=ReqContinueRun, ReqSyncUI=ReqSyncUI,

	-- S→C
	HandPush=HandPush, FieldPush=FieldPush, TakenPush=TakenPush, ScorePush=ScorePush, StatePush=StatePush,

	-- DEV
	DevGrantRyo=DevGrantRyo, DevGrantRole=DevGrantRole,

	-- 遷移ユーティリティ
	showRun    = function() ScreenRouter.show("run") end,
	showHome   = function(payload) ScreenRouter.show("home", payload) end,
	showShop   = function(payload) ScreenRouter.show("shop", payload) end,
	showShrine = function() ScreenRouter.show("shrine") end,

	-- 互換ネスト
	remotes = {
		Confirm=Confirm, ReqPick=ReqPick, ReqRerollAll=ReqRerollAll, ReqRerollHand=ReqRerollHand,
		ShopDone=ShopDone, BuyItem=BuyItem, ShopReroll=ShopReroll,
		ReqStartNewRun=ReqStartNewRun, ReqContinueRun=ReqContinueRun, ReqSyncUI=ReqSyncUI,
		HandPush=HandPush, FieldPush=FieldPush, TakenPush=TakenPush, ScorePush=ScorePush, StatePush=StatePush,
		DevGrantRyo=DevGrantRyo, DevGrantRole=DevGrantRole,
	},
})

--==================================================
-- Remote → 画面の表示/更新（起動時は Home を見せる）
--==================================================
HomeOpen .OnClientEvent:Connect(function(payload) ScreenRouter.show("home", payload) end)
ShopOpen .OnClientEvent:Connect(function(payload) ScreenRouter.show("shop", payload) end)

RoundReady.OnClientEvent:Connect(function()
	ScreenRouter.show("run")
	ScreenRouter.call("run", "requestSync")  -- RunScreen.requestSync()
end)

local function toRun(method, ...) ScreenRouter.call("run", method, ...) end
StatePush.OnClientEvent:Connect(function(st)              toRun("onState", st) end)
HandPush .OnClientEvent:Connect(function(hand)            toRun("onHand", hand) end)
FieldPush.OnClientEvent:Connect(function(field)           toRun("onField", field) end)
TakenPush.OnClientEvent:Connect(function(taken)           toRun("onTaken", taken) end)
ScorePush.OnClientEvent:Connect(function(total,roles,dtl) toRun("onScore", total, roles, dtl) end)

-- ★ 起動時は Home を表示（自動 NewRun はしない）
ScreenRouter.show("home")

print("[ClientMain] ready")
