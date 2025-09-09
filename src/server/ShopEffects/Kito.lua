-- ServerScriptService/ShopEffects/Kito.lua
-- v0.8.3 祈祷（タロット相当）：即時系の効果をここで定義
-- I/F:
--   Kito.apply(effectId, state, ctx) -> (ok:boolean, message:string)
--   Kito.applyQueued(state, ctx)     -> (ok:boolean, message:string)

local RS = game:GetService("ReplicatedStorage")
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))

local Kito = {}

Kito.ID = {
	USHI = "kito_ushi",   -- 丑: 所持文を即時2倍（上限あり）
	TORA = "kito_tora",   -- 寅: 取り札の得点+1（全体／恒常バフ）
	TORI = "kito_tori",   -- 酉: ランダム1枚を bright へ変換（候補無/デッキ無は次ラウンド開始時に変換バフ）
	NE   = "kito_ne",
	U    = "kito_u",
	TATSU= "kito_tatsu",
	MI   = "kito_mi",
	UMA  = "kito_uma",
	SARU = "kito_saru",
	INU  = "kito_inu",
	I    = "kito_i",
	HITSUJI = "kito_hitsuji",
}

local DEFAULTS = { CAP_MON = 999999 }

--========================
-- ユーティリティ
--========================

local function randIndex(n, rng)
	if n <= 0 then return nil end
	if rng and typeof(rng) == "Random" then
		return rng:NextInteger(1, n)
	else
		return math.random(1, n)
	end
end

local function msg(s) return s end

local function ensureBonus(state)
	state.bonus = state.bonus or {}
	return state.bonus
end

--========================
-- 効果本体
--========================

-- 丑：所持文2倍
local function effect_ushi(state, ctx)
	local cap = (ctx and ctx.capMon) or DEFAULTS.CAP_MON
	local before = tonumber(state.mon or 0) or 0
	local after = before * 2
	if after > cap then after = cap end
	state.mon = after
	return true, msg(("丑の祈祷：所持文を2倍に（%d → %d, 上限=%d）"):format(before, after, cap))
end

-- 寅：取り札の得点+1（恒常・スタック）
local function effect_tora(state, _ctx)
	local bonus = ensureBonus(state)
	bonus.takenPointPlus = (bonus.takenPointPlus or 0) + 1
	return true, msg(("寅の祈祷：取り札の得点+1（累計+%d）"):format(bonus.takenPointPlus))
end

-- 酉：非 bright を1枚 bright へ。
-- デッキが無い or 候補無しのときは「次ラウンド開始時変換」キューを +1 して成功扱い。
local function effect_tori(state, ctx)
	-- 正本デッキ（48）をロード
	local deck = RunDeckUtil.load(state)
	if typeof(deck) ~= "table" or #deck == 0 then
		local b = ensureBonus(state)
		b.queueBrightNext = (b.queueBrightNext or 0) + 1
		return true, msg("酉の祈祷：変換候補が無いため、次ラウンド開始時に1枚を光札へ変換（1スタック付与）")
	end

	-- 非 bright 候補
	local cand = {}
	for i, c in ipairs(deck) do
		if c and c.kind ~= "bright" then table.insert(cand, i) end
	end
	if #cand == 0 then
		local b = ensureBonus(state)
		b.queueBrightNext = (b.queueBrightNext or 0) + 1
		return true, msg("酉の祈祷：対象無し。次ラウンド開始時に1枚を光札へ変換（1スタック付与）")
	end

	local pick = cand[randIndex(#cand, ctx and ctx.rng)]
	local card = deck[pick]
	local beforeKind = card.kind
	card.kind = "bright"

	-- 変更を正本へ保存（entries.kind に反映）
	RunDeckUtil.save(state)

	local label = card.name or card.code or (tostring(card.month).."-"..tostring(card.idx))
	return true, msg(("酉の祈祷：%s（%s→bright）へ変換しました"):format(label, tostring(beforeKind)))
end

--========================
-- 次ラウンド開始時：繰り越し消化
--========================
function Kito.applyQueued(state, ctx)
	local b = ensureBonus(state)
	local n = tonumber(b.queueBrightNext or 0) or 0
	if n <= 0 then
		return true, msg("祈祷の繰り越しはありません")
	end

	local deck = RunDeckUtil.load(state)
	if typeof(deck) ~= "table" or #deck == 0 then
		-- デッキが無いなら保留（キューは残す）
		return false, msg("次ラウンド開始時の変換：デッキが空のため保留")
	end

	local rng = (ctx and ctx.rng) or Random.new()
	local converted = 0

	for _=1,n do
		-- 非 bright を探して1枚 bright 化
		local indices = {}
		for i, c in ipairs(deck) do
			if c and c.kind ~= "bright" then
				table.insert(indices, i)
			end
		end
		if #indices == 0 then break end
		local pick = indices[rng:NextInteger(1, #indices)]
		deck[pick].kind = "bright"
		converted += 1
	end

	-- 消化した分だけ減らす
	b.queueBrightNext = math.max(0, (b.queueBrightNext or 0) - converted)

	-- 正本保存
	RunDeckUtil.save(state)

	if converted > 0 then
		return true, msg(("次ラウンド開始時の変換：%d枚を光札へ変換しました"):format(converted))
	else
		return true, msg("次ラウンド開始時の変換：対象無し（保留のまま）")
	end
end

--========================
-- ディスパッチ
--========================
local DISPATCH = {
	[Kito.ID.USHI] = effect_ushi,
	[Kito.ID.TORA] = effect_tora,
	[Kito.ID.TORI] = effect_tori,

	-- 未実装（安全に失敗メッセージ）
	[Kito.ID.NE]      = function() return false, msg("子の祈祷：未実装") end,
	[Kito.ID.U]       = function() return false, msg("卯の祈祷：未実装") end,
	[Kito.ID.TATSU]   = function() return false, msg("辰の祈祷：未実装") end,
	[Kito.ID.MI]      = function() return false, msg("巳の祈祷：未実装") end,
	[Kito.ID.UMA]     = function() return false, msg("午の祈祷：未実装") end,
	[Kito.ID.SARU]    = function() return false, msg("申の祈祷：未実装") end,
	[Kito.ID.INU]     = function() return false, msg("戌の祈祷：未実装") end,
	[Kito.ID.I]       = function() return false, msg("亥の祈祷：未実装") end,
	[Kito.ID.HITSUJI] = function() return false, msg("未の祈祷：未実装") end,
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
