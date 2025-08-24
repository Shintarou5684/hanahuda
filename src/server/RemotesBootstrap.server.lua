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
    "HandPush","FieldPush","TakenPush","ScorePush","StatePush","ShopOpen","HomeOpen",
    -- C->S
    "Confirm","ReqPick","ReqRerollAll","ReqRerollHand","ShopDone",
    -- 起動/同期系
    "ReqStartNewRun","ReqContinueRun","ReqSyncUI","RoundReady",
    -- 屋台
    "BuyItem","ShopReroll",
    -- DEV（Studio用）
    "DevGrantRole","DevGrantRyo",
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

-- 超簡易ステート（あとで本実装に差し替えOK）
local stateByUserId = {}

local function initState(plr)
    stateByUserId[plr.UserId] = {
        -- 基本
        season    = 1,
        target    = 10,
        sum       = 0,
        -- 手番系（UI後方互換のため両方もたせる）
        handsLeft = 8,
        hands     = 8,   -- ClientGuiController は hands を見る
        rerolls   = 0,
        mult      = 1.0,
        -- 通貨/山札
        bank      = 0,
        deckLeft  = 0,
        handLeft  = 8,
        phase     = "play",
    }
end

local function ensureUICompat(s)
    -- 互換フィールドを補完（nil のときだけ）
    if s.hands == nil and s.handsLeft ~= nil then s.hands = s.handsLeft end
    if s.handsLeft == nil and s.hands ~= nil then s.handsLeft = s.hands end
    if s.rerolls == nil then s.rerolls = 0 end
    if s.mult == nil then s.mult = 1.0 end
    if s.target == nil then s.target = 0 end
    if s.sum == nil then s.sum = 0 end
    if s.bank == nil then s.bank = 0 end
    if s.deckLeft == nil then s.deckLeft = 0 end
    if s.handLeft == nil then s.handLeft = s.hands or s.handsLeft or 0 end
end

local function pushState(plr)
    local s = stateByUserId[plr.UserId]
    if not s then initState(plr); s = stateByUserId[plr.UserId] end
    ensureUICompat(s)
    R.StatePush:FireClient(plr, s)
end

Players.PlayerAdded:Connect(function(plr)
    initState(plr)
    -- 必要ならホームを開く通知などここで：
    -- R.HomeOpen:FireClient(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
    stateByUserId[plr.UserId] = nil
end)

-- ===== C->S（とりあえずログ＋最低限動作） =====
R.ReqStartNewRun.OnServerEvent:Connect(function(plr)
    print(("[S] ReqStartNewRun from %s"):format(plr.Name))
    initState(plr)
    pushState(plr)
    -- R.RoundReady:FireClient(plr) -- 必要なら通知
end)

R.ReqContinueRun.OnServerEvent:Connect(function(plr)
    print(("[S] ReqContinueRun from %s"):format(plr.Name))
    -- TODO: セーブから復元する実装に差し替え予定
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

-- DEV ユーティリティ（UIの+役/+両）
if R.DevGrantRole then
    R.DevGrantRole.OnServerEvent:Connect(function(plr)
        print("[S][DEV] GrantRole for", plr.Name)
        -- TODO: 取り札に酒/月/花を注入→ScorePush など
    end)
end
if R.DevGrantRyo then
    R.DevGrantRyo.OnServerEvent:Connect(function(plr, amount)
        amount = tonumber(amount) or 0
        local s = stateByUserId[plr.UserId]; if not s then return end
        s.bank = math.max(0, (s.bank or 0) + amount)
        ensureUICompat(s)
        R.StatePush:FireClient(plr, s)
        print(("[S][DEV] GrantRyo +%d to %s (bank=%d)"):format(amount, plr.Name, s.bank))
    end)
end

print("[RemotesBootstrap] ready")
