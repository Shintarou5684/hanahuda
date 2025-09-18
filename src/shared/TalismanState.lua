-- shared/TalismanState.lua
-- v0.1 Step0: ラン側ボードの初期化と装備ID抽出
local M = {}

local function clamp(n, lo, hi)
	if math.clamp then return math.clamp(n, lo, hi) end
	if n < lo then return lo elseif n > hi then return hi else return n end
end

function M.ensureRunBoard(state: any)
	state.run = state.run or {}
	local accUnlocked = 2
	if state.account and state.account.talismanUnlock and tonumber(state.account.talismanUnlock.unlocked) then
		accUnlocked = clamp(tonumber(state.account.talismanUnlock.unlocked), 0, 6)
	end

	local t = state.run.talisman
	if type(t) ~= "table" then
		t = {
			maxSlots = 6,
			unlocked = accUnlocked,
			slots = {nil,nil,nil,nil,nil,nil},
			bag = {},
		}
		state.run.talisman = t
	else
		t.maxSlots = 6
		t.unlocked = clamp(tonumber(t.unlocked or accUnlocked), 0, 6)
		local s = t.slots or {}
		-- 長さを6に正規化
		t.slots = { s[1], s[2], s[3], s[4], s[5], s[6] }
	end
	return state.run.talisman
end

function M.getEquippedIds(state: any): {string}
	local t = state and state.run and state.run.talisman
	if not t or not t.slots then return {} end
	local out = {}
	for i=1, math.min(6, #t.slots) do
		local id = t.slots[i]
		if id ~= nil then table.insert(out, id) end
	end
	return out
end

return M
