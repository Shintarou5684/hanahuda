-- ServerScriptService/GameInit.server.lua
-- モジュール分割版のエントリポイント（Remotesの生成＆各Serviceの初期化）
-- ★ DataStore最小実装対応：bank / year のロード＆保存（SaveService）

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local SSS     = game:GetService("ServerScriptService")

--==================================================
-- SaveService（bank/year の永続化）
--==================================================
local SaveService = require(SSS:WaitForChild("SaveService"))

--==================================================
-- Remotes を用意（全てここで先に生やす）
--==================================================
local function ensureRemote(name: string)
	local rem = RS:FindFirstChild("Remotes")
	if not rem then
		rem = Instance.new("Folder")
		rem.Name = "Remotes"
		rem.Parent = RS
	end
	local e = rem:FindFirstChild(name)
	if not e then
		e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = rem
	end
	return e
end

-- 必要なリモートを全列挙（先生成）
local Remotes = {
	-- 表示系
	HandPush      = ensureRemote("HandPush"),
	FieldPush     = ensureRemote("FieldPush"),
	TakenPush     = ensureRemote("TakenPush"),
	ScorePush     = ensureRemote("ScorePush"),
	StatePush     = ensureRemote("StatePush"),

	-- 結果/遷移
	StageResult   = ensureRemote("StageResult"),
	DecideNext    = ensureRemote("DecideNext"),

	-- 操作（プレイ）
	ReqPick       = ensureRemote("ReqPick"),
	Confirm       = ensureRemote("Confirm"),
	ReqRerollAll  = ensureRemote("ReqRerollAll"),
	ReqRerollHand = ensureRemote("ReqRerollHand"),

	-- 屋台（ショップ）
	ShopOpen      = ensureRemote("ShopOpen"),
	ShopDone      = ensureRemote("ShopDone"),
	BuyItem       = ensureRemote("BuyItem"),
	ShopReroll    = ensureRemote("ShopReroll"),

	-- 同期（C→S 一回だけの再同期要求）※ ハンドリングは UiResync.server.lua 側
	ReqSyncUI     = ensureRemote("ReqSyncUI"),
}

--=== TOP/HOME Remotes ===
local HomeOpen        = ensureRemote("HomeOpen")        -- S->C: トップページを開く
local ReqStartNewRun  = ensureRemote("ReqStartNewRun")  -- C->S: NEW GAME
local ReqContinueRun  = ensureRemote("ReqContinueRun")  -- C->S: 前回の続き
local RoundReady      = ensureRemote("RoundReady")      -- S->C: ★ 新ラウンド準備完了通知

-- Remotes からも参照できるように
Remotes.HomeOpen       = HomeOpen
Remotes.ReqStartNewRun = ReqStartNewRun
Remotes.ReqContinueRun = ReqContinueRun
Remotes.RoundReady     = RoundReady

--==================================================
-- DEV Remotes（Server / +役 は 3枚注入）
--==================================================
local StateHub = require(RS.SharedModules.StateHub)
local Scoring  = require(RS.SharedModules.Scoring)

local DevGrantRyo  = ensureRemote("DevGrantRyo")
local DevGrantRole = ensureRemote("DevGrantRole")

DevGrantRyo.OnServerEvent:Connect(function(plr, amount)
	amount = tonumber(amount) or 1000
	local s = StateHub.get(plr); if not s then return end
	-- メモリ状態に反映
	s.bank = (s.bank or 0) + amount
	StateHub.pushState(plr, s)
	-- 永続にも反映（dirty化）
	SaveService.addBank(plr, amount)
end)

local function ensureTable(t) return (type(t)=="table") and t or {} end
local function takeByPredOrStub(s, pred, stub)
	s.board = ensureTable(s.board); s.taken = ensureTable(s.taken)
	for i,card in ipairs(s.board) do
		if pred(card) then
			table.insert(s.taken, card)
			table.remove(s.board, i)
			return
		end
	end
	local c = table.clone(stub)
	c.id = c.id or ("dev_"..(c.name or ("m"..(c.month or 0))))
	c.tags = c.tags or {}
	table.insert(s.taken, c)
end

DevGrantRole.OnServerEvent:Connect(function(plr)
	local s = StateHub.get(plr); if not s then return end
	takeByPredOrStub(s,
		function(c) return c.month==9 and ((c.tags and table.find(c.tags,"sake")) or c.name=="盃") end,
		{month=9, kind="seed", name="盃", tags={"thing","sake"}}
	)
	takeByPredOrStub(s,
		function(c) return c.month==8 and c.kind=="bright" end,
		{month=8, kind="bright", name="芒に月"}
	)
	takeByPredOrStub(s,
		function(c) return c.month==3 and c.kind=="bright" end,
		{month=3, kind="bright", name="桜に幕"}
	)
	local total, roles, detail = Scoring.evaluate(s.taken or {})
	s.lastScore = { total=total, roles=roles, detail=detail }
	StateHub.pushState(plr, s)
end)

--==================================================
-- サービス読み込み
--==================================================
local Round        = require(RS.SharedModules.RoundService)
local PickService  = require(RS.SharedModules.PickService)
local Reroll       = require(RS.SharedModules.RerollService)
local Score        = require(RS.SharedModules.ScoreService)
local ShopService  = require(RS.SharedModules.ShopService)

--==================================================
-- 初期化／バインド
--==================================================

-- Remotesを一括で渡す（StateHub は push 時に Remotes.* を使う）
StateHub.init(Remotes)

if PickService and typeof(PickService.bind) == "function" then
	PickService.bind(Remotes)
else
	warn("[GameInit] PickService.bind が見つかりません")
end

if Reroll and typeof(Reroll.bind) == "function" then
	Reroll.bind(Remotes)
else
	warn("[GameInit] Reroll.bind が見つかりません")
end

if Score and typeof(Score.bind) == "function" then
	-- ScoreService には openShop を依存注入
	Score.bind(Remotes, { openShop = ShopService and ShopService.open })
else
	warn("[GameInit] Score.bind が見つかりません")
end

if ShopService and typeof(ShopService.init) == "function" then
	ShopService.init(
		function(plr) return StateHub.get(plr) end,
		function(plr) StateHub.pushState(plr) end
	)
else
	warn("[GameInit] ShopService.init が見つかりません")
end

--==================================================
-- Player Added / Removing（永続のロードと保存）
--==================================================
Players.PlayerAdded:Connect(function(plr)
	-- プロファイルをロード（{bank, year}）
	local prof = SaveService.load(plr)

	-- 既存のStateに bank/year をマージ（他は触らない）
	local s = StateHub.get(plr) or {}
	s.bank = prof.bank or 0
	s.year = prof.year or 0
	StateHub.set(plr, s)

	-- 初回はトップを開く（UIで使うなら bank/year を同梱）
	HomeOpen:FireClient(plr, { hasSave = false, bank = s.bank, year = s.year })
end)

Players.PlayerRemoving:Connect(function(plr)
	-- 退室時に保存（失敗時は warn のみ）
	SaveService.flush(plr)
end)

-- サーバ終了時の保険（任意）
game:BindToClose(function()
	-- なるべく保存を試みる
	pcall(function() SaveService.flushAll() end)
end)

--==================================================
-- ラン開始/続き（RoundReady → RunScreen.requestSync → UiResync）
--==================================================
local function startSeason(plr, opts)
	-- ラン全体の初期化
	Round.resetRun(plr, opts)
	-- ★ ここで必ず今季の山/手/場を生成
	Round.newRound(plr)
	-- ★ 少し待ってから準備完了を通知（0残像対策）
	task.delay(0.05, function()
		RoundReady:FireClient(plr)
	end)
end

ReqStartNewRun.OnServerEvent:Connect(function(plr)
	startSeason(plr, { fresh = true })
end)

ReqContinueRun.OnServerEvent:Connect(function(plr)
	-- まだCONTINUE実装がないので NEW GAME と同様に扱う
	warn(("[Home] ReqContinueRun by %s: fallback NEW GAME."):format(plr.Name))
	startSeason(plr, { fresh = true })
end)

--==================================================
-- 屋台 → 次シーズン遷移
--==================================================
Remotes.ShopDone.OnServerEvent:Connect(function(plr: Player)
	local s = StateHub.get(plr); if not s then return end
	if s.phase ~= "shop" then return end

	-- 前季のスコア情報は破棄（画面再同期時の誤表示を防ぐ）
	s.lastScore = nil
	s.phase = "play"

	local nextSeason = (s.season or 1) + 1
	if nextSeason > 4 then
		-- 冬→春はランリセットから
		Round.resetRun(plr)
		Round.newRound(plr)
	else
		Round.newRound(plr, nextSeason)
	end

	task.delay(0.05, function()
		RoundReady:FireClient(plr)
	end)
end)

--==================================================
-- 達成後：冬専用 3択（StageResult）→ DecideNext
--==================================================
-- DecideNext の引数：op = "home" | "next" | "save"
Remotes.DecideNext.OnServerEvent:Connect(function(plr: Player, op: string)
	local s = StateHub.get(plr); if not s then return end
	if (s.season or 1) ~= 4 then return end

	-- ★ 冬クリア時の精算は ScoreService 側で「+2両」を付与済み
	--   ここでは倍率等を初期化するだけ
	s.mult = 1.0

	if op == "home" then
		-- 帰宅カウントでアンロック管理（暫定：メモリのみ）
		s.homeCount = (s.homeCount or 0) + 1
		StateHub.pushState(plr) -- 表示更新用

		-- トップへ
		Round.resetRun(plr) -- 内部は初期化しておく
		Remotes.HomeOpen:FireClient(plr, { hasSave = false, homeCount = s.homeCount })
		return

	elseif op == "next" then
		-- 25年進行＋屋台オープン（次ランの前準備）
		s.year = (s.year or 0) + 25
		SaveService.setYear(plr, s.year)

		s.phase = "shop"
		if ShopService and typeof(ShopService.open) == "function" then
			ShopService.open(plr, s, { reason = "after_winter" })
		end
		return

	elseif op == "save" then
		-- DataStore 未実装：将来対応（とりあえずホームへ戻す）
		warn("[DecideNext] save is not implemented yet; go Home.")
		Round.resetRun(plr)
		Remotes.HomeOpen:FireClient(plr, { hasSave = true })
		return

	else
		warn(("[DecideNext] unknown op: %s"):format(tostring(op)))
	end
end)

print("[Init] Game loaded (modularized, remotes-ready, save-ready)")
