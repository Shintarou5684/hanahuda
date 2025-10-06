-- KitoPickStyles.lua
-- Pass1: 既存見た目そのまま / 値だけ集約

local Color3 = Color3
local M = {}

M.colors = {
  shade             = Color3.new(0, 0, 0),
  panelBg           = Color3.fromRGB(24,24,28),

  -- カード
  cardBg            = Color3.fromRGB(40,42,54),
  cardImgFallback   = Color3.fromRGB(55,57,69),
  cardNameText      = Color3.fromRGB(232,232,240),
  cardInfoText      = Color3.fromRGB(210,210,220),

  -- テキスト
  titleText         = Color3.fromRGB(230,230,240),
  kitoNameText      = Color3.fromRGB(236,236,246),
  effectText        = Color3.fromRGB(200,200,210),
  pickInfoText      = Color3.fromRGB(200,200,210),

  -- ボタン
  confirmText       = Color3.fromRGB(16,16,20),
  confirmBg         = Color3.fromRGB(120,200,120),
  skipText          = Color3.fromRGB(230,230,240),
  skipBg            = Color3.fromRGB(70,70,78),

  -- 選択
  selectedBg        = Color3.fromRGB(70,110,210),
  selectedStroke    = Color3.fromRGB(90,130,230),

  -- 非対象
  ineligibleMask    = Color3.new(0,0,0),
  ineligibleTitle   = Color3.fromRGB(230,230,240),
  ineligibleSub     = Color3.fromRGB(220,220,230),
}

M.sizes = {
  -- レイヤ
  shadeTransparency     = 0.35,

  -- パネル
  panelCorner           = 18,
  panelPadding          = 16,
  panelWidth            = 880,
  panelHeight           = 560,
  panelPosYScale        = 0.52,  -- パネルY（中央より少し下）

  -- ヘッダ
  titleHeight           = 28,
  headerIcon            = 44,
  headerGap             = 8,
  kitoNameHeight        = 22,
  kitoNameTopGap        = 2,

  -- 効果説明
  effectTopGap          = 6,
  effectMinHeight       = 22,
  effectInitHeight      = 40,   -- 初期配置用の仮高さ（実際は TextBounds で再レイアウト）
  effectBelowGap        = 8,

  -- フッタ
  footerHeightReserve   = 84,   -- 下部の確保枠（レイアウト用）
  footerHeight          = 52,
  footerBottomGap       = 8,

  -- スクロール / グリッド
  scrollBar             = 6,
  gridCellW             = 180,
  gridCellH             = 160,
  gridGap               = 12,

  -- カード内寸
  cardImgH              = 112,
  cardNameH             = 18,
  cardNameLeft          = 6,
  cardNameTopGap        = 4,
  cardInfoH             = 16,
  cardInfoLeft          = 6,
  cardInfoBottomGap     = 8,

  -- ボタン
  btnCorner             = 10,
  btnSkipW              = 140,
  btnConfirmW           = 160,
  btnH                  = 44,
  btnGap                = 16,   -- Skip と Confirm の間
  btnRightGap           = 8,    -- Confirm の右余白

  -- ラベル
  pickInfoRightReserve  = 360,  -- PickInfo右側の確保幅（ボタン領域）
}

M.fontSizes = {
  title     = 22,
  kitoName  = 20,
  effect    = 18,
  pickInfo  = 18,
  btn       = 20,
  cardName  = 16,
  cardInfo  = 14,
  inelMain  = 18,
  inelSub   = 14,
}

M.z = {
  panel = 1,
  overlay = 5,
  overlayText = 6,
  headerIcon = 2,
}

return M
