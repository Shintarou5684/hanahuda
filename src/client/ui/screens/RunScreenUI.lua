-- StarterPlayerScripts/UI/screens/RunScreenUI.lua
-- 画面の土台UIを構築して参照を束ねて返す（重複除去リファクタ版）

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

local lib    = script.Parent.Parent:WaitForChild("lib")
local UiUtil = require(lib:WaitForChild("UiUtil"))

local M = {}

--=== local helpers ======================================================
local function addCornerStroke(frame: Instance, radius: number?, strokeColor: Color3?, thickness: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or (Theme.PANEL_RADIUS or 10))
	corner.Parent = frame

	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1
	if strokeColor then s.Color = strokeColor end
	s.Parent = frame
	return frame
end

local function makeList(parent: Instance, dir: Enum.FillDirection, paddingScaleOrPx: number, hAlign, vAlign)
	local l = Instance.new("UIListLayout")
	l.Parent = parent
	l.FillDirection = dir
	local isScale = paddingScaleOrPx <= 1
	l.Padding = isScale and UDim.new(paddingScaleOrPx, 0) or UDim.new(0, paddingScaleOrPx)
	l.HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left
	l.VerticalAlignment   = vAlign or Enum.VerticalAlignment.Top
	l.SortOrder = Enum.SortOrder.LayoutOrder
	return l
end

local function makePanel(parent: Instance, name: string, sizeScale: Vector2, layoutOrder: number, bgColor: Color3, strokeColor: Color3?, titleText: string?, titleColor: Color3?)
	local p = Instance.new("Frame")
	p.Name = name
	p.Parent = parent
	p.Size = UDim2.fromScale(sizeScale.X, sizeScale.Y)
	p.LayoutOrder = layoutOrder or 1
	p.BackgroundColor3 = bgColor
	addCornerStroke(p, nil, strokeColor, 1)

	if titleText and titleText ~= "" then
		local title = UiUtil.makeLabel(p, name.."Title", titleText, UDim2.new(1,-12,0,24), UDim2.new(0,6,0,6), nil, titleColor)
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
	end
	return p
end

local function makeSideBtn(parent: Instance, name: string, text: string, bg: Color3)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Parent = parent
	btn.Size = UDim2.new(1, 0, 0, 44)
	btn.AutoButtonColor = true
	btn.Text = text
	btn.TextScaled = true
	btn.BackgroundColor3 = bg
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = btn
	return btn
end
--=======================================================================

function M.build(parentGui: Instance)
	--=== Theme 参照（比率優先） ========================================
	local T = Theme or {}
	local S = T.SIZES  or {}
	local C = T.COLORS or {}
	local R = T.RATIOS or {}
	local IMAGES = T.IMAGES or {}

	local ASPECT       = T.ASPECT or (16/9)
	local PAD          = (R.CENTER_PAD ~= nil and R.CENTER_PAD) or (R.PAD or 0.02)
	local LEFT_W       = R.LEFT_W      or 0.18
	local RIGHT_W      = R.RIGHT_W     or 0.22
	local BOARD_H      = R.BOARD_H     or 0.50
	local TUTORIAL_H   = R.TUTORIAL_H  or 0.08
	local HAND_H       = R.HAND_H      or 0.28
	local CONTROLS_H   = R.CONTROLS_H  or 0.10
	local ROW_GAP      = 0.035

	local FIELD_BG_IMAGE = IMAGES.FIELD_BG or "rbxassetid://138521222203366"

	local COLOR_TEXT         = C.TextDefault     or Color3.fromRGB(20,20,20)
	local COLOR_RIGHT_BG     = C.RightPaneBg     or Color3.fromRGB(245,248,255)
	local COLOR_RIGHT_STROKE = C.RightPaneStroke or Color3.fromRGB(210,220,230)
	local COLOR_PANEL_BG     = C.PanelBg         or Color3.fromRGB(255,255,255)
	local COLOR_PANEL_STROKE = C.PanelStroke     or Color3.fromRGB(220,225,235)
	local COL_GAP      = R.COL_GAP or 0.015  -- ← 追加：列のすき間（左右ともにこの幅）



	--=== Root ScreenGui ==================================================
	local g = parentGui
	if not g or not g:IsA("ScreenGui") then
		g = Instance.new("ScreenGui")
		g.Name = "RunScreen"
		g.ResetOnSpawn = false
		g.IgnoreGuiInset = true
		g.DisplayOrder = 10
		g.Enabled = true
		g.Parent = parentGui
	end

	--=== Root と PlayArea ================================================
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Parent = g
	root.Size = UDim2.fromScale(1,1)
	root.BackgroundTransparency = 1
	root.Visible = false

	local playArea = Instance.new("Frame")
	playArea.Name = "PlayArea"
	playArea.Parent = root
	playArea.AnchorPoint = Vector2.new(0.5,0.5)
	playArea.Position = UDim2.fromScale(0.5,0.5)
	playArea.Size = UDim2.fromScale(1,1)
	playArea.BackgroundTransparency = 1
	do
		local ar = Instance.new("UIAspectRatioConstraint")
		ar.AspectRatio = ASPECT
		ar.DominantAxis = Enum.DominantAxis.Width
		ar.Parent = playArea
	end

	--=== 3カラム ========================================================
	local left = Instance.new("Frame")
	left.Name = "LeftSidebar"
	left.Parent = playArea
	left.BackgroundTransparency = 1
	left.Size = UDim2.fromScale(LEFT_W, 1 - PAD*2)
	left.Position = UDim2.fromScale(PAD, PAD)

	local center = Instance.new("Frame")
	center.Name = "CenterMain"
	center.Parent = playArea
	center.BackgroundTransparency = 1
	center.Size     = UDim2.fromScale(1 - LEFT_W - RIGHT_W - PAD*2 - COL_GAP*2, 1 - PAD*2)
	center.Position = UDim2.fromScale(PAD + LEFT_W + COL_GAP, PAD)


	local rightPane = Instance.new("Frame")
	rightPane.Name = "RightPane"
	rightPane.Parent = playArea
	rightPane.BackgroundColor3 = COLOR_RIGHT_BG
	rightPane.BackgroundTransparency = T.rightPaneBgT or 0.08
	rightPane.Size = UDim2.fromScale(RIGHT_W, 1 - PAD*2)
	rightPane.Position = UDim2.fromScale(1 - RIGHT_W - PAD, PAD)
	addCornerStroke(rightPane, nil, COLOR_RIGHT_STROKE, 1)

	--=== Left：情報 → 目標 → 現在スコア → 操作 =========================
	makeList(left, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

	-- 情報パネル（1）
	local infoPanel = makePanel(left, "InfoPanel", Vector2.new(1, 0.14), 1, COLOR_PANEL_BG, COLOR_PANEL_STROKE)
	local info = UiUtil.makeLabel(infoPanel, "Info",
		"年:----  季節:--  目標:--  合計:--  残ハンド:--  残リロール:--  倍率:--  Bank:--",
		UDim2.new(1,-12,1,-12), UDim2.new(0,6,0,6), Vector2.new(0,0), COLOR_TEXT)
	info.TextWrapped = true
	info.TextScaled = true
	info.TextXAlignment = Enum.TextXAlignment.Left

	-- 目標スコア（2）
	local goalPanel = makePanel(left, "GoalPanel", Vector2.new(1, 0.10), 2, COLOR_PANEL_BG, COLOR_PANEL_STROKE, "目標スコア", COLOR_TEXT)
	local goalText = UiUtil.makeLabel(goalPanel, "GoalValue", "—", UDim2.new(1,-12,1,-36), UDim2.new(0,6,0,30), nil, COLOR_TEXT)
	goalText.TextScaled = true
	goalText.TextXAlignment = Enum.TextXAlignment.Left

	-- 現在スコア（3）
	local scorePanel = makePanel(left, "ScorePanel", Vector2.new(1, 0.22), 3, COLOR_PANEL_BG, COLOR_PANEL_STROKE, "現在スコア", COLOR_TEXT)
	local scoreBox = UiUtil.makeLabel(scorePanel, "ScoreBox", "得点：0\n役：--",
		UDim2.new(1,-12,1,-42), UDim2.new(0,6,0,36), nil, COLOR_TEXT)
	scoreBox.TextYAlignment = Enum.TextYAlignment.Top

	-- 操作（4）
	local controlsPanel = Instance.new("Frame")
	controlsPanel.Name = "ControlsPanel"
	controlsPanel.Parent = left
	controlsPanel.Size = UDim2.fromScale(1, 0)
	controlsPanel.AutomaticSize = Enum.AutomaticSize.Y
	controlsPanel.BackgroundTransparency = 1
	controlsPanel.LayoutOrder = 4

	makeList(controlsPanel, Enum.FillDirection.Vertical, 8)

	local COLOR_PRIMARY = C.PrimaryBtnBg or Color3.fromRGB(255,153,0)
	local COLOR_WARN    = C.WarnBtnBg    or Color3.fromRGB(220,70,70)

	local btnConfirm    = makeSideBtn(controlsPanel, "Confirm",    "この手で勝負", COLOR_PRIMARY)
	local btnRerollAll  = makeSideBtn(controlsPanel, "RerollAll",  "全体リロール", COLOR_WARN)
	local btnRerollHand = makeSideBtn(controlsPanel, "RerollHand", "手札だけリロール", COLOR_WARN)

	--=== Center：盤面 / お知らせ / チュートリアル / 手札 ================
	makeList(center, Enum.FillDirection.Vertical, 0.02, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

	-- 盤面（1）
	local boardArea = Instance.new("Frame")
	boardArea.Name = "BoardArea"
	boardArea.Parent = center
	boardArea.BackgroundTransparency = 1
	boardArea.Size = UDim2.fromScale(1, BOARD_H)
	boardArea.LayoutOrder = 1
	do
		local tatami = Instance.new("ImageLabel")
		tatami.Name = "TatamiBG"
		tatami.Parent = boardArea
		tatami.Image = FIELD_BG_IMAGE
		tatami.BackgroundTransparency = 1
		tatami.Size = UDim2.fromScale(1,1)
		tatami.ScaleType = Enum.ScaleType.Crop
		tatami.ZIndex = 0

		local boardWrap = Instance.new("Frame")
		boardWrap.Name = "BoardWrap"
		boardWrap.Parent = boardArea
		boardWrap.BackgroundTransparency = 1
		boardWrap.Size = UDim2.fromScale(1,1)
		boardWrap.ZIndex = 1

		makeList(boardWrap, Enum.FillDirection.Vertical, ROW_GAP)

		local boardRowTop = Instance.new("Frame")
		boardRowTop.Name = "BoardRowTop"
		boardRowTop.Parent = boardWrap
		boardRowTop.BackgroundTransparency = 1
		boardRowTop.Size = UDim2.fromScale(1, (1 - ROW_GAP) * 0.5)
		makeList(boardRowTop, Enum.FillDirection.Horizontal, 0.02)

		local boardRowBottom = Instance.new("Frame")
		boardRowBottom.Name = "BoardRowBottom"
		boardRowBottom.Parent = boardWrap
		boardRowBottom.BackgroundTransparency = 1
		boardRowBottom.Size = UDim2.fromScale(1, (1 - ROW_GAP) * 0.5)
		makeList(boardRowBottom, Enum.FillDirection.Horizontal, 0.02)

		-- 返却参照のためローカルに保持
		M._boardRowTop = boardRowTop
		M._boardRowBottom = boardRowBottom
	end

	-- お知らせ（2）
	local notice = Instance.new("Frame")
	notice.Name = "NoticeBar"
	notice.Parent = center
	notice.LayoutOrder = 4
	local noticeH = math.max(0.05, (TUTORIAL_H or 0.08) * 0.9)
	notice.Size = UDim2.fromScale(1, noticeH)
	notice.BackgroundColor3 = Color3.fromRGB(240,246,255)
	addCornerStroke(notice, nil, nil, 1)
	local noticeText = UiUtil.makeLabel(notice, "NoticeText", "", UDim2.new(1,-16,1,-12), UDim2.new(0,8,0,6), nil, COLOR_TEXT)
	noticeText.TextScaled = true
	noticeText.TextWrapped = true
	noticeText.TextXAlignment = Enum.TextXAlignment.Left

	-- 一行チュートリアル（3）
	local tutorial = Instance.new("Frame")
	tutorial.Name = "TutorialBar"
	tutorial.Parent = center
	tutorial.Size = UDim2.fromScale(1, TUTORIAL_H)
	tutorial.BackgroundColor3 = Color3.fromRGB(255,153,0)
	tutorial.LayoutOrder = 3
	addCornerStroke(tutorial, nil, nil, 1)
	local help = UiUtil.makeLabel(tutorial, "Help",
		T.helpText or "一行チュートリアル",
		UDim2.new(1,-16,1,-12), UDim2.new(0,8,0,6), nil, COLOR_TEXT)
	help.TextScaled = true
	help.TextWrapped = true
	help.TextXAlignment = Enum.TextXAlignment.Center

	-- 手札（4）
	local handArea = Instance.new("Frame")
	handArea.Name = "HandArea"
	handArea.Parent = center
	handArea.BackgroundTransparency = 1
	handArea.Size = UDim2.fromScale(1, HAND_H)
	handArea.LayoutOrder = 2

	--=== Right：取り札のみ ==============================================
	makeList(rightPane, Enum.FillDirection.Vertical, 0.02, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

	local takenPanel = makePanel(rightPane, "TakenPanel", Vector2.new(1,1), 1, COLOR_PANEL_BG, COLOR_PANEL_STROKE, "取り札", COLOR_TEXT)

	local takenBox = Instance.new("ScrollingFrame")
	takenBox.Name = "TakenBox"
	takenBox.Parent = takenPanel
	takenBox.Size = UDim2.new(1,-12,1,-42)
	takenBox.Position = UDim2.new(0,6,0,36)
	takenBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
	takenBox.CanvasSize = UDim2.new(0,0,0,0)
	takenBox.ScrollBarThickness = 8
	takenBox.BackgroundTransparency = 1

	--=== 返却 ===========================================================
	return {
		gui = g,
		root = root,
		playArea = playArea,
		info = info,
		goalText = goalText,
		help = help,
		notice = noticeText,
		handArea = handArea,
		boardRowTop = M._boardRowTop,
		boardRowBottom = M._boardRowBottom,
		takenBox = takenBox,
		scoreBox = scoreBox,
		buttons = {
			confirm = btnConfirm,
			rerollAll = btnRerollAll,
			rerollHand = btnRerollHand,
		},
		theme = { T = T, S = S, C = C, R = R },
	}
end

return M
