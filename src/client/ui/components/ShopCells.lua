-- StarterPlayerScripts/UI/components/ShopCells.lua
-- v0.9.I5 full-art + text-fallback
--  - KITO: アイコンが解決できたときはカード全面にフルアート表示
--  - 非KITO/アイコン未解決: 効果テキスト（ShopFormat.itemTitle）をカードに表示（faceName()にフォールバック）
--  - 価格バンドは下部固定、従来の診断ログ/安全化は維持

local RS           = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Shared
local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat    = require(SharedModules:WaitForChild("ShopFormat"))

-- Logger（診断）
local Logger = require(SharedModules:WaitForChild("Logger"))
local LOG    = Logger.scope("ShopCells")

-- Theme & Locale
local Config = RS:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

-- ★ ShopDefs（互換ID→正規ID）
local okDefs, ShopDefs = pcall(function()
	return require(SharedModules:WaitForChild("ShopDefs"))
end)

-- ★ 干支アイコン（厳格: kito.<animal> のみ受理）
--   このファイルは ui/components にあるので、ui/lib/KitoAssets を参照する
local KitoAssets do
	local ok, mod = pcall(function()
		return require(script.Parent.Parent:WaitForChild("lib"):WaitForChild("KitoAssets"))
	end)
	KitoAssets = ok and mod or nil
	if not KitoAssets then
		LOG.warn("[init] KitoAssets not found; KITO icons will be disabled on shop cells")
	end
end

local M = {}

--========================
-- 小ユーティリティ
--========================
local function _safeId(it:any): string
	local raw = tostring(it and it.id or "Item")
	return (raw:gsub("[^%w_%-]", "_"))
end

local function _getFaceName(it:any): string
	local ok, name = pcall(function() return ShopFormat.faceName(it) end)
	return (ok and tostring(name or "")) or ""
end

local function _fmtPrice(v:any): string
	local ok, s = pcall(function() return ShopFormat.fmtPrice(v) end)
	return (ok and tostring(s or "")) or tostring(v or "")
end

local function _title(it:any, lang:string): string
	local ok, s = pcall(function() return ShopFormat.itemTitle(it, lang) end)
	return (ok and tostring(s or "")) or ""
end

local function _desc(it:any, lang:string): string
	local ok, s = pcall(function() return ShopFormat.itemDesc(it, lang) end)
	return (ok and tostring(s or "")) or ""
end

local function _catLabel(it:any, lang:string): string
	local cat = tostring(it and it.category or "-")
	return Locale.t(lang, "SHOP_UI_LABEL_CATEGORY"):format(cat)
end

local function _priceLabel(it:any, lang:string): string
	return Locale.t(lang, "SHOP_UI_LABEL_PRICE"):format(_fmtPrice(it and it.price))
end

local function _computeAffordable(mon:any, price:any): boolean
	local m = tonumber(mon or 0) or 0
	local p = tonumber(price or 0) or 0
	return m >= p
end

local function _themeColor(path:string, fallback: Color3): Color3
	local col = fallback
	if Theme and Theme.COLORS and typeof(Theme.COLORS[path]) == "Color3" then
		col = Theme.COLORS[path]
	end
	return col
end

local function addCorner(gui: Instance, px: number?)
	local ok = pcall(function()
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, px or (Theme and Theme.PANEL_RADIUS) or 10)
		c.Parent = gui
	end)
	return ok
end

local function addStroke(gui: Instance, color: Color3?, thickness: number?, transparency: number?)
	local ok, stroke = pcall(function()
		local s = Instance.new("UIStroke")
		s.Thickness = thickness or 1
		s.Color = color or _themeColor("PanelStroke", Color3.fromRGB(70,70,80))
		s.Transparency = transparency or 0
		s.Parent = gui
		return s
	end)
	return ok and stroke or nil
end

local function _setAttributes(inst: Instance, it:any, lang:string, mon:number, affordable:boolean)
	if not (inst and typeof(inst.SetAttribute)=="function") then return end
	inst:SetAttribute("id", tostring(it and it.id or ""))
	inst:SetAttribute("category", tostring(it and it.category or ""))
	inst:SetAttribute("price", tonumber(it and it.price or 0) or 0)
	inst:SetAttribute("lang", lang)
	inst:SetAttribute("affordable", affordable and true or false)
	inst:SetAttribute("face", _getFaceName(it))
end

--========================
-- KITOフルアート背景（診断付き）
--========================
-- 成功したら true を返す（＝テキストを消してOK）
local function _applyKitoFullArt(btn: Instance, priceBand: Instance, it:any): boolean
	if not (btn and btn:IsA("GuiObject")) then return false end
	if not it then return false end
	if tostring(it.category) ~= "kito" then
		return false
	end
	if not KitoAssets then
		LOG.warn("[kito][skip] id=%s reason=KitoAssets-missing", tostring(it.id or "?"))
		return false
	end

	local effectRaw = tostring(it.effect or "")
	local effectCanon = effectRaw
	if okDefs and ShopDefs and type(ShopDefs.toCanonicalEffectId) == "function" then
		local ok, canon = pcall(ShopDefs.toCanonicalEffectId, effectRaw)
		if ok and canon and canon ~= "" then effectCanon = canon end
	end
	LOG.info("[kito][canon] id=%s raw=%s -> canon=%s", tostring(it.id or "?"), effectRaw, effectCanon)

	local icon
	local okGet, res = pcall(function() return KitoAssets.getIcon(effectCanon) end)
	if okGet then icon = res else LOG.warn("[kito][icon-error] id=%s err=%s", tostring(it.id or "?"), tostring(res)) end
	if not icon or icon == "" then
		LOG.warn("[kito][icon-miss] id=%s canon=%s (no icon)", tostring(it.id or "?"), effectCanon)
		return false
	end

	-- 既存の小アイコン破棄（あれば）
	local oldSmall = btn:FindFirstChild("KitoIcon")
	if oldSmall then oldSmall:Destroy() end

	-- 既存フルアート破棄してから再生成
	local oldArt = btn:FindFirstChild("KitoArt")
	if oldArt then oldArt:Destroy() end

	local art = Instance.new("ImageLabel")
	art.Name = "KitoArt"
	art.Image = icon
	art.BackgroundTransparency = 1
	art.ScaleType = Enum.ScaleType.Fit
	-- カード全面（下の価格バンド分だけ高さを差し引く）
	local priceH = 20
	if priceBand and priceBand:IsA("GuiObject") then
		local h = tonumber(priceBand.Size.Y.Offset) or priceH
		priceH = h
	end
	art.Size = UDim2.new(1, 0, 1, -priceH)
	art.Position = UDim2.new(0, 0, 0, 0)
	art.ZIndex = (btn.ZIndex or 0) + 1
	art.Parent = btn

	LOG.info("[kito][full-art] id=%s icon=%s", tostring(it.id or "?"), tostring(icon))
	return true
end

--========================
-- メイン：カード生成
--========================
-- create(parent, nodes, it, lang, mon, handlers={ onBuy=function(it) end })
function M.create(parent: Instance, nodes, it: any, lang: string, mon: number, handlers)
	if not (parent and parent:IsA("GuiObject")) then return nil end
	lang = tostring(lang or "en")
	mon  = tonumber(mon or 0) or 0
	handlers = handlers or {}

	-- 本体ボタン（和紙パネル風）
	local btn = Instance.new("TextButton")
	btn.Name = _safeId(it)

	-- ★ まずはテキストで顔を作る（タイトル→faceName フォールバック）
	local faceText = _title(it, lang)
	if faceText == "" then faceText = _getFaceName(it) end
	btn.Text = faceText
	btn.TextWrapped = true
	btn.TextScaled  = true
	do
		-- 文字サイズの上限（大きすぎ回避）
		local max = Instance.new("UITextSizeConstraint")
		max.MaxTextSize = 24
		max.Parent = btn
	end
	btn.TextXAlignment = Enum.TextXAlignment.Center
	btn.TextYAlignment = Enum.TextYAlignment.Center

	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = _themeColor("TextDefault", Color3.fromRGB(240,240,240))
	btn.BackgroundColor3 = _themeColor("PanelBg", Color3.fromRGB(35,38,46))
	btn.AutoButtonColor  = true
	btn.ZIndex = 10
	btn.Parent = parent
	addCorner(btn, Theme and Theme.PANEL_RADIUS or 10)
	local stroke = addStroke(btn, _themeColor("PanelStroke", Color3.fromRGB(70,70,80)), 1, 0)

	-- 価格バンド
	local priceBand = Instance.new("TextLabel")
	priceBand.Name = "Price"
	priceBand.BackgroundColor3 = _themeColor("BadgeBg", Color3.fromRGB(25,28,36))
	priceBand.Size = UDim2.new(1,0,0,20)
	priceBand.Position = UDim2.new(0,0,1,-20)
	priceBand.Text = _fmtPrice(it and it.price)
	priceBand.TextSize = 14
	priceBand.Font = Enum.Font.Gotham
	priceBand.TextColor3 = Color3.fromRGB(245,245,245)
	priceBand.ZIndex = 11
	priceBand.Active = false
	priceBand.Selectable = false
	priceBand.Parent = btn
	addStroke(priceBand, _themeColor("BadgeStroke", Color3.fromRGB(60,65,80)), 1, 0.2)

	-- 購入可否
	local affordable = _computeAffordable(mon, it and it.price)
	if not affordable then
		local insuff = Locale.t(lang, "SHOP_UI_INSUFFICIENT_SUFFIX")
		priceBand.Text = _fmtPrice(it and it.price) .. insuff
		priceBand.BackgroundTransparency = 0.15
		btn.AutoButtonColor = true
	end

	-- Attributes
	_setAttributes(btn, it, lang, mon, affordable)

	-- ★ KITOフルアート適用（成功したときのみテキストを消す）
	local applied = _applyKitoFullArt(btn, priceBand, it)
	if applied and btn:IsA("TextButton") then
		btn.Text = ""
	end

	-- Hover/Selection 演出
	local ti = TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local baseBg = btn.BackgroundColor3
	local function hoverIn()
		if stroke then stroke.Thickness = 2 end
		TweenService:Create(btn, ti, { BackgroundColor3 = baseBg:Lerp(Color3.new(1,1,1), 0.06) }):Play()
	end
	local function hoverOut()
		if stroke then stroke.Thickness = 1 end
		TweenService:Create(btn, ti, { BackgroundColor3 = baseBg }):Play()
	end
	btn.MouseEnter:Connect(hoverIn)
	btn.MouseLeave:Connect(hoverOut)
	if btn.SelectionGained then btn.SelectionGained:Connect(hoverIn) end
	if btn.SelectionLost   then btn.SelectionLost  :Connect(hoverOut) end

	-- 説明（右の Info パネルへ）
	local function showDesc()
		local title = _title(it, lang)
		local desc  = _desc(it, lang)
		local lines = {
			string.format("<b>%s</b>", title ~= "" and title or _getFaceName(it)),
			_catLabel(it, lang),
			_priceLabel(it, lang),
			"",
			(desc ~= "" and desc or Locale.t(lang, "SHOP_UI_NO_DESC")),
		}
		if nodes and nodes.infoText then
			nodes.infoText.Text = table.concat(lines, "\n")
		end
	end
	btn.MouseEnter:Connect(showDesc)
	if btn.SelectionGained then btn.SelectionGained:Connect(showDesc) end

	-- 購入
	local function doBuy()
		if not (handlers and typeof(handlers.onBuy)=="function") then return end
		pcall(function() handlers.onBuy(it) end)
	end
	btn.Activated:Connect(doBuy)

	return btn
end

return M
