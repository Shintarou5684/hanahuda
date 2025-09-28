-- src/server/ShopEffects/Kito.lua
-- v0.9.12 Kito（祈祷）
--  - UIDファースト / 酉・巳は EffectsRegistry に委譲 / UI分岐を厳格化
--  - 丑/寅：サーバ状態のみ変更（従来通り）＋ kito_last へ記録
--  - 酉/巳/（卯/午/戌/亥/未 ブリッジ）: EffectsRegistry に委譲（成功時に kito_last へ記録）
--  - 子   ：最後に成功した本体KITO（kito_last）を再発火（※ 子自身は記録しない）
--  - ★ DEPRECATED underscore id（kito_...）を受け取った場合は kito.... に正規化して処理（後方互換）
-- I/F:
--   Kito.apply(effectId, state, ctx) -> (ok:boolean, message:string)
--     state: ランタイム状態テーブル（mon/bonus/kito など）
--     ctx:   {
--       runId?: any,            -- ★必要（未指定でも state から解決を試みる）
--       uids?: {string},        -- UIで選んだ1枚（推奨：1件）
--       poolUids?: {string},    -- 12枚提示の候補（未選択時の補助）
--       codes?: {string}, poolCodes?: {string}, -- 後方互換（無ければUIDでOK）
--       preferKind?: "hikari"|"bright",         -- 酉のみ使用（内部では"hikari"で渡す）
--       player?: Player         -- UIモード（提示）に必要
--       -- 内部フラグ:
--       -- __fromChild?: boolean -- 子からの再発火時に true（記録抑止用）
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
	KO   = "kito_ko",          -- 子（最後の本体KITOを再発火）
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
-- kito_last（最後の本体KITO）記録
--========================
local function sanitizePayloadForRecord(payload:any)
	-- 再発火に必要なヒントだけを保持（UID/Code/プレイヤ/Run/RNG等は保存しない）
	if typeof(payload) ~= "table" then return nil end
	local out = {}
	if payload.preferKind ~= nil then out.preferKind = payload.preferKind end
	return (next(out) ~= nil) and out or nil
end

local function shouldRecord(ctx:any)
	-- 子からの再発火では記録しない
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
-- DEPRECATED underscore id（kito_...）→ dot（kito....）正規化
--========================
local function normalizeDeprecatedId(eid:string?): (string, boolean)
	if typeof(eid) ~= "string" then return tostring(eid), false end
	if eid:sub(1,5) == "kito_" then
		local normalized = "kito." .. eid:sub(6)
		return normalized, true
	end
	return eid, false
end

--========================
-- 丑：所持文2倍（ステートのみ）
--========================
local function effect_ushi(state, ctx)
	local cap    = (ctx and ctx.capMon) or DEFAULTS.CAP_MON
	local before = tonumber(state.mon or 0) or 0
	local after  = math.min(before * 2, cap)
	state.mon    = after

	-- 記録（内蔵系はそのままIDを保存：underscore形式で統一）
	recordLastKito(state, Kito.ID.USHI, nil, { changed = 1 }, ctx)

	return true, msg(("丑：所持文2倍（%d → %d, 上限=%d）"):format(before, after, cap))
end

--========================
-- 寅：取り札の得点+1（恒常）
--========================
local function effect_tora(state, ctx)
	local b = ensureBonus(state)
	b.takenPointPlus = (b.takenPointPlus or 0) + 1
	local k = ensureKito(state)
	k.tora = (tonumber(k.tora) or 0) + 1

	-- 記録（内蔵系はそのままIDを保存：underscore形式で統一）
	recordLastKito(state, Kito.ID.TORA, nil, { changed = 1 }, ctx)

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

	-- ★ 成功：kito_last に記録（子由来なら記録しない）
	recordLastKito(state, effectModuleId, payload, res, ctx)

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
-- 子：最後の本体KITOを再発火（自分自身は記録しない）
--========================
local function effect_ko(state, ctx)
	state.run = state.run or {}
	local last = state.run.kito_last
	if typeof(last) ~= "table" or typeof(last.id) ~= "string" or last.id == "" then
		return false, "子：前回の祈祷がありません"
	end

	-- 子自身が記録されていた場合の保護（通常ありえないが旧データ救済）
	if last.id == Kito.ID.KO or last.id == "kito.ko" then
		return false, "子：前回が子のため再発火不可"
	end

	-- 子由来フラグを立てて“記録抑止”
	ctx = ctx or {}
	ctx.__fromChild = true

	-- 保存されていた最小ヒント（現状 preferKind のみ）を反映
	if typeof(last.payload) == "table" and ctx.preferKind == nil then
		ctx.preferKind = last.payload.preferKind
	end

	local id = last.id

	-- 1) 内蔵系（丑/寅/酉/巳）を識別：underscore と dot の両方を救済
	if id == Kito.ID.TORA or id == "kito.tora" then
		return effect_tora(state, ctx)
	elseif id == Kito.ID.USHI or id == "kito.ushi" then
		return effect_ushi(state, ctx)
	elseif id == Kito.ID.MI   or id == "kito.mi" then
		return effect_mi(state, ctx)
	elseif id == Kito.ID.TORI or id == "kito.tori" then
		return effect_tori(state, ctx)
	end

	-- 2) Effects系（"kito." から始まるモジュールID）はそのまま再発火
	if id:sub(1,5) == "kito." then
		-- label は "子" でOK（UIトースト用途）
		return apply_via_effects(id, "子", state, ctx, ctx.preferKind)
	end

	-- 未知ID
	return false, ("子：未知の前回ID: %s"):format(tostring(id))
end

--========================
-- ディスパッチ（従来4種 + 子）
--  - ★ dot形式（kito.xxx）でも直接呼べるようエイリアス登録
--========================
local DISPATCH = {
	-- underscore 既定
	[Kito.ID.USHI] = effect_ushi,
	[Kito.ID.TORA] = effect_tora,
	[Kito.ID.TORI] = effect_tori, -- 酉：EffectsRegistry を叩く（UIモード時はKitoPickへ）
	[Kito.ID.MI]   = effect_mi,   -- 巳：EffectsRegistry を叩く（UIモード時はKitoPickへ）
	[Kito.ID.KO]   = effect_ko,   -- 子：最後の本体KITOを再発火

	-- ★ dot 互換
	["kito.ushi"]  = effect_ushi,
	["kito.tora"]  = effect_tora,
	["kito.tori"]  = effect_tori,
	["kito.mi"]    = effect_mi,
	["kito.ko"]    = effect_ko,
}

--=== bridge for new KITO effects (卯/午/戌/亥/未) ==========================
-- ShopDefs.effect の揺れ（"kito_xxx" と "kito.xxx"）を吸収し、EffectsRegistry へ委譲
local KITO_BRIDGE_MAP = {
	-- 卯：短冊化
	["kito_usagi"]          = { label = "卯", moduleId = "kito.usagi_ribbon" },
	["kito.usagi"]          = { label = "卯", moduleId = "kito.usagi_ribbon" }, -- 簡略dotにも対応
	["kito.usagi_ribbon"]   = { label = "卯", moduleId = "kito.usagi_ribbon" },

	-- 午：タネ化
	["kito_uma"]            = { label = "午", moduleId = "kito.uma_seed" },
	["kito.uma"]            = { label = "午", moduleId = "kito.uma_seed" },     -- 簡略dotにも対応
	["kito.uma_seed"]       = { label = "午", moduleId = "kito.uma_seed" },

	-- 戌：2枚カス化（別名にも対応）
	["kito_inu"]            = { label = "戌", moduleId = "kito.inu_chaff2" },
	["kito.inu"]            = { label = "戌", moduleId = "kito.inu_chaff2" },   -- 簡略dotにも対応
	["kito.inu_chaff2"]     = { label = "戌", moduleId = "kito.inu_chaff2" },
	["kito.inu_two_chaff"]  = { label = "戌", moduleId = "kito.inu_chaff2" },

	-- 亥：酒化（9月seed=盃）
	["kito_i"]              = { label = "亥", moduleId = "kito.i_sake" },
	["kito.i"]              = { label = "亥", moduleId = "kito.i_sake" },       -- 簡略dotにも対応
	["kito.i_sake"]         = { label = "亥", moduleId = "kito.i_sake" },

	-- 未：圧縮（山札から1枚削除）
	["kito_hitsuji"]        = { label = "未", moduleId = "kito.hitsuji_prune" },
	["kito.hitsuji"]        = { label = "未", moduleId = "kito.hitsuji_prune" },-- 簡略dotにも対応
	["kito.hitsuji_prune"]  = { label = "未", moduleId = "kito.hitsuji_prune" },
}

--========================
-- エントリポイント
--========================
function Kito.apply(effectId, state, ctx)
	if typeof(state) ~= "table" then
		return false, "state が無効です"
	end

	-- ★ 後方互換：underscore → dot へ正規化
	local key = tostring(effectId or "")
	key = normalizeDeprecatedId(key)

	-- まずは内蔵／直接ディスパッチ（dot/underscore両対応）
	local fn = DISPATCH[key]
	if not fn then
		-- ★ 新祈祷（卯/午/戌/亥/未）はブリッジで EffectsRegistry に委譲
		local br = KITO_BRIDGE_MAP[key]
		if br then
			return apply_via_effects(br.moduleId, br.label, state, ctx, nil)
		end
		-- 将来の拡張： "kito." で始まるIDはそのまま EffectsRegistry に渡す（前方互換）
		if typeof(key) == "string" and key:sub(1,5) == "kito." then
			return apply_via_effects(key, "祈祷", state, ctx, nil)
		end
		return false, ("不明な祈祷ID: %s"):format(tostring(effectId))
	end

	local ok, message = fn(state, ctx)
	return ok == true, tostring(message or "")
end

return Kito
