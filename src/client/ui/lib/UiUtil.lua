-- StarterPlayerScripts/UI/lib/UiUtil.lua
-- ラベル作成・子要素クリア・汎用ボタン作成の小物ユーティリティ
-- Theme が存在すれば色を拝借するが、無くても安全に動く

local RS = game:GetService("ReplicatedStorage")

-- 任意 Theme（あれば使う）
local Theme: any = nil
do
	local cfg = RS:FindFirstChild("Config")
	if cfg and cfg:FindFirstChild("Theme") then
		local ok, t = pcall(function() return require(cfg.Theme) end)
		if ok then Theme = t end
	end
end

local C = (Theme and Theme.COLORS) or {}

local U = {}

-- ラベル生成（RunScreen の makeLabel と同じ引数順）
function U.makeLabel(parent: Instance, name: string, text: string?, size: UDim2?, pos: UDim2?, anchor: Vector2?, color: Color3?)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Parent = parent
	l.BackgroundTransparency = 1
	l.Text = text or ""
	l.TextScaled = true
	l.Size = size or UDim2.new(0,100,0,24)
	l.Position = pos or UDim2.new(0,0,0,0)
	if anchor then l.AnchorPoint = anchor end
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.TextColor3 = color or C.TextDefault or Color3.fromRGB(20,20,20)
	return l
end

-- 子GUIを全消し（ScrollingFrame/Frame などに使用）
-- exceptNames: {"KeepThis","AndThat"} のように残したい子の名前配列（任意）
function U.clear(container: Instance, exceptNames: {string}? )
	local except = {}
	if typeof(exceptNames) == "table" then
		for _,n in ipairs(exceptNames) do except[n] = true end
	end
	for _,child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") and not except[child.Name] then
			child:Destroy()
		end
	end
end

-- 汎用テキストボタン（角丸付き）
-- size/pos はそのまま渡す（RunScreen 側のレイアウトに合わせる）
function U.makeTextBtn(parent: Instance, text: string, size: UDim2?, pos: UDim2?, bgColor: Color3?)
	local b = Instance.new("TextButton")
	b.Parent = parent
	b.Text = text
	b.TextScaled = true
	b.AutoButtonColor = true
	b.Size = size or UDim2.new(0,120,0,36)
	b.Position = pos or UDim2.new(0,0,0,0)
	b.BackgroundColor3 = bgColor or C.ButtonBg or Color3.fromRGB(255,255,255)
	b.BorderSizePixel = 1
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = b
	return b
end

return U
