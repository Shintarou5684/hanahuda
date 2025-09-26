-- StarterPlayerScripts/UI/DevLogViewer.client.lua
-- In-game log viewer you can copy from (F10 to toggle)

local Players      = game:GetService("Players")
local LogService   = game:GetService("LogService")
local CAS          = game:GetService("ContextActionService")
local RunService   = game:GetService("RunService")

local MAX_LINES = 5000

-- buffer
local lines = {}
local function push(msgType, message)
	local tag = (typeof(msgType) == "EnumItem") and msgType.Name or tostring(msgType)
	local s = string.format("[%s] %s", tag, tostring(message))
	lines[#lines+1] = s
	if #lines > MAX_LINES then
		table.remove(lines, 1)
	end
end

-- seed with existing history (if available)
pcall(function()
	for _, e in ipairs(LogService:GetLogHistory()) do
		push(e.messageType, e.message)
	end
end)

-- live feed
LogService.MessageOut:Connect(function(message, msgType)
	push(msgType, message)
end)

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "DevLogViewer"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999
gui.Enabled = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local modal = Instance.new("Frame")
modal.Name = "Panel"
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.Position = UDim2.fromScale(0.5, 0.5)
modal.Size = UDim2.fromScale(0.9, 0.8)
modal.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
modal.BorderSizePixel = 0
modal.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = modal

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Color = Color3.fromRGB(70, 75, 90)
stroke.Parent = modal

local header = Instance.new("TextLabel")
header.BackgroundTransparency = 1
header.TextXAlignment = Enum.TextXAlignment.Left
header.Font = Enum.Font.GothamBold
header.Text = "Developer Log (F10 to close) — Ctrl+A → Ctrl+C to copy"
header.TextSize = 16
header.TextColor3 = Color3.fromRGB(240, 240, 240)
header.Size = UDim2.new(1, -16, 0, 32)
header.Position = UDim2.new(0, 8, 0, 4)
header.Parent = modal

local box = Instance.new("TextBox")
box.Name = "LogBox"
box.MultiLine = true
box.ClearTextOnFocus = false
box.TextEditable = true
box.RichText = false
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.Font = Enum.Font.Code
box.TextSize = 14
box.TextColor3 = Color3.fromRGB(225, 225, 225)
box.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
box.Size = UDim2.new(1, -16, 1, -72)
box.Position = UDim2.new(0, 8, 0, 36)
box.TextWrapped = false
box.Parent = modal

local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0, 120, 0, 28)
refreshBtn.Position = UDim2.new(0, 8, 1, -32)
refreshBtn.Text = "Refresh"
refreshBtn.Font = Enum.Font.Gotham
refreshBtn.TextSize = 14
refreshBtn.TextColor3 = Color3.fromRGB(20, 22, 28)
refreshBtn.BackgroundColor3 = Color3.fromRGB(180, 190, 210)
refreshBtn.Parent = modal
Instance.new("UICorner", refreshBtn)

local selectAllBtn = Instance.new("TextButton")
selectAllBtn.Size = UDim2.new(0, 120, 0, 28)
selectAllBtn.Position = UDim2.new(0, 136, 1, -32)
selectAllBtn.Text = "Select All"
selectAllBtn.Font = Enum.Font.Gotham
selectAllBtn.TextSize = 14
selectAllBtn.TextColor3 = Color3.fromRGB(20, 22, 28)
selectAllBtn.BackgroundColor3 = Color3.fromRGB(180, 190, 210)
selectAllBtn.Parent = modal
Instance.new("UICorner", selectAllBtn)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 120, 0, 28)
closeBtn.Position = UDim2.new(1, -128, 1, -32)
closeBtn.Text = "Close"
closeBtn.Font = Enum.Font.Gotham
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
closeBtn.BackgroundColor3 = Color3.fromRGB(90, 95, 110)
closeBtn.Parent = modal
Instance.new("UICorner", closeBtn)

local function fill()
	box.Text = table.concat(lines, "\n")
	-- scroll to bottom
	RunService.Heartbeat:Wait()
	box.CursorPosition = #box.Text + 1
	box.SelectionStart = #box.Text + 1
end

local function toggle()
	gui.Enabled = not gui.Enabled
	if gui.Enabled then fill() end
end

refreshBtn.Activated:Connect(fill)
closeBtn.Activated:Connect(function() gui.Enabled = false end)
selectAllBtn.Activated:Connect(function()
	local txt = box.Text or ""
	box:CaptureFocus()
	task.wait()
	box.SelectionStart = 1
	box.CursorPosition = #txt + 1
end)

-- F10 toggle
CAS:BindAction("DevLogViewerToggle", function(_, state)
	if state == Enum.UserInputState.Begin then
		toggle()
	end
end, false, Enum.KeyCode.F10)
