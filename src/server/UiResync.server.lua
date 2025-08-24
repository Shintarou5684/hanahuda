-- UiResync.server.lua  v0.8.2
-- 役割：クライアントからの ReqSyncUI を受けて UI 一式を再送

local RS = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes")
local HandPush   = Remotes:WaitForChild("HandPush")
local FieldPush  = Remotes:WaitForChild("FieldPush")
local TakenPush  = Remotes:WaitForChild("TakenPush")
local ScorePush  = Remotes:WaitForChild("ScorePush")

local Shared = RS:WaitForChild("SharedModules")
local StateHub = require(Shared:WaitForChild("StateHub"))
local Score    = require(Shared:WaitForChild("ScoreService"))

local function pushAll(plr, s)
	HandPush :FireClient(plr, s and s.hand   or {})
	FieldPush:FireClient(plr, s and s.board  or {})
	TakenPush:FireClient(plr, s and s.taken  or {})
	local total, roles, detail = Score.lastScoreFor(s)
	ScorePush:FireClient(plr, total or 0, roles or {}, detail or {mon=0,pts=0})
	StateHub.pushState(plr, s, Remotes)
end

Remotes:WaitForChild("ReqSyncUI").OnServerEvent:Connect(function(plr)
	local s = StateHub.get(plr)
	if not s then return end
	-- ラウンド初期化直後の数フレーム待ち（0残像対策）
	task.wait(0.05)
	pushAll(plr, s)
end)
