-- StarterPlayerScripts/UI/components/renderers/ShopRenderer.lua
-- v0.9.SIMPLE-17
--  - 未使用APIを削除：render(self) / TalismanBoard ロード系を撤去（View 側が管理）
--  - 旧版の暫定ログを削減（KITO 正規化/貼付の詳細ログを debug か無出力へ）
--  - Remotes 直叩きとなる導線を完全排除（handlers 経由のみ）→ Wires 単一路線化に準拠
--  - CI（Case-Insensitive）探索ユーティリティは維持
--  - Styles / KitoAssets は遅延ロード & 1回限定再試行のまま安定化
--  - 公開API：renderCell / setCellSelected のみ

local RS = game:GetService("ReplicatedStorage")

-- Shared
local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat    = require(SharedModules:WaitForChild("ShopFormat"))
local Logger        = require(SharedModules:WaitForChild("Logger"))
local LOG           = Logger.scope("ShopRenderer")

-- Config
local Config = RS:WaitForChild("Config")
local Locale = require(Config:WaitForChild("Locale"))
local Theme  = require(Config:WaitForChild("Theme"))

--========================
-- 共通ユーティリティ（CI = Case-Insensitive）
--========================
local function _lower(s) return string.lower(tostring(s or "")) end

local function findAncestorCI(startInst: Instance, name: string): Instance?
	local target = _lower(name)
	local node = startInst
	while node do
		if _lower(node.Name) == target then return node end
		node = node.Parent
	end
	return nil
end

local function findChildCI(parent: Instance?, name: string): Instance?
	if not parent then return nil end
	local target = _lower(name)
	for _, ch in ipairs(parent:GetChildren()) do
		if _lower(ch.Name) == target then return ch end
	end
	return nil
end

local function requireModuleCI(root: Instance?, path: {string}, waitSeconds: number?): any
	if not root then return nil end
	local node: Instance? = root
	for _, seg in ipairs(path) do
		local found = findChildCI(node, seg)
		if (not found) and waitSeconds and waitSeconds > 0 then
			local deadline = os.clock() + waitSeconds
			while (not found) and os.clock() < deadline do
				found = findChildCI(node, seg) or node:FindFirstChild(seg)
				if not found then task.wait(0.05) end
			end
		end
		if not found then return nil end
		node = found
	end
	if node and node:IsA("ModuleScript") then
		local ok, mod = pcall(require, node)
		if ok then return mod end
	end
	return nil
end

--========================
-- Styles（UI/styles/ShopStyles を CI 解決）
--========================
local Styles do
	local ok, mod = pcall(function()
		local uiRoot = findAncestorCI(script, "UI")
		assert(uiRoot, "UI root not found for ShopRenderer (case-insensitive)")
		return requireModuleCI(uiRoot, {"styles","ShopStyles"}, 0.5)
	end)
	Styles = ok and mod or nil
end

--========================
-- KitoAssets：遅延ロード（UI/lib/KitoAssets を CI 解決）
--========================
local KitoAssets -- cache
local function _getKitoAssets()
	if KitoAssets ~= nil then return KitoAssets end
	local uiRoot = findAncestorCI(script, "UI")
	if not uiRoot then return nil end
	local mod = requireModuleCI(uiRoot, {"lib","KitoAssets"}, 0.5)
	if mod then
		KitoAssets = mod
		return mod
	end
	return nil
end

--========================
-- 内部ユーティリティ
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

-- Styles → Theme → 既定 の順で色を解決
local function _styleColor(key:string, fallback: Color3): Color3
	if Styles and Styles.colors and typeof(Styles.colors[key]) == "Color3" then
		return Styles.colors[key]
	end
	local map = {
		panelStroke = "PanelStroke",
		badgeBg     = "BadgeBg",
		badgeStroke = "BadgeStroke",
		text        = "TextDefault",
		cardBg      = "PanelBg",
		selectedStroke = "SelectedStroke",
	}
	local themeKey = map[key]
	if themeKey and Theme and Theme.COLORS and typeof(Theme.COLORS[themeKey]) == "Color3" then
		return Theme.COLORS[themeKey]
	end
	return fallback
end

local function addCorner(gui: Instance, px: number?)
	pcall(function()
		local c = Instance.new("UICorner")
		local r = px or (Styles and Styles.sizes and Styles.sizes.panelCorner) or Theme.PANEL_RADIUS or 10
		c.CornerRadius = UDim.new(0, r)
		c.Parent = gui
	end)
end

local function addStroke(gui: Instance, color: Color3?, thickness: number?, transparency: number?)
	local ok, stroke = pcall(function()
		local s = Instance.new("UIStroke")
		s.Thickness = thickness or 1
		s.Color = color or _styleColor("panelStroke", Color3.fromRGB(70,70,80))
		s.Transparency = transparency or 0
		s.Parent = gui
		return s
	end)
	return ok and stroke or nil
end

--========================
-- KITOフルアート（成功で true）
--========================
local function _applyKitoFullArt(btn: Instance, priceBand: Instance, it:any): boolean
	if not (btn and btn:IsA("GuiObject")) then return false end
	if not it or tostring(it.category) ~= "kito" then return false end

	-- KitoAssets を遅延解決（未準備時は軽い再試行）
	local KA = _getKitoAssets()
	if not KA then
		local alreadyRetried = (typeof(btn.GetAttribute) == "function") and (btn:GetAttribute("kitoArtRetry") == true)
		if not alreadyRetried then
			if typeof(btn.SetAttribute) == "function" then
				btn:SetAttribute("kitoArtRetry", true)
			end
			task.delay(0.30, function()
				local KA2 = _getKitoAssets()
				if KA2 then
					local ok2 = _applyKitoFullArt(btn, priceBand, it)
					if ok2 and btn:IsA("TextButton") then btn.Text = "" end
				end
			end)
		end
		-- 過剰ログを避ける
		LOG.debug("[kito] assets not ready; will retry once")
		return false
	end

	-- effect ID 正規化（ShopDefs があれば使用）
	local effectCanon = tostring(it.effect or "")
	local okDefs, ShopDefs = pcall(function()
		return require(SharedModules:WaitForChild("ShopDefs"))
	end)
	if okDefs and ShopDefs and type(ShopDefs.toCanonicalEffectId) == "function" then
		local ok, canon = pcall(ShopDefs.toCanonicalEffectId, effectCanon)
		if ok and canon and canon ~= "" then effectCanon = canon end
	end

	-- アイコン解決
	local icon
	local okGet, res = pcall(function() return KA.getIcon(effectCanon) end)
	if okGet then
		icon = res
	end
	if not icon or icon == "" then
		-- ここは実害があるので warn を維持
		LOG.warn("[kito] icon not found for effect=%s", tostring(effectCanon))
		return false
	end

	-- 旧パーツ除去 → フルアート貼付
	local oldSmall = btn:FindFirstChild("KitoIcon"); if oldSmall then oldSmall:Destroy() end
	local oldArt   = btn:FindFirstChild("KitoArt");  if oldArt  then oldArt:Destroy()  end

	local art = Instance.new("ImageLabel")
	art.Name = "KitoArt"
	art.Image = icon
	art.BackgroundTransparency = 1
	art.ScaleType = Enum.ScaleType.Fit
	local priceH = (Styles and Styles.sizes and Styles.sizes.priceBandH) or 20
	if priceBand and priceBand:IsA("GuiObject") then
		local h = tonumber(priceBand.Size.Y.Offset) or priceH
		priceH = h
	end
	art.Size = UDim2.new(1, 0, 1, -priceH)
	art.Position = UDim2.new(0, 0, 0, 0)
	art.ZIndex = (btn.ZIndex or 0) + 1
	art.Parent = btn

	-- 詳細ログは控えめに
	LOG.debug("[kito] full-art applied")
	return true
end

local M = {}

--========================
-- 公開：セル生成（唯一の入口）
--========================
function M.renderCell(parent: Instance, nodes, it: any, lang: string, mon: number, handlers)
	if not (parent and parent:IsA("GuiObject")) then return nil end
	lang = tostring(lang or "en")
	mon  = tonumber(mon or 0) or 0
	handlers = handlers or {}

	local TweenService = game:GetService("TweenService")

	-- 本体ボタン（和紙パネル風）
	local btn = Instance.new("TextButton")
	btn.Name = _safeId(it)

	-- まずはテキストで顔（タイトル→faceName フォールバック）
	local faceText = _title(it, lang)
	if faceText == "" then faceText = _getFaceName(it) end
	btn.Text = faceText
	btn.TextWrapped = true
	btn.TextScaled  = true
	do
		local max = Instance.new("UITextSizeConstraint")
		local maxPx = (Styles and Styles.fontSizes and Styles.fontSizes.cellTextMax) or 24
		max.MaxTextSize = maxPx
		max.Parent = btn
	end
	btn.TextXAlignment = Enum.TextXAlignment.Center
	btn.TextYAlignment = Enum.TextYAlignment.Center

	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = _styleColor("text", Color3.fromRGB(240,240,240))
	btn.BackgroundColor3 = _styleColor("cardBg", Color3.fromRGB(35,38,46))
	btn.AutoButtonColor  = true
	btn.ZIndex = (Styles and Styles.z and Styles.z.cells) or 10
	btn.Parent = parent
	addCorner(btn, (Styles and Styles.sizes and Styles.sizes.panelCorner) or Theme.PANEL_RADIUS or 10)
	local stroke = addStroke(btn, _styleColor("panelStroke", Color3.fromRGB(70,70,80)), 1, 0)

	-- 価格バンド
	local priceBandH = (Styles and Styles.sizes and Styles.sizes.priceBandH) or 20
	local priceBand = Instance.new("TextLabel")
	priceBand.Name = "Price"
	priceBand.BackgroundColor3 = _styleColor("badgeBg", Color3.fromRGB(25,28,36))
	priceBand.Size = UDim2.new(1,0,0,priceBandH)
	priceBand.Position = UDim2.new(0,0,1,-priceBandH)
	priceBand.Text = _fmtPrice(it and it.price)
	priceBand.TextSize = (Styles and Styles.fontSizes and Styles.fontSizes.price) or 14
	priceBand.Font = Enum.Font.Gotham
	priceBand.TextColor3 = Color3.fromRGB(245,245,245)
	priceBand.ZIndex = (Styles and Styles.z and Styles.z.price) or 11
	priceBand.Active = false
	priceBand.Selectable = false
	priceBand.Parent = btn
	addStroke(priceBand, _styleColor("badgeStroke", Color3.fromRGB(60,65,80)), 1, 0.2)

	-- 購入可否
	local affordable = _computeAffordable(mon, it and it.price)
	if not affordable then
		local insuff = Locale.t(lang, "SHOP_UI_INSUFFICIENT_SUFFIX")
		priceBand.Text = _fmtPrice(it and it.price) + insuff -- Lua で + は文字連結不可 → 修正
		priceBand.Text = _fmtPrice(it and it.price) .. insuff
		priceBand.BackgroundTransparency = 0.15
		btn.AutoButtonColor = true
	end

	-- Attributes
	if typeof(btn.SetAttribute)=="function" then
		btn:SetAttribute("id", tostring(it and it.id or ""))
		btn:SetAttribute("category", tostring(it and it.category or ""))
		btn:SetAttribute("price", tonumber(it and it.price or 0) or 0)
		btn:SetAttribute("lang", lang)
		btn:SetAttribute("affordable", affordable and true or false)
		btn:SetAttribute("face", _getFaceName(it))
	end

	-- KITOフルアート適用（成功時はテキスト隠し）
	local applied = _applyKitoFullArt(btn, priceBand, it)
	if applied and btn:IsA("TextButton") then btn.Text = "" end

	-- Hover/Selection
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

	-- 右パネルへ説明
	local function showDesc()
		local t = _title(it, lang)
		local d = _desc(it, lang)
		local lines = {
			string.format("<b>%s</b>", t ~= "" and t or _getFaceName(it)),
			_catLabel(it, lang),
			_priceLabel(it, lang),
			"",
			(d ~= "" and d or Locale.t(lang, "SHOP_UI_NO_DESC")),
		}
		if nodes and nodes.infoText then nodes.infoText.Text = table.concat(lines, "\n") end
	end
	btn.MouseEnter:Connect(showDesc)
	if btn.SelectionGained then btn.SelectionGained:Connect(showDesc) end

	-- 購入（handlers 経由・Remotes は叩かない）
	local function doBuy()
		if handlers and typeof(handlers.onBuy)=="function" then
			pcall(function() handlers.onBuy(it) end)
		end
	end
	btn.Activated:Connect(doBuy)

	return btn
end

--========================
-- 公開：選択トグル
--========================
function M.setCellSelected(btn: Instance, selected: boolean)
	if not (btn and btn:IsA("GuiObject")) then return end
	local stroke = btn:FindFirstChild("SelStroke")
	if not stroke then
		local s = Instance.new("UIStroke")
		s.Name = "SelStroke"
		s.Thickness = 3
		s.Transparency = 0
		s.Color = _styleColor("selectedStroke", Color3.fromRGB(255, 210, 110))
		s.Parent = btn
		stroke = s
	end
	stroke.Enabled = selected and true or false
	if typeof(btn.SetAttribute)=="function" then
		btn:SetAttribute("selected", selected and true or false)
	end
end

return M
