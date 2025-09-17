-- StarterPlayerScripts/UI/screens/RunScreenUI.lua
-- UIビルダーは親付けしない契約（親付けは ScreenRouter の責務）
-- v0.9.7-P1-3: Logger導入／言語コードを "ja"/"en" に統一（入力 "jp" は "ja" へ正規化）
-- v0.9.6-P0-11 以降：親付け除去／その他の挙動は従来どおり

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")

-- Logger
local Logger = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("RunScreenUI")

local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

local lib    = script.Parent.Parent:WaitForChild("lib")
local UiUtil = require(lib:WaitForChild("UiUtil"))

local M = {}

--=== lang helpers =======================================================
local function normLang(v: string?): string?
	local x = tostring(v or ""):lower()
	if x == "ja" or x == "en" then return x end
	if x == "jp" then
		LOG.warn("[Locale] received legacy 'jp'; normalize to 'ja'")
		return "ja"
	end
	return nil
end

local function pickInitialLang(): string
	local g = (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or nil
	local n = normLang(g)
	if n then return n end
	local p = (type(Locale.pick)=="function" and Locale.pick()) or nil
	return normLang(p) or "en"
end
--=======================================================================

--=== helpers ============================================================
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
		title.ZIndex = 3 -- 木目より確実に前面へ
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

-- 言語：Global → OS 推定（"jp" は "ja" へ正規化）
local _lang = pickInitialLang()
LOG.debug("init _lang=%s", tostring(_lang))

-- ラベル適用
local function applyTexts(tRefs)
	if not tRefs then return end
	local t = function(key) return Locale.t(_lang, key) end

	-- 右カラム：取り札
	if tRefs.takenPanel and tRefs.takenPanel:FindFirstChild("TakenPanelTitle") then
		tRefs.takenPanel.TakenPanelTitle.Text = t("RUN_TAKEN_TITLE")
		tRefs.takenPanel.TakenPanelTitle.ZIndex = 3
	end

	-- 左カラム：ボタン
	if tRefs.buttons then
		if tRefs.buttons.confirm    then tRefs.buttons.confirm.Text    = t("RUN_BTN_CONFIRM") end
		if tRefs.buttons.rerollAll  then tRefs.buttons.rerollAll.Text  = t("RUN_BTN_REROLL_ALL") end
		if tRefs.buttons.rerollHand then tRefs.buttons.rerollHand.Text = t("RUN_BTN_REROLL_HAND") end
		if tRefs.buttons.yaku       then
			local lbl = Locale.t(_lang, "RUN_BTN_YAKU")
			if not lbl or lbl == "" or lbl == "RUN_BTN_YAKU" then
				lbl = (_lang == "en") and "Yaku" or "役一覧"
			end
			tRefs.buttons.yaku.Text = lbl
		end
	end

	-- ヘルプ
	if tRefs.help then
		local T = Theme or {}
		local helpDefault = (T and T.helpText) and T.helpText or t("RUN_HELP_LINE")
		tRefs.help.Text = helpDefault
	end

	-- 情報パネル
	if tRefs.info then
		tRefs.info.Text = t("RUN_INFO_PLACEHOLDER")
	end

	-- スコア：辞書の初期値
	if tRefs.scoreBox then
		tRefs.scoreBox.Text = t("RUN_SCOREBOX_INIT")
	end
end

--[[
UIビルダーは親付けしない契約に統一：
- 第1引数 parentGui は互換のため受け取るが、**親付けには使用しない**（無視）。
- ScreenGui は生成するが、**Parent を設定しない**。親付けは ScreenRouter が行う。
]]
function M.build(_parentGuiIgnored: Instance?, opts)
	local want = opts and opts.lang or nil
	local n = normLang(want)
	if n then _lang = n end
	LOG.debug("build lang=%s (opts=%s)", tostring(_lang), tostring(want))

	--=== Theme ===========================================================
	local T = Theme or {}
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

	local ROOM_BG_IMAGE  = IMAGES.ROOM_BG  or "rbxassetid://134603580471930"
	local FIELD_BG_IMAGE = IMAGES.FIELD_BG or "rbxassetid://138521222203366"
	local TAKEN_BG_IMAGE = IMAGES.TAKEN_BG or "rbxassetid://93059114972102"

	local COLOR_TEXT         = (T.COLORS and T.COLORS.TextDefault)     or Color3.fromRGB(20,20,20)
	local COLOR_RIGHT_BG     = (T.COLORS and T.COLORS.RightPaneBg)     or Color3.fromRGB(245,248,255)
	local COLOR_RIGHT_STROKE = (T.COLORS and T.COLORS.RightPaneStroke) or Color3.fromRGB(210,220,230)
	local COLOR_PANEL_BG     = (T.COLORS and T.COLORS.PanelBg)         or Color3.fromRGB(255,255,255)
	local COLOR_PANEL_STROKE = (T.COLORS and T.COLORS.PanelStroke)     or Color3.fromRGB(220,225,235)

	--=== ScreenGui（※親付けしない） ======================================
	local g = Instance.new("ScreenGui")
	g.Name = "RunScreen"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 10
	g.Enabled = true
	-- ★ ここで Parent を設定しない（Router が playerGui に付ける）

	-- 背景
	local roomBG = Instance.new("ImageLabel")
	roomBG.Name = "RoomBG"
	roomBG.Parent = g
	roomBG.Image = ROOM_BG_IMAGE
	roomBG.BackgroundTransparency = 1
	roomBG.Size = UDim2.fromScale(1,1)
	roomBG.ScaleType = Enum.ScaleType.Crop
	roomBG.ZIndex = 0
	roomBG.ImageTransparency = TRANSP.roomBg or 0

	-- Root
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

	-- 3カラム
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
	rightPane.BackgroundTransparency = T.rightPaneBgT or 0
	rightPane.Size = UDim2.fromScale(RIGHT_W, 1 - PAD*2)
	rightPane.Position = UDim2.fromScale(1 - RIGHT_W - PAD, PAD)
	rightPane.ZIndex = 1
	addCornerStroke(rightPane, nil, COLOR_RIGHT_STROKE, 1)

	-- Left：情報パネル
	makeList(left, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

	local infoPanel = makePanel(left, "InfoPanel", Vector2.new(1, 0.14), 1, COLOR_PANEL_BG, COLOR_PANEL_STROKE)
	local info = UiUtil.makeLabel(infoPanel, "Info", "--", UDim2.new(1,-12,1,-12), UDim2.new(0,6,0,6), Vector2.new(0,0), COLOR_TEXT)
	info.TextWrapped = true
	info.TextScaled = true
	info.TextXAlignment = Enum.TextXAlignment.Left

	-- 目標（見出しなし）
	local goalPanel = makePanel(left, "GoalPanel", Vector2.new(1, 0.10), 2, COLOR_PANEL_BG, COLOR_PANEL_STROKE, nil, nil)
	local goalText = UiUtil.makeLabel(goalPanel, "GoalValue", "—", UDim2.new(1,-12,1,-12), UDim2.new(0,6,0,6), nil, COLOR_TEXT)
	goalText.TextScaled = true
	goalText.TextXAlignment = Enum.TextXAlignment.Left

	-- スコア＋役一覧
	local scorePanel = makePanel(left, "ScorePanel", Vector2.new(1, 0.26), 3, COLOR_PANEL_BG, COLOR_PANEL_STROKE, nil, nil)
	local scoreStack = Instance.new("Frame"); scoreStack.Name="ScoreStack"; scoreStack.Parent=scorePanel
	scoreStack.Size = UDim2.new(1,-12,1,-12); scoreStack.Position = UDim2.new(0,6,0,6); scoreStack.BackgroundTransparency=1
	makeList(scoreStack, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)

	local scoreBox = UiUtil.makeLabel(scoreStack, "ScoreBox", "--", UDim2.new(1,0,0,96), UDim2.new(0,0,0,0), nil, COLOR_TEXT)
	scoreBox.TextYAlignment = Enum.TextYAlignment.Top
	scoreBox.TextWrapped = true
	scoreBox.TextScaled = true

	local btnYakuColor = (Theme.COLORS and Theme.COLORS.InfoBtnBg) or Color3.fromRGB(120, 180, 255)
	local btnYaku = makeSideBtn(scoreStack, "OpenYaku", "", btnYakuColor)

	-- コントロールボタン
	local controlsPanel = Instance.new("Frame")
	controlsPanel.Name = "ControlsPanel"
	controlsPanel.Parent = left
	controlsPanel.Size = UDim2.fromScale(1, 0)
	controlsPanel.AutomaticSize = Enum.AutomaticSize.Y
	controlsPanel.BackgroundTransparency = 1
	controlsPanel.LayoutOrder = 4
	controlsPanel.ZIndex = 1
	makeList(controlsPanel, Enum.FillDirection.Vertical, 8)

	local btnConfirm    = makeSideBtn(controlsPanel, "Confirm",    "", (T.COLORS and T.COLORS.PrimaryBtnBg) or Color3.fromRGB(255,153,0))
	local btnRerollAll  = makeSideBtn(controlsPanel, "RerollAll",  "", (T.COLORS and T.COLORS.WarnBtnBg)    or Color3.fromRGB(220,70,70))
	local btnRerollHand = makeSideBtn(controlsPanel, "RerollHand", "", (T.COLORS and T.COLORS.WarnBtnBg)    or Color3.fromRGB(220,70,70))

	-- Center
	makeList(center, Enum.FillDirection.Vertical, 0.02, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)
	local boardArea = Instance.new("Frame"); boardArea.Name="BoardArea"; boardArea.Parent=center; boardArea.BackgroundTransparency=1
	boardArea.Size=UDim2.fromScale(1, BOARD_H); boardArea.LayoutOrder=1; boardArea.ZIndex=1
	do
		local tatami = Instance.new("ImageLabel"); tatami.Name="BoardBG"; tatami.Parent=boardArea
		tatami.Image=FIELD_BG_IMAGE; tatami.BackgroundTransparency=1; tatami.Size=UDim2.fromScale(1,1)
		tatami.ScaleType=Enum.ScaleType.Crop; tatami.ZIndex=1; tatami.ImageTransparency=TRANSP.boardBg or 0
		local tatamiCorner = Instance.new("UICorner"); tatamiCorner.CornerRadius=UDim.new(0, Theme.PANEL_RADIUS or 10); tatamiCorner.Parent=tatami

		local boardWrap = Instance.new("Frame"); boardWrap.Name="BoardWrap"; boardWrap.Parent=boardArea
		boardWrap.BackgroundTransparency=1; boardWrap.Size=UDim2.fromScale(1,1); boardWrap.ZIndex=2
		makeList(boardWrap, Enum.FillDirection.Vertical, ROW_GAP)

		local top = Instance.new("Frame"); top.Name="BoardRowTop"; top.Parent=boardWrap; top.BackgroundTransparency=1
		top.Size=UDim2.fromScale(1,(1-ROW_GAP)*0.5); top.ZIndex=2; makeList(top, Enum.FillDirection.Horizontal, 0.02)

		local bottom = Instance.new("Frame"); bottom.Name="BoardRowBottom"; bottom.Parent=boardWrap; bottom.BackgroundTransparency=1
		bottom.Size=UDim2.fromScale(1,(1-ROW_GAP)*0.5); bottom.ZIndex=2; makeList(bottom, Enum.FillDirection.Horizontal, 0.02)

		M._boardRowTop, M._boardRowBottom = top, bottom
	end

	local notice = Instance.new("Frame"); notice.Name="NoticeBar"; notice.Parent=center; notice.LayoutOrder=4
	local noticeH = math.max(0.05, (TUTORIAL_H or 0.08) * 0.9)
	notice.Size=UDim2.fromScale(1, noticeH); notice.BackgroundColor3=Color3.fromRGB(240,246,255); notice.ZIndex=1; addCornerStroke(notice,nil,nil,1)
	local noticeText = UiUtil.makeLabel(notice, "NoticeText", "", UDim2.new(1,-16,1,-12), UDim2.new(0,8,0,6), nil, COLOR_TEXT)
	noticeText.TextScaled=true; noticeText.TextWrapped=true; noticeText.TextXAlignment=Enum.TextXAlignment.Left

	local tutorial = Instance.new("Frame"); tutorial.Name="TutorialBar"; tutorial.Parent=center
	tutorial.Size=UDim2.fromScale(1, TUTORIAL_H); tutorial.BackgroundColor3=Color3.fromRGB(255,153,0)
	tutorial.LayoutOrder=3; tutorial.ZIndex=1; addCornerStroke(tutorial,nil,nil,1)
	local help = UiUtil.makeLabel(tutorial, "Help", "", UDim2.new(1,-16,1,-12), UDim2.new(0,8,0,6), nil, COLOR_TEXT)
	help.TextScaled=true; help.TextWrapped=true; help.TextXAlignment=Enum.TextXAlignment.Center

	local handArea = Instance.new("Frame"); handArea.Name="HandArea"; handArea.Parent=center
	handArea.BackgroundTransparency=1; handArea.Size=UDim2.fromScale(1, HAND_H); handArea.LayoutOrder=2; handArea.ZIndex=1

	-- Right：取り札
	makeList(rightPane, Enum.FillDirection.Vertical, 0.02, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)
	local takenPanel = makePanel(rightPane, "TakenPanel", Vector2.new(1,1), 1, COLOR_PANEL_BG, COLOR_PANEL_STROKE, Locale.t(_lang, "RUN_TAKEN_TITLE"), COLOR_TEXT)
	local takenBG = Instance.new("ImageLabel"); takenBG.Name="TakenBG"; takenBG.Parent=takenPanel
	takenBG.Image=TAKEN_BG_IMAGE; takenBG.BackgroundTransparency=1; takenBG.ScaleType=Enum.ScaleType.Crop; takenBG.Size=UDim2.fromScale(1,1)
	takenBG.ZIndex=1; takenBG.ImageTransparency=TRANSP.takenBg or 0
	local takenCorner = Instance.new("UICorner"); takenCorner.CornerRadius=UDim.new(0, Theme.PANEL_RADIUS or 10); takenCorner.Parent=takenBG
	local takenBox = Instance.new("ScrollingFrame"); takenBox.Name="TakenBox"; takenBox.Parent=takenPanel
	takenBox.Size=UDim2.new(1,-12,1,-42); takenBox.Position=UDim2.new(0,6,0,36); takenBox.AutomaticCanvasSize=Enum.AutomaticSize.Y
	takenBox.CanvasSize=UDim2.new(0,0,0,0); takenBox.ScrollBarThickness=8; takenBox.BackgroundTransparency=1; takenBox.ZIndex=2

	-- 参照束
	local refs = {
		gui = g, root = root, playArea = playArea,
		info = info, goalText = goalText, scoreBox = scoreBox,
		help = help, notice = noticeText, handArea = handArea,
		boardRowTop = M._boardRowTop, boardRowBottom = M._boardRowBottom,
		takenBox = takenBox, takenPanel = takenPanel,
		scorePanel = scorePanel, goalPanel = goalPanel,
		buttons = { yaku = btnYaku, confirm = btnConfirm, rerollAll = btnRerollAll, rerollHand = btnRerollHand },
	}

	-- 初期テキスト
	local function setLang(newLang: string)
		local n2 = normLang(newLang)
		if not n2 then return end
		_lang = n2
		applyTexts(refs)
	end
	applyTexts(refs)

	-- 言語変更イベント購読（Home の切替 → setGlobal で即反映）
	local langConn = nil
	if typeof(Locale.changed) == "RBXScriptSignal" then
		langConn = Locale.changed:Connect(function(newLang)
			local nn = normLang(newLang)
			if nn then setLang(nn) end
		end)
	end

	-- 任意：スコア文面のフォーマッタ（Run側で利用）
	refs.formatScore = function(score, mons, pts, rolesText)
		if _lang == "ja" then
			return string.format("得点：%d\n文%d×%d点\n%s", score or 0, mons or 0, pts or 0, rolesText or "役：--")
		else
			return string.format("Score: %d\n%dMon × %dPts\n%s", score or 0, mons or 0, pts or 0, rolesText or "Roles: --")
		end
	end

	-- 後片付け用
	refs.cleanup = function()
		if langConn then langConn:Disconnect() end
	end
	refs.setLang = setLang
	refs.getLang = function() return _lang end

	LOG.debug("build done | lang=%s", tostring(_lang))
	return refs
end

return M
