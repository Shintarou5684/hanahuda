-- C:\Users\msk_7\Documents\Roblox\hanahuda\src\config\Theme.lua
local Theme = {}

--==================================================
-- 画像ID（畳など）
--==================================================
Theme.IMAGES = {
	FIELD_BG = "rbxassetid://138521222203366", -- 最新指定
}

--==================================================
-- 横基準のプレイエリア縦横比
--==================================================
Theme.ASPECT = 16/9

--==================================================
-- 比率レイアウト用の定数
--==================================================
Theme.RATIOS = {
	PAD         = 0.02,
	CENTER_PAD  = 0.02,

	LEFT_W      = 0.18,
	RIGHT_W     = 0.33, -- ★元0.22 → 約1.5倍に拡張

	BOARD_H     = 0.50,
	TUTORIAL_H  = 0.08,
	HAND_H      = 0.28,

	CONTROLS_H  = 0.10,
}

--==================================================
-- 絶対値サイズ
--==================================================
Theme.SIZES = {
	PAD        = 10,
	BOARD_H    = 340,
	CONTROLS_H = 44,
	HELP_H     = 22,
	HAND_H     = 168,
	RIGHT_W    = 495, -- ★元330 → 1.5倍に拡張
	ROW_GAP    = 12,
}

--==================================================
-- 見た目（色・角丸）
--==================================================
Theme.COLORS = {
	TextDefault        = Color3.fromRGB(20,20,20),
	HelpText           = Color3.fromRGB(30,90,120),

	-- パネル系
	RightPaneBg        = Color3.fromRGB(245,248,255),
	RightPaneStroke    = Color3.fromRGB(210,220,230),
	PanelBg            = Color3.fromRGB(255,255,255),
	PanelStroke        = Color3.fromRGB(220,225,235),

	-- カードバッジ帯
	BadgeBg            = Color3.fromRGB(25,28,36),
	BadgeStroke        = Color3.fromRGB(60,65,80),

	-- 手札エリアの装飾
	HandHolderBg       = Color3.fromRGB(245,248,252),
	HandHolderStroke   = Color3.fromRGB(210,220,230),

	-- ボタン
	DevBtnBg           = Color3.fromRGB(35,130,90),
	DevBtnText         = Color3.fromRGB(255,255,255),

	PrimaryBtnBg       = Color3.fromRGB(255,153,0),
	PrimaryBtnText     = Color3.fromRGB(30,30,30),
	WarnBtnBg          = Color3.fromRGB(220,70,70),
}

Theme.PANEL_RADIUS = 10

--==================================================
-- 役種に応じたバッジ文字色
--==================================================
function Theme.colorForKind(kind: string)
	if kind == "bright" then return Color3.fromRGB(255,230,140)
	elseif kind == "seed" then return Color3.fromRGB(200,240,255)
	elseif kind == "ribbon" then return Color3.fromRGB(255,200,220)
	else return Color3.fromRGB(235,235,235) end
end

return Theme
