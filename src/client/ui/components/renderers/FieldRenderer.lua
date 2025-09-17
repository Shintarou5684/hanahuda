-- StarterPlayerScripts/UI/components/renderers/FieldRenderer.lua
-- 場札の描画レンダラ：上下2段に分けて配置
-- v0.9.7-P1-4: Theme 完全デフォルト化 + 札フッタを常にカード幅いっぱい
--              言語コード正規化（"jp"→"ja"）/ JP時の英語カテゴリ混入を修正

local components = script.Parent.Parent
local lib        = components.Parent:WaitForChild("lib")

local UiUtil   = require(lib:WaitForChild("UiUtil"))
local CardNode = require(components:WaitForChild("CardNode"))

-- ★ 依存
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config  = ReplicatedStorage:WaitForChild("Config")
local Locale  = require(Config:WaitForChild("Locale"))
local Theme   = require(Config:WaitForChild("Theme"))

-- 言語（"ja"/"en"）。"jp" は "ja" へ正規化、取得不可は "en"
local function _lang()
	local v
	if typeof(Locale.getGlobal) == "function" then
		local ok, g = pcall(Locale.getGlobal); if ok then v = g end
	end
	if v == nil and typeof(Locale.pick) == "function" then
		local ok, p = pcall(Locale.pick); if ok then v = p end
	end
	v = tostring(v or "en"):lower()
	if v == "jp" then return "ja" end
	if v == "ja" or v == "en" then return v end
	return "en"
end

--=== フッタ用ユーティリティ ============================================

-- カテゴリの英語ラベル（短め）
local function _catEn(src)
	src = tostring(src or ""):lower()
	if src=="光" or src=="ひかり" or src=="hikari" or src=="bright" then return "Bright" end
	if src=="タネ" or src=="種"   or src=="tane"   or src=="seed"   then return "Seed"   end
	if src=="短冊"               or src=="ribbon"                       then return "Ribbon" end
	if src=="カス" or src=="kasu" or src=="chaff"                      then return "Chaff"  end
	return src
end

-- カテゴリの日本語ラベル（英語/表記ゆれを吸収）
local function _catJa(src)
	src = tostring(src or ""):lower()
	if src=="bright" or src=="光" or src=="ひかり" or src=="hikari" then return "光"   end
	if src=="seed"   or src=="タネ" or src=="種"   or src=="tane"   then return "タネ" end
	if src=="ribbon" or src=="短冊"                                 then return "短冊" end
	if src=="chaff"  or src=="kasu" or src=="カス"                  then return "カス"  end
	return src
end

-- フッタ表示テキスト（JP: "11月/タネ" ／ EN: "11/Seed"）
local function makeFooterText(monthNum, kindOrName, lang)
	local m = tonumber(monthNum)
	local mStr = m and tostring(m) or ""
	if lang == "en" then
		local cat = _catEn(kindOrName)
		if mStr ~= "" and cat ~= "" then
			return string.format("%s/%s", mStr, cat)
		elseif mStr ~= "" then
			return mStr
		else
			return cat
		end
	else
		local cat = _catJa(kindOrName)
		if mStr ~= "" and cat ~= "" then
			return string.format("%s月/%s", mStr, cat)
		elseif mStr ~= "" then
			return (mStr .. "月")
		else
			return cat
		end
	end
end

-- カード下部にフッタバッジを追加（カード幅いっぱい）
local function addFooter(node: Instance, text: string, kindForColor: string?)
	-- 既存 Footer を除去
	local old = node:FindFirstChild("Footer")
	if old then old:Destroy() end

	local SZ   = Theme.SIZES or {}
	local COL  = Theme.COLORS or {}
	local badgeH = SZ.BadgeH or 26

	local footer = Instance.new("Frame")
	footer.Name = "Footer"
	footer.Parent = node
	footer.AnchorPoint = Vector2.new(0,1)
	footer.Position = UDim2.new(0, 0, 1, -2)              -- 下に 2px マージン
	footer.Size     = UDim2.new(1, 0, 0, badgeH)          -- ★カード幅いっぱい
	footer.BackgroundColor3 = COL.BadgeBg or Color3.fromRGB(25,28,36)
	footer.BackgroundTransparency = 0.15
	footer.BorderSizePixel = 0
	footer.ZIndex = 10
	footer.ClipsDescendants = true

	local uic = Instance.new("UICorner")
	uic.CornerRadius = UDim.new(0, Theme.PANEL_RADIUS or 10)
	uic.Parent = footer

	local stroke = Instance.new("UIStroke")
	stroke.Color = COL.BadgeStroke or Color3.fromRGB(60,65,80)
	stroke.Thickness = 1
	stroke.Parent = footer

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
	label.TextScaled = true
	-- 役種に応じた文字色（Theme.colorForKind）。該当なしは白っぽく。
	local txtColor = (type(Theme.colorForKind)=="function" and Theme.colorForKind(kindForColor or "")) or Color3.fromRGB(235,235,235)
	label.TextColor3 = txtColor
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 11
end
--=======================================================================

local M = {}

-- opts:
--   width:number?         -- 未指定ならスケールレイアウト（推奨）
--   height:number?        -- 未指定ならスケールレイアウト（推奨）
--   rowPaddingScale:number?  -- カード間隔（比率）。未指定は Theme.RATIOS.COL_GAP
--   onPick:(bindex:number)->()      -- 場札クリック時に呼ぶ
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

	local list = field or {}
	local n = #list
	local split = math.ceil(n/2) -- 前半=上段、後半=下段
	local topCount = math.min(split, n)
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
	local langNow  = _lang()

	for i, card in ipairs(list) do
		local code = card.code or string.format("%02d%02d", card.month, card.idx)
		local parentRow = (i <= split) and topRow or bottomRow
		local rowWScale = (i <= split) and W_TOP or W_BOTTOM

		local node
		if useScale then
			-- スケールレイアウト：横幅は行の枚数に応じて最適化
			node = CardNode.create(parentRow, code, nil, nil, {
				month = card.month, kind = card.kind, name = card.name
			})
			node.Size = UDim2.fromScale(rowWScale, 0.90)
		else
			-- 互換：px 指定
			node = CardNode.create(parentRow, code, W, H, {
				month = card.month, kind = card.kind, name = card.name
			})
		end

		node:SetAttribute("bindex", i)
		node.LayoutOrder = i

		-- ▼ 言語対応のフッタ（EN: "11/Seed" / JP: "11月/タネ"）
		local footerText = makeFooterText(card.month, card.kind or card.name, langNow)
		addFooter(node, footerText, card.kind)

		-- クリック
		if onPick then
			node.MouseButton1Click:Connect(function()
				onPick(i)
			end)
		end
	end
end

return M
