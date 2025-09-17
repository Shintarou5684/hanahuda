-- src/client/ui/screens/ShopScreen.lua
-- v0.9.6-P1-3 ShopScreen（Logger導入／言語コードを "ja"/"en" に正規化・"jp" は警告して "ja" へ）
--  - [A] ShopFormat
--  - [B] ShopCells
--  - [C] ShopUI
--  - [D] ShopRenderer
--  - [E] ShopWires（ボタン配線／ShopOpenリスナーは持たない＝ClientMainに一本化）

local Shop = {}
Shop.__index = Shop

--========= 依存読込 =========
local RS = game:GetService("ReplicatedStorage")
local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat = require(SharedModules:WaitForChild("ShopFormat"))

-- Logger
local Logger = require(SharedModules:WaitForChild("Logger"))
-- ⚠️ Luau ではフィールド名に予約語（for）はドット記法不可。ブラケットで呼ぶ。
local LOG = (typeof(Logger.scope) == "function" and Logger.scope("ShopScreen"))
		or (typeof(Logger["for"]) == "function" and Logger["for"]("ShopScreen"))
		or { debug=function()end, info=function()end, warn=function(...) warn(...) end }

-- ui/components/*
local uiRoot = script.Parent.Parent
local componentsFolder = uiRoot:WaitForChild("components")
local ShopUI       = require(componentsFolder:WaitForChild("ShopUI"))
local ShopRenderer = require(componentsFolder:WaitForChild("renderers"):WaitForChild("ShopRenderer"))
local ShopWires    = require(componentsFolder:WaitForChild("controllers"):WaitForChild("ShopWires"))

export type Payload = {
	items: {any}?,         -- サーバ互換: items/stock どちらでも
	stock: {any}?,
	mon: number?,          -- 所持文（同義: totalMon）
	totalMon: number?,
	rerollCost: number?,   -- 1回あたりの費用
	canReroll: boolean?,   -- サーバ提示の可否（なければクライアントで mon>=cost 判定）
	seasonSum: number?,    -- クリア合計
	target: number?,       -- 目標
	rewardMon: number?,    -- 報酬
	lang: string?,         -- "ja"/"en"（※"jp" は受けたら "ja" に正規化）
	notice: string?,       -- UI通知文
	currentDeck: any?,     -- {v=2, codes, histogram, entries[{code,kind}], count}
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

	-- UI生成
	local gui, nodes = ShopUI.build()
	self.gui = gui
	self._nodes = nodes

	-- 配線＆初期プレースホルダ
	ShopWires.wireButtons(self)
	ShopWires.applyInfoPlaceholder(self)

	LOG.debug("boot")
	return self
end

--==================================================
-- public
--==================================================

function Shop:setData(payload: Payload)
	-- 言語正規化（"jp" → "ja"）
	if payload and payload.lang then
		local nl = normToJa(payload.lang)
		if nl and nl ~= payload.lang then payload.lang = nl end
		self._lang = nl or self._lang
	end
	self._payload = payload
	LOG.debug("setData | items=%d lang=%s", countItems(payload), tostring(self._lang))
	self:_render()
end

function Shop:show(payload: Payload?)
	if payload then
		-- 言語正規化（"jp" → "ja"）
		if payload.lang then
			local nl = normToJa(payload.lang)
			if nl and nl ~= payload.lang then payload.lang = nl end
			self._lang = nl or self._lang
		end
		self._payload = payload
	end
	self.gui.Enabled = true
	LOG.info("show | enabled=true items=%d lang=%s", countItems(self._payload), tostring(self._lang))
	self:_render()
	self:_applyRerollButtonState() -- P0-5: 受信後にボタン可否を再評価
end

function Shop:hide()
	if self.gui.Enabled then
		LOG.debug("hide | enabled=false")
	end
	self.gui.Enabled = false
end

function Shop:update(payload: Payload?)
	if payload then
		-- 言語正規化（"jp" → "ja"）
		if payload.lang then
			local nl = normToJa(payload.lang)
			if nl and nl ~= payload.lang then payload.lang = nl end
			self._lang = nl or self._lang
		end
		self._payload = payload
	end
	LOG.debug("update | items=%d lang=%s", countItems(self._payload), tostring(self._lang))
	self:_render()
	self:_applyRerollButtonState() -- P0-5: 差分更新時も評価
end

function Shop:setLang(lang: string?)
	-- ★ ログ出力を抑止（ノイジーなため）
	self._lang = normToJa(lang)
	ShopWires.applyInfoPlaceholder(self)
	-- P0-8対応: setLang ではフルレンダしない（旧payloadでの再有効化を防ぐ）
end

-- Remotes配線（委譲／非推奨フックを返すだけ）
function Shop:attachRemotes(remotes: any, router: any?)
	-- ShopWires.attachRemotes は警告を出しつつ「UIだけ更新する関数」を返す
	-- （ClientMain が唯一 <ShopOpen> を受け、Router.show("shop", payload) まで行う想定）
	LOG.debug("attachRemotes (compat)")
	return ShopWires.attachRemotes(self, remotes, router)
end

--==================================================
-- render（委譲）
--==================================================

function Shop:_render()
	return ShopRenderer.render(self)
end

--==================================================
-- internal utils
--==================================================

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
