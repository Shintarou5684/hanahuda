-- ShrineScreen (ModuleScript)
local Shrine = {}
Shrine.__index = Shrine

function Shrine.new(deps)
	local self = setmetatable({}, Shrine)
	self.deps = deps

	local g = Instance.new("ScreenGui")
	g.Name = "ShrineScreen"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 40
	g.Enabled = false
	self.gui = g

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,0,1,0)
	label.BackgroundTransparency = 1
	label.Text = "神社（恒久強化）- 準備中"
	label.Parent = g

	return self
end

function Shrine:show() self.gui.Enabled = true end
function Shrine:hide() self.gui.Enabled = false end

return Shrine
