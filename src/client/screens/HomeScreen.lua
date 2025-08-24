-- StarterPlayerScripts/UI/screens/HomeScreen.lua
-- NEW GAME / 神社 / 持ち物 / 設定 / CONTINUE

local Home = {}
Home.__index = Home

local function setInteractable(btn: TextButton, on: boolean)
	btn.AutoButtonColor = on
	btn.Active = on
	btn.BackgroundTransparency = on and 0 or 0.5
	btn.TextTransparency = on and 0 or 0.4
end

function Home.new(deps)
	local self = setmetatable({}, Home)
	self.deps = deps

	-- ルートGUI（親への取り付けは Router 側で行う）
	local g = Instance.new("ScreenGui")
	g.Name = "HomeScreen"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 100
	g.Enabled = false
	self.gui = g

	-- 背景
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1,1)
	bg.BackgroundColor3 = Color3.fromRGB(10,12,16)
	bg.BackgroundTransparency = 0.2
	bg.Parent = g

	-- タイトル
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,0,0,80)
	title.Position = UDim2.new(0,0,0,40)
	title.BackgroundTransparency = 1
	title.Text = "花札 × 倍率ローグ"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(240,240,240)
	title.Parent = bg

	-- ボタンFactory
	local function makeBtn(text, y)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 320, 0, 56)
		b.Position = UDim2.new(0.5, -160, 0, 140 + (y * 66))
		b.BackgroundColor3 = Color3.fromRGB(30,34,44)
		b.BorderSizePixel = 0
		b.AutoButtonColor = true
		b.Text = text
		b.TextColor3 = Color3.fromRGB(235,235,235)
		b.Font = Enum.Font.GothamMedium
		b.TextSize = 22
		b.Parent = bg
		local uic = Instance.new("UICorner"); uic.CornerRadius = UDim.new(0, 12); uic.Parent = b
		local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(70,75,90); stroke.Thickness = 1; stroke.Parent = b
		return b
	end

	self.btnNew      = makeBtn("NEW GAME（新しく始める）", 0)
	self.btnShrine   = makeBtn("神社（恒久強化）",        1)
	self.btnItems    = makeBtn("持ち物（所持確認）",      2)
	self.btnSettings = makeBtn("設定",                    3)
	self.btnCont     = makeBtn("前回の続き（CONTINUE）",  4)

	-- クリック
	self.btnNew.Activated:Connect(function()
		-- 先にRun画面を開く→サーバへ要求（初回のState/Hand push取りこぼし防止）
		if self.deps.showRun then self.deps.showRun() end
		if self.deps.remotes and self.deps.remotes.ReqStartNewRun then
			self.deps.remotes.ReqStartNewRun:FireServer()
		elseif self.deps.ReqStartNewRun then
			self.deps.ReqStartNewRun:FireServer()
		end
		self:hide()
	end)

	self.btnShrine.Activated:Connect(function()
		-- 画面遷移があれば使う／なければトースト
		if self.deps.showShrine then
			self.deps.showShrine()
			self:hide()
		else
			pcall(function()
				game.StarterGui:SetCore("SendNotification", {Title="神社", Text="開発中：恒久強化ショップ", Duration=2})
			end)
		end
	end)

	self.btnItems.Activated:Connect(function()
		pcall(function()
			game.StarterGui:SetCore("SendNotification", {Title="持ち物", Text="開発中：所持品一覧", Duration=2})
		end)
	end)

	self.btnSettings.Activated:Connect(function()
		pcall(function()
			game.StarterGui:SetCore("SendNotification", {Title="設定", Text="開発中：サウンド/UI/操作", Duration=2})
		end)
	end)

	self.btnCont.Activated:Connect(function()
		if not self.btnCont.Active then return end
		if self.deps.showRun then self.deps.showRun() end
		if self.deps.remotes and self.deps.remotes.ReqContinueRun then
			self.deps.remotes.ReqContinueRun:FireServer()
		elseif self.deps.ReqContinueRun then
			self.deps.ReqContinueRun:FireServer()
		end
		self:hide()
	end)

	return self
end

function Home:show(payload)
	-- payload = { hasSave = bool }
	local hasSave = payload and payload.hasSave == true
	setInteractable(self.btnCont, hasSave)
	self.gui.Enabled = true
end

function Home:hide()
	self.gui.Enabled = false
end

return Home
