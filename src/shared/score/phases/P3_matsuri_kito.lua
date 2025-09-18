-- ReplicatedStorage/SharedModules/score/phases/P3_matsuri_kito.lua
-- v0.9.3-S4 P3: 祭事/寅の上乗せ（ledger対応）

local RS = game:GetService("ReplicatedStorage")
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))
local K = require(script.Parent.Parent.constants)

local P3 = {}

-- 入力: roles(table), monBase(number), ptsBase(number), state(table?), ctx?
-- 出力: mon(number), pts(number)
function P3.applyMatsuriAndKito(roles: any, mon: number, pts: number, state: any, ctx: any)
	local mon0, pts0 = mon, pts

	if typeof(state) == "table" then
		-- 祭事
		local levels = RunDeckUtil.getMatsuriLevels(state) or {}
		if next(levels) ~= nil then
			local yakuList = {}
			for roleKey, v in pairs(roles) do
				if v and v > 0 then
					local yaku = K.ROLE_TO_YAKU[roleKey]
					if yaku then table.insert(yakuList, yaku) end
				end
			end
			for _, yakuId in ipairs(yakuList) do
				local festivals = K.YAKU_TO_SAI[yakuId]
				if festivals then
					for _, fid in ipairs(festivals) do
						local lv = tonumber(levels[fid] or 0) or 0
						if lv > 0 then
							local coeff = K.MATSURI_COEFF[fid]
							if coeff then
								mon += lv * (coeff[1] or 0)
								pts += lv * (coeff[2] or 0)
							end
						end
					end
				end
			end
		end

		-- 干支：寅（Ptsに +1/Lv）
		do
			local kitoLevels = (RunDeckUtil.getKitoLevels and RunDeckUtil.getKitoLevels(state)) or state.kito or {}
			local toraLv = tonumber(kitoLevels.tora or kitoLevels["kito_tora"] or 0) or 0
			if toraLv > 0 then pts += toraLv end
		end
	end

	-- ledger: P3の寄与（差分）
	if ctx and typeof(ctx.add) == "function" then
		ctx:add("P3_matsuri_kito", mon - mon0, pts - pts0, "matsuri/kito add-ons")
	end

	return mon, pts
end

return P3
