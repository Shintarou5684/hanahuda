-- StarterPlayerScripts/UI/components/renderers/FieldRenderer.lua
-- 場札の描画レンダラ：上下2段に分けて配置

local components = script.Parent.Parent
local lib        = components.Parent:WaitForChild("lib")

local UiUtil   = require(lib:WaitForChild("UiUtil"))
local CardNode = require(components:WaitForChild("CardNode"))

-- ★ 言語取得（グローバル優先）
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config  = ReplicatedStorage:WaitForChild("Config")
local Locale  = require(Config:WaitForChild("Locale"))
local function _lang()
	return (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or Locale.pick()
end

--=== フッタ用ユーティリティ ============================================

-- カテゴリの英語ラベル（短め）
local function _catEn(jp)
	if jp=="光" or jp=="ヒカリ" then return "Bright" end
	if jp=="タネ" or jp=="種"   then return "Seed"   end -- Animal/Tane を短く Seed に
	if jp=="短冊"               then return "Ribbon" end
	if jp=="カス"               then return "Chaff"  end
	return jp or ""
end

-- フッタ表示テキスト（JP: "11月/タネ" ／ EN: "11/Seed"）
local function makeFooterText(monthNum, catJP, lang)
	local m = tonumber(monthNum)
	local mStr = m and tostring(m) or ""
	if lang == "en" then
		-- 月という単位語は出さず、数字のみ
		if mStr ~= "" and catJP then
			return string.format("%s/%s", mStr, _catEn(catJP))
		elseif mStr ~= "" then
			return mStr
		else
			return _catEn(catJP)
		end
	else
		-- 日本語は従来どおり「11月/タネ」
		if mStr ~= "" and catJP then
			return string.format("%s月/%s", mStr, catJP)
		elseif mStr ~= "" then
			return (mStr .. "月")
		else
			return (catJP or "")
		end
	end
end

-- カード下部に小さなフッタバッジを作る（CardNode.addBadge の代替）
local function addFooter(node: Instance, text: string)
	-- 既存の Footer があれば消す
	local old = node:FindFirstChild("Footer")
	if old then old:Destroy() end

	local footer = Instance.new("Frame")
	footer.Name = "Footer"
	footer.Parent = node
	footer.AnchorPoint = Vector2.new(0,1)
	footer.Position = UDim2.new(0, 6, 1, -6)
	footer.Size = UDim2.fromOffset(0, 22)
	footer.AutomaticSize = Enum.AutomaticSize.X
	footer.BackgroundColor3 = Color3.fromRGB(36,40,52)
	footer.BackgroundTransparency = 0.15
	footer.BorderSizePixel = 0
	footer.ZIndex = 10
	footer.ClipsDescendants = true

	local uic = Instance.new("UICorner"); uic.CornerRadius = UDim.new(0, 6); uic.Parent = footer
	local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(70,75,90); stroke.Thickness = 0; stroke.Parent = footer

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, 6)
	pad.PaddingRight  = UDim.new(0, 6)
	pad.PaddingTop    = UDim.new(0, 2)
	pad.PaddingBottom = UDim.new(0, 2)
	pad.Parent = footer

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Parent = footer
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = tostring(text or "")
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextScaled = false
	label.TextColor3 = Color3.fromRGB(240,240,240)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 11
end
--=======================================================================

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

		-- ▼ 既存の addBadge は使わず、言語対応したフッタを自前で作る
		--    月の“単位語”は EN では出さない（11/Seed）
		local footerText = makeFooterText(card.month, card.kind or card.name, _lang())
		addFooter(node, footerText)

		-- クリック
		if onPick then
			node.MouseButton1Click:Connect(function()
				onPick(i)
			end)
		end
	end
end

return M
