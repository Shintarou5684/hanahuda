-- StarterPlayerScripts/UI/components/ResultModal.lua
-- ステージ結果モーダル：2択（こいこい／ホーム）＋ワンボタン（final）
-- v0.9.8: 12-month対応／解禁ロジック撤廃／"next","save"削除 → "koikoi","home" に集約
--         Theme 完全デフォルト化（配色は Theme を参照）

local M = {}

-- 型（Luau）
type NavIF = { next: (NavIF, string) -> () }
type Handlers = { home: (() -> ())?, koikoi: (() -> ())?, final: (() -> ())? }
type ResultAPI = {
	hide: (ResultAPI) -> (),
	-- 2択：こいこい/ホーム（9/10/11/12月のクリア時に利用）
	show: (ResultAPI, data: {
		rewardBank: number?,        -- 付与両（既定=2）
		titleText: string?,         -- タイトル上書き（省略時は自動生成）
		descText: string?,          -- 説明上書き（省略時は自動生成）
		nextMonth: number?,         -- こいこい先の月（例: 10）
		nextGoal: number?,          -- こいこい先の目標スコア
	}?) -> (),
	-- ワンボタン（完全終了時 12月想定）
	showFinal: (ResultAPI, titleText: string?, descText: string?, buttonText: string?, onClick: (() -> ())?) -> (),
	setLocked: (ResultAPI, boolean) -> (), -- こいこいボタンのロックだけ提供
	on: (ResultAPI, Handlers) -> (),
	bindNav: (ResultAPI, Nav: NavIF) -> (),
	destroy: (ResultAPI) -> (),
}

-- Theme 参照
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

--==================================================
-- 内部：ボタンのロック見た目
--==================================================
local function setLockedVisual(button: TextButton, locked: boolean)
	if not button then return end
	-- 初回に元色を保存
	if button:GetAttribute("OrigBG3") == nil then
		button:SetAttribute("OrigBG3", button.BackgroundColor3)
	end
	if button:GetAttribute("OrigTX3") == nil then
		button:SetAttribute("OrigTX3", button.TextColor3)
	end
	if button:GetAttribute("OrigText") == nil then
		button:SetAttribute("OrigText", button.Text)
	end

	local baseText = button:GetAttribute("OrigText") or button.Text
	if locked then
		button.AutoButtonColor = false
		button:SetAttribute("locked", true)
		-- グレー系（Cancel系）に寄せる
		local C = Theme.COLORS
		button.BackgroundColor3 = (C and (C.CancelBtnBg or C.PanelStroke)) or Color3.fromRGB(200,200,200)
		button.TextColor3       = (C and (C.CancelBtnText or C.TextDefault)) or Color3.fromRGB(40,40,40)
		button.Text = tostring(baseText) .. "  🔒"
	else
		button.AutoButtonColor = true
		button:SetAttribute("locked", false)
		-- 元色に戻す
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
	modal.Size = UDim2.new(0, 520, 0, 260)
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
	title.RichText = true
	title.ZIndex = 101
	title.Text = "結果"
	title.TextColor3 = (Theme.COLORS and Theme.COLORS.TextDefault) or Color3.fromRGB(25,25,25)

	local desc = Instance.new("TextLabel")
	desc.Name = "Desc"
	desc.Parent = modal
	desc.BackgroundTransparency = 1
	desc.TextScaled = true
	desc.Size = UDim2.new(1,-40,0,32)
	desc.Position = UDim2.new(0.5,0,0,70)
	desc.AnchorPoint = Vector2.new(0.5,0)
	desc.TextXAlignment = Enum.TextXAlignment.Center
	desc.TextWrapped = true
	desc.RichText = true
	desc.ZIndex = 101
	desc.Text = ""
	desc.TextColor3 = (Theme.COLORS and Theme.COLORS.TextDefault) or Color3.fromRGB(25,25,25)

	-------------------------------- 2択ボタン行（こいこい／ホーム）
	local btnRow = Instance.new("Frame")
	btnRow.Name = "BtnRow"
	btnRow.Parent = modal
	btnRow.Size = UDim2.new(1,-40,0,64)
	btnRow.Position = UDim2.new(0.5,0,0,120)
	btnRow.AnchorPoint = Vector2.new(0.5,0)
	btnRow.BackgroundTransparency = 1
	btnRow.ZIndex = 101
	local layout = Instance.new("UIListLayout", btnRow)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 16)

	local function mkBtn(text: string, style: "primary" | "neutral" | "warn" | nil): TextButton
		local C = Theme.COLORS
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0.45, 0, 1, 0)
		b.Text = text
		b.AutoButtonColor = true
		b.TextWrapped = true
		b.RichText = true
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
	local btnKoi   = mkBtn("こいこい", "primary") -- テキストは show() 時に上書き

	-------------------------------- ワンボタン（final）
	local finalBtn = Instance.new("TextButton")
	finalBtn.Name = "FinalBtn"
	finalBtn.Parent = modal
	finalBtn.Size = UDim2.new(0, 240, 0, 48)
	finalBtn.Position = UDim2.new(0.5,0,0,120)
	finalBtn.AnchorPoint = Vector2.new(0.5,0)
	finalBtn.AutoButtonColor = true
	finalBtn.TextWrapped = true
	finalBtn.RichText = true
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

	-------------------------------- ハンドラ
	local on: Handlers = { home = nil, koikoi = nil, final = nil }

	-- クリック結線（ロック中は無視：こいこいのみロック対象）
	btnHome.Activated:Connect(function()
		if on.home then on.home() end
	end)
	btnKoi.Activated:Connect(function()
		if btnKoi:GetAttribute("locked") then return end
		if on.koikoi then on.koikoi() end
	end)
	finalBtn.Activated:Connect(function()
		if on.final then on.final() end
	end)

	-- 背景クリックでは閉じない（意図的に no-op）
	overlay.Activated:Connect(function() end)

	-------------------------------- API
	local api: any = {}

	function api:hide()
		overlay.Visible = false
		modal.Visible = false
	end

	-- 2択（9/10/11/12月のクリア時）
	-- data: { rewardBank?, titleText?, descText?, nextMonth?, nextGoal? }
	function api:show(data)
		local add       = tonumber(data and data.rewardBank) or 2
		local nextMonth = tonumber(data and data.nextMonth) or nil
		local nextGoal  = tonumber(data and data.nextGoal) or nil

		local titleText = data and data.titleText
			or ("クリアおめでとう！  +%d両"):format(add)

		local descText = data and data.descText
			or (nextMonth and nextGoal)
				and ("このまま こいこい で <b>%d月：目標 %s</b> に挑戦しますか？"):format(nextMonth, tostring(nextGoal))
				or "このまま こいこい で続けますか？"

		local koiLabel = (nextMonth and nextGoal)
			and ("こいこい（%d月：目標 %s）"):format(nextMonth, tostring(nextGoal))
			or "こいこい"

		local C = Theme.COLORS
		title.TextColor3 = (C and C.TextDefault) or title.TextColor3
		desc.TextColor3  = (C and C.TextDefault) or desc.TextColor3

		title.Text = titleText
		desc.Text  = descText
		btnKoi.Text = koiLabel

		-- 表示切替：2択オン／ワンボタンオフ
		btnRow.Visible = true
		finalBtn.Visible = false

		overlay.Visible = true
		modal.Visible = true
	end

	-- 完全終了（12月など）：ワンボタン
	function api:showFinal(titleText: string?, descText: string?, buttonText: string?, onClick: (() -> ())?)
		title.Text = titleText or "クリアおめでとう！"
		desc.Text  = descText  or "このランは終了です。メニューに戻ります。"
		finalBtn.Text = buttonText or "メニューに戻る"
		on.final = onClick

		-- 表示切替：2択オフ／ワンボタンオン
		btnRow.Visible = false
		finalBtn.Visible = true

		overlay.Visible = true
		modal.Visible = true
	end

	-- こいこいボタンのロック設定（救済演出や通信中のガード等に）
	function api:setLocked(koikoiLocked:boolean)
		setLockedVisual(btnKoi, koikoiLocked and true or false)
	end

	-- ハンドラ設定
	function api:on(handlers: Handlers)
		on.home   = handlers and handlers.home   or on.home
		on.koikoi = handlers and handlers.koikoi or on.koikoi
		on.final  = handlers and handlers.final  or on.final
	end

	-- ▼ Nav 糖衣（UI側は self._resultModal:bindNav(self.deps.Nav) だけでOK）
	function api:bindNav(nav: NavIF)
		if not nav or type(nav.next) ~= "function" then return end
		on.home   = function() nav:next("home") end
		on.koikoi = function() nav:next("koikoi") end
		on.final  = function() nav:next("home") end
	end

	-- 破棄（画面遷移時のリーク防止）
	function api:destroy()
		self:hide()
		pcall(function() modal:Destroy() end)
		pcall(function() overlay:Destroy() end)
	end

	return api
end

return M
