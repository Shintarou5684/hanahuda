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
local okLocale, Locale = pcall(function()
	return require(RS:WaitForChild("Config"):WaitForChild("Locale"))
end)
if not okLocale or type(Locale) ~= "table" then
	-- フォールバック：最低限の get/set だけ持つダミー
	warn("[ClientMain] Locale module missing; using fallback")
	local _g = "en"
	Locale = {}
	function Locale.getGlobal() return _g end
	function Locale.setGlobal(v)
		if v == "ja" or v == "jp" then _g = "jp" else _g = "en" end
	end
end

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

-- Router 読み込み＋フォールバックスタブ
local Router
do
	local ok, mod = pcall(require, ScreenRouterModule)
	if not ok then
		warn("[ClientMain] require(ScreenRouter) failed; using stub Router:", mod)
		mod = {}
	end
	if type(mod) ~= "table" then mod = {} end
	-- 欠けているAPIはスタブ化（fatalを避ける）
	mod.init    = (type(mod.init)    == "function") and mod.init    or function(_) end
	mod.setDeps = (type(mod.setDeps) == "function") and mod.setDeps or function(_) end
	mod.show    = (type(mod.show)    == "function") and mod.show    or function(_) end
	mod.call    = (type(mod.call)    == "function") and mod.call    or function() end
	Router = mod
end

-- 画面モジュール
local Screens = {
	home   = require(ScreensFolder:WaitForChild("HomeScreen")),
	run    = require(ScreensFolder:WaitForChild("RunScreen")),
	shop   = require(ScreensFolder:WaitForChild("ShopScreen")),
	shrine = require(ScreensFolder:WaitForChild("ShrineScreen")),
}

-- Router 起動
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
			p.lang = (type(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
		end
		Router.show("run", p)
	end,
	showHome   = function(payload)
		local p = payload or {}
		if p.lang == nil then
			p.lang = (type(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
		end
		Router.show("home", p)
	end,
	showShop   = function(payload)
		local p = payload or {}
		if p.lang == nil then
			p.lang = (type(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
		end
		Router.show("shop", p)
	end,
	showShrine = function()
		Router.show("shrine", { lang = (type(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en" })
	end,

	-- 軽量トースト（屋台MVPで使用）
	toast = function(msg, dur)
		pcall(function()
			game.StarterGui:SetCore("SendNotification", {
				Title = "通知",
				Text = msg,
				Duration = dur or 2,
			})
		end)
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
	if payload and payload.lang and type(Locale.setGlobal) == "function" then
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
		p.lang = (type(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
	end
	-- ★ ScreenRouter v0.9.1 で、同一画面でも update/show が走る
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

	local lang = (type(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
	print("[ClientMain] RoundReady → show(run)+setLang(" .. tostring(lang) .. ")+requestSync")

	-- 1) 画面インスタンスの確保
	Router.show("run")

	-- 2) ランタイム言語の明示適用（直接呼ぶ：vararg不使用）
	if Router and type(Router.call)=="function" then
		Router.call("run", "setLang", lang)
		Router.call("run", "requestSync")
	end

	task.defer(function() roundReadyBusy = false end)
end)

-- プレイ画面（状態/手札/場/取り札/得点）→ run へ転送（vararg不使用で個別に転送）
StatePush.OnClientEvent:Connect(function(st)
	-- state から lang が来たら現在言語を同期（ja/jp/en を許容）
	if st and st.lang and type(Locale.setGlobal)=="function" then
		local l = tostring(st.lang)
		if l == "ja" or l == "jp" or l == "en" then
			Locale.setGlobal(l)
		end
	end
	print(("[ClientMain] StatePush season=%s deckLeft=%s handLeft=%s"):format(
		tostring(st and st.season), tostring(st and st.deckLeft), tostring(st and st.handLeft)))
	if Router and type(Router.call)=="function" then
		Router.call("run", "onState", st)
	end
end)

HandPush.OnClientEvent:Connect(function(hand)
	print("[ClientMain] HandPush recv", typeof(hand), #(hand or {}))
	if Router and type(Router.call)=="function" then
		Router.call("run", "onHand", hand)
	end
end)

FieldPush.OnClientEvent:Connect(function(field)
	print("[ClientMain] FieldPush recv", typeof(field), #(field or {}))
	if Router and type(Router.call)=="function" then
		Router.call("run", "onField", field)
	end
end)

TakenPush.OnClientEvent:Connect(function(taken)
	print("[ClientMain] TakenPush recv", typeof(taken), #(taken or {}))
	if Router and type(Router.call)=="function" then
		Router.call("run", "onTaken", taken)
	end
end)

ScorePush.OnClientEvent:Connect(function(total, roles, dtl)
	print("[ClientMain] ScorePush recv types:", typeof(total), typeof(roles), typeof(dtl))
	if Router and type(Router.call)=="function" then
		-- 引数は明示3つ（vararg不使用）
		Router.call("run", "onScore", total, roles, dtl)
	end
end)

-- ★ 冬クリア（3択モーダル表示）— フォワード（RunScreenが直接listenする場合の保険）
StageResult.OnClientEvent:Connect(function(payload)
	print("[ClientMain] StageResult recv", typeof(payload))
	if Router and type(Router.call)=="function" then
		Router.call("run", "onStageResult", payload)
	end
end)

print("[ClientMain] ready")
