-- ReplicatedStorage/SharedModules/PickService.lua
local RS = game:GetService("ReplicatedStorage")
local StateHub = require(RS.SharedModules.StateHub)

local Pick = {}

local function countSameMonth(list, month)
	local idxs = {}
	for i,card in ipairs(list) do if card.month == month then table.insert(idxs, i) end end
	return idxs
end

local function sweepFourOnBoard(s)
	local seen = {}
	for i,card in ipairs(s.board) do
		local m = card.month; seen[m] = seen[m] or {}; table.insert(seen[m], i)
	end
	for _,idxs in pairs(seen) do
		if #idxs >= 4 then
			table.sort(idxs, function(a,b) return a>b end)
			for _,bi in ipairs(idxs) do
				table.insert(s.dump, table.remove(s.board, bi))
			end
		end
	end
end

local function takeFromBoardByMonth(s, month, howMany)
	local takenCount = 0
	for i = #s.board, 1, -1 do
		if s.board[i].month == month then
			table.insert(s.taken, table.remove(s.board, i))
			takenCount += 1
			if howMany and takenCount >= howMany then break end
		end
	end
	return takenCount
end

local function drawOneFromDeck(s)
	if #s.deck <= 0 then return nil end
	local c = table.remove(s.deck)
	table.insert(s.board, c)
	return c
end

function Pick.bind(Remotes)
	Remotes.ReqPick.OnServerEvent:Connect(function(plr: Player, handIdx: number, boardIdx: number?)
		local s = StateHub.get(plr); if not s or s.phase~="play" then return end
		if not handIdx or not s.hand[handIdx] then return end

		local playCard = table.remove(s.hand, handIdx)

		local idxsOnBoard = countSameMonth(s.board, playCard.month)
		if #idxsOnBoard == 3 then
			table.insert(s.taken, playCard)
			takeFromBoardByMonth(s, playCard.month, 3)
		else
			if #idxsOnBoard >= 1 then
				local matched = false
				if boardIdx and s.board[boardIdx] and s.board[boardIdx].month == playCard.month then
					table.insert(s.taken, playCard)
					table.insert(s.taken, table.remove(s.board, boardIdx))
					matched = true
				end
				if not matched then
					table.insert(s.taken, playCard)
					takeFromBoardByMonth(s, playCard.month, 1)
				end
			else
				table.insert(s.board, playCard)
			end
		end
		sweepFourOnBoard(s)

		local flip = drawOneFromDeck(s)
		if flip then
			local idxs2 = countSameMonth(s.board, flip.month)
			if #idxs2 >= 2 then
				local takenOne = false
				for i = #s.board, 1, -1 do
					if s.board[i].month == flip.month and s.board[i] ~= flip then
						table.insert(s.taken, table.remove(s.board, i))
						takenOne = true; break
					end
				end
				for i = #s.board, 1, -1 do
					if s.board[i] == flip then
						table.insert(s.taken, table.remove(s.board, i))
						break
					end
				end
			end
			sweepFourOnBoard(s)
		end

		StateHub.pushState(plr)
	end)
end

return Pick
