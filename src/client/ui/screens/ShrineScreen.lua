-- ShrineScreen.lua  v0.8 minimal
return function(deps)
	local self = {}
	local g = Instance.new("ScreenGui")
	g.Name = "ShrineScreen"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 6; g.Enabled = true
	self.gui = g

	local root = Instance.new("Frame")
	root.Name = "Root"; root.Parent = g; root.Size = UDim2.fromScale(1,1)
	root.BackgroundColor3 = Color3.fromRGB(245,245,252)

	local title = Instance.new("TextLabel")
	title.Parent = root; title.Size = UDim2.new(1, -20, 0, 48); title.Position = UDim2.new(0,10,0,20)
	title.BackgroundTransparency = 1; title.TextXAlignment = Enum.TextXAlignment.Left; title.TextScaled = true
	title.Text = "神社（準備中）"

	local back = Instance.new("TextButton")
	back.Parent = root; back.Size = UDim2.new(0, 180, 0, 44); back.Position = UDim2.new(0,10,0,80)
	back.Text = "← HOME へ"; back.AutoButtonColor = true
	back.MouseButton1Click:Connect(function()
		if deps and deps.showHome then deps.showHome() end
	end)

	function self:show() self.gui.Enabled = true; if self.gui.Parent ~= deps.playerGui then self.gui.Parent = deps.playerGui end end
	function self:hide() self.gui.Enabled = false end
	return self
end
