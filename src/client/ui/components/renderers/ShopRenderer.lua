-- StarterPlayerScripts/UI/screens/ShopRenderer.lua
-- v0.9.SIMPLE-7
--  - 下段 TalismanArea に護符ボードをマウント（初回のみ）
--  - payload.talisman を表示（nilならデフォルト6枠表示）
--  - items を描画前に self:isItemHidden(id) でフィルタ（既存）

local RS = game:GetService("ReplicatedStorage")
local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat = require(SharedModules:WaitForChild("ShopFormat"))

local Logger = require(SharedModules:WaitForChild("Logger"))
local LOG    = Logger.scope("ShopRenderer")

local ShopCells = require(script.Parent.Parent:WaitForChild("ShopCells"))
local ShopI18n  = require(script.Parent.Parent:WaitForChild("i18n"):WaitForChild("ShopI18n"))

-- TalismanBoard の安全取得（UI/components から辿る）
local function requireTalismanBoard()
	local uiRoot = script:FindFirstAncestor("UI")
	if not uiRoot then return nil end
	local comps = uiRoot:FindFirstChild("components")
	if not comps then return nil end
	local mod = comps:FindFirstChild("TalismanBoard")
	if mod and mod:IsA("ModuleScript") then
		local ok, tb = pcall(function() return require(mod) end)
		if ok then return tb end
	end
	return nil
end

local M = {}

local function isTalismanItem(it: any): boolean
	return typeof(it) == "table" and (it.category == "talisman") and (it.talismanId ~= nil)
end

function M.render(self)
	local nodes = self._nodes
	if not nodes then return end

	local p = self._payload or {}
	local items = p.items or p.stock or {}
	local lang = self._lang or ShopFormat.normLang(p.lang)
	local mon = tonumber(p.mon or p.totalMon or 0) or 0
	local rerollCost = tonumber(p.rerollCost or 1) or 1

	-- ★ 護符ボード（初回マウント）
	if nodes.taliArea and not self._taliBoard then
		local TB = requireTalismanBoard()
		if TB then
			self._taliBoard = TB.new(nodes.taliArea, {
				title = (lang == "ja") and "護符ボード" or "Talisman Board",
				widthScale = 0.9,
				padScale   = 0.01,
			})
			local inst = self._taliBoard:getInstance()
			inst.AnchorPoint = Vector2.new(0.5, 0)
			inst.Position    = UDim2.fromScale(0.5, 0)
			inst.ZIndex      = 2
		else
			LOG.warn("TalismanBoard module not found; skip mount")
		end
	end
	-- データ反映（存在すれば）
	if self._taliBoard then
		local langFix = (lang == "ja") and "ja" or "en"
		self._taliBoard:setLang(langFix)
		-- p.talisman が来なければ内部で defaultData() が出る想定
		self._taliBoard:setData(p.talisman)
	end

	-- ★ 一時SoldOutフィルタ
	local vis = {}
	for _, it in ipairs(items) do
		local id = it and it.id
		local hidden = false
		if typeof(self.isItemHidden) == "function" then
			local ok, h = pcall(function() return self:isItemHidden(id) end)
			hidden = ok and (h == true)
		end
		if not hidden then
			table.insert(vis, it)
		end
	end

	LOG.debug("render | lang=%s items=%d→%d mon=%d rerollCost=%d",
		tostring(lang), #items, #vis, mon, rerollCost)

	-- タイトル・ボタン
	if nodes.title then
		nodes.title.Text = ShopI18n.t(lang, "title_mvp")
	end
	if nodes.deckBtn then
		local txt = self._deckOpen and ShopI18n.t(lang, "deck_btn_hide") or ShopI18n.t(lang, "deck_btn_show")
		nodes.deckBtn.Text = txt
	end
	if nodes.rerollBtn then
		nodes.rerollBtn.Text = ShopI18n.t(lang, "reroll_btn_fmt", rerollCost)
		local can = (p.canReroll ~= false) and (mon >= rerollCost)
		nodes.rerollBtn.Active = can
		nodes.rerollBtn.AutoButtonColor = can
		nodes.rerollBtn.TextTransparency = 0
		nodes.rerollBtn.BackgroundTransparency = 0
	end
	if nodes.infoTitle then
		nodes.infoTitle.Text = ShopI18n.t(lang, "info_title")
	end
	if nodes.closeBtn then
		nodes.closeBtn.Text = ShopI18n.t(lang, "close_btn")
	end

	-- 右パネル
	do
		local deckPanel = nodes.deckPanel
		local infoPanel = nodes.infoPanel
		local deckTitle = nodes.deckTitle
		local deckText  = nodes.deckText

		if deckPanel and infoPanel then
			deckPanel.Visible = self._deckOpen
			infoPanel.Visible = not self._deckOpen
		end

		if deckPanel and deckTitle and deckText then
			local n, lst = ShopFormat.deckListFromSnapshot(p.currentDeck)
			deckTitle.Text = ShopI18n.t(lang, "deck_title_fmt", n)
			deckText.Text  = (n > 0) and lst or ShopI18n.t(lang, "deck_empty")
		end
	end

	-- 左グリッド再構築
	local scroll = nodes.scroll
	if not scroll then return end
	for _, ch in ipairs(scroll:GetChildren()) do
		if ch:IsA("GuiObject") and ch ~= nodes.grid then
			ch:Destroy()
		end
	end

	-- BUY ハンドラ
	local function onBuy(it: any)
		if self._buyBusy then return end

		if isTalismanItem(it) then
			LOG.info("BUY click (auto place) | id=%s name=%s taliId=%s",
				tostring(it.id or "?"), tostring(it.name or "?"), tostring(it.talismanId))
			if typeof(self.autoPlace) == "function" then
				self:autoPlace(it.talismanId, it)
			else
				LOG.warn("autoPlace is not available on host; skip BUY for talisman")
			end
			return
		end

		if not (self.deps and self.deps.remotes and self.deps.remotes.BuyItem) then
			LOG.warn("remotes.BuyItem is missing; cannot buy id=%s", tostring(it and it.id))
			return
		end
		self._buyBusy = true
		LOG.info("BUY click | id=%s name=%s", tostring(it.id or "?"), tostring(it.name or "?"))
		self.deps.remotes.BuyItem:FireServer(it.id)
		task.delay(0.25, function() self._buyBusy = false end)
	end

	for _, it in ipairs(vis) do
		ShopCells.create(scroll, nodes, it, lang, mon, { onBuy = onBuy })
	end

	-- CanvasSize
	task.defer(function()
		local gridObj = nodes.grid
		if not gridObj then return end
		local frameW = scroll.AbsoluteSize.X
		local cellW = gridObj.CellSize.X.Offset + gridObj.CellPadding.X.Offset
		local perRow = math.max(1, math.floor(frameW / math.max(1, cellW)))
		local rows = math.ceil(#vis / perRow)
		local cellH = gridObj.CellSize.Y.Offset + gridObj.CellPadding.Y.Offset
		local needed = rows * cellH + 8
		scroll.CanvasSize = UDim2.new(0, 0, 0, needed)
	end)

	-- サマリ
	local s = {}
	if p.seasonSum ~= nil or p.target ~= nil or p.rewardMon ~= nil then
		table.insert(s, ShopI18n.t(
			lang,
			"summary_cleared_fmt",
			tonumber(p.seasonSum or 0),
			tonumber(p.target or 0),
			tonumber(p.rewardMon or 0),
			tonumber(p.totalMon or mon or 0)
		))
	end
	table.insert(s, ShopI18n.t(lang, "summary_items_fmt", #vis))
	table.insert(s, ShopI18n.t(lang, "summary_money_fmt", mon))
	if nodes.summary then
		nodes.summary.Text = table.concat(s, "\n")
	end
end

return M
