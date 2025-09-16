-- src/client/ui/components/i18n/ShopI18n.lua
-- v0.9.SIMPLE Shop専用I18nアダプタ（残回数系キーを撤去）

local M = {}

local en = {
  title_mvp           = "Shop (MVP)",
  deck_btn_show       = "View Deck",
  deck_btn_hide       = "Hide Deck",
  reroll_btn_fmt      = "Reroll (-%d)",

  info_title          = "Item Info",
  info_placeholder    = "(Hover or click an item)",

  deck_title_fmt      = "Current Deck (%d cards)",
  deck_empty          = "(no cards)",

  summary_cleared_fmt = "Cleared! Total:%d / Target:%d\nReward: %d mon (Have: %d)\n",
  summary_items_fmt   = "Items: %d",
  summary_money_fmt   = "Money: %d mon",

  close_btn           = "Close shop and next season",
  toast_closed        = "Closed the shop. On to next season.",

  label_category      = "Category: %s",
  label_price         = "Price: %s",
  no_desc             = "(no description)",
  insufficient_suffix = " (insufficient)",
}

local ja = {
  title_mvp           = "屋台（MVP）",
  deck_btn_show       = "デッキを見る",
  deck_btn_hide       = "デッキを隠す",
  reroll_btn_fmt      = "リロール（-%d 文）",

  info_title          = "アイテム情報",
  info_placeholder    = "（アイテムにマウスを乗せるか、クリックしてください）",

  deck_title_fmt      = "現在のデッキ（%d 枚）",
  deck_empty          = "(カード無し)",

  summary_cleared_fmt = "達成！ 合計:%d / 目標:%d\n報酬：%d 文（所持：%d 文）\n",
  summary_items_fmt   = "商品数: %d 点",
  summary_money_fmt   = "所持文: %d 文",

  close_btn           = "屋台を閉じて次の季節へ",
  toast_closed        = "屋台を閉じました。次の季節へ。",

  label_category      = "カテゴリ: %s",
  label_price         = "価格: %s",
  no_desc             = "(説明なし)",
  insufficient_suffix = "（不足）",
}

local dict = { en = en, ja = ja }

local function pick(lang:string?)
  lang = tostring(lang or ""):lower()
  if lang == "en" then return "en" end
  if lang == "ja" or lang == "jp" then return "ja" end
  return "ja"
end

function M.t(lang:string?, key:string, ...)
  local use = pick(lang)
  local pack = dict[use] or dict.ja
  local base = (pack and pack[key]) or (dict.en and dict.en[key]) or key
  if select("#", ...) > 0 then
    local ok, res = pcall(string.format, base, ...)
    if ok then return res else return base end
  end
  return base
end

return M
