-- StarterPlayerScripts/UI/components/renderers/TakenRenderer.lua
-- v1.1.0 (Responsive: keep current look, size by parent)
--  - 現在のUI（ラベルピル + 色ドット + 1/3オーバーラップのカード列）を維持
--  - すべて親サイズから相対計算（タグH/タグW/行H/余白/ドットサイズ等）
--  - 親の AbsoluteSize 変化で自動再レイアウト
--  - 言語は "ja"/"en" を LocaleUtil から取得

local RS        = game:GetService("ReplicatedStorage")
local Config    = RS:WaitForChild("Config")
local Theme     = require(Config:WaitForChild("Theme"))
local LocaleUtil= require(RS:WaitForChild("SharedModules"):WaitForChild("LocaleUtil"))

-- CardNode（カード1枚）
local UI_ROOT   = script.Parent.Parent
local CardNode  = require(UI_ROOT:WaitForChild("CardNode"))

local M = {}

-- ========= lang / labels =========
local CATEGORY_JA = { bright = "光",     seed = "タネ",   ribbon = "短冊",  chaff = "カス",   kasu="カス" }
local CATEGORY_EN = { bright = "Bright", seed = "Seed",   ribbon = "Ribbon", chaff = "Chaff", kasu="Chaff" }
local ORDER       = { "bright", "seed", "ribbon", "chaff" }

local function curLang(): string
	return LocaleUtil.safeGlobal() or LocaleUtil.pickInitial() or "en"
end

-- ========= colors =========
local function kindColor(kind: string): Color3
	if Theme and Theme.colorForKind then
		local ok, c = pcall(function() return Theme.colorForKind(kind) end)
		if ok and typeof(c) == "Color3" then return c end
	end
	local C = Theme.COLORS or {}
	return C.BadgeStroke or C.SelectedStroke or C.TextDefault or Color3.fromRGB(200,200,200)
end

-- ========= utils =========
local function clearAll(parent: Instance)
	for _, ch in ipairs(parent:GetChildren()) do ch:Destroy() end
end
local function monthOf(code: string)
	local m = tonumber(string.sub(tostring(code or ""), 1, 2)); return m or 99
end
local function widthFromHeight(h: number): number
	return math.floor(h * (63/88)) -- 花札の実寸比
end

-- responsiveデータ保持とresize接続
local _store  = setmetatable({}, { __mode="k" }) -- parent -> takenCards
local _conns  = setmetatable({}, { __mode="k" }) -- parent -> RBXScriptConnection

-- ========= 本体描画（親サイズに相対） =========
local function paint(parent: Instance, takenCards: {any})
	clearAll(parent)

	local W = math.max(1, parent.AbsoluteSize.X)
	local H = math.max(1, parent.AbsoluteSize.Y)

	-- ---- 相対寸法（現状の見た目に寄せてチューニング） ----
	-- 横幅基準で安定するように多くをWから算出、必要に応じてHでクランプ
	local padX       = math.floor(W * 0.035)                      -- 左右余白
	local sectionGap = math.floor(H * 0.018)                      -- セクション間
	local tagH       = math.floor(math.clamp(H * 0.055, 18, 36))  -- タグの高さ
	local tagW       = math.floor(math.clamp(W * 0.44, 96, 180))  -- タグの幅（ピル）
	local dotSize    = math.floor(tagH * 0.48)                    -- 色ドットの直径
	local gapBelow   = math.floor(tagH * 0.50)                    -- タグ下のスペース
	local rowH       = math.floor(math.clamp(W * 0.25, 48, 120))  -- カード列の高さ
	local radiusPx   = tonumber(Theme.PANEL_RADIUS) or 10

	-- カード重なり
	local overlap = (Theme.RATIOS and Theme.RATIOS.TAKEN_OVERLAP) or 0.33

	-- 言語マップ
	local MAP = (curLang()=="ja") and CATEGORY_JA or CATEGORY_EN

	-- バケット化＆1月→12月でソート
	local buckets = { bright={}, seed={}, ribbon={}, chaff={} }
	for _, c in ipairs(takenCards or {}) do
		local k = tostring(c.kind or "chaff"):lower()
		if not buckets[k] then k = "chaff" end
		table.insert(buckets[k], c)
	end
	for _, arr in pairs(buckets) do
		table.sort(arr, function(a,b) return monthOf(a.code) < monthOf(b.code) end)
	end

	-- 使用高さ（CanvasSize用）
	local usedY   = 0
	local C       = Theme.COLORS or {}
	local parentZ = (parent:IsA("GuiObject") and parent.ZIndex) or 1

	for _, kind in ipairs(ORDER) do
		local arr = buckets[kind] or {}
		local title = MAP[kind] or kind

		-- セクション（タグ + 列）
		local sectionH = tagH + gapBelow + rowH
		local section = Instance.new("Frame")
		section.Name = "Section_"..kind
		section.BackgroundTransparency = 1
		section.Size = UDim2.new(1, -padX*2, 0, sectionH)
		section.Position = UDim2.new(0, padX, 0, usedY)
		section.ZIndex = parentZ + 2
		section.Parent = parent

		-- タグ（不透明ピル + ストローク + 色ドット + テキスト）
		do
			local tag = Instance.new("Frame")
			tag.Name = "LabelTag"
			tag.BackgroundTransparency = 0
			tag.BackgroundColor3 = C.PanelBg or Color3.fromRGB(32,34,40)
			tag.Size = UDim2.new(0, tagW, 0, tagH)
			tag.Position = UDim2.fromOffset(0,0)
			tag.ZIndex = section.ZIndex + 1
			tag.Parent = section

			local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, radiusPx); cr.Parent = tag
			local st = Instance.new("UIStroke"); st.Color = C.PanelStroke or Color3.fromRGB(70,70,80); st.Thickness = 1; st.Parent = tag

			local dot = Instance.new("Frame")
			dot.Name = "KindDot"
			dot.BackgroundColor3 = kindColor(kind)
			dot.BorderSizePixel  = 0
			dot.AnchorPoint = Vector2.new(0,0.5)
			dot.Position = UDim2.fromOffset(8, tagH*0.5)
			dot.Size     = UDim2.fromOffset(dotSize, dotSize)
			dot.ZIndex   = tag.ZIndex + 1
			dot.Parent   = tag
			local dcr = Instance.new("UICorner"); dcr.CornerRadius = UDim.new(1,0); dcr.Parent = dot

			local lab = Instance.new("TextLabel")
			lab.Name = "Text"
			lab.BackgroundTransparency = 1
			lab.TextXAlignment = Enum.TextXAlignment.Left
			lab.TextYAlignment = Enum.TextYAlignment.Center
			lab.AnchorPoint = Vector2.new(0,0.5)
			lab.Position = UDim2.fromOffset(8 + dotSize + 8, tagH*0.5)
			lab.Size     = UDim2.new(1, -(8 + dotSize + 8 + 8), 1, 0)
			lab.Font     = Enum.Font.GothamBold
			lab.TextColor3 = C.TextDefault or Color3.fromRGB(235,235,238)
			lab.TextScaled = true
			local lim = Instance.new("UITextSizeConstraint"); lim.MaxTextSize = 18; lim.Parent = lab
			lab.Text = string.format("%s ×%d", title, #arr)
			lab.ZIndex = tag.ZIndex + 1
			lab.Parent = tag
		end

		-- カード行（1/3オーバーラップ）
		do
			local row = Instance.new("Frame")
			row.Name = "CardsRow"
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, rowH)
			row.Position = UDim2.fromOffset(0, tagH + gapBelow)
			row.ZIndex = section.ZIndex + 2
			row.Parent = section

			local cardH = rowH - 2
			local cardW = widthFromHeight(cardH)
			local stepX = math.max(1, math.floor(cardW * (1 - overlap)))

			local x = 0
			local z = row.ZIndex + 1
			for _, card in ipairs(arr) do
				local node
				if type(CardNode) == "table" and type(CardNode.create) == "function" then
					node = CardNode.create(row, card.code, {
						anchor = Vector2.new(0, 0),
						pos    = UDim2.fromOffset(x, 1),
						size   = UDim2.fromOffset(cardW, cardH),
						zindex = z,
					})
				elseif type(CardNode) == "function" then
					node = CardNode(row, card.code, {
						anchor = Vector2.new(0, 0),
						pos    = UDim2.fromOffset(x, 1),
						size   = UDim2.fromOffset(cardW, cardH),
						zindex = z,
					})
				elseif type(CardNode) == "table" and type(CardNode.new) == "function" then
					node = CardNode.new(row, card.code, {
						anchor = Vector2.new(0, 0),
						pos    = UDim2.fromOffset(x, 1),
						size   = UDim2.fromOffset(cardW, cardH),
						zindex = z,
					})
				end
				x += stepX
				z += 1
			end
		end

		usedY += sectionH + sectionGap
	end

	-- ScrollingFrame対応（横スクロール不要）
	if parent:IsA("ScrollingFrame") then
		parent.ScrollingDirection = Enum.ScrollingDirection.Y
		parent.CanvasSize = UDim2.fromOffset(0, usedY)
		parent.ScrollBarThickness = (Theme.SIZES and Theme.SIZES.scrollBar) or 8
	end
end

-- ========= 公開API =========
function M.renderTaken(parent: Instance, takenCards: {any})
	if not parent or not parent.Destroy then return end
	_store[parent] = takenCards

	-- 初回描画
	paint(parent, takenCards)

	-- 既存のリサイズ接続は張り替え
	if _conns[parent] then
		_conns[parent]:Disconnect()
		_conns[parent] = nil
	end
	_conns[parent] = parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local data = _store[parent]
		if data then paint(parent, data) end
	end)
end

return M
