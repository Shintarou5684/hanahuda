local M = {}
function M.create(parent: Instance, text: string?)
	local overlay = Instance.new("Frame")
	overlay.Name = "LoadingOverlay"
	overlay.Parent = parent
	overlay.Size = UDim2.fromScale(1,1)
	overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
	overlay.BackgroundTransparency = 0.35
	overlay.Visible = false
	overlay.ZIndex = 50

	local msg = Instance.new("TextLabel")
	msg.Name = "Msg"
	msg.Parent = overlay
	msg.BackgroundTransparency = 1
	msg.TextScaled = true
	msg.Size = UDim2.new(0,480,0,48)
	msg.Position = UDim2.new(0.5,0,0.5,0)
	msg.AnchorPoint = Vector2.new(0.5,0.5)
	msg.TextXAlignment = Enum.TextXAlignment.Center
	msg.TextColor3 = Color3.fromRGB(255,255,255)
	msg.Text = text or "読み込み中..."

	local api = {}
	function api:show() overlay.Visible = true end
	function api:hide() overlay.Visible = false end
	function api:setText(t) msg.Text = t or "" end
	return api
end
return M
