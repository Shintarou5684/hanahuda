-- StarterPlayerScripts/UI/screens/RunScreenUI.lua
-- 画面の土台UIを構築して参照を束ねて返す（背景テクスチャ＋透過度対応）
-- 和室（ROOM_BG）＝最背面、毛氈（FIELD_BG）＝盤面、木目（TAKEN_BG）＝取り札

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

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

-- 内部状態（言語）: Global -> OS（pick）の順で決定。以降、OS に自動で戻さない
local _lang = (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or Locale.pick()
print("[LANG_FLOW] RunScreenUI.init _lang(from Global or OS) =", _lang)

-- UIテキストの反映（ランタイム切替対応）
local function applyTexts(tRefs)
	if not tRefs then return end
	local t = function(key) return Locale.t(_lang, key) end

	-- 左カラム：タイトルなど
	if tRefs.goalPanel and tRefs.goalPanel:FindFirstChild("GoalPanelTitle") then
		tRefs.goalPanel.GoalPanelTitle.Text = t("RUN_GOAL_TITLE")
	end
	if tRefs.scorePanel and tRefs.scorePanel:FindFirstChild("ScorePanelTitle") then
		tRefs.scorePanel.ScorePanelTitle.Text = t("RUN_SCORE_TITLE")
	end
	-- 右カラム：取り札
	if tRefs.takenPanel and tRefs.takenPanel:FindFirstChild("TakenPanelTitle") then
		tRefs.takenPanel.TakenPanelTitle.Text = t("RUN_TAKEN_TITLE")
	end
	-- ボタン
	if tRefs.buttons then
		if tRefs.buttons.confirm    then tRefs.buttons.confirm.Text    = t("RUN_BTN_CONFIRM") end
		if tRefs.buttons.rerollAll  then tRefs.buttons.rerollAll.Text  = t("RUN_BTN_REROLL_ALL") end
		if tRefs.buttons.rerollHand then tRefs.buttons.rerollHand.Text = t("RUN_BTN_REROLL_HAND") end

		-- ★ 追加：役一覧ボタン（ローカライズが無い場合はフォールバック）
		if tRefs.buttons.yaku then
			local label = t("RUN_BTN_YAKU")
			if not label or label == "" or label == "RUN_BTN_YAKU" then
				label = (_lang == "en") and "Yaku" or "役一覧"
			end
			tRefs.buttons.yaku.Text = label
		end
	end
	-- ヘルプ・バー
	if tRefs.help then
		-- Theme.helpText があれば優先。無ければ Locale の定義
		local T = Theme or {}
		local helpDefault = (T and T.helpText) and T.helpText or t("RUN_HELP_LINE")
		tRefs.help.Text = helpDefault
	end
	-- 情報パネルの初期プレースホルダ
	if tRefs.info then
		tRefs.info.Text = t("RUN_INFO_PLACEHOLDER")
	end
	-- スコアボックスの初期表示
	if tRefs.scoreBox then
		tRefs.scoreBox.Text = t("RUN_SCOREBOX_INIT")
	end
end

function M.build(parentGui: Instance, opts)
	-- opts.lang があれば最優先で採用（OSに戻さない）
	if opts and (opts.lang == "jp" or opts.lang == "en") then
		print("[LANG_FLOW] RunScreenUI.build opts.lang override=", opts.lang, " (before=", _lang,")")
		_lang = opts.lang
	end
	print("[LANG_FLOW] RunScreenUI.build final _lang=", _lang)

	--=== Theme 参照 ======================================================
	local T = Theme or {}
	local S = T.SIZES  or {}
	local C = T.COLORS or {}
	local R = T.RATIOS or {}
	local IMAGES = T.IMAGES or {}
	local TRANSP = T.TRANSPARENCY or {}

	local ASPECT       = T.ASPECT or (16/9)
	local PAD          = (R.CENTER_PAD ~= nil and R.CENTER_PAD) or (R.PAD or 0.02)
	local LEFT_W       = R.LEFT_W      or 0.18
	local RIGHT_W      = R.RIGHT_W     or 0.22
	local BOARD_H      = R.BOARD_H     or 0.50
	local TUTORIAL_H   = R.TUTORIAL_H  or 0.08
	local HAND_H       = R.HAND_H      or 0.28
	local ROW_GAP      = 0.035
	local COL_GAP      = R.COL_GAP or 0.015

	-- 画像ID（Theme優先／フォールバックあり）
	local ROOM_BG_IMAGE  = IMAGES.ROOM_BG  or "rbxassetid://134603580471930"
	local FIELD_BG_IMAGE = IMAGES.FIELD_BG or "rbxassetid://138521222203366" -- 既定：畳
	local TAKEN_BG_IMAGE = IMAGES.TAKEN_BG or "rbxassetid://93059114972102"

	-- 色
	local COLOR_TEXT         = C.TextDefault     or Color3.fromRGB(20,20,20)
	local COLOR_RIGHT_BG     = C.RightPaneBg     or Color3.fromRGB(245,248,255)
	local COLOR_RIGHT_STROKE = C.RightPaneStroke or Color3.fromRGB(210,220,230)
	local COLOR_PANEL_BG     = C.PanelBg         or Color3.fromRGB(255,255,255)
	local COLOR_PANEL_STROKE = C.PanelStroke     or Color3.fromRGB(220,225,235)

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

	--=== 最背面：和室背景 ================================================
	local roomBG = Instance.new("ImageLabel")
	roomBG.Name = "RoomBG"
	roomBG.Parent = g
	roomBG.Image = ROOM_BG_IMAGE
	roomBG.BackgroundTransparency = 1
	roomBG.Size = UDim2.fromScale(1,1)
	roomBG.Position = UDim2.fromScale(0,0)
	roomBG.ScaleType = Enum.ScaleType.Crop
	roomBG.ZIndex = 0
	roomBG.ImageTransparency = TRANSP.roomBg or 0

	--=== Root と PlayArea ===============================================
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Parent = g
	root.Size = UDim2.fromScale(1,1)
	root.BackgroundTransparency = 1
	root.Visible = false
	root.ZIndex = 1

	local playArea = Instance.new("Frame")
	playArea.Name = "PlayArea"
	playArea.Parent = root
	playArea.AnchorPoint = Vector2.new(0.5,0.5)
	playArea.Position = UDim2.fromScale(0.5,0.5)
	playArea.Size = UDim2.fromScale(1,1)
	playArea.BackgroundTransparency = 1
	playArea.ZIndex = 1
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
	left.ZIndex = 1

	local center = Instance.new("Frame")
	center.Name = "CenterMain"
	center.Parent = playArea
	center.BackgroundTransparency = 1
	center.Size     = UDim2.fromScale(1 - LEFT_W - RIGHT_W - PAD*2 - COL_GAP*2, 1 - PAD*2)
	center.Position = UDim2.fromScale(PAD + LEFT_W + COL_GAP, PAD)
	center.ZIndex = 1

	local rightPane = Instance.new("Frame")
	rightPane.Name = "RightPane"
	rightPane.Parent = playArea
	rightPane.BackgroundColor3 = COLOR_RIGHT_BG
	rightPane.BackgroundTransparency = T.rightPaneBgT or 0.08
	rightPane.Size = UDim2.fromScale(RIGHT_W, 1 - PAD*2)
	rightPane.Position = UDim2.fromScale(1 - RIGHT_W - PAD, PAD)
	rightPane.ZIndex = 1
	addCornerStroke(rightPane, nil, COLOR_RIGHT_STROKE, 1)

	--=== Left：情報パネル群 =============================================
	makeList(left, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

	local infoPanel = makePanel(left, "InfoPanel", Vector2.new(1, 0.14), 1, COLOR_PANEL_BG, COLOR_PANEL_STROKE)
	infoPanel.ZIndex = 1
	local info = UiUtil.makeLabel(infoPanel, "Info",
		"--", -- 文字列は applyTexts() で差し替え
		UDim2.new(1,-12,1,-12), UDim2.new(0,6,0,6), Vector2.new(0,0), COLOR_TEXT)
	info.TextWrapped = true
	info.TextScaled = true
	info.TextXAlignment = Enum.TextXAlignment.Left

	-- タイトルは初期ロケールで生成（後で applyTexts が上書き）
	local goalPanel = makePanel(left, "GoalPanel", Vector2.new(1, 0.10), 2, COLOR_PANEL_BG, COLOR_PANEL_STROKE, Locale.t(_lang, "RUN_GOAL_TITLE"), COLOR_TEXT)
	goalPanel.ZIndex = 1
	local goalText = UiUtil.makeLabel(goalPanel, "GoalValue", "—", UDim2.new(1,-12,1,-36), UDim2.new(0,6,0,30), nil, COLOR_TEXT)
	goalText.TextScaled = true
	goalText.TextXAlignment = Enum.TextXAlignment.Left

	local scorePanel = makePanel(left, "ScorePanel", Vector2.new(1, 0.22), 3, COLOR_PANEL_BG, COLOR_PANEL_STROKE, Locale.t(_lang, "RUN_SCORE_TITLE"), COLOR_TEXT)
	scorePanel.ZIndex = 1
	local scoreBox = UiUtil.makeLabel(scorePanel, "ScoreBox", "--",
		UDim2.new(1,-12,1,-42), UDim2.new(0,6,0,36), nil, COLOR_TEXT)
	scoreBox.TextYAlignment = Enum.TextYAlignment.Top

	local controlsPanel = Instance.new("Frame")
	controlsPanel.Name = "ControlsPanel"
	controlsPanel.Parent = left
	controlsPanel.Size = UDim2.fromScale(1, 0)
	controlsPanel.AutomaticSize = Enum.AutomaticSize.Y
	controlsPanel.BackgroundTransparency = 1
	controlsPanel.LayoutOrder = 4
	controlsPanel.ZIndex = 1
	makeList(controlsPanel, Enum.FillDirection.Vertical, 8)

	-- 既存
	local btnConfirm    = makeSideBtn(controlsPanel, "Confirm",    "", C.PrimaryBtnBg or Color3.fromRGB(255,153,0))
	local btnRerollAll  = makeSideBtn(controlsPanel, "RerollAll",  "", C.WarnBtnBg or Color3.fromRGB(220,70,70))
	local btnRerollHand = makeSideBtn(controlsPanel, "RerollHand", "", C.WarnBtnBg or Color3.fromRGB(220,70,70))

	-- ★ 追加：役一覧ボタン（Confirm の“上”に出す）
	local btnYaku = makeSideBtn(
		controlsPanel,
		"OpenYaku",
		"",  -- 文字列は applyTexts() で入れる
		(C.SecondaryBtnBg or C.PrimaryBtnBg or Color3.fromRGB(80,120,200))
	)

	-- ★ 並び順（UIListLayout 用）：Yaku=9, Confirm=10, RerollAll=11, RerollHand=12
	btnYaku.LayoutOrder     = 9
	btnConfirm.LayoutOrder  = 10
	btnRerollAll.LayoutOrder  = 11
	btnRerollHand.LayoutOrder = 12

	--=== Center：盤面 / お知らせ / チュートリアル / 手札 ================
	makeList(center, Enum.FillDirection.Vertical, 0.02, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

	local boardArea = Instance.new("Frame")
	boardArea.Name = "BoardArea"
	boardArea.Parent = center
	boardArea.BackgroundTransparency = 1
	boardArea.Size = UDim2.fromScale(1, BOARD_H)
	boardArea.LayoutOrder = 1
	boardArea.ZIndex = 1
	do
		local tatami = Instance.new("ImageLabel")
		tatami.Name = "BoardBG"
		tatami.Parent = boardArea
		tatami.Image = FIELD_BG_IMAGE
		tatami.BackgroundTransparency = 1
		tatami.Size = UDim2.fromScale(1,1)
		tatami.ScaleType = Enum.ScaleType.Crop
		tatami.ZIndex = 1
		tatami.ImageTransparency = TRANSP.boardBg or 0
		local tatamiCorner = Instance.new("UICorner")
		tatamiCorner.CornerRadius = UDim.new(0, Theme.PANEL_RADIUS or 10)
		tatamiCorner.Parent = tatami

		local boardWrap = Instance.new("Frame")
		boardWrap.Name = "BoardWrap"
		boardWrap.Parent = boardArea
		boardWrap.BackgroundTransparency = 1
		boardWrap.Size = UDim2.fromScale(1,1)
		boardWrap.ZIndex = 2

		makeList(boardWrap, Enum.FillDirection.Vertical, ROW_GAP)

		local boardRowTop = Instance.new("Frame")
		boardRowTop.Name = "BoardRowTop"
		boardRowTop.Parent = boardWrap
		boardRowTop.BackgroundTransparency = 1
		boardRowTop.Size = UDim2.fromScale(1, (1 - ROW_GAP) * 0.5)
		boardRowTop.ZIndex = 2
		makeList(boardRowTop, Enum.FillDirection.Horizontal, 0.02)

		local boardRowBottom = Instance.new("Frame")
		boardRowBottom.Name = "BoardRowBottom"
		boardRowBottom.Parent = boardWrap
		boardRowBottom.BackgroundTransparency = 1
		boardRowBottom.Size = UDim2.fromScale(1, (1 - ROW_GAP) * 0.5)
		boardRowBottom.ZIndex = 2
		makeList(boardRowBottom, Enum.FillDirection.Horizontal, 0.02)

		M._boardRowTop = boardRowTop
		M._boardRowBottom = boardRowBottom
	end

	local notice = Instance.new("Frame")
	notice.Name = "NoticeBar"
	notice.Parent = center
	notice.LayoutOrder = 4
	local noticeH = math.max(0.05, (TUTORIAL_H or 0.08) * 0.9)
	notice.Size = UDim2.fromScale(1, noticeH)
	notice.BackgroundColor3 = Color3.fromRGB(240,246,255)
	notice.ZIndex = 1
	addCornerStroke(notice, nil, nil, 1)
	local noticeText = UiUtil.makeLabel(notice, "NoticeText", "", UDim2.new(1,-16,1,-12), UDim2.new(0,8,0,6), nil, COLOR_TEXT)
	noticeText.TextScaled = true
	noticeText.TextWrapped = true
	noticeText.TextXAlignment = Enum.TextXAlignment.Left

	local tutorial = Instance.new("Frame")
	tutorial.Name = "TutorialBar"
	tutorial.Parent = center
	tutorial.Size = UDim2.fromScale(1, TUTORIAL_H)
	tutorial.BackgroundColor3 = Color3.fromRGB(255,153,0)
	tutorial.LayoutOrder = 3
	tutorial.ZIndex = 1
	addCornerStroke(tutorial, nil, nil, 1)
	local help = UiUtil.makeLabel(tutorial, "Help",
		"", -- 文字列は applyTexts() で設定
		UDim2.new(1,-16,1,-12), UDim2.new(0,8,0,6), nil, COLOR_TEXT)
	help.TextScaled = true
	help.TextWrapped = true
	help.TextXAlignment = Enum.TextXAlignment.Center

	local handArea = Instance.new("Frame")
	handArea.Name = "HandArea"
	handArea.Parent = center
	handArea.BackgroundTransparency = 1
	handArea.Size = UDim2.fromScale(1, HAND_H)
	handArea.LayoutOrder = 2
	handArea.ZIndex = 1

	--=== Right：取り札 ================================================
	makeList(rightPane, Enum.FillDirection.Vertical, 0.02, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

	local takenPanel = makePanel(rightPane, "TakenPanel", Vector2.new(1,1), 1, COLOR_PANEL_BG, COLOR_PANEL_STROKE, Locale.t(_lang, "RUN_TAKEN_TITLE"), COLOR_TEXT)
	takenPanel.ZIndex = 1

	local takenBG = Instance.new("ImageLabel")
	takenBG.Name = "TakenBG"
	takenBG.Parent = takenPanel
	takenBG.Image = TAKEN_BG_IMAGE
	takenBG.BackgroundTransparency = 1
	takenBG.ScaleType = Enum.ScaleType.Crop
	takenBG.Size = UDim2.fromScale(1,1)
	takenBG.ZIndex = 1
	takenBG.ImageTransparency = TRANSP.takenBg or 0
	local takenCorner = Instance.new("UICorner")
	takenCorner.CornerRadius = UDim.new(0, Theme.PANEL_RADIUS or 10)
	takenCorner.Parent = takenBG

	local takenBox = Instance.new("ScrollingFrame")
	takenBox.Name = "TakenBox"
	takenBox.Parent = takenPanel
	takenBox.Size = UDim2.new(1,-12,1,-42)
	takenBox.Position = UDim2.new(0,6,0,36)
	takenBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
	takenBox.CanvasSize = UDim2.new(0,0,0,0)
	takenBox.ScrollBarThickness = 8
	takenBox.BackgroundTransparency = 1
	takenBox.ZIndex = 2

	-- 返却参照束
	local refs = {
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
		goalPanel = goalPanel,
		scorePanel = scorePanel,
		takenPanel = takenPanel,
		buttons = {
			yaku = btnYaku,        -- ★ 追加
			confirm = btnConfirm,
			rerollAll = btnRerollAll,
			rerollHand = btnRerollHand,
		},
		theme = { T = T, S = S, C = C, R = R },
	}

	-- 初期テキスト適用
	applyTexts(refs)

	-- ランタイム言語切替API
	local function setLang(newLang: string)
		print("[LANG_FLOW] RunScreenUI.setLang called with", newLang, " (prev=", _lang,")")
		if newLang ~= "jp" and newLang ~= "en" then return end
		_lang = newLang
		applyTexts(refs)
	end

	refs.setLang = setLang
	refs.getLang = function() return _lang end

	-- ★ build の最終行ログ（念のため残す）
	print(("[LANG_FLOW] RunScreenUI.build done | lang=%s | has setLang=%s")
		:format(tostring(_lang), tostring(type(setLang)=="function")))

	return refs
end

return M
