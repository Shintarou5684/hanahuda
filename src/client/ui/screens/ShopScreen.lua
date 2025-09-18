-- src/client/ui/screens/ShopScreen.lua
-- v0.9.7-P2-2 ShopScreen（屋台背景レイヤ + 護符ボード常時表示 / Logger導入 / 言語コード正規化）
--  - [A] ShopFormat
--  - [B] ShopCells
--  - [C] ShopUI
--  - [D] ShopRenderer
--  - [E] ShopWires（ボタン配線／ShopOpenリスナーは持たない＝ClientMainに一本化）
--  - [+] 背景レイヤ（Theme.IMAGES.SHOP_BG / Theme.TRANSPARENCY.shopBg を採用）
--  - [+] 護符ボード（TalismanBoard）を常時表示（表示のみ / 操作不可）

local Shop = {}
Shop.__index = Shop

--========= 依存読込 =========
local RS = game:GetService("ReplicatedStorage")
local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat = require(SharedModules:WaitForChild("ShopFormat"))

-- Theme（背景ID/透過など単一情報源）
local Config = RS:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

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
-- [+] 護符ボード（表示専用）
local TalismanBoard = require(componentsFolder:WaitForChild("TalismanBoard"))

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
	-- state は Router からの統合payloadで入ってくる想定
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
	self._bg = nil -- 背景ImageLabel
	self._taliBoard = nil -- [+] 護符ボード

	-- UI生成
	local gui, nodes = ShopUI.build()
	self.gui = gui
	self._nodes = nodes

	-- ▼ 背景レイヤを用意（最背面）。ThemeからID/透過を取得。
	self:_ensureBg()

	-- ▼ 配線＆初期プレースホルダ
	ShopWires.wireButtons(self)
	ShopWires.applyInfoPlaceholder(self)

	-- [+] ▼ 護符ボード（表示のみ）を右上に常時表示（初期タイトルはJP。言語は後で setLangで反映）
	do
		self._taliBoard = TalismanBoard.new(self.gui, { title = "護符ボード" })
		local inst = self._taliBoard:getInstance()
		-- 右上固定（重なり回避のため、少し内側に寄せる）
		inst.AnchorPoint = Vector2.new(1, 0)
		inst.Position = UDim2.new(1, -24, 0, 64)   -- 右から24px / 上から64px
		inst.ZIndex = 5                              -- 背景(0)より上。既存UIが1〜4なら5に。
	end

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

	-- [+] 護符ボードへ反映（言語→データの順で）
	if self._taliBoard then
		self._taliBoard:setLang(self._lang or "ja")
		self._taliBoard:setData(getTalismanFromPayload(payload))
	end

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
	self:_ensureBg(true) -- 有効化時に最背面へ再配置（他UIが増えても背面を維持）
	LOG.info("show | enabled=true items=%d lang=%s", countItems(self._payload), tostring(self._lang))

	-- [+] 護符ボードへ反映（再表示時にも同期）
	if self._taliBoard then
		self._taliBoard:setLang(self._lang or "ja")
		self._taliBoard:setData(getTalismanFromPayload(self._payload))
	end

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

	-- [+] 護符ボードへ反映（差分更新でも同期）
	if self._taliBoard then
		self._taliBoard:setLang(self._lang or "ja")
		self._taliBoard:setData(getTalismanFromPayload(self._payload))
	end

	self:_render()
	self:_applyRerollButtonState() -- P0-5: 差分更新時も評価
end

function Shop:setLang(lang: string?)
	-- ★ ログ出力を抑止（ノイジーなため）
	self._lang = normToJa(lang)
	ShopWires.applyInfoPlaceholder(self)

	-- [+] 護符ボードのタイトルも追従（ここでは再renderしない）
	if self._taliBoard then
		self._taliBoard:setLang(self._lang or "ja")
	end
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

-- 背景ImageLabelの生成・更新（Themeに追従）
function Shop:_ensureBg(forceToBack: boolean?)
	if not self.gui then return end

	-- 既存があれば更新、なければ生成
	local bg = self._bg
	if not bg or not bg.Parent then
		bg = Instance.new("ImageLabel")
		bg.Name = "BgImage"
		bg.BackgroundTransparency = 1
		bg.BorderSizePixel = 0
		bg.Active = false -- クリック透過
		bg.ScaleType = Enum.ScaleType.Crop -- 画面全面を覆う
		bg.AnchorPoint = Vector2.new(0.5, 0.5)
		bg.Position = UDim2.fromScale(0.5, 0.5)
		bg.Size = UDim2.fromScale(1, 1)
		bg.ZIndex = 0
		bg.Parent = self.gui
		self._bg = bg
	end

	-- Theme から画像/透過を反映
	bg.Image = Theme.IMAGES and Theme.IMAGES.SHOP_BG or ""
	bg.ImageTransparency = (Theme.TRANSPARENCY and Theme.TRANSPARENCY.shopBg) or 0

	-- 同一ScreenGui内で最背面に維持（Bg→その他UIの順）
	if forceToBack then
		-- BgImage をいったん最後に出してから ZIndex=0 に固定、
		-- 他の子は ZIndex>=1 の想定（既存UIは通常1以上）。
		bg.ZIndex = 0
		bg.LayoutOrder = -10000 -- 並び順ヒント（ZIndexBehavior.Sibling時の保険）
		bg.Parent = self.gui -- reparentで最後尾へ（明示）
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
