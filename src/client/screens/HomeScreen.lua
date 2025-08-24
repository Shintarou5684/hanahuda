-- HomeScreen.lua  v0.8
return function(deps)
	local self = {}
	local g = Instance.new("ScreenGui")
	g.Name = "HomeScreen"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 5; g.Enabled = true
	self.gui = g

	local root = Instance.new("Frame")
	root.Name = "Root"; root.Parent = g; root.Size = UDim2.fromScale(1,1)
	root.BackgroundColor3 = Color3.fromRGB(245,249,255)

	local title = Instance.new("TextLabel")
	title.Parent = root; title.BackgroundTransparency = 1
	title.Size = UDim2.new(1,0,0,60); title.Position = UDim2.new(0,0,0,40)
	title.Text = "花札 × 倍率ローグ"; title.Font = Enum.Font.GothamBold; title.TextScaled = true

	local menu = Instance.new("Frame")
	menu.Parent = root; menu.Size = UDim2.new(0, 360, 0, 300); menu.Position = UDim2.new(0.5,0,0.5,0); menu.AnchorPoint = Vector2.new(0.5,0.5)
	menu.BackgroundTransparency = 1
	local layout = Instance.new("UIListLayout", menu)
	layout.FillDirection = Enum.FillDirection.Vertical; layout.Padding = UDim.new(0, 12); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local function makeBtn(t, onClick)
		local b = Instance.new("TextButton"); b.Parent = menu
		b.Size = UDim2.new(1, 0, 0, 48); b.Text = t; b.AutoButtonColor = true
		b.BackgroundColor3 = Color3.fromRGB(255,255,255); b.BorderSizePixel = 1
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = b
		if onClick then b.MouseButton1Click:Connect(onClick) end
		return b
	end

	makeBtn("NEW GAME", function()
		if deps and deps.ReqStartNewRun then deps.ReqStartNewRun:FireServer() end
	end)
	makeBtn("神社（SHRINE）", function()
		if deps and deps.showShrine then deps.showShrine() end
	end)
	makeBtn("持ち物（STUB）", function() end)
	makeBtn("設定（STUB）", function() end)
	makeBtn("CONTINUE（未実装）", function()
		if deps and deps.ReqContinueRun then deps.ReqContinueRun:FireServer() end
	end)

	function self:show()
		self.gui.Enabled = true
		if self.gui.Parent ~= deps.playerGui then self.gui.Parent = deps.playerGui end
	end
	function self:hide() self.gui.Enabled = false end
	return self
end
