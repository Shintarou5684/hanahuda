-- StarterPlayerScripts/UI/components/ShopCells.lua
-- v0.9.H ShopCells：商品カードのUIリファイン（Theme薄適用 + 軽いホバー）
-- - 角丸/ストローク/色を Theme から適用
-- - 価格バンドをダーク帯（Badge系）に
-- - ホバーでカードのストロークを少し強調
-- - 既存のクリック/説明表示/購入フローは据え置き
-- P0-12: 二重クリック対策
--  - 価格帯を TextLabel 化 + InputTransparent=true（入力は親ボタンへ）
--  - Activated は本体ボタンのみ接続

local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Shared
local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat = require(SharedModules:WaitForChild("ShopFormat"))

-- Theme & I18n
local Config   = RS:WaitForChild("Config")
local Theme    = require(Config:WaitForChild("Theme"))
local ShopI18n = require(script.Parent:WaitForChild("i18n"):WaitForChild("ShopI18n"))

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

local function fmtPrice(n: number?): string
	return ("%d 文"):format(tonumber(n or 0))
end

local function itemTitle(it: any): string
	if it and it.name then return tostring(it.name) end
	return tostring(it and it.id or "???")
end

local function itemDesc(it: any, lang: string): string
	if not it then return "" end
	if lang == "en" then
		return (it.descEN or it.descEn or it.name or it.id or "")
	else
		return (it.descJP or it.descJa or it.name or it.id or "")
	end
end

-- UIに出すのは “名前だけ”
local ZODIAC_NAME: {[string]: string} = {
	kito_ko="子", kito_ushi="丑", kito_tora="寅", kito_u="卯", kito_tatsu="辰", kito_mi="巳",
	kito_uma="午", kito_hitsuji="未", kito_saru="申", kito_tori="酉", kito_inu="戌", kito_i="亥",
}
local function faceName(it: any): string
	if not it then return "???" end
	if it.displayName and tostring(it.displayName) ~= "" then return tostring(it.displayName) end
	if it.short and tostring(it.short) ~= "" then return tostring(it.short) end
	if it.shortName and tostring(it.shortName) ~= "" then return tostring(it.shortName) end
	if it.id and ZODIAC_NAME[it.id] then return ZODIAC_NAME[it.id] end
	return tostring(it.name or it.id or "???")
end

--========================
-- メイン：カード生成
--========================
function M.create(parent: Instance, nodes, it: any, lang: string, mon: number, handlers)
	-- カード本体（和紙パネル風）
	local btn = Instance.new("TextButton")
	btn.Name = it.id or "Item"
	btn.Text = faceName(it)
	btn.TextSize = 28
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Theme.COLORS.TextDefault
	btn.BackgroundColor3 = Theme.COLORS.PanelBg
	btn.AutoButtonColor = true
	btn.ZIndex = 10
	btn.Parent = parent
	addCorner(btn, Theme.PANEL_RADIUS)
	local stroke = addStroke(btn, Theme.COLORS.PanelStroke, 1, 0)

	-- 価格バンド（入力は親に透過させる）
	local priceBand = Instance.new("TextLabel")
	priceBand.Name = "Price"
	priceBand.BackgroundColor3 = Theme.COLORS.BadgeBg
	priceBand.Size = UDim2.new(1,0,0,20)
	priceBand.Position = UDim2.new(0,0,1,-20)
	priceBand.Text = fmtPrice(it.price)
	priceBand.TextSize = 14
	priceBand.Font = Enum.Font.Gotham
	priceBand.TextColor3 = Color3.fromRGB(245,245,245)
	priceBand.ZIndex = 11
	priceBand.InputTransparent = true -- ★ ここがポイント：クリックは親ボタンへ通す
	priceBand.Parent = btn
	addStroke(priceBand, Theme.COLORS.BadgeStroke, 1, 0.2)

	-- 購入可否の視覚
	local affordable = (tonumber(mon or 0) >= tonumber(it.price or 0))
	if not affordable then
		priceBand.Text = fmtPrice(it.price) .. ShopI18n.t(lang, "insufficient_suffix")
		priceBand.BackgroundTransparency = 0.15
		btn.AutoButtonColor = true -- クリックは許可（従来通りサーバ側で弾く）
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
	-- priceBand は InputTransparent のため、MouseEnter/Leave は不要（親で拾える）

	-- 説明表示（Infoパネルへ）
	local function showDesc()
		local desc = itemDesc(it, lang)
		local lines = {
			("<b>%s</b>"):format(it.name or itemTitle(it)),
			ShopI18n.t(lang, "label_category", tostring(it.category or "-")),
			ShopI18n.t(lang, "label_price", fmtPrice(it.price)),
			"",
			(desc ~= "" and desc or ShopI18n.t(lang, "no_desc")),
		}
		if nodes and nodes.infoText then
			nodes.infoText.Text = table.concat(lines, "\n")
		end
	end
	btn.MouseEnter:Connect(showDesc)
	-- priceBand からの説明表示も、InputTransparent により btn.MouseEnter で一貫化

	-- 購入（Activated は本体のみ）
	local function doBuy()
		if not handlers or type(handlers.onBuy) ~= "function" then return end
		handlers.onBuy(it)
	end
	btn.Activated:Connect(doBuy)
	-- ★ 削除: priceBand.Activated（Label化 + 入力透過で二重送出を根絶）

end

return M
