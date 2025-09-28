-- src/server/ShopEffects/Kito.lua
-- v0.9.10 Kito（祈祷）: UIDファースト / 酉・巳は EffectsRegistry に委譲 / UI分岐を厳格化
--  - 丑/寅：サーバ状態のみ変更（従来通り）
--  - 酉   ：デッキ変更は Deck/Effects（"kito.tori_brighten"）で実施（UIあり）
--  - 巳   ：デッキ変更は Deck/Effects（"kito.mi_venom"）で実施（UIあり）
-- I/F:
--   Kito.apply(effectId, state, ctx) -> (ok:boolean, message:string)
--     state: ランタイム状態テーブル（mon/bonus/kito など）
--     ctx:   {
--       runId?: any,            -- ★必要（未指定でも state から解決を試みる）
--       uids?: {string},        -- UIで選んだ1枚（推奨：1件）
--       poolUids?: {string},    -- 12枚提示の候補（未選択時の補助）
--       codes?: {string}, poolCodes?: {string}, -- 後方互換（無ければUIDでOK）
--       preferKind?: "hikari"|"bright",         -- 酉のみ使用
--       player?: Player         -- UIモード（提示）に必要
--     }

local RS   = game:GetService("ReplicatedStorage")
local SSS  = game:GetService("ServerScriptService")

local Shared  = RS:WaitForChild("SharedModules")
local Config  = RS:WaitForChild("Config")

-- デッキ変更系の窓口
local EffectsRegistry = require(Shared:WaitForChild("Deck"):WaitForChild("EffectsRegistry"))
-- UI切替
local Balance        = require(Config:WaitForChild("Balance"))

-- 12枚提示→選択→確定（UIモード時のみ）
local KitoPickCore = nil
local function lazyGetKitoPickCore()
	if not KitoPickCore then
		KitoPickCore = require(SSS:WaitForChild("KitoPickCore"))
	end
	return KitoPickCore
end

local Kito = {}

Kito.ID = {
	USHI = "kito_ushi",        -- 所持文2倍
	TORA = "kito_tora",        -- 取り札+1
	TORI = "kito_tori",        -- 1枚を光札に（Effects "kito.tori_brighten"）
	MI   = "kito_mi",          -- 1枚をカス札に（Effects "kito.mi_venom"）
}

local DEFAULTS = { CAP_MON = 999999 }

local function msg(s) return s end

local function ensureBonus(state)
	state.bonus = state.bonus or {}
	return state.bonus
end

local function ensureKito(state)
	state.kito = state.kito or {}
	return state.kito
end

--=== utils =========================================================
local function isArray(t)
	if typeof(t) ~= "table" then return false end
	for i = 1, #t do if t[i] == nil then return false end end
	return true
end

local function isNonEmptyArray(t)
	return isArray(t) and #t > 0
end

local function normalizeArrayOrNil(t)
	if isNonEmptyArray(t) then return t end
	return nil
end

-- Effects側の正は "hikari"（"bright" を受けても内部で扱えるが、ここでは正規化）
local function normPreferKind(s: string?)
	if s == "bright" then return "hikari" end
	return "hikari"
end

local function resolveRunIdFrom(anyTable)
	if type(anyTable) ~= "table" then return nil end
	-- direct
	local direct = anyTable.runId or anyTable.deckRunId or anyTable.id or anyTable.deckRunID or anyTable.runID
	if direct ~= nil then return direct end
	-- nested
	local run = anyTable.run
	if type(run) == "table" then
		return run.runId or run.deckRunId or run.id or run.deckRunID or run.runID
	end
	return nil
end

local function resolveRunId(state, ctx)
	return resolveRunIdFrom(ctx) or resolveRunIdFrom(state)
end

--========================
-- 丑：所持文2倍（ステートのみ）
--========================
local function effect_ushi(state, ctx)
	local cap    = (ctx and ctx.capMon) or DEFAULTS.CAP_MON
	local before = tonumber(state.mon or 0) or 0
	local after  = math.min(before * 2, cap)
	state.mon    = after
	return true, msg(("丑：所持文2倍（%d → %d, 上限=%d）"):format(before, after, cap))
end

--========================
-- 寅：取り札の得点+1（恒常）
--========================
local function effect_tora(state, _ctx)
	local b = ensureBonus(state)
	b.takenPointPlus = (b.takenPointPlus or 0) + 1
	local k = ensureKito(state)
	k.tora = (tonumber(k.tora) or 0) + 1
	return true, msg(("寅：取り札の得点+1（累計+%d / Lv=%d）"):format(b.takenPointPlus, k.tora))
end

--========================
-- 共通：UIモードか直適用かを判定して適用（Effects ID を確実に使用）
--========================
local function apply_via_effects(effectModuleId:string, labelJP:string, state, ctx, preferKind:string?)
	-- ★ runId を state/ctx から厳密解決
	local runId = resolveRunId(state, ctx)
	if runId == nil then
		return false, (labelJP .. "：runId が未指定です")
	end

	-- UIモード：配列が「非空」のときだけ「指定あり」とみなす
	local uids       = normalizeArrayOrNil(ctx and ctx.uids)
	local poolUids   = normalizeArrayOrNil(ctx and ctx.poolUids)
	local codes      = normalizeArrayOrNil(ctx and ctx.codes)
	local poolCodes  = normalizeArrayOrNil(ctx and ctx.poolCodes)

	if Balance.KITO_UI_ENABLED == true then
		local hasAnyInput = (uids ~= nil) or (poolUids ~= nil) or (codes ~= nil) or (poolCodes ~= nil)
		if not hasAnyInput then
			local player = (ctx and ctx.player) or (state and state.player)
			if not player then
				return false, (labelJP .. "：UIモードですが player が不明です（ctx.player を渡してください）")
			end
			-- Effects ID を渡す（Shop ID ではない）
			lazyGetKitoPickCore().startFor(player, { runId = runId }, effectModuleId, preferKind)
			return true, (labelJP .. "：候補を表示しました。対象を選んでください。")
		end
	end

	-- 直適用（空配列は nil 済み）
	local payload = {
		uids       = uids,
		poolUids   = poolUids,
		codes      = codes,
		poolCodes  = poolCodes,
		preferKind = preferKind,
		-- 再適用抑止などのタグは effect 側で適宜解釈
		tag        = "eff:" .. tostring(effectModuleId),
	}
	local res = EffectsRegistry.apply(runId, effectModuleId, payload)
	if not res or res.ok ~= true then
		local reason = (res and (res.error or res.message)) or "unknown"
		return false, (labelJP .. "：失敗（" .. tostring(reason) .. "）")
	end

	local changed = tonumber(res.changed or 0) or 0
	if changed > 0 then
		return true, (labelJP .. "：1枚を変換（成功）")
	else
		return true, (labelJP .. "：変換対象なし（" .. tostring(res.meta or "no-eligible-target") .. "）")
	end
end

--========================
-- 酉：デッキ変更（Effects "kito.tori_brighten"）
--========================
local function effect_tori(state, ctx)
	local preferKind = normPreferKind(ctx and ctx.preferKind)
	return apply_via_effects("kito.tori_brighten", "酉", state, ctx, preferKind)
end

--========================
-- 巳：デッキ変更（Effects "kito.mi_venom"）
--========================
local function effect_mi(state, ctx)
	-- 巳は preferKind 不要
	return apply_via_effects("kito.mi_venom", "巳", state, ctx, nil)
end

--========================
-- ディスパッチ（従来4種）
--========================
local DISPATCH = {
	[Kito.ID.USHI] = effect_ushi,
	[Kito.ID.TORA] = effect_tora,
	[Kito.ID.TORI] = effect_tori, -- 酉：EffectsRegistry を叩く（UIモード時はKitoPickへ）
	[Kito.ID.MI]   = effect_mi,   -- 巳：EffectsRegistry を叩く（UIモード時はKitoPickへ）
}

--=== bridge for new KITO effects (卯/午/戌/亥) ==============================
-- ShopDefs.effect の揺れ（"kito_xxx" と "kito.xxx"）を吸収し、EffectsRegistry へ委譲
local KITO_BRIDGE_MAP = {
	-- 卯：短冊化
	["kito_usagi"]          = { label = "卯", moduleId = "kito.usagi_ribbon" },
	["kito.usagi_ribbon"]   = { label = "卯", moduleId = "kito.usagi_ribbon" },

	-- 午：タネ化
	["kito_uma"]            = { label = "午", moduleId = "kito.uma_seed" },
	["kito.uma_seed"]       = { label = "午", moduleId = "kito.uma_seed" },

	-- 戌：2枚カス化（別名にも対応）
	["kito_inu"]            = { label = "戌", moduleId = "kito.inu_chaff2" },
	["kito.inu_chaff2"]     = { label = "戌", moduleId = "kito.inu_chaff2" },
	["kito.inu_two_chaff"]  = { label = "戌", moduleId = "kito.inu_chaff2" },

	-- 亥：酒化（9月seed=盃）
	["kito_i"]              = { label = "亥", moduleId = "kito.i_sake" },
	["kito.i_sake"]         = { label = "亥", moduleId = "kito.i_sake" },
}

--========================
-- エントリポイント
--========================
function Kito.apply(effectId, state, ctx)
	if typeof(state) ~= "table" then
		return false, "state が無効です"
	end
	local fn = DISPATCH[effectId]
	if not fn then
		-- ★ 新祈祷（卯/午/戌/亥）はブリッジで EffectsRegistry に委譲
		local key = tostring(effectId or "")
		local br = KITO_BRIDGE_MAP[key]
		if br then
			return apply_via_effects(br.moduleId, br.label, state, ctx, nil)
		end
		-- 将来の拡張： "kito." で始まるIDはそのまま EffectsRegistry に渡す（前方互換）
		if typeof(effectId) == "string" and effectId:sub(1,5) == "kito." then
			return apply_via_effects(effectId, "祈祷", state, ctx, nil)
		end
		return false, ("不明な祈祷ID: %s"):format(tostring(effectId))
	end
	local ok, message = fn(state, ctx)
	return ok == true, tostring(message or "")
end

return Kito
