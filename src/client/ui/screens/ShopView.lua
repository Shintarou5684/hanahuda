-- StarterPlayerScripts/UI/screens/ShopView.lua
-- v0.9.9-P3-06 Styles一本化：Theme直参照削除（色/寸法）
--  - モーダル/ヘッダ/ボタン等の色・角丸・線色：Styles に一本化（Theme直参照を撤去）
--  - addCorner/addStroke の既定は最小定数のみ（Themeに依存しない）
--  - セルクリック＝即購入は ClientSignals.BuyRequested:Fire(it) に統一（Remotes直叩きなし）
--  - フッターは CloseBtn（「ショップを終えて次の月に進む」）
--  - 背景画像のみ Theme.IMAGES.SHOP_BG / Theme.TRANSPARENCY.shopBg を使用（画像はThemeの責務）

local Shop = {}
Shop.__index = Shop

local RS = game:GetService("ReplicatedStorage")
local SharedModules = RS:WaitForChild("SharedModules")

-- Config（Theme は背景画像用途のみ）
local Config = RS:WaitForChild("Config")
local Locale = require(Config:WaitForChild("Locale"))
local Theme  = require(Config:WaitForChild("Theme"))

-- Logger
local Logger = require(SharedModules:WaitForChild("Logger"))
local LOG = (typeof(Logger.scope) == "function" and Logger.scope("ShopView"))
	or (typeof(Logger["for"]) == "function" and Logger["for"]("ShopView"))
	or { debug=function()end, info=function()end, warn=function(...) warn(...) end }

-- Styles（UI/styles/ShopStyles）
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
local Renderer      = require(componentsFolder:WaitForChild("renderers"):WaitForChild("ShopRenderer"))
local ShopWires     = require(componentsFolder:WaitForChild("controllers"):WaitForChild("ShopWires"))
local ClientSignals = require(componentsFolder:WaitForChild("controllers"):WaitForChild("ClientSignals"))
local TalismanBoard = require(componentsFolder:WaitForChild("TalismanBoard"))

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
	local v = (typeof(Locale.normalize)=="function" and Locale.normalize(lang)) or (lang or "ja")
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

local function stockSignature(items: {any}?): string
	if typeof(items) ~= "table" then return "<nil>" end
	local parts = { tostring(#items) }
	for _, it in ipairs(items) do
		local id    = (it and it.id) or (it and it.code) or (it and it.sku) or ""
		local kind  = (it and (it.kind or it.type or it.category)) or ""
		local price = (it and (it.price or it.cost)) or ""
		local extra = (it and it.uid) or (it and it.name) or ""
		parts[#parts+1] = table.concat({tostring(id), tostring(kind), tostring(price), tostring(extra)}, ":")
	end
	return table.concat(parts, "||")
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
	local s = (typeof(Locale.t)=="function" and Locale.t(l, "SHOP_UI_TALISMAN_BOARD_TITLE")) or "護符"
	if s == "SHOP_UI_TALISMAN_BOARD_TITLE" then
		s = (typeof(Locale.t)=="function" and Locale.t(l, "SHOP_UI_TALISMAN_BOARD")) or "護符"
	end
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

--================ View helpers（Stylesのみ参照） ================
local function _styleColor(key, fallback)
	if Styles and Styles.colors and typeof(Styles.colors[key]) == "Color3" then
		return Styles.colors[key]
	end
	return fallback or Color3.fromRGB(200,200,200)
end

local function _styleSize(key, fallback)
	if Styles and Styles.sizes and tonumber(Styles.sizes[key]) then
		return Styles.sizes[key]
	end
	return fallback
end

local function addCorner(gui: Instance, radiusPx: number?)
	local ok, _ = pcall(function()
		local c = Instance.new("UICorner")
		local r = radiusPx or _styleSize("panelCorner", 10)
		c.CornerRadius = UDim.new(0, r)
		c.Parent = gui
	end)
	return ok
end

local function addStroke(gui: Instance, colorKeyOrColor: any, thickness: number?)
	local ok, _ = pcall(function()
		local s = Instance.new("UIStroke")
		s.Thickness = thickness or 1
		local col = colorKeyOrColor
		if typeof(colorKeyOrColor) == "string" then
			col = _styleColor(colorKeyOrColor, Color3.fromRGB(180,180,180))
		end
		s.Color = col or Color3.fromRGB(180,180,180)
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
	self._buyBusy = false -- セルクリック即購入の連打防止
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

	-- Remotes（既存互換）
	self._remotes = RS:WaitForChild("Remotes", 10)

	self.show          = _bindSelf(self, Shop.show)
	self.hide          = _bindSelf(self, Shop.hide)
	self.update        = _bindSelf(self, Shop.update)
	self.setData       = _bindSelf(self, Shop.setData)
	self.setLang       = _bindSelf(self, Shop.setLang)
	self.attachRemotes = _bindSelf(self, Shop.attachRemotes)
	self.autoPlace     = _bindSelf(self, Shop.autoPlace)

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

	-- 背景（※画像のみ Theme 由来：色・寸法は Styles 管理）
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
	modal.BackgroundColor3 = _styleColor("rightPaneBg", Color3.fromRGB(250,248,240))
	modal.BorderSizePixel = 0
	modal.ZIndex = 1
	modal.Parent = g
	addCorner(modal, _styleSize("panelCorner", 10))
	addStroke(modal, "rightPaneStroke", 1)

	-- header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundColor3 = _styleColor("panelBg", Color3.fromRGB(252,250,244))
	header.BorderSizePixel = 0
	header.Size = UDim2.new(1,0,0,(Styles and Styles.sizes and Styles.sizes.headerH) or 48)
	header.ZIndex = 2
	header.Parent = modal
	addStroke(header, "panelStroke", 1)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1,-20,1,0)
	title.Position = UDim2.new(0,10,0,0)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "屋台（View）"
	title.TextSize = (Styles and Styles.fontSizes and Styles.fontSizes.title) or 20
	title.TextColor3 = _styleColor("text", Color3.fromRGB(25,25,25))
	title.ZIndex = 3
	title.Parent = header

	local deckBtn = Instance.new("TextButton")
	deckBtn.Name = "DeckBtn"
	deckBtn.Size = UDim2.new(0,(Styles and Styles.sizes and Styles.sizes.deckBtnW) or 140,0,(Styles and Styles.sizes and Styles.sizes.deckBtnH) or 32)
	deckBtn.Position = UDim2.new(1,-300,0.5,-16)
	deckBtn.Text = "デッキを見る"
	deckBtn.ZIndex = 3
	deckBtn.Parent = header
	addCorner(deckBtn, _styleSize("btnCorner", 8))
	addStroke(deckBtn, "panelStroke", 1)

	local rerollBtn = Instance.new("TextButton")
	rerollBtn.Name = "RerollBtn"
	rerollBtn.Size = UDim2.new(0,(Styles and Styles.sizes and Styles.sizes.rerollBtnW) or 140,0,(Styles and Styles.sizes and Styles.sizes.rerollBtnH) or 32)
	rerollBtn.Position = UDim2.new(1,-150,0.5,-16)
	rerollBtn.Text = "リロール"
	rerollBtn.ZIndex = 3
	rerollBtn.Parent = header
	rerollBtn.BackgroundColor3 = _styleColor("warnBtnBg", Color3.fromRGB(180,80,40))
	rerollBtn.TextColor3 = _styleColor("warnBtnText", Color3.fromRGB(255,240,230))
	addCorner(rerollBtn, _styleSize("btnCorner", 8))

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
	deckPanel.BackgroundColor3 = _styleColor("panelBg", Color3.fromRGB(252,250,244))
	deckPanel.BorderSizePixel = 0
	deckPanel.Size = UDim2.new(1,0,0.52,0)
	deckPanel.Position = UDim2.new(0,0,0,0)
	deckPanel.Visible = false
	deckPanel.ZIndex = 2; deckPanel.Parent = right
	addCorner(deckPanel, _styleSize("panelCorner", 10))
	addStroke(deckPanel, "panelStroke", 1)

	local deckTitle = Instance.new("TextLabel")
	deckTitle.Name = "DeckTitle"; deckTitle.BackgroundTransparency = 1
	deckTitle.Size = UDim2.new(1,-10,0,24); deckTitle.Position = UDim2.new(0,6,0,4)
	deckTitle.TextXAlignment = Enum.TextXAlignment.Left
	deckTitle.Text = "現在のデッキ"
	deckTitle.TextSize = (Styles and Styles.fontSizes and Styles.fontSizes.deckTitle) or 18
	deckTitle.TextColor3 = _styleColor("text", Color3.fromRGB(25,25,25))
	deckTitle.ZIndex = 3; deckTitle.Parent = deckPanel

	local deckText = Instance.new("TextLabel")
	deckText.Name = "DeckText"; deckText.BackgroundTransparency = 1
	deckText.Size = UDim2.new(1,-12,1,-30); deckText.Position = UDim2.new(0,6,0,28)
	deckText.TextXAlignment = Enum.TextXAlignment.Left; deckText.TextYAlignment = Enum.TextYAlignment.Top
	deckText.TextWrapped = true; deckText.RichText = false; deckText.Text = ""
	deckText.TextColor3 = _styleColor("text", Color3.fromRGB(25,25,25))
	deckText.ZIndex = 3; deckText.Parent = deckPanel

	local infoPanel = Instance.new("Frame")
	infoPanel.Name = "InfoPanel"
	infoPanel.BackgroundColor3 = _styleColor("panelBg", Color3.fromRGB(252,250,244))
	infoPanel.BorderSizePixel = 0
	infoPanel.Size = UDim2.new(1,0,0.52,0)
	infoPanel.Position = UDim2.new(0,0,0,0)
	infoPanel.Visible = true
	infoPanel.ZIndex = 2; infoPanel.Parent = right
	addCorner(infoPanel, _styleSize("panelCorner", 10))
	addStroke(infoPanel, "panelStroke", 1)

	local infoTitle = Instance.new("TextLabel")
	infoTitle.Name = "InfoTitle"; infoTitle.BackgroundTransparency = 1
	infoTitle.Size = UDim2.new(1,-10,0,24); infoTitle.Position = UDim2.new(0,6,0,4)
	infoTitle.TextXAlignment = Enum.TextXAlignment.Left
	infoTitle.Text = "アイテム情報"
	infoTitle.TextSize = (Styles and Styles.fontSizes and Styles.fontSizes.infoTitle) or 18
	infoTitle.TextColor3 = _styleColor("text", Color3.fromRGB(25,25,25))
	infoTitle.ZIndex = 3; infoTitle.Parent = infoPanel

	local infoText = Instance.new("TextLabel")
	infoText.Name = "InfoText"; infoText.BackgroundTransparency = 1
	infoText.Size = UDim2.new(1,-12,1,-30); infoText.Position = UDim2.new(0,6,0,28)
	infoText.TextXAlignment = Enum.TextXAlignment.Left
	infoText.TextYAlignment = Enum.TextYAlignment.Top
	infoText.TextWrapped = true; infoText.RichText = true
	infoText.Text = "（アイテムにマウスを乗せるか、クリックしてください）"
	infoText.TextColor3 = _styleColor("helpText", Color3.fromRGB(60,40,20))
	infoText.ZIndex = 3; infoText.Parent = infoPanel

	-- 右：サマリ（下段固定）
	local summary = Instance.new("TextLabel")
	summary.Name = "Summary"; summary.BackgroundTransparency = 1
	summary.Size = UDim2.new(1,0,0.48,0); summary.Position = UDim2.new(0,0,0.52,0)
	summary.TextXAlignment = Enum.TextXAlignment.Left; summary.TextYAlignment = Enum.TextYAlignment.Top
	summary.TextWrapped = true; summary.RichText = false; summary.Text = ""
	summary.TextColor3 = _styleColor("text", Color3.fromRGB(25,25,25))
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
	closeBtn.BackgroundColor3 = _styleColor("primaryBtnBg", Color3.fromRGB(190,50,50))
	closeBtn.TextColor3 = _styleColor("primaryBtnText", Color3.fromRGB(255,245,240))
	addCorner(closeBtn, _styleSize("btnCorner", 8))

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

	-- セル生成（クリック＝説明更新→即購入）
	local created = 0
	for _, it in ipairs(items) do
		local btn = Renderer.renderCell(scroll, self._nodes, it, lang, mon, nil)
		if btn then
			self._cellById[tostring(it.id)] = btn
			btn.Activated:Connect(function()
				self:_onSelectItem(it)   -- 右ペイン更新
				self:_attemptBuy(it)     -- 即購入（Signals 経由）
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
		stroke.Color = _styleColor("panelStroke", Color3.fromRGB(180,180,180))
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

-- ★ 即購入（資金チェック→Signals 経由。talismanは自動配置）
function Shop:_attemptBuy(it:any)
	if not it or self._buyBusy then return end

	local lang  = self._lang or "ja"
	local mon   = tonumber((self._payload and (self._payload.mon or self._payload.totalMon)) or 0) or 0
	local price = tonumber(it.price or 0) or 0
	if mon < price then
		local toast = self.deps and self.deps.toast
		if typeof(toast)=="function" then
			local msg = (typeof(Locale.t)=="function" and Locale.t(lang, "SHOP_UI_NOT_ENOUGH_MONEY")) or "お金が足りません"
			toast(msg)
		end
		return
	end

	self._buyBusy = true

	-- talisman は autoPlace（PlaceOnSlot はサービスの責務）
	if tostring(it.category) == "talisman" and it.talismanId then
		self:autoPlace(it.talismanId, it)
	else
		-- Remotes直叩き禁止：ClientSignals 経由で Wires が送る
		local ok = pcall(function()
			if ClientSignals and ClientSignals.BuyRequested and typeof(ClientSignals.BuyRequested.Fire)=="function" then
				ClientSignals.BuyRequested:Fire(it)
			elseif self.deps and self.deps.signals and self.deps.signals.BuyRequested then
				self.deps.signals.BuyRequested:Fire(it)
			else
				error("ClientSignals.BuyRequested not available")
			end
		end)
		if not ok then
			LOG.warn("[ShopView] BuyRequested signal not available; cannot buy id=%s", tostring(it.id))
		end
	end

	-- ハイライト解除（サーバ反映で在庫更新見込み）
	if self._selectedId and self._cellById[self._selectedId] then
		_applyCellSelected(self._cellById[self._selectedId], false)
	end
	self._selectedId = nil

	task.delay(0.25, function() self._buyBusy = false end)
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
	return ShopWires.attachRemotes(self, remotes, router)
end

--============== auto-place（購入時に使用） ==============
local function _findFirstEmpty(self)
	local t = self:_snapBoard()
	local unlocked = tonumber(t.unlocked or 0) or 0
	local slots = t.slots or {}
	for i=1, math.min(unlocked, 6) do if slots[i] == nil then return i end end
	return nil
end

function Shop:autoPlace(talismanId: string, item: any?)
	if not talismanId or talismanId == "" then
		LOG.warn("[ShopView] autoPlace: invalid talismanId"); return
	end
	local idx = _findFirstEmpty(self)
	if not idx then
		local toast = self.deps and self.deps.toast
		if typeof(toast) == "function" then toast(Locale.t(self._lang, "SHOP_UI_NO_EMPTY_SLOT")) end
		LOG.info("[ShopView] autoPlace aborted: no empty slot"); return
	end
	if item and item.id ~= nil then
		-- 在庫隠しを行う場合はここで
	end
	LOG.info("[ShopView] auto-place index=%d id=%s", idx, tostring(talismanId))

	local placeRE = RS:WaitForChild("Remotes", 5) and RS.Remotes:FindFirstChild("PlaceOnSlot")
	if placeRE and placeRE:IsA("RemoteEvent") then
		placeRE:FireServer(idx, talismanId)
	else
		LOG.warn("[ShopView] PlaceOnSlot RemoteEvent not available; skipped")
	end
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
