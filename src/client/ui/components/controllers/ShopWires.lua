-- v0.10.0-A  Wires send-only (A: ClientMain centralizes remote listeners)
--  - This file NO LONGER listens to Remotes.
--  - ShopOpen / ShopResult reception is centralized in ClientMain.
--  - Payloads arrive via ClientSignals.ShopIncoming (fired by ClientMain).
--  - View/Renderer never call remotes directly; they raise ClientSignals.* only.
--  - This module sends Buy/Reroll/Close to server and wires view buttons.

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Remotes = RS:WaitForChild("Remotes")

local SharedModules = RS:WaitForChild("SharedModules")
local Config        = RS:WaitForChild("Config")

local Logger     = require(SharedModules:WaitForChild("Logger"))
local LOG        = Logger.scope("ShopWires")
local Locale     = require(Config:WaitForChild("Locale"))
local LocaleUtil = require(SharedModules:WaitForChild("LocaleUtil"))

-- ClientSignals (Events bus shared across UI)
local ClientSignals = require(script.Parent:WaitForChild("ClientSignals"))

local M = {}

--=====================
-- DI deps (Router/toast)
--=====================
M._deps = {
	Router = nil,  -- expects ensure/show/call/active
	toast  = function(_) end,
}

--=====================
-- State
--=====================
M._wiredSignals = false
M._lastPayload  = nil
M._buyBusy      = false
M._rerollBusy   = false

--=====================
-- helpers
--=====================
local function _normLang(lang)
	return (type(LocaleUtil.norm)=="function" and LocaleUtil.norm(lang)) or lang or "en"
end

local function _snapFromView()
	-- Try to peek current ShopView instance payload as a fallback
	local R = M._deps.Router
	if not (R and type(R.ensure)=="function") then return nil end
	local ok, inst = pcall(function() return R.ensure("shop") end)
	if not ok or type(inst) ~= "table" then return nil end
	return inst._payload  -- ShopView keeps latest payload here
end

local function _currentPayload()
	-- Prefer the latest from ClientSignals.ShopIncoming; fallback to ShopView._payload
	return M._lastPayload or _snapFromView()
end

local function _money(payload)
	local p = payload or _currentPayload() or {}
	return tonumber((p.mon or p.totalMon) or 0) or 0
end

local function _snapTalisman(payload)
	local p = payload or _currentPayload()
	return p and p.state and p.state.run and p.state.run.talisman or nil
end

local function _findFirstEmptySlot(payload)
	local t = _snapTalisman(payload)
	if type(t) ~= "table" then return nil end
	local unlocked = tonumber(t.unlocked or 0) or 0
	local s = t.slots or {}
	for i=1, math.min(unlocked, 6) do
		if s[i] == nil then return i end
	end
	return nil
end

--=====================
-- Signals → Remotes（送信はここだけ）
--=====================
local function _sendBuy(it)
	if M._buyBusy or not it then return end

	local mon   = _money(nil)
	local price = tonumber(it.price or 0) or 0
	if mon < price then
		local lang = _normLang((M._lastPayload and M._lastPayload.lang) or "ja")
		local msg  = (type(Locale.t)=="function" and Locale.t(lang, "SHOP_UI_NOT_ENOUGH_MONEY")) or "お金が足りません"
		M._deps.toast(msg)
		return
	end

	M._buyBusy = true

	-- talisman は護符スロットに自動配置
	if tostring(it.category) == "talisman" and it.talismanId then
		local idx = _findFirstEmptySlot(nil)
		if not idx then
			local lang = _normLang((M._lastPayload and M._lastPayload.lang) or "ja")
			local msg  = (type(Locale.t)=="function" and Locale.t(lang, "SHOP_UI_NO_EMPTY_SLOT")) or "空きスロットがありません"
			M._deps.toast(msg)
			M._buyBusy = false
			return
		end
		local PlaceOnSlot = Remotes:FindFirstChild("PlaceOnSlot")
		if PlaceOnSlot and PlaceOnSlot:IsA("RemoteEvent") then
			pcall(function() PlaceOnSlot:FireServer(idx, it.talismanId) end)
		else
			LOG.warn("[ShopWires] PlaceOnSlot missing; skip")
		end
	else
		local BuyItem = Remotes:FindFirstChild("BuyItem")
		if BuyItem and BuyItem:IsA("RemoteEvent") then
			pcall(function() BuyItem:FireServer(it.id) end)
		else
			LOG.warn("[ShopWires] BuyItem missing; skip id=%s", tostring(it.id))
		end
	end

	task.delay(0.25, function() M._buyBusy = false end)
end

local function _sendReroll()
	if M._rerollBusy then return end
	M._rerollBusy = true
	local re = Remotes:FindFirstChild("ShopReroll")
	if re and re:IsA("RemoteEvent") then
		pcall(function() re:FireServer() end)
	else
		LOG.warn("[ShopWires] ShopReroll missing; skip")
	end
	task.delay(0.25, function() M._rerollBusy = false end)
end

local function _sendClose()
	local re = Remotes:FindFirstChild("ShopDone")
	if re and re:IsA("RemoteEvent") then
		pcall(function() re:FireServer() end)
	else
		LOG.warn("[ShopWires] ShopDone missing; skip")
	end
end

--=====================
-- Public: init / wireButtons / applyInfoPlaceholder
--=====================
function M.init(opts)
	M._deps.Router = (opts and opts.Router) or M._deps.Router
	M._deps.toast  = (opts and opts.toast)  or M._deps.toast

	if M._wiredSignals then return end

	-- ▼ ClientMain が発火するローカルバス（受信）を購読
	if ClientSignals and ClientSignals.ShopIncoming and typeof(ClientSignals.ShopIncoming.Connect)=="function" then
		ClientSignals.ShopIncoming:Connect(function(payload)
			if type(payload) == "table" then
				if payload.lang then payload.lang = _normLang(payload.lang) end
				M._lastPayload = payload
				LOG.info("ShopIncoming: payload updated (lang=%s)", tostring(payload.lang))
			end
		end)
	else
		LOG.warn("ClientSignals.ShopIncoming not available; relying on ShopView payload only")
	end

	-- ▲（任意）ShopResult は View 側で使う想定。必要ならここで購読してもよいが、受信は ClientMain に集約済み。

	-- Signals → Remotes（送信専任）
	if ClientSignals and ClientSignals.BuyRequested then
		ClientSignals.BuyRequested:Connect(_sendBuy)
	end
	if ClientSignals and ClientSignals.RerollRequested then
		ClientSignals.RerollRequested:Connect(_sendReroll)
	end
	if ClientSignals and ClientSignals.CloseRequested then
		ClientSignals.CloseRequested:Connect(_sendClose)
	end

	M._wiredSignals = true
	LOG.info("wired: ClientSignals (send-only: Buy/Reroll/Close) | recv via ShopIncoming")
end

function M.wireButtons(view)
	local n = view and view._nodes
	if not n then return end
	-- Reroll
	if n.rerollBtn and n.rerollBtn.Activated then
		n.rerollBtn.Activated:Connect(function()
			_sendReroll()
		end)
		LOG.info("wireButtons: RerollBtn connected")
	end
	-- Deck toggle
	if n.deckBtn and n.deckBtn.Activated then
		n.deckBtn.Activated:Connect(function()
			view._deckOpen = not (view._deckOpen == true)
			if n.deckPanel and n.infoPanel then
				n.deckPanel.Visible = view._deckOpen
				n.infoPanel.Visible = not view._deckOpen
			end
		end)
		LOG.info("wireButtons: DeckBtn connected")
	end
	-- Close
	if n.closeBtn and n.closeBtn.Activated then
		n.closeBtn.Activated:Connect(function()
			_sendClose()
			LOG.info("[CLOSE] → ShopDone.FireServer")
		end)
		LOG.info("wireButtons: CloseBtn connected")
	else
		LOG.warn("wireButtons: CloseBtn missing; skip")
	end
end

function M.applyInfoPlaceholder(view)
	local n = view and view._nodes
	if not n or not n.infoText then return end
	if n.infoText.Text == "" then
		n.infoText.Text = "（アイテムにマウスを乗せるか、クリックしてください）"
	end
end

return M
