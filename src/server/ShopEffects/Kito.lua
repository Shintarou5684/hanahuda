-- src/server/ShopEffects/Kito.lua
-- v0.9.15 Kito（祈祷）— DOT ONLY（kito.* を唯一の真実として運用）
--  - 子(ko)UI先行起動のFIXを維持（v0.9.13）
--  - Kito.recordFromPick(state, effectId, payload, meta) を維持
--  - ★破壊的変更: アンダーバーID（kito_）の受理/変換を全廃。渡されてもエラーを返す。

local RS   = game:GetService("ReplicatedStorage")
local SSS  = game:GetService("ServerScriptService")

local Shared  = RS:WaitForChild("SharedModules")
local Config  = RS:WaitForChild("Config")

local EffectsRegistry = require(Shared:WaitForChild("Deck"):WaitForChild("EffectsRegistry"))
local Balance        = require(Config:WaitForChild("Balance"))

--========================
-- KitoPickCore lazy-load
--========================
local KitoPickCore = nil
local function lazyGetKitoPickCore()
	if not KitoPickCore then
		KitoPickCore = require(SSS:WaitForChild("KitoPickCore"))
	end
	return KitoPickCore
end

--========================
-- Module
--========================
local Kito = {}

-- ★ドットIDを唯一の真実に統一
Kito.ID = {
	USHI = "kito.ushi",
	TORA = "kito.tora",
	TORI = "kito.tori",
	MI   = "kito.mi",
	KO   = "kito.ko",
}

local DEFAULTS = { CAP_MON = 999999 }
local function msg(s) return s end

local function ensureBonus(state) state.bonus = state.bonus or {}; return state.bonus end
local function ensureKito(state)  state.kito  = state.kito  or {}; return state.kito  end

local function isArray(t) if typeof(t)~="table" then return false end for i=1,#t do if t[i]==nil then return false end end return true end
local function isNonEmptyArray(t) return isArray(t) and #t>0 end
local function normalizeArrayOrNil(t) if isNonEmptyArray(t) then return t end return nil end

-- preferKind は当面 "hikari" 固定（将来の拡張に備え関数化）
local function normPreferKind(s: string?) if s=="bright" then return "hikari" end return "hikari" end

local function resolveRunIdFrom(anyTable)
	if type(anyTable)~="table" then return nil end
	local direct = anyTable.runId or anyTable.deckRunId or anyTable.id or anyTable.deckRunID or anyTable.runID
	if direct ~= nil then return direct end
	local run = anyTable.run
	if type(run)=="table" then
		return run.runId or run.deckRunId or run.id or run.deckRunID or run.runID
	end
	return nil
end
local function resolveRunId(state, ctx) return resolveRunIdFrom(ctx) or resolveRunIdFrom(state) end

--========================
-- 記録ヘルパ
--========================
local function sanitizePayloadForRecord(payload:any)
	if typeof(payload) ~= "table" then return nil end
	local out = {}
	if payload.preferKind ~= nil then out.preferKind = payload.preferKind end
	return (next(out) ~= nil) and out or nil
end

local function shouldRecord(ctx:any)
	return not (typeof(ctx) == "table" and ctx.__fromChild == true)
end

local function recordLastKito(state:any, effectId:string, payload:any?, meta:any?, ctx:any?)
	if not shouldRecord(ctx) then return end
	state.run = state.run or {}
	state.run.kito_last = {
		v       = 1,
		id      = tostring(effectId or ""),
		payload = sanitizePayloadForRecord(payload),
		meta    = (typeof(meta)=="table") and {
			changed    = meta.changed,
			pickReason = meta.pickReason,
			targetUid  = meta.targetUid,
			targetCode = meta.targetCode,
		} or nil,
		t       = os.time(),
	}
end

--========================
-- 内蔵エフェクト
--========================

-- 丑：所持文2倍（上限あり）
local function effect_ushi(state, ctx)
	local cap    = (ctx and ctx.capMon) or DEFAULTS.CAP_MON
	local before = tonumber(state.mon or 0) or 0
	local after  = math.min(before * 2, cap)
	state.mon    = after
	recordLastKito(state, Kito.ID.USHI, nil, { changed = 1 }, ctx)
	return true, msg(("丑：所持文2倍（%d → %d, 上限=%d）"):format(before, after, cap))
end

-- 寅：取り札の得点+1（累積）
local function effect_tora(state, ctx)
	local b = ensureBonus(state); b.takenPointPlus = (b.takenPointPlus or 0) + 1
	local k = ensureKito(state);  k.tora = (tonumber(k.tora) or 0) + 1
	recordLastKito(state, Kito.ID.TORA, nil, { changed = 1 }, ctx)
	return true, msg(("寅：取り札の得点+1（累計+%d / Lv=%d）"):format(b.takenPointPlus, k.tora))
end

-- Deck/Effects 経由の共通適用（UI起動にも対応）
local function apply_via_effects(effectModuleId:string, labelJP:string, state, ctx, preferKind:string?)
	local runId = resolveRunId(state, ctx)
	if runId == nil then
		return false, (labelJP .. "：runId が未指定です")
	end

	local uids      = normalizeArrayOrNil(ctx and ctx.uids)
	local poolUids  = normalizeArrayOrNil(ctx and ctx.poolUids)
	local codes     = normalizeArrayOrNil(ctx and ctx.codes)
	local poolCodes = normalizeArrayOrNil(ctx and ctx.poolCodes)

	if Balance.KITO_UI_ENABLED == true then
		local hasAnyInput = (uids~=nil) or (poolUids~=nil) or (codes~=nil) or (poolCodes~=nil)
		if not hasAnyInput then
			local player = (ctx and ctx.player) or (state and state.player)
			if not player then
				return false, (labelJP .. "：UIモードですが player が不明です（ctx.player を渡してください）")
			end
			lazyGetKitoPickCore().startFor(player, { runId = runId }, effectModuleId, preferKind)
			return true, (labelJP .. "：候補を表示しました。対象を選んでください。")
		end
	end

	local payload = {
		uids       = uids, poolUids = poolUids,
		codes      = codes, poolCodes = poolCodes,
		preferKind = preferKind,
		tag        = "eff:" .. tostring(effectModuleId),
	}
	local res = EffectsRegistry.apply(runId, effectModuleId, payload)
	if not res or res.ok ~= true then
		local reason = (res and (res.error or res.message)) or "unknown"
		return false, (labelJP .. "：失敗（" .. tostring(reason) .. "）")
	end

	recordLastKito(state, effectModuleId, payload, res, ctx)

	local changed = tonumber(res.changed or 0) or 0
	if changed > 0 then
		return true, (labelJP .. "：1枚を変換（成功）")
	else
		return true, (labelJP .. "：変換対象なし（" .. tostring(res.meta or "no-eligible-target") .. "）")
	end
end

-- 酉 / 巳（Deck/Effectsを呼ぶタイプ）
local function effect_tori(state, ctx)
	local preferKind = normPreferKind(ctx and ctx.preferKind)
	return apply_via_effects("kito.tori_brighten", "酉", state, ctx, preferKind)
end
local function effect_mi(state, ctx)
	return apply_via_effects("kito.mi_venom", "巳", state, ctx, nil)
end

-- 子：最後の本体KITOを再発火（自分自身は記録しない）
local function effect_ko(state, ctx)
	state.run = state.run or {}
	local last = state.run.kito_last
	if typeof(last) ~= "table" or typeof(last.id) ~= "string" or last.id == "" then
		return false, "子：前回の祈祷がありません"
	end
	if last.id == Kito.ID.KO or last.id == "kito.ko" then
		return false, "子：前回が子のため再発火不可"
	end

	ctx = ctx or {} ; ctx.__fromChild = true
	if typeof(last.payload) == "table" and ctx.preferKind == nil then
		ctx.preferKind = last.payload.preferKind
	end
	local id = last.id

	-- 先にUI（Deck/Effects系×未指定）なら起動
	do
		local uiEnabled = (Balance and Balance.KITO_UI_ENABLED == true)
		local noTargetGiven =
			(not isNonEmptyArray(ctx.uids))
			and (not isNonEmptyArray(ctx.poolUids))
			and (not isNonEmptyArray(ctx.codes))
			and (not isNonEmptyArray(ctx.poolCodes))
		if uiEnabled and typeof(id)=="string" and id:sub(1,5)=="kito." and noTargetGiven then
			local player = (ctx and ctx.player) or (state and state.player)
			if player then
				local runId = resolveRunId(state, ctx)
				if runId == nil then return false, "子：runId が未指定です" end
				local Core = lazyGetKitoPickCore()
				if Core and type(Core.startFor)=="function" then
					Core.startFor(player, { runId = runId }, id, ctx.preferKind)
					return true, "子：候補を表示しました。対象を選んでください。"
				end
			end
		end
	end

	-- 内蔵（dotのみ）
	if id == Kito.ID.TORA or id == "kito.tora" then return effect_tora(state, ctx)
	elseif id == Kito.ID.USHI or id == "kito.ushi" then return effect_ushi(state, ctx)
	elseif id == Kito.ID.MI   or id == "kito.mi"   then return effect_mi(state, ctx)
	elseif id == Kito.ID.TORI or id == "kito.tori" then return effect_tori(state, ctx) end

	-- Deck/Effects系（dotのみ）
	if typeof(id)=="string" and id:sub(1,5) == "kito." then
		return apply_via_effects(id, "子", state, ctx, ctx.preferKind)
	end

	return false, ("子：未知の前回ID: %s"):format(tostring(id))
end

--========================
-- ディスパッチ（dotのみ）
--========================
local DISPATCH = {
	[Kito.ID.USHI] = effect_ushi,
	[Kito.ID.TORA] = effect_tora,
	[Kito.ID.TORI] = effect_tori,
	[Kito.ID.MI]   = effect_mi,
	[Kito.ID.KO]   = effect_ko,

	["kito.ushi"]  = effect_ushi,
	["kito.tora"]  = effect_tora,
	["kito.tori"]  = effect_tori,
	["kito.mi"]    = effect_mi,
	["kito.ko"]    = effect_ko,
}

--========================
-- ブリッジ（同義dot→モジュールID）※アンダーバーKEYは廃止
--========================
local KITO_BRIDGE_MAP = {
	["kito.usagi"]         = { label = "卯", moduleId = "kito.usagi_ribbon" },
	["kito.usagi_ribbon"]  = { label = "卯", moduleId = "kito.usagi_ribbon" },

	["kito.uma"]           = { label = "午", moduleId = "kito.uma_seed" },
	["kito.uma_seed"]      = { label = "午", moduleId = "kito.uma_seed" },

	["kito.inu"]           = { label = "戌", moduleId = "kito.inu_chaff2" },
	["kito.inu_chaff2"]    = { label = "戌", moduleId = "kito.inu_chaff2" },
	["kito.inu_two_chaff"] = { label = "戌", moduleId = "kito.inu_chaff2" },

	["kito.i"]             = { label = "亥", moduleId = "kito.i_sake" },
	["kito.i_sake"]        = { label = "亥", moduleId = "kito.i_sake" },

	["kito.hitsuji"]       = { label = "未", moduleId = "kito.hitsuji_prune" },
	["kito.hitsuji_prune"] = { label = "未", moduleId = "kito.hitsuji_prune" },
}

--========================
-- 公開 I/F
--========================
function Kito.apply(effectId, state, ctx)
	if typeof(state) ~= "table" then return false, "state が無効です" end

	local key = tostring(effectId or "")

	-- ★明示拒否：アンダーバーIDは非対応（変換しない）
	if typeof(key)=="string" and key:sub(1,5) == "kito_" then
		return false, ("不明な祈祷ID（kito_ は非対応です。kito. を使用してください）: %s"):format(key)
	end

	-- 内蔵ディスパッチ（dot）
	local fn = DISPATCH[key]
	if fn then
		local ok, message = fn(state, ctx)
		return ok == true, tostring(message or "")
	end

	-- ブリッジ（dot → モジュールID）
	local br = KITO_BRIDGE_MAP[key]
	if br then
		return apply_via_effects(br.moduleId, br.label, state, ctx, nil)
	end

	-- Deck/Effects 登録IDへ直通（dotのみ）
	if typeof(key)=="string" and key:sub(1,5)=="kito." then
		return apply_via_effects(key, "祈祷", state, ctx, nil)
	end

	return false, ("不明な祈祷ID: %s"):format(tostring(effectId))
end

-- ★公開：KitoPickServerから成功時に呼ぶ“記録フック”
function Kito.recordFromPick(state:any, effectModuleId:string, payload:any?, meta:any?)
	-- ctx=nil（= __fromChild=false で記録する）
	recordLastKito(state, effectModuleId, payload, meta, nil)
end

return Kito
