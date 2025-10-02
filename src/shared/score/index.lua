-- ReplicatedStorage/SharedModules/score/index.lua
-- v0.9.3-S10 P4_talisman no-op配管＋equipped受け渡し（挙動不変）

local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local K   = require(script.Parent.constants)
local Ctx = require(script.Parent.ctx)

local P1 = require(script.Parent.phases.P1_count)
local P2 = require(script.Parent.phases.P2_roles)
local P3 = require(script.Parent.phases.P3_matsuri_kito)
local P4 = require(script.Parent.phases.P4_talisman)    -- ← no-op 実体
local P5 = require(script.Parent.phases.P5_omamori)     -- ← no-op（既存/無ければ本回答のstubを使用）
local PF = require(script.Parent.phases.finalize)

-- hooks
local TalHook = require(script.Parent.hooks.talisman)   -- ← ★ 新設フック

-- スコープ付きロガー（タグ=Score）
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

local function devLog(msg)
	if not RunService:IsStudio() then return end
	if LOG and typeof(LOG.info) == "function" then
		LOG.info(msg)
	else
		warn("[Score][DEV] " .. tostring(msg))
	end
end

local M = {}

function M.evaluate(takenCards, state)
	local ctx = Ctx.new()

	-- S2: state → ctx.equipped へ“正式形”で転記（talismanのみ・他は将来拡張）
	--     旧来の state.equipped/loadout 等があっても、talismanは run.talisman から読むのを優先
	do
		local equipped = {}
		equipped.talisman = TalHook.readEquipped(state) -- => { {id=...}, ... } or {}
		-- 互換: 既存の他スロットがあれば温存
		local legacy = (typeof(state)=="table") and (state.equipped or state.loadout or state.equip) or nil
		if typeof(legacy)=="table" then
			for k,v in pairs(legacy) do
				if k ~= "talisman" then
					equipped[k] = v
				end
			end
		end
		if typeof(ctx.setEquipped) == "function" then
			ctx:setEquipped(equipped)
		else
			ctx.equipped = equipped
		end
	end

	-- P1: カウント
	local c = P1.counts(takenCards)

	-- P2: 役 → mon/pts 基礎
	local roles, mon, pts = P2.evaluateRoles(takenCards, c, ctx)

	-- P3: 祭事/寅の上乗せ
	mon, pts = P3.applyMatsuriAndKito(roles, mon, pts, state, ctx)

	-- P4: 護符（no-op: 装備数ログとledger追記のみ。数値は不変）
	roles, mon, pts = P4.applyTalisman(roles, mon, pts, state, ctx)

	-- P5: お守り（no-op/将来ON）
	roles, mon, pts = P5.applyOmamori(roles, mon, pts, state, ctx)

	-- Dev: ledger出力（Studioのみ）
	if RunService:IsStudio() then
		for _,line in ipairs(ctx.ledger) do
			devLog(string.format("%s: dmon=%.3f dpts=%.3f %s",
				tostring(line.phase),
				tonumber(line.dmon or 0),
				tonumber(line.dpts or 0),
				tostring(line.note or "")
			))
		end
	end

	-- finalize（唯一式）— 現状 factor=1 で挙動不変
	local total, _mon, _pts, factor = PF.finalize(mon, pts, ctx)
	return total, roles, { mon = mon, pts = pts }
end

-- 互換API
function M.getFestivalStat(fid, level)
	local lv = tonumber(level or 0) or 0
	local coeff = K.MATSURI_COEFF[fid]
	if not coeff then return 0, 0 end
	return lv * (coeff[1] or 0), lv * (coeff[2] or 0)
end

function M.getFestivalsForYaku(yakuId)
	return K.YAKU_TO_SAI[yakuId] or {}
end

function M.getKitoPts(effectId, level)
	if effectId == "tora" or effectId == "kito.tora" then
		return tonumber(level or 0) or 0
	end
	return 0
end

return M
