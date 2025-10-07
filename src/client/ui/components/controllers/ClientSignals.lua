-- Lightweight local-bus for Shop UI
local function newSignal()
	local ev = Instance.new("BindableEvent")
	return {
		Fire    = function(self, ...) ev:Fire(...) end,
		Connect = function(self, fn) return ev.Event:Connect(fn) end,
		Wait    = function(self) return ev.Event:Wait() end,
	}
end

local Signals = {
	-- Remotes → UI
	ShopIncoming = newSignal(),  -- payload
	ShopResult   = newSignal(),  -- result from server (optional)

	-- UI → Wires（送信は Wires が担う）
	BuyRequested    = newSignal(), -- (itemTable)
	RerollRequested = newSignal(),
	CloseRequested  = newSignal(),
	DeckToggle      = newSignal(), -- optional
}

return Signals
