-- ClientMain.client.lua
-- 画面の振り分け（Router）と Remote 配線の入口 + 受信ログ

print("[ClientMain] boot")

--==================================================
-- Services / Folders / Remotes
--==================================================
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes")

-- S→C
local HomeOpen    = Remotes:WaitForChild("HomeOpen")
local ShopOpen    = Remotes:WaitForChild("ShopOpen")
local StatePush   = Remotes:WaitForChild("StatePush")
local HandPush    = Remotes:WaitForChild("HandPush")
local FieldPush   = Remotes:WaitForChild("FieldPush")
local TakenPush   = Remotes:WaitForChild("TakenPush")
local ScorePush   = Remotes:WaitForChild("ScorePush")
local RoundReady  = Remotes:WaitForChild("RoundReady")   -- ★ 新ラウンド準備完了
local StageResult = Remotes:WaitForChild("StageResult")  -- ★ 冬クリアの3択UI用（S→C）

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
local DecideNext     = Remotes:WaitForChild("DecideNext") -- ★ 冬クリア後の決定（C→S）

-- DEV（Studio用：無い場合もある）
local DevGrantRyo  = Remotes:FindFirstChild("DevGrantRyo")
local DevGrantRole = Remotes:FindFirstChild("DevGrantRole")

--==================================================
-- Screen Router 初期化（UI フォルダの有無に依らない）
--==================================================
-- uiRoot は ① script.Parent/UI があればそれ、②無ければ script.Parent 直下を使う
local uiRoot = script.Parent:FindFirstChild("UI") or script.Parent

-- ScreenRouter と screens フォルダも、存在チェックしつつ取得
local ScreenRouterModule = uiRoot:FindFirstChild("ScreenRouter") or uiRoot:WaitForChild("ScreenRouter")
local ScreensFolder      = uiRoot:FindFirstChild("screens")      or uiRoot:WaitForChild("screens")
local Router             = require(ScreenRouterModule)

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
	showRun    = function() Router.show("run") end,
	showHome   = function(payload) Router.show("home", payload) end,
	showShop   = function(payload) Router.show("shop", payload) end,
	showShrine = function() Router.show("shrine") end,

	-- 互換ネスト（古いコードのために維持）
	remotes = {
		Confirm=Confirm, ReqPick=ReqPick, ReqRerollAll=ReqRerollAll, ReqRerollHand=ReqRerollHand,
		ShopDone=ShopDone, BuyItem=BuyItem, ShopReroll=ShopReroll,
		ReqStartNewRun=ReqStartNewRun, ReqContinueRun=ReqContinueRun, ReqSyncUI=ReqSyncUI,
		HandPush=HandPush, FieldPush=FieldPush, TakenPush=TakenPush, ScorePush=ScorePush, StatePush=StatePush,
		StageResult=StageResult,
		DecideNext=DecideNext,
		DevGrantRyo=DevGrantRyo, DevGrantRole=DevGrantRole,
	},
})

--==================================================
-- Remote → 画面の表示/更新（デバッグログ付き）
--==================================================

-- トップ（帰宅先）
HomeOpen.OnClientEvent:Connect(function(payload)
	print("[ClientMain] HomeOpen", typeof(payload))
	Router.show("home", payload)
end)

-- 屋台
ShopOpen.OnClientEvent:Connect(function(payload)
	print("[ClientMain] ShopOpen", typeof(payload))
	Router.show("shop", payload)
end)

-- ★ 新ラウンド準備完了 → Run画面を開いて「1回だけ再同期」させる
RoundReady.OnClientEvent:Connect(function()
	print("[ClientMain] RoundReady → show(run)+requestSync")
	Router.show("run")
	Router.call("run", "requestSync")  -- RunScreen.requestSync() を呼ぶ
end)

-- プレイ画面（状態/手札/場/取り札/得点）→ run へ転送
local function f(method, ...)
	-- print("[ClientMain] call run:", method)
	Router.call("run", method, ...)
end

StatePush.OnClientEvent:Connect(function(st)
	print(("[ClientMain] StatePush season=%s deckLeft=%s handLeft=%s"):format(
		tostring(st and st.season), tostring(st and st.deckLeft), tostring(st and st.handLeft)))
	f("onState", st)
end)

HandPush.OnClientEvent:Connect(function(hand)
	print("[ClientMain] HandPush recv", typeof(hand), #(hand or {}))
	f("onHand", hand)
end)

FieldPush.OnClientEvent:Connect(function(field)
	print("[ClientMain] FieldPush recv", typeof(field), #(field or {}))
	f("onField", field)
end)

TakenPush.OnClientEvent:Connect(function(taken)
	print("[ClientMain] TakenPush recv", typeof(taken), #(taken or {}))
	f("onTaken", taken)
end)

ScorePush.OnClientEvent:Connect(function(total, roles, dtl)
	-- 型だけ出す（UI側で安全化しているのでここは軽め）
	print("[ClientMain] ScorePush recv types:", typeof(total), typeof(roles), typeof(dtl))
	f("onScore", total, roles, dtl)
end)

-- ★ 冬クリア（3択モーダル表示）— フォワード（RunScreenが直接listenする場合の保険）
StageResult.OnClientEvent:Connect(function(payload)
	print("[ClientMain] StageResult recv", typeof(payload))
	f("onStageResult", payload)
end)

print("[ClientMain] ready")
