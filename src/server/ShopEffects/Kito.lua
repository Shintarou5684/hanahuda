-- v0.9.3 祈祷：プール確定ルート優先（uid差分適用）＋共通ヘルパ導入
--        フォールバック: ラン構成(configSnapshot)を直接更新（旧実装互換・寅Lvはstate.kitoへ反映）
-- I/F:
--   Kito.apply(effectId, state, ctx) -> (ok:boolean, message:string)

local RS = game:GetService("ReplicatedStorage")

local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))
local CardEngine  = require(RS:WaitForChild("SharedModules"):WaitForChild("CardEngine"))
local PoolEditor  = require(RS:WaitForChild("SharedModules"):WaitForChild("PoolEditor"))

local Kito = {}

Kito.ID = {
	USHI = "kito_ushi",   -- 所持文を即時2倍（上限あり）
	TORA = "kito_tora",   -- 取り札の得点+1（恒常バフ）
	TORI = "kito_tori",   -- ランダム1枚を bright へ変換（プール確定・候補無し→次季に繰越）
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

--========================
-- 共通ヘルパ：1枚変換（プール確定→SNAP構成 フォールバック）
--========================
-- opts = { targetKind:string, preferNonTarget:boolean?, rng:any? }
local function pool_convert_one(state:any, opts)
	local targetKind      = tostring(opts and opts.targetKind or "")
	local preferNonTarget = not (opts and opts.preferNonTarget == false)

	-- --- プール確定（ライブデッキ） ---
	if typeof(state) == "table" and typeof(state.deck) == "table" and #state.deck > 0 then
		local sess = PoolEditor.start(state, 1)
		if sess and typeof(sess.uids) == "table" and #sess.uids > 0 then
			local pick, pickedLabel = {}, nil
			for _, uid in ipairs(sess.uids) do
				local e = sess.snap[uid]
				if e then
					if preferNonTarget and e.kind ~= targetKind then
						table.insert(pick, uid)
						pickedLabel = e.name or e.code
						break
					end
				end
			end
			if #pick == 0 then
				pick = { sess.uids[1] }
				local e = sess.snap[pick[1]]
				pickedLabel = e and (e.name or e.code) or "(unknown)"
			end

			PoolEditor.mutate(sess, { kind = "convertKind", targetKind = targetKind, uids = pick })
			local ok, reason = PoolEditor.commit(state, sess)
			if ok then
				return true, ("【POOL確定】%s→%s"):format(pickedLabel or "対象", targetKind)
			else
				-- 版数不一致/期限切れなど。フォールバックへ。
				-- reason: "deck changed; please retry" / "session expired" など
			end
		end
	end

	-- --- フォールバック（SNAP構成編集） ---
	local deck = RunDeckUtil.loadConfig(state, true)
	if not deck or #deck == 0 then
		local b = ensureBonus(state)
		b.queueBrightNext = (b.queueBrightNext or 0) + 1
		return true, ("【SNAP構成】候補なし→次季に変換予約(+1) target=%s"):format(targetKind)
	end

	-- 既存の安全APIで bright 変換のみ対応（他kindは必要になったらCardEngine側を拡張）
	if targetKind == "bright" then
		local ok2, idx = CardEngine.convertRandomNonBrightToBright(deck, opts and opts.rng)
		if ok2 then
			local label = deck[idx].name or deck[idx].code
			RunDeckUtil.saveConfig(state, deck)
			return true, ("【SNAP構成】%s→%s"):format(label, targetKind)
		else
			local b = ensureBonus(state)
			b.queueBrightNext = (b.queueBrightNext or 0) + 1
			return true, ("【SNAP構成】対象なし→次季に変換予約(+1) target=%s"):format(targetKind)
		end
	end

	return false, "unsupported fallback for kind=" .. targetKind
end

--========================
-- 各 祈祷
--========================

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
	local b = ensureBonus(state)
	b.takenPointPlus = (b.takenPointPlus or 0) + 1
	local k = ensureKito(state)
	k.tora = (tonumber(k.tora) or 0) + 1
	return true, msg(("寅：取り札の得点+1（累計+%d / Lv=%d）"):format(b.takenPointPlus, k.tora))
end

-- 酉：1枚を bright へ（プール確定優先）
local function effect_tori(state, ctx)
	local ok, info = pool_convert_one(state, {
		targetKind = "bright",
		preferNonTarget = true,
		rng = ctx and ctx.rng,
	})
	if ok then
		return true, ("酉：1枚を光札に変換 %s"):format(info)
	else
		return false, ("酉：変換失敗 %s"):format(info)
	end
end

--========================
-- ディスパッチ
--========================
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
