-- StarterPlayerScripts/UI/screens/RunScreenUI.lua
-- UIビルダーは親付けしない契約（親付けは ScreenRouter の責務）
-- v0.9.7-P1-7:
--   - リロールボタン文言を固定化
--       ja: 「場札入替」 / 「手札入替」
--       en: "Refresh Board" / "Redraw Hand"
--     （Locale のキーに依存せず、setLang でも追従）
-- v0.9.7-P1-6: ★ リロール（場/手）ボタンの左に残回数バッジを追加
--              （refs.counters.rerollField / refs.counters.rerollHand）＋見た目調整APIを追加
-- v0.9.7-P1-5: 「あきらめる」ボタンを追加（refs.buttons.giveUp）
-- v0.9.7-P1-4: Theme完全デフォルト化（色・画像・透過のUI側フォールバック撤去）
-- v0.9.7-P1-3: Logger導入／言語コードを "ja"/"en" に統一（入力 "jp" は "ja" へ正規化）
-- v0.9.6-P0-11 以降：親付け除去／その他の挙動は従来どおり

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")

-- Logger
local Logger = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("RunScreenUI")

local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

local lib    = script.Parent.Parent.Parent:WaitForChild("lib")
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

-- ▼ 左に残回数バッジ＋右に少し細いボタンのセットを生成
local function makeCounteredButton(parent: Instance, name: string, initialText: string, btnBg: Color3)
	local holder = Instance.new("Frame")
	holder.Name = name .. "Holder"
	holder.Parent = parent
	holder.Size = UDim2.new(1, 0, 0, 44)
	holder.BackgroundTransparency = 1

	local _ = makeList(holder, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

	local badge = Instance.new("TextLabel")
	badge.Name = name .. "Count"
	badge.Parent = holder
	badge.Size = UDim2.new(0, 40, 1, 0)
	badge.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	badge.BackgroundTransparency = 0.25
	badge.BorderSizePixel = 0
	badge.Text = "0"
	badge.Font = Enum.Font.GothamBold
	badge.TextScaled = true
	badge.TextColor3 = Color3.new(1,1,1)
	local badgeCorner = Instance.new("UICorner"); badgeCorner.CornerRadius = UDim.new(0, 8); badgeCorner.Parent = badge

	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Parent = holder
	btn.Size = UDim2.new(1, -46, 1, 0) -- 左に40pxバッジ＋6pxパディング
	btn.AutoButtonColor = true
	btn.Text = initialText
	btn.TextScaled = true
	btn.BackgroundColor3 = btnBg
	btn.BorderSizePixel = 0
	local btnCorner = Instance.new("UICorner"); btnCorner.CornerRadius = UDim.new(0, 8); btnCorner.Parent = btn

	return badge, btn, holder
end
--=======================================================================

-- 言語：Global → OS 推定（"jp" は "ja" へ正規化）
local _lang = pickInitialLang()
LOG.debug("init _lang=%s", tostring(_lang))

-- ▼ 追加：リロールボタンの固定ラベル
local function rerollLabels(lang: string)
	lang = tostring(lang or "en"):lower()
	if lang == "ja" then
		return { all = "場札入替", hand = "手札入替" }
	else
		return { all = "Refresh Board", hand = "Redraw Hand" }
	end
end

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
		if tRefs.buttons.confirm then
			tRefs.buttons.confirm.Text = t("RUN_BTN_CONFIRM")
		end

		-- ★ 固定文言（Localeキーに依存しない）
		local rl = rerollLabels(_lang)
		if tRefs.buttons.rerollAll  then tRefs.buttons.rerollAll.Text  = rl.all  end
		if tRefs.buttons.rerollHand then tRefs.buttons.rerollHand.Text = rl.hand end

		if tRefs.buttons.yaku then
			local lbl = Locale.t(_lang, "RUN_BTN_YAKU")
			if not lbl or lbl == "" or lbl == "RUN_BTN_YAKU" then
				lbl = (_lang == "en") and "Yaku" or "役一覧"
			end
			tRefs.buttons.yaku.Text = lbl
		end
		-- あきらめる
		if tRefs.buttons.giveUp then
			local txt = Locale.t(_lang, "RUN_BTN_GIVEUP")
			if not txt or txt == "" or txt == "RUN_BTN_GIVEUP" then
				txt = (_lang == "en") and "Give Up" or "あきらめる"
			end
			tRefs.buttons.giveUp.Text = txt
		end
	end

	-- ヘルプ
	if tRefs.help then
		local Tm = Theme
		local helpDefault = (Tm and Tm.helpText) and Tm.helpText or t("RUN_HELP_LINE")
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
	local T       = Theme
	local C       = T.COLORS
	local R       = T.RATIOS
	local IMAGES  = T.IMAGES
	local TRANSP  = T.TRANSPARENCY

	local ASPECT     = T.ASPECT
	local PAD        = R.CENTER_PAD
	local LEFT_W     = R.LEFT_W
	local RIGHT_W    = R.RIGHT_W
	local BOARD_H    = R.BOARD_H
	local TUTORIAL_H = R.TUTORIAL_H
	local HAND_H     = R.HAND_H
	local ROW_GAP    = 0.035
	local COL_GAP    = R.COL_GAP

	local ROOM_BG_IMAGE  = IMAGES.ROOM_BG
	local FIELD_BG_IMAGE = IMAGES.FIELD_BG
	local TAKEN_BG_IMAGE = IMAGES.TAKEN_BG

	local COLOR_TEXT           = C.TextDefault
	local COLOR_RIGHT_BG       = C.RightPaneBg
	local COLOR_RIGHT_STROKE   = C.RightPaneStroke
	local COLOR_PANEL_BG       = C.PanelBg
	local COLOR_PANEL_STROKE   = C.PanelStroke
	local COLOR_NOTICE_BG      = C.NoticeBg   or C.PanelBg
	local COLOR_TUTORIAL_BG    = C.TutorialBg or C.PrimaryBtnBg
	local BTN_PRIMARY_BG       = C.PrimaryBtnBg
	local BTN_WARN_BG          = C.WarnBtnBg
	local BTN_YAKU_BG          = C.InfoBtnBg

	--=== ScreenGui（※親付けしない） ======================================
	local g = Instance.new("ScreenGui")
	g.Name = "RunScreen"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 10
	g.Enabled = true

	-- 背景
	local roomBG = Instance.new("ImageLabel")
	roomBG.Name = "RoomBG"
	roomBG.Parent = g
	roomBG.Image = ROOM_BG_IMAGE
	roomBG.BackgroundTransparency = 1
	roomBG.Size = UDim2.fromScale(1,1)
	roomBG.ScaleType = Enum.ScaleType.Crop
	roomBG.ZIndex = 0
	roomBG.ImageTransparency = TRANSP.roomBg

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
	rightPane.BackgroundTransparency = T.rightPaneBgT
	rightPane.Size = UDim2.fromScale(RIGHT_W, 1 - PAD*2)
	rightPane.Position = UDim2.fromScale(1 - RIGHT_W - PAD, PAD)
	rightPane.ZIndex = 1
	addCornerStroke(rightPane, nil, COLOR_RIGHT_STROKE, 1)

	-- Left：情報パネル
	makeList(left, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

	local infoPanel = makePanel(left, "InfoPanel", Vector2.new(1, 0.14), 1, COLOR_PANEL_BG, COLOR_PANEL_STROKE)
	local info = UiUtil.makeLabel(infoPanel, "Info", "--", UDim2.new(1,-12,1,-12), UDim2.new(0,6,0,6), nil, COLOR_TEXT)
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

	local btnYaku = makeSideBtn(scoreStack, "OpenYaku", "", BTN_YAKU_BG)

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

	local btnConfirm    = makeSideBtn(controlsPanel, "Confirm",    "", BTN_PRIMARY_BG)

	-- ★ リロール2種：左に残回数バッジ＋右に細いボタン
	local badgeField, btnRerollAll = makeCounteredButton(controlsPanel, "RerollAll",  "", BTN_WARN_BG)
	local badgeHand,  btnRerollHand = makeCounteredButton(controlsPanel, "RerollHand", "", BTN_WARN_BG)

	-- あきらめる
	local btnGiveUp     = makeSideBtn(controlsPanel, "GiveUp",     "", BTN_WARN_BG)

	-- Center
	makeList(center, Enum.FillDirection.Vertical, 0.02, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)
	local boardArea = Instance.new("Frame"); boardArea.Name="BoardArea"; boardArea.Parent=center; boardArea.BackgroundTransparency=1
	boardArea.Size=UDim2.fromScale(1, BOARD_H); boardArea.LayoutOrder=1; boardArea.ZIndex=1
	do
		local tatami = Instance.new("ImageLabel"); tatami.Name="BoardBG"; tatami.Parent=boardArea
		tatami.Image=FIELD_BG_IMAGE; tatami.BackgroundTransparency=1; tatami.Size=UDim2.fromScale(1,1)
		tatami.ScaleType=Enum.ScaleType.Crop; tatami.ZIndex=1; tatami.ImageTransparency=TRANSP.boardBg
		local tatamiCorner = Instance.new("UICorner"); tatamiCorner.CornerRadius=UDim.new(0, Theme.PANEL_RADIUS or 10); tatamiCorner.Parent=tatami

		local boardWrap = Instance.new("Frame"); boardWrap.Name="BoardWrap"; boardWrap.Parent=boardArea
		boardWrap.BackgroundTransparency=1; boardWrap.Size=UDim2.fromScale(1,1); boardWrap.ZIndex=2
		makeList(boardWrap, Enum.FillDirection.Vertical, 0.035)

		local top = Instance.new("Frame"); top.Name="BoardRowTop"; top.Parent=boardWrap; top.BackgroundTransparency=1
		top.Size=UDim2.fromScale(1,(1-0.035)*0.5); top.ZIndex=2; makeList(top, Enum.FillDirection.Horizontal, 0.02)

		local bottom = Instance.new("Frame"); bottom.Name="BoardRowBottom"; bottom.Parent=boardWrap; bottom.BackgroundTransparency=1
		bottom.Size=UDim2.fromScale(1,(1-0.035)*0.5); bottom.ZIndex=2; makeList(bottom, Enum.FillDirection.Horizontal, 0.02)

		M._boardRowTop, M._boardRowBottom = top, bottom
	end

	local notice = Instance.new("Frame"); notice.Name="NoticeBar"; notice.Parent=center; notice.LayoutOrder=4
	local noticeH = math.max(0.05, (TUTORIAL_H) * 0.9)
	notice.Size=UDim2.fromScale(1, noticeH); notice.BackgroundColor3=COLOR_NOTICE_BG; notice.ZIndex=1; addCornerStroke(notice,nil,nil,1)
	local noticeText = UiUtil.makeLabel(notice, "NoticeText", "", UDim2.new(1,-16,1,-12), UDim2.new(0,8,0,6), nil, COLOR_TEXT)
	noticeText.TextScaled=true; noticeText.TextWrapped=true; noticeText.TextXAlignment=Enum.TextXAlignment.Left

	local tutorial = Instance.new("Frame"); tutorial.Name="TutorialBar"; tutorial.Parent=center
	tutorial.Size=UDim2.fromScale(1, TUTORIAL_H); tutorial.BackgroundColor3=COLOR_TUTORIAL_BG
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
	takenBG.ZIndex=1; takenBG.ImageTransparency=TRANSP.takenBg
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
		buttons = {
			yaku = btnYaku,
			confirm = btnConfirm,
			rerollAll = btnRerollAll,
			rerollHand = btnRerollHand,
			giveUp = btnGiveUp,
		},
		counters = {
			rerollField = badgeField,
			rerollHand  = badgeHand,
		},
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

	-- リロール残の反映とボタン活性制御（外部のStatePushハンドラから呼ぶ）
	refs.setRerollCounts = function(fieldLeft:number?, handLeft:number?, phase:string?)
		local f = tonumber(fieldLeft or 0) or 0
		local h = tonumber(handLeft  or 0) or 0
		if refs.counters and refs.counters.rerollField then refs.counters.rerollField.Text = tostring(f) end
		if refs.counters and refs.counters.rerollHand  then refs.counters.rerollHand.Text  = tostring(h) end

		local isPlay = (phase == nil) or (phase == "play")
		local function applyBtn(btn: TextButton?, left:number)
			if not btn then return end
			local enabled = isPlay and (left > 0)
			btn.Active = enabled
			btn.AutoButtonColor = enabled
			btn.TextTransparency = enabled and 0 or 0.5
			btn.BackgroundTransparency = enabled and 0 or 0.2
		end
		applyBtn(refs.buttons.rerollAll,  f)
		applyBtn(refs.buttons.rerollHand, h)
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
