-- hooks/omamori.lua — S-3 no-op。将来ここにお守りの効果を追加。
local M = {}

function M.apply(roles, mon, pts, state)
	return roles, mon, pts
end

return M
