-- ServerScriptService/UiResync.server.lua
local RS         = game:GetService("ReplicatedStorage")
local Remotes    = RS:WaitForChild("Remotes")
local SharedMods = RS:WaitForChild("SharedModules")
local StateHub   = require(SharedMods:WaitForChild("StateHub"))

local HandPush   = Remotes:WaitForChild("HandPush")
local FieldPush  = Remotes:WaitForChild("FieldPush")
local TakenPush  = Remotes:WaitForChild("TakenPush")
local ScorePush  = Remotes:WaitForChild("ScorePush")
local ReqSyncUI  = Remotes:WaitForChild("ReqSyncUI")

local function pushAll(plr)
	local s = StateHub.get(plr) or {}

	-- 初期データを各Pushで再送
	HandPush:FireClient(plr,  s.hand   or {})
	FieldPush:FireClient(plr, s.board  or {})
	TakenPush:FireClient(plr, s.taken  or {})

	-- ScorePush は（total, roles, detail）の3引数で送る
	local last = s.lastScore or {}
	local total  = tonumber(last.total)  or 0
	local roles  = last.roles            or {}
	local detail = last.detail           or { mon=0, pts=0 }
	ScorePush:FireClient(plr, total, roles, detail)

	-- 最後に State 正規ルート（季節・目標・合計など）
	StateHub.pushState(plr)
end

ReqSyncUI.OnServerEvent:Connect(function(plr)
	-- newRound直後の 0 残像を避けるため 1〜2フレーム待つ
	task.wait(0.1)
	pushAll(plr)
end)
