-- src/client/ui/components/TalismanBoard.lua
-- v0.1 Step0: 表示専用。クリック等の操作は未実装
local RS = game:GetService("ReplicatedStorage")
local Config = RS:FindFirstChild("Config") or RS:FindFirstChild("config") or RS
local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

local M = {}
M.__index = M

local function makeSlot(parent, index)
	local f = Instance.new("Frame")
	f.Name = "Slot"..index
	f.Size = UDim2.new(0, 80, 0, 80)
	f.BackgroundColor3 = (Theme.COLORS and (Theme.COLORS.bg2 or Color3.fromRGB(30,30,30))) or Color3.fromRGB(30,30,30)
	f.BorderSizePixel = 1
	f.Parent = parent

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = f

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.TextColor3 = Color3.fromRGB(220,220,220)
	label.Text = ""  -- 後で setData で決定
	label.Parent = f

	return f, label
end

-- ✅ Luau 型修正: opts は { title: string? }? の形にする
function M.new(parentGui: Instance, opts: { title: string? }?)
	local self = setmetatable({}, M)

	local root = Instance.new("Frame")
	root.Name = "TalismanBoard"
	root.Size = UDim2.new(0, 280, 0, 200)  -- 3x2 グリッド想定
	root.BackgroundTransparency = 1
	root.Parent = parentGui
	self.root = root

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 24)
	title.BackgroundTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.Text = (opts and opts.title) or "Talisman"
	title.TextColor3 = Color3.fromRGB(235,235,235)
	title.Parent = root

	local gridHolder = Instance.new("Frame")
	gridHolder.Name = "Grid"
	gridHolder.Position = UDim2.new(0, 0, 0, 28)
	gridHolder.Size = UDim2.new(1, 0, 1, -28)
	gridHolder.BackgroundTransparency = 1
	gridHolder.Parent = root

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0, 88, 0, 88)
	layout.CellPadding = UDim2.new(0, 8, 0, 8)
	layout.FillDirectionMaxCells = 3 -- 3列
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gridHolder

	self.slots = {}
	self.labels = {}
	for i=1,6 do
		local f, lbl = makeSlot(gridHolder, i)
		self.slots[i] = f
		self.labels[i] = lbl
	end

	self._lang = (typeof(Locale.get) == "function" and Locale.get()) or "ja"
	self:setLang(self._lang)
	return self
end

function M:setLang(lang: string?)
	self._lang = (lang == "en") and "en" or "ja"
	if self.root and self.root:FindFirstChild("Title") then
		self.root.Title.Text = (self._lang == "ja") and "護符ボード" or "Talisman Board"
	end
end

-- talisman: { maxSlots=6, unlocked=2, slots={...} }
function M:setData(talisman: any)
	self._data = talisman or { maxSlots = 6, unlocked = 2, slots = {nil,nil,nil,nil,nil,nil} }
	for i=1,6 do
		local slot = self.slots[i]
		local lbl  = self.labels[i]
		local withinUnlock = i <= (self._data.unlocked or 0)
		local id = self._data.slots and self._data.slots[i] or nil

		if not withinUnlock then
			slot.BackgroundColor3 = Color3.fromRGB(35,35,35)
			lbl.Text = "🔒"
		elseif id == nil then
			slot.BackgroundColor3 = Color3.fromRGB(50,50,50)
			lbl.Text = (self._lang == "ja") and "空" or "Empty"
		else
			slot.BackgroundColor3 = Color3.fromRGB(70,70,90)
			lbl.Text = tostring(id) -- Step0はID文字列表示だけ
		end
	end
end

function M:getInstance() return self.root end
function M:destroy() if self.root then self.root:Destroy() end end

return M
