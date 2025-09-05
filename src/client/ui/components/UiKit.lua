-- StarterPlayerScripts/UI/components/UiKit.lua
local UiKit = {}

function UiKit.notify(title: string, text: string, duration: number?)
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = title, Text = text, Duration = duration or 2
		})
	end)
end

function UiKit.label(parent: Instance, name: string, text: string, size: UDim2, pos: UDim2, anchor: Vector2?)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Parent = parent
	l.BackgroundTransparency = 1
	l.Text = text or ""
	l.TextScaled = true
	l.Size = size or UDim2.new(0,100,0,24)
	l.Position = pos or UDim2.new(0,0,0,0)
	if anchor then l.AnchorPoint = anchor end
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	return l
end

function UiKit.button(parent: Instance, txt: string, size: UDim2, pos: UDim2)
	local b = Instance.new("TextButton")
	b.Parent = parent
	b.Text = txt
	b.TextScaled = true
	b.Size = size or UDim2.fromOffset(120,40)
	if pos then b.Position = pos end
	b.AutoButtonColor = true
	b.BackgroundColor3 = Color3.fromRGB(255,255,255)
	b.BorderSizePixel = 1
	return b
end

local UiKit = {}

function UiKit.makeAspectContainer(parent, aspect) -- aspect 例: 16/9
	local frame = Instance.new("Frame")
	frame.Name = "PlayArea"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = parent

	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = aspect
	ar.DominantAxis = Enum.DominantAxis.Width -- 横幅を基準に高さを決める
	ar.Parent = frame

	local uis = Instance.new("UISizeConstraint")
	uis.MinSize = Vector2.new(960, 540) -- 小さすぎ防止（任意）
	-- uis.MaxSize = Vector2.new(3840, 2160) -- 必要なら上限も
	uis.Parent = frame

	return frame
end

return UiKit
