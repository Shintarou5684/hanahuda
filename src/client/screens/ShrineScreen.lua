-- ShrineScreen.lua
-- 神社（スタブ）：戻るボタンのみ

local Shrine = {}
Shrine.__index = Shrine

function Shrine.new(deps)
	local self = setmetatable({}, Shrine)
	self.deps = deps

	local g = Instance.new("ScreenGui")
	g.Name = "ShrineScreen"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 6; g.Enabled = true
	self.gui = g

	local frame = Instance.new("Frame")
	frame.Name = "Root"; frame.Parent = g
	frame.Size = UDim2.fromScale(1,1)
	frame.BackgroundColor3 = Color3.fromRGB(250,245,235)
	frame.Visible = false
	self.frame = frame

	local title = Instance.new("TextLabel")
	title.Parent = frame
	title.Size = UDim2.new(1,0,0,60)
	title.Position = UDim2.new(0,0,0,20)
	title.BackgroundTransparency = 1
	title.Text = "神社（準備中）"
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold

	local back = Instance.new("TextButton")
	back.Parent = frame
	back.Size = UDim2.new(0, 200, 0, 44)
	back.Position = UDim2.new(0, 20, 0, 100)
	back.Text = "HOMEへ戻る"
	back.TextScaled = true
	back.MouseButton1Click:Connect(function()
		if self.deps and self.deps.showHome then
			self.deps.showHome()
		end
	end)

	return self
end

function Shrine:show()
	self.frame.Visible = true
end

function Shrine:hide()
	self.frame.Visible = false
end

function Shrine:destroy()
	if self.gui then self.gui:Destroy() end
end

return Shrine
