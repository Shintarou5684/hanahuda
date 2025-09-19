-- LocaleUtil.lua (client/shared)
local RS = game:GetService("ReplicatedStorage")
local Locale = require(RS:WaitForChild("Config"):WaitForChild("Locale"))

local M = {}

function M.norm(v:string?)
	v = tostring(v or ""):lower()
	if v=="ja" or v=="en" then return v end
	if v=="jp" then return "ja" end
	return nil
end

function M.safeGlobal()
	if typeof(Locale.getGlobal)=="function" then
		local ok, val = pcall(Locale.getGlobal)
		if ok then return M.norm(val) end
	end
	return nil
end

function M.pickInitial()
	return M.safeGlobal()
	    or (type(Locale.pick)=="function" and (M.norm(Locale.pick()) or "en"))
	    or "en"
end

return M
