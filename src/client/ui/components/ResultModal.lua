-- StarterPlayerScripts/UI/components/ResultModal.lua
-- ステージ結果モーダル：2択（こいこい／ホーム）＋ワンボタン（final）＋内訳→屋台（breakdown）
-- v0.9.9d: レイアウト調整（列幅/余白/行高/合計とボタン位置）

local M = {}

-- ===== 型（Luau） =====
type NavIF = { next: (NavIF, string) -> () }
type Handlers = {
	home: (() -> ())?, koikoi: (() -> ())?, final: (() -> ())?, shop: (() -> ())?
}
type ResultAPI = {
	hide: (ResultAPI) -> (),
	show: (ResultAPI, data: { rewardBank:number?, titleText:string?, descText:string?, nextMonth:number?, nextGoal:number? }?) -> (),
	showFinal: (ResultAPI, titleText:string?, descText:string?, buttonText:string?, onClick:(() -> ())?) -> (),
	showBreakdown: (ResultAPI, data: {
		titleText:string?, descText:string?, buttonText:string?, rewardMon:number?,
		breakdown: {
			base:number?, baseMult:number?, baseEarn:number?,
			stageMon:number?, divisor:number?, addFromStage:number?,
			rerollBoard:number?, addRerB:number?, rerollHand:number?, addRerH:number?,
			addBonus:number?,
		}?,
	}) -> (),
	setLocked: (ResultAPI, boolean) -> (),
	on: (ResultAPI, Handlers) -> (),
	bindNav: (ResultAPI, NavIF) -> (),
	destroy: (ResultAPI) -> (),
}
type ButtonStyle = "primary" | "neutral" | "warn"

-- Theme
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

--==================================================
-- 内部：ボタンのロック見た目
--==================================================
local function setLockedVisual(button: TextButton, locked: boolean)
	if not button then return end
	if button:GetAttribute("OrigBG3") == nil then button:SetAttribute("OrigBG3", button.BackgroundColor3) end
	if button:GetAttribute("OrigTX3") == nil then button:SetAttribute("OrigTX3", button.TextColor3) end
	if button:GetAttribute("OrigText") == nil then button:SetAttribute("OrigText", button.Text) end
	local baseText = button:GetAttribute("OrigText") or button.Text
	if locked then
		button.AutoButtonColor = false
		button:SetAttribute("locked", true)
		local C = Theme.COLORS
		button.BackgroundColor3 = (C and (C.CancelBtnBg or C.PanelStroke)) or Color3.fromRGB(200,200,200)
		button.TextColor3       = (C and (C.CancelBtnText or C.TextDefault)) or Color3.fromRGB(40,40,40)
		button.Text = tostring(baseText) .. "  [LOCK]"
	else
		button.AutoButtonColor = true
		button:SetAttribute("locked", false)
		local bg = button:GetAttribute("OrigBG3")
		local tx = button:GetAttribute("OrigTX3")
		if typeof(bg) == "Color3" then button.BackgroundColor3 = bg end
		if typeof(tx) == "Color3" then button.TextColor3       = tx end
		button.Text = tostring(baseText)
	end
end

--==================================================
-- Factory
--==================================================
function M.create(parent: Instance): ResultAPI
	-------------------------------- オーバーレイ
	local overlay = Instance.new("TextButton")
	overlay.Name = "ResultBackdrop"
	overlay.Parent = parent
	overlay.Size = UDim2.fromScale(1,1)
	overlay.AutoButtonColor = false
	overlay.Text = ""
	overlay.Visible = false
	overlay.ZIndex = 99
	do
		local C = Theme.COLORS
		overlay.BackgroundColor3 = (C and C.OverlayBg) or Color3.fromRGB(0,0,0)
		overlay.BackgroundTransparency = (Theme.overlayBgT ~= nil) and Theme.overlayBgT or 0.35
	end

	-------------------------------- 本体フレーム
	local modal = Instance.new("Frame")
	modal.Name = "ResultModal"
	modal.Parent = parent
	modal.Visible = false
	modal.Size = UDim2.new(0, 540, 0, 430) -- 幅+20 / 高さ+40
	modal.Position = UDim2.new(0.5, 0, 0.5, 0)
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.ZIndex = 100
	do
		local C = Theme.COLORS
		modal.BackgroundColor3 = (C and C.PanelBg) or Color3.fromRGB(255,255,255)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, Theme.PANEL_RADIUS or 10)
		corner.Parent = modal
		local stroke = Instance.new("UIStroke")
		stroke.Color = (C and C.PanelStroke) or Color3.fromRGB(210,210,210)
		stroke.Thickness = 1
		stroke.Parent = modal
	end

	-------------------------------- タイトル／説明
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Parent = modal
	title.BackgroundTransparency = 1
	title.TextScaled = true
	title.Size = UDim2.new(1,-20,0,48)
	title.Position = UDim2.new(0.5,0,0,16)
	title.AnchorPoint = Vector2.new(0.5,0)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Font = Enum.Font.GothamBold
	title.TextWrapped = true
	title.RichText = false
	title.ZIndex = 101
	title.Text = "結果"
	title.TextColor3 = (Theme.COLORS and Theme.COLORS.TextDefault) or Color3.fromRGB(25,25,25)

	local desc = Instance.new("TextLabel")
	desc.Name = "Desc"
	desc.Parent = modal
	desc.BackgroundTransparency = 1
	desc.TextScaled = true
	desc.Size = UDim2.new(1,-40,0,28)
	desc.Position = UDim2.new(0.5,0,0,68)
	desc.AnchorPoint = Vector2.new(0.5,0)
	desc.TextXAlignment = Enum.TextXAlignment.Center
	desc.TextWrapped = true
	desc.RichText = false
	desc.ZIndex = 101
	desc.Text = ""
	desc.TextColor3 = (Theme.COLORS and Theme.COLORS.TextDefault) or Color3.fromRGB(25,25,25)

	-- ★ 表レイアウト（3カラム）
	local tableFrame = Instance.new("Frame")
	tableFrame.Name = "BreakdownTable"
	tableFrame.Parent = modal
	tableFrame.BackgroundTransparency = 1
	tableFrame.Position = UDim2.new(0.5,0,0,108)
	tableFrame.Size = UDim2.new(1,-48,0,220) -- 横余白を少し増やす
	tableFrame.AnchorPoint = Vector2.new(0.5,0)
	tableFrame.ZIndex = 101
	local vlist = Instance.new("UIListLayout")
	vlist.Parent = tableFrame
	vlist.FillDirection = Enum.FillDirection.Vertical
	vlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	vlist.SortOrder = Enum.SortOrder.LayoutOrder
	vlist.Padding = UDim.new(0, 6)

	-- 列幅（見た目バランス調整）
	local COL_LEFT  = 170  -- 項目
	local COL_RIGHT = 120  -- 獲得文（右寄せ）
	local COL_GAP   = 12   -- 左と中の間の余白

	-- 行生成ヘルパ
	local function mkRow(leftText:string, midText:string, rightText:string, big:boolean?, boldRight:boolean?)
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1,0,0, big and 30 or 24)
		row.ZIndex = 101
		row.Parent = tableFrame

		local left = Instance.new("TextLabel")
		left.BackgroundTransparency = 1
		left.Size = UDim2.new(0, COL_LEFT, 1, 0)  -- 固定幅
		left.Position = UDim2.new(0,0,0,0)
		left.TextXAlignment = Enum.TextXAlignment.Left
		left.TextYAlignment = Enum.TextYAlignment.Center
		left.TextScaled = false
		left.TextSize = big and 20 or 18
		left.Font = big and Enum.Font.GothamBold or Enum.Font.Gotham
		left.Text = leftText
		left.ZIndex = 101
		left.Parent = row

		local mid = Instance.new("TextLabel")
		mid.BackgroundTransparency = 1
		mid.Size = UDim2.new(1, -(COL_LEFT + COL_RIGHT + COL_GAP + 8), 1, 0) -- 右に余白8
		mid.Position = UDim2.new(0, COL_LEFT + COL_GAP, 0, 0)
		mid.TextXAlignment = Enum.TextXAlignment.Left
		mid.TextYAlignment = Enum.TextYAlignment.Center
		mid.TextScaled = false
		mid.TextSize = big and 20 or 18
		mid.Font = Enum.Font.Gotham
		mid.Text = midText
		mid.ZIndex = 101
		mid.Parent = row

		local right = Instance.new("TextLabel")
		right.BackgroundTransparency = 1
		right.Size = UDim2.new(0, COL_RIGHT, 1, 0) -- 固定幅
		right.Position = UDim2.new(1, -COL_RIGHT - 8, 0, 0) -- 右端に8px余白
		right.TextXAlignment = Enum.TextXAlignment.Right
		right.TextYAlignment = Enum.TextYAlignment.Center
		right.TextScaled = false
		right.TextSize = big and 22 or 18
		right.Font = (boldRight and Enum.Font.GothamBold) or Enum.Font.Gotham
		right.Text = rightText
		right.ZIndex = 101
		right.Parent = row

		return row
	end

	local function mkSeparator()
		local sep = Instance.new("Frame")
		sep.BackgroundTransparency = 1
		sep.Size = UDim2.new(1,0,0,12)
		sep.ZIndex = 101
		sep.Parent = tableFrame

		local line = Instance.new("Frame")
		line.BackgroundColor3 = (Theme.COLORS and Theme.COLORS.PanelStroke) or Color3.fromRGB(210,210,210)
		line.BorderSizePixel = 0
		line.Size = UDim2.new(1,0,0,1)
		line.Position = UDim2.new(0,0,0.5,0)
		line.Parent = sep
	end

	-------------------------------- 2択ボタン行（こいこい／ホーム）
	local btnRow = Instance.new("Frame")
	btnRow.Name = "BtnRow"
	btnRow.Parent = modal
	btnRow.Size = UDim2.new(1,-40,0,64)
	btnRow.Position = UDim2.new(0.5,0,0,354) -- さらに下へ
	btnRow.AnchorPoint = Vector2.new(0.5,0)
	btnRow.BackgroundTransparency = 1
	btnRow.ZIndex = 101
	local layout = Instance.new("UIListLayout", btnRow)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 16)

	local function mkBtn(text: string, style: ButtonStyle?): TextButton
		local C = Theme.COLORS
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0.45, 0, 1, 0)
		b.Text = text
		b.AutoButtonColor = true
		b.TextWrapped = true
		b.RichText = false
		b.ZIndex = 102
		b.Parent = btnRow

		local bg, tx
		if style == "primary" then
			bg = C and C.PrimaryBtnBg or Color3.fromRGB(190,50,50)
			tx = C and C.PrimaryBtnText or Color3.fromRGB(255,245,240)
		elseif style == "warn" then
			bg = C and C.WarnBtnBg or Color3.fromRGB(180,80,40)
			tx = C and C.WarnBtnText or Color3.fromRGB(255,240,230)
		else
			bg = C and C.CancelBtnBg or Color3.fromRGB(120,130,140)
			tx = C and C.CancelBtnText or Color3.fromRGB(240,240,240)
		end
		b.BackgroundColor3 = bg
		b.TextColor3 = tx
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, Theme.PANEL_RADIUS or 10)
		c.Parent = b

		b:SetAttribute("OrigText", text)
		b:SetAttribute("OrigBG3", bg)
		b:SetAttribute("OrigTX3", tx)
		return b
	end

	local btnHome  = mkBtn("ホームへ", "neutral")
	local btnKoi   = mkBtn("こいこい", "primary")

	-------------------------------- ワンボタン（final）
	local finalBtn = Instance.new("TextButton")
	finalBtn.Name = "FinalBtn"
	finalBtn.Parent = modal
	finalBtn.Size = UDim2.new(0, 240, 0, 48)
	finalBtn.Position = UDim2.new(0.5,0,0,354)
	finalBtn.AnchorPoint = Vector2.new(0.5,0)
	finalBtn.AutoButtonColor = true
	finalBtn.TextWrapped = true
	finalBtn.RichText = false
	finalBtn.Visible = false
	finalBtn.ZIndex = 102
	do
		local C = Theme.COLORS
		finalBtn.BackgroundColor3 = (C and C.PrimaryBtnBg) or Color3.fromRGB(190,50,50)
		finalBtn.TextColor3       = (C and C.PrimaryBtnText) or Color3.fromRGB(255,245,240)
		local fcorner = Instance.new("UICorner")
		fcorner.CornerRadius = UDim.new(0, Theme.PANEL_RADIUS or 10)
		fcorner.Parent = finalBtn
	end

	-------------------------------- ワンボタン（breakdown→屋台）
	local okBtn = Instance.new("TextButton")
	okBtn.Name = "OkBtn"
	okBtn.Parent = modal
	okBtn.Size = UDim2.new(0, 240, 0, 48)
	okBtn.Position = UDim2.new(0.5,0,0,354)
	okBtn.AnchorPoint = Vector2.new(0.5,0)
	okBtn.AutoButtonColor = true
	okBtn.TextWrapped = true
	okBtn.RichText = false
	okBtn.Visible = false
	okBtn.ZIndex = 102
	do
		local C = Theme.COLORS
		okBtn.BackgroundColor3 = (C and C.PrimaryBtnBg) or Color3.fromRGB(190,50,50)
		okBtn.TextColor3       = (C and C.PrimaryBtnText) or Color3.fromRGB(255,245,240)
		local oc = Instance.new("UICorner")
		oc.CornerRadius = UDim.new(0, Theme.PANEL_RADIUS or 10)
		oc.Parent = okBtn
	end

	-------------------------------- ハンドラ
	local on: Handlers = { home = nil, koikoi = nil, final = nil, shop = nil }
	btnHome.Activated:Connect(function() if on.home then on.home() end end)
	btnKoi.Activated:Connect(function() if btnKoi:GetAttribute("locked") then return end if on.koikoi then on.koikoi() end end)
	finalBtn.Activated:Connect(function() if on.final then on.final() end end)
	okBtn.Activated:Connect(function() if on.shop then on.shop() end end)
	overlay.Activated:Connect(function() end) -- 背景クリック無効

	-------------------------------- API
	local api: any = {}

	function api:hide()
		overlay.Visible = false
		modal.Visible = false
	end

	-- 2択（9/10/11/12月）
	function api:show(data)
		local add       = tonumber(data and data.rewardBank) or 2
		local nextMonth = tonumber(data and data.nextMonth) or nil
		local nextGoal  = tonumber(data and data.nextGoal) or nil

		local titleText = (data and data.titleText) or ("クリアおめでとう！  +%d両"):format(add)
		local descText  = (data and data.descText)
			or ((nextMonth and nextGoal) and ("このまま こいこい で %d月: 目標 %s に挑戦しますか？"):format(nextMonth, tostring(nextGoal))
				or "このまま こいこい で続けますか？")

		local koiLabel = ((nextMonth and nextGoal) and ("こいこい（%d月: 目標 %s）"):format(nextMonth, tostring(nextGoal))) or "こいこい"

		local C = Theme.COLORS
		title.TextColor3 = (C and C.TextDefault) or title.TextColor3
		desc.TextColor3  = (C and C.TextDefault) or desc.TextColor3

		title.Text = titleText
		desc.Text  = descText

		tableFrame.Visible = false
		btnKoi.Text = koiLabel
		btnRow.Visible = true
		finalBtn.Visible = false
		okBtn.Visible = false

		overlay.Visible = true
		modal.Visible = true
	end

	function api:showFinal(titleText: string?, descText: string?, buttonText: string?, onClick: (() -> ())?)
		title.Text = titleText or "クリアおめでとう！"
		desc.Text  = descText  or "このランは終了です。メニューに戻ります。"

		tableFrame.Visible = false
		finalBtn.Text = buttonText or "メニューに戻る"
		on.final = onClick

		btnRow.Visible = false
		okBtn.Visible = false
		finalBtn.Visible = true

		overlay.Visible = true
		modal.Visible = true
	end

	function api:showBreakdown(data)
		local bd = (data and data.breakdown) or {}
		local total = tonumber(data and data.rewardMon) or 0

		title.Text = (data and data.titleText) or "クリア！"
		desc.Text  = (data and data.descText)  or "獲得文の内訳を確認してください"
		okBtn.Text = (data and data.buttonText) or "屋台へ"

		-- 既存行クリア
		for _,child in ipairs(tableFrame:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		-- ヘッダー（3カラムの見出し）
		mkRow("基本点", "× 倍数", "＝ 獲得文", true, true)

		-- 行
		mkRow("基本報酬",
			string.format("%d × %d", tonumber(bd.base or 0), tonumber(bd.baseMult or 1)),
			string.format("%d", tonumber(bd.baseEarn or (bd.base or 0))),
			false, true
		)
		mkRow("獲得加算",
			string.format("%d / %d", tonumber(bd.stageMon or 0), tonumber(bd.divisor or 1)),
			string.format("%d", tonumber(bd.addFromStage or 0)),
			false, true
		)
		mkRow("場リロール",
			string.format("%d × 1", tonumber(bd.rerollBoard or 0)),
			string.format("%d", tonumber(bd.addRerB or 0)),
			false, true
		)
		mkRow("手札リロール",
			string.format("%d × 1", tonumber(bd.rerollHand or 0)),
			string.format("%d", tonumber(bd.addRerH or 0)),
			false, true
		)
		local _bonus = tonumber(bd.addBonus or 0)
		mkRow("追加ボーナス",
		(_bonus == 0) and "0" or "",
		string.format("%d", _bonus),
		false, true
		)

		-- 仕切り線
		mkSeparator()

		-- 合計（大きめ/右に寄せすぎない：右余白8を維持）
		mkRow("合計", "", string.format("%d 文", total), true, true)

		tableFrame.Visible = true
		btnRow.Visible = false
		finalBtn.Visible = false
		okBtn.Visible = true

		overlay.Visible = true
		modal.Visible = true
	end

	function api:setLocked(koikoiLocked:boolean)
		setLockedVisual(btnKoi, koikoiLocked and true or false)
	end

	function api:on(handlers: Handlers)
		on.home   = handlers and handlers.home   or on.home
		on.koikoi = handlers and handlers.koikoi or on.koikoi
		on.final  = handlers and handlers.final  or on.final
		on.shop   = handlers and handlers.shop   or on.shop
	end

	function api:bindNav(nav: NavIF)
		if not nav or type(nav.next) ~= "function" then return end
		on.home   = function() nav:next("home") end
		on.koikoi = function() nav:next("koikoi") end
		on.final  = function() nav:next("home") end
		on.shop   = function() nav:next("shop") end
	end

	function api:destroy()
		self:hide()
		pcall(function() modal:Destroy() end)
		pcall(function() overlay:Destroy() end)
	end

	return api
end

return M
