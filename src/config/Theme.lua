-- C:\Users\msk_7\Documents\Roblox\hanahuda\src\config\Theme.lua
local Theme = {}

--==================================================
-- 画像ID（畳・毛氈・木目など）
--==================================================
Theme.IMAGES = {
	ROOM_BG   = "rbxassetid://134603580471930",   -- 和室：背景（最背面）
	FIELD_BG  = "rbxassetid://112698123788404",   -- 毛氈：場札エリア
	TAKEN_BG  = "rbxassetid://93059114972102",    -- 木目：取り札エリア
}

--==================================================
-- 背景透過度（視認性調整用）
--==================================================
Theme.TRANSPARENCY = {
	roomBg  = 0.15, -- 和室背景は少し淡く
	boardBg = 0.15, -- 毛氈はほんのり
	takenBg = 0.15, -- 木目もほんのり
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
	TextDefault        = Color3.fromRGB(25,25,25),
	HelpText           = Color3.fromRGB(60,40,20), -- ★濃茶寄りで視認性改善

	-- パネル系（和紙風に寄せたオフホワイト）
	RightPaneBg        = Color3.fromRGB(250,248,240),
	RightPaneStroke    = Color3.fromRGB(210,200,190),
	PanelBg            = Color3.fromRGB(252,250,244),
	PanelStroke        = Color3.fromRGB(220,210,200),

	-- カードバッジ帯
	BadgeBg            = Color3.fromRGB(25,28,36),
	BadgeStroke        = Color3.fromRGB(60,65,80),

	-- 手札エリアの装飾
	HandHolderBg       = Color3.fromRGB(245,248,252),
	HandHolderStroke   = Color3.fromRGB(210,220,230),

	-- ボタン
	PrimaryBtnBg  = Color3.fromRGB(190, 50, 50),   -- 勝負ボタン：深紅
  PrimaryBtnText= Color3.fromRGB(255, 245, 240),

  WarnBtnBg     = Color3.fromRGB(180, 80, 40),   -- リロール：赤茶
  WarnBtnText   = Color3.fromRGB(255, 240, 230),

  CancelBtnBg   = Color3.fromRGB(120, 130, 140), -- 戻る/キャンセル：灰青
  CancelBtnText = Color3.fromRGB(240, 240, 240),

  DevBtnBg      = Color3.fromRGB(40, 100, 60),   -- DEV：深緑
  DevBtnText    = Color3.fromRGB(255, 255, 255),
}


Theme.PANEL_RADIUS = 10

--==================================================
-- 役種に応じたバッジ文字色
--==================================================
function Theme.colorForKind(kind: string)
	if kind == "bright" then
		return Color3.fromRGB(255,230,140)
	elseif kind == "seed" then
		return Color3.fromRGB(200,240,255)
	elseif kind == "ribbon" then
		return Color3.fromRGB(255,200,220)
	else
		return Color3.fromRGB(235,235,235)
	end
end

return Theme
