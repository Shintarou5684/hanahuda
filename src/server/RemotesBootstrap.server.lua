-- RemotesBootstrap.server.lua
print("[RemotesBootstrap] wiring...")

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

-- Remotes フォルダを保証
local Remotes = RS:FindFirstChild("Remotes")
if not Remotes then
    Remotes = Instance.new("Folder")
    Remotes.Name = "Remotes"
    Remotes.Parent = RS
end

-- 使う（使う予定の）RemoteEvent 名
local REMOTE_NAMES = {
    -- S->C
    "HandPush", "FieldPush", "TakenPush", "ScorePush", "StatePush", "ShopOpen",
    -- C->S
    "Confirm", "ReqPick", "ReqRerollAll", "ReqRerollHand", "ShopDone",
    -- 起動/同期系
    "ReqStartNewRun", "ReqSyncUI",
}

local function ensureRemote(name)
    local r = Remotes:FindFirstChild(name)
    if not r then
        r = Instance.new("RemoteEvent")
        r.Name = name
        r.Parent = Remotes
    end
    return r
end

-- 参照マップ
local R = {}
for _, n in ipairs(REMOTE_NAMES) do
    R[n] = ensureRemote(n)
end

-- 超簡易ステート（あとで本実装に差し替えてOK）
local stateByUserId = {}

local function initState(plr)
    stateByUserId[plr.UserId] = {
        season    = 1,
        handsLeft = 8,
        mon       = 0,
        bank      = 0,
        phase     = "play",
    }
end

local function pushState(plr)
    local s = stateByUserId[plr.UserId]
    if not s then initState(plr); s = stateByUserId[plr.UserId] end
    R.StatePush:FireClient(plr, s)
end

Players.PlayerAdded:Connect(function(plr)
    initState(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
    stateByUserId[plr.UserId] = nil
end)

-- ===== C->S（とりあえずログ＋最低限動作） =====
R.ReqStartNewRun.OnServerEvent:Connect(function(plr)
    print(("[S] ReqStartNewRun from %s"):format(plr.Name))
    initState(plr)
    pushState(plr)
end)

R.ReqSyncUI.OnServerEvent:Connect(function(plr)
    print(("[S] ReqSyncUI from %s"):format(plr.Name))
    pushState(plr)
end)

R.Confirm.OnServerEvent:Connect(function(plr, ...)
    print("[S] Confirm", plr.Name, ...)
end)

R.ReqPick.OnServerEvent:Connect(function(plr, ...)
    print("[S] ReqPick", plr.Name, ...)
end)

R.ReqRerollAll.OnServerEvent:Connect(function(plr, ...)
    print("[S] ReqRerollAll", plr.Name, ...)
end)

R.ReqRerollHand.OnServerEvent:Connect(function(plr, ...)
    print("[S] ReqRerollHand", plr.Name, ...)
end)

R.ShopDone.OnServerEvent:Connect(function(plr, ...)
    print("[S] ShopDone", plr.Name, ...)
end)

print("[RemotesBootstrap] ready")
