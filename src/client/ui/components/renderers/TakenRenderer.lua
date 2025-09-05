-- StarterPlayerScripts/UI/components/renderers/TakenRenderer.lua
-- 取り札描画（右枠拡張版）
-- 分類: 光 / タネ / 短冊 / カス
-- 各カテゴリは1月→12月順に並び、1/3重ねて表示（横方向）

local RS = game:GetService("ReplicatedStorage")
local Theme = require(RS:WaitForChild("Config"):WaitForChild("Theme"))

-- CardNode（カード1枚の描画モジュール）
local UI_ROOT = script.Parent.Parent
local CardNode = require(UI_ROOT:WaitForChild("CardNode"))

local M = {}

-- ===== 内部 util =====
local function clearChildrenExceptLayouts(parent: Instance)
	for _, ch in ipairs(parent:GetChildren()) do
		if not ch:IsA("UIListLayout") and not ch:IsA("UIGridLayout")
			and not ch:IsA("UITableLayout") and not ch:IsA("UIPageLayout")
			and not ch:IsA("UIAspectRatioConstraint") and not ch:IsA("UISizeConstraint")
			and not ch:IsA("UITextSizeConstraint")
		then
			ch:Destroy()
		end
	end
end

local function applyZIndexRecursive(inst: Instance, z: number)
	pcall(function()
		if inst:IsA("GuiObject") then inst.ZIndex = z end
		for _, c in ipairs(inst:GetChildren()) do
			applyZIndexRecursive(c, z)
		end
	end)
end

-- kind名 → 表示カテゴリ名
local CATEGORY_MAP = { bright = "光", seed = "タネ", ribbon = "短冊", chaff = "カス" }
-- 表示順（固定）
local CAT_ORDER = { "光", "タネ", "短冊", "カス" }

-- 0101〜1204 の前2桁（月）
local function monthOf(code: string)
	local m = tonumber(string.sub(tostring(code or ""), 1, 2))
	return m or 99
end

--- takenCards: { {code="0101", kind="bright"}, ... }
function M.renderTaken(parent: Instance, takenCards: {any})
	if not parent or not parent.Destroy then return end
	clearChildrenExceptLayouts(parent)

	-- バケット（日本語キーはブラケットで）
	local buckets = { ["光"] = {}, ["タネ"] = {}, ["短冊"] = {}, ["カス"] = {} }

	-- 仕分け
	for _, card in ipairs(takenCards or {}) do
		local kind = tostring(card.kind or "chaff")
		local cat  = CATEGORY_MAP[kind] or "カス"
		table.insert(buckets[cat], card)
	end

	-- 1月→12月でソート
	for _, arr in pairs(buckets) do
		table.sort(arr, function(a, b) return monthOf(a.code) < monthOf(b.code) end)
	end

	-- レイアウト計算
	local S = Theme.SIZES or {}
	local C = Theme.COLORS or {}

	-- ★ 半分サイズに縮小
	local base = tonumber(S.HAND_H) or 168
	local cardH   = math.floor(base * 0.5)        -- 高さ(px)
	local cardW   = math.floor(cardH * (63/88))   -- ★ 花札の実寸横幅（63:88）

	local overlap    = 0.33                        -- 1/3重ね
	local stepX      = math.max(1, math.floor(cardW * (1 - overlap))) -- ★ 横幅ベースで計算
	local sectionGap = 4                           -- セクション間の縦隙間を詰める
	local panelPadX  = 6
	local rowH       = cardH + 2                   -- 行高

	local labelW     = 28
	local labelPadY  = 2

	-- 親がUIListLayoutを持っているなら、その並べ方に従う
	local parentHasList = parent:FindFirstChildOfClass("UIListLayout") ~= nil

	local usedHeight = 0
	for _, catName in ipairs(CAT_ORDER) do
		local arr = buckets[catName]

		-- セクション枠
		local section = Instance.new("Frame")
		section.Name = "Section_" .. catName
		section.Parent = parent
		section.BackgroundTransparency = 1
		section.ClipsDescendants = false
		section.AutomaticSize = Enum.AutomaticSize.None
		section.Size = UDim2.new(1, -panelPadX*2, 0, rowH)
		if not parentHasList then
			section.Position = UDim2.new(0, panelPadX, 0, usedHeight)
		end

		-- ラベル
		do
			local label = Instance.new("TextLabel")
			label.Name = "Label"
			label.Parent = section
			label.BackgroundTransparency = 1
			label.Size = UDim2.new(0, labelW, 1, 0)
			label.Position = UDim2.new(0, 0, 0, 0)
			label.Text = catName
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextYAlignment = Enum.TextYAlignment.Top
			label.TextSize = 14
			label.Font = Enum.Font.GothamBold
			label.TextColor3 = (C.MUTED_TEXT or Color3.fromRGB(80, 80, 80))
			label.BorderSizePixel = 0
			local pad = Instance.new("UIPadding")
			pad.Parent = label
			pad.PaddingTop = UDim.new(0, labelPadY)
		end

		-- カードを横並び（1/3重ね）＋ 後ろほどZIndex高く
		local x = labelW + 4
		local z = 10
		for _, card in ipairs(arr) do
			local node
			if type(CardNode) == "table" and type(CardNode.create) == "function" then
				node = CardNode.create(section, card.code, {
					anchor = Vector2.new(0, 0),
					pos    = UDim2.new(0, x, 0, 1),
					size   = UDim2.fromOffset(cardW, cardH),   -- ★ 幅×高を明示
					zindex = z,
				})
			elseif type(CardNode) == "function" then
				node = CardNode(section, card.code, {
					anchor = Vector2.new(0, 0),
					pos    = UDim2.new(0, x, 0, 1),
					size   = UDim2.fromOffset(cardW, cardH),
					zindex = z,
				})
			elseif type(CardNode) == "table" and type(CardNode.new) == "function" then
				node = CardNode.new(section, card.code, {
					anchor = Vector2.new(0, 0),
					pos    = UDim2.new(0, x, 0, 1),
					size   = UDim2.fromOffset(cardW, cardH),
					zindex = z,
				})
			else
				warn("[TakenRenderer] CardNode API が見つかりません（create/new/call いずれも無し）")
			end

			if node and typeof(node) == "Instance" then
				node.Parent = section
			end

			x += stepX
			z += 1
		end

		usedHeight += rowH + sectionGap
	end

	-- ScrollingFrame 対応（AutomaticCanvasSize を使わない場合）
	if parent:IsA("ScrollingFrame") then
		if parent.AutomaticCanvasSize == Enum.AutomaticSize.None then
			parent.CanvasSize = UDim2.new(0, 0, 0, usedHeight)
		end
	end

	-- 親がUIListLayoutを持っている場合は、縦のPaddingも詰める
	local list = parent:FindFirstChildOfClass("UIListLayout")
	if list then
		list.Padding = UDim.new(0, sectionGap)
		list.HorizontalAlignment = Enum.HorizontalAlignment.Left
		list.SortOrder = Enum.SortOrder.LayoutOrder
	end
end

return M
