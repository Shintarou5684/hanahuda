-- GameInit.server.lua  v0.8.2
-- 役割：全Remote生成／各Service初期化／トップ遷移／季節遷移／ラウンド準備通知
-- ※ 最初は必ず Home を開きます（自動でラン開始しません）

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

--==================================================
-- Remotes（必ず先に生やす）
--==================================================
local Remotes = Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = RS

local function newRemote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = Remotes
	return r
end

-- S→C
local HomeOpen   = newRemote("HomeOpen")
local ShopOpen   = newRemote("ShopOpen")
local StatePush  = newRemote("StatePush")
local HandPush   = newRemote("HandPush")
local FieldPush  = newRemote("FieldPush")
local TakenPush  = newRemote("TakenPush")
local ScorePush  = newRemote("ScorePush")
local RoundReady = newRemote("RoundReady")

-- C→S
local ReqStartNewRun = newRemote("ReqStartNewRun")
local ReqContinueRun = newRemote("ReqContinueRun")
local Confirm        = newRemote("Confirm")
local ReqRerollAll   = newRemote("ReqRerollAll")
local ReqRerollHand  = newRemote("ReqRerollHand")
local ShopDone       = newRemote("ShopDone")
local BuyItem        = newRemote("BuyItem")
local ShopReroll     = newRemote("ShopReroll")
local ReqPick        = newRemote("ReqPick")
local ReqSyncUI      = newRemote("ReqSyncUI")

-- DEV
local DevGrantRyo  = newRemote("DevGrantRyo")
local DevGrantRole = newRemote("DevGrantRole")

print("[RemotesBootstrap] wiring...")

--==================================================
-- SharedModules 読み込み
--==================================================
local Shared = RS:WaitForChild("SharedModules")
local StateHub     = require(Shared:WaitForChild("StateHub"))
local RoundService = require(Shared:WaitForChild("RoundService"))
local PickService  = require(Shared:WaitForChild("PickService"))
local Reroll       = require(Shared:WaitForChild("RerollService"))
local Score        = require(Shared:WaitForChild("ScoreService"))
local ShopService  = require(Shared:WaitForChild("ShopService"))

-- ScoreService ←→ ShopService の依存注入（循環回避）
Score.bind(Remotes, {
	openShop = function(plr, s, opts)
		ShopService.open(plr, s, Remotes, opts)
	end
})

--==================================================
-- ヘルパ：状態を一括Push（UiResyncからも呼ばれる）
--==================================================
local function pushAll(plr, s)
	-- ハンドなどは nil セーフで送る（クライアント側は空で描く）
	HandPush :FireClient(plr, s and s.hand   or {})
	FieldPush:FireClient(plr, s and s.board  or {})
	TakenPush:FireClient(plr, s and s.taken  or {})
	local total, roles, detail = Score.lastScoreFor(s) -- なければ 0/{} に寄せる
	ScorePush:FireClient(plr, total or 0, roles or {}, detail or {mon=0,pts=0})
	StateHub.pushState(plr, s, Remotes) -- これが StatePush を正規経路で送る
end

--==================================================
-- イベント配線（C→S）
--==================================================
ReqStartNewRun.OnServerEvent:Connect(function(plr)
	local s = RoundService.resetRun(plr)
	RoundReady:FireClient(plr)   -- クライアントに「Run画面を開いて同期開始してね」
end)

ReqContinueRun.OnServerEvent:Connect(function(plr)
	-- まだ未実装：当面は NEW RUN と同等にしておく
	local s = RoundService.resetRun(plr)
	RoundReady:FireClient(plr)
end)

ReqPick.OnServerEvent:Connect(function(plr, handIdx, boardIdx)
	local s = StateHub.require(plr)
	PickService.pick(plr, s, handIdx, boardIdx, Remotes)
end)

Confirm.OnServerEvent:Connect(function(plr)
	local s = StateHub.require(plr)
	Score.confirm(plr, s, Remotes) -- 達成時は ShopOpen を送る
end)

ReqRerollAll.OnServerEvent:Connect(function(plr)
	local s = StateHub.require(plr)
	Reroll.all(plr, s, Remotes)
end)

ReqRerollHand.OnServerEvent:Connect(function(plr)
	local s = StateHub.require(plr)
	Reroll.hand(plr, s, Remotes)
end)

BuyItem.OnServerEvent:Connect(function(plr, itemId)
	local s = StateHub.require(plr)
	ShopService.buy(plr, s, Remotes, itemId)
end)

ShopReroll.OnServerEvent:Connect(function(plr)
	local s = StateHub.require(plr)
	ShopService.reroll(plr, s, Remotes)
end)

ShopDone.OnServerEvent:Connect(function(plr)
	local s = StateHub.require(plr)
	-- 冬→春は resetRun、他季は newRound
	if s.season >= 4 then
		s = RoundService.resetRun(plr)
	else
		s = RoundService.newRound(plr)
	end
	s.lastScore = nil -- 季節跨ぎの残留対策
	RoundReady:FireClient(plr)
end)

-- DEV
DevGrantRyo.OnServerEvent:Connect(function(plr, amount)
	local s = StateHub.require(plr)
	s.bank = (s.bank or 0) + (tonumber(amount) or 1000)
	StateHub.pushState(plr, s, Remotes)
end)

DevGrantRole.OnServerEvent:Connect(function(plr)
	local s = StateHub.require(plr)
	Score.devGrantRole(plr, s, Remotes)
end)

-- 同期要求（UiResync.server からもやるが保険としてここでも処理可）
ReqSyncUI.OnServerEvent:Connect(function(plr)
	local s = StateHub.get(plr)
	if s then pushAll(plr, s) end
end)

--==================================================
-- PlayerAdded：最初に必ず Home を表示する
--==================================================
Players.PlayerAdded:Connect(function(plr)
	-- ここでは run を開始しない。トップメニューだけ開く。
	HomeOpen:FireClient(plr, {
		canContinue = false, -- 将来のセーブ実装向け
		bank = 0,
	})
end)

Players.PlayerRemoving:Connect(function(plr)
	-- TODO: 将来セーブするならここで
end)

print("[RemotesBootstrap] ready")
print("[Init] Game loaded (modularized, remotes-ready, save-ready)")
