-- StarterPlayerScripts/UI/components/renderers/FieldRenderer.lua
-- 場札の描画レンダラ：上下2段に分けて配置

local components = script.Parent.Parent
local lib        = components.Parent:WaitForChild("lib")

local UiUtil   = require(lib:WaitForChild("UiUtil"))
local CardNode = require(components:WaitForChild("CardNode"))

local M = {}

-- opts:
--   width:number? = 80
--   height:number? -- 必須ではないが、渡せばそれで描画（例：ROW_H - 16）
--   onPick:(bindex:number)->() -- 場札クリック時に呼ぶ
function M.render(topRow: Instance, bottomRow: Instance, field: {any}?, opts: {width:number?, height:number?, onPick:any}? )
	opts = opts or {}
	local W = opts.width  or 80
	local H = opts.height or 96
	local onPick = opts.onPick

	UiUtil.clear(topRow, {"UIListLayout"})
	UiUtil.clear(bottomRow, {"UIListLayout"})

	local n = #(field or {})
	local split = math.ceil(n/2)

	for i, card in ipairs(field or {}) do
		local code = card.code or string.format("%02d%02d", card.month, card.idx)
		local parentRow = (i <= split) and topRow or bottomRow
		local node = CardNode.create(parentRow, code, W, H, {
			month = card.month, kind = card.kind, name = card.name
		})
		node:SetAttribute("bindex", i)
		CardNode.addBadge(node, { month = card.month, kind = card.kind, name = card.name })

		if onPick then
			node.MouseButton1Click:Connect(function()
				onPick(i)
			end)
		end
	end
end

return M
