-- src/client/ui/screens/ShopScreen.lua
-- v0.9.SIMPLE ShopScreen（残回数系の型定義を撤去）
--  - [A] ShopFormat
--  - [B] ShopCells
--  - [C] ShopUI
--  - [D] ShopRenderer
--  - [E] ShopWires（配線・Remotes委譲）

local Shop = {}
Shop.__index = Shop

--========= 依存読込 =========
local RS = game:GetService("ReplicatedStorage")
local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat = require(SharedModules:WaitForChild("ShopFormat"))

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
	lang: string?,         -- "ja"/"en"
	notice: string?,       -- UI通知文
	currentDeck: any?,     -- {v=2, codes, histogram, entries[{code,kind}], count}
}

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

	return self
end

--==================================================
-- public
--==================================================

function Shop:setData(payload: Payload)
	print("[SHOP][UI] setData items=", (payload and (payload.items and #payload.items or payload.stock and #payload.stock)) or 0)
	self._payload = payload
	self:_render()
end

function Shop:show(payload: Payload?)
	if payload then self._payload = payload end
	self.gui.Enabled = true
	print("[SHOP][UI] show (enabled=true)")
	self:_render()
end

function Shop:hide()
	if self.gui.Enabled then
		print("[SHOP][UI] hide (enabled=false)")
	end
	self.gui.Enabled = false
end

function Shop:update(payload: Payload?)
	if payload then self._payload = payload end
	print("[SHOP][UI] update")
	self:_render()
end

function Shop:setLang(lang: string?)
	self._lang = ShopFormat.normLang(lang)
	print("[SHOP][UI] setLang ->", self._lang)
	ShopWires.applyInfoPlaceholder(self)
	self:_render()
end

-- Remotes配線（委譲）
function Shop:attachRemotes(remotes: any, router: any?)
	return ShopWires.attachRemotes(self, remotes, router)
end

--==================================================
-- render（委譲）
--==================================================

function Shop:_render()
	return ShopRenderer.render(self)
end

return Shop
