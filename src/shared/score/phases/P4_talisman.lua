-- ReplicatedStorage/SharedModules/score/phases/P4_talisman.lua
-- v0.9.3-S10: P4 受け口の堅牢化（ID正規化＋ledger no-op）
-- ・Hooks.apply があれば呼ぶ（安全 pcall）
-- ・無くても no-op で ledger に記録
-- ・ctx.equipped.talisman は { "id", ... } / { {id="..."}, ... } の両方を許容

local RS = game:GetService("ReplicatedStorage")

-- optional: Logger（StudioのみINFO）
local LOG = nil
do
	local ok, Logger = pcall(function()
		local SharedModules = RS:WaitForChild("SharedModules")
		return require(SharedModules:WaitForChild("Logger"))
	end)
	if ok and Logger and typeof(Logger.scope) == "function" then
		LOG = Logger.scope("Score")
	end
end

-- optional: Hooks（ある場合のみ使用）
local Hooks_Talisman = nil
do
	local ok, mod = pcall(function()
		local SharedModules = RS:WaitForChild("SharedModules")
		local Hooks = SharedModules:FindFirstChild("hooks")
		if not Hooks then return nil end
		return require(Hooks:WaitForChild("talisman"))
	end)
	if ok and mod then Hooks_Talisman = mod end
end

local function toIdList(eq)
	-- eq: { "dev_plus1", ... } or { {id="dev_plus1"}, ... }
	local out = {}
	if typeof(eq) ~= "table" then return out end
	for i = 1, #eq do
		local v = eq[i]
		if typeof(v) == "string" then
			table.insert(out, v)
		elseif typeof(v) == "table" and v.id ~= nil then
			table.insert(out, tostring(v.id))
		end
	end
	return out
end

local function addLedger(ctx, dmon, dpts, note)
	ctx = ctx or {}
	if typeof(ctx.add) == "function" then
		ctx:add("P4_talisman", dmon or 0, dpts or 0, note or "")
	else
		ctx.ledger = ctx.ledger or {}
		table.insert(ctx.ledger, { phase = "P4_talisman", dmon = dmon or 0, dpts = dpts or 0, note = note or "" })
	end
end

local P4 = {}

function P4.applyTalisman(roles, mon, pts, state, ctx)
	local mon0, pts0 = mon, pts

	-- 1) 可能なら Hooks.apply を呼ぶ（no-opでもOK）
	if Hooks_Talisman and typeof(Hooks_Talisman.apply) == "function" then
		local ok, r_roles, r_mon, r_pts = pcall(Hooks_Talisman.apply, roles, mon, pts, state, ctx)
		if ok and r_roles ~= nil and r_mon ~= nil and r_pts ~= nil then
			roles, mon, pts = r_roles, r_mon, r_pts
		end
	end

	-- 2) 装備IDのログ（no-op）。両形式に対応してCSV化
	local eq = (ctx and ctx.equipped and ctx.equipped.talisman) or {}
	local ids = toIdList(eq)
	local note = "no-op"
	if #ids > 0 then
		note = ("no-op IDs=%s"):format(table.concat(ids, ","))
	end

	-- 3) ledger 追記（差分0か、Hooksが数値変更していればその差分）
	local dmon, dpts = (mon - mon0), (pts - pts0)
	addLedger(ctx, dmon, dpts, note)

	-- 4) Studioログ
	local RunService = game:GetService("RunService")
	if LOG and RunService:IsStudio() then
		LOG.info(("[P4_talisman] equipped=%d %s dmon=%.3f dpts=%.3f"):format(#ids, note, dmon, dpts))
	end

	return roles, mon, pts
end

return P4
