-- ReplicatedStorage/SharedModules/Deck/DeckViewAdapter.lua
-- Step D: 表示用VM（View Model）アダプタ
-- 仕様根拠:
--  - VM項目: imageId / badges / kind / month / name（確定）【DeckSchema Step A】 
--  - 画像決定: imageOverride ?? CardImageMap.get(code)（確定）【DeckSchema Step A】
--  - 画像マップ: SharedModules/CardImageMap を利用（既存）【PROJECT_SNAPSHOT.md】

local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("SharedModules")

local CardImageMap = require(Shared:WaitForChild("CardImageMap"))

local M = {}

--========================
-- 内部: 安全ユーティリティ
--========================

local function _deriveCode(card: any): string
	-- code があれば最優先。無ければ month/idx から派生。
	if card and card.code then
		return tostring(card.code)
	end
	local m = tonumber(card and card.month) or 1
	local i = tonumber(card and card.idx) or 1
	if m < 1 then m = 1 end; if m > 12 then m = 12 end
	if i < 1 then i = 1 end; if i > 4 then i = 4 end
	return string.format("%02d%02d", m, i) -- 例: 0101
end

local function _buildBadges(card: any): {string}
	-- “バッジ”はUI表示用の短いラベル配列。
	-- 仕様上の必須は「badges を持つこと」まで（表記はUI側に委譲可能）【DeckSchema Step A】
	-- ここでは tags と effects を素直に並べる（推測による翻訳や省略はしない）。
	local out = {}

	-- tags: 配列想定（なければ無視）
	if card and typeof(card.tags) == "table" then
		for _, t in ipairs(card.tags) do
			table.insert(out, tostring(t))
		end
	end

	-- effects: 文字列 or {id=..., ...} などを素直に見出し化
	if card and typeof(card.effects) == "table" then
		for _, e in ipairs(card.effects) do
			if typeof(e) == "string" then
				table.insert(out, e)
			elseif typeof(e) == "table" then
				local label = (e.id ~= nil) and tostring(e.id) or "effect"
				table.insert(out, label)
			end
		end
	end

	return out
end

local function _pickImageId(card: any, code: string): string
	-- 画像は imageOverride があればそれを採用、無ければマップから取得（確定仕様）
	if card and card.imageOverride ~= nil then
		return tostring(card.imageOverride)
	end
	local ok, id = pcall(function() return CardImageMap.get(code) end)
	return ok and tostring(id) or ""
end

--========================
-- 公開API
--========================

-- card 1枚 → 表示VM
-- 返すテーブル：
--   { code, imageId, badges, kind, month, name }
function M.toVM(card: any): any
	if typeof(card) ~= "table" then
		return { code = "0101", imageId = "", badges = {}, kind = "", month = 1, name = "" }
	end

	local code = _deriveCode(card)
	local imageId = _pickImageId(card, code)
	local badges = _buildBadges(card)

	-- kind/month/name はカードが持つソースをそのまま反映（推測で補完しない）
	local out = {
		code   = code,
		imageId= imageId,
		badges = badges,
		kind   = card.kind,
		month  = card.month,
		name   = card.name,
	}

	return out
end

-- entries の配列（デッキなど）→ VM配列
function M.toVMs(entries: {any}?): {any}
	local src = (typeof(entries) == "table") and entries or {}
	local out = table.create(#src)
	for i, card in ipairs(src) do
		out[i] = M.toVM(card)
	end
	return out
end

return M
