-- StarterPlayerScripts/UI/components/renderers/TakenRenderer.lua
-- 取り札の描画レンダラ：スクロール内にグリッドで並べる

local components = script.Parent.Parent
local UiUtil     = require(components.Parent.lib:WaitForChild("UiUtil"))
local CardNode   = require(components:WaitForChild("CardNode"))

local M = {}

-- opts:
--   cellW:number? = 80
--   cellH:number? = 112
function M.render(scrollFrame: ScrollingFrame, cards: {any}?, opts: {cellW:number?, cellH:number?}? )
	opts = opts or {}
	local CW = opts.cellW or 80
	local CH = opts.cellH or 112

	-- 既存レイアウトは一度全消し（Takenは都度作り直す前提）
	for _, c in ipairs(scrollFrame:GetChildren()) do c:Destroy() end

	local grid = Instance.new("UIGridLayout")
	grid.CellSize    = UDim2.new(0, CW, 0, CH)
	grid.CellPadding = UDim2.new(0, 10, 0, 10)
	grid.SortOrder   = Enum.SortOrder.LayoutOrder
	grid.Parent      = scrollFrame

	for i, card in ipairs(cards or {}) do
		local m   = tonumber(card and card.month) or 0
		local idx = tonumber(card and card.idx)   or 0
		local code = (type(card)=="table" and card.code and card.code ~= "") and card.code
			or string.format("%02d%02d", m, idx)

		local node = CardNode.create(scrollFrame, code, CW, CH, {
			month = card.month, kind = card.kind, name = card.name
		})
		node.AutoButtonColor = false
		node.LayoutOrder = i
		CardNode.addBadge(node, { month = card.month, kind = card.kind, name = card.name })

		local kind = (type(card)=="table" and card.kind) or ""
		local name = (type(card)=="table" and card.name) or ""
		node:SetAttribute("tip", string.format("月%s %s %s", tostring(m), tostring(kind), tostring(name)))
	end
end

return M
