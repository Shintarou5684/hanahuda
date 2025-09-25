-- ReplicatedStorage/SharedModules/Deck/EffectsRegistry.lua
-- Step E: 効果ハブ（集約と実行の窓口）
-- 責務：
--  - register(id, handler) で効果を登録
--  - apply(runId, effectId, payload?) で効果を実行
--  - handler 内で DeckStore / DeckOps / CardEngine を自由に使えるよう依存を注入
--
-- ポリシー：
--  - Deck の変更は DeckStore.transact を通す（純関数 DeckOps で生成→差し替え）
--  - ここでは「登録と実行の枠」だけ提供。個別効果のロジックは別モジュールで定義して register する

local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("SharedModules")

-- 依存（注入するための“共通道具”）
local DeckStore  = require(Shared:WaitForChild("Deck"):WaitForChild("DeckStore"))
local DeckOps    = require(Shared:WaitForChild("Deck"):WaitForChild("DeckOps"))
local CardEngine = require(Shared:WaitForChild("CardEngine"))

local Registry: {[string]: (any)->(any)} = {}

local M = {}

export type ApplyResult = {
	ok: boolean,
	changed: number?,      -- 変更枚数など（任意）
	meta: any?,            -- 効果側からの追加情報（任意）
	error: string?,        -- エラー文字列（失敗時）
}

-- 効果を登録
function M.register(id: string, handler: (ctx:any)->(any))
	assert(type(id) == "string" and #id > 0, "EffectsRegistry.register: id must be non-empty string")
	assert(type(handler) == "function", "EffectsRegistry.register: handler must be function")
	if Registry[id] ~= nil then
		warn(("[EffectsRegistry] overwriting existing effect id: %s"):format(id))
	end
	Registry[id] = handler
end

-- 効果が登録済みか
function M.has(id: string): boolean
	return Registry[id] ~= nil
end

-- 登録一覧（デバッグ用）
function M.list(): {string}
	local t = {}
	for k,_ in pairs(Registry) do table.insert(t, k) end
	table.sort(t)
	return t
end

-- 効果を実行
-- runId: DeckStore のランID（ゲーム/ラウンドなどの単位）
-- effectId: 登録した効果ID
-- payload: 効果固有の入力（対象コード配列など）
function M.apply(runId: any, effectId: string, payload: any?): ApplyResult
	if type(effectId) ~= "string" or #effectId == 0 then
		return { ok = false, error = "effectId is invalid" }
	end
	local handler = Registry[effectId]
	if not handler then
		return { ok = false, error = ("effect '%s' not registered"):format(tostring(effectId)) }
	end

	-- 効果ハンドラへ渡すコンテキスト
	local ctx = {
		runId   = runId,
		payload = payload,
		-- 共通道具（依存の注入）
		DeckStore  = DeckStore,
		DeckOps    = DeckOps,
		CardEngine = CardEngine,

		-- よく使う補助（任意で追加可能）
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
				-- 線形探索のフォールバック
				local want = {}
				for _, code in ipairs(codes) do want[code] = true end
				for _, c in ipairs(deck.entries) do
					if c and want[c.code] then table.insert(out, c) end
				end
			end
			return out
		end,

		-- Deck 置換の薄いラッパ（関数名はプロジェクト実装に合わせて）
		replace = function(deck, oldCode: string, newCard: any)
			-- DeckStore に実体 API があればそちらを使う
			if DeckStore.replaceEntry then
				return DeckStore.replaceEntry(deck, oldCode, newCard)
			elseif DeckStore.upsertEntry then
				return DeckStore.upsertEntry(deck, oldCode, newCard)
			else
				error("DeckStore.replaceEntry/upsertEntry not found")
			end
		end,
	}

	-- ハンドラは（必要なら）内部で DeckStore.transact を呼ぶ想定
	-- 返り値は自由だが、ここでは { ok, changed, meta } 形式に正規化して返す
	local ok, res = pcall(handler, ctx)
	if not ok then
		return { ok = false, error = tostring(res) }
	end

	-- ハンドラ側が {ok=?, changed=?, meta=?} を返さなかった場合の救済
	if typeof(res) ~= "table" then
		return { ok = true, meta = res }
	end
	if res.ok == nil then res.ok = true end
	return res :: ApplyResult
end

return M
