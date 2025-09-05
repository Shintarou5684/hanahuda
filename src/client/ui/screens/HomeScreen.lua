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

-- 軽量通知（SetCoreが失敗しても落ちない）
local function notify(title: string, text: string, duration: number?)
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 2,
		})
	end)
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

	--========================
	-- 背景画像（TOPアート：絵のみ）
	--========================
	local bg = Instance.new("ImageLabel")
	bg.Name = "Background"
	bg.Size = UDim2.fromScale(1,1)
	bg.Position = UDim2.fromOffset(0,0)
	bg.BackgroundTransparency = 1
	bg.Image = "rbxassetid://132353504528822" -- 背景イメージID（絵のみ）
	bg.ScaleType = Enum.ScaleType.Crop
	bg.ZIndex = 0
	bg.Parent = g

	-- 可読性向上の薄いディマー（やや強めに調整）
	local dim = Instance.new("Frame")
	dim.Name = "Dimmer"
	dim.Size = UDim2.fromScale(1,1)
	dim.BackgroundColor3 = Color3.fromRGB(0,0,0)
	dim.BackgroundTransparency = 0.32 -- 0.28 → 0.32
	dim.ZIndex = 1
	dim.Parent = g

	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0,0,0)),
		ColorSequenceKeypoint.new(0.20, Color3.fromRGB(40,40,40)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(70,70,70)),
		ColorSequenceKeypoint.new(0.80, Color3.fromRGB(40,40,40)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0,0,0)),
	})
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 0.48),
		NumberSequenceKeypoint.new(0.20, 0.40),
		NumberSequenceKeypoint.new(0.50, 0.22), -- 0.18 → 0.22
		NumberSequenceKeypoint.new(0.80, 0.40),
		NumberSequenceKeypoint.new(1.00, 0.48),
	})
	grad.Parent = dim

	-- 前景レイヤ
	local ui = Instance.new("Frame")
	ui.Name = "UIRoot"
	ui.Size = UDim2.fromScale(1,1)
	ui.BackgroundTransparency = 1
	ui.ZIndex = 2
	ui.Parent = g

	-- タイトル（日本語）
	local titleJP = Instance.new("TextLabel")
	titleJP.Name = "TitleJP"
	titleJP.Size = UDim2.new(1,0,0,76)
	titleJP.Position = UDim2.new(0,0,0,36)
	titleJP.BackgroundTransparency = 1
	titleJP.Text = "極楽蝶"
	titleJP.Font = Enum.Font.GothamBlack
	titleJP.TextScaled = true
	titleJP.TextColor3 = Color3.fromRGB(245,245,245)
	titleJP.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	titleJP.TextStrokeTransparency = 0.25 -- 0.35 → 0.25（可読性UP）
	titleJP.ZIndex = 2
	titleJP.Parent = ui

	-- サブタイトル（英語）
	local titleEN = Instance.new("TextLabel")
	titleEN.Name = "TitleEN"
	titleEN.Size = UDim2.new(1,0,0,38)
	titleEN.Position = UDim2.new(0,0,0,104)
	titleEN.BackgroundTransparency = 1
	titleEN.Text = "Hanahuda Rogue" -- 指定の綴り
	titleEN.Font = Enum.Font.Gotham
	titleEN.TextScaled = true
	titleEN.TextColor3 = Color3.fromRGB(235,235,235)
	titleEN.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	titleEN.TextStrokeTransparency = 0.35 -- 0.45 → 0.35
	titleEN.ZIndex = 2
	titleEN.Parent = ui

	-- ステータス（年 / 両 / 進捗）
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1,0,0,26)
	status.Position = UDim2.new(0,0,0,146)
	status.BackgroundTransparency = 1
	status.Text = "年:----  両:0  進捗: 通算 0/3 クリア"
	status.Font = Enum.Font.Gotham
	status.TextSize = 20
	status.TextColor3 = Color3.fromRGB(230,230,230)
	status.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	status.TextStrokeTransparency = 0.6
	status.TextXAlignment = Enum.TextXAlignment.Center
	status.ZIndex = 2
	status.Parent = ui
	self.statusLabel = status

	--========================
	-- メニュー：中央寄せ
	--========================
	local menu = Instance.new("Frame")
	menu.Name = "Menu"
	menu.Size = UDim2.new(0, 360, 0, 10) -- 高さは自動
	menu.AutomaticSize = Enum.AutomaticSize.Y
	menu.BackgroundTransparency = 1
	menu.AnchorPoint = Vector2.new(0.5, 0.5)
	menu.Position = UDim2.fromScale(0.5, 0.55) -- 画面中央やや下
	menu.ZIndex = 2
	menu.Parent = ui

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = menu

	local function makeBtn(text)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 56)
		b.BackgroundColor3 = Color3.fromRGB(30,34,44)
		b.BackgroundTransparency = 0.12
		b.BorderSizePixel = 0
		b.AutoButtonColor = true
		b.Text = text
		b.TextColor3 = Color3.fromRGB(235,235,235)
		b.Font = Enum.Font.GothamMedium
		b.TextSize = 22
		b.ZIndex = 2
		b.Parent = menu
		local uic = Instance.new("UICorner"); uic.CornerRadius = UDim.new(0, 12); uic.Parent = b
		local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(70,75,90); stroke.Thickness = 1; stroke.Parent = b
		local shadow = Instance.new("UIStroke"); shadow.Color = Color3.fromRGB(0,0,0); shadow.Thickness = 3; shadow.Transparency = 0.9; shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; shadow.Parent = b
		return b
	end

	self.btnNew      = makeBtn("NEW GAME")
	self.btnShrine   = makeBtn("神社（開発中）")
	self.btnItems    = makeBtn("持ち物（開発中）")
	self.btnSettings = makeBtn("設定（開発中）")
	self.btnCont     = makeBtn("CONTINUE（開発中）")

	--========================
	-- BETA TEST バッジ（画面右下固定）
	--========================
	local beta = Instance.new("TextLabel")
	beta.Name = "BetaBadge"
	beta.AnchorPoint = Vector2.new(1,1)
	beta.Position = UDim2.new(1, -16, 1, -12) -- 画面右下
	beta.BackgroundTransparency = 0.25
	beta.BackgroundColor3 = Color3.fromRGB(20,22,28)
	beta.Text = "BETA TEST"
	beta.Font = Enum.Font.GothamBold
	beta.TextSize = 16
	beta.TextColor3 = Color3.fromRGB(255,255,255)
	beta.ZIndex = 3
	beta.Parent = ui -- メニューではなく画面固定に変更
	local betaCorner = Instance.new("UICorner"); betaCorner.CornerRadius = UDim.new(0, 8); betaCorner.Parent = beta
	local betaPad = Instance.new("UIPadding"); betaPad.PaddingLeft = UDim.new(0,10); betaPad.PaddingRight = UDim.new(0,10); betaPad.PaddingTop = UDim.new(0,4); betaPad.PaddingBottom = UDim.new(0,4); betaPad.Parent = beta

	-- 初期は無効（HomeOpenで有効化）
	setInteractable(self.btnCont, false)

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
		notify("神社", "開発中：恒久強化ショップ", 2)
	end)

	self.btnItems.Activated:Connect(function()
		notify("持ち物", "開発中：所持品一覧", 2)
	end)

	self.btnSettings.Activated:Connect(function()
		notify("設定", "開発中：サウンド/UI/操作", 2)
	end)

	self.btnCont.Activated:Connect(function()
		-- v0.8.2 MVP：セーブ未実装のためスタブのみ
		if not self.btnCont.Active then return end
		notify("CONTINUE", "次回対応（セーブ未実装）", 2)
	end)

	return self
end

function Home:show(payload)
	-- payload = { hasSave:bool, bank:number, year:number, clears:number }
	local hasSave = payload and payload.hasSave == true
	local bank    = (payload and tonumber(payload.bank))   or 0
	local year    = (payload and tonumber(payload.year))   or 0
	local clears  = (payload and tonumber(payload.clears)) or 0

	setInteractable(self.btnCont, hasSave)

	-- ステータス更新（年は0/未設定なら ---- 表示）
	local yearTxt = (year > 0) and tostring(year) or "----"
	if self.statusLabel then
		self.statusLabel.Text = string.format("年:%s  両:%d  進捗: 通算 %d/3 クリア", yearTxt, bank, clears)
	end

	self.gui.Enabled = true
end

function Home:hide()
	self.gui.Enabled = false
end

return Home
