-- P5: Omamori（お守り）受け口 — いまは no-op（ledger対応＋S-8: 装備ID表示）
local RS = game:GetService("ReplicatedStorage")

local Hooks_Omamori = nil
do
	local ok, mod = pcall(function()
		local SharedModules = RS:WaitForChild("SharedModules")
		local Hooks = SharedModules:FindFirstChild("hooks")
		if not Hooks then return nil end
		return require(Hooks:WaitForChild("omamori"))
	end)
	if ok and mod then Hooks_Omamori = mod end
end

local P5 = {}

function P5.applyOmamori(roles, mon, pts, state, ctx)
	local mon0, pts0 = mon, pts
	if Hooks_Omamori and typeof(Hooks_Omamori.apply) == "function" then
		local ok, r_roles, r_mon, r_pts = pcall(Hooks_Omamori.apply, roles, mon, pts, state, ctx)
		if ok and r_roles ~= nil and r_mon ~= nil and r_pts ~= nil then
			roles, mon, pts = r_roles, r_mon, r_pts
		end
	end
	-- S-8: 装備IDログ（no-op）
	local ids = (ctx and ctx.equipped and ctx.equipped.omamori) or {}
	local note = "omamori effects"
	if typeof(ids)=="table" and #ids > 0 then
		note = note .. " IDs=" .. table.concat(ids, ",")
	end
	if ctx and typeof(ctx.add) == "function" then
		ctx:add("P5_omamori", mon - mon0, pts - pts0, note)
	end
	return roles, mon, pts
end

return P5
