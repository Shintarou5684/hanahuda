-- hooks/talisman.lua — S-3 no-op。将来ここに護符の加点/倍率を追加。
local M = {}

-- 期待I/F: apply(roles, mon, pts, state) -> roles, mon, pts
function M.apply(roles, mon, pts, state)
	return roles, mon, pts
end

return M
