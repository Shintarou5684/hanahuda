-- ShopScreen.lua  v0.8 minimal
return function(deps)
	local self = {}
	local g = Instance.new("ScreenGui")
	g.Name = "ShopScreen"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 20; g.Enabled = true
	self.gui = g

	local frame = Instance.new("Frame")
	frame.Name = "Root"; frame.Parent = g; frame.Size = UDim2.fromScale(1,1)
	frame.BackgroundColor3 = Color3.fromRGB(250,248,240)

	local title = Instance.new("TextLabel")
	title.Parent = frame; title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -20, 0, 40); title.Position = UDim2.new(0,10,0,10)
	title.TextXAlignment = Enum.TextXAlignment.Left; title.TextScaled = true
	title.Text = "屋台（WIP）"

	-- 閉じるボタン（次の季節へ）
	local close = Instance.new("TextButton")
	close.Parent = frame; close.Size = UDim2.new(0, 200, 0, 48); close.Position = UDim2.new(1,-210,1,-58)
	close.Text = "屋台を閉じる →"; close.AutoButtonColor = true
	close.BackgroundColor3 = Color3.fromRGB(255,255,255); close.BorderSizePixel = 1

	close.MouseButton1Click:Connect(function()
		if deps and deps.ShopDone then deps.ShopDone:FireServer() end
	end)

	function self:show(payload)
		self.gui.Enabled = true
		if self.gui.Parent ~= deps.playerGui then self.gui.Parent = deps.playerGui end
	end
	function self:hide() self.gui.Enabled = false end
	return self
end
