-- ReplicatedStorage/SharedModules/score/ctx.lua
-- v0.9.3-S9 計算用コンテキスト
-- ・ledger で各フェーズの寄与を記録
-- ・equipped（S-8）：護符/お守りの装備ID群を通す
-- ・mult（S-9）：将来の倍率合成先（add=加算倍率総和, mul=乗算倍率積）

local Ctx = {}
Ctx.__index = Ctx

function Ctx.new()
	return setmetatable({
		mon = 0,
		pts = 0,
		roles = {},
		ledger = {}, -- { {phase="P2_roles", dmon=+X, dpts=+Y, note="..."} , ... }
		equipped = { talisman = {}, omamori = {} }, -- S-8
		mult = { add = 0, mul = 1 }, -- S-9 finalize用（現状add=0,mul=1で挙動不変）
	}, Ctx)
end

function Ctx:add(phase: string, dmon: number?, dpts: number?, note: string?)
	table.insert(self.ledger, {
		phase = phase,
		dmon  = dmon or 0,
		dpts  = dpts or 0,
		note  = note,
	})
end

-- S-8: 装備IDセット（配列 or set を許容）
local function toIdList(v)
	local out = {}
	if typeof(v) ~= "table" then return out end
	local n = 0
	for k, val in pairs(v) do
		if typeof(k)=="number" then
			-- 配列
			if val ~= nil then
				n += 1; out[n] = tostring(val)
			end
		else
			-- set/dict
			if val then
				n += 1; out[n] = tostring(k)
			end
		end
	end
	return out
end

function Ctx:setEquipped(e)
	if typeof(e) ~= "table" then return end
	self.equipped = {
		talisman = toIdList(e.talisman or e.talismans or e.tlmn or {}),
		omamori  = toIdList(e.omamori  or e.oma      or e.omo  or {}),
	}
end

return Ctx
