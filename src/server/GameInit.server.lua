-- ServerScriptService/GameInit.server.lua
-- エントリポイント：Remotes生成／各Service初期化／永続（SaveService）連携
-- v0.9.2 → v0.9.2-langfix2 (+P1-3 logger) → v0.9.3-effects-bootstrap
--  - STARTGAME に統合（セーブがあればCONTINUE / なければNEW）
--  - SaveService.activeRun（季節開始/屋台入場）スナップからの復帰に対応
--  - HomeOpen.hasSave を正しく反映
--  - 言語保存 ReqSetLang を実装
--  - ★ 言語コードを外部公開 "ja/en" に統一（"jp" は受け取ったら "ja" に正規化）
--  - ★ 冬クリア→HOME/保存→HOME 時は“春スナップ”を残さない（hasSave=false を返す）
--  - ★ P1-1: DecideNext の実装を NavServer に一本化（本ファイルは初期化のみ）
--  - ★ P1-3: Logger 導入（print/warn を LOG.* に置換）
--  - ★ P2-10: ラン終了後は強制NEW（_forceNewOnNextStart フラグを尊重）
--  - ★ v0.9.3: Deck/EffectsRegistry の一括登録を起動時に実行
--              ＋ 酉UI用 Remotes（KitoPickStart/KitoPickDecide）を正式に生やす
--  - ★ v0.9.3-fix: ShopDone 時に DeckRegistry の最新スナップショットを次シーズンへ明示伝播
--                  （変更されたデッキを直後のシーズンで必ず使用）

--==================================================
-- Services
--==================================================
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local SSS     = game:GetService("ServerScriptService")

--==================================================
-- Logger
--==================================================
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("GameInit")
Logger.configure({
	level = Logger.INFO,
	timePrefix = true,
	dupWindowSec = 0.5,
})

LOG.info("boot")

--==================================================
-- SaveService（bank/year/clears/lang/activeRun の永続化）
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

	-- ★ 酉UI（新経路）: サーバ→クライアント候補提示 / クライアント→サーバ決定
	KitoPickStart  = ensureRemote("KitoPickStart"),   -- S→C: 12候補提示
	KitoPickDecide = ensureRemote("KitoPickDecide"),  -- C→S: 決定/スキップ
}

-- Top/Home 系
local HomeOpen        = ensureRemote("HomeOpen")        -- S→C: トップを開く
local ReqStartNewRun  = ensureRemote("ReqStartNewRun")  -- C→S: ★後方互換（NEW強制）
local ReqContinueRun  = ensureRemote("ReqContinueRun")  -- C→S: ★後方互換（CONTINUE推奨）
local ReqStartGame    = ensureRemote("ReqStartGame")    -- C→S: ★統合エントリ（NEW or CONTINUE 自動）
local RoundReady      = ensureRemote("RoundReady")      -- S→C: 新ラウンド準備完了
local ReqSetLang      = ensureRemote("ReqSetLang")      -- C→S: 言語保存

-- Remotes からも参照できるように追加
Remotes.HomeOpen        = HomeOpen
Remotes.ReqStartNewRun  = ReqStartNewRun
Remotes.ReqContinueRun  = ReqContinueRun
Remotes.ReqStartGame    = ReqStartGame
Remotes.RoundReady      = RoundReady
Remotes.ReqSetLang      = ReqSetLang

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

-- ★ P1-1: NavServer を導入（DecideNext の唯一線）
local NavServer    = require(SSS:WaitForChild("NavServer"))

-- （任意）酉ピックのハンドラ群（あれば起動時に Remotes を注入して配線）
local KitoPickServer do
	local ok, mod = pcall(function() return require(SSS:WaitForChild("KitoPickServer")) end)
	if ok and type(mod) == "table" then
		KitoPickServer = mod
	else
		KitoPickServer = nil
	end
end

-- ★ DeckRegistry（最新デッキ状態のソース）
local DeckRegistry do
	local ok, mod = pcall(function()
		-- プロジェクト構成に合わせて DeckRegistry の場所を解決
		return require(RS:WaitForChild("SharedModules"):WaitForChild("Deck"):WaitForChild("DeckRegistry"))
	end)
	DeckRegistry = ok and mod or nil
end

--==================================================
-- Deck Effects（新経路の唯一のデッキ変化窓口）: 起動時に一括登録
--==================================================
local function bootstrapEffects()
	local ok, err = pcall(function()
		require(RS:WaitForChild("SharedModules"):WaitForChild("Deck"):WaitForChild("EffectsRegisterAll"))
	end)
	if ok then
		LOG.info("[Effects] EffectsRegistry initialized (Deck/EffectsRegisterAll)")
	else
		LOG.warn("[Effects] initialization failed: %s", tostring(err))
	end
end

--==================================================
-- DEV Remotes（Studio向け：+両 / +役 付与）
--==================================================
local DevGrantRyo  = ensureRemote("DevGrantRyo")
local DevGrantRole = ensureRemote("DevGrantRole")

DevGrantRyo.OnServerEvent:Connect(function(plr, amount)
	amount = tonumber(amount) or 1000
	local s = StateHub.get(plr); if not s then return end
	s.bank = (s.bank or 0) + amount
	StateHub.pushState(plr)
	SaveService.addBank(plr, amount)
	LOG.debug("DevGrantRyo | user=%s amount=%d bank=%d", plr.Name, amount, s.bank or -1)
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

	local total, roles, detail = Scoring.evaluate(s.taken or {}, s)
	s.lastScore = { total = total or 0, roles = roles, detail = detail }
	StateHub.pushState(plr)
	LOG.debug("DevGrantRole | user=%s total=%s", plr.Name, tostring(total))
end)

--==================================================
-- 言語ユーティリティ（ja/en 正規化）
--==================================================
local function normLang(v:string?): string?
	v = tostring(v or ""):lower()
	if v == "ja" or v == "jp" then return "ja" end
	if v == "en" then return "en" end
	return nil
end

--==================================================
-- 初期化／バインド
--==================================================
-- ★ Deck Effects 登録（最初に実施）
bootstrapEffects()

-- StateHub / 各サービス紐付け
StateHub.init(Remotes)

if PickService and typeof(PickService.bind) == "function" then
	PickService.bind(Remotes)
else
	LOG.warn("PickService.bind が見つかりません")
end

if Reroll and typeof(Reroll.bind) == "function" then
	Reroll.bind(Remotes)
else
	LOG.warn("Reroll.bind が見つかりません")
end

if Score and typeof(Score.bind) == "function" then
	Score.bind(Remotes, { openShop = ShopService and ShopService.open })
else
	LOG.warn("Score.bind が見つかりません")
end

if ShopService and typeof(ShopService.init) == "function" then
	ShopService.init(
		function(plr) return StateHub.get(plr) end,
		function(plr) StateHub.pushState(plr) end
	)
else
	LOG.warn("ShopService.init が見つかりません")
end

-- ★ 酉ピック（新経路）の配線があれば注入して起動
if KitoPickServer and typeof(KitoPickServer.bind) == "function" then
	KitoPickServer.bind(Remotes)
	LOG.info("[KitoPickServer] ready (handlers wiring)")
end

-- ★ P1-1: NavServer を初期化（DecideNext の唯一線）。依存はここで注入。
NavServer.init({
	StateHub    = StateHub,
	Round       = Round,
	ShopService = ShopService,
	SaveService = SaveService,
	HomeOpen    = HomeOpen,           -- S→C push（NavServerで使用）
	DecideNext  = Remotes.DecideNext, -- C→S pull（同上）
})

--==================================================
-- Player lifecycle：永続ロード/保存 + 言語ログ
--==================================================
Players.PlayerAdded:Connect(function(plr)
	LOG.info("PlayerAdded | begin load profile | user=%s userId=%d", plr.Name, plr.UserId)

	local prof = SaveService.load(plr)
	LOG.debug(
		"Profile loaded | user=%s bank=%s year=%s asc=%s clears=%s lang=%s",
		plr.Name,
		tostring(prof and prof.bank), tostring(prof and prof.year),
		tostring(prof and prof.asc),  tostring(prof and prof.clears),
		tostring(prof and prof.lang)
	)

	local s = StateHub.get(plr) or {}
	local savedLang = normLang(SaveService.getLang(plr)) or "en"

	s.bank        = prof.bank   or 0
	s.year        = prof.year   or 0
	s.totalClears = prof.clears or 0
	s.lang        = savedLang
	-- 念のため NEW強制フラグは初期状態では無効化
	s._forceNewOnNextStart = false

	StateHub.set(plr, s)

	LOG.debug(
		"State set | user=%s lang=%s bank=%d year=%d clears=%d",
		plr.Name, s.lang, s.bank or 0, s.year or 0, s.totalClears or 0
	)

	local hasSave = SaveService.getActiveRun(plr) ~= nil
	LOG.info(
		"HomeOpen → C | user=%s lang=%s hasSave=%s bank=%d year=%d clears=%d",
		plr.Name, s.lang, tostring(hasSave), s.bank or 0, s.year or 0, s.totalClears or 0
	)

	HomeOpen:FireClient(plr, {
		hasSave = hasSave,
		bank    = s.bank,
		year    = s.year,
		clears  = s.totalClears or 0,
		lang    = s.lang, -- "ja" or "en"
	})
end)

Players.PlayerRemoving:Connect(function(plr)
	LOG.info("PlayerRemoving | flush profile | user=%s", plr.Name)
	SaveService.flush(plr)
end)

game:BindToClose(function()
	LOG.info("BindToClose | flushAll begin")
	pcall(function() SaveService.flushAll() end)
	LOG.info("BindToClose | flushAll end")
end)

--==================================================
-- 言語保存（C→S）
--==================================================
ReqSetLang.OnServerEvent:Connect(function(plr, lang)
	local n = normLang(lang)
	if not n then
		LOG.warn("ReqSetLang invalid | user=%s from=%s", plr.Name, tostring(lang))
		return
	end
	SaveService.setLang(plr, n)

	local s = StateHub.get(plr) or {}
	s.lang = n
	StateHub.set(plr, s)

	LOG.info("setLang | saved & state updated | user=%s lang=%s", plr.Name, n)
end)

--==================================================
-- ラン開始/続き（RoundReady → RunScreen.requestSync → UiResync）
--==================================================
local function fireReadySoon(plr)
	task.delay(0.05, function()
		Remotes.RoundReady:FireClient(plr)
	end)
end

local function startNewRun(plr)
	-- NEW 開始前に続きスナップは必ず破棄
	if SaveService.clearActiveRun then pcall(function() SaveService.clearActiveRun(plr) end) end
	Round.resetRun(plr)
	fireReadySoon(plr)
	LOG.info("startNewRun | user=%s", plr.Name)
end

local function continueFromSnapshot(plr, snap:any)
	local s = StateHub.get(plr) or {}
	s.bank = tonumber(snap.bank or s.bank or 0) or 0
	s.mon  = tonumber(snap.mon  or s.mon  or 0) or 0
	if snap.effects then
		s.effects = snap.effects
	end
	StateHub.set(plr, s)

	local season = tonumber(snap.season or 1) or 1

	-- ★ 復帰時：保存されている deckSnapshot があれば Round へ明示的に渡す
	local opts = nil
	if snap.deckSnapshot then
		opts = { deckSnapshot = snap.deckSnapshot }
	end

	Round.newRound(plr, season, opts)

	fireReadySoon(plr)

	if snap.atShop and ShopService and typeof(ShopService.open)=="function" then
		task.delay(0.08, function()
			local cur = StateHub.get(plr); if not cur then return end
			cur.phase = "shop"
			if snap.shopStock then
				cur.shop = cur.shop or {}
				cur.shop.stock = snap.shopStock
			end
			StateHub.set(plr, cur)
			ShopService.open(plr, cur, { notice = "" })
		end)
	end

	LOG.info("continueFromSnapshot | user=%s season=%d atShop=%s", plr.Name, season, tostring(snap.atShop))
end

-- ★ 統合：NEW/CNT 自動判定（ラン終了後は強制NEW）
local function startGameAuto(plr)
	local s = StateHub.get(plr) or {}

	-- ★ NavServer の endRunAndClean が立てるフラグを最優先
	if s._forceNewOnNextStart then
		LOG.info("startGameAuto | force NEW (flag) | user=%s", plr.Name)
		s._forceNewOnNextStart = false -- 一度使ったら解除
		StateHub.set(plr, s)
		startNewRun(plr)
		return
	end

	local snap = SaveService.getActiveRun(plr)
	if snap then
		continueFromSnapshot(plr, snap)
	else
		startNewRun(plr)
	end
end

-- ★ 新：統合エントリ
ReqStartGame.OnServerEvent:Connect(function(plr)
	startGameAuto(plr)
end)

-- ★ 旧：後方互換（NEWを強制）
ReqStartNewRun.OnServerEvent:Connect(function(plr)
	startNewRun(plr)
end)

-- ★ 旧：後方互換（CONTINUE優先 / 無ければNEW）
ReqContinueRun.OnServerEvent:Connect(function(plr)
	startGameAuto(plr)
end)

--==================================================
-- 屋台 → 次シーズン遷移
--==================================================
Remotes.ShopDone.OnServerEvent:Connect(function(plr: Player)
	local s = StateHub.get(plr); if not s then return end
	if s.phase ~= "shop" then return end

	-- ★★★★★ ここが本修正の核心 ★★★★★
	-- ショップでの効果（例：酉の光札化）は DeckRegistry にコミット済み。
	-- 次シーズン開始前に「今のDeckRegistry」をスナップショット化して newRound に渡す。
	local nextSeason = (s.season or 1) + 1
	local deckSnapForNext = nil

	if DeckRegistry and typeof(Round.getRunId) == "function" and typeof(DeckRegistry.dumpSnapshot) == "function" then
		local runId = Round.getRunId(plr) -- Round 側で管理している現在の runId を取得
		if runId then
			local ok, snap = pcall(function() return DeckRegistry.dumpSnapshot(runId) end)
			if ok and snap then
				deckSnapForNext = snap
				LOG.info("[ShopDone] captured latest deck snapshot for next season | run=%s", tostring(runId))
				-- 任意：復帰用に ActiveRun にも保存しておくと安全
				if typeof(SaveService.updateActiveRunDeck) == "function" then
					pcall(function() SaveService.updateActiveRunDeck(plr, snap) end)
				end
			else
				LOG.warn("[ShopDone] dumpSnapshot failed | err=%s", tostring(snap))
			end
		else
			LOG.warn("[ShopDone] Round.getRunId returned nil (skip snapshot)")
		end
	else
		LOG.warn("[ShopDone] DeckRegistry or Round.getRunId not available (skip snapshot)")
	end
	-- ★★★★★ ここまで ★★★★★

	s.lastScore = nil
	s.phase = "play"

	if nextSeason > 4 then
		-- 冬→春はランリセット（継続プレイのためスナップ維持でOK）
		Round.resetRun(plr)
	else
		-- ★ 修正：次シーズン開始時に明示的に deckSnapshot を渡す
		local opts = deckSnapForNext and { deckSnapshot = deckSnapForNext } or nil
		Round.newRound(plr, nextSeason, opts)
		StateHub.set(plr, s)
	end

	fireReadySoon(plr)
	LOG.info("ShopDone → next | user=%s nextSeason=%d", plr.Name, nextSeason)
end)

--==================================================
-- 以降、DecideNext の実装は NavServer に移管済み（ここには置かない）
--==================================================
