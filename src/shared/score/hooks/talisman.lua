-- ReplicatedStorage/SharedModules/score/hooks/talisman.lua
-- v0.9.4-S5: 護符の効果をスコア（mon）へ反映
-- 公開I/F:
--   readEquipped(state) -> { {id="..."}, ... }
--   apply(roles, mon, pts, state, ctx) -> roles, mon, pts
-- 互換: 既存の roles/mon/pts の型を変更しない（mon のみ加算）


local RS = game:GetService("ReplicatedStorage")
local SharedModules = RS:WaitForChild("SharedModules")
local TalismanState = require(SharedModules:WaitForChild("TalismanState"))

-- TalismanDefs は配置が「Shared/TalismanDefs.lua」想定。
-- プロジェクト差に備えてフォールバックも用意。
local function requireTalismanDefs()
	-- 1) ReplicatedStorage/Shared/TalismanDefs
	local Shared = RS:FindFirstChild("Shared")
	if Shared and Shared:FindFirstChild("TalismanDefs") then
		return require(Shared.TalismanDefs)
	end
	-- 2) ReplicatedStorage/SharedModules/TalismanDefs
	if SharedModules:FindFirstChild("TalismanDefs") then
		return require(SharedModules.TalismanDefs)
	end
	error("TalismanDefs not found under RS/Shared or RS/SharedModules")
end

local TalismanDefs = requireTalismanDefs()

local M = {}

--==================================================
-- utils
--==================================================

local function cloneArray(t)
	if table.clone then return table.clone(t or {}) end
	local r = {}
	for i,v in ipairs(t or {}) do r[i] = v end
	return r
end

-- roles は {"gokou","shikou",...} or {gokou=true,...} の両対応
local function hasRole(roles, key)
	if type(roles) ~= "table" or not key then return false end
	if roles[key] == true then return true end
	for _, v in ipairs(roles) do
		if v == key then return true end
	end
	return false
end

local function anyRole(roles, keys)
	for _, k in ipairs(keys or {}) do
		if hasRole(roles, k) then return true end
	end
	return false
end

--==================================================
-- API
--==================================================

-- state.run.talisman.slots を唯一の情報源として読み取り、
-- ctx.equipped.talisman 向けの正規形（配列 { {id=...}, ... }）に変換
function M.readEquipped(state)
	local ids = TalismanState.getEquippedIds(state) -- { "id", ... } or {}
	local out = {}
	if typeof(ids) ~= "table" then return out end
	for i = 1, #ids do
		local id = ids[i]
		if id ~= nil then
			table.insert(out, { id = tostring(id) })
		end
	end
	return out
end

-- S5: 護符効果を mon に反映（roles/pts は不変）
-- ・純関数的に動作（副作用なし）。ログ出力だけ任意で対応（ctx.log があれば）。
-- ・Defs 仕様:
--    - enabled == false なら無効
--    - stack == false なら同一IDは1回まで
--    - limit が数値ならその回数まで適用
--    - effect:
--        type="add_mon", amount=+N
--        type="add_role_mon", role="gokou", amount=+N
--        type="add_any_role_mon", roles={...}, amount=+N
function M.apply(roles, mon, pts, state, ctx)
	-- 安全な既定値
	local r   = roles or {}
	local m   = tonumber(mon) or 0
	local p   = pts   -- そのまま返す
	local ids = TalismanState.getEquippedIds(state) or {}

	if type(ids) ~= "table" or #ids == 0 then
		return r, m, p
	end

	-- スタック制御
	local appliedCount = {}
	local totalAdd = 0

	for _, id in ipairs(ids) do
		if type(id) == "string" and #id > 0 then
			-- Defs.get(id) 優先（存在しない場合は registry 直参照を許容）
			local def = nil
			if type(TalismanDefs.get) == "function" then
				def = TalismanDefs.get(id)
			elseif TalismanDefs.registry then
				def = TalismanDefs.registry[id]
				if def and def.enabled == false then def = nil end
			end

			if def then
				-- スタック／上限
				local cnt = appliedCount[def.id] or 0
				if def.stack == false and cnt >= 1 then
					-- 何もしない
				elseif type(def.limit) == "number" and cnt >= def.limit then
					-- 何もしない
				else
					local eff = def.effect or {}
					local delta = 0

					if eff.type == "add_mon" then
						delta = tonumber(eff.amount) or 0

					elseif eff.type == "add_role_mon" then
						if eff.role and hasRole(r, eff.role) then
							delta = tonumber(eff.amount) or 0
						end

					elseif eff.type == "add_any_role_mon" then
						if anyRole(r, eff.roles) then
							delta = tonumber(eff.amount) or 0
						end
					end

					if delta ~= 0 then
						appliedCount[def.id] = cnt + 1
						totalAdd = totalAdd + delta
						if ctx and type(ctx.log) == "function" then
							pcall(ctx.log, "[P5_score] talisman=%s delta=%d", def.id, delta)
						end
					end
				end
			end
		end
	end

	if totalAdd ~= 0 then
		m = m + totalAdd
	end

	return r, m, p
end

return M
