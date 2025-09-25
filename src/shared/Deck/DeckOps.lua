-- ReplicatedStorage/SharedModules/Deck/DeckOps.lua
-- Step C: 変更ロジックの純関数群（入力Card -> 新Card）
-- 仕様根拠:
--  - Step C 要件: convertKind / convertMonth / attachTag / attachEffect / overrideImage【Deck_Refactor_FullSpec_Workplan.md】
--  - tags/effects は「安全に無効（空 or nil）」初期で、指定が無ければ現状維持【DeckSchema Step A 確定版】

local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("SharedModules")

-- 依存（兄弟/既存）
local DeckSchema = require(Shared:WaitForChild("Deck"):WaitForChild("DeckSchema"))
local CardEngine = require(Shared:WaitForChild("CardEngine"))

local M = {}

--========================
-- 内部ヘルパ
--========================

local function _cloneArray(src)
	if typeof(src) ~= "table" then return {} end
	-- Luauの table.clone は配列/連想どちらも浅いコピー
	return table.clone(src)
end

local function _deriveCode(month: number, idx: number): string
	local m = math.clamp(math.floor(tonumber(month) or 0), 1, 12)
	-- 月ごとの定義数に合わせて idx をクランプ（通常 1..4）
	local defM = CardEngine.cardsByMonth[m]
	local maxIdx = (typeof(defM) == "table") and #defM or 4
	local i = math.clamp(math.floor(tonumber(idx) or 0), 1, math.max(1, maxIdx))
	return string.format("%02d%02d", m, i)
end

local function _safeDefaults(card:any): any
	-- DeckSchema.defaults() をベースに、既存カードの値で上書き
	-- ※浅いコピーで十分（tags/effects は別途クローン）
	local base = DeckSchema.defaults()
	for k, v in pairs(card or {}) do
		base[k] = v
	end
	-- 可変配列は必ずクローン
	base.tags    = _cloneArray(base.tags)
	base.effects = _cloneArray(base.effects)
	return base
end

-- 同月で targetKind を持つ定義の idx を探索（無ければ現在の idx を返す）
local function _findIdxOfKindInMonth(month: number, targetKind: string, fallbackIdx: number): number
	local m = math.clamp(math.floor(tonumber(month) or 0), 1, 12)
	local defM = CardEngine.cardsByMonth[m]
	if typeof(defM) == "table" then
		for i, def in ipairs(defM) do
			if def and tostring(def.kind) == tostring(targetKind) then
				return i
			end
		end
		return math.clamp(fallbackIdx or 1, 1, #defM)
	end
	return math.clamp(fallbackIdx or 1, 1, 4)
end

-- 新しいカードテーブルを返す（codeの一貫更新）
local function _with(card:any, patch:any): any
	local c = _safeDefaults(card)
	for k, v in pairs(patch or {}) do
		c[k] = v
	end
	-- month/idx から code を再派生
	c.code = _deriveCode(c.month, c.idx)
	return c
end

--========================
-- 公開API（純関数）
--========================

-- kind を変換。idx は「同月で指定kindを持つ定義」の idx に合わせる（なければ現idxをクランプして維持）
function M.convertKind(card:any, toKind:string): any
	local src = _safeDefaults(card)
	local tgtKind = tostring(toKind or src.kind)
	local nextIdx = _findIdxOfKindInMonth(src.month, tgtKind, src.idx)
	return _with(src, { kind = tgtKind, idx = nextIdx })
end

-- month を変換。idx は「新しい月で現kindが存在すればそのidx、無ければ現idxをクランプ」
function M.convertMonth(card:any, toMonth:number): any
	local src = _safeDefaults(card)
	local m = math.clamp(math.floor(tonumber(toMonth) or src.month), 1, 12)
	local defM = CardEngine.cardsByMonth[m]
	local nextIdx
	if typeof(defM) == "table" then
		-- 同kind の idx を優先探索
		local found = nil
		for i, def in ipairs(defM) do
			if def and tostring(def.kind) == tostring(src.kind) then found = i; break end
		end
		if found then
			nextIdx = found
		else
			-- 見つからなければ既存 idx をクランプ
			nextIdx = math.clamp(src.idx or 1, 1, #defM)
		end
	else
		nextIdx = math.clamp(src.idx or 1, 1, 4)
	end
	return _with(src, { month = m, idx = nextIdx })
end

-- タグを付与（配列tagsに重複なしで追加）
-- keyのみ  or key,val（valがある場合は "key:value" の文字列として追加）
function M.attachTag(card:any, key:any, val:any?): any
	local src = _safeDefaults(card)
	local tags = _cloneArray(src.tags)
	if typeof(key) == "table" then
		-- テーブル渡しは配列想定：すべて追加
		for _, t in ipairs(key) do
			local s = tostring(t)
			local exists = false
			for _, x in ipairs(tags) do if x == s then exists = true; break end end
			if not exists then table.insert(tags, s) end
		end
	else
		local s = tostring(key)
		if val ~= nil and val ~= true then
			s = ("%s:%s"):format(s, tostring(val))
		end
		local exists = false
		for _, x in ipairs(tags) do if x == s then exists = true; break end end
		if not exists then table.insert(tags, s) end
	end
	return _with(src, { tags = tags })
end

-- エフェクトを付与（effects 配列の末尾に追加。文字列/テーブルどちらも許容）
function M.attachEffect(card:any, spec:any): any
	local src = _safeDefaults(card)
	local effects = _cloneArray(src.effects)
	table.insert(effects, spec)
	return _with(src, { effects = effects })
end

-- 画像差し替え（nil指定で解除）。最終決定は ViewAdapter: imageOverride ?? CardImageMap.get(code)
function M.overrideImage(card:any, assetId:string?): any
	local src = _safeDefaults(card)
	local v
if assetId == nil then
	v = nil
else
	v = tostring(assetId)
end
return _with(src, { imageOverride = v })
end

return M
