-- screens/run/StateCache.lua
local M = {}
function M.new()
	return { state=nil, total=0 }
end
function M.onState(cache, st) cache.state = st end
function M.onScore(cache, total) cache.total = tonumber(total or 0) or 0 end
return M
