-- ClientMain.client.lua
-- 司令塔：Remotes配線、ScreenRouter初期化、画面遷移の入口（自動開始はしない）

print("[ClientMain] boot")

--==================================================
-- Services / Folders / Remotes
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
local RoundReady = Remotes:WaitForChild("RoundReady")   -- 新ラウンド準備完了

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

-- 将来/オプション（存在しない環境でもOKにする）
local StageResult = Remotes:FindFirstChild("StageResult")  -- S→C（冬クリア時など）
local DecideNext  = Remotes:FindFirstChild("DecideNext")   -- C→S（冬後の選択）

-- DEV（Studio用）
local DevGrantRyo  = Remotes:FindFirstChild("DevGrantRyo")
local DevGrantRole = Remotes:FindFirstChild("DevGrantRole")

--==================================================
-- Screen Router 初期化
--==================================================
local UI            = script.Parent:WaitForChild("UI")  -- このスクリプトの親フォルダに ScreenRouter/sreens がある想定
local ScreensFolder = UI:WaitForChild("screens")
local Router        = require(UI:WaitForChild("ScreenRouter"))

local Screens = {
	home   = require(ScreensFolder:WaitForChild("HomeScreen")),
	run    = require(ScreensFolder:WaitForChild("RunScreen")),
	shop   = require(ScreensFolder:WaitForChild("ShopScreen")),
	shrine = require(ScreensFolder:WaitForChild("ShrineScreen")),
}
Router.init(Screens)

Router.setDeps({
	playerGui = Players.LocalPlayer:WaitForChild("PlayerGui"),

	-- C→S
	Confirm=Confirm, ReqPick=ReqPick, ReqRerollAll=ReqRerollAll, ReqRerollHand=ReqRerollHand,
	ShopDone=ShopDone, BuyItem=BuyItem, ShopReroll=ShopReroll,
	ReqStartNewRun=ReqStartNewRun, ReqContinueRun=ReqContinueRun, ReqSyncUI=ReqSyncUI,
	DecideNext=DecideNext,

	-- S→C
	HandPush=HandPush, FieldPush=FieldPush, TakenPush=TakenPush, ScorePush=ScorePush, StatePush=StatePush,
	StageResult=StageResult,

	-- DEV
	DevGrantRyo=DevGrantRyo, DevGrantRole=DevGrantRole,

	-- 遷移ユーティリティ
	showRun    = function(payload) Router.show("run", payload) end,
	showHome   = function(payload) Router.show("home", payload) end,
	showShop   = function(payload) Router.show("shop", payload) end,
	showShrine = function(payload) Router.show("shrine", payload) end,

	-- 互換ネスト（旧コード呼び出し用）
	remotes = {
		Confirm=Confirm, ReqPick=ReqPick, ReqRerollAll=ReqRerollAll, ReqRerollHand=ReqRerollHand,
		ShopDone=ShopDone, BuyItem=BuyItem, ShopReroll=ShopReroll,
		ReqStartNewRun=ReqStartNewRun, ReqContinueRun=ReqContinueRun, ReqSyncUI=ReqSyncUI,
		HandPush=HandPush, FieldPush=FieldPush, TakenPush=TakenPush, ScorePush=ScorePush, StatePush=StatePush,
		StageResult=StageResult, DecideNext=DecideNext,
		DevGrantRyo=DevGrantRyo, DevGrantRole=DevGrantRole,
	},
})

--==================================================
-- Remote → 画面の表示/更新
--==================================================

-- トップ（帰宅先）
HomeOpen.OnClientEvent:Connect(function(payload)
	Router.show("home", payload)
end)

-- 屋台
ShopOpen.OnClientEvent:Connect(function(payload)
	Router.show("shop", payload)
end)

-- 新ラウンド準備完了 → Run画面を開いて「1回だけ再同期」
RoundReady.OnClientEvent:Connect(function()
	Router.show("run")
	Router.call("run", "requestSync")  -- RunScreen.requestSync()
end)

-- プレイ画面（状態/手札/場/取り札/得点）→ run へ転送
local function toRun(method, ...) Router.call("run", method, ...) end
StatePush.OnClientEvent:Connect(function(st)                toRun("onState", st) end)
HandPush .OnClientEvent:Connect(function(hand)              toRun("onHand", hand) end)
FieldPush.OnClientEvent:Connect(function(field)             toRun("onField", field) end)
TakenPush.OnClientEvent:Connect(function(taken)             toRun("onTaken", taken) end)
ScorePush.OnClientEvent:Connect(function(total,roles,dtl)   toRun("onScore", total, roles, dtl) end)

-- 起動時はHOMEを表示（自動開始はしない）
Router.show("home")

print("[ClientMain] ready")
