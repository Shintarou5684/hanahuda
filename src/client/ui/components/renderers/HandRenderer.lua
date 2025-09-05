-- StarterPlayerScripts/UI/components/renderers/HandRenderer.lua
-- 手札を描画。selectedIndex のハイライトは内部で管理

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

local components = script.Parent.Parent
local CardNode   = require(components:WaitForChild("CardNode"))

local M = {}

-- 選択ハイライト（UIStroke太さ切替）
local function highlight(container: Instance, selectedIndex: number?)
	for _,node in ipairs(container:GetChildren()) do
		if node:IsA("ImageButton") or node:IsA("TextButton") then
			local myIdx = node:GetAttribute("index")
			local on = (selectedIndex ~= nil and myIdx == selectedIndex)
			local stroke = node:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Thickness = on and 4 or 1
				stroke.Color = Color3.fromRGB(255,180,0)
				stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			end
			if node:IsA("TextButton") then
				node.BorderSizePixel = on and 4 or 1
				node.BorderColor3 = Color3.fromRGB(255,180,0)
			end
		end
	end
end

-- 子を掃除
local function clear(container: Instance)
	for _,c in ipairs(container:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("ImageButton") or c:IsA("TextLabel") or c:IsA("Frame") or c:IsA("ImageLabel") or c:IsA("UIListLayout") or c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

-- API: render(container, hand, { width, height, selectedIndex, onSelect, paddingScale })
--  - width/height 未指定 → 比率レイアウト（各カードは高さ90%、横幅は手札枚数から自動算出）
--  - width/height 指定   → 従来通りのpxレイアウト（互換）
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
		-- 行幅1.0から左右と間の余白 (n+1) 個分の Padding を引いて、n で割る
		local raw = (1 - gapScale * (n + 1)) / n
		-- 見やすさの下限/上限をクランプ
		if raw < 0.09 then raw = 0.09 end
		if raw > 0.16 then raw = 0.16 end
		return raw
	end
	local W_SCALE = useScale and calcWScale(count) or nil
	local H_SCALE = 0.90

	-- カードを生成して並べる
	for i, card in ipairs(hand or {}) do
		local code = card.code or string.format("%02d%02d", card.month, card.idx)

		local node
		if useScale then
			-- CardNode 側は高さ0.90・花札比固定。ここで横幅だけ最適値を適用
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
		CardNode.addBadge(node, { month = card.month, kind = card.kind, name = card.name })

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
