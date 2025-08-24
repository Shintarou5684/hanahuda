-- ShopScreen.lua
-- 屋台モーダル（在庫表示／購入／リロール／閉じる）

local Shop = {}
Shop.__index = Shop

local function makeLabel(parent, text, size, pos, anchor)
	local l = Instance.new("TextLabel")
	l.Parent = parent
	l.BackgroundTransparency = 1
	l.Text = text or ""
	l.TextScaled = true
	l.Size = size or UDim2.new(0,100,0,28)
	l.Position = pos or UDim2.new(0,0,0,0)
	if anchor then l.AnchorPoint = anchor end
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	return l
end

function Shop.new(deps)
	local self = setmetatable({}, Shop)
	self.deps = deps
	self._conns = {}

	local g = Instance.new("ScreenGui")
	g.Name = "ShopScreen"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 50; g.Enabled = true
	self.gui = g

	local root = Instance.new("Frame")
	root.Name = "Root"; root.Parent = g
	root.Size = UDim2.fromScale(1,1)
	root.BackgroundColor3 = Color3.fromRGB(0,0,0)
	root.BackgroundTransparency = 0.35
	root.Visible = false
	self.root = root

	local modal = Instance.new("Frame")
	modal.Name = "Modal"; modal.Parent = root
	modal.Size = UDim2.new(0, 640, 0, 420)
	modal.Position = UDim2.new(0.5, 0, 0.5, 0)
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.BackgroundColor3 = Color3.fromRGB(255,255,255)
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,16); corner.Parent = modal

	local title = makeLabel(modal, "屋台", UDim2.new(1,-20,0,44), UDim2.new(0.5,0,0,12), Vector2.new(0.5,0))
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Font = Enum.Font.GothamBold

	local list = Instance.new("Frame"); list.Parent = modal
	list.Name = "List"; list.Size = UDim2.new(1,-40,0,260); list.Position = UDim2.new(0.5,0,0,64)
	list.AnchorPoint = Vector2.new(0.5,0); list.BackgroundTransparency = 1
	local layout = Instance.new("UIListLayout"); layout.Parent = list
	layout.FillDirection = Enum.FillDirection.Vertical; layout.Padding = UDim.new(0,8)

	local footer = Instance.new("Frame"); footer.Parent = modal
	footer.Name="Footer"; footer.Size = UDim2.new(1,-40,0,56); footer.Position = UDim2.new(0.5,0,1,-64); footer.AnchorPoint = Vector2.new(0.5,1)
	footer.BackgroundTransparency = 1
	local reroll = Instance.new("TextButton"); reroll.Parent = footer
	reroll.Text = "リロール"; reroll.TextScaled = true; reroll.Size = UDim2.new(0,180,1,0); reroll.Position = UDim2.new(0,0,0,0)
	local close  = Instance.new("TextButton"); close.Parent = footer
	close.Text = "屋台を閉じる"; close.TextScaled = true; close.Size = UDim2.new(0,220,1,0); close.Position = UDim2.new(1,-220,0,0); close.AnchorPoint = Vector2.new(1,0)

	local money = makeLabel(modal, "文:-- / 両:--", UDim2.new(1,-40,0,32), UDim2.new(0.5,0,1,-24), Vector2.new(0.5,1))
	money.TextXAlignment = Enum.TextXAlignment.Center

	local function clearList()
		for _,c in ipairs(list:GetChildren()) do
			if c:IsA("Frame") or c:IsA("TextLabel") or c:IsA("TextButton") then c:Destroy() end
		end
	end

	local function makeRow(item)
		local row = Instance.new("Frame"); row.Parent = list
		row.Size = UDim2.new(1,0,0,44); row.BackgroundTransparency = 1
		local name = makeLabel(row, tostring(item.name or "不明"), UDim2.new(0.6,0,1,0), UDim2.new(0,0,0,0))
		name.TextXAlignment = Enum.TextXAlignment.Left
		local price = makeLabel(row, ("価格: %s文"):format(tostring(item.price or "?")), UDim2.new(0.2,0,1,0), UDim2.new(0.62,0,0,0))
		price.TextXAlignment = Enum.TextXAlignment.Left
		local buy = Instance.new("TextButton"); buy.Parent = row
		buy.Text = "購入"; buy.TextScaled = true; buy.Size = UDim2.new(0.18,0,1,0); buy.Position = UDim2.new(0.82,0,0,0)
		buy.MouseButton1Click:Connect(function()
			if self.deps and self.deps.BuyItem then
				local id = item.id or item.itemId or item.name
				self.deps.BuyItem:FireServer(id)
			end
		end)
	end

	-- payload: { stock=[{id,name,price,...}], mon=, bank= }
	function Shop:setData(payload)
		local stock = (type(payload)=="table" and payload.stock) or {}
		local mon   = (type(payload)=="table" and payload.mon) or 0
		local bank  = (type(payload)=="table" and payload.bank) or 0
		clearList()
		for _,it in ipairs(stock) do makeRow(it) end
		money.Text = ("文:%d / 両:%d"):format(tonumber(mon) or 0, tonumber(bank) or 0)
	end
	self.setData = function(_, payload) self:setData(payload) end

	-- ボタン
	reroll.MouseButton1Click:Connect(function()
		if self.deps and self.deps.ShopReroll then self.deps.ShopReroll:FireServer() end
	end)
	close.MouseButton1Click:Connect(function()
		if self.deps and self.deps.ShopDone then self.deps.ShopDone:FireServer() end
		self:hide()
		if self.deps and self.deps.showRun then self.deps.showRun() end
	end)

	return self
end

function Shop:show(payload)
	self.root.Visible = true
	if payload then self:setData(payload) end
end

function Shop:hide()
	self.root.Visible = false
end

function Shop:destroy()
	if self.gui then self.gui:Destroy() end
end

return Shop
