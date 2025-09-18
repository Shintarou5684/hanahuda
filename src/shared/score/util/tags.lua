-- ReplicatedStorage/SharedModules/score/util/tags.lua
-- v0.9.3-S2 タグ集合（現行同等）

local M = {}

function M.toTagSet(tags: any): {[string]: boolean}
	local set: {[string]: boolean} = {}
	if typeof(tags) == "table" then
		for k,v in pairs(tags) do
			if typeof(k) == "number" then
				set[v] = true
			else
				set[k] = (v == nil) and true or v
			end
		end
	end
	return set
end

function M.hasTags(card: any, names: {string}?): boolean
	local set = M.toTagSet(card and card.tags)
	for _,name in ipairs(names or {}) do
		if not set[name] then return false end
	end
	return true
end

return M
