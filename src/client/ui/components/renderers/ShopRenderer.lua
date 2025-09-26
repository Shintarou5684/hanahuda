-- StarterPlayerScripts/UI/components/renderers/ShopRenderer.lua
-- v0.9.SIMPLE-10 (diag logging)
--  - 可視0時のダンプ、通常時の items→vis サマリを INFO で出力

local RS = game:GetService("ReplicatedStorage")
local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat = require(SharedModules:WaitForChild("ShopFormat"))

local Config = RS:WaitForChild("Config")
local Locale = require(Config:WaitForChild("Locale"))

local Logger = require(SharedModules:WaitForChild("Logger"))
local LOG    = Logger.scope("ShopRenderer")

local ShopCells = require(script.Parent.Parent:WaitForChild("ShopCells"))

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

local function _id(it) return tostring(it and it.id or "?") end

local M = {}

local function isTalismanItem(it: any): boolean
	return typeof(it) == "table" and (it.category == "talisman") and (it.talismanId ~= nil)
end

function M.render(self)
	local nodes = self._nodes
	if not nodes then return end

	--=== Payload 正規化 ===
	local p       = self._payload or {}
	local items   = p.items or p.stock or {}
	local lang    = ShopFormat.normLang(p.lang) or "en"
	local mon     = tonumber(p.mon or p.totalMon or 0) or 0
	local rerollCost = tonumber(p.rerollCost or 1) or 1

	--=== 護符ボード（初回マウント） ===
	if nodes.taliArea and not self._taliBoard then
		local TB = requireTalismanBoard()
		if TB then
			local title = Locale.t(lang, "SHOP_UI_TALISMAN_BOARD")
			local ok, board = pcall(function()
				return TB.new(nodes.taliArea, { title = title, widthScale = 0.9, padScale = 0.01 })
			end)
			if ok and board then
				self._taliBoard = board
				local inst = self._taliBoard.getInstance and self._taliBoard:getInstance()
				if inst then inst.AnchorPoint = Vector2.new(0.5, 0); inst.Position = UDim2.fromScale(0.5, 0); inst.ZIndex = 2 end
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
		local id = it and it.id
		local hidden = false
		if typeof(self.isItemHidden) == "function" then
			local ok, h = pcall(function() return self:isItemHidden(id) end)
			hidden = ok and (h == true)
			if not ok then LOG.warn("isItemHidden failed for id=%s", tostring(id)) end
		end
		if not hidden then
			table.insert(vis, it)
		else
			table.insert(hiddenList, tostring(id))
		end
	end

	local canReroll = (p.canReroll ~= false) and (mon >= rerollCost)
	LOG.info("render snapshot | items=%d vis=%d hidden=%d mon=%d cost=%d canReroll=%s lang=%s",
		#items, #vis, #hiddenList, mon, rerollCost, tostring(canReroll), lang)

	if #items > 0 and #vis == 0 then
		-- 可視0 → 何が隠れているかを列挙（最大10件）
		local maxDump = math.min(10, #hiddenList)
		LOG.info("render dump (all hidden) | ids=%s...", table.concat(hiddenList, ", ", 1, maxDump))
	end

	--=== タイトル・ボタン ===
	if nodes.title then nodes.title.Text = Locale.t(lang, "SHOP_UI_TITLE") end
	if nodes.deckBtn then
		local txt = self._deckOpen and Locale.t(lang, "SHOP_UI_HIDE_DECK") or Locale.t(lang, "SHOP_UI_VIEW_DECK")
		nodes.deckBtn.Text = txt
	end
	if nodes.rerollBtn then
		nodes.rerollBtn.Text = Locale.t(lang, "SHOP_UI_REROLL_FMT"):format(rerollCost)
		nodes.rerollBtn.Active = canReroll
		nodes.rerollBtn.AutoButtonColor = canReroll
		nodes.rerollBtn.TextTransparency = 0
		nodes.rerollBtn.BackgroundTransparency = 0
	end
	if nodes.infoTitle then nodes.infoTitle.Text = Locale.t(lang, "SHOP_UI_INFO_TITLE") end
	if nodes.closeBtn then nodes.closeBtn.Text = Locale.t(lang, "SHOP_UI_CLOSE_BTN") end

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
		ShopCells.create(scroll, nodes, it, lang, mon, { onBuy = onBuy })
		if i <= 3 then LOG.info("cell create #%d | id=%s cat=%s price=%s", i, _id(it), tostring(it and it.category or "?"), tostring(it and it.price or "?")) end
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

return M
