-- StarterPlayerScripts/UI/lib/FormatUtil.lua
-- スコア・状態などの整形ユーティリティ（12か月版・言語対応）
-- ・month / monthStr / goal を優先表示（season は互換として括弧付き併記）
-- ・旧フィールド（target, season, seasonStr 等）も吸収

local RS = game:GetService("ReplicatedStorage")
local Locale = require(RS:WaitForChild("Config"):WaitForChild("Locale"))

local M = {}

--==================================================
-- 言語コードの正規化
--==================================================
local function normLang(lang: string?)
	local v = tostring(lang or ""):lower()
	if v == "jp" then v = "ja" end
	if v ~= "ja" and v ~= "en" then v = "en" end
	return v
end

--==================================================
-- 役名のローカライズ辞書（"ja" を正規キーに）
--==================================================
local ROLE_NAMES = {
	en = {
		five_bright      = "Five Brights",
		four_bright      = "Four Brights",
		rain_four_bright = "Rain Four Brights",
		three_bright     = "Three Brights",
		inoshikacho      = "Boar–Deer–Butterfly",
		red_ribbon       = "Red Ribbons",
		blue_ribbon      = "Blue Ribbons",
		seeds            = "Seeds",
		ribbons          = "Ribbons",
		chaffs           = "Chaff",
		hanami           = "Hanami Sake",
		tsukimi          = "Tsukimi Sake",
	},
	ja = {
		five_bright      = "五光",
		four_bright      = "四光",
		rain_four_bright = "雨四光",
		three_bright     = "三光",
		inoshikacho      = "猪鹿蝶",
		red_ribbon       = "赤短",
		blue_ribbon      = "青短",
		seeds            = "たね",
		ribbons          = "たん",
		chaffs           = "かす",
		hanami           = "花見で一杯",
		tsukimi          = "月見で一杯",
	}
}

--==================================================
-- 役集合を「a / b / c」形式の文字列に
-- roles: { [role_key]=true or number } / array でもOK（キーを拾う）
--==================================================
function M.rolesToLines(roles, langOpt)
	local lang = normLang(langOpt or (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en")
	local names = ROLE_NAMES[lang] or ROLE_NAMES.en

	if typeof(roles) ~= "table" then
		return Locale.t(lang, "ROLES_NONE")
	end

	local hasAny = false
	local list = {}

	-- roles が map でも配列でも対応
	for k, v in pairs(roles) do
		local key = (typeof(k) == "string") and k
		         or (typeof(v) == "string") and v
		         or nil
		if key then
			local disp = names[key] or key
			table.insert(list, disp)
			hasAny = true
		end
	end

	if not hasAny or #list == 0 then
		return Locale.t(lang, "ROLES_NONE")
	end

	table.sort(list, function(a, b) return tostring(a) < tostring(b) end)
	return table.concat(list, " / ")
end

--==================================================
-- 月名 / 季節名（簡易ローカライズ）
--==================================================
local SEASON_JA = {"春","夏","秋","冬"}
local SEASON_EN = {"Spring","Summer","Autumn","Winter"}

local function monthLabel(m:number, lang:string): string
	m = tonumber(m) or 0
	if m < 1 then m = 1 end
	if m > 12 then m = 12 end
	-- monthStr が来ない場合のフォールバック表記
	if lang == "ja" then
		return tostring(m) .. "月"
	else
		return "M" .. tostring(m)
	end
end

local function seasonLabel(s:number, lang:string): string
	local tbl = (lang=="ja") and SEASON_JA or SEASON_EN
	if s>=1 and s<=#tbl then return tbl[s] end
	-- 不明値を簡易に整形
	return (lang=="ja") and ("季節"..tostring(s)) or ("S"..tostring(s))
end

--==================================================
-- 状態行（英/日対応・12か月対応）
-- 呼び出し側から lang を渡す想定（nilなら "en"）
--==================================================
function M.stateLineText(st, langOpt)
	local lang = normLang(langOpt or (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en")

	-- できるだけ多くのキーに対応（サーバ実装差異の吸収）
	local y     = tonumber(st and (st.year or st.y)) or 0
	local s     = tonumber(st and (st.season or st.s)) or 0
	local m     = tonumber(st and (st.month or (st.run and st.run.month))) or 0
	local goal  = st and (st.goal or st.target)
	local sum   = tonumber(st and (st.sum or st.seasonSum)) or 0
	local handsLeft   = tonumber(st and (st.hands or st.handLeft or st.handsLeft or st.handRemain)) or 0
	local rerollsLeft = tonumber(st and (st.rerolls or st.rerollRemain or st.rerollsLeft)) or 0
	local mult  = tonumber(st and (st.mult or st.multiplier)) or 1
	local bank  = tonumber(st and (st.bank)) or 0
	local deckLeft = tonumber(st and (st.deckLeft or st.deck or st.deckCount)) or 0
	local handCount= tonumber(st and (st.hand or st.handCount)) or 0

	local yearTxt = (y > 0) and tostring(y) or ((lang=="ja") and "----" or "----")

	-- month は文字列優先
	local monthStr = nil
	if st and typeof(st.monthStr) == "string" and st.monthStr ~= "" then
		monthStr = st.monthStr
	else
		monthStr = (m > 0) and monthLabel(m, lang) or ((lang=="ja") and "--月" or "M--")
	end

	-- season は互換のため括弧で併記（存在時のみ）
	local seasonStr: string? = nil
	if st and typeof(st.seasonStr) == "string" and st.seasonStr ~= "" then
		seasonStr = st.seasonStr
	elseif s > 0 then
		seasonStr = seasonLabel(s, lang)
	end
	local seasonSuffix = (seasonStr and seasonStr ~= "") and (lang=="ja" and ("（"..seasonStr.."）") or (" ("..seasonStr..")")) or ""

	if lang == "ja" then
		return string.format(
			"年:%s  月:%s%s  目標:%s  合計:%d  残ハンド:%d  残リロール:%d  倍率:%.1fx  Bank:%d  山:%d  手:%d",
			yearTxt, monthStr, seasonSuffix, tostring(goal or "—"), sum, handsLeft, rerollsLeft, mult, bank, deckLeft, handCount
		)
	else
		return string.format(
			"Year:%s  Month:%s%s  Goal:%s  Total:%d  Hands:%d  Rerolls:%d  Mult:%.1fx  Bank:%d  Deck:%d  Hand:%d",
			yearTxt, monthStr, seasonSuffix, tostring(goal or "—"), sum, handsLeft, rerollsLeft, mult, bank, deckLeft, handCount
		)
	end
end

return M
