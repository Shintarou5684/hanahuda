--C:\Users\msk_7\Documents\Roblox\hanahuda\src\config\Theme.lua
local Theme = {}

-- 画像ID（畳など）
Theme.IMAGES = {
	FIELD_BG = "rbxassetid://138521222203366", -- 最新指定
}

-- サイズ・余白（見本寄せ）
Theme.SIZES = {
	PAD        = 10,
	BOARD_H    = 340,   -- 場画像エリア
	CONTROLS_H = 44,    -- アクションボタン行（小さく）
	HELP_H     = 22,    -- ボタン下ヘルプ
	HAND_H     = 168,
	RIGHT_W    = 330,
	ROW_GAP    = 12,    -- 場札上下段の隙間
}

-- 色（UIの共通カラー。必要に応じて追加）
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

	-- 手札エリアの装飾（必要なら使う）
	HandHolderBg       = Color3.fromRGB(245,248,252),
	HandHolderStroke   = Color3.fromRGB(210,220,230),

	-- ボタン
	DevBtnBg           = Color3.fromRGB(35,130,90),
	DevBtnText         = Color3.fromRGB(255,255,255),
}

-- 役種に応じたバッジ文字色
function Theme.colorForKind(kind: string)
	if kind == "bright" then return Color3.fromRGB(255,230,140)
	elseif kind == "seed" then return Color3.fromRGB(200,240,255)
	elseif kind == "ribbon" then return Color3.fromRGB(255,200,220)
	else return Color3.fromRGB(235,235,235) end
end

return Theme
