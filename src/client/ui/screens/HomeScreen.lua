-- StarterPlayerScripts/UI/screens/HomeScreen.lua
-- START GAME / 神社 / 持ち物 / 設定 / パッチノート（別モジュール化）
-- 言語切替（EN/JA）対応：保存(lang)があればそれを優先、無ければOS基準
-- v0.9.5-P0-6/10:
--  - HomeOpen 到着まで START を無効化（ラベル「同期中…/Syncing…」）
--  - HomeOpen 受信後に hasSave を反映して START を有効化
--  - 言語コードは外部公開を "ja" / "en" に統一（"jp" を使わない）
--  - START文言は言語切替時に「同期中…」へ戻さない（_refreshStartButtonで一元管理）
--  - 右端の安全余白、PatchNotes分離 など従来機能は維持

local Home = {}
Home.__index = Home

--========================
-- Services / Locale
--========================
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local Locale  = require(RS:WaitForChild("Config"):WaitForChild("Locale"))
local PatchNotesModal = require(script.Parent:WaitForChild("PatchNotesModal"))

-- ★ 右端の安全余白（必要に応じて増減）
local RIGHT_SAFE_PAD = 32 -- px 例: 32/40/48 に調整可

local function detectOSLang()
	local lp  = Players.LocalPlayer
	local lid = (lp and lp.LocaleId) and string.lower(lp.LocaleId) or "en-us"
	return (string.sub(lid, 1, 2) == "ja") and "ja" or "en"
end

local function pickLang(forced)
	-- 優先: 明示指定 → Locale.pick() → OS
	if forced == "ja" or forced == "en" then return forced end
	if typeof(Locale.pick) == "function" then
		local ok, v = pcall(Locale.pick)
		if ok and (v == "ja" or v == "en") then return v end
	end
	return detectOSLang()
end

local function makeL(dict) return function(k) return dict[k] or k end end

-- 直接辞書を参照してフォールバック文字列を返すユーティリティ
local function Dget(dict, key, fallback)
	return (dict and dict[key]) or fallback
end

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

-- ★ HomeOpen前のSTARTラベル
local function syncingLabel(lang: string, dict)
	if lang == "ja" then
		return Dget(dict, "BTN_SYNCING", "同期中…")
	else
		return Dget(dict, "BTN_SYNCING", "Syncing…")
	end
end

--========================
-- Class
--========================
function Home.new(deps)
	local self = setmetatable({}, Home)
	self.deps = deps
	self.hasSave = false -- HomeOpen から受け取って保持（STARTラベル切替に使用）

	-- 言語（初期は保存/明示→OSの順）
	self.lang = pickLang(deps and deps.lang)
	-- Locale.get を優先（ja/en の内部正規化を尊重）
	self.Dict = (typeof(Locale.get)=="function" and Locale.get(self.lang)) or Locale[self.lang] or Locale.en
	self._L   = makeL(self.Dict)
	-- ★ 現在言語をクライアント全体にも共有（Router/Run/Shopでも使う）
	if typeof(Locale.setGlobal) == "function" then
		Locale.setGlobal(self.lang)
	end

	-- ルートGUI
	local g = Instance.new("ScreenGui")
	g.Name             = "HomeScreen"
	g.ResetOnSpawn     = false
	g.IgnoreGuiInset   = true
	g.DisplayOrder     = 100
	g.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
	g.Enabled          = false
	self.gui           = g

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

	-- ★ ボタン構成（START / SHRINE / ITEMS / SETTINGS / PATCH NOTES）
	self.btnStart     = makeBtn("") -- 文言は後で適用（HomeOpenまで同期中表示）
	self.btnShrine    = makeBtn("")
	self.btnItems     = makeBtn("")
	self.btnSettings  = makeBtn("")
	self.btnPatch     = makeBtn("")

	--========================
	-- BETA バッジ
	--========================
	local beta = Instance.new("TextLabel")
	beta.Name                   = "BetaBadge"
	beta.AnchorPoint            = Vector2.new(1,1)
	beta.Position               = UDim2.new(1, -(16 + RIGHT_SAFE_PAD), 1, -12) -- ← 右余白を追加
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
	langBox.Position               = UDim2.new(1, -(16 + RIGHT_SAFE_PAD), 0, 16) -- ← 右余白を追加
	langBox.BackgroundColor3       = Color3.fromRGB(20,22,28)
	langBox.BackgroundTransparency = 0.25
	langBox.ZIndex                 = 3
	langBox.AutomaticSize          = Enum.AutomaticSize.XY -- 中身に合わせて自動拡張
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

	--========================
	-- ★ Patch Notes モーダル（別モジュール）
	--========================
	self.patch = PatchNotesModal.new({
		parentGui = self.gui,
		lang      = self.lang, -- 'ja' / 'en'
		Locale    = Locale,
	})

	--========================
	-- イベント
	--========================
	self.btnStart.Activated:Connect(function()
		-- ✅ RoundReady を待って Run 画面へ（ここでは Home を閉じるのみ）
		local r = self.deps and self.deps.remotes or self.deps
		-- 新：統合エントリ（推奨）
		if r and r.ReqStartGame then
			r.ReqStartGame:FireServer()
		else
			-- 旧：後方互換（スナップ有→CONTINUE / 無→NEW）
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

	-- ★ パッチノート：モーダルを開く
	self.btnPatch.Activated:Connect(function()
		self.patch:show()
	end)

	-- 言語切替ボタン（内部コードは "ja"/"en"）
	self.chipEN.Activated:Connect(function() self:setLanguage("en", true) end)
	self.chipJP.Activated:Connect(function() self:setLanguage("ja", true) end)

	-- 初回の文言適用（STARTはここでは触らない）
	self:applyLocaleTexts()
	self:_refreshStartButton()

	return self
end

--========================
-- 内部：STARTボタンの文言/可否を一元管理
--========================
function Home:_refreshStartButton()
	if not self.btnStart then return end
	if self.gui and self.gui.Enabled then
		-- HomeOpen 到着後：CONTINUE / Start Game を表示し、押下可
		if self.hasSave then
			self.btnStart.Text = Dget(self.Dict, "BTN_CONT", "CONTINUE")
		else
			self.btnStart.Text = Dget(self.Dict, "BTN_START", "Start Game")
		end
		setInteractable(self.btnStart, true)
	else
		-- HomeOpen 以前：同期中＋無効化
		self.btnStart.Text = syncingLabel(self.lang, self.Dict)
		setInteractable(self.btnStart, false)
	end
end

--========================
-- 言語切替 / テキスト適用
--========================
function Home:setLanguage(lang: string, requestSave: boolean?)
	if lang ~= "ja" and lang ~= "en" then return end
	if self.lang == lang then return end

	self.lang = lang
	self.Dict = (typeof(Locale.get)=="function" and Locale.get(self.lang)) or Locale[self.lang] or Locale.en
	self._L   = makeL(self.Dict)

	-- 静的テキストを更新（STARTは触らない）
	self:applyLocaleTexts()

	-- 見た目の選択状態（簡易ハイライト）
	self.chipEN.BackgroundTransparency = (lang == "en") and 0 or 0.1
	self.chipJP.BackgroundTransparency = (lang == "ja") and 0 or 0.1

	-- ★ 現在言語をグローバルにも反映（Router/Run/Shopの自動注入で使用）
	if typeof(Locale.setGlobal) == "function" then
		Locale.setGlobal(lang)
	end

	-- モーダルにも言語反映
	if self.patch and self.patch.setLanguage then
		self.patch:setLanguage(lang)
	end

	-- START の文言/可否を現在状態に合わせて再適用
	self:_refreshStartButton()

	-- サーバ保存（任意・存在すれば）
	if requestSave and self.deps and self.deps.remotes and self.deps.remotes.ReqSetLang then
		self.deps.remotes.ReqSetLang:FireServer(lang)
	end
end

-- 文言を一括適用（静的部分）
function Home:applyLocaleTexts()
	local L = self._L
	-- タイトル/サブタイトル
	if self.titleJP     then self.titleJP.Text     = L("MAIN_TITLE") end
	if self.titleEN     then self.titleEN.Text     = L("SUBTITLE") end
	-- ステータス初期表示（HomeOpenで実値に更新）
	if self.statusLabel then
		self.statusLabel.Text = string.format(L("STATUS_FMT"), L("UNSET_YEAR"), 0, 0)
	end
	-- メニュー（STARTはここで触らない）
	if self.btnShrine    then self.btnShrine.Text    = L("BTN_SHRINE")   end
	if self.btnItems     then self.btnItems.Text     = L("BTN_ITEMS")    end
	if self.btnSettings  then self.btnSettings.Text  = L("BTN_SETTINGS") end
	if self.btnPatch     then self.btnPatch.Text     = Dget(self.Dict, "BTN_PATCH", "PATCH NOTES") end
	if self.betaLabel    then self.betaLabel.Text    = L("BETA_BADGE")   end
end

function Home:show(payload)
	-- payload = { hasSave:bool, bank:number, year:number, clears:number, lang:"ja"|"en" }
	-- 言語（保存値が来ていれば適用）："jp" が来ても互換で "ja" に吸収
	local plang = payload and tostring(payload.lang or ""):lower() or nil
	if plang == "jp" then plang = "ja" end
	if plang and (plang == "ja" or plang == "en") and plang ~= self.lang then
		self:setLanguage(plang, false)
	end

	self.hasSave = (payload and payload.hasSave == true) or false
	local bank    = (payload and tonumber(payload.bank))   or 0
	local year    = (payload and tonumber(payload.year))   or 0
	local clears  = (payload and tonumber(payload.clears)) or 0

	-- ステータス更新
	local L = self._L
	local yearTxt = (year > 0) and tostring(year) or L("UNSET_YEAR")
	if self.statusLabel then
		self.statusLabel.Text = string.format(L("STATUS_FMT"), yearTxt, bank, clears)
	end

	-- チップ選択状態の見た目
	self.chipEN.BackgroundTransparency = (self.lang == "en") and 0 or 0.1
	self.chipJP.BackgroundTransparency = (self.lang == "ja") and 0 or 0.1

	-- ★ 念のためグローバル言語を再同期
	if typeof(Locale.setGlobal) == "function" then
		Locale.setGlobal(self.lang)
	end

	-- HomeOpen 到着：GUI有効化→STARTを適切に更新
	self.gui.Enabled = true
	self:_refreshStartButton()
end

function Home:hide()
	self.gui.Enabled = false
	-- 非表示時の START 文言は _refreshStartButton が次回呼びで同期中へ戻す
end

return Home
