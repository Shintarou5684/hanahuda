-- ReplicatedStorage/SharedModules/ShopFormat.lua
-- v0.9.B ShopFormat：SHOP向けの整形系ユーティリティ（Locale優先 + 後方互換）
local ShopFormat = {}

--==================================================
-- 依存（Locale 一元化）
--==================================================
local RS = game:GetService("ReplicatedStorage")
local Config = RS:WaitForChild("Config")
local Locale = require(Config:WaitForChild("Locale"))

--==================================================
-- 言語正規化（Locale に委譲）
--==================================================
function ShopFormat.normLang(s: string?): string
	return Locale.normalize(s)
end

--==================================================
-- 価格表記（※従来通り「文」固定。英語UIでもこのまま）
--==================================================
function ShopFormat.fmtPrice(n: number?): string
	return ("%d 文"):format(tonumber(n or 0))
end

--==================================================
-- タイトル/説明（Locale.t 最優先 → 既存フィールドへフォールバック）
--==================================================
-- 後方互換：lang 省略可（省略時は Locale の共有言語を使用）
function ShopFormat.itemTitle(it: any, lang: string?): string
	if not it then return "???" end
	local id = tostring(it.id or "")
	if id ~= "" then
		local key = ("SHOP_ITEM_%s_NAME"):format(id)
		local s = Locale.t(lang, key)
		if s and s ~= key then
			return s
		end
	end
	-- フォールバック：従来 name → id
	return tostring(it.name or (id ~= "" and id) or "???")
end

function ShopFormat.itemDesc(it: any, lang: string?): string
	if not it then return "" end
	local id = tostring(it.id or "")
	if id ~= "" then
		local key = ("SHOP_ITEM_%s_DESC"):format(id)
		local s = Locale.t(lang, key)
		if s and s ~= key then
			return s
		end
	end
	-- 既存フィールドへフォールバック
	local use = Locale.normalize(lang)
	if use == "en" then
		return (it.descEN or it.descEn or it.name or it.id or "")
	else
		return (it.descJP or it.descJa or it.name or it.id or "")
	end
end

--==================================================
-- “名前だけ”フェイス表示（干支ID→短名）
--  - id/effect の両方を参照
--  - kito.<name> / kito_<name> / 旧モジュール名(Usagi_Ribbonize 等) すべて対応
--==================================================

-- 基底トークン -> 漢字
local ZKANJI: {[string]: string} = {
	ko="子", ushi="丑", tora="寅", u="卯", usagi="卯", tatsu="辰", mi="巳",
	uma="午", hitsuji="未", saru="申", tori="酉", inu="戌", i="亥",
}

-- 旧モジュール名（kito.* 以外）→ 漢字
local LEGACY_MODULE2KANJI: {[string]: string} = {
	["tori_brighten"]   = "酉",
	["mi_venom"]        = "巳",
	["usagi_ribbonize"] = "卯",
	["uma_seedize"]     = "午",
	["inu_chaff2"]      = "戌",
	["i_sakeify"]       = "亥",
	["hitsuji_prune"]   = "未",
}

local function pickZodiacKanjiFromId(s: string?): string?
	if type(s) ~= "string" then return nil end
	s = string.lower(s)

	-- 1) 旧モジュール名にそのまま一致
	do
		local direct = LEGACY_MODULE2KANJI[s]
		if direct then return direct end
	end

	-- 2) "kito.<name>..." / "kito_<name>..." の <name> を抽出（最初の区切りまで）
	--    例: kito.tori_brighten → tori / kito_inu_two_chaff → inu
	local name = s:match("^kito[._-]([a-z]+)")
	if name then
		if name == "u" then name = "usagi" end -- 旧: kito_u 対応
		return ZKANJI[name]
	end

	return nil
end

function ShopFormat.faceName(it: any): string
	if not it then return "???" end
	-- 1) 明示の短名を優先
	for _, k in ipairs({ "displayName", "short", "shortName" }) do
		local v = it[k]
		if v and tostring(v) ~= "" then return tostring(v) end
	end
	-- 2) effect → id の順で干支判定（ドット/アンダーバー/旧名すべてOK）
	local z = pickZodiacKanjiFromId(it.effect) or pickZodiacKanjiFromId(it.id)
	if z then return z end
	-- 3) 最後に name / id をそのまま
	return tostring(it.name or it.id or "???")
end


--==================================================
-- デッキスナップショット → リスト文字列
--==================================================
function ShopFormat.deckListFromSnapshot(snap: any): (integer, string)
	if typeof(snap) ~= "table" then return 0, "" end
	local countMap: {[string]: number} = {}
	local order = {}
	local entries = snap.entries
	if typeof(entries) == "table" and #entries > 0 then
		for _, e in ipairs(entries) do
			local code = tostring(e.code)
			if not countMap[code] then table.insert(order, code) end
			countMap[code] = (countMap[code] or 0) + 1
		end
	else
		for _, code in ipairs(snap.codes or {}) do
			code = tostring(code)
			if not countMap[code] then table.insert(order, code) end
			countMap[code] = (countMap[code] or 0) + 1
		end
	end
	table.sort(order, function(a,b) return a < b end)
	local parts = {}
	for _, code in ipairs(order) do
		local n = countMap[code] or 0
		table.insert(parts, (n > 1) and ("%s x%d"):format(code, n) or code)
	end
	return tonumber(snap.count or 0) or 0, table.concat(parts, ", ")
end

return ShopFormat
