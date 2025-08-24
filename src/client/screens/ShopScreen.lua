-- ShopScreen (ModuleScript)
-- ShopOpen で呼び出される。とりあえず「屋台を閉じる」だけ用意。

local Shop = {}
Shop.__index = Shop

function Shop.new(deps)
	local self = setmetatable({}, Shop)
	self.deps = deps

	local g = Instance.new("ScreenGui")
	g.Name = "ShopScreen"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 50
	g.Enabled = false
	self.gui = g

	local modal = Instance.new("Frame")
	modal.Name = "Modal"
	modal.AnchorPoint = Vector2.new(0.5,0.5)
	modal.Position = UDim2.new(0.5,0,0.5,0)
	modal.Size = UDim2.new(0.7,0,0.6,0)
	modal.BackgroundColor3 = Color3.fromRGB(255,255,255)
	modal.Parent = g

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1,-20,0,40)
	title.Position = UDim2.new(0,10,0,10)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Text = "屋台（簡易版）"
	title.Parent = modal

	local info = Instance.new("TextLabel")
	info.Name = "Info"
	info.BackgroundTransparency = 1
	info.Size = UDim2.new(1,-20,0,60)
	info.Position = UDim2.new(0,10,0,54)
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top
	info.Text = ""
	info.Parent = modal

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0,240,0,44)
	closeBtn.Position = UDim2.new(0.5,-120,1,-56)
	closeBtn.Text = "屋台を閉じて次の季節へ"
	closeBtn.Parent = modal
	closeBtn.Activated:Connect(function()
		self:hide()
		self.deps.remotes.ShopDone:FireServer()
	end)

	return self
end

function Shop:show(payload)
	self.gui.Enabled = true
	local info = self.gui.Modal.Info
	info.Text = ("達成！ 合計:%d / 目標:%d\n報酬：%d 文（所持：%d 文）"):format(
		payload.seasonSum or 0, payload.target or 0, payload.rewardMon or 0, payload.totalMon or 0
	)
end

function Shop:hide()
	self.gui.Enabled = false
end

return Shop
