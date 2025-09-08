-- StarterPlayerScripts/UI/screens/HomeScreen.lua
-- NEW GAME / 神社 / 持ち物 / 設定 / CONTINUE
-- 言語切替（EN/JP）対応：保存(lang)があればそれを優先、無ければOS基準

local Home = {}
Home.__index = Home

--========================
-- Services / Locale
--========================
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local Locale  = require(RS:WaitForChild("Config"):WaitForChild("Locale"))

local function detectOSLang()
	local lp  = Players.LocalPlayer
	local lid = (lp and lp.LocaleId) and string.lower(lp.LocaleId) or "en-us"
	return (string.sub(lid, 1, 2) == "ja") and "jp" or "en"
end

local function pickLang(forced)
	-- 優先: 明示指定 → Locale.pick() → OS
	if forced == "jp" or forced == "en" then return forced end
	if typeof(Locale.pick) == "function" then
		local ok, v = pcall(Locale.pick)
		if ok and (v == "jp" or v == "en") then return v end
	end
	return detectOSLang()
end

local function makeL(dict) return function(k) return dict[k] or k end end

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

	-- 言語（初期は保存/明示→OSの順）
	self.lang   = pickLang(deps and deps.lang)
	self.Dict   = Locale[self.lang] or Locale.en
	self._L     = makeL(self.Dict)
	-- ★ 現在言語をクライアント全体にも共有（Router/Run/Shopでも使う）
	if typeof(Locale.setGlobal) == "function" then
		Locale.setGlobal(self.lang)
	end

	-- ルートGUI
	local g = Instance.new("ScreenGui")
	g.Name           = "HomeScreen"
	g.ResetOnSpawn   = false
	g.IgnoreGuiInset = true
	g.DisplayOrder   = 100
	g.Enabled        = false
	self.gui         = g

	--========================
	-- 背景
	--========================
	local bg = Instance.new("ImageLabel")
	bg.Name                   = "Background"
	bg.Size                   = UDim2.fromScale(1,1)
	bg.Position               = UDim2.fromOffset(0,0)
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

	--========================
	-- 前景レイヤ
	--========================
	local ui = Instance.new("Frame")
	ui.Name                   = "UIRoot"
	ui.Size                   = UDim2.fromScale(1,1)
	ui.BackgroundTransparency = 1
	ui.ZIndex                 = 2
	ui.Parent                 = g

	-- タイトル
	self.titleJP = Instance.new("TextLabel")
	self.titleJP.Name                   = "TitleJP"
	self.titleJP.Size                   = UDim2.new(1,0,0,76)
	self.titleJP.Position               = UDim2.new(0,0,0,36)
	self.titleJP.BackgroundTransparency = 1
	self.titleJP.Font                   = Enum.Font.GothamBlack
	self.titleJP.TextScaled             = true
	self.titleJP.TextColor3             = Color3.fromRGB(245,245,245)
	self.titleJP.TextStrokeColor3       = Color3.fromRGB(0,0,0)
	self.titleJP.TextStrokeTransparency = 0.25
	self.titleJP.ZIndex                 = 2
	self.titleJP.Parent                 = ui

	self.titleEN = Instance.new("TextLabel")
	self.titleEN.Name                   = "TitleEN"
	self.titleEN.Size                   = UDim2.new(1,0,0,38)
	self.titleEN.Position               = UDim2.new(0,0,0,104)
	self.titleEN.BackgroundTransparency = 1
	self.titleEN.Font                   = Enum.Font.Gotham
	self.titleEN.TextScaled             = true
	self.titleEN.TextColor3             = Color3.fromRGB(235,235,235)
	self.titleEN.TextStrokeColor3       = Color3.fromRGB(0,0,0)
	self.titleEN.TextStrokeTransparency = 0.35
	self.titleEN.ZIndex                 = 2
	self.titleEN.Parent                 = ui

	-- ステータス
	self.statusLabel = Instance.new("TextLabel")
	self.statusLabel.Name                   = "Status"
	self.statusLabel.Size                   = UDim2.new(1,0,0,26)
	self.statusLabel.Position               = UDim2.new(0,0,0,146)
	self.statusLabel.BackgroundTransparency = 1
	self.statusLabel.Font                   = Enum.Font.Gotham
	self.statusLabel.TextSize               = 20
	self.statusLabel.TextColor3             = Color3.fromRGB(230,230,230)
	self.statusLabel.TextStrokeColor3       = Color3.fromRGB(0,0,0)
	self.statusLabel.TextStrokeTransparency = 0.6
	self.statusLabel.TextXAlignment         = Enum.TextXAlignment.Center
	self.statusLabel.ZIndex                 = 2
	self.statusLabel.Parent                 = ui

	--========================
	-- メニュー
	--========================
	local menu = Instance.new("Frame")
	menu.Name                   = "Menu"
	menu.Size                   = UDim2.new(0, 360, 0, 10)
	menu.AutomaticSize          = Enum.AutomaticSize.Y
	menu.BackgroundTransparency = 1
	menu.AnchorPoint            = Vector2.new(0.5, 0.5)
	menu.Position               = UDim2.fromScale(0.5, 0.55)
	menu.ZIndex                 = 2
	menu.Parent                 = ui

	local layout = Instance.new("UIListLayout")
	layout.Padding              = UDim.new(0, 10)
	layout.HorizontalAlignment  = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment    = Enum.VerticalAlignment.Center
	layout.SortOrder            = Enum.SortOrder.LayoutOrder
	layout.Parent               = menu

	local function makeBtn(text: string)
		local b = Instance.new("TextButton")
		b.Size                   = UDim2.new(1, 0, 0, 56)
		b.BackgroundColor3       = Color3.fromRGB(30,34,44)
		b.BackgroundTransparency = 0.12
		b.BorderSizePixel        = 0
		b.AutoButtonColor        = true
		b.Text                   = text
		b.TextColor3             = Color3.fromRGB(235,235,235)
		b.Font                   = Enum.Font.GothamMedium
		b.TextSize               = 22
		b.ZIndex                 = 2
		b.Parent                 = menu

		local uic = Instance.new("UICorner"); uic.CornerRadius = UDim.new(0, 12); uic.Parent = b
		local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(70,75,90); stroke.Thickness = 1; stroke.Parent = b
		local shadow = Instance.new("UIStroke"); shadow.Color = Color3.fromRGB(0,0,0); shadow.Thickness = 3; shadow.Transparency = 0.9; shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; shadow.Parent = b
		return b
	end

	self.btnNew      = makeBtn("") -- 後で文言を適用
	self.btnShrine   = makeBtn("")
	self.btnItems    = makeBtn("")
	self.btnSettings = makeBtn("")
	self.btnCont     = makeBtn("")

	--========================
	-- BETA バッジ
	--========================
	local beta = Instance.new("TextLabel")
	beta.Name                   = "BetaBadge"
	beta.AnchorPoint            = Vector2.new(1,1)
	beta.Position               = UDim2.new(1, -16, 1, -12)
	beta.BackgroundTransparency = 0.25
	beta.BackgroundColor3       = Color3.fromRGB(20,22,28)
	beta.Font                   = Enum.Font.GothamBold
	beta.TextSize               = 16
	beta.TextColor3             = Color3.fromRGB(255,255,255)
	beta.ZIndex                 = 3
	beta.Parent                 = ui
	local betaCorner = Instance.new("UICorner"); betaCorner.CornerRadius = UDim.new(0, 8); betaCorner.Parent = beta
	local betaPad = Instance.new("UIPadding")
	betaPad.PaddingLeft   = UDim.new(0,10)
	betaPad.PaddingRight  = UDim.new(0,10)
	betaPad.PaddingTop    = UDim.new(0,4)
	betaPad.PaddingBottom = UDim.new(0,4)
	betaPad.Parent        = beta
	self.betaLabel = beta

	--========================
	-- 言語スイッチ（右上）
	--========================
	local langBox = Instance.new("Frame")
	langBox.Name                   = "LangBox"
	langBox.AnchorPoint            = Vector2.new(1,0)
	langBox.Position               = UDim2.new(1, -16, 0, 16)
	langBox.BackgroundColor3       = Color3.fromRGB(20,22,28)
	langBox.BackgroundTransparency = 0.25
	langBox.ZIndex                 = 3
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
	self.chipJP = makeChip("JP")

	--========================
	-- イベント
	--========================
self.btnNew.Activated:Connect(function()
	-- ✅ 先に画面を開かない：RoundReady を待って run を開く
	if self.deps and self.deps.remotes and self.deps.remotes.ReqStartNewRun then
		self.deps.remotes.ReqStartNewRun:FireServer()
	elseif self.deps and self.deps.ReqStartNewRun then
		self.deps.ReqStartNewRun:FireServer()
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

	self.btnCont.Activated:Connect(function()
		if not self.btnCont.Active then return end
		notify(self._L("CONTINUE_STUB_TITLE"), self._L("CONTINUE_STUB_TEXT"), 2)
	end)

	-- 言語切替ボタン
	self.chipEN.Activated:Connect(function() self:setLanguage("en", true) end)
	self.chipJP.Activated:Connect(function() self:setLanguage("jp", true) end)

	-- 初回の文言適用
	self:applyLocaleTexts()

	-- CONTINUEは初期無効（HomeOpenで切替）
	setInteractable(self.btnCont, false)

	return self
end

-- 言語を変更（local適用＋保存をリクエスト）
function Home:setLanguage(lang: string, requestSave: boolean?)
	if lang ~= "jp" and lang ~= "en" then return end
	if self.lang == lang then return end

	self.lang = lang
	self.Dict = Locale[self.lang] or Locale.en
	self._L   = makeL(self.Dict)
	self:applyLocaleTexts()

	-- 見た目の選択状態（簡易ハイライト）
	self.chipEN.BackgroundTransparency = (lang == "en") and 0 or 0.1
	self.chipJP.BackgroundTransparency = (lang == "jp") and 0 or 0.1

	-- ★ 現在言語をグローバルにも反映（Router/Run/Shopの自動注入で使用）
	if typeof(Locale.setGlobal) == "function" then
		Locale.setGlobal(lang)
	end

	-- サーバ保存（任意・存在すれば）
	if requestSave and self.deps and self.deps.remotes and self.deps.remotes.ReqSetLang then
		self.deps.remotes.ReqSetLang:FireServer(lang)
	end
end

-- 文言を一括適用
function Home:applyLocaleTexts()
	local L = self._L
	if self.titleJP     then self.titleJP.Text     = L("MAIN_TITLE") end
	if self.titleEN     then self.titleEN.Text     = L("SUBTITLE") end
	if self.statusLabel then
		self.statusLabel.Text = string.format(L("STATUS_FMT"), L("UNSET_YEAR"), 0, 0)
	end
	if self.btnNew      then self.btnNew.Text      = L("BTN_NEW")      end
	if self.btnShrine   then self.btnShrine.Text   = L("BTN_SHRINE")   end
	if self.btnItems    then self.btnItems.Text    = L("BTN_ITEMS")    end
	if self.btnSettings then self.btnSettings.Text = L("BTN_SETTINGS") end
	if self.btnCont     then self.btnCont.Text     = L("BTN_CONT")     end
	if self.betaLabel   then self.betaLabel.Text   = L("BETA_BADGE")   end
end

function Home:show(payload)
	-- payload = { hasSave:bool, bank:number, year:number, clears:number, lang:"jp"|"en" }
	-- 言語（保存値が来ていれば適用）
	if payload and (payload.lang == "jp" or payload.lang == "en") and payload.lang ~= self.lang then
		self:setLanguage(payload.lang, false)
	end

	local hasSave = payload and payload.hasSave == true
	local bank    = (payload and tonumber(payload.bank))   or 0
	local year    = (payload and tonumber(payload.year))   or 0
	local clears  = (payload and tonumber(payload.clears)) or 0

	setInteractable(self.btnCont, hasSave)

	local L = self._L
	local yearTxt = (year > 0) and tostring(year) or L("UNSET_YEAR")
	if self.statusLabel then
		self.statusLabel.Text = string.format(L("STATUS_FMT"), yearTxt, bank, clears)
	end

	-- チップ選択状態の見た目
	self.chipEN.BackgroundTransparency = (self.lang == "en") and 0 or 0.1
	self.chipJP.BackgroundTransparency = (self.lang == "jp") and 0 or 0.1

	-- ★ 念のためグローバル言語を再同期
	if typeof(Locale.setGlobal) == "function" then
		Locale.setGlobal(self.lang)
	end

	self.gui.Enabled = true
end

function Home:hide()
	self.gui.Enabled = false
end

return Home
