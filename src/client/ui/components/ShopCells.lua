-- StarterPlayerScripts/UI/components/ShopCells.lua
-- v0.9.I ShopCells：整形ロジックを ShopFormat/Locale に統一（S5）
--  - 価格/タイトル/説明/フェイス名のローカル実装を削除
--  - 文字列は ShopFormat と Locale に委譲
--  - 「不足」接尾辞/ラベル文言は Locale の SHOP_UI_* を使用
--  - 既存のUI/入力/購入フローは据え置き

local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Shared
local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat = require(SharedModules:WaitForChild("ShopFormat"))

-- Theme & Locale
local Config = RS:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

local M = {}

--========================
-- 小ユーティリティ
--========================
local function addCorner(gui: Instance, px: number?)
	local ok = pcall(function()
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, px or Theme.PANEL_RADIUS or 10)
		c.Parent = gui
	end)
	return ok
end

local function addStroke(gui: Instance, color: Color3?, thickness: number?, transparency: number?)
	local ok, stroke = pcall(function()
		local s = Instance.new("UIStroke")
		s.Thickness = thickness or 1
		s.Color = color or Theme.COLORS.PanelStroke
		s.Transparency = transparency or 0
		s.Parent = gui
		return s
	end)
	return ok and stroke or nil
end

--========================
-- メイン：カード生成
--========================
function M.create(parent: Instance, nodes, it: any, lang: string, mon: number, handlers)
	-- カード本体（和紙パネル風）
	local btn = Instance.new("TextButton")
	btn.Name = it.id or "Item"
	btn.Text = ShopFormat.faceName(it)
	btn.TextSize = 28
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Theme.COLORS.TextDefault
	btn.BackgroundColor3 = Theme.COLORS.PanelBg
	btn.AutoButtonColor = true
	btn.ZIndex = 10
	btn.Parent = parent
	addCorner(btn, Theme.PANEL_RADIUS)
	local stroke = addStroke(btn, Theme.COLORS.PanelStroke, 1, 0)

	-- 価格バンド（TextLabel にし、入力は親へパス）
	local priceBand = Instance.new("TextLabel")
	priceBand.Name = "Price"
	priceBand.BackgroundColor3 = Theme.COLORS.BadgeBg
	priceBand.Size = UDim2.new(1,0,0,20)
	priceBand.Position = UDim2.new(0,0,1,-20)
	priceBand.Text = ShopFormat.fmtPrice(it.price)
	priceBand.TextSize = 14
	priceBand.Font = Enum.Font.Gotham
	priceBand.TextColor3 = Color3.fromRGB(245,245,245)
	priceBand.ZIndex = 11
	priceBand.Active = false       -- 入力を自身で取らない
	priceBand.Selectable = false   -- 選択不可
	priceBand.Parent = btn
	addStroke(priceBand, Theme.COLORS.BadgeStroke, 1, 0.2)

	-- 購入可否の視覚
	local affordable = (tonumber(mon or 0) >= tonumber(it.price or 0))
	if not affordable then
		priceBand.Text = ShopFormat.fmtPrice(it.price) .. Locale.t(lang, "SHOP_UI_INSUFFICIENT_SUFFIX")
		priceBand.BackgroundTransparency = 0.15
		btn.AutoButtonColor = true -- クリックは許可（サーバ側で弾く）
	end

	-- ホバー：枠と背景をわずかに強調
	local ti = TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local baseBg = btn.BackgroundColor3

	local function hoverIn()
		if stroke then stroke.Thickness = 2 end
		TweenService:Create(btn, ti, { BackgroundColor3 = baseBg:Lerp(Color3.new(1,1,1), 0.06) }):Play()
	end
	local function hoverOut()
		if stroke then stroke.Thickness = 1 end
		TweenService:Create(btn, ti, { BackgroundColor3 = baseBg }):Play()
	end

	btn.MouseEnter:Connect(hoverIn)
	btn.MouseLeave:Connect(hoverOut)

	-- 説明表示（右の Info パネルへ）
	local function showDesc()
		local title = ShopFormat.itemTitle(it, lang)
		local desc  = ShopFormat.itemDesc(it, lang)
		local lines = {
			string.format("<b>%s</b>", title),
			Locale.t(lang, "SHOP_UI_LABEL_CATEGORY"):format(tostring(it.category or "-")),
			Locale.t(lang, "SHOP_UI_LABEL_PRICE"):format(ShopFormat.fmtPrice(it.price)),
			"",
			(desc ~= "" and desc or Locale.t(lang, "SHOP_UI_NO_DESC")),
		}
		if nodes and nodes.infoText then
			nodes.infoText.Text = table.concat(lines, "\n")
		end
	end
	btn.MouseEnter:Connect(showDesc)

	-- 購入（Activated は本体のみ）
	local function doBuy()
		if not handlers or type(handlers.onBuy) ~= "function" then return end
		handlers.onBuy(it)
	end
	btn.Activated:Connect(doBuy)
end

return M
