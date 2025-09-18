-- ReplicatedStorage/SharedModules/score/phases/P1_count.lua
-- v0.9.3-S2 P1: 枚数/月/タグ集計（現行countsと同値）

local P0 = require(script.Parent.P0_normalize)

local P1 = {}

function P1.counts(cards: {any}?): {bright:number, seed:number, ribbon:number, chaff:number, months:any, tags:any}
	local c = {bright=0, seed=0, ribbon=0, chaff=0, months={}, tags={}}
	for _,card in ipairs(cards or {}) do
		local k = P0.normKind(card and card.kind)
		if k then c[k] += 1 end
		if card and card.month then
			c.months[card.month] = (c.months[card.month] or 0) + 1
		end
		local tset = P0.toTagSet(card and card.tags)
		for t,_ in pairs(tset) do
			c.tags[t] = (c.tags[t] or 0) + 1
		end
	end
	return c
end

return P1
