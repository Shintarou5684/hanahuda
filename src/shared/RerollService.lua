-- ReplicatedStorage/SharedModules/RerollService.lua
local RS = game:GetService("ReplicatedStorage")
local CardEngine = require(RS.SharedModules.CardEngine)
local StateHub   = require(RS.SharedModules.StateHub)

local Reroll = {}

local function shuffleDeck(deck) CardEngine.shuffle(deck, os.time()) end
local function rebuildDeckWith(parts)
	local deck = {}
	local function push(list) if list then for i=1,#list do table.insert(deck, list[i]) end end end
	push(parts.deck); push(parts.hand); push(parts.board); push(parts.dump)
	return deck
end

local function doRerollAll(s)
	local newDeck = rebuildDeckWith({ deck=s.deck, hand=s.hand, board=s.board, dump=s.dump })
	s.hand, s.board, s.dump = {}, {}, {}
	shuffleDeck(newDeck)
	for i=1,5 do if #newDeck>0 then table.insert(s.hand,  table.remove(newDeck)) end end
	for i=1,8 do if #newDeck>0 then table.insert(s.board, table.remove(newDeck)) end end
	s.deck = newDeck
end

local function doRerollHand(s)
	local newDeck = rebuildDeckWith({ deck=s.deck, hand=s.hand })
	s.hand = {}
	shuffleDeck(newDeck)
	for i=1,5 do if #newDeck>0 then table.insert(s.hand, table.remove(newDeck)) end end
	s.deck = newDeck
end

function Reroll.bind(Remotes, sweepFourOnBoardFn) -- sweepはPickServiceの同等処理を使うなら渡さなくてもOK
	Remotes.ReqRerollAll.OnServerEvent:Connect(function(plr)
		local s = StateHub.get(plr); if not s or s.phase~="play" then return end
		if s.rerollsLeft <= 0 then return end
		doRerollAll(s); s.rerollsLeft -= 1
		if sweepFourOnBoardFn then sweepFourOnBoardFn(s) end
		StateHub.pushState(plr)
	end)
	Remotes.ReqRerollHand.OnServerEvent:Connect(function(plr)
		local s = StateHub.get(plr); if not s or s.phase~="play" then return end
		if s.rerollsLeft <= 0 then return end
		doRerollHand(s); s.rerollsLeft -= 1
		if sweepFourOnBoardFn then sweepFourOnBoardFn(s) end
		StateHub.pushState(plr)
	end)
end

return Reroll
