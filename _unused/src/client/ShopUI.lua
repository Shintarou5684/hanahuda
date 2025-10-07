-- src/client/ui/components/ShopUI.lua
-- v0.9.G TWO-ROWS: 上下2段（上=0.7 / 下=0.3）下段に TalismanArea 追加
-- Phase1: 見た目値を ShopStyles 経由に（挙動は不変）

local RS = game:GetService("ReplicatedStorage")

-- Theme は最終フォールバックとして存続
local Config = RS:WaitForChild("Config")
local Theme = require(Config:WaitForChild("Theme"))

-- Styles（UI配下: UI/styles/ShopStyles.lua）
local Styles do
	local ok, mod = pcall(function()
		-- ShopUI.lua は UI/components 配下
		return require(script.Parent.Parent:WaitForChild("styles"):WaitForChild("ShopStyles"))
	end)
	Styles = ok and mod or nil
end

local M = {}

-- 小ユーティリティ：角丸とストローク（既定値を Styles へ移譲）
local function addCorner(gui: Instance, radius: number?)
	local ok, _ = pcall(function()
		local c = Instance.new("UICorner")
		local r = radius or (Styles and Styles.sizes.panelCorner) or Theme.PANEL_RADIUS or 10
		c.CornerRadius = UDim.new(0, r)
		c.Parent = gui
	end)
	return ok
end

local function addStroke(gui: Instance, color: Color3?, thickness: number?)
	local ok, _ = pcall(function()
		local s = Instance.new("UIStroke")
		s.Thickness = thickness or 1
		s.Color = color or (Styles and Styles.colors.panelStroke) or Theme.COLORS.PanelStroke
		s.Transparency = 0
		s.Parent = gui
	end)
	return ok
end

function M.build()
	-- root
	local g = Instance.new("ScreenGui")
	g.Name = "ShopScreen"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 50
	g.Enabled = false
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- modal（右ペイン風：和紙オフホワイト＋ストローク）
	local modal = Instance.new("Frame")
	modal.Name = "Modal"
	modal.AnchorPoint = Vector2.new(0.5,0.5)
	modal.Position = UDim2.new(0.5,0,0.5,0)
	modal.Size = UDim2.new(
		(Styles and Styles.sizes.modalWScale) or 0.82, 0,
		(Styles and Styles.sizes.modalHScale) or 0.72, 0
	)
	modal.BackgroundColor3 = (Styles and Styles.colors.rightPaneBg) or Theme.COLORS.RightPaneBg
	modal.BorderSizePixel = 0
	modal.ZIndex = 1
	modal.Parent = g
	addCorner(modal)
	addStroke(modal, (Styles and Styles.colors.rightPaneStroke) or Theme.COLORS.RightPaneStroke, 1)

	-- header（薄いパネル色＋ストローク）
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundColor3 = (Styles and Styles.colors.panelBg) or Theme.COLORS.PanelBg
	header.BorderSizePixel = 0
	header.Size = UDim2.new(1,0,0,(Styles and Styles.sizes.headerH) or 48)
	header.ZIndex = 2
	header.Parent = modal
	addStroke(header, (Styles and Styles.colors.panelStroke) or Theme.COLORS.PanelStroke, 1)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1,-20,1,0)
	title.Position = UDim2.new(0,10,0,0)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "屋台（MVP）"
	title.TextSize = (Styles and Styles.fontSizes.title) or 20
	title.TextColor3 = (Styles and Styles.colors.text) or Theme.COLORS.TextDefault
	title.ZIndex = 3
	title.Parent = header

	local deckBtn = Instance.new("TextButton")
	deckBtn.Name = "DeckBtn"
	deckBtn.Size = UDim2.new(0,(Styles and Styles.sizes.deckBtnW) or 140,0,(Styles and Styles.sizes.deckBtnH) or 32)
	deckBtn.Position = UDim2.new(1,-300,0.5,-16)
	deckBtn.Text = "デッキを見る"
	deckBtn.ZIndex = 3
	deckBtn.Parent = header
	addCorner(deckBtn, (Styles and Styles.sizes.btnCorner) or 8)
	addStroke(deckBtn, (Styles and Styles.colors.panelStroke) or Theme.COLORS.PanelStroke, 1)

	local rerollBtn = Instance.new("TextButton")
	rerollBtn.Name = "RerollBtn"
	rerollBtn.Size = UDim2.new(0,(Styles and Styles.sizes.rerollBtnW) or 140,0,(Styles and Styles.sizes.rerollBtnH) or 32)
	rerollBtn.Position = UDim2.new(1,-150,0.5,-16)
	rerollBtn.Text = "リロール"
	rerollBtn.ZIndex = 3
	rerollBtn.Parent = header
	-- Warn button styling
	rerollBtn.BackgroundColor3 = (Styles and Styles.colors.warnBtnBg) or Theme.COLORS.WarnBtnBg
	rerollBtn.TextColor3 = (Styles and Styles.colors.warnBtnText) or Theme.COLORS.WarnBtnText
	addCorner(rerollBtn, (Styles and Styles.sizes.btnCorner) or 8)

	-- body（上下2段）
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(
		1,-(Styles and Styles.sizes.bodyPad and Styles.sizes.bodyPad*2 or 20),
		1,-((Styles and Styles.sizes.headerH or 48)+(Styles and Styles.sizes.footerH or 64))
	)
	body.Position = UDim2.new(0,(Styles and Styles.sizes.bodyPad) or 10,0,(Styles and Styles.sizes.headerH) or 48)
	body.ZIndex = 1
	body.Parent = modal

	local vlist = Instance.new("UIListLayout")
	vlist.FillDirection = Enum.FillDirection.Vertical
	vlist.SortOrder = Enum.SortOrder.LayoutOrder
	vlist.Padding = UDim.new(0,(Styles and Styles.sizes.vlistGap) or 8)
	vlist.Parent = body

	-- 上段（コンテンツ 70%）
	local top = Instance.new("Frame")
	top.Name = "Top"
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(1,0,0.7,0)
	top.LayoutOrder = 1
	top.ZIndex = 1
	top.Parent = body

	local left = Instance.new("Frame")
	left.Name = "Left"
	left.BackgroundTransparency = 1
	left.Size = UDim2.new(0.62,0,1,0)
	left.ZIndex = 1
	left.Parent = top

	local right = Instance.new("Frame")
	right.Name = "Right"
	right.BackgroundTransparency = 1
	right.Size = UDim2.new(0.38,0,1,0)
	right.Position = UDim2.new(0.62,0,0,0)
	right.ZIndex = 1
	right.Parent = top

	-- 左スクロール
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Size = UDim2.new(1,0,1,0)
	scroll.CanvasSize = UDim2.new(0,0,0,0)
	scroll.ScrollBarThickness = (Styles and Styles.sizes.scrollBar) or 8
	scroll.BackgroundTransparency = 1
	scroll.ZIndex = 2
	scroll.Active = true
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = left

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset((Styles and Styles.sizes.gridCellW) or 96, (Styles and Styles.sizes.gridCellH) or 144)
	grid.CellPadding = UDim2.fromOffset((Styles and Styles.sizes.gridGap) or 8, (Styles and Styles.sizes.gridGap) or 8)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroll

	-- 右：デッキパネル
	local deckPanel = Instance.new("Frame")
	deckPanel.Name = "DeckPanel"
	deckPanel.BackgroundColor3 = (Styles and Styles.colors.panelBg) or Theme.COLORS.PanelBg
	deckPanel.BorderSizePixel = 0
	deckPanel.Size = UDim2.new(1,0,0.52,0)
	deckPanel.Position = UDim2.new(0,0,0,0)
	deckPanel.Visible = false
	deckPanel.ZIndex = 2
	deckPanel.Parent = right
	addCorner(deckPanel)
	addStroke(deckPanel, (Styles and Styles.colors.panelStroke) or Theme.COLORS.PanelStroke, 1)

	local deckTitle = Instance.new("TextLabel")
	deckTitle.Name = "DeckTitle"
	deckTitle.BackgroundTransparency = 1
	deckTitle.Size = UDim2.new(1,-10,0,24)
	deckTitle.Position = UDim2.new(0,6,0,4)
	deckTitle.TextXAlignment = Enum.TextXAlignment.Left
	deckTitle.Text = "現在のデッキ"
	deckTitle.TextSize = (Styles and Styles.fontSizes.deckTitle) or 18
	deckTitle.TextColor3 = (Styles and Styles.colors.text) or Theme.COLORS.TextDefault
	deckTitle.ZIndex = 3
	deckTitle.Parent = deckPanel

	local deckText = Instance.new("TextLabel")
	deckText.Name = "DeckText"
	deckText.BackgroundTransparency = 1
	deckText.Size = UDim2.new(1,-12,1,-30)
	deckText.Position = UDim2.new(0,6,0,28)
	deckText.TextXAlignment = Enum.TextXAlignment.Left
	deckText.TextYAlignment = Enum.TextYAlignment.Top
	deckText.TextWrapped = true
	deckText.RichText = false
	deckText.Text = ""
	deckText.TextColor3 = (Styles and Styles.colors.text) or Theme.COLORS.TextDefault
	deckText.ZIndex = 3
	deckText.Parent = deckPanel

	-- 右：カード情報
	local infoPanel = Instance.new("Frame")
	infoPanel.Name = "InfoPanel"
	infoPanel.BackgroundColor3 = (Styles and Styles.colors.panelBg) or Theme.COLORS.PanelBg
	infoPanel.BorderSizePixel = 0
	infoPanel.Size = UDim2.new(1,0,0.52,0)
	infoPanel.Position = UDim2.new(0,0,0,0)
	infoPanel.Visible = true
	infoPanel.ZIndex = 2
	infoPanel.Parent = right
	addCorner(infoPanel)
	addStroke(infoPanel, (Styles and Styles.colors.panelStroke) or Theme.COLORS.PanelStroke, 1)

	local infoTitle = Instance.new("TextLabel")
	infoTitle.Name = "InfoTitle"
	infoTitle.BackgroundTransparency = 1
	infoTitle.Size = UDim2.new(1,-10,0,24)
	infoTitle.Position = UDim2.new(0,6,0,4)
	infoTitle.TextXAlignment = Enum.TextXAlignment.Left
	infoTitle.Text = "アイテム情報"
	infoTitle.TextSize = (Styles and Styles.fontSizes.infoTitle) or 18
	infoTitle.TextColor3 = (Styles and Styles.colors.text) or Theme.COLORS.TextDefault
	infoTitle.ZIndex = 3
	infoTitle.Parent = infoPanel

	local infoText = Instance.new("TextLabel")
	infoText.Name = "InfoText"
	infoText.BackgroundTransparency = 1
	infoText.Size = UDim2.new(1,-12,1,-30)
	infoText.Position = UDim2.new(0,6,0,28)
	infoText.TextXAlignment = Enum.TextXAlignment.Left
	infoText.TextYAlignment = Enum.TextYAlignment.Top
	infoText.TextWrapped = true
	infoText.RichText = true   -- <b>…</b> 太字対応
	infoText.Text = "（アイテムにマウスを乗せるか、クリックしてください）"
	infoText.TextColor3 = (Styles and Styles.colors.helpText) or Theme.COLORS.HelpText
	infoText.ZIndex = 3
	infoText.Parent = infoPanel

	-- 右：サマリ（下段固定）
	local summary = Instance.new("TextLabel")
	summary.Name = "Summary"
	summary.BackgroundTransparency = 1
	summary.Size = UDim2.new(1,0,0.48,0)
	summary.Position = UDim2.new(0,0,0.52,0)
	summary.TextXAlignment = Enum.TextXAlignment.Left
	summary.TextYAlignment = Enum.TextYAlignment.Top
	summary.TextWrapped = true
	summary.RichText = false
	summary.Text = ""
	summary.TextColor3 = (Styles and Styles.colors.text) or Theme.COLORS.TextDefault
	summary.ZIndex = 1
	summary.Parent = right

	-- 下段（護符 30%）
	local bottom = Instance.new("Frame")
	bottom.Name = "Bottom"
	bottom.BackgroundTransparency = 1
	bottom.Size = UDim2.new(1,0,0.3,0)
	bottom.LayoutOrder = 2
	bottom.ZIndex = 1
	bottom.Parent = body

	local taliArea = Instance.new("Frame")
	taliArea.Name = "TalismanArea"
	taliArea.BackgroundTransparency = 1
	taliArea.Size = UDim2.fromScale(1,1)
	taliArea.Parent = bottom

	-- footer
	local footer = Instance.new("Frame")
	footer.Name = "Footer"
	footer.BackgroundTransparency = 1
	footer.Size = UDim2.new(1,0,0,(Styles and Styles.sizes.footerH) or 64)
	footer.Position = UDim2.new(0,0,1,-((Styles and Styles.sizes.footerH) or 64))
	footer.ZIndex = 1
	footer.Parent = modal

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0,(Styles and Styles.sizes.closeBtnW) or 260,0,(Styles and Styles.sizes.closeBtnH) or 44)
	closeBtn.Position = UDim2.new(0.5,-((Styles and Styles.sizes.closeBtnW) or 260)/2,0.5,-((Styles and Styles.sizes.closeBtnH) or 44)/2)
	closeBtn.Text = "屋台を閉じて次の季節へ"
	closeBtn.ZIndex = 2
	closeBtn.Parent = footer
	-- Primary button styling
	closeBtn.BackgroundColor3 = (Styles and Styles.colors.primaryBtnBg) or Theme.COLORS.PrimaryBtnBg
	closeBtn.TextColor3 = (Styles and Styles.colors.primaryBtnText) or Theme.COLORS.PrimaryBtnText
	addCorner(closeBtn, (Styles and Styles.sizes.btnCorner) or 8)

	-- nodes 返却（従来互換＋taliArea）
	local nodes = {
		title = title, rerollBtn = rerollBtn, deckBtn = deckBtn,
		scroll = scroll, grid = grid,
		summary = summary,
		deckPanel = deckPanel, deckTitle = deckTitle, deckText = deckText,
		infoPanel = infoPanel, infoTitle = infoTitle, infoText = infoText,
		closeBtn = closeBtn,
		taliArea = taliArea,
	}

	return g, nodes
end

return M