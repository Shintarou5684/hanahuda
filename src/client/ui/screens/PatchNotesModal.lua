-- StarterPlayerScripts/UI/screens/PatchNotesModal.lua
-- v0.9.4 Patch Notes: 前面フルスクリーンモーダル（スクロール）
-- ・Config/PatchNotes.lua があればそれを優先（RichText対応）
-- ・Locale辞書の PATCH_TITLE / PATCH_BODY をフォールバックで使用
-- ・Home からは new() → :show() / :hide() / :setLanguage() を呼ぶだけ

local Patch = {}
Patch.__index = Patch

local RS = game:GetService("ReplicatedStorage")

-- PatchNotes を安全にロード（任意ファイル）
local function safeLoadPatchNotes()
	local ok, mod = pcall(function()
		local cfg = RS:FindFirstChild("Config")
		if not cfg then return nil end
		local src = cfg:FindFirstChild("PatchNotes")
		return src and require(src) or nil
	end)
	if ok and type(mod) == "table" then
		return mod
	end
	return nil
end

local function makeL(dict) return function(k) return dict[k] or k end end
local function Dget(dict, key, fallback) return (dict and dict[key]) or fallback end

--========================
-- Ctor
--========================
-- opts = { parentGui:ScreenGui, lang:"jp"|"en", Locale:table }
function Patch.new(opts)
	local self = setmetatable({}, Patch)

	self.Locale = (opts and opts.Locale) or require(RS:WaitForChild("Config"):WaitForChild("Locale"))
	self.lang   = (opts and opts.lang == "jp") and "jp" or "en"
	self.Dict   = self.Locale[self.lang] or self.Locale.en
	self._L     = makeL(self.Dict)
	self.parent = opts and opts.parentGui

	self.PatchNotes = safeLoadPatchNotes()

	-- ルート（画面全体、最前面）
	local root = Instance.new("Frame")
	root.Name                   = "PatchModal"
	root.Size                   = UDim2.fromScale(1,1)
	root.BackgroundColor3       = Color3.fromRGB(0,0,0)
	root.BackgroundTransparency = 0.35
	root.ZIndex                 = 50
	root.Visible                = false
	if self.parent then root.Parent = self.parent end
	self.root = root

	-- クリック吸収
	local blocker = Instance.new("TextButton")
	blocker.Name                   = "Blocker"
	blocker.Size                   = UDim2.fromScale(1,1)
	blocker.BackgroundTransparency = 1
	blocker.Text                   = ""
	blocker.AutoButtonColor        = false
	blocker.ZIndex                 = 50
	blocker.Parent                 = root
	-- 背景クリックで閉じたい時はコメントアウト解除
	-- blocker.Activated:Connect(function() self:hide() end)

	-- パネル
	local panel = Instance.new("Frame")
	panel.Name                   = "Panel"
	panel.AnchorPoint            = Vector2.new(0.5, 0.5)
	panel.Position               = UDim2.fromScale(0.5, 0.5)
	panel.Size                   = UDim2.new(0.84, 0, 0.78, 0)
	panel.BackgroundColor3       = Color3.fromRGB(24,26,34)
	panel.BackgroundTransparency = 0.05
	panel.ZIndex                 = 55
	panel.Parent                 = root
	local round = Instance.new("UICorner"); round.CornerRadius = UDim.new(0,16); round.Parent = panel
	local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(70,75,90); stroke.Thickness = 1; stroke.Parent = panel

	-- ヘッダ（タイトル＋閉じる）
	local header = Instance.new("Frame")
	header.Name                   = "Header"
	header.Size                   = UDim2.new(1, 0, 0, 52)
	header.BackgroundTransparency = 1
	header.ZIndex                 = 56
	header.Parent                 = panel

	local title = Instance.new("TextLabel")
	title.Name                   = "Title"
	title.Position               = UDim2.new(0, 20, 0, 8)
	title.Size                   = UDim2.new(1, -80, 1, -8)
	title.BackgroundTransparency = 1
	title.Font                   = Enum.Font.GothamBold
	title.TextSize               = 24
	title.TextXAlignment         = Enum.TextXAlignment.Left
	title.TextColor3             = Color3.fromRGB(240,240,240)
	title.ZIndex                 = 56
	title.Parent                 = header
	self.titleLbl = title

	local close = Instance.new("TextButton")
	close.Name                   = "Close"
	close.AnchorPoint            = Vector2.new(1,0)
	close.Position               = UDim2.new(1, -12, 0, 10)
	close.Size                   = UDim2.new(0, 36, 0, 32)
	close.BackgroundColor3       = Color3.fromRGB(36,40,52)
	close.BackgroundTransparency = 0.1
	close.AutoButtonColor        = true
	close.Text                   = "×"
	close.Font                   = Enum.Font.GothamBold
	close.TextSize               = 22
	close.TextColor3             = Color3.fromRGB(235,235,235)
	close.ZIndex                 = 57
	close.Parent                 = header
	local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 8); cr.Parent = close
	local cs = Instance.new("UIStroke"); cs.Color = Color3.fromRGB(70,75,90); cs.Thickness = 1; cs.Parent = close
	close.Activated:Connect(function() self:hide() end)

	-- ボディ（スクロール）
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name                    = "BodyScroll"
	scroll.AnchorPoint            = Vector2.new(0.5, 0)
	scroll.Position               = UDim2.new(0.5, 0, 0, 56)
	scroll.Size                   = UDim2.new(1, -24, 1, -66)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
	scroll.ScrollBarThickness     = 8
	scroll.AutomaticCanvasSize    = Enum.AutomaticSize.None
	scroll.ZIndex                 = 55
	scroll.Parent                 = panel
	self.scroll = scroll

	local body = Instance.new("TextLabel")
	body.Name                   = "Body"
	body.Size                   = UDim2.new(1, -20, 0, 0)
	body.Position               = UDim2.new(0, 10, 0, 6)
	body.BackgroundTransparency = 1
	body.Font                   = Enum.Font.Gotham
	body.TextSize               = 18
	body.TextXAlignment         = Enum.TextXAlignment.Left
	body.TextYAlignment         = Enum.TextYAlignment.Top
	body.TextWrapped            = true
	body.RichText               = true
	body.TextColor3             = Color3.fromRGB(235,235,235)
	body.ZIndex                 = 55
	body.Parent                 = scroll
	self.bodyLbl = body

	-- テキスト変化でリサイズ
	body:GetPropertyChangedSignal("TextBounds"):Connect(function()
		local h = math.max(0, body.TextBounds.Y)
		body.Size = UDim2.new(1, -20, 0, h + 8)
		scroll.CanvasSize = UDim2.new(0, 0, 0, h + 20)
	end)

	-- 初期テキスト反映
	self:_applyText()

	return self
end

--========================
-- 内部：文字列の決定と適用
--========================
function Patch:_getStrings()
	-- 既定値（Locale辞書）
	local title = Dget(self.Dict, "PATCH_TITLE", "Patch Notes")
			local body  = Dget(self.Dict, "PATCH_BODY", [[<b>Coming soon...</b>
We’ll post detailed changes here.]])


	-- Config/PatchNotes.lua があれば優先
	-- return { title = {jp=..., en=...}, body={jp=..., en=...} } を想定
	if self.PatchNotes then
		local lang = (self.lang == "jp") and "jp" or "en"
		local t = self.PatchNotes.title
		if type(t) == "table" and type(t[lang]) == "string" then
			title = t[lang]
		elseif type(self.PatchNotes["title_"..lang]) == "string" then
			title = self.PatchNotes["title_"..lang]
		end
		local b = self.PatchNotes.body
		if type(b) == "table" and type(b[lang]) == "string" then
			body = b[lang]
		elseif type(self.PatchNotes["body_"..lang]) == "string" then
			body = self.PatchNotes["body_"..lang]
		end
	end
	return title, body
end

function Patch:_applyText()
	local title, body = self:_getStrings()
	if self.titleLbl then self.titleLbl.Text = title end
	if self.bodyLbl  then self.bodyLbl.Text  = body  end
	-- スクロール位置を先頭へ
	if self.scroll then self.scroll.CanvasPosition = Vector2.new(0,0) end
end

--========================
-- API
--========================
function Patch:setLanguage(lang)
	if lang ~= "jp" and lang ~= "en" then return end
	if self.lang == lang then return end
	self.lang = lang
	self.Dict = self.Locale[self.lang] or self.Locale.en
	self._L   = makeL(self.Dict)
	self:_applyText()
end

function Patch:show()
	if self.root then self.root.Visible = true end
end

function Patch:hide()
	if self.root then self.root.Visible = false end
end

return Patch
