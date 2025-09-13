-- StarterPlayerScripts/UI/components/renderers/HandRenderer.lua
-- 手札を描画。selectedIndex のハイライトは内部で管理

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

local components = script.Parent.Parent
local CardNode   = require(components:WaitForChild("CardNode"))

local M = {}

--========================
-- 言語/フッタユーティリティ
--========================
local function _lang()
	return (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or Locale.pick()
end

local function _catEn(v)
	v = tostring(v or ""):lower()
	if v=="光" or v=="ひかり" or v=="hikari" or v=="bright" then return "Bright" end
	if v=="タネ" or v=="種" or v=="tane" or v=="seed" then return "Seed" end
	if v=="短冊" or v=="ribbon" then return "Ribbon" end
	if v=="カス" or v=="kasu" or v=="chaff" then return "Chaff" end
	return v
end

local function _catJp(v)
	v = tostring(v or ""):lower()
	if v=="bright" or v=="光" then return "光" end
	if v=="seed"   or v=="タネ" or v=="種" then return "タネ" end
	if v=="ribbon" or v=="短冊" then return "短冊" end
	if v=="chaff"  or v=="kasu" or v=="カス" then return "カス" end
	return v
end

-- JP: "11月/タネ" / EN: "11/Seed"（英語は「月」を省く）
local function makeFooterText(monthNum, cat, lang)
	local m = tonumber(monthNum)
	local mStr = m and tostring(m) or ""
	if lang == "en" then
		local catEn = _catEn(cat)
		if mStr ~= "" and catEn ~= "" then
			return string.format("%s/%s", mStr, catEn)
		elseif mStr ~= "" then
			return mStr
		else
			return catEn
		end
	else
		local catJp = _catJp(cat)
		if mStr ~= "" and catJp ~= "" then
			return string.format("%s月/%s", mStr, catJp)
		elseif mStr ~= "" then
			return (mStr .. "月")
		else
			return catJp
		end
	end
end

-- カード下部にフッタ（小バッジ）を重ねる
local function addFooter(node: Instance, text: string)
	-- 既存削除
	local old = node:FindFirstChild("Footer")
	if old then old:Destroy() end

	local footer = Instance.new("Frame")
	footer.Name = "Footer"
	footer.Parent = node
	footer.AnchorPoint = Vector2.new(0,1)
	footer.Position = UDim2.new(0, 6, 1, -6)
	footer.Size = UDim2.fromOffset(0, 22)      -- 横は自動
	footer.AutomaticSize = Enum.AutomaticSize.X
	footer.BackgroundColor3 = Color3.fromRGB(36,40,52)
	footer.BackgroundTransparency = 0.15
	footer.BorderSizePixel = 0
	footer.ZIndex = 10
	footer.ClipsDescendants = true

	local uic = Instance.new("UICorner"); uic.CornerRadius = UDim.new(0, 6); uic.Parent = footer
	local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(70,75,90); stroke.Thickness = 0; stroke.Parent = footer

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, 6)
	pad.PaddingRight  = UDim.new(0, 6)
	pad.PaddingTop    = UDim.new(0, 2)
	pad.PaddingBottom = UDim.new(0, 2)
	pad.Parent = footer

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Parent = footer
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = tostring(text or "")
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextScaled = false
	label.TextColor3 = Color3.fromRGB(240,240,240)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 11
end

--========================
-- 選択ハイライト（枠は黄色にせず、未選択=0px/選択=3px＋影を濃く）
--========================
local HIGHLIGHT_THICK  = (Theme and Theme.HIGHLIGHT_THICKNESS) or 3
local NORMAL_THICK     = 0
local SHADOW_ON_ALPHA  = 0.45  -- 選択時の影の濃さ（0=不透明）
local SHADOW_OFF_ALPHA = 0.70  -- 未選択時

local function highlight(container: Instance, selectedIndex: number?)
	for _,node in ipairs(container:GetChildren()) do
		if node:IsA("ImageButton") or node:IsA("TextButton") then
			local myIdx = node:GetAttribute("index")
			local on = (selectedIndex ~= nil and myIdx == selectedIndex)

			-- 外枠は色を変えず、太さだけで出す（未選択は0pxで完全非表示）
			local stroke = node:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Thickness    = on and HIGHLIGHT_THICK or NORMAL_THICK
				stroke.Transparency = on and 0 or 1
				-- ※ stroke.Color は CardNode 側の既定色のまま（黄色にしない）
				stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				stroke.Color = on and Color3.fromRGB(0,255,255) or Color3.fromRGB(0,0,0)
			end

			-- 影を強めて視覚的なハイライト
			local shadow = node:FindFirstChild("Shadow")
			if shadow and shadow:IsA("ImageLabel") then
				shadow.ImageTransparency = on and SHADOW_ON_ALPHA or SHADOW_OFF_ALPHA
			end

			-- TextButtonの枠も常に消す
			if node:IsA("TextButton") then
				node.BorderSizePixel = 0
			end
		end
	end
end

-- 子を掃除
local function clear(container: Instance)
	for _,c in ipairs(container:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("ImageButton") or c:IsA("TextLabel")
			or c:IsA("Frame") or c:IsA("ImageLabel") or c:IsA("UIListLayout") or c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

--========================
-- API
--========================
-- render(container, hand, { width, height, selectedIndex, onSelect, paddingScale })
--  - width/height 未指定 → 比率レイアウト（各カードは高さ90%、横幅は手札枚数から自動算出）
--  - width/height 指定   → pxレイアウト（互換）
--  - paddingScale       → カード間の横間隔（比率）。既定 0.02（= 2%）
function M.render(container: Instance, hand: {any}?, opts: {width:number?, height:number?, selectedIndex:number?, onSelect:(number)->()? , paddingScale:number?})
	opts = opts or {}
	local useScale = (opts.width == nil and opts.height == nil)
	local w = opts.width  or 90
	local h = opts.height or 150
	local gapScale = (typeof(opts.paddingScale) == "number" and opts.paddingScale) or 0.02

	clear(container)

	-- 並べ方：横並び（比率Padding）＋左右にも同じ余白を付与
	local layout = Instance.new("UIListLayout")
	layout.Parent = container
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(gapScale, 0)

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft  = UDim.new(gapScale, 0)
	pad.PaddingRight = UDim.new(gapScale, 0)
	pad.Parent = container

	-- 手札枚数に応じて横幅スケールを自動算出
	local count = #(hand or {})
	local function calcWScale(n: number): number
		if n <= 0 then return 0.12 end
		local raw = (1 - gapScale * (n + 1)) / n
		if raw < 0.09 then raw = 0.09 end
		if raw > 0.16 then raw = 0.16 end
		return raw
	end
	local W_SCALE = useScale and calcWScale(count) or nil
	local H_SCALE = 0.90
	local langNow = _lang()

	-- カードを生成して並べる
	for i, card in ipairs(hand or {}) do
		local code = card.code or string.format("%02d%02d", card.month, card.idx)

		local node
		if useScale then
			node = CardNode.create(container, code, nil, nil, {
				month = card.month, kind = card.kind, name = card.name
			})
			node.Size = UDim2.fromScale(W_SCALE, H_SCALE)
		else
			node = CardNode.create(container, code, w, h, {
				month = card.month, kind = card.kind, name = card.name
			})
		end

		node:SetAttribute("index", i)

		-- ▼ 言語対応のフッタ（EN: "11/Seed" / JP: "11月/タネ"）
		local footerText = makeFooterText(card.month, card.kind or card.name, langNow)
		addFooter(node, footerText)

		if typeof(opts.onSelect) == "function" then
			node.MouseButton1Click:Connect(function()
				opts.onSelect(i)
				-- コールバックだけでなく、内部ハイライトも即時更新
				highlight(container, i)
			end)
		end
	end

	-- 初期ハイライト
	highlight(container, opts.selectedIndex)
end

return M
