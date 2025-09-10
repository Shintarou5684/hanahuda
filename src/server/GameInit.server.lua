-- ServerScriptService/GameInit.server.lua
-- エントリポイント：Remotes生成／各Service初期化／永続（SaveService）連携

--==================================================
-- Services
--==================================================
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local SSS     = game:GetService("ServerScriptService")

--==================================================
-- SaveService（bank/year/clears/lang の永続化）
--==================================================
local SaveService = require(SSS:WaitForChild("SaveService"))

--==================================================
-- Remotes 生成（すべてここで先に生やす）
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

-- Core push系
local Remotes = {
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

	-- 同期（C→S：再同期要求。実処理は UiResync.server.lua）
	ReqSyncUI     = ensureRemote("ReqSyncUI"),
}

-- Top/Home 系
local HomeOpen        = ensureRemote("HomeOpen")        -- S→C: トップを開く
local ReqStartNewRun  = ensureRemote("ReqStartNewRun")  -- C→S: NEW GAME
local ReqContinueRun  = ensureRemote("ReqContinueRun")  -- C→S: CONTINUE（現状NEW扱い）
local RoundReady      = ensureRemote("RoundReady")      -- S→C: 新ラウンド準備完了
local ReqSetLang      = ensureRemote("ReqSetLang")      -- C→S: 言語保存

-- Remotes からも参照できるように追加
Remotes.HomeOpen       = HomeOpen
Remotes.ReqStartNewRun = ReqStartNewRun
Remotes.ReqContinueRun = ReqContinueRun
Remotes.RoundReady     = RoundReady
Remotes.ReqSetLang     = ReqSetLang

--==================================================
-- Server-side modules
--==================================================
local StateHub = require(RS.SharedModules.StateHub)
local Scoring  = require(RS.SharedModules.Scoring)

local Round        = require(RS.SharedModules.RoundService)
local PickService  = require(RS.SharedModules.PickService)
local Reroll       = require(RS.SharedModules.RerollService)
local Score        = require(RS.SharedModules.ScoreService)
local ShopService  = require(RS.SharedModules.ShopService)

--==================================================
-- DEV Remotes（Studio向け：+両 / +役 付与）
--==================================================
local DevGrantRyo  = ensureRemote("DevGrantRyo")
local DevGrantRole = ensureRemote("DevGrantRole")

DevGrantRyo.OnServerEvent:Connect(function(plr, amount)
	amount = tonumber(amount) or 1000
	local s = StateHub.get(plr); if not s then return end
	s.bank = (s.bank or 0) + amount                -- メモリ状態
	StateHub.pushState(plr, s)
	SaveService.addBank(plr, amount)               -- 永続もdirty化
end)

local function ensureTable(t) return (type(t)=="table") and t or {} end
local function takeByPredOrStub(s, pred, stub)
	s.board = ensureTable(s.board); s.taken = ensureTable(s.taken)
	for i,card in ipairs(s.board) do
		if pred(card) then
			table.insert(s.taken, card); table.remove(s.board, i); return
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
	takeByPredOrStub(s, function(c) return c.month==8 and c.kind=="bright" end, {month=8, kind="bright", name="芒に月"})
	takeByPredOrStub(s, function(c) return c.month==3 and c.kind=="bright" end, {month=3, kind="bright", name="桜に幕"})

	-- ★ 修正ポイント：未定義の takenCards/state ではなく、s.taken と s を渡す
	local total, roles, detail = Scoring.evaluate(s.taken or {}, s)

	s.lastScore = { total = total or 0, roles = roles, detail = detail }
	StateHub.pushState(plr) -- 第2引数は不要（あっても問題ないが省略でOK）
end)


--==================================================
-- 初期化／バインド
--==================================================
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
-- Player lifecycle：永続ロード/保存 + 言語トレースログ
--==================================================

-- 共有ミニロガー（サーバ用）
local function S(tag, msg, kv)
	-- kv は {k=v, ...} or nil
	local parts = {}
	if type(kv)=="table" then
		for k,v in pairs(kv) do
			table.insert(parts, (tostring(k).."="..tostring(v)))
		end
	end
	print(("[LANG_FLOW][S] %-16s | %s%s"):format(tag, msg or "", (#parts>0) and (" | "..table.concat(parts," ")) or ""))
end

Players.PlayerAdded:Connect(function(plr)
	-- 1) 入力：ロード直前
	S("PlayerAdded", "begin load profile", {user=plr.Name, userId=plr.UserId})

	-- 2) プロファイルをロード（保存>OS で lang 決定）
	local prof = SaveService.load(plr)
	S("load.done", "profile loaded", {
		user=plr.Name,
		bank=prof and prof.bank,
		year=prof and prof.year,
		asc =prof and prof.asc,
		clears=prof and prof.clears,
		lang=prof and prof.lang
	})

	-- 3) State に bank/year/clears/lang をマージして確定
	local s = StateHub.get(plr) or {}
	local beforeLang = s.lang
	s.bank        = prof.bank   or 0
	s.year        = prof.year   or 0
	s.totalClears = prof.clears or 0
	s.lang        = (prof.lang == "jp" and "jp") or "en"
	StateHub.set(plr, s)

	S("state.set", "state merged & set", {
		user=plr.Name,
		beforeLang=beforeLang,
		stateLang=s.lang,
		bank=s.bank, year=s.year, clears=s.totalClears
	})

	-- 4) HomeOpen（トップ表示）に保存言語を必ず同梱
	S("HomeOpen→C", "send payload to client", {
		user=plr.Name,
		payloadLang=s.lang,
		hasSave=false, bank=s.bank, year=s.year, clears=s.totalClears or 0
	})

	HomeOpen:FireClient(plr, {
		hasSave = false,
		bank    = s.bank,
		year    = s.year,
		clears  = s.totalClears or 0,
		lang    = s.lang,
	})
end)

Players.PlayerRemoving:Connect(function(plr)
	S("PlayerRemoving", "flush profile", {user=plr.Name})
	SaveService.flush(plr) -- 退室時の保存（失敗時は内部でwarn）
end)

game:BindToClose(function()
	S("BindToClose", "flushAll begin")
	pcall(function() SaveService.flushAll() end) -- サーバ終了時の保険
	S("BindToClose", "flushAll end")
end)

--==================================================
-- ラン開始/続き（RoundReady → RunScreen.requestSync → UiResync）
--==================================================
local function startSeason(plr, opts)
	Round.resetRun(plr, opts)     -- ラン全体の初期化（内部で newRound(1) まで）
	task.delay(0.05, function()   -- 0残像対策
		RoundReady:FireClient(plr)
	end)
end

ReqStartNewRun.OnServerEvent:Connect(function(plr)
	startSeason(plr, { fresh = true })
end)

ReqContinueRun.OnServerEvent:Connect(function(plr)
	-- CONTINUE 未実装：暫定で NEW GAME 相当
	startSeason(plr, { fresh = true })
end)

--==================================================
-- 屋台 → 次シーズン遷移
--==================================================
Remotes.ShopDone.OnServerEvent:Connect(function(plr: Player)
	local s = StateHub.get(plr); if not s then return end
	if s.phase ~= "shop" then return end

	-- 前季スコアの残留を防ぐ
	s.lastScore = nil
	s.phase = "play"

	local nextSeason = (s.season or 1) + 1
	if nextSeason > 4 then
		-- 冬→春はランリセット
		Round.resetRun(plr)
	else
		-- 同一ラン内の季節遷移
		Round.newRound(plr, nextSeason)
		StateHub.set(plr, s)
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

	local clears = tonumber(s.totalClears or 0) or 0
	local unlocked = clears >= 3

	-- 共通初期化
	s.mult = 1.0

	-- サーバ側ガード：未解禁なら "home" 以外は無効化
	if op ~= "home" and not unlocked then
		op = "home"
	end

	if op == "home" then
		-- トップへ戻す（新ランに初期化）
		Round.resetRun(plr)
		Remotes.HomeOpen:FireClient(plr, {
			hasSave = false,
			bank    = s.bank or 0,
			year    = s.year or 0,
			clears  = s.totalClears or 0,
			lang    = SaveService.getLang(plr),
		})
		return

	elseif op == "next" then
		-- 25年進行＋屋台
		s.year = (s.year or 0) + 25
		if typeof(SaveService.bumpYear) == "function" then
			SaveService.bumpYear(plr, 25)
		else
			SaveService.setYear(plr, s.year)
		end
		s.phase = "shop"
		if ShopService and typeof(ShopService.open) == "function" then
			ShopService.open(plr, s, { reason = "after_winter" })
		else
			StateHub.pushState(plr)
		end
		return

	elseif op == "save" then
		-- 永続保存→トップへ
		local ok = true
		if typeof(SaveService.flush) == "function" then
			ok = SaveService.flush(plr) == true
		end
		Round.resetRun(plr)
		Remotes.HomeOpen:FireClient(plr, {
			hasSave = true,
			bank    = s.bank or 0,
			year    = s.year or 0,
			clears  = s.totalClears or 0,
			saved   = ok,
			lang    = SaveService.getLang(plr),
		})
		return
	end
end)
