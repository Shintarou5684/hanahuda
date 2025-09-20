-- src/client/ui/components/i18n/ShopI18n.lua
-- v0.9.ADAPTER ShopI18n → Locale 委譲アダプタ
-- 目的:
--  - 既存呼び出し(ShopI18n.t(lang, key, ...))はそのまま
--  - 内部で Locale.t(lang, "SHOP_UI_*") に委譲（マッピング付き）
--  - Locale 未定義キーはレガシー内蔵辞書へフォールバック
--
-- ログ:
--  - 初期化時: [ShopI18n] adapter active
--  - マッピング使用時: [ShopI18n] map old_key -> SHOP_UI_*
--  - フォールバック時: [ShopI18n] fallback legacy for key=...

local RS = game:GetService("ReplicatedStorage")

-- Locale / Logger
local Config        = RS:WaitForChild("Config")
local Locale        = require(Config:WaitForChild("Locale"))
local SharedModules = RS:WaitForChild("SharedModules")
local Logger        = require(SharedModules:WaitForChild("Logger"))
local LOG           = Logger.scope("ShopI18n")

local M = {}

--========================
-- 旧→新キー マッピング
--========================
local MAP_OLD_TO_NEW = {
  title_mvp            = "SHOP_UI_TITLE",
  deck_btn_show        = "SHOP_UI_VIEW_DECK",
  deck_btn_hide        = "SHOP_UI_HIDE_DECK",
  reroll_btn_fmt       = "SHOP_UI_REROLL_FMT",
  info_title           = "SHOP_UI_INFO_TITLE",
  info_placeholder     = "SHOP_UI_INFO_PLACEHOLDER",
  deck_title_fmt       = "SHOP_UI_DECK_TITLE_FMT",
  deck_empty           = "SHOP_UI_DECK_EMPTY",
  summary_cleared_fmt  = "SHOP_UI_SUMMARY_CLEARED_FMT",
  summary_items_fmt    = "SHOP_UI_SUMMARY_ITEMS_FMT",
  summary_money_fmt    = "SHOP_UI_SUMMARY_MONEY_FMT",
  close_btn            = "SHOP_UI_CLOSE_BTN",
  toast_closed         = "SHOP_UI_TOAST_CLOSED",     -- （Locale未定義なら下のレガシーにフォールバック）
  label_category       = "SHOP_UI_LABEL_CATEGORY",
  label_price          = "SHOP_UI_LABEL_PRICE",
  no_desc              = "SHOP_UI_NO_DESC",
  insufficient_suffix  = "SHOP_UI_INSUFFICIENT_SUFFIX",
}

--========================
-- レガシー辞書（フォールバック用）
--========================
local en_legacy = {
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

local ja_legacy = {
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

local function pickLegacy(lang: string?)
  local use = Locale.normalize(lang)
  return (use == "en") and en_legacy or ja_legacy
end

--========================
-- 本体: t(lang, key, ...)
--========================
local function resolveKey(key: string)
  -- 旧キー → 新キー
  local mapped = MAP_OLD_TO_NEW[key]
  if mapped then return mapped, true end
  -- 既に新キー（SHOP_UI_...）を直接呼ばれた場合もそのまま許容
  if string.sub(key, 1, 8) == "SHOP_UI_" then
    return key, false
  end
  return nil, false
end

local function safeFormat(fmtStr: string, ...)
  if select("#", ...) == 0 then return fmtStr end
  local ok, out = pcall(string.format, fmtStr, ...)
  return ok and out or fmtStr
end

function M.t(lang: string?, key: string, ...)
  key = tostring(key or "")
  if key == "" then return "" end

  local use = Locale.normalize(lang)
  local newKey, mapped = resolveKey(key)
  if newKey then
    local res = Locale.t(use, newKey, ...)
    if res ~= newKey then
      if mapped then
        LOG.debug("adapter map %s -> %s | lang=%s", key, newKey, use)
      end
      return res
    end
    -- 委譲先に未定義 → 下へフォールバック
    LOG.debug("adapter miss Locale for key=%s (mapped=%s)", newKey, tostring(mapped))
  else
    LOG.debug("adapter pass-through (legacy key) key=%s", key)
  end

  -- ===== フォールバック：レガシー辞書 =====
  local legacy = pickLegacy(use)
  local base = legacy[key]
  if base ~= nil then
    LOG.debug("fallback legacy for key=%s | lang=%s", key, use)
    return safeFormat(base, ...)
  end

  -- 最終フォールバック：新キーを持っていればそれも見る
  if newKey and legacy[newKey] then
    LOG.debug("fallback legacy(newKey) for key=%s -> %s | lang=%s", key, newKey, use)
    return safeFormat(legacy[newKey], ...)
  end

  -- 何も無ければキーをそのまま返す
  LOG.warn("missing i18n key (no Locale, no legacy) key=%s", key)
  return key
end

LOG.info("adapter active (Locale-first)")

return M
