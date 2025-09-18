-- ReplicatedStorage/SharedModules/score/index.lua
-- v0.9.3-S9 finalize＋equipped受け渡し（挙動不変）

local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local K   = require(script.Parent.constants)
local Ctx = require(script.Parent.ctx)

local P1 = require(script.Parent.phases.P1_count)
local P2 = require(script.Parent.phases.P2_roles)
local P3 = require(script.Parent.phases.P3_matsuri_kito)
local P4 = require(script.Parent.phases.P4_talisman)
local P5 = require(script.Parent.phases.P5_omamori)
local PF = require(script.Parent.phases.finalize)  -- ★ S-9

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

	-- S-8: state から装備IDを通す（配線のみ）
	if typeof(state) == "table" then
		local eq = state.equipped or state.loadout or state.equip or {}
		if typeof(ctx.setEquipped) == "function" then
			ctx:setEquipped(eq)
		end
	end

	-- P1: カウント
	local c = P1.counts(takenCards)

	-- P2: 役 → mon/pts 基礎
	local roles, mon, pts = P2.evaluateRoles(takenCards, c, ctx)

	-- P3: 祭事/寅の上乗せ
	mon, pts = P3.applyMatsuriAndKito(roles, mon, pts, state, ctx)

	-- P4: 護符（no-op, IDsログ）
	roles, mon, pts = P4.applyTalisman(roles, mon, pts, state, ctx)

	-- P5: お守り（no-op, IDsログ）
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

	-- ★ S-9: finalize（唯一の式）— 挙動は不変（factor=1 のため）
	local total, _mon, _pts, factor = PF.finalize(mon, pts, ctx)
	-- factor は今は 1。将来 add/mul が入ったらここで一括適用。

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
	if effectId == "tora" or effectId == "kito_tora" then
		return tonumber(level or 0) or 0
	end
	return 0
end

return M
