-- shared/TalismanDefs.lua
-- v0.1 Step0: 参照だけ。enabled=false の雛形
local M = {}

M.registry = {
	-- 開発用サンプル（Step4で enabled=true にする）
	dev_plus1 =       { id="dev_plus1",       nameJa="開発+1",     nameEn="Dev +1",     enabled=false },
	dev_gokou_plus5 = { id="dev_gokou_plus5", nameJa="五光+5",     nameEn="Gokou +5",   enabled=false },
	dev_sake_plus3 =  { id="dev_sake_plus3",  nameJa="酒+3",       nameEn="Sake +3",    enabled=false },
}

function M.get(id)
	local d = M.registry[id]
	if not d or d.enabled == false then return nil end
	return d
end

return M
