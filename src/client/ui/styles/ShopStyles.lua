-- src/client/ui/styles/ShopStyles.lua
-- Phase1: Theme をブリッジして Shop の見た目値を一元化

local RS = game:GetService("ReplicatedStorage")
local Config = RS:WaitForChild("Config")
local Theme = require(Config:WaitForChild("Theme"))

local M = {}

-- 色（Theme を既定にブリッジ）
M.colors = {
  rightPaneBg     = Theme.COLORS.RightPaneBg,
  rightPaneStroke = Theme.COLORS.RightPaneStroke,
  panelBg         = Theme.COLORS.PanelBg,
  panelStroke     = Theme.COLORS.PanelStroke,
  text            = Theme.COLORS.TextDefault,
  helpText        = Theme.COLORS.HelpText,
  primaryBtnBg    = Theme.COLORS.PrimaryBtnBg,
  primaryBtnText  = Theme.COLORS.PrimaryBtnText,
  warnBtnBg       = Theme.COLORS.WarnBtnBg,
  warnBtnText     = Theme.COLORS.WarnBtnText,
  badgeBg         = Theme.COLORS.BadgeBg,
  badgeStroke     = Theme.COLORS.BadgeStroke,
  -- セル背景（現行は PanelBg を流用）
  cardBg          = Theme.COLORS.PanelBg,
}

-- 寸法・角丸・比率
M.sizes = {
  modalWScale   = 0.82,
  modalHScale   = 0.72,
  panelCorner   = Theme.PANEL_RADIUS or 10,

  headerH       = 48,
  footerH       = 64,
  bodyPad       = 10,
  vlistGap      = 8,

  -- ヘッダボタン
  deckBtnW      = 140,
  deckBtnH      = 32,
  rerollBtnW    = 140,
  rerollBtnH    = 32,
  btnCorner     = 8,

  -- グリッド＆スクロール
  gridCellW     = 96,
  gridCellH     = 144,
  gridGap       = 8,
  scrollBar     = 8,

  -- セル（価格帯など）
  priceBandH    = 20,

  -- フッタ
  closeBtnW     = 260,
  closeBtnH     = 44,
}

-- フォントサイズ
M.fontSizes = {
  title         = 20,
  deckTitle     = 18,
  infoTitle     = 18,
  price         = 14,
  cellTextMax   = 24,
}

-- Z（参考値。既存と同等の並びを維持）
M.z = {
  modal     = 1,
  header    = 2,
  headerTxt = 3,
  cells     = 10,
  price     = 11,
}

return M