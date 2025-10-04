-- v0.9.1 → v0.9.1-nextdeck (+12-month: month/goal 初期化・保持)
-- 季節開始ロジック（configSnapshot/外部デッキスナップ → 当季デッキ → ★季節開始スナップ保存）
-- ★ Reroll統一：rerollFieldLeft / rerollHandLeft を唯一の真実（SSOT）とする
--    旧フィールド（handsLeft / rerollsLeft）への書き込み・同期を完全撤廃

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

local CardEngine   = require(RS.SharedModules.CardEngine)
local StateHub     = require(RS.SharedModules.StateHub)
local RunDeckUtil  = require(RS.SharedModules.RunDeckUtil)

-- ★ 12-month: Balance（目標スコア/開始月 等）
local Balance do
	local ok, mod = pcall(function() return require(RS:WaitForChild("Config"):WaitForChild("Balance")) end)
	Balance = ok and mod or {
		STAGE_START_MONTH = 1,
		getGoalForMonth = function(_) return 1 end,
		-- フォールバック（分離リロール初期値）
		REROLL_FIELD_INIT = 5,
		REROLL_HAND_INIT  = 3,
	}
end

-- ★ SaveService（サーバ専用：失敗してもゲームは継続）
local SaveService do
	local ok, mod = pcall(function() return require(SSS:WaitForChild("SaveService")) end)
	if ok then SaveService = mod else
		warn("[RoundService] SaveService not available; season snapshots will be skipped.")
		SaveService = nil
	end
end

local Round = {}

-- 旧 MAX_HANDS / MAX_REROLLS は廃止。Balance の REROLL_*_INIT を使用。

local function makeSeasonSeed(seasonNum: number?)
	local guid = HttpService:GenerateGUID(false)
	local mixed = string.format("%s-%s-%.6f", guid, tostring(seasonNum or 0), os.clock())
	local num = tonumber((mixed:gsub("%D","")):sub(1,9)) or math.random(1, 10^9)
	return num
end

-- ★ ランIDを状態に付与（なければ採番）
local function ensureRunId(state)
	state.run = state.run or {}
	if not state.run.id or state.run.id == "" then
		state.run.id = HttpService:GenerateGUID(false)
	end
	return state.run.id
end

-- ★ 12-month: 月初の goal を state に設定
local function setMonthAndGoal(state, monthOrNil)
	state.run = state.run or {}
	if monthOrNil ~= nil then
		state.run.month = tonumber(monthOrNil) or state.run.month or Balance.STAGE_START_MONTH or 1
	else
		state.run.month = state.run.month or Balance.STAGE_START_MONTH or 1
	end
	-- 目標スコア（UI/未達判定用）
	if Balance.getGoalForMonth then
		state.goal = Balance.getGoalForMonth(state.run.month)
	elseif Balance.GOAL_BY_MONTH then
		state.goal = Balance.GOAL_BY_MONTH[state.run.month] or Balance.GOAL_BY_MONTH[1] or 1
	else
		state.goal = 1
	end
end

-- 次季に繰り越された bright 変換スタックを消化（ラン構成に反映）
local function consumeQueuedConversions(state, rng)
	local bonus = state.bonus
	local n = tonumber(bonus and bonus.queueBrightNext or 0) or 0
	if n <= 0 then return end
	local cfg = RunDeckUtil.loadConfig(state, true)
	local converted = 0
	for _=1,n do
		local ok = CardEngine.convertRandomNonBrightToBright(cfg, rng)
		if not ok then break end
		converted += 1
	end
	if converted > 0 then
		RunDeckUtil.saveConfig(state, cfg)
		bonus.queueBrightNext = math.max(0, n - converted)
	end
end

-- ★ DeckRegistry.dumpSnapshot(runId) 等から来る可能性を想定して
--   「構成デッキ」形式へ寄せる（配列 or snap.cards を許容）
local function snapshotToConfigDeck(snap)
	if not snap then return nil end
	local src = snap.cards or snap
	if type(src) ~= "table" then return nil end

	local cfg = {}
	for i, c in ipairs(src) do
		-- month/idx/kind/name/tags/code が取れればそのまま採用
		cfg[i] = {
			month = c.month, idx = c.idx, kind = c.kind,
			name  = c.name,  tags = (c.tags and table.clone(c.tags) or nil),
			code  = c.code,
		}
	end
	-- 48枚想定。足りない/壊れていたら無効
	if #cfg < 48 then return nil end
	return cfg
end

-- 内部：分離リロール初期化（場/手）— SSOT
local function initRerollCounters(state)
	state.run = state.run or {}
	-- Balance から初期値
	local initField = tonumber(Balance.REROLL_FIELD_INIT or 5) or 5
	local initHand  = tonumber(Balance.REROLL_HAND_INIT  or 3) or 3

	-- ★ 正カウンタ（唯一の真実）
	state.rerollFieldLeft = initField
	state.rerollHandLeft  = initHand

	-- ★ セーブ/復帰向けの補助（正本のコピー）
	state.run.reroll = { field = initField, hand = initHand }

	-- ※ 旧互換フィールド（handsLeft / rerollsLeft）は作らない・触らない
end

-- 季節開始（1=春, 2=夏, ...）
-- ★ 第3引数 opts を追加。opts.deckSnapshot があればそれを最優先で当季の構成に使う。
function Round.newRound(plr: Player, seasonNum: number, opts: any?)
	opts = opts or {}

	local s = StateHub.get(plr) or {}
	-- ランIDを必ず持たせる（GameInit からの参照用）
	local runId = ensureRunId(s)

	-- ★ 12-month: month と goal を必ず与える（復帰時は保持、明示指定があれば採用）
	setMonthAndGoal(s, (s.run and s.run.month) or nil)
	-- ★ ラウンド開始ごとにリロール回数を初期化（場/手 分離）
	initRerollCounters(s)

	StateHub.set(plr, s)  -- ここで goal/リロールが state に乗る（この後 push でクライアント反映）

	-- 1) ラン構成をロード or 外部スナップで上書き
	consumeQueuedConversions(s, Random.new())

	local configDeck
	if opts.deckSnapshot then
		configDeck = snapshotToConfigDeck(opts.deckSnapshot)
		-- 破損や想定外フォーマットなら従来のロードにフォールバック
		if not configDeck then
			warn("[RoundService] deckSnapshot was invalid; falling back to RunDeckUtil.loadConfig")
			configDeck = RunDeckUtil.loadConfig(s, true)
		else
			-- 外部スナップが有効なら構成の正本として保存しておく
			RunDeckUtil.saveConfig(s, configDeck)
		end
	else
		configDeck = RunDeckUtil.loadConfig(s, true) -- 48枚（従来）
	end

	-- 2) 当季デッキを構成からクローン
	local seasonDeck = {}
	for i, c in ipairs(configDeck) do
		seasonDeck[i] = {
			month=c.month, idx=c.idx, kind=c.kind, name=c.name,
			tags=c.tags and table.clone(c.tags) or nil, code=c.code,
		}
	end

	-- 2.5) ★ シードを明示管理（復元用に state に保持）
	local seed = makeSeasonSeed(seasonNum)
	CardEngine.shuffle(seasonDeck, seed)

	-- 3) 初期配り
	local hand  = CardEngine.draw(seasonDeck, 5)
	local board = {}
	for i=1,8 do table.insert(board, table.remove(seasonDeck)) end

	-- 4) 状態保存（命名統一：board/dump）
	s.run         = s.run or {}
	-- run.id は ensureRunId でセット済み
	s.deck        = seasonDeck
	s.hand        = hand
	s.board       = board
	s.taken       = {}
	s.dump        = {}
	s.season      = seasonNum

	-- ★ 分離済みカウンタは initRerollCounters 済み（旧フィールドは作らない）

	s.seasonSum   = 0
	s.chainCount  = 0
	s.mult        = s.mult or 1.0
	s.bank        = s.bank or 0
	s.mon         = s.mon or 0
	s.phase       = "play"
	s.deckSeed    = seed            -- ★ 復元用に保持
	-- ★ 12-month: 月初に goal を再確認（他所で month を更新して戻ってきた場合も安全）
	s.goal        = (Balance.getGoalForMonth and Balance.getGoalForMonth(s.run.month))
	               or (Balance.GOAL_BY_MONTH and (Balance.GOAL_BY_MONTH[s.run.month] or Balance.GOAL_BY_MONTH[1]))
	               or 1

	StateHub.set(plr, s)
	StateHub.pushState(plr)

	-- 5) ★ 季節開始スナップを保存（CONTINUE用）
	if SaveService and SaveService.snapSeasonStart then
		pcall(function()
			-- SaveService 側が deckSnapshot を受ける設計であれば、ここで configDeck も併せて保存しておくと復帰が堅牢
			-- 既存インタフェース維持のため引数はそのまま
			SaveService.snapSeasonStart(plr, s, seasonNum)
		end)
	end
end

-- ランを完全リセット（構成も初期48へ戻す）
function Round.resetRun(plr: Player)
	local prev = StateHub.get(plr)
	local keepBank   = (prev and prev.bank) or 0
	local keepYear   = (prev and prev.year) or 0
	local keepClears = (prev and prev.totalClears) or 0

	local fresh = {
		bank = keepBank, year = keepYear, totalClears = keepClears,
		mult = 1.0, mon = 0, phase = "play",
		run = { configSnapshot = nil }, -- 次で自動初期化（run.id は newRound 内で自動採番）
	}
	-- ★ 12-month: ラン開始時の month/goal を初期化
	setMonthAndGoal(fresh, Balance and Balance.STAGE_START_MONTH or 1)

	-- ★ 分離リロールの初期化（SSOT）
	initRerollCounters(fresh)

	StateHub.set(plr, fresh)

	-- ★ 新ラン開始（newRound 内でスナップも作成される）
	Round.newRound(plr, 1)
end

-- ★ GameInit から現在ランIDを引くためのAPI
function Round.getRunId(plr: Player)
	local s = StateHub.get(plr)
	if not s then return nil end
	if not (s.run and s.run.id) then return nil end
	return s.run.id
end

return Round
