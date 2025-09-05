-- StarterPlayerScripts/UI/components/renderers/HandRenderer.lua
-- 手札を描画。selectedIndex のハイライトは内部で管理

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

local components = script.Parent.Parent
local CardNode   = require(components:WaitForChild("CardNode"))

local M = {}

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

local function clear(container: Instance)
	for _,c in ipairs(container:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("ImageButton") or c:IsA("TextLabel") or c:IsA("Frame") or c:IsA("ImageLabel") then
			c:Destroy()
		end
	end
end

-- API: render(container, hand, { width, height, selectedIndex, onSelect })
function M.render(container: Instance, hand: {any}?, opts: {width:number?, height:number?, selectedIndex:number?, onSelect:(number)->()?})
	opts = opts or {}
	local w = opts.width  or 90
	local h = opts.height or 150

	clear(container)

	for i, card in ipairs(hand or {}) do
		local code = card.code or string.format("%02d%02d", card.month, card.idx)
		local node = CardNode.create(container, code, w, h, {
			month = card.month, kind = card.kind, name = card.name
		})
		node:SetAttribute("index", i)
		CardNode.addBadge(node, { month = card.month, kind = card.kind, name = card.name })
		if typeof(opts.onSelect) == "function" then
			node.MouseButton1Click:Connect(function()
				opts.onSelect(i)
			end)
		end
	end
	highlight(container, opts.selectedIndex)
end

return M
