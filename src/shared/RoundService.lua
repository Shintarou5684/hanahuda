-- v0.9.0 季節開始ロジック（configSnapshot → 当季デッキ）
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local CardEngine   = require(RS.SharedModules.CardEngine)
local StateHub     = require(RS.SharedModules.StateHub)
local RunDeckUtil  = require(RS.SharedModules.RunDeckUtil)

local Round = {}

local MAX_HANDS   = 3
local MAX_REROLLS = 5

local function makeSeasonSeed(seasonNum: number?)
	local guid = HttpService:GenerateGUID(false)
	local mixed = string.format("%s-%s-%.6f", guid, tostring(seasonNum or 0), os.clock())
	local num = tonumber((mixed:gsub("%D","")):sub(1,9)) or math.random(1, 10^9)
	return num
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

-- 季節開始（1=春, 2=夏, ...）
function Round.newRound(plr: Player, seasonNum: number)
	local s = StateHub.get(plr) or {}

	-- 1) ラン構成をロード（無ければ初期化）
	consumeQueuedConversions(s, Random.new())
	local configDeck = RunDeckUtil.loadConfig(s, true) -- 48枚

	-- 2) 当季デッキを構成からクローン＆シャッフル
	local seasonDeck = {}
	for i, c in ipairs(configDeck) do
		seasonDeck[i] = {
			month=c.month, idx=c.idx, kind=c.kind, name=c.name,
			tags=c.tags and table.clone(c.tags) or nil, code=c.code,
		}
	end
	CardEngine.shuffle(seasonDeck, makeSeasonSeed(seasonNum))

	-- 3) 初期配り
	local hand  = CardEngine.draw(seasonDeck, 5)
	local board = {}
	for i=1,8 do table.insert(board, table.remove(seasonDeck)) end

	-- 4) 状態保存（命名統一：board/dump）
	s.run         = s.run or {}
	s.deck        = seasonDeck
	s.hand        = hand
	s.board       = board
	s.taken       = {}
	s.dump        = {}
	s.season      = seasonNum
	s.handsLeft   = MAX_HANDS
	s.rerollsLeft = MAX_REROLLS
	s.seasonSum   = 0
	s.chainCount  = 0
	s.mult        = s.mult or 1.0
	s.bank        = s.bank or 0
	s.mon         = s.mon or 0
	s.phase       = "play"

	StateHub.set(plr, s)
	StateHub.pushState(plr)
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
		run = { configSnapshot = nil }, -- 次で自動初期化
	}
	StateHub.set(plr, fresh)
	Round.newRound(plr, 1)
end

return Round
