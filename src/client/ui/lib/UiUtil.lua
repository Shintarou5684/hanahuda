-- StarterPlayerScripts/UI/lib/UiUtil.lua
-- ラベル作成・子要素クリア・汎用ボタン作成の小物ユーティリティ
-- v0.9.7-P1-4: Theme に完全寄せ（色／角丸／枠線／余白のフォールバック撤去）
-- 既存APIは互換維持（makeLabel / clear / makeTextBtn）。加えて便利関数を少量追加。

local RS = game:GetService("ReplicatedStorage")

-- 任意 Theme（あれば使う）
local Theme: any = nil
do
	local cfg = RS:FindFirstChild("Config")
	if cfg and cfg:FindFirstChild("Theme") then
		local ok, t = pcall(function() return require(cfg.Theme) end)
		if ok then Theme = t end
	end
end

local C = (Theme and Theme.COLORS) or {}
local S = (Theme and Theme.SIZES)  or {}
local RADIUS = (Theme and Theme.PANEL_RADIUS) or 10

local U = {}

--==================================================
-- 内部ヘルパ
--==================================================
local function _addCornerStroke(frame: Instance, radiusPx: number?, strokeColor: Color3?, thickness: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radiusPx or RADIUS)
	corner.Parent = frame
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1
	s.Color = strokeColor or C.PanelStroke or Color3.fromRGB(210, 210, 210)
	s.Transparency = 0
	s.Parent = frame
	return frame
end

local function _btnPalette(style: string?): (Color3, Color3)
	style = tostring(style or "neutral")
	if style == "primary" then
		return (C.PrimaryBtnBg or Color3.fromRGB(190,50,50)),
		       (C.PrimaryBtnText or Color3.fromRGB(255,245,240))
	elseif style == "warn" then
		return (C.WarnBtnBg or Color3.fromRGB(180,80,40)),
		       (C.WarnBtnText or Color3.fromRGB(255,240,230))
	elseif style == "info" then
		return (C.InfoBtnBg or Color3.fromRGB(120,180,255)),
		       (C.TextDefault or Color3.fromRGB(25,25,25))
	elseif style == "dev" then
		return (C.DevBtnBg or Color3.fromRGB(40,100,60)),
		       (C.DevBtnText or Color3.fromRGB(255,255,255))
	elseif style == "cancel" then
		return (C.CancelBtnBg or Color3.fromRGB(120,130,140)),
		       (C.CancelBtnText or Color3.fromRGB(240,240,240))
	else -- neutral
		return (C.CancelBtnBg or Color3.fromRGB(120,130,140)),
		       (C.CancelBtnText or Color3.fromRGB(240,240,240))
	end
end

--==================================================
-- ラベル生成（RunScreen の makeLabel と同じ引数順）
--==================================================
function U.makeLabel(parent: Instance, name: string, text: string?, size: UDim2?, pos: UDim2?, anchor: Vector2?, color: Color3?)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Parent = parent
	l.BackgroundTransparency = 1
	l.Text = text or ""
	l.TextScaled = true
	l.Size = size or UDim2.new(0,100,0,24)
	l.Position = pos or UDim2.new(0,0,0,0)
	if anchor then l.AnchorPoint = anchor end
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.TextColor3 = color or C.TextDefault or Color3.fromRGB(20,20,20)
	return l
end

--==================================================
-- 子要素を全消し
-- exceptNames: {"KeepThis","AndThat"} のように残したい子の名前配列（任意）
-- ※ UIListLayout / UIPadding などレイアウト系も**全部**消します（二重生成防止）
--==================================================
function U.clear(container: Instance, exceptNames: {string}? )
	local except = {}
	if typeof(exceptNames) == "table" then
		for _,n in ipairs(exceptNames) do except[n] = true end
	end
	for _,child in ipairs(container:GetChildren()) do
		if not except[child.Name] then
			child:Destroy()
		end
	end
end

--==================================================
-- 汎用テキストボタン（角丸＋UIStroke）
-- size/pos はそのまま渡す（RunScreen 側のレイアウトに合わせる）
-- bgColor が未指定なら Theme の "neutral(=cancel系)" を既定採用
--==================================================
function U.makeTextBtn(parent: Instance, text: string, size: UDim2?, pos: UDim2?, bgColor: Color3?)
	local b = Instance.new("TextButton")
	b.Parent = parent
	b.Text = text
	b.TextScaled = true
	b.AutoButtonColor = true
	b.Size = size or UDim2.new(0,120,0,math.max(36, S.CONTROLS_H or 36))
	b.Position = pos or UDim2.new(0,0,0,0)
	b.BackgroundColor3 = bgColor or (C.CancelBtnBg or Color3.fromRGB(120,130,140))
	b.BorderSizePixel = 0
	b.TextColor3 = C.CancelBtnText or Color3.fromRGB(240,240,240)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, RADIUS); c.Parent = b
	local s = Instance.new("UIStroke"); s.Color = C.PanelStroke or Color3.fromRGB(210,210,210); s.Thickness = 1; s.Parent = b
	return b
end

--==================================================
-- 追加：ボタンスタイル適用（"primary"|"warn"|"cancel"|"info"|"dev"|"neutral"）
--==================================================
function U.styleButton(btn: TextButton, style: string?)
	if not (btn and btn:IsA("TextButton")) then return end
	local bg, tx = _btnPalette(style)
	btn.BackgroundColor3 = bg
	btn.TextColor3 = tx
	-- 元色も属性に保存（ResultModal 等のロック切替用）
	btn:SetAttribute("OrigBG3", bg)
	btn:SetAttribute("OrigTX3", tx)
end

--==================================================
-- 追加：パネル作成（角丸＋枠線つき）
-- size: UDim2（Scale/Offsetどちらでも） / layoutOrder 任意
-- titleText を渡すと左上にタイトルラベルを内包
--==================================================
function U.makePanel(parent: Instance, name: string, size: UDim2, layoutOrder: number?, titleText: string?, titleColor: Color3?)
	local f = Instance.new("Frame")
	f.Name = name
	f.Parent = parent
	f.Size = size
	f.LayoutOrder = layoutOrder or 1
	f.BackgroundColor3 = C.PanelBg or Color3.fromRGB(255,255,255)
	_addCornerStroke(f, RADIUS, C.PanelStroke, 1)

	if titleText and titleText ~= "" then
		local title = U.makeLabel(f, name.."Title", titleText, UDim2.new(1, - (S.PAD or 10)*2, 0, 24), UDim2.new(0, (S.PAD or 10), 0, (S.PAD or 10)), nil, titleColor or C.TextDefault)
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = f.ZIndex + 1
	end
	return f
end

--==================================================
-- 追加：共通 Padding（左右PADをThemeから）
--==================================================
function U.addSidePadding(frame: Instance, padPx: number?)
	local p = Instance.new("UIPadding")
	local px = padPx or (S.PAD or 10)
	p.PaddingLeft  = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = frame
	return p
end

return U
