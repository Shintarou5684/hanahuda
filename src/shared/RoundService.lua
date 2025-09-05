-- ReplicatedStorage/SharedModules/RoundService.lua
local RS = game:GetService("ReplicatedStorage")
local HttpService    = game:GetService("HttpService")

local CardEngine = require(RS.SharedModules.CardEngine)
local StateHub   = require(RS.SharedModules.StateHub)

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

-- 新しいシーズンを開始（同一ラン内の季節遷移もここ）
function Round.newRound(plr: Player, seasonNum: number)
	-- ★ シーズン毎に新しい山を作成＆毎回ユニークなシードでシャッフル
	local deck = CardEngine.buildDeck()
	CardEngine.shuffle(deck, makeSeasonSeed(seasonNum))

	-- 手札5枚
	local hand = CardEngine.draw(deck, 5)

	-- 場札8枚（山の末尾から取り出し）
	local board = {}
	for i = 1, 8 do
		table.insert(board, table.remove(deck))
	end

	-- 状態を新規テーブルで保存（参照の使い回しを避ける）
	local s = StateHub.get(plr) or {}
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
	StateHub.set(plr, {
		bank = keepBank,
		year = keepYear,
		totalClears = keepClears,
		mult = 1.0,
		mon  = 0,
		phase = "play",
	})
	Round.newRound(plr, 1)
end

return Round
