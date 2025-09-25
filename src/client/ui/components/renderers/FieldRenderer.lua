-- StarterPlayerScripts/UI/components/renderers/FieldRenderer.lua
-- 場札の描画レンダラ：上下2段に分けて配置
-- v0.9.7-P1-6: DeckViewAdapter による一括VM化 + フッタ表示は CardNode に全面委譲
--               （画像決定/ローカライズ/配色は CardNode 側に集約）

local components = script.Parent.Parent
local lib        = components.Parent:WaitForChild("lib")

local UiUtil     = require(lib:WaitForChild("UiUtil"))
local CardNode   = require(components:WaitForChild("CardNode"))

-- ★ 依存
local RS         = game:GetService("ReplicatedStorage")
local Shared     = RS:WaitForChild("SharedModules")
local DeckViewAdapter = require(Shared:WaitForChild("Deck"):WaitForChild("DeckViewAdapter"))

local Config  = RS:WaitForChild("Config")
local Theme   = require(Config:WaitForChild("Theme"))

local M = {}

-- opts:
--   width:number?               -- 未指定ならスケールレイアウト（推奨）
--   height:number?              -- 未指定ならスケールレイアウト（推奨）
--   rowPaddingScale:number?     -- カード間隔（比率）。未指定は Theme.RATIOS.COL_GAP
--   onPick:(bindex:number)->()  -- 場札クリック時に呼ぶ
function M.render(topRow: Instance, bottomRow: Instance, field: {any}?, opts: {width:number?, height:number?, rowPaddingScale:number?, onPick:any}? )
	opts = opts or {}
	local useScale = (opts.width == nil and opts.height == nil)
	local W = opts.width  or 80
	local H = opts.height or 96
	local R = Theme.RATIOS or {}
	local padScale = (typeof(opts.rowPaddingScale) == "number" and opts.rowPaddingScale) or R.COL_GAP or 0.015
	local onPick = opts.onPick

	-- 既存をクリア
	UiUtil.clear(topRow, {})
	UiUtil.clear(bottomRow, {})

	-- 行レイアウト（横並び・両端にも同じ余白）
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

	-- ---- DeckViewAdapter で一括VM化（画像ID/種別/月/名称の決定を委譲） ----
	local vms = DeckViewAdapter.toVMs(field or {})
	local n   = #vms

	-- 上下2段にスプリット
	local split       = math.ceil(n/2) -- 前半=上段、後半=下段
	local topCount    = math.min(split, n)
	local bottomCount = math.max(0, n - split)

	-- 行ごとのカード幅（scale）
	local function calcWScale(count: number): number
		if count <= 0 then return 0.12 end
		local raw = (1 - padScale * (count + 1)) / count -- 両端＋間の余白
		if raw < 0.08 then raw = 0.08 end
		if raw > 0.18 then raw = 0.18 end
		return raw
	end

	local W_TOP    = calcWScale(topCount)
	local W_BOTTOM = calcWScale(bottomCount)

	for i, vm in ipairs(vms) do
		local parentRow = (i <= split) and topRow or bottomRow
		local rowWScale = (i <= split) and W_TOP  or W_BOTTOM

		local node
		if useScale then
			-- スケールレイアウト：横幅は行の枚数に応じて最適化
			node = CardNode.create(parentRow, vm.code, nil, nil, {
				month = vm.month, kind = vm.kind, name = vm.name,
			})
			node.Size = UDim2.fromScale(rowWScale, 0.90)
		else
			-- 互換：px 指定
			node = CardNode.create(parentRow, vm.code, W, H, {
				month = vm.month, kind = vm.kind, name = vm.name,
			})
		end

		-- 配列順を保持
		node:SetAttribute("bindex", i)
		node.LayoutOrder = i

		-- ▼ フッタ（ローカライズ/文字色は CardNode に委譲）
		-- info を省略すれば、CardNode 側が VM/Attributes 由来で自動表示
		CardNode.addBadge(node)

		-- クリック
		if onPick then
			node.MouseButton1Click:Connect(function()
				onPick(i)
			end)
		end
	end
end

return M
