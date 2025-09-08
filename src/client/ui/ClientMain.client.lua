-- ClientMain.client.lua
-- 画面の振り分け（Router）と Remote 配線の入口 + 受信ログ（vararg「...」は一切不使用）
print("[ClientMain] boot")

--==================================================
-- Services / Folders / Remotes
--==================================================
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes")

-- Locale（現在言語の保持/参照）
local Locale  = require(RS:WaitForChild("Config"):WaitForChild("Locale"))

--============= S → C =============
local HomeOpen    = Remotes:WaitForChild("HomeOpen")
local ShopOpen    = Remotes:WaitForChild("ShopOpen")
local StatePush   = Remotes:WaitForChild("StatePush")
local HandPush    = Remotes:WaitForChild("HandPush")
local FieldPush   = Remotes:WaitForChild("FieldPush")
local TakenPush   = Remotes:WaitForChild("TakenPush")
local ScorePush   = Remotes:WaitForChild("ScorePush")
local RoundReady  = Remotes:WaitForChild("RoundReady")   -- ★ 新ラウンド準備完了
local StageResult = Remotes:WaitForChild("StageResult")  -- ★ 冬クリアの3択UI用（S→C）

--============= C → S =============
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
local ReqSetLang     = Remotes:WaitForChild("ReqSetLang") -- ★ 言語保存（C→S）

-- DEV（Studio用：無い場合もある）
local DevGrantRyo  = Remotes:FindFirstChild("DevGrantRyo")
local DevGrantRole = Remotes:FindFirstChild("DevGrantRole")

--==================================================
-- Screen Router 初期化（UI フォルダの有無に依らない）
--==================================================
local uiRoot = script.Parent:FindFirstChild("UI") or script.Parent

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

--==================================================
-- 依存注入（現在言語を常に注入）
--==================================================
Router.setDeps({
	playerGui = Players.LocalPlayer:WaitForChild("PlayerGui"),

	-- C→S
	Confirm=Confirm, ReqPick=ReqPick, ReqRerollAll=ReqRerollAll, ReqRerollHand=ReqRerollHand,
	ShopDone=ShopDone, BuyItem=BuyItem, ShopReroll=ShopReroll,
	ReqStartNewRun=ReqStartNewRun, ReqContinueRun=ReqContinueRun, ReqSyncUI=ReqSyncUI,
	DecideNext=DecideNext,
	ReqSetLang=ReqSetLang, -- ★ Homeからサーバへ言語保存依頼

	-- S→C
	HandPush=HandPush, FieldPush=FieldPush, TakenPush=TakenPush, ScorePush=ScorePush, StatePush=StatePush,
	StageResult=StageResult,

	-- DEV
	DevGrantRyo=DevGrantRyo, DevGrantRole=DevGrantRole,

	-- 遷移ユーティリティ（現在言語を常に注入）
	showRun    = function(payload)
		local p = payload or {}
		if p.lang == nil then
			p.lang = (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
		end
		Router.show("run", p)
	end,
	showHome   = function(payload)
		local p = payload or {}
		if p.lang == nil then
			p.lang = (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
		end
		Router.show("home", p)
	end,
	showShop   = function(payload)
		local p = payload or {}
		if p.lang == nil then
			p.lang = (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
		end
		Router.show("shop", p)
	end,
	showShrine = function()
		Router.show("shrine", { lang = (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en" })
	end,

	-- 互換ネスト（古いコードのために維持）
	remotes = {
		Confirm=Confirm, ReqPick=ReqPick, ReqRerollAll=ReqRerollAll, ReqRerollHand=ReqRerollHand,
		ShopDone=ShopDone, BuyItem=BuyItem, ShopReroll=ShopReroll,
		ReqStartNewRun=ReqStartNewRun, ReqContinueRun=ReqContinueRun, ReqSyncUI=ReqSyncUI,
		HandPush=HandPush, FieldPush=FieldPush, TakenPush=TakenPush, ScorePush=ScorePush, StatePush=StatePush,
		StageResult=StageResult,
		DecideNext=DecideNext,
		ReqSetLang=ReqSetLang,
		DevGrantRyo=DevGrantRyo, DevGrantRole=DevGrantRole,
	},
})

--==================================================
-- Remote → 画面の表示/更新（デバッグログ付き）
--==================================================

-- トップ（帰宅先）
HomeOpen.OnClientEvent:Connect(function(payload)
	-- ★ payload.lang を共有へ反映してから Home を開く
	if payload and payload.lang and typeof(Locale.setGlobal) == "function" then
		Locale.setGlobal(payload.lang)
		print("[LANG_FLOW] ClientMain.HomeOpen setGlobal ->", payload.lang)
	end
	print("[ClientMain] HomeOpen", typeof(payload), payload and payload.lang)
	Router.show("home", payload)
end)

-- 屋台
ShopOpen.OnClientEvent:Connect(function(payload)
	print("[ClientMain] ShopOpen", typeof(payload))
	-- 言語が無ければ現在言語で補完
	local p = payload or {}
	if p.lang == nil then
		p.lang = (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
	end
	Router.show("shop", p)
end)

-- ★ RoundReady：Run を開く前に setLang → その後 requestSync（デバウンス付き）
local roundReadyBusy = false
RoundReady.OnClientEvent:Connect(function()
	if roundReadyBusy then
		print("[ClientMain] RoundReady ignored (busy)")
		return
	end
	roundReadyBusy = true

	local lang = (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
	print("[ClientMain] RoundReady → show(run)+setLang(" .. tostring(lang) .. ")+requestSync")

	-- 1) 画面インスタンスの確保
	Router.show("run")

	-- 2) ランタイム言語の明示適用（直接呼ぶ：vararg不使用）
	if Router and typeof(Router.call)=="function" then
		Router.call("run", "setLang", lang)
		Router.call("run", "requestSync")
	end

	task.defer(function() roundReadyBusy = false end)
end)

-- プレイ画面（状態/手札/場/取り札/得点）→ run へ転送（vararg不使用で個別に転送）
StatePush.OnClientEvent:Connect(function(st)
	-- state から lang が来る場合は現在言語を同期（保険）
	if st and st.lang and (st.lang == "jp" or st.lang == "en") and typeof(Locale.setGlobal)=="function" then
		Locale.setGlobal(st.lang)
	end
	print(("[ClientMain] StatePush season=%s deckLeft=%s handLeft=%s"):format(
		tostring(st and st.season), tostring(st and st.deckLeft), tostring(st and st.handLeft)))
	if Router and typeof(Router.call)=="function" then
		Router.call("run", "onState", st)
	end
end)

HandPush.OnClientEvent:Connect(function(hand)
	print("[ClientMain] HandPush recv", typeof(hand), #(hand or {}))
	if Router and typeof(Router.call)=="function" then
		Router.call("run", "onHand", hand)
	end
end)

FieldPush.OnClientEvent:Connect(function(field)
	print("[ClientMain] FieldPush recv", typeof(field), #(field or {}))
	if Router and typeof(Router.call)=="function" then
		Router.call("run", "onField", field)
	end
end)

TakenPush.OnClientEvent:Connect(function(taken)
	print("[ClientMain] TakenPush recv", typeof(taken), #(taken or {}))
	if Router and typeof(Router.call)=="function" then
		Router.call("run", "onTaken", taken)
	end
end)

ScorePush.OnClientEvent:Connect(function(total, roles, dtl)
	print("[ClientMain] ScorePush recv types:", typeof(total), typeof(roles), typeof(dtl))
	if Router and typeof(Router.call)=="function" then
		-- 引数は明示3つ（vararg不使用）
		Router.call("run", "onScore", total, roles, dtl)
	end
end)

-- ★ 冬クリア（3択モーダル表示）— フォワード（RunScreenが直接listenする場合の保険）
StageResult.OnClientEvent:Connect(function(payload)
	print("[ClientMain] StageResult recv", typeof(payload))
	if Router and typeof(Router.call)=="function" then
		Router.call("run", "onStageResult", payload)
	end
end)

print("[ClientMain] ready")
