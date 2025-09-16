-- StarterPlayerScripts/UI/lib/FormatUtil.lua
-- スコア・状態などの整形ユーティリティ（言語対応）

local RS = game:GetService("ReplicatedStorage")
local Locale = require(RS:WaitForChild("Config"):WaitForChild("Locale"))

local M = {}

-- 役名のローカライズ辞書
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
  jp = {
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
  local lang = langOpt or (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
  local names = ROLE_NAMES[lang] or ROLE_NAMES.en

  if typeof(roles) ~= "table" then
    return Locale.t(lang, "ROLES_NONE")
  end

  local hasAny = false
  local list = {}

  -- roles が map でも配列でも対応
  for k,v in pairs(roles) do
    local key = (typeof(k)=="string") and k or (typeof(v)=="string" and v) or nil
    if key then
      local disp = names[key] or key
      table.insert(list, disp)
      hasAny = true
    end
  end

  if not hasAny or #list == 0 then
    return Locale.t(lang, "ROLES_NONE")
  end

  table.sort(list, function(a,b) return tostring(a) < tostring(b) end)
  return table.concat(list, " / ")
end

-- 既存の日本語固定行はそのまま（範囲外）。必要になったらi18n化する。
function M.stateLineText(st)
  local ytxt = (st and st.year and tonumber(st.year) and st.year > 0) and tostring(st.year) or "----"
  local seasonTxt = (st and (st.seasonStr or (st.season and ("季節"..tostring(st.season))))) or "季節--"
  local target = (st and st.target) or 0
  local sum    = (st and st.sum)    or 0
  local hands  = (st and st.hands)  or 0
  local reroll = (st and st.rerolls) or 0
  local mult   = (st and st.mult)   or 1
  local bank   = (st and st.bank)   or 0
  local dleft  = (st and st.deckLeft) or 0
  local hleft  = (st and st.handLeft) or 0

  return ("年:%s  季節:%s  目標:%d  合計:%d  残ハンド:%d  残リロール:%d  倍率:%.1fx  Bank:%d  山:%d  手:%d")
    :format(ytxt, seasonTxt, target, sum, hands, reroll, mult, bank, dleft, hleft)
end

return M
