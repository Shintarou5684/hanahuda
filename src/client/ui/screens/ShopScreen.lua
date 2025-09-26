-- StarterPlayerScripts/UI/screens/ShopScreen.lua
-- v0.9.9-P2-16 ShopScreen（診断ログ強化）
--  - 可視件数・在庫署名の遷移・リロール可否を INFO で出力
--  - 他は前版(P2-15)の selfバインド/LOG統一そのまま

local Shop = {}
Shop.__index = Shop

local RS = game:GetService("ReplicatedStorage")
local SharedModules = RS:WaitForChild("SharedModules")

local Config = RS:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

local Logger = require(SharedModules:WaitForChild("Logger"))
local LOG = (typeof(Logger.scope) == "function" and Logger.scope("ShopScreen"))
	or (typeof(Logger["for"]) == "function" and Logger["for"]("ShopScreen"))
	or { debug=function()end, info=function()end, warn=function(...) warn(...) end }

local uiRoot = script.Parent.Parent
local componentsFolder = uiRoot:WaitForChild("components")
local ShopUI        = require(componentsFolder:WaitForChild("ShopUI"))
local ShopRenderer  = require(componentsFolder:WaitForChild("renderers"):WaitForChild("ShopRenderer"))
local ShopWires     = require(componentsFolder:WaitForChild("controllers"):WaitForChild("ShopWires"))
local TalismanBoard = require(componentsFolder:WaitForChild("TalismanBoard"))

export type Payload = {
	items: {any}?, stock: {any}?,
	mon: number?, totalMon: number?,
	rerollCost: number?, canReroll: boolean?,
	seasonSum: number?, target: number?, rewardMon: number?,
	lang: string?, notice: string?, currentDeck: any?, state: any?,
}

--================ helpers ================
local function normalizeLang(lang: string?): string
	local v = Locale.normalize(lang)
	if tostring(lang or ""):lower() == "jp" and v == "ja" then
		LOG.warn("[Locale] received legacy 'jp'; normalize to 'ja'")
	end
	return v
end

local function countItems(p: Payload?): number
	if not p then return 0 end
	if typeof(p.items) == "table" then return #p.items end
	if typeof(p.stock) == "table" then return #p.stock end
	return 0
end

local function stockSignature(items: {any}?): string
	if typeof(items) ~= "table" then return "<nil>" end
	local parts = { tostring(#items) }
	for _, it in ipairs(items) do
		local id    = (it and it.id) or (it and it.code) or (it and it.sku) or ""
		local kind  = (it and (it.kind or it.type or it.category)) or ""
		local price = (it and (it.price or it.cost)) or ""
		local extra = (it and it.uid) or (it and it.name) or ""
		parts[#parts+1] = table.concat({tostring(id), tostring(kind), tostring(price), tostring(extra)}, ":")
	end
	return table.concat(parts, "||")
end

local function getTalismanFromPayload(p: Payload?)
	if not p then return nil end
	local s = p.state
	if s and s.run and s.run.talisman then
		return s.run.talisman
	end
	return nil
end

local function cloneSlots6(slots)
	local s = slots or {}
	return { s[1], s[2], s[3], s[4], s[5], s[6] }
end

local function cloneTalismanData(t)
	if typeof(t) ~= "table" then return nil end
	return { maxSlots=tonumber(t.maxSlots or 6) or 6, unlocked=tonumber(t.unlocked or 0) or 0, slots=cloneSlots6(t.slots) }
end

local function talismanSignature(t)
	if typeof(t) ~= "table" then return "<nil>" end
	local parts = { tostring(tonumber(t.unlocked or 0) or 0) }
	local s = t.slots or {}
	for i=1,6 do parts[#parts+1] = tostring(s[i] or "") end
	return table.concat(parts, "|")
end

local function taliTitleText(lang: string?): string
	local l = lang or "ja"
	local s = Locale.t(l, "SHOP_UI_TALISMAN_BOARD_TITLE")
	if s == "SHOP_UI_TALISMAN_BOARD_TITLE" then s = Locale.t(l, "SHOP_UI_TALISMAN_BOARD") end
	return s
end

local function normalizePayload(p: Payload?): Payload?
	if not p then return nil end
	if p.lang then
		local nl = normalizeLang(p.lang); if nl and nl ~= p.lang then p.lang = nl end
	end
	if typeof(p.items) ~= "table" and typeof(p.stock) == "table" then
		p.items = p.stock
	end
	return p
end

--================ class ==================
local function _bindSelf(self, fn)
	return function(_, ...) return fn(self, ...) end
end

function Shop.new(deps)
	local self = setmetatable({}, Shop)
	self.deps = deps
	self._payload = nil
	self._closing = false
	self._buyBusy = false
	self._rerollBusy = false
	self._lang = nil
	self._deckOpen = false
	self._bg = nil
	self._taliBoard = nil

	self._preview = nil
	self._lastPlaced = nil
	self._localBoard = nil
	self._taliSig = "<none>"

	self._hiddenItems = {}   -- [itemId]=true
	self._stockSig = ""      -- 在庫構成署名

	local gui, nodes = ShopUI.build()
	self.gui = gui
	self._nodes = nodes
	self:_ensureBg()

	ShopWires.wireButtons(self)
	ShopWires.applyInfoPlaceholder(self)

	do
		local parent = nodes.taliArea or gui
		self._taliBoard = TalismanBoard.new(parent, {
			title      = taliTitleText(self._lang or "ja"),
			widthScale = 0.95, padScale = 0.01,
		})
		local inst = self._taliBoard:getInstance()
		inst.AnchorPoint = Vector2.new(0.5, 0); inst.Position = UDim2.fromScale(0.5, 0); inst.ZIndex = 2
	end

	self._remotes = RS:WaitForChild("Remotes", 10)
	if not self._remotes then
		LOG.warn("[ShopScreen] Remotes folder missing (timeout)")
	else
		self._placeRE = self._remotes:WaitForChild("PlaceOnSlot", 10)
		if not self._placeRE then LOG.warn("[ShopScreen] PlaceOnSlot missing (timeout)") end
		local ack = self._remotes:FindFirstChild("TalismanPlaced")
		if ack and ack:IsA("RemoteEvent") then
			ack.OnClientEvent:Connect(function(data)
				local base = getTalismanFromPayload(self._payload) or { maxSlots=6, unlocked=0, slots={nil,nil,nil,nil,nil,nil} }
				self._localBoard = {
					maxSlots = base.maxSlots or 6,
					unlocked = tonumber(data and data.unlocked or base.unlocked or 0) or 0,
					slots    = (data and data.slots) or cloneSlots6(base.slots),
				}
				self._taliSig = talismanSignature(self._localBoard)
				self._preview = nil; self._lastPlaced = nil
				if self._taliBoard then self._taliBoard:setData(self._localBoard) end
				LOG.info("ack TalismanPlaced | idx=%s id=%s sig=%s", tostring(data and data.index), tostring(data and data.id), self._taliSig)
			end)
		end
	end

	self.show          = _bindSelf(self, Shop.show)
	self.update        = _bindSelf(self, Shop.update)
	self.setData       = _bindSelf(self, Shop.setData)
	self.setLang       = _bindSelf(self, Shop.setLang)
	self.attachRemotes = _bindSelf(self, Shop.attachRemotes)
	self.autoPlace     = _bindSelf(self, Shop.autoPlace)

	LOG.info("boot")
	return self
end

--============ private utils =============
function Shop:_snapBoard()
	return self._localBoard or self._preview or getTalismanFromPayload(self._payload) or { maxSlots=6, unlocked=0, slots={nil,nil,nil,nil,nil,nil} }
end

function Shop:_findFirstEmpty()
	local t = self:_snapBoard()
	local unlocked = tonumber(t.unlocked or 0) or 0
	local slots = t.slots or {}
	for i=1, math.min(unlocked, 6) do if slots[i] == nil then return i end end
	return nil
end

function Shop:_refreshStockSignature(payload: Payload?)
	local items = (payload and (payload.items or payload.stock)) or {}
	local newSig = stockSignature(items)
	local oldSig = self._stockSig

	if newSig ~= oldSig then
		self._stockSig = newSig
		self._hiddenItems = {}
		LOG.info("[stock] changed -> clear hidden | old=%s new=%s count=%d", tostring(oldSig), tostring(newSig), #items)
	else
		-- 現在の hidden 適用後の可視件数
		local visible = 0
		for _, it in ipairs(items) do
			local id = it and it.id
			if not self:isItemHidden(id) then visible += 1 end
		end
		if visible == 0 and #items > 0 then
			self._hiddenItems = {}
			LOG.warn("[stock] visible=0 while items=%d; forced clear hidden (safety)", #items)
		end
		LOG.info("[stock] unchanged | sig=%s items=%d visible=%d hiddenCache#=%d", tostring(newSig), #items, visible, (function() local c=0 for _ in pairs(self._hiddenItems) do c+=1 end return c end)())
	end
end

local function maybeClearPreview(self)
	if not self._preview or not self._lastPlaced then return end
	local base = self:_snapBoard(); if not base or not base.slots then return end
	local idx = self._lastPlaced.index; local id  = self._lastPlaced.id
	if idx and id and base.slots[idx] == id then
		self._preview = nil; self._lastPlaced = nil
		LOG.info("[preview] cleared by server state | idx=%d id=%s", idx, id)
	end
end

function Shop:_applyServerTalismanOnce(payload: Payload?)
	local sv = cloneTalismanData(getTalismanFromPayload(payload))
	if not sv then return end
	local sig = talismanSignature(sv)
	if sig == self._taliSig then return end
	self._localBoard = sv; self._taliSig = sig; self._preview = nil; self._lastPlaced = nil
	if self._taliBoard then self._taliBoard:setData(self._localBoard) end
	LOG.info("[talisman] server applied | sig=%s", sig)
end

function Shop:_syncTalismanBoard()
	if not self._taliBoard then return end
	local lang = self._lang or "ja"
	pcall(function()
		if typeof(self._taliBoard.setLang) == "function" then self._taliBoard:setLang(lang) end
		if typeof(self._taliBoard.setData) == "function" then self._taliBoard:setData(self:_snapBoard()) end
		local inst = self._taliBoard:getInstance()
		if inst and inst:FindFirstChild("Title") and inst.Title:IsA("TextLabel") then
			inst.Title.Text = taliTitleText(lang)
		end
	end)
end

--================ public =================
function Shop:setData(payload: Payload)
	payload = normalizePayload(payload)
	if payload and payload.lang then self._lang = payload.lang end
	self:_refreshStockSignature(payload)
	self._payload = payload
	maybeClearPreview(self)
	self:_applyServerTalismanOnce(payload)

	LOG.info("setData | items=%d lang=%s", countItems(payload), tostring(self._lang))
	self:_syncTalismanBoard()
	self:_render()
end

function Shop:show(payload: Payload?)
	if payload then
		payload = normalizePayload(payload)
		if payload and payload.lang then self._lang = payload.lang end
		self:_refreshStockSignature(payload)
		self._payload = payload
		self:_applyServerTalismanOnce(payload)
		maybeClearPreview(self)
	end

	-- UI状態を必ず初期化（戻り遷移含む）
	self._hiddenItems = {}; self._buyBusy = false; self._rerollBusy = false
	-- セーフティ：初期化後の在庫整合を再チェック
	self:_refreshStockSignature(self._payload)

	self.gui.Enabled = true
	self:_ensureBg(true)
	LOG.info("show | enabled=true items=%d lang=%s", countItems(self._payload), tostring(self._lang))

	self:_syncTalismanBoard()
	self:_render()
	self:_applyRerollButtonState()
end

function Shop:hide()
	if self.gui.Enabled then LOG.info("hide | enabled=false") end
	self.gui.Enabled = false
end

function Shop:update(payload: Payload?)
	if payload then
		payload = normalizePayload(payload)
		if payload and payload.lang then self._lang = payload.lang end
		self:_refreshStockSignature(payload)
		self._payload = payload
		self:_applyServerTalismanOnce(payload)
		maybeClearPreview(self)
	end

	LOG.info("update | items=%d lang=%s", countItems(self._payload), tostring(self._lang))
	self:_syncTalismanBoard()
	self:_render()
	self:_applyRerollButtonState()
end

function Shop:setLang(lang: string?)
	self._lang = normalizeLang(lang)
	ShopWires.applyInfoPlaceholder(self)
	self:_syncTalismanBoard()
end

function Shop:attachRemotes(remotes: any, router: any?)
	LOG.info("attachRemotes (compat)")
	return ShopWires.attachRemotes(self, remotes, router)
end

--============== auto-place ==============
function Shop:autoPlace(talismanId: string, item: any?)
	if not talismanId or talismanId == "" then
		LOG.warn("[Shop] autoPlace: invalid talismanId"); return
	end
	local idx = self:_findFirstEmpty()
	if not idx then
		local toast = self.deps and self.deps.toast
		if typeof(toast) == "function" then toast(Locale.t(self._lang, "SHOP_UI_NO_EMPTY_SLOT")) end
		LOG.info("[Shop] autoPlace aborted: no empty slot"); return
	end
	if item and item.id ~= nil then self:hideItemTemporarily(item.id) end
	LOG.info("[Shop] auto-place index=%d id=%s", idx, tostring(talismanId))

	local t = self:_snapBoard()
	local preview = { maxSlots = t.maxSlots or 6, unlocked = t.unlocked or 0, slots = cloneSlots6(t.slots) }
	preview.slots[idx] = tostring(talismanId) .. "(仮)"
	self._preview = preview; self._lastPlaced = { index = idx, id = talismanId }
	if self._taliBoard then
		self._taliBoard:setData(self._preview)
		local inst = self._taliBoard:getInstance()
		if inst and inst:FindFirstChild("Title") and inst.Title:IsA("TextLabel") then
			inst.Title.Text = taliTitleText(self._lang or "ja")
		end
	end
	if self._placeRE and self._placeRE:IsA("RemoteEvent") then
		self._placeRE:FireServer(idx, talismanId)
	else
		LOG.warn("[Shop] PlaceOnSlot RemoteEvent not available; local preview only")
	end
end

--============== render ==================
function Shop:_render()
	return ShopRenderer.render(self)
end

--============== internals ===============
function Shop:_ensureBg(forceToBack: boolean?)
	if not self.gui then return end
	local bg = self._bg
	if not bg or not bg.Parent then
		bg = Instance.new("ImageLabel")
		bg.Name = "BgImage"; bg.BackgroundTransparency = 1; bg.BorderSizePixel = 0; bg.Active = false
		bg.ScaleType = Enum.ScaleType.Crop; bg.AnchorPoint = Vector2.new(0.5, 0.5); bg.Position = UDim2.fromScale(0.5, 0.5)
		bg.Size = UDim2.fromScale(1, 1); bg.ZIndex = 0; bg.Parent = self.gui; self._bg = bg
	end
	bg.Image = Theme.IMAGES and Theme.IMAGES.SHOP_BG or ""
	bg.ImageTransparency = (Theme.TRANSPARENCY and Theme.TRANSPARENCY.shopBg) or 0
	if forceToBack then bg.ZIndex = 0; bg.LayoutOrder = -10000; bg.Parent = self.gui end
end

function Shop:isItemHidden(id: any)
	if id == nil then return false end
	return self._hiddenItems[tostring(id)] == true
end

function Shop:hideItemTemporarily(id: any)
	if id == nil then return end
	self._hiddenItems[tostring(id)] = true
	LOG.info("[stock] hideItem temp id=%s hidden#=%d", tostring(id), (function() local c=0 for _ in pairs(self._hiddenItems) do c+=1 end return c end)())
	self:_render()
end

function Shop:_applyRerollButtonState()
	local p = self._payload or {}
	local money = tonumber(p.mon or p.totalMon or 0) or 0
	local cost  = tonumber(p.rerollCost or 1) or 1
	local can   = (p.canReroll ~= false) and (money >= cost)
	local active = (self._rerollBusy ~= true) and can
	if self._nodes and self._nodes.rerollBtn then
		self._nodes.rerollBtn.Active = active
		self._nodes.rerollBtn.AutoButtonColor = active
	end
	LOG.info("[reroll] btnState active=%s mon=%d cost=%d can=%s busy=%s", tostring(active), money, cost, tostring(can), tostring(self._rerollBusy))
end

return Shop
