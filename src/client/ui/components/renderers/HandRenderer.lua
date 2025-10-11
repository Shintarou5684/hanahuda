-- StarterPlayerScripts/UI/components/renderers/HandRenderer.lua
-- 手札を描画。selectedIndex のハイライトは内部で管理（縁取りは使わず影＋持ち上げで強調）
-- v0.9.7-P1-6: Lift/Scale on selected + Slot/Root wrap（UIListLayout干渉回避）

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

local Shared          = ReplicatedStorage:WaitForChild("SharedModules")
local DeckViewAdapter = require(Shared:WaitForChild("Deck"):WaitForChild("DeckViewAdapter"))

local components = script.Parent.Parent
local CardNode   = require(components:WaitForChild("CardNode"))

local M = {}

--========================
-- 選択ハイライト（縁取りは使わない）
--========================
local SHADOW_ON_ALPHA  = (Theme and Theme.HandShadowOnT  ~= nil) and Theme.HandShadowOnT  or 0.45 -- 0=不透明
local SHADOW_OFF_ALPHA = (Theme and Theme.HandShadowOffT ~= nil) and Theme.HandShadowOffT or 0.70

-- 視覚効果（持ち上げ＆拡大）パラメータ
local LIFT_Y         = -10                                  -- 持ち上げ量(px)
local SCALE_SELECTED = 1.05
local SCALE_NORMAL   = 1.00
local TWEEN_T        = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--========================
-- 内部：Slot/Root を用意
--========================
local function createSlot(parent: Instance, size: UDim2)
	local slot = Instance.new("Frame")
	slot.Name = "Slot"
	slot.BackgroundTransparency = 1
	slot.Size = size
	slot.Parent = parent

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.AnchorPoint = Vector2.new(0, 0)
	root.Position    = UDim2.new(0, 0, 0, 0)
	root.Size        = UDim2.fromScale(1, 1)
	root.ZIndex      = 1
	root.Parent      = slot

	return slot, root
end

--========================
-- 内部：持ち上げ＆拡大適用（Rootに対して）
--========================
local function ensureScale(root: Instance)
	local scale = root:FindFirstChild("SelScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "SelScale"
		scale.Scale = 1
		scale.Parent = root
	end
	return scale
end

local function applyLiftAndScale(root: Instance, selected: boolean)
	if not (root and root:IsA("GuiObject")) then return end
	local scale = ensureScale(root)

	local targetPos   = selected and UDim2.new(0, 0, 0, LIFT_Y) or UDim2.new(0, 0, 0, 0)
	local targetScale = selected and SCALE_SELECTED or SCALE_NORMAL

	-- ZIndexを前面へ（選択中は前に）
	root.ZIndex = selected and 50 or 1

	TweenService:Create(root,  TWEEN_T, { Position = targetPos }):Play()
	TweenService:Create(scale, TWEEN_T, { Scale    = targetScale }):Play()
end

--========================
-- 内部：シャドウ濃度（CardNode の Shadow を使う）
--========================
local function setShadow(btnOrImgBtn: Instance, selected: boolean)
	local shadow = btnOrImgBtn and btnOrImgBtn:FindFirstChild("Shadow")
	if shadow and shadow:IsA("ImageLabel") then
		local target = selected and SHADOW_ON_ALPHA or SHADOW_OFF_ALPHA
		-- 影はスッと変わる方が分かりやすいのでTween
		TweenService:Create(shadow, TWEEN_T, { ImageTransparency = target }):Play()
	end
	if btnOrImgBtn and btnOrImgBtn:IsA("TextButton") then
		btnOrImgBtn.BorderSizePixel = 0
	end
end

--========================
-- 内部：選択ハイライト一括適用
--========================
local function highlight(container: Instance, selectedIndex: number?)
	for _, slot in ipairs(container:GetChildren()) do
		if slot:IsA("Frame") and slot.Name == "Slot" then
			local root = slot:FindFirstChild("Root")
			if root and root:IsA("GuiObject") then
				-- ルート直下のカードボタン（ImageButton/TextButton）を探す
				local cardBtn: Instance? = nil
				for _, ch in ipairs(root:GetChildren()) do
					if ch:IsA("ImageButton") or ch:IsA("TextButton") then
						cardBtn = ch
						break
					end
				end
				if cardBtn then
					local myIdx = cardBtn:GetAttribute("index")
					local on = (selectedIndex ~= nil and myIdx == selectedIndex)
					applyLiftAndScale(root, on)
					setShadow(cardBtn, on)
				end
			end
		end
	end
end

--========================
-- 子を掃除
--========================
local function clear(container: Instance)
	for _, c in ipairs(container:GetChildren()) do
		if c:IsA("GuiObject") or c:IsA("UIListLayout") or c:IsA("UIPadding") then
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
	local useScale  = (opts.width == nil and opts.height == nil)
	local w         = opts.width  or 90
	local h         = opts.height or 150
	local gapScale  = (typeof(opts.paddingScale) == "number" and opts.paddingScale) or 0.02

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
	local vms   = DeckViewAdapter.toVMs(hand or {})
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

	-- カードを生成して並べる（Slot/Rootの2段）
	for i, vm in ipairs(vms) do
		local slotSize: UDim2
		if useScale then
			slotSize = UDim2.fromScale(W_SCALE, H_SCALE)
		else
			slotSize = UDim2.fromOffset(w, h)
		end
		local _slot, root = createSlot(container, slotSize)

		-- 実体（CardNode）は Root の子にする（Rootだけを持ち上げる）
		local node
		if useScale then
			node = CardNode.create(root, vm.code, nil, nil, {
				month = vm.month, kind = vm.kind, name = vm.name,
			})
			node.Size = UDim2.fromScale(1, 1)
		else
			node = CardNode.create(root, vm.code, w, h, {
				month = vm.month, kind = vm.kind, name = vm.name,
			})
		end

		-- index 属性（選択ハイライト用）は CardNode（ボタン）に付与
		node:SetAttribute("index", i)

		-- ▼ フッタ（ローカライズ＆配色は CardNode 側で実施）
		CardNode.addBadge(node)

		-- クリックで選択
		if typeof(opts.onSelect) == "function" then
			local function fireSelect()
				opts.onSelect(i)
				-- 内部ハイライトも即時更新
				highlight(container, i)
			end
			if node:IsA("ImageButton") then
				node.Activated:Connect(fireSelect)
			elseif node:IsA("TextButton") then
				node.MouseButton1Click:Connect(fireSelect)
			end
		end
	end

	-- 初期ハイライト
	highlight(container, opts.selectedIndex)
end

return M
