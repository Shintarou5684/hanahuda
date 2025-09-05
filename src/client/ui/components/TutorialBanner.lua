-- StarterPlayerScripts/UI/components/TutorialBanner.lua
local M = {}

function M.mount(parent: Instance, text: string)
	local t = Instance.new("TextLabel")
	t.Name = "TutorialBanner"
	t.Parent = parent
	t.Size = UDim2.new(1,0,0,28)
	t.Position = UDim2.new(0,0,0,0)
	t.BackgroundTransparency = 0.3
	t.BackgroundColor3 = Color3.fromRGB(20,20,20)
	t.Text = text
	t.Font = Enum.Font.GothamMedium
	t.TextSize = 18
	t.TextColor3 = Color3.fromRGB(230,230,230)
	t.ZIndex = 20
	return t
end

return M
