-- StarterPlayerScripts/UI/screens/RunScreenRemotes.lua
-- Remote 購読/解除と、UI適用の橋渡し

local M = {}

export type Handlers = {
	onHand: (any)->(),
	onField: (any)->(),
	onTaken: (any)->(),
	onScore: (total:any, roles:any, detail:any)->(),
	onState: (st:any)->(),
	onStageResult: (...any)->(),
}

function M.create(deps: any, h: Handlers)
	local self = {
		_conns = {} :: { RBXScriptConnection },
		_connected = false,
		deps = deps or {},
		h = h or ({} :: any),
	}

	-- 内部：安全に Connect するヘルパ
	local function _tryConnect(signal: any, handler: (...any)->())
		if typeof(signal) == "Instance" and signal:IsA("RemoteEvent") then
			return signal.OnClientEvent:Connect(handler)
		elseif typeof(signal) == "RBXScriptSignal" then
			-- もし将来 Bindable/Signal を使う場合の逃げ
			return signal:Connect(handler)
		end
		return nil
	end

	function self:connect()
		if self._connected then return end
		self._connected = true

		-- 必須系
		local c1 = _tryConnect(self.deps.HandPush , self.h.onHand)
		local c2 = _tryConnect(self.deps.FieldPush, self.h.onField)
		local c3 = _tryConnect(self.deps.TakenPush, self.h.onTaken)
		local c4 = _tryConnect(self.deps.ScorePush, self.h.onScore)
		local c5 = _tryConnect(self.deps.StatePush, self.h.onState)

		-- 任意：StageResult
		local c6 = nil
		if self.deps.StageResult ~= nil then
			c6 = _tryConnect(self.deps.StageResult, function(...) self.h.onStageResult(...) end)
		end

		-- つながったものだけ蓄積
		if c1 then table.insert(self._conns, c1) end
		if c2 then table.insert(self._conns, c2) end
		if c3 then table.insert(self._conns, c3) end
		if c4 then table.insert(self._conns, c4) end
		if c5 then table.insert(self._conns, c5) end
		if c6 then table.insert(self._conns, c6) end
	end

	function self:disconnect()
		for _, c in ipairs(self._conns) do
			pcall(function() c:Disconnect() end)
		end
		table.clear(self._conns)
		self._connected = false
	end

	return self
end

return M
