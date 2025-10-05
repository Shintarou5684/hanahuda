-- StarterPlayerScripts/UI/highlight/MatchHighlighter.lua
-- v1.3  外枠のみ（塗りなし）で“くっきり”ハイライト
-- 依存：ReplicatedStorage/Config/Theme.lua（CARD_HL_* を参照）

local RS = game:GetService("ReplicatedStorage")
local Theme = require(RS:WaitForChild("Config"):WaitForChild("Theme"))

local M = {}

-- 監視対象（RunScreen から渡してもらう）
local handArea = nil
local fieldTop = nil
local fieldBottom = nil

-- 内部状態
local conns = {}
local handNodes = {}
local fieldNodes = {}

local function addConn(c) if c then table.insert(conns, c) end end
local function clearConns()
	for _, c in ipairs(conns) do
		pcall(function() c:Disconnect() end)
	end
	conns = {}
end

-- ========== HLレイヤ生成（外枠のみ／塗りなし） ==========
local function ensureHL(gui, name, color3, strokeW)
	if not (gui and gui:IsA("GuiObject")) then return nil end

	local holder = gui:FindFirstChild("HL_Holder")
	if not holder then
		holder = Instance.new("Folder")
		holder.Name = "HL_Holder"
		holder.Archivable = false
		holder.Parent = gui
	end

	local layer = holder:FindFirstChild(name)
	if not layer then
		-- 透明な全面フレーム（枠線のみ表示）
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.Size = UDim2.fromScale(1, 1)
		frame.Position = UDim2.fromScale(0, 0)
		frame.BackgroundTransparency = 1 -- ★ 塗りなし
		frame.BorderSizePixel = 0
		frame.Visible = false
		frame.ZIndex = (gui.ZIndex or 1) + 50 -- 既存UIの上に
		frame.Parent = holder

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = frame

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = strokeW
		stroke.Color = color3
		stroke.Transparency = 0 -- ★ はっきり見せる
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Parent = frame

		layer = frame
	else
		-- 既存があれば色/太さだけ最新化
		local stroke = layer:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = color3
			stroke.Thickness = strokeW
			stroke.Transparency = 0
		end
		if layer:IsA("Frame") then
			layer.BackgroundTransparency = 1
		end
	end
	return layer
end

local function showHL(node, name, show)
	if not node then return end
	local color = Theme.CARD_HL_SELF or Color3.fromRGB(40, 120, 90) -- 統一グリーン
	local strokeW = (Theme.CARD_HL_STROKE_W and tonumber(Theme.CARD_HL_STROKE_W)) or 4
	local layer = ensureHL(node, name, color, strokeW)
	if layer then
		layer.Visible = show and true or false
	end
end

local function clearAllHL()
	for _, n in ipairs(handNodes) do
		showHL(n, "HL_SELF", false)
		showHL(n, "HL_MATCH", false)
	end
	for _, n in ipairs(fieldNodes) do
		showHL(n, "HL_MATCH", false)
	end
end

-- ========== 月取得（Attributes優先、フォールバック冗長） ==========
local function monthOf(node)
	if not node then return nil end
	local m = node:GetAttribute("month")
	if m ~= nil then
		return tonumber(m)
	end
	local ok, val = pcall(function()
		if node:FindFirstChild("meta") and node.meta:FindFirstChild("month") then
			return tonumber(node.meta.month.Value)
		end
		if node:FindFirstChild("data") and node.data:FindFirstChild("month") then
			return tonumber(node.data.month.Value)
		end
		return nil
	end)
	return ok and val or nil
end

-- ========== ハイライト本体 ==========
local function highlightFromHandNode(handNode)
	local m = monthOf(handNode)
	if not m then return end
	-- 自分（外枠）
	showHL(handNode, "HL_SELF", true)
	-- 同月の場札（外枠）
	for _, f in ipairs(fieldNodes) do
		showHL(f, "HL_MATCH", monthOf(f) == m)
	end
end

-- ========== 入力バインド（PC/モバイル） ==========
local function bindInputFor(node)
	if not (node and (node:IsA("ImageButton") or node:IsA("TextButton"))) then return end

	addConn(node.MouseEnter:Connect(function()
		clearAllHL()
		highlightFromHandNode(node)
	end))
	addConn(node.MouseLeave:Connect(function()
		clearAllHL()
	end))
	addConn(node.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			clearAllHL()
			highlightFromHandNode(node)
		end
	end))
	addConn(node.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			clearAllHL()
		end
	end))
end

-- ========== 再収集 ==========
local function recollect()
	handNodes, fieldNodes = {}, {}

	if handArea then
		for _, ch in ipairs(handArea:GetChildren()) do
			if ch:IsA("ImageButton") or ch:IsA("TextButton") then
				table.insert(handNodes, ch)
				bindInputFor(ch)
			end
		end
	end
	local function addField(row)
		if not row then return end
		for _, ch in ipairs(row:GetChildren()) do
			if ch:IsA("ImageButton") or ch:IsA("TextButton") then
				table.insert(fieldNodes, ch)
			end
		end
	end
	addField(fieldTop)
	addField(fieldBottom)
end

local function watchContainer(inst)
	if not inst then return end
	addConn(inst.ChildAdded:Connect(function()
		task.defer(recollect)
	end))
	addConn(inst.ChildRemoved:Connect(function()
		task.defer(recollect)
	end))
end

-- ========== 公開API ==========
function M.init(handArea_, fieldTop_, fieldBottom_)
	M.shutdown()

	handArea, fieldTop, fieldBottom = handArea_, fieldTop_, fieldBottom_
	watchContainer(handArea)
	watchContainer(fieldTop)
	watchContainer(fieldBottom)
	recollect()
end

function M.shutdown()
	clearAllHL()
	clearConns()
	handNodes, fieldNodes = {}, {}
	handArea, fieldTop, fieldBottom = nil, nil, nil
end

return M
