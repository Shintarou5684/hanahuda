-- ReplicatedStorage/SharedModules/NavClient.lua
-- v0.9.3 Nav ラッパ：UI は Nav:next("home"|"next"|"save") だけ呼ぶ
local M = {}
M.__index = M

type Legacy = { GoHome: RemoteEvent?, GoNext: RemoteEvent?, SaveQuit: RemoteEvent? }

function M.new(decideNext: RemoteEvent?, legacy: Legacy?)
	local self = setmetatable({}, M)
	self.DecideNext = decideNext
	self.legacy = legacy or {}
	return self
end

function M:next(op: string)
	-- ロガー整備前の暫定：DoD用ログ
	print("NAV: next " .. tostring(op))
	-- 正準
	if self.DecideNext then
		self.DecideNext:FireServer(op)
		return
	end
	-- レガシー互換（段階的廃止）
	if op == "home" and self.legacy.GoHome then self.legacy.GoHome:FireServer(); return end
	if op == "next" and self.legacy.GoNext then self.legacy.GoNext:FireServer(); return end
	if op == "save" and self.legacy.SaveQuit then self.legacy.SaveQuit:FireServer(); return end
	warn("[NavClient] No route for op=", op)
end

return M
