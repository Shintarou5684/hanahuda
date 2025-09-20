-- StarterPlayerScripts/UI/lib/FormatUtil.lua
-- スコア・状態などの整形ユーティリティ（言語対応）

local RS = game:GetService("ReplicatedStorage")
local Locale = require(RS:WaitForChild("Config"):WaitForChild("Locale"))

local M = {}

-- 言語コードの正規化
local function normLang(lang: string?)
	local v = tostring(lang or ""):lower()
	if v == "jp" then v = "ja" end
	if v ~= "ja" and v ~= "en" then v = "en" end
	return v
end

-- 役名のローカライズ辞書（"ja" を正規キーに）
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

-- 役集合を「a / b / c」形式の文字列に
-- roles: { [role_key]=true or number } / array でもOK（キーを拾う）
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

-- 状態行（英/日対応）
-- 呼び出し側から lang を渡す想定（nilなら "en"）
function M.stateLineText(st, langOpt)
  local lang = normLang(langOpt or (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en")

  -- できるだけ多くのキーに対応（サーバ実装差異の吸収）
  local y   = tonumber(st and (st.year or st.y)) or 0
  local s   = tonumber(st and (st.season or st.s)) or 0
  local goal= st and (st.goal or st.target)
  local sum = tonumber(st and (st.sum or st.seasonSum)) or 0
  local handsLeft   = tonumber(st and (st.hands or st.handLeft or st.handsLeft or st.handRemain)) or 0
  local rerollsLeft = tonumber(st and (st.rerolls or st.rerollRemain or st.rerollsLeft)) or 0
  local mult = tonumber(st and (st.mult or st.multiplier)) or 1
  local bank = tonumber(st and (st.bank)) or 0
  local deckLeft = tonumber(st and (st.deckLeft or st.deck or st.deckCount)) or 0
  local handCount= tonumber(st and (st.hand or st.handCount)) or 0

  local yearTxt = (y > 0) and tostring(y) or ((lang=="ja") and "----" or "----")

  -- season は文字列優先（例: "春/夏/秋/冬" をサーバが渡すケース）
  local seasonStr = nil
  if st and typeof(st.seasonStr) == "string" then seasonStr = st.seasonStr end
  if not seasonStr or seasonStr == "" then
    local seasJa = {"春","夏","秋","冬"}
    local seasEn = {"Spring","Summer","Autumn","Winter"}
    local tbl = (lang=="ja") and seasJa or seasEn
    seasonStr = (s>=1 and s<=#tbl) and tbl[s] or ((lang=="ja") and ("季節"..tostring(s)) or ("S"..tostring(s)))
  end

  if lang == "ja" then
    return string.format(
      "年:%s  季節:%s  目標:%s  合計:%d  残ハンド:%d  残リロール:%d  倍率:%.1fx  Bank:%d  山:%d  手:%d",
      yearTxt, seasonStr, tostring(goal or "—"), sum, handsLeft, rerollsLeft, mult, bank, deckLeft, handCount
    )
  else
    return string.format(
      "Year:%s  Season:%s  Goal:%s  Total:%d  Hand left:%d  Rerolls:%d  Mult:%.1fx  Bank:%d  Deck:%d  Hand:%d",
      yearTxt, seasonStr, tostring(goal or "—"), sum, handsLeft, rerollsLeft, mult, bank, deckLeft, handCount
    )
  end
end

return M
