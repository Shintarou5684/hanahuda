-- StarterPlayerScripts/UI/components/CardNode.lua
-- カード画像ボタン（画像・角丸・枠・軽い拡大アニメ）
-- 右側インフォ / 下部バッジはローカライズ（JA/EN）対応
-- 依存: ReplicatedStorage/SharedModules/CardImageMap.lua
-- 任意依存: ReplicatedStorage/Config/Theme.lua, ReplicatedStorage/Config/Locale.lua
-- v0.9.7-P1-4b:
--   ① 札は“真四角”に統一（UICorner/外枠UIStrokeを生成しない）
--   ② バッジは従来どおりカード幅いっぱい（Size=UDim2.new(1,0,0,h)）
--   ③ 言語正規化を LocaleUtil に統合（"jp"→"ja" 警告は維持）

local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local CardImageMap = require(RS:WaitForChild("SharedModules"):WaitForChild("CardImageMap"))
local LocaleUtil   = require(RS:WaitForChild("SharedModules"):WaitForChild("LocaleUtil"))

-- Optional: Theme / Locale
local Theme: any = nil
local Locale: any = nil
do
	local okCfg, cfg = pcall(function() return RS:FindFirstChild("Config") end)
	if okCfg and cfg then
		if cfg:FindFirstChild("Theme") then
			local okT, t = pcall(function() return require(cfg.Theme) end)
			if okT then Theme = t end
		end
		if cfg:FindFirstChild("Locale") then
			local okL, l = pcall(function() return require(cfg.Locale) end)
			if okL then Locale = l end
		end
	end
end

local M = {}

export type Info = {
	month: number?,  -- 1..12
	kind: string?,   -- "bright"|"seed"|"ribbon"|"chaff"|…（任意）
	name: string?,   -- 札の日本語名など
}

--========================
-- Theme helpers
--========================
local function kindColorFallback(kind: string?)
	if kind == "bright" then return Color3.fromRGB(255,230,140)
	elseif kind == "seed" then return Color3.fromRGB(200,240,255)
	elseif kind == "ribbon" then return Color3.fromRGB(255,200,220)
	else return Color3.fromRGB(235,235,235) end
end

local function colorForKind(kind: string?)
	if Theme and Theme.colorForKind then
		local ok, c = pcall(function() return Theme.colorForKind(kind) end)
		if ok and typeof(c) == "Color3" then return c end
	end
	return kindColorFallback(kind)
end

local function themeColor(key: string, fallback: Color3)
	local c = fallback
	if Theme and Theme.COLORS and typeof(Theme.COLORS[key]) == "Color3" then
		c = Theme.COLORS[key]
	end
	return c
end

local function themeImage(key: string, fallback: string)
	local id = fallback
	if Theme and Theme.IMAGES and typeof(Theme.IMAGES[key]) == "string" and #Theme.IMAGES[key] > 0 then
		id = Theme.IMAGES[key]
	end
	return id
end

--========================
-- Locale helpers（LocaleUtil 統合）
--========================
local function normLangJa(v: string?): string?
	local raw = tostring(v or ""):lower()
	local n = LocaleUtil.norm(raw) -- "ja"/"en" or nil
	if raw == "jp" and n == "ja" then
		warn("[CardNode] received legacy 'jp'; normalizing to 'ja'")
	end
	return n
end

-- "ja"/"en" のみ返す（Locale.getGlobal → Locale.pick → "en"）
local function curLang(): string
	-- 1) グローバル設定
	if Locale and typeof(Locale.getGlobal) == "function" then
		local ok, v = pcall(Locale.getGlobal)
		if ok then
			local n = LocaleUtil.norm(v)
			if n then return n end
		end
	end
	-- 2) OS/環境推奨
	if Locale and typeof(Locale.pick) == "function" then
		local ok, v = pcall(Locale.pick)
		if ok then
			local n = LocaleUtil.norm(v)
			if n then return n end
		end
	end
	-- 3) 既定
	return "en"
end

local function kindJP(kind: string?, fallbackName: string?): string
	if fallbackName and #fallbackName > 0 then return fallbackName end
	if kind == "bright" then return "光"
	elseif kind == "seed" then return "タネ"
	elseif kind == "ribbon" then return "短冊"
	elseif kind == "chaff" or kind == "kasu" then return "カス"
	else return "--" end
end

local function kindEN(kind: string?, fallbackName: string?): string
	if kind == "bright" then return "Bright"
	elseif kind == "seed" then return "Seed"
	elseif kind == "ribbon" then return "Ribbon"
	elseif kind == "chaff" or kind == "kasu" then return "Chaff"
	elseif fallbackName and fallbackName:match("^[%w%p%s]+$") then
		return fallbackName
	else
		return "--"
	end
end

-- JA: "11月/タネ" / EN: "11/Seed"（ENは単位「月」を省く）
local function footerText(monthNum: number?, kind: string?, name: string?, lang: string): string
	local m = tonumber(monthNum)
	local mStr = m and tostring(m) or ""
	if lang == "ja" then
		local k = kindJP(kind, name)
		return (mStr ~= "" and (mStr .. "月/" .. k)) or k
	else
		local k = kindEN(kind, name)
		return (mStr ~= "" and (mStr .. "/" .. k)) or k
	end
end

-- 右側インフォの文言（短め）
local function sideInfoText(monthNum: number?, kind: string?, name: string?, lang: string): string
	local m = tonumber(monthNum) or 0
	if lang == "ja" then
		return string.format("%d月 %s", m, (name and #name>0) and name or kindJP(kind))
	else
		return string.format("%s %s", tostring(m), kindEN(kind))
	end
end

--========================
-- 本体API
--========================
-- 後方互換 API:
--   create(parent, code, w?, h?, info?, showInfoRight?)
-- 新API（推奨）:
--   create(parent, code, opts)
--     opts = {
--       size: UDim2, pos: UDim2, anchor: Vector2, zindex: number,
--       info: Info, showInfoRight: boolean, -- cornerRadius は無効（真四角固定）
--     }
function M.create(parent: Instance, code: string, a: any?, b: any?, c: any?, d: any?)
	-- 画像ID
	local okImg, imgId = pcall(function() return CardImageMap.get(code) end)
	local imageId = (okImg and imgId) or ""

	-- 引数解釈
	local opts: any = nil
	local legacyW: number? = nil
	local legacyH: number? = nil
	local legacyInfo: Info? = nil
	local legacyShowRight: boolean? = nil

	if typeof(a) == "table" and (a.size or a.pos or a.anchor or a.info or a.showInfoRight) then
		opts = a
	else
		legacyW, legacyH, legacyInfo, legacyShowRight = a, b, c, d
	end

	-- レイアウト方針
	local useScale = (opts == nil and legacyW == nil and legacyH == nil)
	local W_SCALE = 0.12
	local H_SCALE = 0.90

	local btn = Instance.new("ImageButton")
	btn.Name = "Card_" .. tostring(code or "????")
	btn.Parent = parent
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
	btn.Image = imageId
	btn.ScaleType = Enum.ScaleType.Fit
	btn.Active = true

	-- ZIndex
	do
		local baseZ = (parent:IsA("GuiObject") and parent.ZIndex or 1) + 1
		btn.ZIndex = (opts and tonumber(opts.zindex)) or baseZ
	end

	-- サイズ決定
	if opts and opts.size then
		btn.Size = opts.size
		useScale = false
	elseif useScale then
		btn.Size = UDim2.fromScale(W_SCALE, H_SCALE)
	else
		local w = tonumber(legacyW) or 180
		local h = tonumber(legacyH) or 120
		btn.Size = UDim2.fromOffset(w, h)
	end

	-- 位置＆アンカー（指定があれば反映）
	if opts and opts.anchor then btn.AnchorPoint = opts.anchor end
	if opts and opts.pos    then btn.Position    = opts.pos    end

	-- 最小サイズの安全弁
	do
		local min = Instance.new("UISizeConstraint")
		min.MinSize = Vector2.new(56, 78) -- 約 63:88
		min.Parent = btn
	end

	-- ★ 真四角：UICorner/外枠UIStrokeは生成しない（＝角丸なし＆縁取りなし）
	-- （ここは意図的に何もしない）

	-- 影（Theme.IMAGES.dropShadow があれば使用）
	do
		local shadow = Instance.new("ImageLabel")
		shadow.Name = "Shadow"
		shadow.Parent = btn
		shadow.BackgroundTransparency = 1
		shadow.Image = themeImage("dropShadow", "rbxassetid://1316045217")
		shadow.ImageTransparency = (Theme and Theme.HandShadowOffT) or 0.70
		shadow.ScaleType = Enum.ScaleType.Slice
		shadow.SliceCenter = Rect.new(10,10,118,118)
		shadow.Size = UDim2.fromScale(1,1)
		shadow.ZIndex = btn.ZIndex - 1
	end

	-- アスペクト固定（横:縦=63:88、高さ基準）
	do
		local ar = Instance.new("UIAspectRatioConstraint")
		ar.AspectRatio = 63/88
		ar.DominantAxis = Enum.DominantAxis.Height
		ar.Parent = btn
	end

	-- クリック感（軽い拡大アニメ）
	do
		local function tweenTo(sz) TweenService:Create(btn, TweenInfo.new(0.06), { Size = sz }):Play() end
		local baseSize: UDim2 = btn.Size

		btn.MouseEnter:Connect(function()
			baseSize = btn.Size
		end)

		local function scaleMul(sz: UDim2, mul: number): UDim2
			if sz.X.Scale > 0 or sz.Y.Scale > 0 then
				return UDim2.new(sz.X.Scale * mul, sz.X.Offset, sz.Y.Scale * mul, sz.Y.Offset)
			else
				return UDim2.fromOffset(math.max(1, sz.X.Offset * mul), math.max(1, sz.Y.Offset * mul))
			end
		end

		btn.MouseButton1Down:Connect(function()
			baseSize = btn.Size
			tweenTo(scaleMul(baseSize, 1.04))
		end)

		local function restore() tweenTo(baseSize) end
		btn.MouseButton1Up:Connect(restore)
		btn.MouseLeave:Connect(restore)
	end

	-- 右側インフォの補助ラベル（必要なときのみ）
	local showInfoRight = (opts and opts.showInfoRight) or legacyShowRight
	local info: Info?    = (opts and opts.info) or legacyInfo
	if showInfoRight and info then
		local lab = Instance.new("TextLabel")
		lab.Name = "SideInfo"
		lab.Parent = btn
		lab.BackgroundTransparency = 1
		lab.TextScaled = true
		lab.Size = UDim2.new(0, 72, 0, 22) -- サイドはpx固定で視認性を保つ
		lab.Position = UDim2.new(1, 6, 0, 0)
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.TextYAlignment = Enum.TextYAlignment.Center
		lab.Font = Enum.Font.GothamMedium
		lab.Text = sideInfoText(info.month, info.kind, info.name, curLang())
		-- 補助ラベルの色は“役色”に寄せてアクセントを付ける
		lab.TextColor3 = colorForKind(info.kind)
		lab.ZIndex = btn.ZIndex + 1
	end

	return btn
end

-- 下部のバッジ（「11月/タネ」 or "11/Seed"）をカードに追加
function M.addBadge(cardButton: Instance, info: Info?)
	if not cardButton or not cardButton:IsA("GuiObject") then return end

	-- 既存を掃除
	local old = cardButton:FindFirstChild("Badge")
	if old then old:Destroy() end
	if not info then return end

	local lang = curLang()

	-- 台（カード幅いっぱい・真四角のまま）
	local holder = Instance.new("Frame")
	holder.Name = "Badge"
	holder.Parent = cardButton
	holder.AnchorPoint = Vector2.new(0, 1)
	holder.Position = UDim2.new(0, 0, 1, -2)              -- 下に2pxマージン
	holder.Size     = UDim2.new(1, 0, 0, 26)              -- カード幅いっぱい
	holder.BackgroundTransparency = 0.15
	holder.BorderSizePixel = 0
	holder.ZIndex = cardButton.ZIndex + 1
	holder.BackgroundColor3 = themeColor("BadgeBg", Color3.fromRGB(25,28,36))

	-- バッジは見た目を保つため角丸を残す（カード本体は真四角）
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, (Theme and Theme.PANEL_RADIUS) or 10); c.Parent = holder
	local s = Instance.new("UIStroke"); s.Thickness = 1; s.Color = themeColor("BadgeStroke", Color3.fromRGB(60,65,80)); s.Parent = holder

	-- 文言
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.Parent = holder
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1,1)
	t.TextScaled = true
	t.TextXAlignment = Enum.TextXAlignment.Center
	t.TextYAlignment = Enum.TextYAlignment.Center
	t.Font = Enum.Font.GothamMedium
	t.TextColor3 = colorForKind(info.kind)
	t.ZIndex = holder.ZIndex + 1
	t.Text = footerText(info.month, info.kind, info.name, lang)
end

return M
