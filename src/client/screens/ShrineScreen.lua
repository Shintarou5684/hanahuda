-- StarterPlayerScripts/UI/screens/ShrineScreen.lua
-- 神社（恒久強化）画面の最小スタブ。戻る（HOME）ボタン付き。

local Shrine = {}
Shrine.__index = Shrine

function Shrine.new(deps)
	local self = setmetatable({}, Shrine)
	self.deps = deps

	-- ルート GUI
	local g = Instance.new("ScreenGui")
	g.Name = "ShrineScreen"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 80
	g.Enabled = true
	self.gui = g

	-- ルートフレーム（普段は非表示、show時にVisible=true）
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Size = UDim2.fromScale(1,1)
	root.BackgroundColor3 = Color3.fromRGB(10,12,16)
	root.BackgroundTransparency = 0.15
	root.Visible = false
	root.Parent = g
	self.root = root

	-- タイトル
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1,0,0,64)
	title.Position = UDim2.new(0,0,0,20)
	title.BackgroundTransparency = 1
	title.Text = "神社（恒久強化）"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(240,240,240)
	title.Parent = root

	-- 本文（準備中）
	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.new(1, -40, 0, 200)
	body.Position = UDim2.new(0, 20, 0, 110)
	body.BackgroundTransparency = 1
	body.TextXAlignment = Enum.TextXAlignment.Center
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.TextScaled = true
	body.Text = "準備中です。\n将来的に恒久強化（祈祷/祭事/お守り）をここで購入できるようにします。"
	body.TextColor3 = Color3.fromRGB(235,235,235)
	body.Parent = root

	-- 戻る（HOME）
	local back = Instance.new("TextButton")
	back.Name = "Back"
	back.Size = UDim2.new(0, 220, 0, 50)
	back.Position = UDim2.new(0.5, -110, 1, -70)
	back.Text = "HOME に戻る"
	back.TextScaled = true
	back.AutoButtonColor = true
	back.BackgroundColor3 = Color3.fromRGB(235,244,255)
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 10); corner.Parent = back
	back.Parent = root

	back.Activated:Connect(function()
		if self.deps and self.deps.showHome then
			self:hide()
			self.deps.showHome({ hasSave = false }) -- 既定：続きはまだ未実装
		end
	end)

	return self
end

function Shrine:show()
	if self.root then self.root.Visible = true end
end

function Shrine:hide()
	if self.root then self.root.Visible = false end
end

return Shrine
