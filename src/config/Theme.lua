-- ReplicatedStorage/Config/Theme.lua
-- v0.9.7-P1-5: Theme を単一情報源に（UIフォールバック撤去用の既定値を追加）
--              + SHOP_BG（屋台背景）を追加

local Theme = {}

--==================================================
-- 画像ID（畳・毛氈・木目・屋台など）
--==================================================
Theme.IMAGES = {
	ROOM_BG  = "rbxassetid://134603580471930",   -- 和室：背景（最背面）
	FIELD_BG = "rbxassetid://112698123788404",   -- 毛氈：場札エリア（現行の既定IDを尊重）
	TAKEN_BG = "rbxassetid://93059114972102",    -- 木目：取り札エリア

	-- ▼ 追加：ショップ（屋台）背景
	SHOP_BG  = "rbxassetid://98985791814763",
}

--==================================================
-- 背景透過度（視認性調整用）
--==================================================
Theme.TRANSPARENCY = {
	roomBg  = 0.15, -- 和室背景は少し淡く
	boardBg = 0.15, -- 毛氈はほんのり
	takenBg = 0.15, -- 木目もほんのり

	-- ▼ 追加：ショップ背景のデフォルト透過
	shopBg  = 0.12,
}
-- Overlay等の半透明（UI側が使う場合あり）
Theme.overlayBgT = 0.35

-- 右ペインの透過（既存UIが T.rightPaneBgT を読むのでデフォルトを用意）
Theme.rightPaneBgT = 0

-- ヘルプ既定文（Localeが取れない/未ロード時の最終フォールバック）
Theme.helpText = "札を選んで場の札と合わせよう！Rerollで手札を入れ替え可能。"

--==================================================
-- 横基準のプレイエリア縦横比
--==================================================
Theme.ASPECT = 16/9

--==================================================
-- 比率レイアウト用の定数
--==================================================
Theme.RATIOS = {
	PAD        = 0.02,
	CENTER_PAD = 0.02,

	LEFT_W     = 0.18,
	RIGHT_W    = 0.33, -- 広め右ペイン

	BOARD_H    = 0.50,
	TUTORIAL_H = 0.08,
	HAND_H     = 0.28,

	CONTROLS_H = 0.10,
	COL_GAP    = 0.015,

	-- 取り札の横重なり比（0〜1）
	TAKEN_OVERLAP = 0.33,
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
	RIGHT_W    = 495, -- 比率と揃う広めレイアウト
	ROW_GAP    = 12,

	-- ▼ 追加：UIフォールバック排除用
	HandSelectStrokeW = 3,   -- 手札選択枠の太さ
	TAKEN_TAG_W       = 110, -- 取り札セクションのタグ幅
}

--==================================================
-- 見た目（色・角丸）
--==================================================
Theme.COLORS = {
	TextDefault        = Color3.fromRGB(25, 25, 25),
	HelpText           = Color3.fromRGB(60, 40, 20),

	-- パネル系（和紙風に寄せたオフホワイト）
	RightPaneBg        = Color3.fromRGB(250, 248, 240),
	RightPaneStroke    = Color3.fromRGB(210, 200, 190),
	PanelBg            = Color3.fromRGB(252, 250, 244),
	PanelStroke        = Color3.fromRGB(220, 210, 200),

	-- カードバッジ帯
	BadgeBg            = Color3.fromRGB(25, 28, 36),
	BadgeStroke        = Color3.fromRGB(60, 65, 80),

	-- 手札エリアの装飾
	HandHolderBg       = Color3.fromRGB(245, 248, 252),
	HandHolderStroke   = Color3.fromRGB(210, 220, 230),

	-- ボタン
	PrimaryBtnBg       = Color3.fromRGB(190, 50, 50),
	PrimaryBtnText     = Color3.fromRGB(255, 245, 240),

	WarnBtnBg          = Color3.fromRGB(180, 80, 40),
	WarnBtnText        = Color3.fromRGB(255, 240, 230),

	CancelBtnBg        = Color3.fromRGB(120, 130, 140),
	CancelBtnText      = Color3.fromRGB(240, 240, 240),

	DevBtnBg           = Color3.fromRGB(40, 100, 60),
	DevBtnText         = Color3.fromRGB(255, 255, 255),

	-- UI側フォールバックを消すために追加（役一覧ボタン等）
	InfoBtnBg          = Color3.fromRGB(120, 180, 255),

	-- ▼ 追加：RunScreenUI/Taken/HandRenderer で参照されうる既定
	NoticeBg           = Color3.fromRGB(240, 246, 255), -- Noticeバー
	TutorialBg         = Color3.fromRGB(255, 153, 0),   -- Tutorialバー
	OverlayBg          = Color3.fromRGB(0, 0, 0),       -- Overlay下地
	HandSelectStroke   = Color3.fromRGB(40, 120, 90),   -- 手札選択枠の色
}

Theme.PANEL_RADIUS = 10

-- 影の濃さ（HandRenderer が参照）
Theme.HandShadowOnT  = 0.45
Theme.HandShadowOffT = 0.70

--==================================================
-- 役種に応じたバッジ文字色
--==================================================
function Theme.colorForKind(kind: string)
	if kind == "bright" then
		return Color3.fromRGB(255, 230, 140)
	elseif kind == "seed" then
		return Color3.fromRGB(200, 240, 255)
	elseif kind == "ribbon" then
		return Color3.fromRGB(255, 200, 220)
	else
		return Color3.fromRGB(235, 235, 235)
	end
end

return Theme
