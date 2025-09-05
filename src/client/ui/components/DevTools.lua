-- StarterPlayerScripts/UI/components/DevTools.lua
-- Studio 専用の開発用チートボタン（+役 / +両）を右下に表示するコンポーネント

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

local DevTools = {}

export type Options = {
	grantRyoAmount: number?, -- +両 で付与する金額（既定: 1000）
	offsetX: number?,         -- 右端からのマージン（px, 既定: 10）
	offsetY: number?,         -- 下端からのマージン（px, 既定: 10）
	width: number?,           -- 全体幅（px, 既定: 160）
	height: number?,          -- 行高さ（px, 既定: 32）
}

function DevTools.create(parent: Instance, deps: any, opts: Options?)
	opts = opts or {}
	local grantRyoAmount = opts.grantRyoAmount or 1000
	local PADX = opts.offsetX or 10
	local PADY = opts.offsetY or 10
	local W    = opts.width   or 160
	local H    = opts.height  or 32

	local C = (Theme and Theme.COLORS) or {}
	local BTN_BG   = C.DevBtnBg   or Color3.fromRGB(35,130,90)
	local BTN_TEXT = C.DevBtnText or Color3.fromRGB(255,255,255)

	local row = Instance.new("Frame")
	row.Name = "DevTools"
	row.Parent = parent
	row.AnchorPoint = Vector2.new(1, 1)
	row.Position = UDim2.new(1, -PADX, 1, -PADY)
	row.Size = UDim2.new(0, W, 0, H)
	row.BackgroundTransparency = 1
	row.ZIndex = 999

	local layout = Instance.new("UIListLayout")
	layout.Parent = row
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Padding = UDim.new(0, 8)

	local function makeBtn(txt: string, onClick: ()->())
		local b = Instance.new("TextButton")
		b.Name = "Btn"
		b.Parent = row
		b.Size = UDim2.new(0, math.floor((W-8)/2), 1, 0)
		b.BackgroundColor3 = BTN_BG
		b.TextColor3 = BTN_TEXT
		b.Text = txt
		b.Font = Enum.Font.GothamBold
		b.TextScaled = true
		b.AutoButtonColor = true
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = b
		b.Activated:Connect(function()
			if typeof(onClick) == "function" then onClick() end
		end)
		return b
	end

	-- +役
	if deps and deps.DevGrantRole then
		makeBtn("+役", function()
			deps.DevGrantRole:FireServer()
		end)
	end

	-- +両
	if deps and deps.DevGrantRyo then
		makeBtn("+両", function()
			deps.DevGrantRyo:FireServer(grantRyoAmount)
		end)
	end

	return row
end

return DevTools
