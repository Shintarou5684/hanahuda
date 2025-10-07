-- StarterPlayerScripts/UI/components/renderers/ShopRenderer.lua
-- v0.9.SIMPLE-16
--  - requireModuleCI を安定化（探索親の取り違えを解消）
--  - GetAttribute チェックは typeof で安全に（既存修正を維持）
--  - Case-insensitive な UI ルート＆子検索
--  - KitoAssets 遅延ロード + 1回限定再試行
--  - Styles も CI で解決
--  - Locale: 護符ボードタイトルは *_TITLE を使用
--  - フェーズ3互換: setCellSelected を公開（選択ハイライト）

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
-- Styles（UI/components/renderers → UI/styles/ShopStyles を CI 解決）
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
		local lib  = findChildCI(uiRoot, "lib")
		local ms   = lib and findChildCI(lib, "KitoAssets")
		LOG.info("[KitoAssets] late-bound OK | module=%s", tostring(ms and ms:GetFullName() or "?"))
		return mod
	end
	return nil
end

--========================
-- TalismanBoard ローダ（CI 解決）
--========================
local function requireTalismanBoard()
	local uiRoot = findAncestorCI(script, "UI")
	if not uiRoot then return nil end
	return requireModuleCI(uiRoot, {"components","TalismanBoard"}, 0.5)
end

local function _id(it) return tostring(it and it.id or "?") end

local M = {}

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
	}
	local themeKey = map[key]
	if themeKey and Theme and Theme.COLORS and typeof(Theme.COLORS[themeKey]) == "Color3" then
		return Theme.COLORS[themeKey]
	end
	return fallback
end

local function addCorner(gui: Instance, px: number?)
	local ok = pcall(function()
		local c = Instance.new("UICorner")
		local r = px or (Styles and Styles.sizes and Styles.sizes.panelCorner) or Theme.PANEL_RADIUS or 10
		c.CornerRadius = UDim.new(0, r)
		c.Parent = gui
	end)
	return ok
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
	if not it then return false end
	if tostring(it.category) ~= "kito" then return false end

	-- KitoAssets を遅延解決
	local KA = _getKitoAssets()
	if not KA then
		-- 初回未解決なら軽く再試行（複製タイミング差分吸収）
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
		LOG.warn("[kito][skip] id=%s reason=KitoAssets-not-ready", tostring(it.id or "?"))
		return false
	end

	-- effect ID 正規化
	local effectRaw = tostring(it.effect or "")
	local effectCanon = effectRaw
	local okDefs, ShopDefs = pcall(function()
		return require(SharedModules:WaitForChild("ShopDefs"))
	end)
	if okDefs and ShopDefs and type(ShopDefs.toCanonicalEffectId) == "function" then
		local ok, canon = pcall(ShopDefs.toCanonicalEffectId, effectRaw)
		if ok and canon and canon ~= "" then effectCanon = canon end
	end
	LOG.info("[kito][canon] id=%s raw=%s -> canon=%s", tostring(it.id or "?"), effectRaw, effectCanon)

	-- アイコン解決
	local icon
	local okGet, res = pcall(function() return KA.getIcon(effectCanon) end)
	if okGet then icon = res else LOG.warn("[kito][icon-error] id=%s err=%s", tostring(it.id or "?"), tostring(res)) end
	if not icon or icon == "" then
		LOG.warn("[kito][icon-miss] id=%s canon=%s (no icon)", tostring(it.id or "?"), effectCanon)
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

	LOG.info("[kito][full-art] id=%s icon=%s", tostring(it.id or "?"), tostring(icon))
	return true
end

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

	-- 購入（フェーズ2互換：セル直押しで購入）
	local function doBuy()
		if not (handlers and typeof(handlers.onBuy)=="function") then return end
		pcall(function() handlers.onBuy(it) end)
	end
	btn.Activated:Connect(doBuy)

	return btn
end

--========================
-- 既存の render(self) を最小変更で維持
--========================
local function isTalismanItem(it: any): boolean
	return typeof(it) == "table" and (it.category == "talisman") and (it.talismanId ~= nil)
end

function M.render(self)
	local nodes = self._nodes
	if not nodes then return end

	--=== Payload 正規化 ===
	local p          = self._payload or {}
	local items      = p.items or p.stock or {}
	local lang       = ShopFormat.normLang(p.lang) or "en"
	local mon        = tonumber(p.mon or p.totalMon or 0) or 0
	local rerollCost = tonumber(p.rerollCost or 1) or 1

	-- KitoAssets の事前ウォームアップ（非致命）
	_getKitoAssets()

	--=== 護符ボード（初回マウント） ===
	if nodes.taliArea and not self._taliBoard then
		local TB = requireTalismanBoard()
		if TB then
			local title = Locale.t(lang, "SHOP_UI_TALISMAN_BOARD_TITLE")
			local ok, board = pcall(function()
				return TB.new(nodes.taliArea, { title = title, widthScale = 0.9, padScale = 0.01 })
			end)
			if ok and board then
				self._taliBoard = board
				local inst = self._taliBoard.getInstance and self._taliBoard:getInstance()
				if inst then
					inst.AnchorPoint = Vector2.new(0.5, 0)
					inst.Position    = UDim2.fromScale(0.5, 0)
					inst.ZIndex      = 2
				end
				LOG.info("mount TalismanBoard | lang=%s title=%s", tostring(lang), tostring(title))
			else
				LOG.warn("TalismanBoard.new failed: %s", tostring(board))
			end
		else
			LOG.warn("TalismanBoard module not found; skip mount")
		end
	end

	--=== 一時 SoldOut フィルタ ===
	local vis, hiddenList = {}, {}
	for _, it in ipairs(items) do
		if typeof(it) == "table" and tostring(it.category) == "kito" then
			LOG.info("[kito][in] id=%s effect(raw)=%s name=%s",
				tostring(it.id or "?"), tostring(it.effect or "<nil>"), tostring(it.name or ""))
		end
		local id = it and it.id
		local hidden = false
		if typeof(self.isItemHidden) == "function" then
			local ok, h = pcall(function() return self:isItemHidden(id) end)
			hidden = ok and (h == true)
			if not ok then LOG.warn("isItemHidden failed for id=%s", tostring(id)) end
		end
		if not hidden then table.insert(vis, it) else table.insert(hiddenList, tostring(id)) end
	end

	local canReroll = (p.canReroll ~= false) and (mon >= rerollCost)
	LOG.info("render snapshot | items=%d vis=%d hidden=%d mon=%d cost=%d canReroll=%s lang=%s",
		#items, #vis, #hiddenList, mon, rerollCost, tostring(canReroll), lang)
	if #items > 0 and #vis == 0 then
		local maxDump = math.min(10, #hiddenList)
		LOG.info("render dump (all hidden) | ids=%s...", table.concat(hiddenList, ", ", 1, maxDump))
	end

	--=== タイトル・ボタン ===
	if nodes.title   then nodes.title.Text   = Locale.t(lang, "SHOP_UI_TITLE") end
	if nodes.deckBtn then
		nodes.deckBtn.Text = self._deckOpen and Locale.t(lang, "SHOP_UI_HIDE_DECK") or Locale.t(lang, "SHOP_UI_VIEW_DECK")
	end
	if nodes.rerollBtn then
		nodes.rerollBtn.Text = Locale.t(lang, "SHOP_UI_REROLL_FMT"):format(rerollCost)
		nodes.rerollBtn.Active = canReroll
		nodes.rerollBtn.AutoButtonColor = canReroll
		nodes.rerollBtn.TextTransparency = 0
		nodes.rerollBtn.BackgroundTransparency = 0
	end
	if nodes.infoTitle then nodes.infoTitle.Text = Locale.t(lang, "SHOP_UI_INFO_TITLE") end
	if nodes.closeBtn  then nodes.closeBtn.Text  = Locale.t(lang, "SHOP_UI_CLOSE_BTN") end

	--=== 右パネル ===
	do
		local deckPanel = nodes.deckPanel
		local infoPanel = nodes.infoPanel
		local deckTitle = nodes.deckTitle
		local deckText  = nodes.deckText

		if deckPanel and infoPanel then
			deckPanel.Visible = self._deckOpen == true
			infoPanel.Visible = not (self._deckOpen == true)
		end

		if deckPanel and deckTitle and deckText then
			local n, lst = ShopFormat.deckListFromSnapshot(p.currentDeck)
			deckTitle.Text = Locale.t(lang, "SHOP_UI_DECK_TITLE_FMT"):format(n)
			deckText.Text  = (n > 0) and lst or Locale.t(lang, "SHOP_UI_DECK_EMPTY")
		end
	end

	--=== 左グリッド再構築 ===
	local scroll = nodes.scroll
	if not scroll then return end
	for _, ch in ipairs(scroll:GetChildren()) do
		if ch:IsA("GuiObject") and ch ~= nodes.grid then ch:Destroy() end
	end

	-- BUY ハンドラ
	local function onBuy(it: any)
		if self._buyBusy then return end
		if isTalismanItem(it) then
			LOG.info("BUY click (auto place) | id=%s name=%s taliId=%s", tostring(it.id or "?"), tostring(it.name or "?"), tostring(it.talismanId))
			if typeof(self.autoPlace) == "function" then
				local ok = pcall(function() self:autoPlace(it.talismanId, it) end)
				if not ok then LOG.warn("autoPlace failed for talismanId=%s", tostring(it.talismanId)) end
			else
				LOG.warn("autoPlace is not available on host; skip BUY for talisman")
			end
			return
		end
		local remotes = self.deps and self.deps.remotes
		local BuyItem = remotes and remotes.BuyItem
		if not BuyItem then
			LOG.warn("remotes.BuyItem is missing; cannot buy id=%s", tostring(it and it.id))
			return
		end
		self._buyBusy = true
		LOG.info("BUY click | id=%s name=%s", tostring(it.id or "?"), tostring(it.name or "?"))
		pcall(function() BuyItem:FireServer(it.id) end)
		task.delay(0.25, function() self._buyBusy = false end)
	end

	-- セル配置（先頭3件だけ INFO）
	for i, it in ipairs(vis) do
		M.renderCell(scroll, nodes, it, lang, mon, { onBuy = onBuy })
		if i <= 3 then
			LOG.info("cell create #%d | id=%s cat=%s price=%s",
				i, _id(it), tostring(it and it.category or "?"), tostring(it and it.price or "?"))
		end
	end

	-- CanvasSize
	task.defer(function()
		local gridObj = nodes.grid
		if not (gridObj and gridObj:IsA("UIGridLayout")) then return end
		local frameW = scroll.AbsoluteSize.X
		local cellW  = (gridObj.CellSize.X.Offset or 0) + (gridObj.CellPadding.X.Offset or 0)
		if cellW <= 0 then return end
		local perRow = math.max(1, math.floor(frameW / cellW))
		local rows   = math.ceil(#vis / perRow)
		local cellH  = (gridObj.CellSize.Y.Offset or 0) + (gridObj.CellPadding.Y.Offset or 0)
		local needed = rows * cellH + 8
		scroll.CanvasSize = UDim2.new(0, 0, 0, needed)
	end)

	--=== サマリ ===
	local s = {}
	if p.seasonSum ~= nil or p.target ~= nil or p.rewardMon ~= nil then
		table.insert(s,
			Locale.t(lang, "SHOP_UI_SUMMARY_CLEARED_FMT")
				:format(tonumber(p.seasonSum or 0) or 0, tonumber(p.target or 0) or 0, tonumber(p.rewardMon or 0) or 0, tonumber(p.totalMon or mon or 0) or 0)
		)
	end
	table.insert(s, Locale.t(lang, "SHOP_UI_SUMMARY_ITEMS_FMT"):format(#vis))
	table.insert(s, Locale.t(lang, "SHOP_UI_SUMMARY_MONEY_FMT"):format(mon))
	if nodes.summary then nodes.summary.Text = table.concat(s, "\n") end
end

--========================
-- 追加公開：選択トグル（フェーズ3向け）
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
