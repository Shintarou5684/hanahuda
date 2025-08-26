-- ReplicatedStorage/SharedModules/RoundService.lua
local RS = game:GetService("ReplicatedStorage")
local CardEngine = require(RS.SharedModules.CardEngine)
local StateHub   = require(RS.SharedModules.StateHub)

local Round = {}

local MAX_HANDS   = 3
local MAX_REROLLS = 5

-- 新しいシーズンを開始（同一ラン内の季節遷移もここ）
function Round.newRound(plr: Player, seasonNum: number)
	local deck = CardEngine.buildDeck()
	CardEngine.shuffle(deck, os.time() // 86400)

	local hand = CardEngine.draw(deck, 5)

	local board = {}
	for i = 1, 8 do
		table.insert(board, table.remove(deck))
	end

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
	-- ラン継続中は倍率・両/文は維持（resetRun時に初期化する）
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
	local keepHome   = (prev and prev.homeCount) or 0
	local keepClears = (prev and prev.totalClears) or 0

	-- 文（mon）はランごとにリセットする
	StateHub.set(plr, {
		bank = keepBank,
		year = keepYear,
		homeCount = keepHome,
		totalClears = keepClears,
		mult = 1.0,
		mon  = 0,
		phase = "play",
	})
	Round.newRound(plr, 1)
end

return Round
