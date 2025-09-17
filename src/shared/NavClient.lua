-- ReplicatedStorage/SharedModules/NavClient.lua
-- v0.9.3 Nav ラッパ：UI は Nav:next("home"|"next"|"save") だけ呼ぶ

local M = {}
M.__index = M

-- legacy = { GoHome: RemoteEvent?, GoNext: RemoteEvent?, SaveQuit: RemoteEvent? }
function M.new(decideNext, legacy)
	local self = setmetatable({}, M)
	self.DecideNext = decideNext
	self.legacy = legacy or {}
	return self
end

function M:next(op)
	-- ロガー整備前の暫定：DoD用ログ
	print("NAV: next " .. tostring(op))

	-- 正準
	if self.DecideNext and typeof(self.DecideNext.FireServer) == "function" then
		self.DecideNext:FireServer(op)
		return
	end

	-- レガシー互換（段階的廃止）
	local lg = self.legacy or {}
	if op == "home" and lg.GoHome then lg.GoHome:FireServer(); return end
	if op == "next" and lg.GoNext then lg.GoNext:FireServer(); return end
	if op == "save" and lg.SaveQuit then lg.SaveQuit:FireServer(); return end

	warn("[NavClient] No route for op=", op)
end

return M
