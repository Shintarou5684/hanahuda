-- StarterPlayerScripts/UI/screens/ShopView.lua
-- v0.9.9-P3-05 View単純化：クリック＝即購入 / 送信は ClientSignals 経由 / フッターは CloseBtn
--  - フッターボタン：ConfirmBtn → CloseBtn（「ショップを終えて次の月に進む」）
--  - View は Remotes を直接叩かず、ClientSignals へ発火のみ
--  - セルクリック：右ペイン更新 → ClientSignals.BuyRequested:Fire(it)
--  - 安全 clamp / Kito 遅延描画 等は前版のまま

local Shop = {}
Shop.__index = Shop

local RS = game:GetService("ReplicatedStorage")
local SharedModules = RS:WaitForChild("SharedModules")

-- Config
local Config = RS:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

-- Logger
local Logger = require(SharedModules:WaitForChild("Logger"))
local LOG = (typeof(Logger.scope) == "function" and Logger.scope("ShopView"))
	or (typeof(Logger["for"]) == "function" and Logger["for"]("ShopView"))
	or { debug=function()end, info=function()end, warn=function(...) warn(...) end }

-- Styles
local Styles do
	local ok, mod = pcall(function()
		local uiRoot = script:FindFirstAncestor("UI")
		return require(uiRoot:WaitForChild("styles"):WaitForChild("ShopStyles"))
	end)
	Styles = ok and mod or nil
end

-- Renderer / Controllers
local uiRoot = script.Parent.Parent
local componentsFolder = uiRoot:WaitForChild("components")
local Renderer       = require(componentsFolder:WaitForChild("renderers"):WaitForChild("ShopRenderer"))
local ShopWires      = require(componentsFolder:WaitForChild("controllers"):WaitForChild("ShopWires"))
local ClientSignals  = require(componentsFolder:WaitForChild("controllers"):WaitForChild("ClientSignals"))
local TalismanBoard  = require(componentsFolder:WaitForChild("TalismanBoard"))

-- Shared helpers
local ShopFormat = require(SharedModules:WaitForChild("ShopFormat"))

--================ types ================
export type Payload = {
	items: {any}?, stock: {any}?,
	mon: number?, totalMon: number?,
	rerollCost: number?, canReroll: boolean?,
	seasonSum: number?, target: number?, rewardMon: number?,
	lang: string?, notice: string?, currentDeck: any?, state: any?,
}

--================ utils ================
local function normalizeLang(lang: string?): string
	local v = Locale.normalize(lang)
	if tostring(lang or ""):lower() == "jp" and v == "ja" then
		LOG.warn("[Locale] received legacy 'jp'; normalize to 'ja'")
	end
	return v
end

local function countItems(p: Payload?): number
	if not p then return 0 end
	if typeof(p.items) == "table" then return #p.items end
	if typeof(p.stock) == "table" then return #p.stock end
	return 0
end

local function getTalismanFromPayload(p: Payload?)
	return (p and p.state and p.state.run and p.state.run.talisman) or nil
end

local function cloneSlots6(slots)
	local s = slots or {}
	return { s[1], s[2], s[3], s[4], s[5], s[6] }
end

local function cloneTalismanData(t)
	if typeof(t) ~= "table" then return nil end
	return { maxSlots=tonumber(t.maxSlots or 6) or 6, unlocked=tonumber(t.unlocked or 0) or 0, slots=cloneSlots6(t.slots) }
end

local function talismanSignature(t)
	if typeof(t) ~= "table" then return "<nil>" end
	local parts = { tostring(tonumber(t.unlocked or 0) or 0) }
	local s = t.slots or {}
	for i=1,6 do parts[#parts+1] = tostring(s[i] or "") end
	return table.concat(parts, "|")
end

local function taliTitleText(lang: string?): string
	local l = lang or "ja"
	local s = Locale.t(l, "SHOP_UI_TALISMAN_BOARD_TITLE")
	if s == "SHOP_UI_TALISMAN_BOARD_TITLE" then s = Locale.t(l, "SHOP_UI_TALISMAN_BOARD") end
	return s
end

-- 安全数値 & 安全 clamp
local function _num(v, default)
	local n = tonumber(v)
	if n == nil or n ~= n then return default end
	return n
end
local function _safeClamp(x, minV, maxV)
	local lo = _num(minV, 0)
	local hi = _num(maxV, 0)
	if hi < lo then lo, hi = hi, lo end
	local xv = _num(x, lo)
	if xv < lo then return lo end
	if xv > hi then return hi end
	return xv
end

--================ View helpers ================
local function addCorner(gui: Instance, radius: number?)
	local ok, _ = pcall(function()
		local c = Instance.new("UICorner")
		local r = radius or (Styles and Styles.sizes and Styles.sizes.panelCorner) or Theme.PANEL_RADIUS or 10
		c.CornerRadius = UDim.new(0, r)
		c.Parent = gui
	end)
	return ok
end
local function addStroke(gui: Instance, color: Color3?, thickness: number?)
	local ok, _ = pcall(function()
		local s = Instance.new("UIStroke")
		s.Thickness = thickness or 1
		s.Color = (color or (Styles and Styles.colors and Styles.colors.panelStroke) or Theme.COLORS.PanelStroke)
		s.Transparency = 0
		s.Parent = gui
	end)
	return ok
end

--================ class ==================
local function _bindSelf(self, fn)
	return function(_, ...) return fn(self, ...) end
end

function Shop.new(deps)
	local self = setmetatable({}, Shop)
	self.deps = deps
	self._payload = nil
	self._lang = nil
	self._rerollBusy = false
	self._hiddenItems = {}
	self._stockSig = ""
	self._bg = nil

	self._taliBoard = nil
	self._localBoard = nil
	self._preview = nil
	self._lastPlaced = nil
	self._taliSig = "<none>"

	self._selectedId = nil
	self._cellById = {}

	self._kitoRefireAt = 0

	self:_ensureGui()

	ShopWires.wireButtons(self)
	ShopWires.applyInfoPlaceholder(self)

	self.show          = _bindSelf(self, Shop.show)
	self.hide          = _bindSelf(self, Shop.hide)
	self.update        = _bindSelf(self, Shop.update)
	self.setData       = _bindSelf(self, Shop.setData)
	self.setLang       = _bindSelf(self, Shop.setLang)
	self.attachRemotes = _bindSelf(self, Shop.attachRemotes)

	LOG.info("boot(View)")
	return self
end

--=========== ensureGui() ===========
function Shop:_ensureGui()
	if self.gui and self._nodes then return end

	local g = Instance.new("ScreenGui")
	g.Name = "ShopView"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 50
	g.Enabled = false
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self.gui = g

	-- 背景
	local bg = Instance.new("ImageLabel")
	bg.Name = "BgImage"
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0
	bg.Active = false
	bg.ScaleType = Enum.ScaleType.Crop
	bg.AnchorPoint = Vector2.new(0.5, 0.5)
	bg.Position = UDim2.fromScale(0.5, 0.5)
	bg.Size = UDim2.fromScale(1, 1)
	bg.ZIndex = 0
	bg.Parent = g
	self._bg = bg
	self:_ensureBg(true)

	-- modal
	local modal = Instance.new("Frame")
	modal.Name = "Modal"
	modal.AnchorPoint = Vector2.new(0.5,0.5)
	modal.Position = UDim2.new(0.5,0,0.5,0)
	modal.Size = UDim2.new(
		(Styles and Styles.sizes and Styles.sizes.modalWScale) or 0.82, 0,
		(Styles and Styles.sizes and Styles.sizes.modalHScale) or 0.72, 0
	)
	modal.BackgroundColor3 = (Styles and Styles.colors and Styles.colors.rightPaneBg) or Theme.COLORS.RightPaneBg
	modal.BorderSizePixel = 0
	modal.ZIndex = 1
	modal.Parent = g
	addCorner(modal)
	addStroke(modal, (Styles and Styles.colors and Styles.colors.rightPaneStroke) or Theme.COLORS.RightPaneStroke, 1)

	-- header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundColor3 = (Styles and Styles.colors and Styles.colors.panelBg) or Theme.COLORS.PanelBg
	header.BorderSizePixel = 0
	header.Size = UDim2.new(1,0,0,(Styles and Styles.sizes and Styles.sizes.headerH) or 48)
	header.ZIndex = 2
	header.Parent = modal
	addStroke(header, (Styles and Styles.colors and Styles.colors.panelStroke) or Theme.COLORS.PanelStroke, 1)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1,-20,1,0)
	title.Position = UDim2.new(0,10,0,0)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "屋台（View）"
	title.TextSize = (Styles and Styles.fontSizes and Styles.fontSizes.title) or 20
	title.TextColor3 = (Styles and Styles.colors and Styles.colors.text) or Theme.COLORS.TextDefault
	title.ZIndex = 3
	title.Parent = header

	local deckBtn = Instance.new("TextButton")
	deckBtn.Name = "DeckBtn"
	deckBtn.Size = UDim2.new(0,(Styles and Styles.sizes and Styles.sizes.deckBtnW) or 140,0,(Styles and Styles.sizes and Styles.sizes.deckBtnH) or 32)
	deckBtn.Position = UDim2.new(1,-300,0.5,-16)
	deckBtn.Text = "デッキを見る"
	deckBtn.ZIndex = 3
	deckBtn.Parent = header
	addCorner(deckBtn, (Styles and Styles.sizes and Styles.sizes.btnCorner) or 8)
	addStroke(deckBtn, (Styles and Styles.colors and Styles.colors.panelStroke) or Theme.COLORS.PanelStroke, 1)

	local rerollBtn = Instance.new("TextButton")
	rerollBtn.Name = "RerollBtn"
	rerollBtn.Size = UDim2.new(0,(Styles and Styles.sizes and Styles.sizes.rerollBtnW) or 140,0,(Styles and Styles.sizes and Styles.sizes.rerollBtnH) or 32)
	rerollBtn.Position = UDim2.new(1,-150,0.5,-16)
	rerollBtn.Text = "リロール"
	rerollBtn.ZIndex = 3
	rerollBtn.Parent = header
	rerollBtn.BackgroundColor3 = (Styles and Styles.colors and Styles.colors.warnBtnBg) or Theme.COLORS.WarnBtnBg
	rerollBtn.TextColor3 = (Styles and Styles.colors and Styles.colors.warnBtnText) or Theme.COLORS.WarnBtnText
	addCorner(rerollBtn, (Styles and Styles.sizes and Styles.sizes.btnCorner) or 8)

	-- body（上下2段）
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	local headerH = (Styles and Styles.sizes and Styles.sizes.headerH) or 48
	local footerH = (Styles and Styles.sizes and Styles.sizes.footerH) or 64
	local bodyPad = (Styles and Styles.sizes and Styles.sizes.bodyPad) or 10
	body.Size = UDim2.new(1,-(bodyPad*2),1,-(headerH+footerH))
	body.Position = UDim2.new(0,bodyPad,0,headerH)
	body.ZIndex = 1
	body.Parent = modal

	local vlist = Instance.new("UIListLayout")
	vlist.FillDirection = Enum.FillDirection.Vertical
	vlist.SortOrder = Enum.SortOrder.LayoutOrder
	vlist.Padding = UDim.new(0,(Styles and Styles.sizes and Styles.sizes.vlistGap) or 8)
	vlist.Parent = body

	-- 上段
	local top = Instance.new("Frame")
	top.Name = "Top"; top.BackgroundTransparency = 1
	top.Size = UDim2.new(1,0,0.7,0)
	top.LayoutOrder = 1; top.ZIndex = 1; top.Parent = body

	local left = Instance.new("Frame")
	left.Name = "Left"; left.BackgroundTransparency = 1
	left.Size = UDim2.new(0.62,0,1,0); left.ZIndex = 1; left.Parent = top

	local right = Instance.new("Frame")
	right.Name = "Right"; right.BackgroundTransparency = 1
	right.Size = UDim2.new(0.38,0,1,0); right.Position = UDim2.new(0.62,0,0,0)
	right.ZIndex = 1; right.Parent = top

	-- 左スクロール＋グリッド
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"; scroll.Size = UDim2.new(1,0,1,0)
	scroll.CanvasSize = UDim2.new(0,0,0,0)
	scroll.ScrollBarThickness = (Styles and Styles.sizes and Styles.sizes.scrollBar) or 8
	scroll.BackgroundTransparency = 1
	scroll.ZIndex = 2; scroll.Active = true
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = left

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset((Styles and Styles.sizes and Styles.sizes.gridCellW) or 96, (Styles and Styles.sizes and Styles.sizes.gridCellH) or 144)
	grid.CellPadding = UDim2.fromOffset((Styles and Styles.sizes and Styles.sizes.gridGap) or 8, (Styles and Styles.sizes and Styles.sizes.gridGap) or 8)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroll

	-- 右：デッキ or 情報
	local deckPanel = Instance.new("Frame")
	deckPanel.Name = "DeckPanel"
	deckPanel.BackgroundColor3 = (Styles and Styles.colors and Styles.colors.panelBg) or Theme.COLORS.PanelBg
	deckPanel.BorderSizePixel = 0
	deckPanel.Size = UDim2.new(1,0,0.52,0)
	deckPanel.Position = UDim2.new(0,0,0,0)
	deckPanel.Visible = false
	deckPanel.ZIndex = 2; deckPanel.Parent = right
	addCorner(deckPanel); addStroke(deckPanel, (Styles and Styles.colors and Styles.colors.panelStroke) or Theme.COLORS.PanelStroke, 1)

	local deckTitle = Instance.new("TextLabel")
	deckTitle.Name = "DeckTitle"; deckTitle.BackgroundTransparency = 1
	deckTitle.Size = UDim2.new(1,-10,0,24); deckTitle.Position = UDim2.new(0,6,0,4)
	deckTitle.TextXAlignment = Enum.TextXAlignment.Left
	deckTitle.Text = "現在のデッキ"
	deckTitle.TextSize = (Styles and Styles.fontSizes and Styles.sizes.deckTitle) or 18
	deckTitle.TextColor3 = (Styles and Styles.colors and Styles.colors.text) or Theme.COLORS.TextDefault
	deckTitle.ZIndex = 3; deckTitle.Parent = deckPanel

	local deckText = Instance.new("TextLabel")
	deckText.Name = "DeckText"; deckText.BackgroundTransparency = 1
	deckText.Size = UDim2.new(1,-12,1,-30); deckText.Position = UDim2.new(0,6,0,28)
	deckText.TextXAlignment = Enum.TextXAlignment.Left; deckText.TextYAlignment = Enum.TextYAlignment.Top
	deckText.TextWrapped = true; deckText.RichText = false; deckText.Text = ""
	deckText.TextColor3 = (Styles and Styles.colors and Styles.colors.text) or Theme.COLORS.TextDefault
	deckText.ZIndex = 3; deckText.Parent = deckPanel

	local infoPanel = Instance.new("Frame")
	infoPanel.Name = "InfoPanel"
	infoPanel.BackgroundColor3 = (Styles and Styles.colors and Styles.colors.panelBg) or Theme.COLORS.PanelBg
	infoPanel.BorderSizePixel = 0
	infoPanel.Size = UDim2.new(1,0,0.52,0)
	infoPanel.Position = UDim2.new(0,0,0,0)
	infoPanel.Visible = true
	infoPanel.ZIndex = 2; infoPanel.Parent = right
	addCorner(infoPanel); addStroke(infoPanel, (Styles and Styles.colors and Styles.colors.panelStroke) or Theme.COLORS.PanelStroke, 1)

	local infoTitle = Instance.new("TextLabel")
	infoTitle.Name = "InfoTitle"; infoTitle.BackgroundTransparency = 1
	infoTitle.Size = UDim2.new(1,-10,0,24); infoTitle.Position = UDim2.new(0,6,0,4)
	infoTitle.TextXAlignment = Enum.TextXAlignment.Left
	infoTitle.Text = "アイテム情報"
	infoTitle.TextSize = (Styles and Styles.fontSizes and Styles.sizes.infoTitle) or 18
	infoTitle.TextColor3 = (Styles and Styles.colors and Styles.colors.text) or Theme.COLORS.TextDefault
	infoTitle.ZIndex = 3; infoTitle.Parent = infoPanel

	local infoText = Instance.new("TextLabel")
	infoText.Name = "InfoText"; infoText.BackgroundTransparency = 1
	infoText.Size = UDim2.new(1,-12,1,-30); infoText.Position = UDim2.new(0,6,0,28)
	infoText.TextXAlignment = Enum.TextXAlignment.Left
	infoText.TextYAlignment = Enum.TextYAlignment.Top
	infoText.TextWrapped = true; infoText.RichText = true
	infoText.Text = "（アイテムにマウスを乗せるか、クリックしてください）"
	infoText.TextColor3 = (Styles and Styles.colors and Styles.colors.helpText) or Theme.COLORS.HelpText
	infoText.ZIndex = 3; infoText.Parent = infoPanel

	-- 右：サマリ（下段固定）
	local summary = Instance.new("TextLabel")
	summary.Name = "Summary"; summary.BackgroundTransparency = 1
	summary.Size = UDim2.new(1,0,0.48,0); summary.Position = UDim2.new(0,0,0.52,0)
	summary.TextXAlignment = Enum.TextXAlignment.Left; summary.TextYAlignment = Enum.TextYAlignment.Top
	summary.TextWrapped = true; summary.RichText = false; summary.Text = ""
	summary.TextColor3 = (Styles and Styles.colors and Styles.colors.text) or Theme.COLORS.TextDefault
	summary.ZIndex = 1; summary.Parent = right

	-- 下段（護符 30%）
	local bottom = Instance.new("Frame")
	bottom.Name = "Bottom"; bottom.BackgroundTransparency = 1
	bottom.Size = UDim2.new(1,0,0.3,0)
	bottom.LayoutOrder = 2; bottom.ZIndex = 1; bottom.Parent = body

	local taliArea = Instance.new("Frame")
	taliArea.Name = "TalismanArea"; taliArea.BackgroundTransparency = 1
	taliArea.Size = UDim2.fromScale(1,1); taliArea.Parent = bottom

	-- footer（CloseBtn）
	local footer = Instance.new("Frame")
	footer.Name = "Footer"; footer.BackgroundTransparency = 1
	footer.Size = UDim2.new(1,0,0,(Styles and Styles.sizes and Styles.sizes.footerH) or 64)
	footer.Position = UDim2.new(0,0,1,-((Styles and Styles.sizes and Styles.sizes.footerH) or 64))
	footer.ZIndex = 1; footer.Parent = modal

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0,(Styles and Styles.sizes and Styles.sizes.closeBtnW) or 260,0,(Styles and Styles.sizes and Styles.sizes.closeBtnH) or 44)
	closeBtn.Position = UDim2.new(0.5,-((Styles and Styles.sizes and Styles.sizes.closeBtnW) or 260)/2,0.5,-((Styles and Styles.sizes and Styles.sizes.closeBtnH) or 44)/2)
	closeBtn.Text = "ショップを終えて次の月に進む"
	closeBtn.ZIndex = 2; closeBtn.Parent = footer
	closeBtn.BackgroundColor3 = (Styles and Styles.colors and Styles.colors.primaryBtnBg) or Theme.COLORS.PrimaryBtnBg
	closeBtn.TextColor3 = (Styles and Styles.colors and Styles.colors.primaryBtnText) or Theme.COLORS.PrimaryBtnText
	addCorner(closeBtn, (Styles and Styles.sizes and Styles.sizes.btnCorner) or 8)

	-- 護符ボード
	self._taliBoard = TalismanBoard.new(taliArea, {
		title      = taliTitleText(self._lang or "ja"),
		widthScale = 0.95, padScale = 0.01,
	})
	local inst = self._taliBoard:getInstance()
	inst.AnchorPoint = Vector2.new(0.5, 0); inst.Position = UDim2.fromScale(0.5, 0); inst.ZIndex = 2

	self._nodes = {
		title = title, rerollBtn = rerollBtn, deckBtn = deckBtn,
		scroll = scroll, grid = grid,
		summary = summary,
		deckPanel = deckPanel, deckTitle = deckTitle, deckText = deckText,
		infoPanel = infoPanel, infoTitle = infoTitle, infoText = infoText,
		closeBtn = closeBtn,
		taliArea = taliArea,
	}
	g.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
end

--=========== relayout ===========
function Shop:relayoutByEffectHeight()
	local n = self._nodes; if not n then return end
	local infoText, infoPanel, summary, infoTitle = n.infoText, n.infoPanel, n.summary, n.infoTitle
	if not (infoText and infoPanel and summary) then return end

	local textH  = (typeof(infoText.TextBounds) == "Vector2" and math.max(0, infoText.TextBounds.Y)) or 0
	local titleH = (infoTitle and infoTitle.AbsoluteSize and infoTitle.AbsoluteSize.Y) or 0
	local pad    = 12
	local desiredTop = math.floor(textH + titleH + pad)

	local hostH = (infoPanel.AbsoluteSize and infoPanel.AbsoluteSize.Y) or 0
	if hostH <= 0 and infoPanel.Parent and infoPanel.Parent.AbsoluteSize then
		hostH = infoPanel.Parent.AbsoluteSize.Y
	end

	local minH = 120
	local maxH = (hostH > 0) and math.floor(hostH * 0.9) or minH
	local use  = _safeClamp(desiredTop, minH, maxH)
	summary.Position = UDim2.new(0, 0, 0, use)
end

--=========== list rebuild ===========
function Shop:rebuildList()
	local nodes = self._nodes; if not nodes then return end
	local scroll, grid = nodes.scroll, nodes.grid
	if not (scroll and grid) then return end

	-- 既存セル破棄
	for _, ch in ipairs(scroll:GetChildren()) do
		if ch:IsA("GuiObject") and ch ~= grid then ch:Destroy() end
	end
	self._cellById = {}
	self._selectedId = nil

	local p = self._payload or {}
	local items = p.items or p.stock or {}
	local lang = ShopFormat.normLang(p.lang) or self._lang or "ja"
	local mon  = tonumber(p.mon or p.totalMon or 0) or 0

	-- セル生成（クリック＝説明更新 → 送信は ClientSignals へ）
	local created = 0
	for _, it in ipairs(items) do
		local btn = Renderer.renderCell(scroll, self._nodes, it, lang, mon, nil)
		if btn then
			self._cellById[tostring(it.id)] = btn
			btn.Activated:Connect(function()
				self:_onSelectItem(it)           -- 右ペイン更新
				ClientSignals.BuyRequested:Fire(it) -- ← 送信は Wires 専任
			end)
			created += 1
		end
	end

	-- CanvasSize 再計算
	task.defer(function()
		local frameW = scroll.AbsoluteSize.X
		local cellW  = (grid.CellSize.X.Offset or 0) + (grid.CellPadding.X.Offset or 0)
		if cellW <= 0 then return end
		local perRow = math.max(1, math.floor(frameW / cellW))
		local rows   = math.ceil(created / perRow)
		local cellH  = (grid.CellSize.Y.Offset or 0) + (grid.CellPadding.Y.Offset or 0)
		local needed = rows * cellH + 8
		scroll.CanvasSize = UDim2.new(0, 0, 0, needed)
	end)
end

-- Renderer.setCellSelected を優先、未実装時はフェイルセーフ
local function _applyCellSelected(btn: Instance?, selected: boolean)
	if not (btn and btn:IsA("GuiObject")) then return end
	if typeof(Renderer.setCellSelected) == "function" then
		return Renderer.setCellSelected(btn, selected)
	end
	local stroke = nil
	for _, ch in ipairs(btn:GetChildren()) do
		if ch:IsA("UIStroke") then stroke = ch break end
	end
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Color = (Styles and Styles.colors and Styles.colors.panelStroke) or Theme.COLORS.PanelStroke
		stroke.Parent = btn
	end
	stroke.Thickness = selected and 3 or 1
end

function Shop:_onSelectItem(it:any)
	local id = tostring(it and it.id or "")
	if id == "" then return end

	-- 以前の選択解除
	if self._selectedId and self._cellById[self._selectedId] then
		_applyCellSelected(self._cellById[self._selectedId], false)
	end

	-- 新規選択
	self._selectedId = id
	local btn = self._cellById[id]
	if btn then _applyCellSelected(btn, true) end

	-- 右パネル文言
	local lang = self._lang or "ja"
	local title = ShopFormat.itemTitle(it, lang)
	local desc  = ShopFormat.itemDesc(it, lang)
	local cat   = Locale.t(lang, "SHOP_UI_LABEL_CATEGORY"):format(tostring(it.category))
	local price = Locale.t(lang, "SHOP_UI_LABEL_PRICE"):format(ShopFormat.fmtPrice(it.price))
	self._nodes.infoText.Text = table.concat({
		string.format("<b>%s</b>", title ~= "" and title or (ShopFormat.faceName(it) or "")),
		cat, price, "", (desc ~= "" and desc or Locale.t(lang, "SHOP_UI_NO_DESC"))
	}, "\n")
	self:relayoutByEffectHeight()
end

--=========== data & render ===========
local function maybeClearPreview(self)
	if not self._preview or not self._lastPlaced then return end
	local base = self:_snapBoard(); if not base or not base.slots then return end
	local idx = self._lastPlaced.index; local id  = self._lastPlaced.id
	if idx and id and base.slots[idx] == id then
		self._preview = nil; self._lastPlaced = nil
		LOG.info("[preview] cleared by server state | idx=%d id=%s", idx, id)
	end
end

function Shop:_snapBoard()
	return self._localBoard or self._preview or getTalismanFromPayload(self._payload) or { maxSlots=6, unlocked=0, slots={nil,nil,nil,nil,nil,nil} }
end

function Shop:_applyServerTalismanOnce(payload: Payload?)
	local sv = cloneTalismanData(getTalismanFromPayload(payload))
	if not sv then return end
	local sig = talismanSignature(sv)
	if sig == self._taliSig then return end
	self._localBoard = sv; self._taliSig = sig; self._preview = nil; self._lastPlaced = nil
	if self._taliBoard then self._taliBoard:setData(self._localBoard) end
	LOG.info("[talisman] server applied | sig=%s", sig)
end

function Shop:_syncTalismanBoard()
	if not self._taliBoard then return end
	local lang = self._lang or "ja"
	pcall(function()
		if typeof(self._taliBoard.setLang) == "function" then self._taliBoard:setLang(lang) end
		if typeof(self._taliBoard.setData) == "function" then self._taliBoard:setData(self:_snapBoard()) end
		local inst = self._taliBoard:getInstance()
		if inst and inst:FindFirstChild("Title") and inst.Title:IsA("TextLabel") then
			inst.Title.Text = taliTitleText(lang)
		end
	end)
end

function Shop:_ensureBg(forceToBack: boolean?)
	if not self.gui then return end
	local bg = self._bg
	if not bg or not bg.Parent then
		bg = Instance.new("ImageLabel")
		bg.Name = "BgImage"; bg.BackgroundTransparency = 1; bg.BorderSizePixel = 0; bg.Active = false
		bg.ScaleType = Enum.ScaleType.Crop; bg.AnchorPoint = Vector2.new(0.5, 0.5); bg.Position = UDim2.fromScale(0.5, 0.5)
		bg.Size = UDim2.fromScale(1, 1); bg.ZIndex = 0; bg.Parent = self.gui; self._bg = bg
	end
	bg.Image = Theme.IMAGES and Theme.IMAGES.SHOP_BG or ""
	bg.ImageTransparency = (Theme.TRANSPARENCY and Theme.TRANSPARENCY.shopBg) or 0
	if forceToBack then bg.ZIndex = 0; bg.LayoutOrder = -10000; bg.Parent = self.gui end
end

--=========== public API ===========
local function normalizePayload(p: Payload?): Payload?
	if not p then return nil end
	if p.lang then
		local nl = normalizeLang(p.lang); if nl and nl ~= p.lang then p.lang = nl end
	end
	if typeof(p.items) ~= "table" and typeof(p.stock) == "table" then
		p.items = p.stock
	end
	return p
end

function Shop:setData(payload: Payload)
	payload = normalizePayload(payload)
	if payload and payload.lang then self._lang = payload.lang end
	self._payload = payload
	maybeClearPreview(self)
	self:_applyServerTalismanOnce(payload)

	-- タイトルや右ペイン固定文言
	local lang = self._lang or "ja"
	local nodes = self._nodes
	if nodes then
		nodes.title.Text     = Locale.t(lang, "SHOP_UI_TITLE")
		nodes.infoTitle.Text = Locale.t(lang, "SHOP_UI_INFO_TITLE")
		if nodes.closeBtn then
			nodes.closeBtn.Text = Locale.t(lang, "SHOP_UI_CLOSE_BTN")
		end
		if nodes.rerollBtn then
			local cost = tonumber(payload.rerollCost or 1) or 1
			nodes.rerollBtn.Text = Locale.t(lang, "SHOP_UI_REROLL_FMT"):format(cost)
		end
		if nodes.deckBtn then
			nodes.deckBtn.Text = Locale.t(lang, "SHOP_UI_VIEW_DECK")
		end
	end

	-- デッキ右ペイン
	do
		local n, lst = ShopFormat.deckListFromSnapshot(payload.currentDeck)
		if nodes then
			nodes.deckTitle.Text = Locale.t(lang, "SHOP_UI_DECK_TITLE_FMT"):format(n)
			nodes.deckText.Text  = (n > 0) and lst or Locale.t(lang, "SHOP_UI_DECK_EMPTY")
		end
	end

	-- サマリ
	do
		local mon = tonumber(payload.mon or payload.totalMon or 0) or 0
		local visCount = countItems(payload)
		local s = {}
		if payload.seasonSum ~= nil or payload.target ~= nil or payload.rewardMon ~= nil then
			table.insert(s,
				Locale.t(lang,"SHOP_UI_SUMMARY_CLEARED_FMT")
					:format(tonumber(payload.seasonSum or 0) or 0, tonumber(payload.target or 0) or 0, tonumber(payload.rewardMon or 0) or 0, tonumber(payload.totalMon or mon or 0) or 0)
			)
		end
		table.insert(s, Locale.t(lang,"SHOP_UI_SUMMARY_ITEMS_FMT"):format(visCount))
		table.insert(s, Locale.t(lang,"SHOP_UI_SUMMARY_MONEY_FMT"):format(mon))
		if nodes then nodes.summary.Text = table.concat(s, "\n") end
	end

	-- 一括再生成
	self:rebuildList()
	self:_applyRerollButtonState()

	-- Kitoアートの遅延再描画
	self:_refreshKitoArtSoon()
end

function Shop:show(payload: Payload?)
	if payload then self:setData(payload) end
	self.gui.Enabled = true
	self:_ensureBg(true)
	self:_applyRerollButtonState()
	self:_refreshKitoArtSoon()
end

function Shop:hide()
	if self.gui.Enabled then LOG.info("hide | enabled=false") end
	self.gui.Enabled = false
end

function Shop:update(payload: Payload?)
	if payload then self:setData(payload) else self:rebuildList() end
	self:_applyRerollButtonState()
	self:_refreshKitoArtSoon()
end

function Shop:setLang(lang: string?)
	self._lang = normalizeLang(lang)
	self:_syncTalismanBoard()
end

function Shop:attachRemotes(remotes: any, router: any?)
	LOG.info("attachRemotes (compat)")
	if typeof(ShopWires.attachRemotes) == "function" then
		return ShopWires.attachRemotes(self, remotes, router)
	end
	-- 単一路線化以降は no-op
	return nil
end

--============== Kito遅延リフレッシュ ==============
function Shop:_refreshKitoArtSoon()
	local now = os.clock()
	self._kitoRefireAt = self._kitoRefireAt or 0
	if (now - self._kitoRefireAt) < 0.5 then return end
	self._kitoRefireAt = now
	task.delay(0.35, function()
		if not (self.gui and self.gui.Enabled) then return end
		if not self._payload then return end
		LOG.info("[kito] late refresh tick -> repaint cells")
		self:rebuildList()
		self:_applyRerollButtonState()
	end)
end

--============== Reroll 状態 ==============
function Shop:_applyRerollButtonState()
	local p = self._payload or {}
	local money = tonumber(p.mon or p.totalMon or 0) or 0
	local cost  = tonumber(p.rerollCost or 1) or 1
	local can   = (p.canReroll ~= false) and (money >= cost)
	local active = (self._rerollBusy ~= true) and can
	if self._nodes and self._nodes.rerollBtn then
		self._nodes.rerollBtn.Active = active
		self._nodes.rerollBtn.AutoButtonColor = active
	end
	LOG.info("[reroll] btnState active=%s mon=%d cost=%d can=%s busy=%s",
		tostring(active), money, cost, tostring(can), tostring(self._rerollBusy))
end

return Shop
