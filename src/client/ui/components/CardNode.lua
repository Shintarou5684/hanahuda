-- StarterPlayerScripts/UI/components/CardNode.lua
-- カード画像ボタン（画像・角丸・枠・軽い拡大アニメ）＋任意のサイド情報／下部バッジ
-- 依存: ReplicatedStorage/SharedModules/CardImageMap.lua
-- 任意依存: ReplicatedStorage/Config/Theme.lua（存在すれば色などを拝借）

local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local CardImageMap = require(RS:WaitForChild("SharedModules"):WaitForChild("CardImageMap"))

-- Theme（任意）。存在しない環境でも動くように安全に参照。
-- ★ ここを「: any」に修正（以前は :: でパースエラー）
local Theme: any = nil
do
	local ok, cfg = pcall(function() return RS:FindFirstChild("Config") end)
	if ok and cfg and cfg:FindFirstChild("Theme") then
		local ok2, t = pcall(function() return require(cfg.Theme) end)
		if ok2 then Theme = t end
	end
end

local M = {}

export type Info = {
	month: number?,  -- 1..12
	kind: string?,   -- "bright" | "seed" | "ribbon" | ...（任意）
	name: string?,   -- 札の日本語名など（任意）
}

-- フォールバック色
local function kindColorFallback(kind: string?)
	if kind == "bright" then return Color3.fromRGB(255,230,140)
	elseif kind == "seed" then return Color3.fromRGB(200,240,255)
	elseif kind == "ribbon" then return Color3.fromRGB(255,200,220)
	else return Color3.fromRGB(235,235,235) end
end

-- 役色は Theme 優先
local function colorForKind(kind: string?)
	if Theme and Theme.colorForKind then
		local ok, c = pcall(function() return Theme.colorForKind(kind) end)
		if ok and typeof(c) == "Color3" then return c end
	end
	return kindColorFallback(kind)
end

-- 安全な Theme 参照ヘルパ
local function themeColor(path: string, fallback: Color3)
	local c = fallback
	if Theme and Theme.COLORS and Theme.COLORS[path] then
		local v = Theme.COLORS[path]
		if typeof(v) == "Color3" then c = v end
	end
	return c
end

local function themeImage(path: string, fallback: string)
	local id = fallback
	if Theme and Theme.IMAGES and Theme.IMAGES[path] then
		local v = Theme.IMAGES[path]
		if typeof(v) == "string" and #v > 0 then id = v end
	end
	return id
end

-- カード画像ボタン + （任意）右側の補助ラベル
function M.create(parent: Instance, code: string, w: number?, h: number?, info: Info?, showInfoRight: boolean?)
	w, h = w or 180, h or 120

	local btn = Instance.new("ImageButton")
	btn.Parent = parent
	btn.Name = "Card_" .. tostring(code or "????")
	btn.BackgroundTransparency = 1
	btn.Size = UDim2.fromOffset(w, h)
	btn.ScaleType = Enum.ScaleType.Fit
	btn.AutoButtonColor = true
	btn.BorderSizePixel = 0
	btn.ZIndex = (parent:IsA("GuiObject") and parent.ZIndex or 1) + 1

	-- 角丸＋枠
	do
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Color = themeColor("CardStroke", Color3.fromRGB(0,0,0))
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = btn
	end

	-- 影（Theme.IMAGES.dropShadow があれば使用）
	do
		local shadow = Instance.new("ImageLabel")
		shadow.Name = "Shadow"
		shadow.Parent = btn
		shadow.BackgroundTransparency = 1
		shadow.Image = themeImage("dropShadow", "rbxassetid://1316045217")
		shadow.ImageTransparency = 0.7
		shadow.ScaleType = Enum.ScaleType.Slice
		shadow.SliceCenter = Rect.new(10,10,118,118)
		shadow.Size = UDim2.fromScale(1,1)
		shadow.ZIndex = btn.ZIndex - 1
	end

	-- 画像本体
	do
		local ok, imgId = pcall(function() return CardImageMap.get(code) end)
		btn.Image = (ok and imgId) or ""
	end

	-- 比率固定
	do
		local ar = Instance.new("UIAspectRatioConstraint")
		ar.AspectRatio = w / h
		ar.Parent = btn
	end

	-- クリック感（軽い拡大アニメ）
	local function tweenSize(sz) TweenService:Create(btn, TweenInfo.new(0.06), { Size = sz }):Play() end
	btn.MouseButton1Down:Connect(function() tweenSize(UDim2.fromOffset(w*1.04, h*1.04)) end)
	btn.MouseButton1Up:Connect(function() tweenSize(UDim2.fromOffset(w, h)) end)
	btn.MouseLeave:Connect(function() btn.Size = UDim2.fromOffset(w, h) end)

	-- 右側の補助ラベル（「1月 短冊」など）※必要なときだけ
	if showInfoRight then
		local lab = Instance.new("TextLabel")
		lab.Name = "SideInfo"
		lab.Parent = btn
		lab.BackgroundTransparency = 1
		lab.TextScaled = true
		lab.Size = UDim2.new(0, 72, 0, 22)
		lab.Position = UDim2.new(1, 6, 0, 0)
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.TextYAlignment = Enum.TextYAlignment.Center
		local m = tonumber(info and info.month) or 0
		local role = tostring(info and info.kind or "")
		local name = tostring(info and info.name or "")
		lab.Text = string.format("%d月 %s", m, (name ~= "" and name) or role)
		lab.TextColor3 = colorForKind(info and info.kind)
		lab.ZIndex = btn.ZIndex + 1
	end

	return btn
end

-- 下部のバッジ（「1月 / 短冊」など）をカードに追加
function M.addBadge(cardButton: Instance, info: Info?)
	if not cardButton or not cardButton:IsA("GuiObject") then return end

	-- 既存を掃除
	local old = cardButton:FindFirstChild("Badge")
	if old then old:Destroy() end

	local m    = tonumber(info and info.month) or 0
	local kind = tostring(info and info.kind or "")
	local name = tostring(info and info.name or "")

	-- 台
	local holder = Instance.new("Frame")
	holder.Name = "Badge"
	holder.Parent = cardButton
	holder.AnchorPoint = Vector2.new(0, 1)
	holder.Position = UDim2.new(0, 0, 1, -2)       -- 下に2pxマージン
	holder.Size     = UDim2.new(1, 0, 0, 26)       -- カード幅いっぱい
	holder.BackgroundTransparency = 0.25
	holder.BorderSizePixel = 0
	holder.ZIndex = cardButton.ZIndex + 1
	holder.BackgroundColor3 = themeColor("BadgeBg", Color3.fromRGB(25,28,36))

	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = holder
	local s = Instance.new("UIStroke"); s.Thickness = 1; s.Color = themeColor("BadgeStroke", Color3.fromRGB(60,65,80)); s.Parent = holder

	-- 文言
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.Parent = holder
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1,1)
	t.TextScaled = true
	t.TextXAlignment = Enum.TextXAlignment.Center
	t.TextYAlignment = Enum.TextYAlignment.Center

	local kindJp = (kind == "ribbon" and "短冊")
		or (kind == "seed" and "たね")
		or (kind == "bright" and "光")
		or (name ~= "" and name)
		or "--"

	t.Text = string.format("%d月 / %s", m, kindJp)
	t.TextColor3 = colorForKind(kind)
	t.Font = Enum.Font.GothamMedium
	t.ZIndex = holder.ZIndex + 1
end

return M
