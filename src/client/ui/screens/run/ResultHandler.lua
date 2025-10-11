-- screens/run/ResultHandler.lua
local M = {}

function M.handle(modal, deps, lang, dataA, dataB)
	-- 既存 RunScreen.onStageResult のロジックをそのまま移植（簡略形の骨）
	-- ここでは署名の解決と final/通常表示の分岐だけ残す
	local data = nil
	if typeof(dataA)=="boolean" and dataA==true and typeof(dataB)=="table" then data=dataB
	elseif typeof(dataA)=="table" then data=dataA else return end

	local function go(where)
		local Nav = deps and deps.Nav
		if Nav and type(Nav.next)=="function" then
			Nav:next((where=="home") and "home" or "next")
		elseif deps and deps.DecideNext then
			deps.DecideNext:FireServer((where=="home") and "home" or "next")
		end
	end

	-- …ロック/clears 判定などは既存のまま移植…
	modal:show(data)
end

return M
