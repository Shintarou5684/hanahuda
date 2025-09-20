-- ReplicatedStorage/SharedModules/score/phases/P5_omamori.lua
-- v0.9.3-S11: hooks の場所を固定参照（SharedModules/score/hooks/omamori）
-- いまは no-op（ledger対応＋装備IDログ）。Hooks.apply があれば安全に呼ぶ。

local RS = game:GetService("ReplicatedStorage")

-- Hooks（固定パスで参照：SharedModules/score/hooks/omamori）
-- ※本プロジェクトでは必ず存在する前提
local Hooks_Omamori = (function()
	local SharedModules = RS:WaitForChild("SharedModules")
	local Score         = SharedModules:WaitForChild("score")
	local HooksFolder   = Score:WaitForChild("hooks")
	local Mod           = require(HooksFolder:WaitForChild("omamori"))
	return Mod
end)()

--========================
-- utils
--========================

local function toIdList(eq)
	-- eq: { "id", ... } or { {id="..."}, ... }
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
		ctx:add("P5_omamori", dmon or 0, dpts or 0, note or "")
	else
		ctx.ledger = ctx.ledger or {}
		table.insert(ctx.ledger, {
			phase = "P5_omamori",
			dmon  = dmon or 0,
			dpts  = dpts or 0,
			note  = note or "",
		})
	end
end

--========================
-- API
--========================

local P5 = {}

function P5.applyOmamori(roles, mon, pts, state, ctx)
	local mon0, pts0 = mon, pts

	-- 1) Hooks.apply を呼ぶ（no-opでもOK）
	if Hooks_Omamori and typeof(Hooks_Omamori.apply) == "function" then
		local ok, r_roles, r_mon, r_pts = pcall(Hooks_Omamori.apply, roles, mon, pts, state, ctx)
		if ok and r_roles ~= nil and r_mon ~= nil and r_pts ~= nil then
			roles, mon, pts = r_roles, r_mon, r_pts
		end
	end

	-- 2) 装備IDログ（no-op）。両形式に対応してCSV化
	local eq = (ctx and ctx.equipped and ctx.equipped.omamori) or {}
	local ids = toIdList(eq)
	local note = "omamori effects"
	if #ids > 0 then
		note = note .. " IDs=" .. table.concat(ids, ",")
	end

	-- 3) ledger 追記（差分0か、Hooksが数値変更していればその差分）
	addLedger(ctx, (mon - mon0), (pts - pts0), note)

	return roles, mon, pts
end

return P5
