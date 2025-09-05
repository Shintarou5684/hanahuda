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
		_conns = {},
		deps = deps,
		h = h,
	}

	function self:connect()
		table.insert(self._conns, self.deps.HandPush .OnClientEvent:Connect(self.h.onHand))
		table.insert(self._conns, self.deps.FieldPush.OnClientEvent:Connect(self.h.onField))
		table.insert(self._conns, self.deps.TakenPush.OnClientEvent:Connect(self.h.onTaken))
		table.insert(self._conns, self.deps.ScorePush.OnClientEvent:Connect(self.h.onScore))
		table.insert(self._conns, self.deps.StatePush.OnClientEvent:Connect(self.h.onState))
		if self.deps.StageResult then
			table.insert(self._conns, self.deps.StageResult.OnClientEvent:Connect(function(...) self.h.onStageResult(...) end))
		end
	end

	function self:disconnect()
		for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
		table.clear(self._conns)
	end

	return self
end

return M
