-- src/client/ui/components/TalismanBoard.lua
-- v1.1 RowResponsive: 横一列・比率可変・正方形スロット
--  - props: new(parentGui, { title?, widthScale?, padScale? })
--  - API : setLang(lang), setData(talisman), getInstance(), destroy()

local RS = game:GetService("ReplicatedStorage")
local Config = RS:FindFirstChild("Config") or RS

local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

local M = {}
M.__index = M

--========================================
-- helpers
--========================================
local function colorOr(defaultC3, path1, path2, fallback)
	local ok, c = pcall(function()
		return Theme.COLORS and Theme.COLORS[path1] and Theme.COLORS[path1][path2]
	end)
	if ok and typeof(c) == "Color3" then return c end
	if typeof(fallback) == "Color3" then return fallback end
	return defaultC3
end

local function makeSlot(parent, index)
	local f = Instance.new("Frame")
	f.Name = ("Slot%d"):format(index)
	-- サイズは Grid の UIGridLayout＋AspectRatio が決めるため初期値はダミー
	f.Size = UDim2.fromScale(0, 1)
	f.BackgroundColor3 = colorOr(Color3.fromRGB(30,30,30), "surface", "base", Color3.fromRGB(30,30,30))
	f.BorderSizePixel = 1
	f.Parent = parent

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = f

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(80,80,80)
	stroke.Enabled = true
	stroke.Parent = f

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.TextColor3 = Color3.fromRGB(220,220,220)
	label.Text = ""
	label.Parent = f

	return f, label, stroke
end

local function defaultData()
	return { maxSlots = 6, unlocked = 2, slots = { nil, nil, nil, nil, nil, nil } }
end

--========================================
-- class
--========================================
-- opts:
--   title?: string
--   widthScale?: number  -- 親幅に対する割合（0〜1、既定=0.6）
--   padScale?: number    -- セル間の横パディング割合（既定=0.01 = 親幅の1%）
function M.new(parentGui: Instance, opts: { title: string?, widthScale: number?, padScale: number? }?)
	local self = setmetatable({}, M)

	opts = opts or {}
	local widthScale = tonumber(opts.widthScale or 0.6) or 0.6
	local padScale   = math.clamp(tonumber(opts.padScale or 0.01) or 0.01, 0, 0.05) -- 過大な隙間を抑制
	-- 6スロ・5箇所の隙間 → 各セルの横幅スケール
	local cellScale  = (1 - 5 * padScale) / 6
	-- 正方形化のため、Grid のアスペクト比 = 1 / cellScale （幅 / 高さ）
	local gridAspect = 1 / cellScale

	local root = Instance.new("Frame")
	root.Name = "TalismanBoard"
	root.BackgroundTransparency = 1
	-- 幅は比率、縦は自動（タイトル高さ + グリッド高さ）
	root.Size = UDim2.new(widthScale, 0, 0, 0)
	root.AutomaticSize = Enum.AutomaticSize.Y
	root.Parent = parentGui
	self.root = root

	-- 縦積み（タイトル→グリッド）
	local vlayout = Instance.new("UIListLayout")
	vlayout.FillDirection = Enum.FillDirection.Vertical
	vlayout.Padding = UDim.new(0, 6)
	vlayout.SortOrder = Enum.SortOrder.LayoutOrder
	vlayout.Parent = root

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 24)
	title.BackgroundTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.Text = (opts and opts.title) or "Talisman"
	title.TextColor3 = Color3.fromRGB(235,235,235)
	title.LayoutOrder = 1
	title.Parent = root

	local gridHolder = Instance.new("Frame")
	gridHolder.Name = "Grid"
	gridHolder.BackgroundTransparency = 1
	-- 横幅100%、高さはアスペクト比で決まる（下でConstraintを付与）
	gridHolder.Size = UDim2.new(1, 0, 0, 0)
	gridHolder.AutomaticSize = Enum.AutomaticSize.Y
	gridHolder.LayoutOrder = 2
	gridHolder.Parent = root

	-- 正方形を保つための「幅：高さ」制約（高さ = 幅 / gridAspect）
	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = gridAspect
	ar.DominantAxis = Enum.DominantAxis.Width
	ar.Parent = gridHolder

	-- 横一列のグリッド
	local layout = Instance.new("UIGridLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.FillDirectionMaxCells = 6
	layout.StartCorner = Enum.StartCorner.TopLeft
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	-- 横は cellScale、縦は100%（Gridの高さ）→ 正方形になる
	layout.CellSize = UDim2.new(cellScale, 0, 1, 0)
	layout.CellPadding = UDim2.new(padScale, 0, 0, 0)
	layout.Parent = gridHolder

	self.slots   = {}
	self.labels  = {}
	self.strokes = {}

	for i = 1, 6 do
		local f, lbl, stroke = makeSlot(gridHolder, i)
		self.slots[i]   = f
		self.labels[i]  = lbl
		self.strokes[i] = stroke
	end

	self._lang = (typeof(Locale.get) == "function" and Locale.get()) or "ja"
	self:setLang(self._lang)

	self._data = defaultData()
	self:setData(nil)

	return self
end

--========================================
-- public
--========================================
function M:setLang(lang: string?)
	self._lang = (lang == "en") and "en" or "ja"
	if self.root and self.root:FindFirstChild("Title") then
		self.root.Title.Text = (self._lang == "ja") and "護符ボード" or "Talisman Board"
	end
end

-- talisman: { maxSlots=6, unlocked=2, slots={...} }
function M:setData(talisman: any)
	self._data = talisman or defaultData()

	for i = 1, 6 do
		local slot   = self.slots[i]
		local lbl    = self.labels[i]
		local stroke = self.strokes[i]

		local withinUnlock = i <= (tonumber(self._data.unlocked or 0) or 0)
		local id = self._data.slots and self._data.slots[i] or nil

		if not withinUnlock then
			-- 未開放
			slot.BackgroundColor3 = Color3.fromRGB(35,35,35)
			lbl.Text = "🔒"
			stroke.Color = Color3.fromRGB(80,80,80)
			stroke.Thickness = 1
		elseif id == nil then
			-- 空
			slot.BackgroundColor3 = Color3.fromRGB(50,50,50)
			lbl.Text = (self._lang == "ja") and "空" or "Empty"
			stroke.Color = Color3.fromRGB(80,80,80)
			stroke.Thickness = 1
		else
			-- 埋まっている
			slot.BackgroundColor3 = Color3.fromRGB(70,70,90)
			lbl.Text = tostring(id)
			stroke.Color = Color3.fromRGB(120,120,160)
			stroke.Thickness = 1
		end
	end
end

function M:getInstance()
	return self.root
end

function M:destroy()
	if self.root then self.root:Destroy() end
end

return M
