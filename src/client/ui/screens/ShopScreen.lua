-- v0.9.4-deckview2-fix
--  - ルア構文修正（三項演算子の除去）
--  - summary の :format 誤用修正
--  - 既存機能はそのまま

local Shop = {}
Shop.__index = Shop

export type Payload = {
	items: {any}?,
	stock: {any}?,
	mon: number?,
	totalMon: number?,
	rerollCost: number?,
	remainingRerolls: number?, -- nil=無制限
	canReroll: boolean?,
	seasonSum: number?,
	target: number?,
	rewardMon: number?,
	lang: string?,   -- "ja"/"en"
	notice: string?,
	currentDeck: any?,  -- {v=2, codes, histogram, entries[{code,kind}], count}
}

--==================================================
-- utils
--==================================================

local function normLang(s: string?): string
	if s == "en" then return "en" end
	if s == "ja" or s == "jp" then return "ja" end
	return "ja"
end

local function fmtPrice(n: number?): string
	return ("%d 文"):format(tonumber(n or 0))
end

local function itemTitle(it: any): string
	if it and it.name then return tostring(it.name) end
	return tostring(it and it.id or "???")
end

local function itemDesc(it: any, lang: string): string
	if not it then return "" end
	if lang == "en" then
		return (it.descEN or it.descEn or it.name or it.id or "")
	else
		return (it.descJP or it.descJa or it.name or it.id or "")
	end
end

-- payload.currentDeck から codes を抽出して "0101 x2, 0103, ..." を作る
local function deckListFromSnapshot(snap: any): (integer, string)
	if typeof(snap) ~= "table" then return 0, "" end
	local countMap: {[string]: number} = {}
	local order = {}
	local entries = snap.entries
	if typeof(entries) == "table" and #entries > 0 then
		for _, e in ipairs(entries) do
			local code = tostring(e.code)
			if not countMap[code] then table.insert(order, code) end
			countMap[code] = (countMap[code] or 0) + 1
		end
	else
		for _, code in ipairs(snap.codes or {}) do
			code = tostring(code)
			if not countMap[code] then table.insert(order, code) end
			countMap[code] = (countMap[code] or 0) + 1
		end
	end
	table.sort(order, function(a,b) return a < b end)
	local parts = {}
	for _, code in ipairs(order) do
		local n = countMap[code] or 0
		table.insert(parts, (n > 1) and ("%s x%d"):format(code, n) or code)
	end
	return tonumber(snap.count or 0) or 0, table.concat(parts, ", ")
end

--==================================================
-- class
--==================================================

function Shop.new(deps)
	local self = setmetatable({}, Shop)
	self.deps = deps
	self._payload = nil
	self._closing = false
	self._buyBusy = false
	self._rerollBusy = false
	self._lang = nil
	self._deckOpen = false

	-- root
	local g = Instance.new("ScreenGui")
	g.Name = "ShopScreen"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 50
	g.Enabled = false
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self.gui = g

	-- modal
	local modal = Instance.new("Frame")
	modal.Name = "Modal"
	modal.AnchorPoint = Vector2.new(0.5,0.5)
	modal.Position = UDim2.new(0.5,0,0.5,0)
	modal.Size = UDim2.new(0.82,0,0.72,0)
	modal.BackgroundColor3 = Color3.fromRGB(245,245,245)
	modal.BorderSizePixel = 0
	modal.ZIndex = 1
	modal.Parent = g

	-- header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundColor3 = Color3.fromRGB(230,230,230)
	header.BorderSizePixel = 0
	header.Size = UDim2.new(1,0,0,48)
	header.ZIndex = 2
	header.Parent = modal

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1,-20,1,0)
	title.Position = UDim2.new(0,10,0,0)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "屋台（MVP）"
	title.TextSize = 20
	title.ZIndex = 3
	title.Parent = header

	local deckBtn = Instance.new("TextButton")
	deckBtn.Name = "DeckBtn"
	deckBtn.Size = UDim2.new(0,140,0,32)
	deckBtn.Position = UDim2.new(1,-300,0.5,-16)
	deckBtn.Text = "デッキを見る"
	deckBtn.ZIndex = 3
	deckBtn.Parent = header

	local rerollBtn = Instance.new("TextButton")
	rerollBtn.Name = "RerollBtn"
	rerollBtn.Size = UDim2.new(0,140,0,32)
	rerollBtn.Position = UDim2.new(1,-150,0.5,-16)
	rerollBtn.Text = "リロール"
	rerollBtn.ZIndex = 3
	rerollBtn.Parent = header

	-- body
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1,-20,1,-48-64)
	body.Position = UDim2.new(0,10,0,48)
	body.ZIndex = 1
	body.Parent = modal

	local left = Instance.new("Frame")
	left.Name = "Left"
	left.BackgroundTransparency = 1
	left.Size = UDim2.new(0.62,0,1,0)
	left.ZIndex = 1
	left.Parent = body

	local right = Instance.new("Frame")
	right.Name = "Right"
	right.BackgroundTransparency = 1
	right.Size = UDim2.new(0.38,0,1,0)
	right.Position = UDim2.new(0.62,0,0,0)
	right.ZIndex = 1
	right.Parent = body

	-- 左スクロール
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Size = UDim2.new(1,0,1,0)
	scroll.CanvasSize = UDim2.new(0,0,0,0)
	scroll.ScrollBarThickness = 8
	scroll.BackgroundTransparency = 1
	scroll.ZIndex = 2
	scroll.Active = true
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = left

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(96, 144)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroll

	-- 右：デッキパネル
	local deckPanel = Instance.new("Frame")
	deckPanel.Name = "DeckPanel"
	deckPanel.BackgroundColor3 = Color3.fromRGB(255,255,255)
	deckPanel.BorderColor3 = Color3.fromRGB(220,220,220)
	deckPanel.Size = UDim2.new(1,0,0.52,0)
	deckPanel.Position = UDim2.new(0,0,0,0)
	deckPanel.Visible = false
	deckPanel.ZIndex = 2
	deckPanel.Parent = right

	local deckTitle = Instance.new("TextLabel")
	deckTitle.Name = "DeckTitle"
	deckTitle.BackgroundTransparency = 1
	deckTitle.Size = UDim2.new(1,-10,0,24)
	deckTitle.Position = UDim2.new(0,6,0,4)
	deckTitle.TextXAlignment = Enum.TextXAlignment.Left
	deckTitle.Text = "現在のデッキ"
	deckTitle.TextSize = 18
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
	deckText.ZIndex = 3
	deckText.Parent = deckPanel

	-- 右：サマリ
	local summary = Instance.new("TextLabel")
	summary.Name = "Summary"
	summary.BackgroundTransparency = 1
	summary.Size = UDim2.new(1,0,1,0)
	summary.Position = UDim2.new(0,0,0,0)
	summary.TextXAlignment = Enum.TextXAlignment.Left
	summary.TextYAlignment = Enum.TextYAlignment.Top
	summary.TextWrapped = true
	summary.Text = ""
	summary.ZIndex = 1
	summary.Parent = right

	-- footer
	local footer = Instance.new("Frame")
	footer.Name = "Footer"
	footer.BackgroundTransparency = 1
	footer.Size = UDim2.new(1,0,0,64)
	footer.Position = UDim2.new(0,0,1,-64)
	footer.ZIndex = 1
	footer.Parent = modal

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0,260,0,44)
	closeBtn.Position = UDim2.new(0.5,-130,0.5,-22)
	closeBtn.Text = "屋台を閉じて次の季節へ"
	closeBtn.ZIndex = 2
	closeBtn.Parent = footer

	-- events
	closeBtn.Activated:Connect(function()
		if self._closing then return end
		self._closing = true
		self:hide()
		if self.deps and self.deps.toast then
			self.deps.toast("屋台を閉じました。次の季節へ。", 2)
		end
		if self.deps and self.deps.remotes and self.deps.remotes.ShopDone then
			self.deps.remotes.ShopDone:FireServer()
		end
		task.delay(0.2, function() self._closing = false end)
	end)

	local rerollBusyDebounce = 0.3
	rerollBtn.Activated:Connect(function()
		if self._rerollBusy then return end
		if not (self.deps and self.deps.remotes and self.deps.remotes.ShopReroll) then return end
		self._rerollBusy = true
		self.deps.remotes.ShopReroll:FireServer()
		task.delay(rerollBusyDebounce, function() self._rerollBusy = false end)
	end)

	deckBtn.Activated:Connect(function()
		self._deckOpen = not self._deckOpen
		self:_render()
	end)

	self._nodes = {
		title = title, rerollBtn = rerollBtn, deckBtn = deckBtn,
		scroll = scroll, grid = grid,
		summary = summary,
		deckPanel = deckPanel, deckTitle = deckTitle, deckText = deckText,
	}
	return self
end

--==================================================
-- public
--==================================================

function Shop:setData(payload: Payload)
	self._payload = payload
	self:_render()
end

function Shop:show(payload: Payload?)
	if payload then self._payload = payload end
	self.gui.Enabled = true
	self:_render()
end

function Shop:hide() self.gui.Enabled = false end

function Shop:update(payload: Payload?)
	if payload then self._payload = payload end
	self:_render()
end

function Shop:setLang(lang: string?)
	self._lang = normLang(lang)
	self:_render()
end

--==================================================
-- cells
--==================================================

function Shop:_createCard(it: any, lang: string, mon: number)
	local btn = Instance.new("TextButton")
	btn.Name = it.id or "Item"
	btn.Text = itemTitle(it)
	btn.TextSize = 28
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.fromRGB(30,30,30)
	btn.BackgroundColor3 = Color3.fromRGB(250,250,250)
	btn.BorderColor3 = Color3.fromRGB(210,210,210)
	btn.AutoButtonColor = true
	btn.ZIndex = 10
	btn.Parent = self._nodes.scroll

	local priceBtn = Instance.new("TextButton")
	priceBtn.Name = "Price"
	priceBtn.AutoButtonColor = false
	priceBtn.BackgroundColor3 = Color3.fromRGB(255,240,200)
	priceBtn.BorderColor3 = Color3.fromRGB(210,180,120)
	priceBtn.Size = UDim2.new(1,0,0,20)
	priceBtn.Position = UDim2.new(0,0,1,-20)
	priceBtn.Text = fmtPrice(it.price)
	priceBtn.TextSize = 14
	priceBtn.ZIndex = 11
	priceBtn.Selectable = false
	priceBtn.Parent = btn

	local affordable = (tonumber(mon or 0) >= tonumber(it.price or 0))
	if not affordable then
		priceBtn.Text = fmtPrice(it.price) .. ((lang=="en") and " (insufficient)" or "（不足）")
	end

	local function showDesc()
		local desc = itemDesc(it, lang)
		local lines = {
			("<b>%s</b>"):format(it.name or itemTitle(it)),
			("カテゴリ: %s"):format(it.category or "-"),
			("価格: %s"):format(fmtPrice(it.price)),
			"",
			(desc ~= "" and desc or ((lang=="en") and "(no description)" or "(説明なし)")),
		}
		self._nodes.summary.Text = table.concat(lines, "\n")
	end
	btn.MouseEnter:Connect(showDesc)
	priceBtn.MouseEnter:Connect(showDesc)

	local function doBuy()
		if self._buyBusy then return end
		if not (self.deps and self.deps.remotes and self.deps.remotes.BuyItem) then return end
		self._buyBusy = true
		self.deps.remotes.BuyItem:FireServer(it.id)
		task.delay(0.25, function() self._buyBusy = false end)
	end
	btn.Activated:Connect(doBuy)
	priceBtn.Activated:Connect(doBuy)
end

--==================================================
-- render
--==================================================

function Shop:_render()
	local p: Payload = self._payload or {}
	local items = p.items or p.stock or {}
	local lang = self._lang or normLang(p.lang)
	local mon = tonumber(p.mon or p.totalMon or 0)
	local rerollCost = tonumber(p.rerollCost or 1)
	local remainingRaw = p.remainingRerolls
	local remaining = (remainingRaw ~= nil) and tonumber(remainingRaw) or nil

	-- タイトル・ボタン（Lua で if/else）
	if self._nodes.title then
		if lang == "en" then
			self._nodes.title.Text = "Shop (MVP)"
		else
			self._nodes.title.Text = "屋台（MVP）"
		end
	end
	if self._nodes.deckBtn then
		if lang == "en" then
			self._nodes.deckBtn.Text = (self._deckOpen and "Hide Deck" or "View Deck")
		else
			self._nodes.deckBtn.Text = (self._deckOpen and "デッキを隠す" or "デッキを見る")
		end
	end
	if self._nodes.rerollBtn then
		if lang == "en" then
			self._nodes.rerollBtn.Text = ("Reroll (-%d)"):format(rerollCost)
		else
			self._nodes.rerollBtn.Text = ("リロール（-%d 文）"):format(rerollCost)
		end
		local can = true
		if p.canReroll == false then can=false end
		if remaining ~= nil and remaining <= 0 then can=false end
		if tonumber(mon or 0) < rerollCost then can=false end
		if self._rerollBusy then can=false end
		self._nodes.rerollBtn.Active = can
		self._nodes.rerollBtn.TextTransparency = can and 0 or 0.4
		self._nodes.rerollBtn.BackgroundTransparency = can and 0 or 0.2
	end

	-- 右：configSnapshot の表示
	do
		local panel = self._nodes.deckPanel
		local title = self._nodes.deckTitle
		local text  = self._nodes.deckText
		if panel and title and text then
			panel.Visible = self._deckOpen
			local n, lst = deckListFromSnapshot(p.currentDeck)
			if lang == "en" then
				title.Text = ("Current Deck (%d cards)"):format(n)
				text.Text  = (n > 0) and lst or "(no cards)"
			else
				title.Text = ("現在のデッキ（%d 枚）"):format(n)
				text.Text  = (n > 0) and lst or "(カード無し)"
			end
		end
	end

	-- 左グリッド：全消し → 全作り直し
	local scroll = self._nodes.scroll
	for _, ch in ipairs(scroll:GetChildren()) do
		if ch:IsA("GuiObject") and ch ~= self._nodes.grid then
			ch:Destroy()
		end
	end
	for _, it in ipairs(items) do
		self:_createCard(it, lang, mon)
	end

	-- CanvasSize 調整
	task.defer(function()
		local gridObj = self._nodes.grid
		if not gridObj then return end
		local frameW = scroll.AbsoluteSize.X
		local cellW = gridObj.CellSize.X.Offset + gridObj.CellPadding.X.Offset
		local perRow = math.max(1, math.floor(frameW / math.max(1, cellW)))
		local rows = math.ceil(#items / perRow)
		local cellH = gridObj.CellSize.Y.Offset + gridObj.CellPadding.Y.Offset
		local needed = rows * cellH + 8
		scroll.CanvasSize = UDim2.new(0, 0, 0, needed)
	end)

	-- サマリ：基本情報
	local s = {}
	if p.seasonSum ~= nil or p.target ~= nil or p.rewardMon ~= nil then
		if lang == "en" then
			table.insert(s, ("Cleared! Total:%d / Target:%d\nReward: %d mon (Have: %d)\n")
				:format(tonumber(p.seasonSum or 0), tonumber(p.target or 0),
				        tonumber(p.rewardMon or 0), tonumber(p.totalMon or mon or 0)))
		else
			table.insert(s, ("達成！ 合計:%d / 目標:%d\n報酬：%d 文（所持：%d 文）\n")
				:format(tonumber(p.seasonSum or 0), tonumber(p.target or 0),
				        tonumber(p.rewardMon or 0), tonumber(p.totalMon or mon or 0)))
		end
	end
	if lang == "en" then
		table.insert(s, ("Items: %d"):format(#items))
		table.insert(s, ("Money: %d mon"):format(mon))
		if remaining ~= nil then
			table.insert(s, ("Rerolls left: %d / Cost: %d"):format(remaining, rerollCost))
		else
			table.insert(s, ("Rerolls: unlimited / Cost: %d"):format(rerollCost))
		end
	else
		table.insert(s, ("商品数: %d 点"):format(#items))
		table.insert(s, ("所持文: %d 文"):format(mon))
		if remaining ~= nil then
			table.insert(s, ("リロール: 残り %d 回 / 1回 %d 文"):format(remaining, rerollCost))
		else
			table.insert(s, ("リロール: 無制限 / 1回 %d 文"):format(rerollCost))
		end
	end
	self._nodes.summary.Text = table.concat(s, "\n")
end

return Shop
