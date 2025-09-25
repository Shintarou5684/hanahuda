-- src/server/ShopEffects/Kito.lua
-- v0.9.9 Kito（祈祷）: UIDファースト / 酉は EffectsRegistry に委譲
--  - 丑/寅：サーバ状態のみ変更（従来通り）
--  - 酉   ：デッキ変更は Deck/Effects（"kito.tori_brighten"）で実施
-- I/F:
--   Kito.apply(effectId, state, ctx) -> (ok:boolean, message:string)
--     state: ランタイム状態テーブル（mon/bonus/kito など）
--     ctx:   {
--       runId:any,
--       -- ★UIDファースト：
--       uids?:{string},        -- UIで選んだ1枚（推奨：1件）
--       poolUids?:{string},    -- 12枚提示の候補（未選択時の補助）
--       -- 後方互換（コード系・なくてもOK）：
--       codes?:{string}, poolCodes?:{string},
--       preferKind?: "hikari"|"bright",
--       player?: Player        -- UIモード（提示）に必要
--     }

local RS   = game:GetService("ReplicatedStorage")
local SSS  = game:GetService("ServerScriptService")

local Shared  = RS:WaitForChild("SharedModules")
local Config  = RS:WaitForChild("Config")

-- 酉（デッキ変更）窓口
local EffectsRegistry = require(Shared:WaitForChild("Deck"):WaitForChild("EffectsRegistry"))
-- UIモード切替
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
	USHI = "kito_ushi",   -- 所持文2倍
	TORA = "kito_tora",   -- 取り札+1
	TORI = "kito_tori",   -- 光札に変換（Effects "kito.tori_brighten"）
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

local function isArray(t)
	if typeof(t) ~= "table" then return false end
	for i = 1, #t do if t[i] == nil then return false end end
	return true
end

-- Effects側の正は "hikari"（"bright" を受けても内部で扱えるが、ここでは正規化）
local function normPreferKind(s: string?)
	if s == "bright" then return "hikari" end
	return "hikari"
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
-- 酉：デッキ変更は EffectsRegistry に委譲（UIDファースト）
--========================
local function effect_tori(state, ctx)
	-- === 前提 ===
	local runId = ctx and ctx.runId
	if runId == nil then
		return false, "酉：runId が未指定です"
	end

	local preferKind = normPreferKind(ctx and ctx.preferKind)

	-- === UIモード（12枚提示） ===
	-- UIが有効かつ、UID/Codeいずれも指定が無いときは提示へ
	if Balance.KITO_UI_ENABLED == true then
		local hasUids      = ctx and isArray(ctx.uids)
		local hasPoolUids  = ctx and isArray(ctx.poolUids)
		local hasCodes     = ctx and isArray(ctx.codes)
		local hasPoolCodes = ctx and isArray(ctx.poolCodes)
		if not hasUids and not hasPoolUids and not hasCodes and not hasPoolCodes then
			local player = (ctx and ctx.player) or (state and state.player)
			if not player then
				return false, "酉：UIモードですが player が不明です（ctx.player を渡してください）"
			end
			lazyGetKitoPickCore().startFor(player, { runId = runId }, "kito_tori", preferKind)
			return true, "酉：候補を表示しました。対象を選んでください。"
		end
	end

	-- === 直接適用（UIDファースト／後方互換で codes 系も許容） ===
	if ctx and ctx.uids and not isArray(ctx.uids) then
		return false, "酉：uids は配列で指定してください"
	end
	if ctx and ctx.poolUids and not isArray(ctx.poolUids) then
		return false, "酉：poolUids は配列で指定してください"
	end
	if ctx and ctx.codes and not isArray(ctx.codes) then
		return false, "酉：codes は配列で指定してください"
	end
	if ctx and ctx.poolCodes and not isArray(ctx.poolCodes) then
		return false, "酉：poolCodes は配列で指定してください"
	end

	-- Effects への入力は UID を主、codes は保険としてフォールバック
	local payload = {
		uids       = ctx and ctx.uids or nil,        -- 推奨：UIで選んだ1枚（UID）
		poolUids   = ctx and ctx.poolUids or nil,    -- 12候補のUID
		-- 互換（無ければUIDに委ねる）
		codes      = ctx and ctx.codes or nil,
		poolCodes  = ctx and ctx.poolCodes or nil,
		preferKind = preferKind,                     -- "hikari" 固定運用
		tag        = "eff:kito_tori_bright",         -- 再適用抑止タグ
	}

	-- 正式IDで適用（EffectsRegistry 側は runId 先行のシグネチャ）
	local res = EffectsRegistry.apply(runId, "kito.tori_brighten", payload)
	if not res or res.ok ~= true then
		local reason = (res and (res.error or res.message)) or "unknown"
		return false, ("酉：失敗（%s）"):format(tostring(reason))
	end

	local changed = tonumber(res.changed or 0) or 0
	if changed > 0 then
		return true, "酉：1枚を光札に変換（成功）"
	else
		return true, ("酉：変換対象なし（%s）"):format(tostring(res.meta or "no-eligible-target"))
	end
end

--========================
-- ディスパッチ
--========================
local DISPATCH = {
	[Kito.ID.USHI] = effect_ushi,
	[Kito.ID.TORA] = effect_tora,
	[Kito.ID.TORI] = effect_tori, -- 酉は EffectsRegistry を叩く（UIモード時はKitoPickへ委譲）
}

function Kito.apply(effectId, state, ctx)
	if typeof(state) ~= "table" then
		return false, "state が無効です"
	end
	local fn = DISPATCH[effectId]
	if not fn then
		return false, ("不明な祈祷ID: %s"):format(tostring(effectId))
	end
	local ok, message = fn(state, ctx)
	return ok == true, tostring(message or "")
end

return Kito
