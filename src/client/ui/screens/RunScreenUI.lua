-- StarterPlayerScripts/UI/screens/RunScreenUI.lua
-- 画面の土台UIを構築して参照を束ねて返す

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

local lib    = script.Parent.Parent:WaitForChild("lib")
local UiUtil = require(lib:WaitForChild("UiUtil"))

local M = {}

function M.build(parentGui: Instance)
	local T = Theme or {}
	local S = T.SIZES  or {}
	local C = T.COLORS or {}
	local IMAGES = T.IMAGES or {}

	local PAD         = S.PAD        or 10
	local BOARD_H     = S.BOARD_H    or 340
	local CONTROLS_H  = S.CONTROLS_H or 44
	local HELP_H      = S.HELP_H     or 22
	local HAND_H      = S.HAND_H     or 168
	local RIGHT_W     = S.RIGHT_W    or 330
	local ROW_GAP     = S.ROW_GAP    or 12
	local FIELD_BG_IMAGE = IMAGES.FIELD_BG or "rbxassetid://138521222203366"

	local COLOR_TEXT         = C.TextDefault     or Color3.fromRGB(20,20,20)
	local COLOR_HELP         = C.HelpText        or Color3.fromRGB(30,90,120)
	local COLOR_RIGHT_BG     = C.RightPaneBg     or Color3.fromRGB(245,248,255)
	local COLOR_RIGHT_STROKE = C.RightPaneStroke or Color3.fromRGB(210,220,230)
	local COLOR_PANEL_BG     = C.PanelBg         or Color3.fromRGB(255,255,255)
	local COLOR_PANEL_STROKE = C.PanelStroke     or Color3.fromRGB(220,225,235)
	local BUTTON_BG          = C.ButtonBg        or Color3.fromRGB(255,255,255)

	-- ルート ScreenGui（親が無ければ作成）
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

	local frame = Instance.new("Frame")
	frame.Name = "Root"
	frame.Parent = g
	frame.Size = UDim2.fromScale(1,1)
	frame.BackgroundTransparency = 1
	frame.Visible = false

	local info = UiUtil.makeLabel(frame, "Info",
		"年:----  季節:--  目標スコア:--  合計:--  残ハンド:--  残リロール:--  倍率:--  Bank:--",
		UDim2.new(1,-PAD*2,0,32), UDim2.new(1,-PAD,0,PAD-2), Vector2.new(1,0), COLOR_TEXT)
	info.TextXAlignment = Enum.TextXAlignment.Right

	-- 左：プレイエリア
	local playArea = Instance.new("Frame")
	playArea.Name="PlayArea"
	playArea.Parent=frame
	playArea.BackgroundTransparency = 1
	playArea.Position=UDim2.new(0,PAD,0,44)
	playArea.Size=UDim2.new(1,-(RIGHT_W+PAD*3),1,-(PAD*2))

	-- 場
	local boardArea = Instance.new("Frame")
	boardArea.Name="BoardArea"
	boardArea.Parent=playArea
	boardArea.BackgroundTransparency = 1
	boardArea.Size=UDim2.new(1,0,0,BOARD_H)

	local tatami = Instance.new("ImageLabel")
	tatami.Name = "TatamiBG"
	tatami.Parent = boardArea
	tatami.Image = FIELD_BG_IMAGE
	tatami.BackgroundTransparency = 1
	tatami.Size = UDim2.new(1, 0, 1, 0)
	tatami.ScaleType = Enum.ScaleType.Crop
	tatami.ZIndex = 0

	local boardWrap = Instance.new("Frame")
	boardWrap.Parent = boardArea
	boardWrap.BackgroundTransparency = 1
	boardWrap.Size = UDim2.new(1,0,1,0)
	boardWrap.ZIndex = 1
	local bwLayout = Instance.new("UIListLayout")
	bwLayout.Parent = boardWrap
	bwLayout.FillDirection = Enum.FillDirection.Horizontal
	bwLayout.Padding = UDim.new(0, 8)
	bwLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	bwLayout.VerticalAlignment = Enum.VerticalAlignment.Top

	local boardLabelCol = Instance.new("Frame")
	boardLabelCol.Name = "BoardLabelCol"
	boardLabelCol.Parent = boardWrap
	boardLabelCol.BackgroundTransparency = 1
	boardLabelCol.Size = UDim2.new(0, 72, 1, 0)
	UiUtil.makeLabel(boardLabelCol, "BoardTitle", "場札", UDim2.new(1,0,0,24), UDim2.new(0,0,0,6), nil, COLOR_TEXT)

	local boardRows = Instance.new("Frame")
	boardRows.Name = "BoardRows"
	boardRows.Parent = boardWrap
	boardRows.BackgroundTransparency = 1
	boardRows.Size = UDim2.new(1, -80, 1, 0)

	local ROW_H = math.floor((BOARD_H - ROW_GAP - 24) / 2)
	local boardRowTop = Instance.new("Frame")
	boardRowTop.Name="BoardRowTop"
	boardRowTop.Parent=boardRows
	boardRowTop.BackgroundTransparency = 1
	boardRowTop.Size=UDim2.new(1,0,0,ROW_H)
	boardRowTop.Position=UDim2.new(0,0,0,24)
	boardRowTop.ZIndex = 1
	local layoutTop = Instance.new("UIListLayout"); layoutTop.Parent = boardRowTop
	layoutTop.FillDirection=Enum.FillDirection.Horizontal
	layoutTop.Padding=UDim.new(0,14)

	local boardRowBottom = Instance.new("Frame")
	boardRowBottom.Name="BoardRowBottom"
	boardRowBottom.Parent=boardRows
	boardRowBottom.BackgroundTransparency = 1
	boardRowBottom.Size=UDim2.new(1,0,0,ROW_H)
	boardRowBottom.Position=UDim2.new(0,0,0,24 + ROW_H + ROW_GAP)
	boardRowBottom.ZIndex = 1
	local layoutBottom = Instance.new("UIListLayout"); layoutBottom.Parent = boardRowBottom
	layoutBottom.FillDirection=Enum.FillDirection.Horizontal
	layoutBottom.Padding=UDim.new(0,14)

	-- アクションボタン列
	local controls = Instance.new("Frame")
	controls.Name="Controls"
	controls.Parent=playArea
	controls.BackgroundTransparency = 1
	controls.Size=UDim2.new(1,0,0,CONTROLS_H)
	controls.Position=UDim2.new(0,0,0,BOARD_H + 8)

	local btnConfirm    = UiUtil.makeTextBtn(controls, "確定（この手で勝負）", UDim2.new(0.19,0,1,0), UDim2.new(0.00,0,0,0), BUTTON_BG)
	local btnRerollAll  = UiUtil.makeTextBtn(controls, "全体リロール",        UDim2.new(0.19,0,1,0), UDim2.new(0.21,0,0,0), BUTTON_BG)
	local btnRerollHand = UiUtil.makeTextBtn(controls, "手札だけリロール",    UDim2.new(0.19,0,1,0), UDim2.new(0.42,0,0,0), BUTTON_BG)
	local btnClearSel   = UiUtil.makeTextBtn(controls, "選択解除",            UDim2.new(0.19,0,1,0), UDim2.new(0.63,0,0,0), BUTTON_BG)

	local help = UiUtil.makeLabel(playArea, "ControlsHelp",
		T.helpText or "遊び方：手札と場札が同じ「月」で取り札をゲット！ 目標スコアを達成しよう",
		UDim2.new(1,0,0,HELP_H),
		UDim2.new(0,0,0,BOARD_H + 8 + CONTROLS_H + 2), nil, COLOR_HELP)
	help.TextXAlignment = Enum.TextXAlignment.Left

	-- 手札
	local handWrap = Instance.new("Frame")
	handWrap.Name = "HandWrap"
	handWrap.Parent = playArea
	handWrap.BackgroundTransparency = 1
	handWrap.Size = UDim2.new(1,0,0,HAND_H)
	handWrap.Position = UDim2.new(0,0,1,-HAND_H)

	local handLabelCol = Instance.new("Frame")
	handLabelCol.Name = "HandLabelCol"
	handLabelCol.Parent = handWrap
	handLabelCol.BackgroundTransparency = 1
	handLabelCol.Size = UDim2.new(0, 72, 1, 0)
	UiUtil.makeLabel(handLabelCol, "HandTitle", "手札", UDim2.new(1,0,0,24), UDim2.new(0,0,0,6), nil, COLOR_TEXT)

	local handArea = Instance.new("Frame")
	handArea.Name="HandArea"
	handArea.Parent=handWrap
	handArea.BackgroundTransparency = 1
	handArea.Size=UDim2.new(1,-80,1,0)
	handArea.Position=UDim2.new(0,80,0,0)
	handArea.ZIndex = 5
	local handLayout = Instance.new("UIListLayout"); handLayout.Parent = handArea
	handLayout.FillDirection=Enum.FillDirection.Horizontal
	handLayout.Padding=UDim.new(0,12)

	-- 右：取り札＋得点
	local rightPane = Instance.new("Frame")
	rightPane.Name="RightPane"
	rightPane.Parent=frame
	rightPane.BackgroundColor3 = COLOR_RIGHT_BG
	rightPane.BackgroundTransparency = T.rightPaneBgT or 0.08
	rightPane.Size=UDim2.new(0,RIGHT_W,1,-(PAD*2))
	rightPane.Position=UDim2.new(1,-(RIGHT_W+PAD),0,44)
	local rpCorner = Instance.new("UICorner"); rpCorner.CornerRadius = UDim.new(0,10); rpCorner.Parent = rightPane
	local rpStroke = Instance.new("UIStroke"); rpStroke.Thickness = 1; rpStroke.Color = COLOR_RIGHT_STROKE; rpStroke.Parent = rightPane

	UiUtil.makeLabel(rightPane, "TakenTitle", "取り札", UDim2.new(0,80,0,24), UDim2.new(0,PAD,0,6), nil, COLOR_TEXT)

	local takenPanel = Instance.new("Frame")
	takenPanel.Name = "TakenPanel"
	takenPanel.Parent = rightPane
	takenPanel.BackgroundColor3 = COLOR_PANEL_BG
	takenPanel.Position = UDim2.new(0,PAD,0,36)
	takenPanel.Size = UDim2.new(1,-PAD*2,0,260)
	local tpCorner = Instance.new("UICorner"); tpCorner.CornerRadius = UDim.new(0,8); tpCorner.Parent = takenPanel
	local tpStroke = Instance.new("UIStroke"); tpStroke.Thickness=1; tpStroke.Color = COLOR_PANEL_STROKE; tpStroke.Parent = takenPanel

	local takenBox = Instance.new("ScrollingFrame")
	takenBox.Name="TakenBox"
	takenBox.Parent=takenPanel
	takenBox.Size=UDim2.new(1,-12,1,-12)
	takenBox.Position=UDim2.new(0,6,0,6)
	takenBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
	takenBox.CanvasSize = UDim2.new(0,0,0,0)
	takenBox.ScrollBarThickness = 8
	takenBox.BackgroundTransparency = 1

	UiUtil.makeLabel(rightPane, "ScoreTitle", "得点", UDim2.new(0,80,0,24), UDim2.new(0,PAD,0,36+260+PAD-24), nil, COLOR_TEXT)

	local scorePanel = Instance.new("Frame")
	scorePanel.Name = "ScorePanel"
	scorePanel.Parent = rightPane
	scorePanel.BackgroundColor3 = COLOR_PANEL_BG
	scorePanel.Position = UDim2.new(0,PAD,0,36+260+PAD)
	scorePanel.Size = UDim2.new(1,-PAD*2,0,120)
	local spCorner = Instance.new("UICorner"); spCorner.CornerRadius = UDim.new(0,8); spCorner.Parent = scorePanel
	local spStroke = Instance.new("UIStroke"); spStroke.Thickness=1; spStroke.Color = COLOR_PANEL_STROKE; spStroke.Parent = scorePanel

	local scoreBox = UiUtil.makeLabel(scorePanel, "ScoreBox", "得点：0\n役：--", UDim2.new(1,-12,1,-12), UDim2.new(0,6,0,6), nil, COLOR_TEXT)
	scoreBox.TextYAlignment = Enum.TextYAlignment.Top

	return {
		gui = g,
		root = frame,
		info = info,
		help = help,
		handArea = handArea,
		boardRowTop = boardRowTop,
		boardRowBottom = boardRowBottom,
		takenBox = takenBox,
		scoreBox = scoreBox,
		buttons = {
			confirm = btnConfirm,
			rerollAll = btnRerollAll,
			rerollHand = btnRerollHand,
			clearSel = btnClearSel,
		},
		metrics = {
			ROW_H = ROW_H,
		},
		theme = { T = T, S = S, C = C }, -- 必要なら利用
	}
end

return M
