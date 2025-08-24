-- ClientWireTap.client.lua
print("[ClientWireTap] ready")

local RS      = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes")

local HandPush      = Remotes:WaitForChild("HandPush")
local FieldPush     = Remotes:WaitForChild("FieldPush")
local TakenPush     = Remotes:WaitForChild("TakenPush")
local ScorePush     = Remotes:WaitForChild("ScorePush")
local StatePush     = Remotes:WaitForChild("StatePush")
local ShopOpen      = Remotes:WaitForChild("ShopOpen")

local ReqStartNewRun= Remotes:WaitForChild("ReqStartNewRun")
local ReqSyncUI     = Remotes:WaitForChild("ReqSyncUI")
local Confirm       = Remotes:WaitForChild("Confirm")
local ReqPick       = Remotes:WaitForChild("ReqPick")
local ReqRerollAll  = Remotes:WaitForChild("ReqRerollAll")
local ReqRerollHand = Remotes:WaitForChild("ReqRerollHand")
local ShopDone      = Remotes:WaitForChild("ShopDone")

-- S->C ログ
local function log(name, ...)
    local args = {...}
    print(("[C] %s: %s"):format(name, table.concat(args, ", ")))
end

HandPush.OnClientEvent:Connect(function(...)  log("HandPush", ...) end)
FieldPush.OnClientEvent:Connect(function(...) log("FieldPush", ...) end)
TakenPush.OnClientEvent:Connect(function(...) log("TakenPush", ...) end)
ScorePush.OnClientEvent:Connect(function(...) log("ScorePush", ...) end)

StatePush.OnClientEvent:Connect(function(st)
    print(("[C] State: season=%s hands=%s mon=%s bank=%s phase=%s")
        :format(st.season, st.handsLeft, st.mon, st.bank, st.phase or "?"))
end)

ShopOpen.OnClientEvent:Connect(function(...) log("ShopOpen", ...) end)

-- 起動直後、最小往復
task.delay(1, function()
    print("[C] Request NewRun...")
    ReqStartNewRun:FireServer()
    task.wait(0.2)
    ReqSyncUI:FireServer()
end)

-- キー操作で手早くテスト
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.N then
        print("[C] N: NewRun"); ReqStartNewRun:FireServer()
    elseif input.KeyCode == Enum.KeyCode.R then
        print("[C] R: SyncUI"); ReqSyncUI:FireServer()
    elseif input.KeyCode == Enum.KeyCode.C then
        print("[C] C: Confirm"); Confirm:FireServer("ok")
    elseif input.KeyCode == Enum.KeyCode.P then
        print("[C] P: ReqPick"); ReqPick:FireServer("handIndex", 1)
    elseif input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.KeypadOne then
        print("[C] 1: RerollAll"); ReqRerollAll:FireServer()
    elseif input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.KeypadTwo then
        print("[C] 2: RerollHand"); ReqRerollHand:FireServer()
    elseif input.KeyCode == Enum.KeyCode.S then
        print("[C] S: ShopDone"); ShopDone:FireServer()
    end
end)
