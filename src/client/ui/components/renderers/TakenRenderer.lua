-- StarterPlayerScripts/UI/components/renderers/TakenRenderer.lua
-- 取り札描画（右枠拡張版）
-- 分類: 光 / タネ / 短冊 / カス（言語で Bright / Seed / Ribbon / Chaff に自動切替）
-- 各カテゴリは 1月→12月 で並び、カードは横方向に 1/3 だけ重ねて表示
-- タグは不透明の白ベース＋濃色文字、タグの“直下”からカードを開始
-- v0.9.7-P1-1: 言語コード外部I/Fを "ja"/"en" に統一（受信 "jp" は警告して "ja" へ正規化）

local RS = game:GetService("ReplicatedStorage")
local Theme   = require(RS:WaitForChild("Config"):WaitForChild("Theme"))
local Locale  = require(RS:WaitForChild("Config"):WaitForChild("Locale"))

-- CardNode（カード1枚の描画モジュール）
local UI_ROOT  = script.Parent.Parent
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

-- "jp" → "ja" 正規化
local function normLangJa(v: string?): string?
	local s = tostring(v or ""):lower()
	if s == "ja" or s == "jp" then
		if s == "jp" then warn("[TakenRenderer] received legacy 'jp'; normalizing to 'ja'") end
		return "ja"
	elseif s == "en" then
		return "en"
	end
	return nil
end

-- 現在言語（"ja"/"en"。取得不可なら "en"）
local function curLang(): string
	-- Locale.getGlobal
	if typeof(Locale.getGlobal) == "function" then
		local ok, v = pcall(Locale.getGlobal)
		if ok then
			local n = normLangJa(v)
			if n then return n end
		end
	end
	-- Locale.pick
	if typeof(Locale.pick) == "function" then
		local ok, v = pcall(Locale.pick)
		if ok then
			local n = normLangJa(v)
			if n then return n end
		end
	end
	return "en"
end

-- kind名 → 表示カテゴリ名（JA/EN）
local CATEGORY_JA = { bright = "光",     seed = "タネ",   ribbon = "短冊",  chaff = "カス",   kasu = "カス" }
local CATEGORY_EN = { bright = "Bright", seed = "Seed",   ribbon = "Ribbon", chaff = "Chaff", kasu = "Chaff" }
-- 表示順（固定）
local CAT_ORDER_JA = { "光", "タネ", "短冊", "カス" }
local CAT_ORDER_EN = { "Bright", "Seed", "Ribbon", "Chaff" }

-- 役色（Theme があればそちらを優先）
local function kindColor(kind: string): Color3
	if Theme and Theme.colorForKind then
		local ok, c = pcall(function() return Theme.colorForKind(kind) end)
		if ok and typeof(c) == "Color3" then return c end
	end
	if kind == "bright" then return Color3.fromRGB(255,230,140)
	elseif kind == "seed" then return Color3.fromRGB(200,240,255)
	elseif kind == "ribbon" then return Color3.fromRGB(255,200,220)
	else return Color3.fromRGB(220,225,235) end
end

-- 63:88 の実寸横幅（高さから算出）
local function widthFromHeight(h: number): number
	return math.floor(h * (63/88))
end

-- 0101〜1204 の前2桁（月）
local function monthOf(code: string)
	local m = tonumber(string.sub(tostring(code or ""), 1, 2))
	return m or 99
end

--- takenCards: { {code="0101", kind="bright", month=1, name="松に鶴"}, ... }
function M.renderTaken(parent: Instance, takenCards: {any})
	if not parent or not parent.Destroy then return end
	clearChildrenExceptLayouts(parent)

	local lang      = curLang()
	local CAT_MAP   = (lang == "ja") and CATEGORY_JA or CATEGORY_EN
	local CAT_ORDER = (lang == "ja") and CAT_ORDER_JA or CAT_ORDER_EN

	-- バケット（キーは表示名で）
	local buckets = {}
	for _, key in ipairs(CAT_ORDER) do buckets[key] = {} end

	-- 仕分け
	for _, card in ipairs(takenCards or {}) do
		local kind = tostring(card.kind or "chaff")
		local catName = CAT_MAP[kind] or CAT_MAP["chaff"]
		table.insert(buckets[catName], card)
	end

	-- 1月→12月でソート
	for _, arr in pairs(buckets) do
		table.sort(arr, function(a, b) return monthOf(a.code) < monthOf(b.code) end)
	end

	-- レイアウト定数
	local S = Theme.SIZES or {}
	local C = Theme.COLORS or {}

	-- カードは「半分サイズ」
	local baseH    = tonumber(S.HAND_H) or 168
	local cardH    = math.floor(baseH * 0.5)
	local cardW    = widthFromHeight(cardH)
	local overlap  = 0.33
	local stepX    = math.max(1, math.floor(cardW * (1 - overlap)))

	-- 余白など
	local panelPadX   = 6
	local gapBetween  = 6             -- タグ行とカード行の間
	local sectionGap  = 8             -- セクション間
	local tagH        = 24
	local rowH        = cardH + 2

	local usedHeight  = 0
	local parentZ     = (parent:IsA("GuiObject") and parent.ZIndex) or 1

	for _, catName in ipairs(CAT_ORDER) do
		local arr = buckets[catName]

		-- セクション枠（タグ行＋カード行の2段）
		local section = Instance.new("Frame")
		section.Name = "Section_" .. catName
		section.Parent = parent
		section.BackgroundTransparency = 1
		section.ClipsDescendants = false
		section.AutomaticSize = Enum.AutomaticSize.None
		section.Size = UDim2.new(1, -panelPadX*2, 0, tagH + gapBetween + rowH)
		section.Position = UDim2.new(0, panelPadX, 0, usedHeight)
		section.ZIndex = parentZ + 2    -- 木目より確実に前面

		-- === タグ行（不透明の白＋濃い文字、左に色ドット） ===
		do
			local tag = Instance.new("Frame")
			tag.Name = "LabelTag"
			tag.Parent = section
			tag.BackgroundTransparency = 0                 -- 透過なし（くっきり）
			tag.BackgroundColor3 = (C.PanelBg or Color3.fromRGB(255,255,255))
			tag.Position = UDim2.new(0, 0, 0, 0)
			tag.Size = UDim2.new(0, 110, 0, tagH)          -- 幅は固定でOK
			tag.ZIndex = section.ZIndex + 1

			local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 10); cr.Parent = tag
			local st = Instance.new("UIStroke")
			st.Color = C.PanelStroke or Color3.fromRGB(210,220,230)
			st.Thickness = 1
			st.Transparency = 0
			st.Parent = tag

			-- 種類の色ドット
			local kindGuess = "chaff"
			if catName == CATEGORY_JA.bright or catName == CATEGORY_EN.bright then kindGuess = "bright"
			elseif catName == CATEGORY_JA.seed or catName == CATEGORY_EN.seed then kindGuess = "seed"
			elseif catName == CATEGORY_JA.ribbon or catName == CATEGORY_EN.ribbon then kindGuess = "ribbon"
			end

			local dot = Instance.new("Frame")
			dot.Name = "KindDot"
			dot.Parent = tag
			dot.BackgroundColor3 = kindColor(kindGuess)
			dot.Size = UDim2.new(0, 10, 0, 10)
			dot.Position = UDim2.new(0, 8, 0.5, -5)
			dot.ZIndex = tag.ZIndex + 1
			local dcr = Instance.new("UICorner"); dcr.CornerRadius = UDim.new(0, 5); dcr.Parent = dot

			local lab = Instance.new("TextLabel")
			lab.Name = "Text"
			lab.Parent = tag
			lab.BackgroundTransparency = 1
			lab.Position = UDim2.new(0, 8 + 10 + 6, 0, 0)  -- ドットの右から文字
			lab.Size = UDim2.new(1, -(8 + 10 + 6 + 8), 1, 0)
			lab.TextXAlignment = Enum.TextXAlignment.Left
			lab.TextYAlignment = Enum.TextYAlignment.Center
			lab.TextSize = 14
			lab.Font = Enum.Font.GothamBold
			lab.ZIndex = tag.ZIndex + 1
			lab.Text = string.format("%s ×%d", catName, #arr)
			lab.TextColor3 = (C.TextDefault or Color3.fromRGB(40,40,40)) -- くっきり
		end

		-- === カード行（タグの直下から開始） ===
		do
			local row = Instance.new("Frame")
			row.Name = "CardsRow"
			row.Parent = section
			row.BackgroundTransparency = 1
			row.Position = UDim2.new(0, 0, 0, tagH + gapBetween)
			row.Size = UDim2.new(1, 0, 0, rowH)
			row.ZIndex = section.ZIndex + 2

			local x = 0
			local z = row.ZIndex + 1
			for _, card in ipairs(arr) do
				local node
				if type(CardNode) == "table" and type(CardNode.create) == "function" then
					node = CardNode.create(row, card.code, {
						anchor = Vector2.new(0, 0),
						pos    = UDim2.new(0, x, 0, 1),
						size   = UDim2.fromOffset(cardW, cardH),
						zindex = z,
					})
				elseif type(CardNode) == "function" then
					node = CardNode(row, card.code, {
						anchor = Vector2.new(0, 0),
						pos    = UDim2.new(0, x, 0, 1),
						size   = UDim2.fromOffset(cardW, cardH),
						zindex = z,
					})
				elseif type(CardNode) == "table" and type(CardNode.new) == "function" then
					node = CardNode.new(row, card.code, {
						anchor = Vector2.new(0, 0),
						pos    = UDim2.new(0, x, 0, 1),
						size   = UDim2.fromOffset(cardW, cardH),
						zindex = z,
					})
				end

				-- ★取り札カードには“下部バッジ”は付けない（見た目をすっきり）
				-- （何もしない）

				x += stepX
				z += 1
			end
		end

		usedHeight += (tagH + gapBetween + rowH) + sectionGap
	end

	-- ScrollingFrame の CanvasSize を手動設定（Auto でなければ）
	if parent:IsA("ScrollingFrame") then
		if parent.AutomaticCanvasSize == Enum.AutomaticSize.None then
			parent.CanvasSize = UDim2.new(0, 0, 0, usedHeight)
		end
	end

	-- 親が UIListLayout を持っている場合は、縦Paddingを詰める
	local list = parent:FindFirstChildOfClass("UIListLayout")
	if list then
		list.Padding = UDim.new(0, sectionGap)
		list.HorizontalAlignment = Enum.HorizontalAlignment.Left
		list.SortOrder = Enum.SortOrder.LayoutOrder
	end
end

return M
