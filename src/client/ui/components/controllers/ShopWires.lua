-- v0.10.0 Wires single-route: Remotes subscriber & sender
--  - Only this file listens to Remotes (ShopOpen/ShopResult)
--  - View/Renderer never fire remotes; they raise ClientSignals.* only
--  - Also wires View buttons and deck toggle

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Remotes = RS:WaitForChild("Remotes")

local SharedModules = RS:WaitForChild("SharedModules")
local Config        = RS:WaitForChild("Config")

local Logger     = require(SharedModules:WaitForChild("Logger"))
local LOG        = Logger.scope("ShopWires")
local Locale     = require(Config:WaitForChild("Locale"))
local LocaleUtil = require(SharedModules:WaitForChild("LocaleUtil"))

local ClientSignals = require(script.Parent:WaitForChild("ClientSignals"))

local M = {}

-- deps: Router/toast だけDI（なければ安全スタブ）
M._deps = {
	Router = nil,
	toast  = function(_) end,
}

M._wiredRemotes = false
M._wiredSignals = false
M._lastPayload  = nil
M._buyBusy      = false
M._rerollBusy   = false

--=====================
-- helpers
--=====================
local function _normLang(lang)
	local l = (type(Locale.normalize)=="function" and Locale.normalize(lang)) or lang or "en"
	if tostring(lang or ""):lower()=="jp" and l=="ja" then
		LOG.warn("[Locale] received legacy 'jp'; normalize to 'ja'")
	end
	return l
end

local function _ensureRouter()
	local R = M._deps.Router or {}
	R.ensure = (type(R.ensure)=="function") and R.ensure or function() end
	R.active = (type(R.active)=="function") and R.active or function() return nil end
	R.show   = (type(R.show)  =="function") and R.show   or function() end
	R.call   = (type(R.call)  =="function") and R.call   or function() end
	return R
end

local function _snapTalisman(payload)
	local p = payload or M._lastPayload
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

local function _money(payload)
	return tonumber((payload and (payload.mon or payload.totalMon)) or 0) or 0
end

--=====================
-- Remotes → Signals / Router
--=====================
local function _onShopOpen(payload)
	M._lastPayload = payload or {}
	if M._lastPayload and M._lastPayload.lang then
		M._lastPayload.lang = _normLang(M._lastPayload.lang)
	end

	-- Router制御（kitoPick前面時は裏更新）
	local R = _ensureRouter()
	if R.active() == "kitoPick" then
		local ok, shopInst = pcall(function() return R.ensure("shop") end)
		if ok and shopInst then
			if type(shopInst.setData)=="function" then
				pcall(function() shopInst:setData(M._lastPayload) end)
			end
			if type(shopInst.update)=="function" then
				pcall(function() shopInst:update(M._lastPayload) end)
			end
			LOG.info("<ShopOpen> updated in background | lang=%s (kitoPick active)", tostring(M._lastPayload.lang))
		else
			R.show("shop", M._lastPayload)
			LOG.info("<ShopOpen> routed (fallback) | lang=%s", tostring(M._lastPayload.lang))
		end
	else
		R.show("shop", M._lastPayload)
		LOG.info("<ShopOpen> routed | lang=%s", tostring(M._lastPayload.lang))
	end

	-- ローカルバス配布（必要なら他UIが聞ける）
	ClientSignals.ShopIncoming:Fire(M._lastPayload)
end

local function _onShopResult(res)
	ClientSignals.ShopResult:Fire(res)
end

--=====================
-- Signals → Remotes（送信はここだけ）
--=====================
local function _sendBuy(it)
	if M._buyBusy then return end
	if not it then return end
	local mon   = _money(M._lastPayload)
	local price = tonumber(it.price or 0) or 0
	if mon < price then
		M._deps.toast((Locale.t and Locale.t(_normLang(M._lastPayload and M._lastPayload.lang), "SHOP_UI_NOT_ENOUGH_MONEY")) or "お金が足りません")
		return
	end
	M._buyBusy = true

	-- talisman は自動配置
	if tostring(it.category) == "talisman" and it.talismanId then
		local idx = _findFirstEmptySlot(M._lastPayload)
		if not idx then
			M._deps.toast(Locale.t(_normLang(M._lastPayload and M._lastPayload.lang), "SHOP_UI_NO_EMPTY_SLOT"))
			M._buyBusy = false
			return
		end
		local PlaceOnSlot = Remotes:FindFirstChild("PlaceOnSlot")
		if PlaceOnSlot and PlaceOnSlot:IsA("RemoteEvent") then
			PlaceOnSlot:FireServer(idx, it.talismanId)
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

	-- Remotes → Signals
	if not M._wiredRemotes then
		local ShopOpen = Remotes:WaitForChild("ShopOpen")
		ShopOpen.OnClientEvent:Connect(_onShopOpen)
		local ShopResult = Remotes:FindFirstChild("ShopResult")
		if ShopResult and ShopResult:IsA("RemoteEvent") then
			ShopResult.OnClientEvent:Connect(_onShopResult)
		end
		M._wiredRemotes = true
		LOG.info("wired: Remotes (ShopOpen/ShopResult)")
	end

	-- Signals → Remotes（送信）
	if not M._wiredSignals then
		ClientSignals.BuyRequested:Connect(_sendBuy)
		ClientSignals.RerollRequested:Connect(_sendReroll)
		ClientSignals.CloseRequested:Connect(_sendClose)
		M._wiredSignals = true
		LOG.info("wired: ClientSignals (Buy/Reroll/Close)")
	end
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
