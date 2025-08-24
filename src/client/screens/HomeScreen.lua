-- HomeScreen.lua
-- TOPメニュー：NEW GAME / 神社 / 持ち物 / 設定 / CONTINUE（将来）
-- 「NEW GAME」を押したときだけラン開始（自動開始はしない）

local Home = {}
Home.__index = Home

local function makeBtn(parent, text, pos)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 240, 0, 56)
	b.Position = pos
	b.Text = text
	b.TextScaled = true
	b.AutoButtonColor = true
	b.BackgroundColor3 = Color3.fromRGB(245,245,245)
	b.BorderSizePixel = 1
	b.Parent = parent
	return b
end

function Home.new(deps)
	local self = setmetatable({}, Home)
	self.deps = deps

	local g = Instance.new("ScreenGui")
	g.Name = "HomeScreen"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 5; g.Enabled = true
	self.gui = g

	local frame = Instance.new("Frame")
	frame.Name = "Root"; frame.Parent = g
	frame.Size = UDim2.fromScale(1,1)
	frame.BackgroundColor3 = Color3.fromRGB(235,240,248)
	self.frame = frame

	local title = Instance.new("TextLabel")
	title.Parent = frame
	title.Size = UDim2.new(1,0,0,80)
	title.Position = UDim2.new(0,0,0,40)
	title.BackgroundTransparency = 1
	title.Text = "花札 × 倍率ローグ"
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold

	local center = Instance.new("Frame")
	center.Parent = frame
	center.Size = UDim2.new(0, 280, 0, 360)
	center.Position = UDim2.new(0.5, 0, 0.5, 0)
	center.AnchorPoint = Vector2.new(0.5, 0.5)
	center.BackgroundTransparency = 1

	local pad = 12
	local y = 0
	local function row(text, onClick)
		local b = makeBtn(center, text, UDim2.new(0, 20, 0, y))
		y = y + 56 + pad
		b.MouseButton1Click:Connect(onClick)
		return b
	end

	row("NEW GAME", function()
		if self.deps and self.deps.ReqStartNewRun then
			self.deps.ReqStartNewRun:FireServer()
		end
	end)

	row("神社（SHRINE）", function()
		if self.deps and self.deps.showShrine then
			self.deps.showShrine()
		end
	end)

	row("持ち物（未実装）", function() end)
	row("設定（未実装）", function() end)

	row("CONTINUE（将来）", function()
		if self.deps and self.deps.ReqContinueRun then
			self.deps.ReqContinueRun:FireServer()
		end
	end)

	return self
end

function Home:show()
	self.frame.Visible = true
end

function Home:hide()
	self.frame.Visible = false
end

function Home:destroy()
	if self.gui then self.gui:Destroy() end
end

return Home
