-- ClientWireTap.client.lua
print("[ClientWireTap] ready")

local RS      = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes")

-- Remotes
local HandPush       = Remotes:WaitForChild("HandPush")
local FieldPush      = Remotes:WaitForChild("FieldPush")
local TakenPush      = Remotes:WaitForChild("TakenPush")
local ScorePush      = Remotes:WaitForChild("ScorePush")
local StatePush      = Remotes:WaitForChild("StatePush")
local ShopOpen       = Remotes:WaitForChild("ShopOpen")

local ReqStartNewRun = Remotes:WaitForChild("ReqStartNewRun")
local ReqSyncUI      = Remotes:WaitForChild("ReqSyncUI")
local Confirm        = Remotes:WaitForChild("Confirm")
local ReqPick        = Remotes:WaitForChild("ReqPick")
local ReqRerollAll   = Remotes:WaitForChild("ReqRerollAll")
local ReqRerollHand  = Remotes:WaitForChild("ReqRerollHand")
local ShopDone       = Remotes:WaitForChild("ShopDone")

--==================================================
-- 安全なログ（引数を tostring して結合）
--==================================================
local function join_args(args)
	local out = table.create(#args)
	for i, v in ipairs(args) do
		local ok, s = pcall(function() return tostring(v) end)
		out[i] = ok and s or "<unprintable>"
	end
	return table.concat(out, ", ")
end

local function log(name, ...)
	print(("[C] %s: %s"):format(name, join_args({...})))
end

--==================================================
-- 受信ログ
--==================================================
HandPush.OnClientEvent:Connect(function(...)  log("HandPush", ...) end)
FieldPush.OnClientEvent:Connect(function(...) log("FieldPush", ...) end)
TakenPush.OnClientEvent:Connect(function(...) log("TakenPush", ...) end)
ScorePush.OnClientEvent:Connect(function(...) log("ScorePush", ...) end)

StatePush.OnClientEvent:Connect(function(st)
	-- nil セーフ & hands/handsLeft 両対応
	local season  = st and (st.seasonStr or st.season) or "?"
	local hands   = st and (st.hands or st.handsLeft) or 0
	local mon     = st and (st.mon  or 0) or 0
	local bank    = st and (st.bank or 0) or 0
	local phase   = st and (st.phase or "?") or "?"
	print(("[C] State: season=%s hands=%s mon=%s bank=%s phase=%s")
		:format(tostring(season), tostring(hands), tostring(mon), tostring(bank), tostring(phase)))
end)

ShopOpen.OnClientEvent:Connect(function(...) log("ShopOpen", ...) end)

--==================================================
-- 起動直後の最小往復
--==================================================
task.delay(1, function()
	print("[C] Request NewRun...")
	ReqStartNewRun:FireServer()
	task.wait(0.2)
	ReqSyncUI:FireServer()
end)

--==================================================
-- キー操作で手早くテスト
--==================================================
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	local kc = input.KeyCode
	if kc == Enum.KeyCode.N then
		print("[C] N: NewRun"); ReqStartNewRun:FireServer()
	elseif kc == Enum.KeyCode.R then
		print("[C] R: SyncUI"); ReqSyncUI:FireServer()
	elseif kc == Enum.KeyCode.C then
		print("[C] C: Confirm"); Confirm:FireServer("ok")
	elseif kc == Enum.KeyCode.P then
		print("[C] P: ReqPick"); ReqPick:FireServer("handIndex", 1)
	elseif kc == Enum.KeyCode.One or kc == Enum.KeyCode.KeypadOne then
		print("[C] 1: RerollAll"); ReqRerollAll:FireServer()
	elseif kc == Enum.KeyCode.Two or kc == Enum.KeyCode.KeypadTwo then
		print("[C] 2: RerollHand"); ReqRerollHand:FireServer()
	elseif kc == Enum.KeyCode.S then
		print("[C] S: ShopDone"); ShopDone:FireServer()
	end
end)
