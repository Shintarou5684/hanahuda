-- ReplicatedStorage/SharedModules/Deck/DeckViewAdapter.lua
-- Step D: 表示用VM（View Model）アダプタ
-- 仕様根拠:
--  - VM項目: imageId / badges / kind / month / name（確定）【DeckSchema Step A】 
--  - 画像決定: imageOverride ?? CardImageMap.get(code)（確定）【DeckSchema Step A】
--  - 画像マップ: SharedModules/CardImageMap を利用（既存）【PROJECT_SNAPSHOT.md】

local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("SharedModules")

local CardImageMap = require(Shared:WaitForChild("CardImageMap"))
-- ★ 追加: code → month/idx/定義(kind/name) を引くために利用
local CardEngine = require(Shared:WaitForChild("CardEngine"))

local M = {}

--========================
-- 内部: 安全ユーティリティ
--========================

local function _deriveCode(card: any): string
	if card and card.code then
		return tostring(card.code)
	end
	local m = tonumber(card and card.month) or 1
	local i = tonumber(card and card.idx) or 1
	if m < 1 then m = 1 end; if m > 12 then m = 12 end
	if i < 1 then i = 1 end; if i > 4 then i = 4 end
	return string.format("%02d%02d", m, i)
end

local function _buildBadges(card: any): {string}
	local out = {}
	if card and typeof(card.tags) == "table" then
		for _, t in ipairs(card.tags) do
			table.insert(out, tostring(t))
		end
	end
	if card and typeof(card.effects) == "table" then
		for _, e in ipairs(card.effects) do
			if typeof(e) == "string" then
				table.insert(out, e)
			elseif typeof(e) == "table" then
				table.insert(out, (e.id ~= nil) and tostring(e.id) or "effect")
			end
		end
	end
	return out
end

local function _pickImageId(card: any, code: string): string
	if card and card.imageOverride ~= nil then
		return tostring(card.imageOverride)
	end
	local ok, id = pcall(function() return CardImageMap.get(code) end)
	return ok and tostring(id) or ""
end

-- ★ 追加: kind/month/name のフォールバック補完
local function _deriveInfo(card:any, code:string)
	local kind  = card and card.kind  or nil
	local month = card and card.month or nil
	local name  = card and card.name  or nil

	if month == nil or kind == nil or (name == nil or name == "") then
		local ok, mm, ii = pcall(function()
			local m, i = CardEngine.fromCode(code)
			return m, i
		end)
		if ok and mm and ii then
			month = month or mm
			local defM = CardEngine.cardsByMonth[mm]
			local def  = (typeof(defM) == "table") and defM[ii] or nil
			if kind == nil and def and def.kind then kind = def.kind end
			if (name == nil or name == "") and def and def.name then name = def.name end
		end
	end
	return kind, month, name
end

--========================
-- 公開API
--========================

function M.toVM(card: any): any
	if typeof(card) ~= "table" then
		return { code = "0101", imageId = "", badges = {}, kind = "", month = 1, name = "" }
	end

	local code    = _deriveCode(card)
	local imageId = _pickImageId(card, code)
	local badges  = _buildBadges(card)

	-- ★ 不足分のみ安全に補完
	local kind, month, name = _deriveInfo(card, code)

	return {
		code    = code,
		imageId = imageId,
		badges  = badges,
		kind    = kind,
		month   = month,
		name    = name,
	}
end

function M.toVMs(entries: {any}?): {any}
	local src = (typeof(entries) == "table") and entries or {}
	local out = table.create(#src)
	for i, card in ipairs(src) do
		out[i] = M.toVM(card)
	end
	return out
end

return M
