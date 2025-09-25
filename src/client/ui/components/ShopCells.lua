-- StarterPlayerScripts/UI/components/ShopCells.lua
-- v0.9.I3 ShopCells：ShopFormat/Localeへ完全委譲 + 安全化（TextButton.Focused除去）
--  - 価格/タイトル/説明/カテゴリ表記を ShopFormat/Locale に一元委譲
--  - pcall/typeof でガード（落ちないUI）
--  - Mouse/Keyboard/Gamepad 入力の統一（Hover/Selection/Activated）
--  - 主要値を Attributes に保存（デバッグやUIテスト用）

local RS           = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Shared
local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat    = require(SharedModules:WaitForChild("ShopFormat"))

-- Theme & Locale
local Config = RS:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

local M = {}

--========================
-- 小ユーティリティ
--========================
local function _safeId(it:any): string
	local raw = tostring(it and it.id or "Item")
	-- Roblox Name 制限を軽く満たすため、記号を置換
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
-- メイン：カード生成
--========================
-- create(parent, nodes, it, lang, mon, handlers={ onBuy=function(it) end })
function M.create(parent: Instance, nodes, it: any, lang: string, mon: number, handlers)
	-- 親・入力チェック
	if not (parent and parent:IsA("GuiObject")) then return nil end
	lang = tostring(lang or "en")
	mon  = tonumber(mon or 0) or 0
	handlers = handlers or {}

	-- 本体ボタン（和紙パネル風）
	local btn = Instance.new("TextButton")
	btn.Name = _safeId(it)
	btn.Text = _getFaceName(it)
	btn.TextSize = 28
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = _themeColor("TextDefault", Color3.fromRGB(240,240,240))
	btn.BackgroundColor3 = _themeColor("PanelBg", Color3.fromRGB(35,38,46))
	btn.AutoButtonColor  = true
	btn.ZIndex = 10
	btn.Parent = parent
	addCorner(btn, Theme and Theme.PANEL_RADIUS or 10)
	local stroke = addStroke(btn, _themeColor("PanelStroke", Color3.fromRGB(70,70,80)), 1, 0)

	-- 価格バンド（TextLabel、入力は親へパス）
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
	priceBand.Active = false       -- 入力を自身で取らない
	priceBand.Selectable = false   -- 選択不可
	priceBand.Parent = btn
	addStroke(priceBand, _themeColor("BadgeStroke", Color3.fromRGB(60,65,80)), 1, 0.2)

	-- 購入可否の視覚
	local affordable = _computeAffordable(mon, it and it.price)
	if not affordable then
		local insuff = Locale.t(lang, "SHOP_UI_INSUFFICIENT_SUFFIX") -- 例: "（不足）"
		priceBand.Text = _fmtPrice(it and it.price) .. insuff
		priceBand.BackgroundTransparency = 0.15
		-- クリックは許可（サーバ側で弾く）…従来方針を維持
		btn.AutoButtonColor = true
	end

	-- Attributes（UIテスト/デバッグ向け）
	_setAttributes(btn, it, lang, mon, affordable)

	-- Hover/Selection 演出（小さく）
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
	-- TextButton には Focused/FocusLost は無いので SelectionGained/Lost を使用（存在チェック付き）
	if btn.SelectionGained then btn.SelectionGained:Connect(hoverIn) end
	if btn.SelectionLost   then btn.SelectionLost  :Connect(hoverOut) end

	-- 説明表示（右の Info パネルへ）
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

	-- 購入（Activated は Mouse/Touch/Gamepad/Keyboard を包括）
	local function doBuy()
		if not (handlers and typeof(handlers.onBuy)=="function") then return end
		pcall(function() handlers.onBuy(it) end) -- 失敗してもUIは落とさない
	end
	btn.Activated:Connect(doBuy)

	return btn
end

return M
