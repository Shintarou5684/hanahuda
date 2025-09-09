-- ReplicatedStorage/SharedModules/RoundService.lua
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local CardEngine   = require(RS.SharedModules.CardEngine)
local StateHub     = require(RS.SharedModules.StateHub)
local RunDeckUtil  = require(RS.SharedModules.RunDeckUtil) -- ★ 追加：ランデッキ入出力

local Round = {}

local MAX_HANDS   = 3
local MAX_REROLLS = 5

-- 毎シーズン必ず異なるシードを作る（GUID + シーズン番号 + 現在時刻を混ぜる）
local function makeSeasonSeed(seasonNum: number?)
	-- GUIDは十分ランダム。数字以外を落として先頭9桁を使用
	local guid = HttpService:GenerateGUID(false)
	local mixed = string.format("%s-%s-%.6f", guid, tostring(seasonNum or 0), os.clock())
	local num = tonumber((mixed:gsub("%D","")):sub(1,9)) or math.random(1, 10^9)
	return num
end

-- ラン用に保存されている「デッキ構成（コード配列）」から、その季節の山札を新規生成してシャッフル
local function buildShuffledDeckFromRun(stateTbl: any, seasonNum: number)
	-- 1) ラン中デッキをロード（屋台で更新された構成を優先）
	local runDeck = RunDeckUtil.load(stateTbl)

	-- 2) 構成が無ければ（ラン初回など）通常の48枚初期デッキ
	if not runDeck or #runDeck == 0 then
		local d = CardEngine.buildDeck()
		CardEngine.shuffle(d, makeSeasonSeed(seasonNum))
		-- 初回はこの構成をラン用として保存しておく（堅牢化）
		stateTbl.run = stateTbl.run or {}
		stateTbl.run.deck = d
		RunDeckUtil.save(stateTbl)
		return d
	end

	-- 3) 構成（コード配列）から今季の山札を新規に起こす → 毎季節でシャッフル
	local codes = table.create(#runDeck)
	for i, c in ipairs(runDeck) do
		local code = (type(c) == "table" and (c.code or CardEngine.toCode(c.month, c.idx))) or tostring(c)
		codes[i] = code
	end
	local deck = CardEngine.buildDeckFromCodes(codes)
	CardEngine.shuffle(deck, makeSeasonSeed(seasonNum))

	-- 念のためスナップショットを最新化（別環境から復元して来た場合などの保険）
	RunDeckUtil.save(stateTbl)
	return deck
end

-- 新しいシーズンを開始（同一ラン内の季節遷移もここ）
function Round.newRound(plr: Player, seasonNum: number)
	-- ★ ラン構成を優先して今季の山を生成・シャッフル
	local deck = buildShuffledDeckFromRun(StateHub.get(plr) or {}, seasonNum)

	-- 手札5枚
	local hand = CardEngine.draw(deck, 5)

	-- 場札8枚（山の末尾から取り出し）
	local board = {}
	for i = 1, 8 do
		table.insert(board, table.remove(deck))
	end

	-- 状態を新規テーブルで保存（参照の使い回しを避ける）
	local s = StateHub.get(plr) or {}
	s.run         = s.run or {}                 -- ★ 念のため保持
	s.deck        = deck
	s.hand        = hand
	s.board       = board
	s.taken       = {}
	s.dump        = {}
	s.season      = seasonNum
	s.handsLeft   = MAX_HANDS
	s.rerollsLeft = MAX_REROLLS
	s.seasonSum   = 0
	s.chainCount  = 0
	-- ラン継続中は倍率・両/文は維持（resetRun時に初期化）
	s.mult        = s.mult or 1.0
	s.bank        = s.bank or 0      -- 両：永続通貨
	s.mon         = s.mon or 0       -- 文：ラン通貨
	s.phase       = "play"

	-- ★ ラン構成のスナップショットを常に最新化（別経路の変更も拾う）
	RunDeckUtil.save(s)

	StateHub.set(plr, s)
	print(("[Round.newRound] season=%s deck=%d hand=%d board=%d")
		:format(tostring(seasonNum), #deck, #hand, #board))
	StateHub.pushState(plr)
end

-- ランをリセット（新規ラン開始：春=1から）
function Round.resetRun(plr: Player)
	local prev = StateHub.get(plr)
	local keepBank   = (prev and prev.bank) or 0
	local keepYear   = (prev and prev.year) or 0
	local keepClears = (prev and prev.totalClears) or 0

	-- 文（mon）はランごとにリセット
	local fresh = {
		bank = keepBank,
		year = keepYear,
		totalClears = keepClears,
		mult = 1.0,
		mon  = 0,
		phase = "play",
	}

	-- ★ ラン構成は初期化：初回は newRound 内で初期デッキが自動採用される
	StateHub.set(plr, fresh)
	Round.newRound(plr, 1)
end

return Round
