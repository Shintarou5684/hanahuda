-- ReplicatedStorage/SharedModules/Deck/EffectsRegistry.lua
-- Step E: 効果ハブ（集約と実行の窓口）
-- 責務：
--  - register(id, handler) で効果を登録
--  - apply(runId, effectId, payload?) で効果を実行
--  - handler 内で DeckStore / DeckOps / CardEngine を自由に使えるよう依存を注入
--  - registerCanApply(id, fn) / canApply(id, card, ctx) で「適格判定」を統一提供（Serverが唯一の正）
--
-- ポリシー：
--  - Deck の変更は DeckStore.transact を通す（純関数 DeckOps で生成→差し替え）
--  - ここでは「登録と実行の枠」だけ提供。個別効果のロジックは別モジュールで定義して register する
-- v0.9.1-patch: apply() が (store, result) 戻り値に対応（第二戻り値優先）

local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("SharedModules")

-- 依存（注入するための“共通道具”）
local DeckStore  = require(Shared:WaitForChild("Deck"):WaitForChild("DeckStore"))
local DeckOps    = require(Shared:WaitForChild("Deck"):WaitForChild("DeckOps"))
local CardEngine = require(Shared:WaitForChild("CardEngine"))

-- 任意ロガー（無依存ノイズ抑制）
local LOG do
	local ok, Logger = pcall(function()
		return require(Shared:WaitForChild("Logger"))
	end)
	if ok and Logger and type(Logger.scope) == "function" then
		LOG = Logger.scope("EffectsRegistry")
	else
		LOG = { info=function(...) end, debug=function(...) end, warn=function(...) warn(string.format(...)) end }
	end
end

-- 登録テーブル
local Registry: {[string]: (any)->(any)} = {}
local CanApplyRegistry: {[string]: (any, any)->(boolean, string?)} = {} -- (card, ctx) -> (ok, reason?)

local M = {}

export type ApplyResult = {
	ok: boolean,
	changed: number?,      -- 変更枚数（任意）
	meta: any?,            -- 効果側からの追加情報（任意）
	error: string?,        -- エラー文字列（失敗時）
}

--========================================================
-- 内部: ハンドラに渡す ctx の生成
--========================================================
local function buildCtx(runId:any, payload:any?): any
	-- rng は payload.rng（Random型）を優先注入。無ければ各ハンドラ側で Random.new() フォールバック想定。
	local rng
	if typeof(payload) == "table" then
		if typeof(payload.rng) == "Random" then
			rng = payload.rng
		elseif typeof(payload.rngSeed) == "number" then
			-- 任意: 数値seedが来たらここでRandom化
			local ok, r = pcall(function() return Random.new(payload.rngSeed) end)
			if ok and typeof(r) == "Random" then rng = r end
		end
	end

	return {
		runId   = runId,
		payload = payload,

		-- 共通道具（依存の注入）
		DeckStore  = DeckStore,
		DeckOps    = DeckOps,
		CardEngine = CardEngine,

		-- （任意）RNG
		rng = rng,

		-- よく使う補助（必要最小限）
		selectByCodes = function(deck, codes: {string})
			local out = {}
			if typeof(deck) ~= "table" or typeof(codes) ~= "table" then
				return out
			end
			-- entriesByCode 優先、無ければ entries を走査
			if deck.entriesByCode and typeof(deck.entriesByCode) == "table" then
				for _, code in ipairs(codes) do
					local c = deck.entriesByCode[code]
					if c then table.insert(out, c) end
				end
			elseif deck.entries and typeof(deck.entries) == "table" then
				local want = {}
				for _, code in ipairs(codes) do want[code] = true end
				for _, c in ipairs(deck.entries) do
					if c and want[c.code] then table.insert(out, c) end
				end
			end
			return out
		end,

		-- Deck 置換の薄いラッパ（プロジェクト依存：適宜置き換え）
		replace = function(deck, oldCode: string, newCard: any)
			if DeckStore.replaceEntry then
				return DeckStore.replaceEntry(deck, oldCode, newCard)
			elseif DeckStore.upsertEntry then
				return DeckStore.upsertEntry(deck, oldCode, newCard)
			else
				error("DeckStore.replaceEntry/upsertEntry not found")
			end
		end,
	}
end

--========================================================
-- 効果本体の登録・参照
--========================================================
function M.register(id: string, handler: (ctx:any)->(any))
	assert(type(id) == "string" and #id > 0, "EffectsRegistry.register: id must be non-empty string")
	assert(type(handler) == "function", "EffectsRegistry.register: handler must be function")
	if Registry[id] ~= nil then
		warn(("[EffectsRegistry] overwriting existing effect id: %s"):format(id))
	end
	Registry[id] = handler
	LOG.debug("[register] id=%s", id)
end

function M.has(id: string): boolean
	return Registry[id] ~= nil
end

function M.list(): {string}
	local t = {}
	for k,_ in pairs(Registry) do table.insert(t, k) end
	table.sort(t)
	return t
end

--========================================================
-- canApply（適格判定）の登録・参照
--========================================================
-- 登録: (card, ctx) -> (ok:boolean, reason:string?)
function M.registerCanApply(id: string, fn: (any, any)->(boolean, string?))
	assert(type(id) == "string" and #id > 0, "EffectsRegistry.registerCanApply: id must be non-empty string")
	assert(type(fn) == "function", "EffectsRegistry.registerCanApply: fn must be function")
	if CanApplyRegistry[id] ~= nil then
		warn(("[EffectsRegistry] overwriting existing canApply for id: %s"):format(id))
	end
	CanApplyRegistry[id] = fn
	LOG.debug("[registerCanApply] id=%s", id)
end

function M.hasCanApply(id: string): boolean
	return CanApplyRegistry[id] ~= nil
end

-- 取得: 登録が無ければ true を返す（= フィルタ無し）
function M.canApply(id: string, card:any, externCtx:any?): (boolean, string?)
	local fn = CanApplyRegistry[id]
	if not fn then
		return true, "no-check"
	end
	-- externCtx が来ていればそれをベースに最小限の依存を補完
	local ctx = externCtx or {}
	if ctx.DeckStore == nil then ctx.DeckStore = DeckStore end
	if ctx.DeckOps   == nil then ctx.DeckOps   = DeckOps   end
	if ctx.CardEngine== nil then ctx.CardEngine= CardEngine end
	local ok, reason = fn(card, ctx)
	return ok and true or false, reason
end

--========================================================
-- 効果の実行
--========================================================
-- runId: DeckStore のランID（ゲーム/ラウンドなどの単位）
-- effectId: 登録した効果ID
-- payload: 効果固有の入力（対象UID/コード配列・poolUidsなど）
function M.apply(runId: any, effectId: string, payload: any?): ApplyResult
	if type(effectId) ~= "string" or #effectId == 0 then
		return { ok = false, error = "effectId is invalid" }
	end
	local handler = Registry[effectId]
	if not handler then
		return { ok = false, error = ("effect '%s' not registered"):format(tostring(effectId)) }
	end

	local ctx = buildCtx(runId, payload)

	-- 🔧 ハンドラが (store, result) を返す場合に対応：第二戻り値を優先
	local okCall, r1, r2 = pcall(handler, ctx)
	if not okCall then
		LOG.warn("[apply] error id=%s err=%s", effectId, tostring(r1))
		return { ok = false, error = tostring(r1) }
	end

	local res = (r2 ~= nil) and r2 or r1

	-- デッキストア風テーブルのみ返ってきた場合の救済（成功として扱う）
	local function looksLikeDeckStore(v:any)
		return (type(v)=="table") and (type(v.entries)=="table" or type(v.v)=="number")
	end
	if looksLikeDeckStore(res) then
		return { ok = true }
	end

	-- 正規化
	if typeof(res) ~= "table" then
		return { ok = (res ~= false and res ~= nil), meta = res }
	end
	if res.ok == nil then res.ok = true end
	return res :: ApplyResult
end

return M
