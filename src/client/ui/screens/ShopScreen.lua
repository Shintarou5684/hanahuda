-- StarterPlayerScripts/UI/screens/ShopScreen.lua
-- v0.9.7-P2-10 ShopScreen（Server-first talisman + jp→ja + idempotent redraw）
--  - show(payload) で payload.state.run.talisman を即時反映（サーバ確定を優先）
--  - payload.lang を尊重し "jp"→"ja" 正規化
--  - 自動配置は「護符配列が無い or 空スロットがある」時のみ（既存の空き検知で担保）
--  - 同一データの再描画を抑止（talisman シグネチャ比較）

local Shop = {}
Shop.__index = Shop

--========= 依存読込 =========
local RS = game:GetService("ReplicatedStorage")
local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat = require(SharedModules:WaitForChild("ShopFormat"))

local Config = RS:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

local Logger = require(SharedModules:WaitForChild("Logger"))
local LOG = (typeof(Logger.scope) == "function" and Logger.scope("ShopScreen"))
	or (typeof(Logger["for"]) == "function" and Logger["for"]("ShopScreen"))
	or { debug=function()end, info=function()end, warn=function(...) warn(...) end }

-- ui/components/*
local uiRoot = script.Parent.Parent
local componentsFolder = uiRoot:WaitForChild("components")
local ShopUI        = require(componentsFolder:WaitForChild("ShopUI"))
local ShopRenderer  = require(componentsFolder:WaitForChild("renderers"):WaitForChild("ShopRenderer"))
local ShopWires     = require(componentsFolder:WaitForChild("controllers"):WaitForChild("ShopWires"))
local TalismanBoard = require(componentsFolder:WaitForChild("TalismanBoard"))

export type Payload = {
	items: {any}?,
	stock: {any}?,
	mon: number?,
	totalMon: number?,
	rerollCost: number?,
	canReroll: boolean?,
	seasonSum: number?,
	target: number?,
	rewardMon: number?,
	lang: string?,
	notice: string?,
	currentDeck: any?,
	state: any?,
}

--==================================================
-- helpers
--==================================================

local function normToJa(lang: string?)
	local v = ShopFormat.normLang(lang)
	if v == "jp" then
		LOG.warn("[Locale] received legacy 'jp'; normalize to 'ja'")
		return "ja"
	end
	return v
end

local function countItems(p: Payload?): number
	if not p then return 0 end
	if typeof(p.items) == "table" then return #p.items end
	if typeof(p.stock) == "table" then return #p.stock end
	return 0
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
	if typeof(t) ~= "table" then
		return nil
	end
	return {
		maxSlots = tonumber(t.maxSlots or 6) or 6,
		unlocked = tonumber(t.unlocked or 0) or 0,
		slots    = cloneSlots6(t.slots),
	}
end

local function stockSignature(itemsTbl)
	if type(itemsTbl) ~= "table" then return "" end
	local ids = {}
	for i, it in ipairs(itemsTbl) do
		ids[i] = tostring(it.id or ("#"..i))
	end
	table.sort(ids)
	return table.concat(ids, "|")
end

local function talismanSignature(t)
	if typeof(t) ~= "table" then return "<nil>" end
	local parts = { tostring(tonumber(t.unlocked or 0) or 0) }
	local s = t.slots or {}
	for i = 1, 6 do
		parts[#parts+1] = tostring(s[i] or "")
	end
	return table.concat(parts, "|")
end

--==================================================
-- class
--==================================================

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

	-- プレビュー/ローカル影/シグネチャ
	self._preview = nil
	self._lastPlaced = nil
	self._localBoard = nil
	self._taliSig = "<none>"

	-- 一時SoldOut
	self._hiddenItems = {}   -- [itemId]=true
	self._stockSig = ""      -- 在庫構成署名

	-- UI生成
	local gui, nodes = ShopUI.build()
	self.gui = gui
	self._nodes = nodes

	-- 背景
	self:_ensureBg()

	-- 配線＆初期プレースホルダ
	ShopWires.wireButtons(self)
	ShopWires.applyInfoPlaceholder(self)

	-- ===== 護符ボード：下段（taliArea）に設置 =====
	do
		local parent = nodes.taliArea or gui  -- 念のためフォールバック
		self._taliBoard = TalismanBoard.new(parent, {
			title      = "護符ボード",
			widthScale = 0.95,   -- 下段にフィット
			padScale   = 0.01,
		})
		local inst = self._taliBoard:getInstance()
		inst.AnchorPoint = Vector2.new(0.5, 0)     -- 中央寄せ
		inst.Position    = UDim2.fromScale(0.5, 0) -- 上端中央
		inst.ZIndex      = 2                       -- 本文よりやや上
	end
	-- ==============================================

	-- Remotes（S4）
	self._remotes = RS:WaitForChild("Remotes", 10)
	if not self._remotes then
		LOG.warn("[ShopScreen] Remotes folder missing (timeout)")
	else
		self._placeRE = self._remotes:WaitForChild("PlaceOnSlot", 10)
		if not self._placeRE then
			LOG.warn("[ShopScreen] PlaceOnSlot missing (timeout)")
		end
		local ack = self._remotes:FindFirstChild("TalismanPlaced")
		if ack and ack:IsA("RemoteEvent") then
			ack.OnClientEvent:Connect(function(data)
				-- サーバ確定：ローカル影を更新
				local base = getTalismanFromPayload(self._payload) or { maxSlots=6, unlocked=0, slots={nil,nil,nil,nil,nil,nil} }
				self._localBoard = {
					maxSlots = base.maxSlots or 6,
					unlocked = tonumber(data and data.unlocked or base.unlocked or 0) or 0,
					slots    = (data and data.slots) or cloneSlots6(base.slots),
				}
				self._taliSig = talismanSignature(self._localBoard)
				self._preview = nil
				self._lastPlaced = nil
				if self._taliBoard then
					self._taliBoard:setData(self._localBoard)
				end
				LOG.debug("ack TalismanPlaced | idx=%s id=%s", tostring(data and data.index), tostring(data and data.id))
			end)
		end
	end

	self.LOG = LOG
	LOG.debug("boot")
	return self
end

--==================================================
-- public
--==================================================

function Shop:_snapBoard()
	return self._localBoard
		or self._preview
		or getTalismanFromPayload(self._payload)
		or { maxSlots=6, unlocked=0, slots={nil,nil,nil,nil,nil,nil} }
end

function Shop:_findFirstEmpty()
	local t = self:_snapBoard()
	local unlocked = tonumber(t.unlocked or 0) or 0
	local slots = t.slots or {}
	for i=1, math.min(unlocked, 6) do
		if slots[i] == nil then return i end
	end
	return nil
end

function Shop:_refreshStockSignature(payload: Payload?)
	local items = (payload and (payload.items or payload.stock)) or {}
	local sig = stockSignature(items)
	if sig ~= self._stockSig then
		self._stockSig = sig
		self._hiddenItems = {}
		LOG.debug("[Shop] stock changed -> clear hidden")
	end
end

function Shop:isItemHidden(id: any)
	if id == nil then return false end
	return self._hiddenItems[tostring(id)] == true
end
function Shop:hideItemTemporarily(id: any)
	if id == nil then return end
	self._hiddenItems[tostring(id)] = true
	self:_render()
end

local function maybeClearPreview(self)
	if not self._preview or not self._lastPlaced then return end
	local base = self:_snapBoard()
	if not base or not base.slots then return end
	local idx = self._lastPlaced.index
	local id  = self._lastPlaced.id
	if idx and id and base.slots[idx] == id then
		self._preview = nil
		self._lastPlaced = nil
		LOG.info("[Shop] preview cleared by server state | idx=%d id=%s", idx, id)
	end
end

-- サーバ確定 talisman をローカルへ即時反映（重複ならスキップ）
function Shop:_applyServerTalismanOnce(payload: Payload?)
	local sv = cloneTalismanData(getTalismanFromPayload(payload))
	if not sv then return end
	local sig = talismanSignature(sv)
	if sig == self._taliSig then
		-- 同一なら再描画不要
		return
	end
	self._localBoard = sv
	self._taliSig = sig
	self._preview = nil
	self._lastPlaced = nil
	if self._taliBoard then
		self._taliBoard:setData(self._localBoard)
	end
	LOG.debug("[Shop] server talisman applied | sig=%s", sig)
end

function Shop:setData(payload: Payload)
	if payload and payload.lang then
		local nl = normToJa(payload.lang)
		if nl and nl ~= payload.lang then payload.lang = nl end
		self._lang = nl or self._lang
	end
	self:_refreshStockSignature(payload)
	self._payload = payload
	maybeClearPreview(self)

	-- サーバ確定護符を優先反映（差分時のみ）
	self:_applyServerTalismanOnce(payload)

	LOG.debug("setData | items=%d lang=%s", countItems(payload), tostring(self._lang))

	if self._taliBoard then
		self._taliBoard:setLang(self._lang or "ja")
		-- ここでの setData は差分適用済み（_applyServerTalismanOnce 内）なので冪等維持
		self._taliBoard:setData(self:_snapBoard())
	end

	self:_render()
end

function Shop:show(payload: Payload?)
	if payload then
		if payload.lang then
			local nl = normToJa(payload.lang)
			if nl and nl ~= payload.lang then payload.lang = nl end
			self._lang = nl or self._lang
		end
		self:_refreshStockSignature(payload)
		self._payload = payload
		-- ★ 表示初期化：サーバ確定 talisman を即時反映（プレビューは破棄）
		self:_applyServerTalismanOnce(payload)
		maybeClearPreview(self)
	end
	self.gui.Enabled = true
	self:_ensureBg(true)
	LOG.info("show | enabled=true items=%d lang=%s", countItems(self._payload), tostring(self._lang))

	if self._taliBoard then
		self._taliBoard:setLang(self._lang or "ja")
		self._taliBoard:setData(self:_snapBoard())
	end

	self:_render()
	self:_applyRerollButtonState()
end

function Shop:hide()
	if self.gui.Enabled then
		LOG.debug("hide | enabled=false")
	end
	self.gui.Enabled = false
end

function Shop:update(payload: Payload?)
	if payload then
		if payload.lang then
			local nl = normToJa(payload.lang)
			if nl and nl ~= payload.lang then payload.lang = nl end
			self._lang = nl or self._lang
		end
		self:_refreshStockSignature(payload)
		self._payload = payload
		-- 連続 open/update 時も差分だけ適用
		self:_applyServerTalismanOnce(payload)
		maybeClearPreview(self)
	end
	LOG.debug("update | items=%d lang=%s", countItems(self._payload), tostring(self._lang))

	if self._taliBoard then
		self._taliBoard:setLang(self._lang or "ja")
		self._taliBoard:setData(self:_snapBoard())
	end

	self:_render()
	self:_applyRerollButtonState()
end

function Shop:setLang(lang: string?)
	self._lang = normToJa(lang)
	ShopWires.applyInfoPlaceholder(self)
	if self._taliBoard then
		self._taliBoard:setLang(self._lang or "ja")
	end
end

function Shop:attachRemotes(remotes: any, router: any?)
	LOG.debug("attachRemotes (compat)")
	return ShopWires.attachRemotes(self, remotes, router)
end

--==================================================
-- S4: auto-place（唯一の配置経路）
--==================================================

function Shop:autoPlace(talismanId: string, item: any?)
	if not talismanId or talismanId == "" then
		LOG.warn("[Shop] autoPlace: invalid talismanId")
		return
	end

	-- 条件：護符配列が無い or 空スロットがある（_findFirstEmpty() が nil なら中止）
	local idx = self:_findFirstEmpty()
	if not idx then
		local toast = self.deps and self.deps.toast
		if typeof(toast) == "function" then
			toast((self._lang=="ja") and "空きスロットがありません" or "No empty slot available")
		end
		LOG.info("[Shop] autoPlace aborted: no empty slot")
		return
	end

	-- UI: 直ちに「売り切れ」扱いにして非表示
	if item and item.id ~= nil then
		self:hideItemTemporarily(item.id)
	end

	LOG.info("[Shop] auto-place index=%d id=%s", idx, tostring(talismanId))

	-- プレビュー反映
	local t = self:_snapBoard()
	local preview = {
		maxSlots = t.maxSlots or 6,
		unlocked = t.unlocked or 0,
		slots    = cloneSlots6(t.slots),
	}
	preview.slots[idx] = tostring(talismanId) .. "(仮)"
	self._preview = preview
	self._lastPlaced = { index = idx, id = talismanId }
	if self._taliBoard then
		self._taliBoard:setData(self._preview)
	end

	-- サーバ確定
	if self._placeRE and self._placeRE:IsA("RemoteEvent") then
		self._placeRE:FireServer(idx, talismanId)
	else
		LOG.warn("[Shop] PlaceOnSlot RemoteEvent not available; local preview only")
	end
end

--==================================================
-- render
--==================================================

function Shop:_render()
	return ShopRenderer.render(self)
end

--==================================================
-- internal utils
--==================================================

function Shop:_ensureBg(forceToBack: boolean?)
	if not self.gui then return end
	local bg = self._bg
	if not bg or not bg.Parent then
		bg = Instance.new("ImageLabel")
		bg.Name = "BgImage"
		bg.BackgroundTransparency = 1
		bg.BorderSizePixel = 0
		bg.Active = false
		bg.ScaleType = Enum.ScaleType.Crop
		bg.AnchorPoint = Vector2.new(0.5, 0.5)
		bg.Position = UDim2.fromScale(0.5, 0.5)
		bg.Size = UDim2.fromScale(1, 1)
		bg.ZIndex = 0
		bg.Parent = self.gui
		self._bg = bg
	end
	bg.Image = Theme.IMAGES and Theme.IMAGES.SHOP_BG or ""
	bg.ImageTransparency = (Theme.TRANSPARENCY and Theme.TRANSPARENCY.shopBg) or 0
	if forceToBack then
		bg.ZIndex = 0
		bg.LayoutOrder = -10000
		bg.Parent = self.gui
	end
end

function Shop:_applyRerollButtonState()
	local p = self._payload or {}
	local money = tonumber(p.mon or p.totalMon or 0) or 0
	local cost  = tonumber(p.rerollCost or 1) or 1
	local can   = (p.canReroll ~= false) and (money >= cost)
	if self._nodes and self._nodes.rerollBtn then
		self._nodes.rerollBtn.Active = can
		self._nodes.rerollBtn.AutoButtonColor = can
	end
end

return Shop
