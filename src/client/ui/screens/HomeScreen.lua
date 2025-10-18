-- StarterPlayerScripts/UI/screens/HomeScreen.lua
-- v0.9.5-P0-6/12 (status row removed)
--  - タイトル下のステータス行（Year / Cash / Clears）を完全に非表示
--  - 他の挙動は現状維持（横画面/中央1列/言語切替/同期表示など）

local Home = {}
Home.__index = Home

--========================
-- Services / Locale
--========================
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local Locale  = require(RS:WaitForChild("Config"):WaitForChild("Locale"))
local PatchNotesModal = require(script.Parent:WaitForChild("PatchNotesModal"))

-- デバイス幅が極端に広い時のボタン横伸びを抑える上限(px)
local MENU_MAX_W = 640
-- スマホ〜小型画面での最低幅(px)
local MENU_MIN_W = 280
-- 相対ベースの標準幅（画面幅に対する割合）
local MENU_W_SCALE = 0.36

-- BETA/言語チップの右端安全余白（px）
local RIGHT_SAFE_PAD = 20

local function detectOSLang()
	local lp  = Players.LocalPlayer
	local lid = (lp and lp.LocaleId) and string.lower(lp.LocaleId) or "en-us"
	return (string.sub(lid, 1, 2) == "ja") and "ja" or "en"
end

local function pickLang(forced)
	if forced == "ja" or forced == "en" then return forced end
	if typeof(Locale.pick) == "function" then
		local ok, v = pcall(Locale.pick)
		if ok and (v == "ja" or v == "en") then return v end
	end
	return detectOSLang()
end

local function makeL(dict) return function(k) return dict[k] or k end end
local function Dget(dict, key, fallback) return (dict and dict[key]) or fallback end

--========================
-- Helpers
--========================
local function setInteractable(btn: TextButton, on: boolean)
	btn.AutoButtonColor        = on
	btn.Active                 = on
	btn.BackgroundTransparency = on and 0 or 0.5
	btn.TextTransparency       = on and 0 or 0.4
end

local function notify(title: string, text: string, duration: number?)
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title    = title,
			Text     = text,
			Duration = duration or 2,
		})
	end)
end

--========================
-- Class
--========================
function Home.new(deps)
	local self = setmetatable({}, Home)
	self.deps = deps
	self.hasSave = false

	self.lang = pickLang(deps and deps.lang)
	self.Dict = (typeof(Locale.get)=="function" and Locale.get(self.lang)) or Locale[self.lang] or Locale.en
	self._L   = makeL(self.Dict)
	if typeof(Locale.setGlobal) == "function" then
		Locale.setGlobal(self.lang)
	end

	-- ルートGUI（横画面専用）
	local g = Instance.new("ScreenGui")
	g.Name             = "HomeScreen"
	g.ResetOnSpawn     = false
	g.IgnoreGuiInset   = true
	g.DisplayOrder     = 100
	g.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
	g.Enabled          = false
	self.gui           = g

	--================ 背景 =================
	local bg = Instance.new("ImageLabel")
	bg.Name                   = "Background"
	bg.Size                   = UDim2.fromScale(1,1)
	bg.BackgroundTransparency = 1
	bg.Image                  = "rbxassetid://132353504528822"
	bg.ScaleType              = Enum.ScaleType.Crop
	bg.ZIndex                 = 0
	bg.Parent                 = g

	local dim = Instance.new("Frame")
	dim.Name                   = "Dimmer"
	dim.Size                   = UDim2.fromScale(1,1)
	dim.BackgroundColor3       = Color3.fromRGB(0,0,0)
	dim.BackgroundTransparency = 0.32
	dim.ZIndex                 = 1
	dim.Parent                 = g

	local grad = Instance.new("UIGradient")
	grad.Rotation   = 90
	grad.Color      = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0,0,0)),
		ColorSequenceKeypoint.new(0.20, Color3.fromRGB(40,40,40)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(70,70,70)),
		ColorSequenceKeypoint.new(0.80, Color3.fromRGB(40,40,40)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0,0,0)),
	})
	grad.Transparency= NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 0.48),
		NumberSequenceKeypoint.new(0.20, 0.40),
		NumberSequenceKeypoint.new(0.50, 0.22),
		NumberSequenceKeypoint.new(0.80, 0.40),
		NumberSequenceKeypoint.new(1.00, 0.48),
	})
	grad.Parent = dim

	--================ 前景 =================
	local ui = Instance.new("Frame")
	ui.Name                   = "UIRoot"
	ui.Size                   = UDim2.fromScale(1,1)
	ui.BackgroundTransparency = 1
	ui.ZIndex                 = 2
	ui.Parent                 = g

	-- タイトル群（上段に凝集）
	local titleGroup = Instance.new("Frame")
	titleGroup.Name                   = "TitleGroup"
	titleGroup.AnchorPoint            = Vector2.new(0.5, 0)
	titleGroup.Position               = UDim2.fromScale(0.5, 0.05)
	titleGroup.Size                   = UDim2.fromScale(0.9, 0) -- 横は90%で中央、縦は自動
	titleGroup.BackgroundTransparency = 1
	titleGroup.AutomaticSize          = Enum.AutomaticSize.Y
	titleGroup.ZIndex                 = 2
	titleGroup.Parent                 = ui

	local tLayout = Instance.new("UIListLayout")
	tLayout.FillDirection       = Enum.FillDirection.Vertical
	tLayout.Padding             = UDim.new(0, 6)
	tLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tLayout.VerticalAlignment   = Enum.VerticalAlignment.Top
	tLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	tLayout.Parent              = titleGroup

	self.titleJP = Instance.new("TextLabel")
	self.titleJP.Name                   = "TitleJP"
	self.titleJP.Size                   = UDim2.new(1, 0, 0, 76)
	self.titleJP.BackgroundTransparency = 1
	self.titleJP.Font                   = Enum.Font.GothamBlack
	self.titleJP.TextScaled             = true
	self.titleJP.TextColor3             = Color3.fromRGB(245,245,245)
	self.titleJP.TextStrokeColor3       = Color3.fromRGB(0,0,0)
	self.titleJP.TextStrokeTransparency = 0.25
	self.titleJP.ZIndex                 = 2
	self.titleJP.Parent                 = titleGroup

	self.titleEN = Instance.new("TextLabel")
	self.titleEN.Name                   = "TitleEN"
	self.titleEN.Size                   = UDim2.new(1,0,0,38)
	self.titleEN.BackgroundTransparency = 1
	self.titleEN.Font                   = Enum.Font.Gotham
	self.titleEN.TextScaled             = true
	self.titleEN.TextColor3             = Color3.fromRGB(235,235,235)
	self.titleEN.TextStrokeColor3       = Color3.fromRGB(0,0,0)
	self.titleEN.TextStrokeTransparency = 0.35
	self.titleEN.ZIndex                 = 2
	self.titleEN.Parent                 = titleGroup

	-- ▼ ステータス行は互換のため生成のみ。高さ0・不可視・空文字で完全に非表示
	self.statusLabel = Instance.new("TextLabel")
	self.statusLabel.Name                   = "Status"
	self.statusLabel.Size                   = UDim2.new(1,0,0,0) -- 高さ0
	self.statusLabel.BackgroundTransparency = 1
	self.statusLabel.Font                   = Enum.Font.Gotham
	self.statusLabel.TextSize               = 20
	self.statusLabel.TextColor3             = Color3.fromRGB(230,230,230)
	self.statusLabel.TextStrokeColor3       = Color3.fromRGB(0,0,0)
	self.statusLabel.TextStrokeTransparency = 0.6
	self.statusLabel.TextXAlignment         = Enum.TextXAlignment.Center
	self.statusLabel.ZIndex                 = 2
	self.statusLabel.Visible                = false
	self.statusLabel.Text                   = ""
	self.statusLabel.Parent                 = titleGroup

	--================ メニュー（中央1列） =================
	local menu = Instance.new("Frame")
	menu.Name                   = "Menu"
	menu.AnchorPoint            = Vector2.new(0.5, 0)
	menu.Position               = UDim2.fromScale(0.5, 0.32)
	menu.Size                   = UDim2.new(MENU_W_SCALE, 0, 0, 10)
	menu.AutomaticSize          = Enum.AutomaticSize.Y
	menu.BackgroundTransparency = 1
	menu.ZIndex                 = 2
	menu.Parent                 = ui

	local menuSizeLimit = Instance.new("UISizeConstraint")
	menuSizeLimit.MaxSize = Vector2.new(MENU_MAX_W, math.huge)
	menuSizeLimit.MinSize = Vector2.new(MENU_MIN_W, 0)
	menuSizeLimit.Parent  = menu

	local layout = Instance.new("UIListLayout")
	layout.Padding              = UDim.new(0, 10)
	layout.HorizontalAlignment  = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment    = Enum.VerticalAlignment.Top
	layout.SortOrder            = Enum.SortOrder.LayoutOrder
	layout.Parent               = menu

	local function makeBtn(text: string)
		local b = Instance.new("TextButton")
		b.Size                   = UDim2.new(1, 0, 0.085, 0)
		local bh = Instance.new("UISizeConstraint")
		bh.MinSize = Vector2.new(0, 44)
		bh.MaxSize = Vector2.new(10000, 64)
		bh.Parent  = b

		b.BackgroundColor3       = Color3.fromRGB(30,34,44)
		b.BackgroundTransparency = 0.12
		b.BorderSizePixel        = 0
		b.AutoButtonColor        = true
		b.Text                   = text
		b.TextColor3             = Color3.fromRGB(235,235,235)
		b.Font                   = Enum.Font.GothamMedium
		b.TextScaled             = true
		local ts = Instance.new("UITextSizeConstraint"); ts.MaxTextSize = 24; ts.Parent = b
		b.ZIndex                 = 2
		b.Parent                 = menu

		local uic = Instance.new("UICorner"); uic.CornerRadius = UDim.new(0, 12); uic.Parent = b
		local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(70,75,90); stroke.Thickness = 1; stroke.Parent = b
		local shadow = Instance.new("UIStroke"); shadow.Color = Color3.fromRGB(0,0,0); shadow.Thickness = 3; shadow.Transparency = 0.9; shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; shadow.Parent = b
		return b
	end

	self.btnStart     = makeBtn("")
	self.btnShrine    = makeBtn("")
	self.btnItems     = makeBtn("")
	self.btnSettings  = makeBtn("")
	self.btnPatch     = makeBtn("")

	--================ BETA バッジ（右下） =================
	local beta = Instance.new("TextLabel")
	beta.Name                   = "BetaBadge"
	beta.AnchorPoint            = Vector2.new(1,1)
	beta.Position               = UDim2.new(1, -(12 + RIGHT_SAFE_PAD), 1, -12)
	beta.BackgroundTransparency = 0.25
	beta.BackgroundColor3       = Color3.fromRGB(20,22,28)
	beta.Font                   = Enum.Font.GothamBold
	beta.TextSize               = 16
	beta.TextColor3             = Color3.fromRGB(255,255,255)
	beta.ZIndex                 = 3
	beta.RichText               = false
	beta.TextWrapped            = false
	beta.LineHeight             = 1.0
	beta.AutomaticSize          = Enum.AutomaticSize.XY
	beta.Parent                 = ui
	local betaCorner = Instance.new("UICorner"); betaCorner.CornerRadius = UDim.new(0, 8); betaCorner.Parent = beta
	local betaPad = Instance.new("UIPadding")
	betaPad.PaddingLeft   = UDim.new(0,10)
	betaPad.PaddingRight  = UDim.new(0,10)
	betaPad.PaddingTop    = UDim.new(0,4)
	betaPad.PaddingBottom = UDim.new(0,4)
	betaPad.Parent        = beta
	self.betaLabel = beta

	--================ 言語スイッチ（右上） =================
	local langBox = Instance.new("Frame")
	langBox.Name                   = "LangBox"
	langBox.AnchorPoint            = Vector2.new(1,0)
	langBox.Position               = UDim2.new(1, -(12 + RIGHT_SAFE_PAD), 0, 12)
	langBox.BackgroundColor3       = Color3.fromRGB(20,22,28)
	langBox.BackgroundTransparency = 0.25
	langBox.ZIndex                 = 3
	langBox.AutomaticSize          = Enum.AutomaticSize.XY
	langBox.Parent                 = ui
	local lbCorner = Instance.new("UICorner"); lbCorner.CornerRadius = UDim.new(0, 10); lbCorner.Parent = langBox
	local lbPad    = Instance.new("UIPadding")
	lbPad.PaddingLeft   = UDim.new(0,8)
	lbPad.PaddingRight  = UDim.new(0,8)
	lbPad.PaddingTop    = UDim.new(0,4)
	lbPad.PaddingBottom = UDim.new(0,4)
	lbPad.Parent        = langBox

	local h = Instance.new("UIListLayout")
	h.FillDirection       = Enum.FillDirection.Horizontal
	h.Padding             = UDim.new(0, 6)
	h.HorizontalAlignment = Enum.HorizontalAlignment.Center
	h.VerticalAlignment   = Enum.VerticalAlignment.Center
	h.Parent              = langBox

	local function makeChip(text)
		local b = Instance.new("TextButton")
		b.Size                   = UDim2.new(0, 56, 0, 28)
		b.BackgroundColor3       = Color3.fromRGB(36,40,52)
		b.BackgroundTransparency = 0.1
		b.BorderSizePixel        = 0
		b.AutoButtonColor        = true
		b.Text                   = text
		b.TextColor3             = Color3.fromRGB(240,240,240)
		b.Font                   = Enum.Font.GothamMedium
		b.TextSize               = 16
		b.ZIndex                 = 4
		b.Parent                 = langBox
		local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 8); cr.Parent = b
		local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(70,75,90); st.Thickness = 1; st.Parent = b
		return b
	end

	self.chipEN = makeChip("EN")
	self.chipJP = makeChip("JP") -- 表示はJP、内部コードは "ja"

	--================ Patch Notes モーダル =================
	self.patch = PatchNotesModal.new({
		parentGui = self.gui,
		lang      = self.lang,
		Locale    = Locale,
	})

	--================ イベント =================
	self.btnStart.Activated:Connect(function()
		local r = self.deps and self.deps.remotes or self.deps
		if r and r.ReqStartGame then
			r.ReqStartGame:FireServer()
		else
			if self.hasSave and r and r.ReqContinueRun then
				r.ReqContinueRun:FireServer()
			elseif r and r.ReqStartNewRun then
				r.ReqStartNewRun:FireServer()
			end
		end
		self:hide()
	end)

	self.btnShrine.Activated:Connect(function()
		notify(self._L("NOTIFY_SHRINE_TITLE"), self._L("NOTIFY_SHRINE_TEXT"), 2)
	end)

	self.btnItems.Activated:Connect(function()
		notify(self._L("NOTIFY_ITEMS_TITLE"), self._L("NOTIFY_ITEMS_TEXT"), 2)
	end)

	self.btnSettings.Activated:Connect(function()
		notify(self._L("NOTIFY_SETTINGS_TITLE"), self._L("NOTIFY_SETTINGS_TEXT"), 2)
	end)

	self.btnPatch.Activated:Connect(function()
		self.patch:show()
	end)

	self.chipEN.Activated:Connect(function() self:setLanguage("en", true) end)
	self.chipJP.Activated:Connect(function() self:setLanguage("ja", true) end)

	-- 初期文言を適用（STARTは _refreshStartButton で管理）
	self:applyLocaleTexts()
	self:_refreshStartButton()

	return self
end

--================ STARTボタンの文言/可否 =================
function Home:_refreshStartButton()
	if not self.btnStart then return end
	if self.gui and self.gui.Enabled then
		if self.hasSave then
			self.btnStart.Text = Dget(self.Dict, "BTN_CONT", "CONTINUE")
		else
			self.btnStart.Text = Dget(self.Dict, "BTN_START", "Start Game")
		end
		setInteractable(self.btnStart, true)
	else
		self.btnStart.Text = (self.lang == "ja") and Dget(self.Dict, "BTN_SYNCING", "同期中…")
			or Dget(self.Dict, "BTN_SYNCING", "Syncing…")
		setInteractable(self.btnStart, false)
	end
end

--================ 言語切替 =================
function Home:setLanguage(lang: string, requestSave: boolean?)
	if lang ~= "ja" and lang ~= "en" then return end
	if self.lang == lang then return end

	self.lang = lang
	self.Dict = (typeof(Locale.get)=="function" and Locale.get(self.lang)) or Locale[self.lang] or Locale.en
	self._L   = makeL(self.Dict)

	self:applyLocaleTexts()

	self.chipEN.BackgroundTransparency = (lang == "en") and 0 or 0.1
	self.chipJP.BackgroundTransparency = (lang == "ja") and 0 or 0.1

	if typeof(Locale.setGlobal) == "function" then
		Locale.setGlobal(lang)
	end
	if self.patch and self.patch.setLanguage then
		self.patch:setLanguage(lang)
	end

	self:_refreshStartButton()

	if requestSave and self.deps and self.deps.remotes and self.deps.remotes.ReqSetLang then
		self.deps.remotes.ReqSetLang:FireServer(lang)
	end
end

--================ 文言適用 =================
function Home:applyLocaleTexts()
	local L = self._L
	if self.titleJP     then self.titleJP.Text     = L("MAIN_TITLE") end
	if self.titleEN     then self.titleEN.Text     = L("SUBTITLE") end
	-- ▼ ステータスは出さない
	if self.statusLabel then
		self.statusLabel.Text    = ""
		self.statusLabel.Visible = false
		self.statusLabel.Size    = UDim2.new(1,0,0,0)
	end
	if self.btnShrine    then self.btnShrine.Text    = L("BTN_SHRINE")   end
	if self.btnItems     then self.btnItems.Text     = L("BTN_ITEMS")    end
	if self.btnSettings  then self.btnSettings.Text  = L("BTN_SETTINGS") end
	if self.btnPatch     then self.btnPatch.Text     = Dget(self.Dict, "BTN_PATCH", "PATCH NOTES") end
	if self.betaLabel    then self.betaLabel.Text    = L("BETA_BADGE") end
end

--================ 表示/非表示 =================
function Home:show(payload)
	-- payload = { hasSave:bool, bank:number, year:number, clears:number, lang:"ja"|"en" }
	local plang = payload and tostring(payload.lang or ""):lower() or nil
	if plang == "jp" then plang = "ja" end
	if plang and (plang == "ja" or plang == "en") and plang ~= self.lang then
		self:setLanguage(plang, false)
	end

	self.hasSave = (payload and payload.hasSave == true) or false

	-- ▼ ステータスは出さない
	if self.statusLabel then
		self.statusLabel.Text    = ""
		self.statusLabel.Visible = false
		self.statusLabel.Size    = UDim2.new(1,0,0,0)
	end

	self.chipEN.BackgroundTransparency = (self.lang == "en") and 0 or 0.1
	self.chipJP.BackgroundTransparency = (self.lang == "ja") and 0 or 0.1

	if typeof(Locale.setGlobal) == "function" then
		Locale.setGlobal(self.lang)
	end

	self.gui.Enabled = true
	self:_refreshStartButton()
end

function Home:hide()
	self.gui.Enabled = false
end

return Home
