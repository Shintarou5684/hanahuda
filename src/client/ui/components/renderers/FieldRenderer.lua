-- StarterPlayerScripts/UI/components/renderers/FieldRenderer.lua
-- 場札の描画レンダラ：上下2段に分けて配置

local components = script.Parent.Parent
local lib        = components.Parent:WaitForChild("lib")

local UiUtil   = require(lib:WaitForChild("UiUtil"))
local CardNode = require(components:WaitForChild("CardNode"))

local M = {}

-- opts:
--   width:number?         -- 未指定ならスケールレイアウト（推奨）
--   height:number?        -- 未指定ならスケールレイアウト（推奨）
--   rowPaddingScale:number? = 0.02  -- カード間の横間隔（比率）
--   onPick:(bindex:number)->()      -- 場札クリック時に呼ぶ
function M.render(topRow: Instance, bottomRow: Instance, field: {any}?, opts: {width:number?, height:number?, rowPaddingScale:number?, onPick:any}? )
	opts = opts or {}
	local useScale = (opts.width == nil and opts.height == nil)
	local W = opts.width  or 80
	local H = opts.height or 96
	local padScale = (typeof(opts.rowPaddingScale) == "number" and opts.rowPaddingScale) or 0.02
	local onPick = opts.onPick

	-- 既存をクリア（まっさらに）
	UiUtil.clear(topRow, {})
	UiUtil.clear(bottomRow, {})

	-- 行レイアウト（横並び・両端にも同じ余白を付ける）
	local function ensureRowLayout(row: Instance)
		local layout = Instance.new("UIListLayout")
		layout.Parent = row
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(padScale, 0)

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft  = UDim.new(padScale, 0)
		pad.PaddingRight = UDim.new(padScale, 0)
		pad.Parent = row

		return layout, pad
	end

	ensureRowLayout(topRow)
	ensureRowLayout(bottomRow)

	local list = field or {}
	local n = #list
	local split = math.ceil(n/2) -- 前半=上段、後半=下段
	local topCount = math.min(split, n)
	local bottomCount = math.max(0, n - split)

	-- 行ごとのカード幅（scale）を計算
	local function calcWScale(count: number): number
		if count <= 0 then return 0.12 end
		-- 1行の横幅 = 1。両端とカード間に (count+1) 個の padScale が入る想定。
		local raw = (1 - padScale * (count + 1)) / count
		-- 見やすさのため下限/上限をクランプ
		if raw < 0.08 then raw = 0.08 end
		if raw > 0.18 then raw = 0.18 end
		return raw
	end

	local W_TOP    = calcWScale(topCount)
	local W_BOTTOM = calcWScale(bottomCount)

	for i, card in ipairs(list) do
		local code = card.code or string.format("%02d%02d", card.month, card.idx)
		local parentRow = (i <= split) and topRow or bottomRow
		local rowWScale = (i <= split) and W_TOP or W_BOTTOM

		local node
		if useScale then
			-- ★ スケールレイアウト：CardNode 側は比率対応。ここで横幅を行の枚数に合わせて上書き。
			node = CardNode.create(parentRow, code, nil, nil, {
				month = card.month, kind = card.kind, name = card.name
			})
			-- 横幅は行ごとの最適値、高さは CardNode 側が 0.90 を採用
			node.Size = UDim2.fromScale(rowWScale, 0.90)
		else
			-- ★ 互換：pxサイズを明示
			node = CardNode.create(parentRow, code, W, H, {
				month = card.month, kind = card.kind, name = card.name
			})
		end

		node:SetAttribute("bindex", i)
		node.LayoutOrder = i
		CardNode.addBadge(node, { month = card.month, kind = card.kind, name = card.name })

		if onPick then
			node.MouseButton1Click:Connect(function()
				onPick(i)
			end)
		end
	end
end

return M
