-- StarterPlayerScripts/UI/components/renderers/HandRenderer.lua
-- 手札を描画。selectedIndex のハイライトは内部で管理（縁取りは使わず影だけで強調）
-- v0.9.7-P1-5: DeckViewAdapter 一括VM化 / フッタ＆画像決定は CardNode に委譲

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

local Shared      = ReplicatedStorage:WaitForChild("SharedModules")
local DeckViewAdapter = require(Shared:WaitForChild("Deck"):WaitForChild("DeckViewAdapter"))

local components = script.Parent.Parent
local CardNode   = require(components:WaitForChild("CardNode"))

local M = {}

--========================
-- 選択ハイライト（縁取りは使わない）
--========================
local SHADOW_ON_ALPHA  = (Theme and Theme.HandShadowOnT  ~= nil) and Theme.HandShadowOnT  or 0.45  -- 0=不透明（濃い影）
local SHADOW_OFF_ALPHA = (Theme and Theme.HandShadowOffT ~= nil) and Theme.HandShadowOffT or 0.70

local function highlight(container: Instance, selectedIndex: number?)
	for _,node in ipairs(container:GetChildren()) do
		if node:IsA("ImageButton") or node:IsA("TextButton") then
			local myIdx = node:GetAttribute("index")
			local on = (selectedIndex ~= nil and myIdx == selectedIndex)

			-- 縁取りは一切使わない（UIStrokeを触らない）

			-- 影でハイライト（CardNode 側の Shadow:ImageLabel を利用）
			local shadow = node:FindFirstChild("Shadow")
			if shadow and shadow:IsA("ImageLabel") then
				shadow.ImageTransparency = on and SHADOW_ON_ALPHA or SHADOW_OFF_ALPHA
			end

			-- TextButtonの枠は常に消す
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

	-- ---- ここから：DeckViewAdapter で一括VM化 ----
	local vms = DeckViewAdapter.toVMs(hand or {})
	local count = #vms

	-- 手札枚数に応じて横幅スケールを自動算出
	local function calcWScale(n: number): number
		if n <= 0 then return 0.12 end
		local raw = (1 - gapScale * (n + 1)) / n
		if raw < 0.09 then raw = 0.09 end
		if raw > 0.16 then raw = 0.16 end
		return raw
	end
	local W_SCALE = useScale and calcWScale(count) or nil
	local H_SCALE = 0.90

	-- カードを生成して並べる
	for i, vm in ipairs(vms) do
		local node
		if useScale then
			node = CardNode.create(container, vm.code, nil, nil, {
				month = vm.month, kind = vm.kind, name = vm.name,
			})
			node.Size = UDim2.fromScale(W_SCALE, H_SCALE)
		else
			node = CardNode.create(container, vm.code, w, h, {
				month = vm.month, kind = vm.kind, name = vm.name,
			})
		end

		-- index 属性（選択ハイライト用）
		node:SetAttribute("index", i)

		-- ▼ フッタ（ローカライズ＆配色は CardNode 側で実施）
		-- info を省略すれば、CardNode 側が Attributes/VM 由来で自動表示
		CardNode.addBadge(node)

		-- クリック時の選択
		if typeof(opts.onSelect) == "function" then
			node.MouseButton1Click:Connect(function()
				opts.onSelect(i)
				-- 内部ハイライトも即時更新（影だけで表現）
				highlight(container, i)
			end)
		end
	end

	-- 初期ハイライト
	highlight(container, opts.selectedIndex)
end

return M
