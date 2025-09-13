-- v0.9.1 祈祷：ラン構成(config)を直接更新する安全設計（寅Lvをstate.kitoへ反映）
-- I/F:
--   Kito.apply(effectId, state, ctx) -> (ok:boolean, message:string)

local RS = game:GetService("ReplicatedStorage")
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))
local CardEngine  = require(RS:WaitForChild("SharedModules"):WaitForChild("CardEngine"))

local Kito = {}

Kito.ID = {
	USHI = "kito_ushi",   -- 所持文を即時2倍（上限あり）
	TORA = "kito_tora",   -- 取り札の得点+1（恒常バフ）
	TORI = "kito_tori",   -- ランダム1枚を bright へ変換（候補無し→次季に繰越）
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

-- 丑：所持文2倍（プレイヤー状態のみ変更）
local function effect_ushi(state, ctx)
	local cap = (ctx and ctx.capMon) or DEFAULTS.CAP_MON
	local before = tonumber(state.mon or 0) or 0
	local after = math.min(before * 2, cap)
	state.mon = after
	return true, msg(("丑：所持文2倍（%d → %d, 上限=%d）"):format(before, after, cap))
end

-- 寅：取り札の得点+1（恒常）
-- ※ UI後方互換のため bonus.takenPointPlus も増やすが、参照の唯一真実は state.kito.tora
local function effect_tora(state, _ctx)
	-- 後方互換（旧UI/計算で利用している可能性あり）
	local b = ensureBonus(state)
	b.takenPointPlus = (b.takenPointPlus or 0) + 1

	-- 採点（Scoring）側が参照する干支レベル
	local k = ensureKito(state)
	k.tora = (tonumber(k.tora) or 0) + 1

	return true, msg(("寅：取り札の得点+1（累計+%d / Lv=%d）"):format(b.takenPointPlus, k.tora))
end

-- 酉：ラン構成の非brightを1枚brightへ
-- 候補無しなら queueBrightNext を +1（次季で消化）
local function effect_tori(state, ctx)
	-- ラン構成（48枚）をロード（無ければ初期化）
	local deck = RunDeckUtil.loadConfig(state, true) -- true=必要なら初期化
	if not deck or #deck == 0 then
		local b = ensureBonus(state)
		b.queueBrightNext = (b.queueBrightNext or 0) + 1
		return true, msg("酉：構成が空のため、次の季節開始時に1枚brightへ変換（+1スタック）")
	end

	local ok, idx = CardEngine.convertRandomNonBrightToBright(deck, ctx and ctx.rng)
	if not ok then
		local b = ensureBonus(state)
		b.queueBrightNext = (b.queueBrightNext or 0) + 1
		return true, msg("酉：対象無し。次の季節開始時に1枚brightへ変換（+1スタック）")
	end

	local label = deck[idx].name or deck[idx].code
	RunDeckUtil.saveConfig(state, deck)
	return true, msg(("酉：%s を bright に変換しました"):format(label))
end

local DISPATCH = {
	[Kito.ID.USHI] = effect_ushi,
	[Kito.ID.TORA] = effect_tora,
	[Kito.ID.TORI] = effect_tori,
}

function Kito.apply(effectId, state, ctx)
	local fn = DISPATCH[effectId]
	if not fn then
		return false, msg(("不明な祈祷ID: %s"):format(tostring(effectId)))
	end
	if typeof(state) ~= "table" then
		return false, msg("state が無効です")
	end
	local ok, message = fn(state, ctx)
	return ok == true, tostring(message or "")
end

return Kito
