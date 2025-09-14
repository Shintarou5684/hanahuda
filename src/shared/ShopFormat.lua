-- ReplicatedStorage/SharedModules/ShopFormat.lua
-- v0.9.A ShopFormat：SHOP向けの整形系ユーティリティを集約（挙動は従来通り）
local ShopFormat = {}

--==================================================
-- 言語正規化（"en" / "ja"）
--==================================================
function ShopFormat.normLang(s: string?): string
	if s == "en" then return "en" end
	if s == "ja" or s == "jp" then return "ja" end
	return "ja"
end

--==================================================
-- 価格表記（※従来通り「文」固定。英語UIでもここはそのまま）
--==================================================
function ShopFormat.fmtPrice(n: number?): string
	return ("%d 文"):format(tonumber(n or 0))
end

--==================================================
-- タイトル/説明
--==================================================
function ShopFormat.itemTitle(it: any): string
	if it and it.name then return tostring(it.name) end
	return tostring(it and it.id or "???")
end

function ShopFormat.itemDesc(it: any, lang: string): string
	if not it then return "" end
	if lang == "en" then
		return (it.descEN or it.descEn or it.name or it.id or "")
	else
		return (it.descJP or it.descJa or it.name or it.id or "")
	end
end

--==================================================
-- “名前だけ”フェイス表示（干支ID→短名）
--==================================================
local ZODIAC_NAME: {[string]: string} = {
	kito_ko="子", kito_ushi="丑", kito_tora="寅", kito_u="卯", kito_tatsu="辰", kito_mi="巳",
	kito_uma="午", kito_hitsuji="未", kito_saru="申", kito_tori="酉", kito_inu="戌", kito_i="亥",
}

function ShopFormat.faceName(it: any): string
	if not it then return "???" end
	-- 1) 明示の短名を優先
	if it.displayName and tostring(it.displayName) ~= "" then return tostring(it.displayName) end
	if it.short and tostring(it.short) ~= "" then return tostring(it.short) end
	if it.shortName and tostring(it.shortName) ~= "" then return tostring(it.shortName) end
	-- 2) 干支IDは固定辞書
	if it.id and ZODIAC_NAME[it.id] then return ZODIAC_NAME[it.id] end
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
