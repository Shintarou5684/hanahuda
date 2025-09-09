-- StarterPlayerScripts/UI/screens/ShopScreen.lua
-- v0.9.4-deckview
--  - 「デッキを見る」ボタンを追加（ヘッダー右）
--  - 右ペイン上部に現在デッキパネルをトグル表示
--  - サーバ payload の deck/currentDeck（codes 配列）を表示
--  - 既存の“毎回フル再描画”方針は維持

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

	lang: string?,   -- "ja"|"jp"|"en"
	notice: string?,

	-- ★追加（どちらでも可）
	deck: any?,          -- {codes={...}} or array
	currentDeck: any?,   -- {codes={...}} or array
}

--==================================================
-- utils
--==================================================

local function normLang(s: string?): string
	if s == "en" then return "en" end
	if s == "ja" or s == "jp" then return "ja" end
	return "ja"
end

local function kitoKanji(effectId: string?): string?
	if not effectId then return nil end
	local key = effectId:match("^kito_(.+)$")
	if not key then return nil end
	local map = {
		ushi="丑", tora="寅", tori="酉",
		ne="子", u="卯", tatsu="辰", mi="巳",
		uma="午", saru="申", inu="戌", i="亥", hitsuji="未",
	}
	return map[key]
end

local function itemTitle(it: any): string
	return kitoKanji(it.effect or it.id) or it.name or it.id or "???"
end

local function itemDesc(it: any, lang: string): string
	if not it then return "" end
	if lang == "en" then
		return (it.descEN or it.descEn or it.descENUS or it.name or it.id or "")
	else
		return (it.descJP or it.descJa or it.descJp or it.name or it.id or "")
	end
end

local function fmtPrice(n: number?): string
	return ("%d 文"):format(tonumber(n or 0))
end

-- payload からデッキの codes 配列を吸い出し、ソート＆カウント文字列を返す
local function extractDeckCodes(p: Payload): ({string}, string)
	local raw = p.currentDeck or p.deck
	local codes: {string} = {}

	if typeof(raw) == "table" then
		-- 1) { codes = {...}, count = n } 形式
		if typeof(raw.codes) == "table" then
			for _, c in ipairs(raw.codes) do
				table.insert(codes, tostring(c))
			end
		else
			-- 2) 単純な配列形式
			for _, c in ipairs(raw) do
				table.insert(codes, tostring(c))
			end
		end
	end

	-- 表示を安定させるためソート
	table.sort(codes, function(a,b) return tostring(a) < tostring(b) end)

	-- 集計（"0101 x2, 0103 x1, ..."）
	local countMap: {[string]: number} = {}
	for _, c in ipairs(codes) do
		countMap[c] = (countMap[c] or 0) + 1
	end
	local parts = {}
	for _, c in ipairs(codes) do
		if countMap[c] then
			table.insert(parts, (countMap[c] > 1) and (("%s x%d"):format(c, countMap[c])) or c)
			countMap[c] = nil -- 一度だけ出力
		end
	end

	return codes, table.concat(parts, ", ")
end

--==================================================
-- main
--==================================================

function Shop.new(deps)
	local self = setmetatable({}, Shop)
	self.deps = deps
	self._payload = nil
	self._closing = false
	self._buyBusy = false
	self._rerollBusy = false
	self._lang = nil
	self._deckOpen = false -- ★デッキパネルのトグル状態

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

	-- ★デッキ表示ボタン
	local deckBtn = Instance.new("TextButton")
	deckBtn.Name = "DeckBtn"
	deckBtn.Size = UDim2.new(0,140,0,32)
	deckBtn.Position = UDim2.new(1,-300,0.5,-16) -- Reroll の左
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

	-- 左：スクロール
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

	-- 右：デッキパネル（上）＋ サマリ（下）
	local deckPanel = Instance.new("Frame")
	deckPanel.Name = "DeckPanel"
	deckPanel.BackgroundColor3 = Color3.fromRGB(255,255,255)
	deckPanel.BorderColor3 = Color3.fromRGB(220,220,220)
	deckPanel.Size = UDim2.new(1,0,0.52,0)
	deckPanel.Position = UDim2.new(0,0,0,0)
	deckPanel.Visible = false -- 初期は閉じる
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

	local info = Instance.new("TextLabel")
	info.Name = "Info"
	info.BackgroundColor3 = Color3.fromRGB(255,255,255)
	info.BorderColor3 = Color3.fromRGB(220,220,220)
	info.Size = UDim2.new(1,0,0.52,0)
	info.Position = UDim2.new(0,0,0,0)
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top
	info.TextWrapped = true
	info.RichText = true
	info.Text = ""
	info.ZIndex = 1
	info.Parent = right

	local summary = Instance.new("TextLabel")
	summary.Name = "Summary"
	summary.BackgroundTransparency = 1
	summary.Size = UDim2.new(1,0,0.48,-8)
	summary.Position = UDim2.new(0,0,0.52,8)
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
		print("[ShopScreen] Reroll click")
		self.deps.remotes.ShopReroll:FireServer()
		task.delay(rerollBusyDebounce, function() self._rerollBusy = false end)
	end)

	deckBtn.Activated:Connect(function()
		self._deckOpen = not self._deckOpen
		self:_render() -- 表示/非表示を即反映
	end)

	self._nodes = {
		title = title, rerollBtn = rerollBtn, deckBtn = deckBtn,
		scroll = scroll, grid = grid,
		info = info, summary = summary,
		deckPanel = deckPanel, deckTitle = deckTitle, deckText = deckText,
	}
	return self
end

--==================================================
-- public (必ず描画)
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

function Shop:hide()
	self.gui.Enabled = false
end

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
	local scroll = self._nodes.scroll

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
	btn.Parent = scroll

	local function doBuy()
		if self._buyBusy then return end
		if not (self.deps and self.deps.remotes and self.deps.remotes.BuyItem) then return end
		self._buyBusy = true
		print("[ShopScreen] Buy click:", it.id, "price=", it.price)
		self.deps.remotes.BuyItem:FireServer(it.id)
		task.delay(0.25, function() self._buyBusy = false end)
	end

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
		self._nodes.info.Text = table.concat(lines, "\n")
	end
	btn.MouseEnter:Connect(showDesc)
	priceBtn.MouseEnter:Connect(showDesc)

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

	print(("[ShopScreen] _render begin | items=%d mon=%s lang=%s deckOpen=%s")
		:format(#items, tostring(mon), tostring(lang), tostring(self._deckOpen)))

	-- タイトル・ボタン
	if self._nodes.title then
		self._nodes.title.Text = (lang == "en") and "Shop (MVP)" or "屋台（MVP）"
	end
	if self._nodes.deckBtn then
		self._nodes.deckBtn.Text = (lang=="en")
			and (self._deckOpen and "Hide Deck" or "View Deck")
			or  (self._deckOpen and "デッキを隠す" or "デッキを見る")
	end
	if self._nodes.rerollBtn then
		self._nodes.rerollBtn.Text = ((lang=="en") and "Reroll (-%d)" or "リロール（-%d 文）"):format(rerollCost)
		local can = true
		if p.canReroll == false then can=false end
		if remaining ~= nil and remaining <= 0 then can=false end
		if tonumber(mon or 0) < rerollCost then can=false end
		if self._rerollBusy then can=false end
		self._nodes.rerollBtn.Active = can
		self._nodes.rerollBtn.TextTransparency = can and 0 or 0.4
		self._nodes.rerollBtn.BackgroundTransparency = can and 0 or 0.2
	end

	-- 右ペイン：サマリ
	local hasResult = (p.seasonSum ~= nil) or (p.target ~= nil) or (p.rewardMon ~= nil)
	local resultLine = ""
	if hasResult then
		if lang == "en" then
			resultLine = ("Cleared! Total:%d / Target:%d\nReward: %d mon (Have: %d)\n\n"):format(
				tonumber(p.seasonSum or 0), tonumber(p.target or 0),
				tonumber(p.rewardMon or 0), tonumber(p.totalMon or mon or 0))
		else
			resultLine = ("達成！ 合計:%d / 目標:%d\n報酬：%d 文（所持：%d 文）\n\n"):format(
				tonumber(p.seasonSum or 0), tonumber(p.target or 0),
				tonumber(p.rewardMon or 0), tonumber(p.totalMon or mon or 0))
		end
	end

	local rerollLine
	if lang == "en" then
		rerollLine = (remaining ~= nil)
			and ("Rerolls left: %d / Cost: %d"):format(remaining, rerollCost)
			or  ("Rerolls: unlimited / Cost: %d"):format(rerollCost)
	else
		rerollLine = (remaining ~= nil)
			and ("リロール: 残り %d 回 / 1回 %d 文"):format(remaining, rerollCost)
			or  ("リロール: 無制限 / 1回 %d 文"):format(rerollCost)
	end

	if self._nodes.summary then
		self._nodes.summary.Text = table.concat({
			resultLine,
			(lang=="en") and ("Items: %d"):format(#items) or ("商品数: %d 点"):format(#items),
			(lang=="en") and ("Money: %d mon"):format(mon) or ("所持文: %d 文"):format(mon),
			rerollLine,
			"",
			(lang=="en") and "Hover a card to see details. Click to buy."
			               or "カードにカーソルで説明、クリックで購入。",
		}, "\n")
	end

	-- ★デッキパネルの内容
	do
		local panel = self._nodes.deckPanel
		local title = self._nodes.deckTitle
		local text  = self._nodes.deckText
		if panel and title and text then
			panel.Visible = self._deckOpen
			local codes, listText = extractDeckCodes(p)

			if lang == "en" then
				title.Text = ("Current Deck (%d cards)"):format(#codes)
				text.Text  = (#codes > 0) and listText or "(no cards)"
			else
				title.Text = ("現在のデッキ（%d 枚）"):format(#codes)
				text.Text  = (#codes > 0) and listText or "(カード無し)"
			end

			-- デッキパネルが開いている間は、背面の info は隠す
			if self._nodes.info then
				self._nodes.info.Visible = not self._deckOpen
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

	-- Info 初期文面（デッキパネルが閉じている時のみ）
	if self._nodes.info and not self._deckOpen then
		if p.notice and p.notice ~= "" then
			self._nodes.info.Text = p.notice
		elseif items[1] then
			self._nodes.info.Text = (lang == "en")
				and "Hover a card to see details."
				or  "カードにカーソルを合わせると効果説明が表示されます。"
		else
			self._nodes.info.Text = (lang == "en") and "No items." or "商品がありません。"
		end
	end

	print("[ShopScreen] _render end")
end

return Shop
