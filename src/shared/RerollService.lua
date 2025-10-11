-- ReplicatedStorage/SharedModules/RerollService.lua
-- v0.10.1 Field-only reroll fix
--  - 場リロール(ReqRerollAll)は「手札を維持し、場だけ引き直し」に変更
--  - 手札リロール(ReqRerollHand)は従来どおり手札のみ
--  - SSOT: s.rerollFieldLeft / s.rerollHandLeft を唯一の真実として扱う
--  - 旧フィールド（rerollsLeft / handsLeft）には一切触れない

local RS = game:GetService("ReplicatedStorage")
local CardEngine = require(RS.SharedModules.CardEngine)
local StateHub   = require(RS.SharedModules.StateHub)

local Reroll = {}

--========================
-- 内部ヘルパ
--========================
local function shuffleDeck(deck)
	CardEngine.shuffle(deck, os.time())
end

local function rebuildDeckWith(parts)
	local deck = {}
	local function push(list)
		if list then
			for i = 1, #list do
				table.insert(deck, list[i])
			end
		end
	end
	push(parts.deck); push(parts.hand); push(parts.board); push(parts.dump)
	return deck
end

-- 正準カウンタの存在を保証（run.reroll を参考に補完）。旧フィールドは触らない。
local function ensureRerollCounters(s:any)
	s.run = s.run or {}
	s.run.reroll = s.run.reroll or {}

	if s.rerollFieldLeft == nil then
		local v = tonumber(s.run.reroll.field or 0) or 0
		s.rerollFieldLeft = v
	end
	if s.rerollHandLeft == nil then
		local v = tonumber(s.run.reroll.hand or 0) or 0
		s.rerollHandLeft = v
	end

	s.rerollFieldLeft = tonumber(s.rerollFieldLeft or 0) or 0
	s.rerollHandLeft  = tonumber(s.rerollHandLeft  or 0) or 0

	-- 正本を run.reroll にも常に反映（セーブ/復帰向け）
	s.run.reroll.field = s.rerollFieldLeft
	s.run.reroll.hand  = s.rerollHandLeft
end

local function decAndSync(s:any, key:string)
	ensureRerollCounters(s)
	local v = tonumber(s[key] or 0) or 0
	if v <= 0 then return false end
	s[key] = v - 1

	-- 正本→run.reroll へ同期（旧フィールドは同期しない）
	if key == "rerollFieldLeft" then
		s.run.reroll.field = s.rerollFieldLeft
	elseif key == "rerollHandLeft" then
		s.run.reroll.hand  = s.rerollHandLeft
	end
	return true
end

--========================
-- 実処理
--========================
-- ★ 場のみリロール（手札はそのまま）
local function doRerollField(s)
	-- 場(board)だけを山に戻して引き直す（dump は触らない）
	local newDeck = rebuildDeckWith({ deck = s.deck, board = s.board })
	s.board = {}
	shuffleDeck(newDeck)
	for i = 1, 8 do
		if #newDeck > 0 then table.insert(s.board, table.remove(newDeck)) end
	end
	s.deck = newDeck
end

-- 手札のみリロール（場はそのまま）
local function doRerollHand(s)
	local newDeck = rebuildDeckWith({ deck = s.deck, hand = s.hand })
	s.hand = {}
	shuffleDeck(newDeck)
	for i = 1, 5 do
		if #newDeck > 0 then table.insert(s.hand, table.remove(newDeck)) end
	end
	s.deck = newDeck
end

--========================
-- バインド
--========================
function Reroll.bind(Remotes, sweepFourOnBoardFn) -- sweep は PickService の同等処理を使うなら渡さなくてもOK
	-- 場リロール（互換のため Remote 名は ReqRerollAll のまま使用）
	Remotes.ReqRerollAll.OnServerEvent:Connect(function(plr)
		local s = StateHub.get(plr); if not s or s.phase ~= "play" then return end
		ensureRerollCounters(s)
		if not decAndSync(s, "rerollFieldLeft") then return end
		doRerollField(s)
		if sweepFourOnBoardFn then sweepFourOnBoardFn(s) end
		StateHub.set(plr, s); StateHub.pushState(plr)
	end)

	-- 手札リロール
	Remotes.ReqRerollHand.OnServerEvent:Connect(function(plr)
		local s = StateHub.get(plr); if not s or s.phase ~= "play" then return end
		ensureRerollCounters(s)
		if not decAndSync(s, "rerollHandLeft") then return end
		doRerollHand(s)
		if sweepFourOnBoardFn then sweepFourOnBoardFn(s) end
		StateHub.set(plr, s); StateHub.pushState(plr)
	end)
end

return Reroll
