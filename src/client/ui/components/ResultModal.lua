-- StarterPlayerScripts/UI/components/ResultModal.lua
-- ステージ結果モーダル：3択／ワンボタン（final）両対応（Nav統一/ロック無効化対応）

local M = {}

-- 型（Luau）
type NavIF = { next: (NavIF, string) -> () }
type Handlers = { home: (() -> ())?, next: (() -> ())?, save: (() -> ())?, final: (() -> ())? }
type ResultAPI = {
	hide: (ResultAPI) -> (),
	show: (ResultAPI, data: { rewardBank: number?, message: string?, clears: number? }?) -> (),
	showFinal: (ResultAPI, titleText: string?, descText: string?, buttonText: string?, onClick: (() -> ())?) -> (),
	setLocked: (ResultAPI, boolean, boolean) -> (),
	on: (ResultAPI, Handlers) -> (),
	bindNav: (ResultAPI, Nav: NavIF) -> (),
	destroy: (ResultAPI) -> (),
}

local function setLocked(button: TextButton, locked: boolean)
	if not button then return end
	local base = button:GetAttribute("OrigText") or button.Text
	if locked then
		button.AutoButtonColor = false
		button.BackgroundColor3 = Color3.fromRGB(220,220,220)
		button.Text = tostring(base) .. "  🔒"
		button:SetAttribute("locked", true)
	else
		button.AutoButtonColor = true
		button.BackgroundColor3 = Color3.fromRGB(240,240,240)
		button.Text = tostring(base)
		button:SetAttribute("locked", false)
	end
end

function M.create(parent: Instance): ResultAPI
	-- 背景
	local modalOverlay = Instance.new("TextButton")
	modalOverlay.Name = "ResultBackdrop"
	modalOverlay.Parent = parent
	modalOverlay.Size = UDim2.fromScale(1,1)
	modalOverlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
	modalOverlay.BackgroundTransparency = 0.35
	modalOverlay.AutoButtonColor = false
	modalOverlay.Text = ""
	modalOverlay.Visible = false
	modalOverlay.ZIndex = 99

	-- 本体
	local resultModal = Instance.new("Frame")
	resultModal.Name = "ResultModal"
	resultModal.Parent = parent
	resultModal.Visible = false
	resultModal.Size = UDim2.new(0, 520, 0, 260)
	resultModal.Position = UDim2.new(0.5, 0, 0.5, 0)
	resultModal.AnchorPoint = Vector2.new(0.5, 0.5)
	resultModal.BackgroundColor3 = Color3.fromRGB(255,255,255)
	resultModal.ZIndex = 100
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,16); corner.Parent = resultModal

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Parent = resultModal
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

	local desc = Instance.new("TextLabel")
	desc.Name = "Desc"
	desc.Parent = resultModal
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

	-- ▼ ボタン行（3択用）
	local btnRow = Instance.new("Frame")
	btnRow.Name = "BtnRow"
	btnRow.Parent = resultModal
	btnRow.Size = UDim2.new(1,-40,0,64)
	btnRow.Position = UDim2.new(0.5,0,0,120)
	btnRow.AnchorPoint = Vector2.new(0.5,0)
	btnRow.BackgroundTransparency = 1
	btnRow.ZIndex = 101
	local layout = Instance.new("UIListLayout", btnRow)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 16)

	local function mkBtn(text: string): TextButton
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0.31, 0, 1, 0)
		b.Text = text
		b.AutoButtonColor = true
		b.BackgroundColor3 = Color3.fromRGB(240,240,240)
		b.TextWrapped = true
		b.RichText = true
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = b
		b.Parent = btnRow
		b.ZIndex = 102
		b:SetAttribute("OrigText", text)
		return b
	end
	local btnHome = mkBtn("帰宅する（TOPへ）")
	local btnNext = mkBtn("次のステージへ（+25年＆屋台）")
	local btnSave = mkBtn("セーブして終了")

	-- ▼ ワンボタン（final）用
	local finalBtn = Instance.new("TextButton")
	finalBtn.Name = "FinalBtn"
	finalBtn.Parent = resultModal
	finalBtn.Size = UDim2.new(0, 240, 0, 48)
	finalBtn.Position = UDim2.new(0.5,0,0,120)
	finalBtn.AnchorPoint = Vector2.new(0.5,0)
	finalBtn.AutoButtonColor = true
	finalBtn.BackgroundColor3 = Color3.fromRGB(240,240,240)
	finalBtn.TextWrapped = true
	finalBtn.RichText = true
	local fcorner = Instance.new("UICorner"); fcorner.CornerRadius = UDim.new(0, 10); fcorner.Parent = finalBtn
	finalBtn.Visible = false
	finalBtn.ZIndex = 102

	-- ハンドラ
	local on: Handlers = { home = nil, next = nil, save = nil, final = nil }

	-- クリック結線（ロック中は無視）
	btnHome.Activated:Connect(function()
		if on.home then on.home() end
	end)
	btnNext.Activated:Connect(function()
		if btnNext:GetAttribute("locked") then return end
		if on.next then on.next() end
	end)
	btnSave.Activated:Connect(function()
		if btnSave:GetAttribute("locked") then return end
		if on.save then on.save() end
	end)
	finalBtn.Activated:Connect(function()
		if on.final then on.final() end
	end)

	-- 背景クリックでは閉じない（意図的にno-op）
	modalOverlay.Activated:Connect(function() end)

	-- API
	local api: any = {}

	function api:hide()
		modalOverlay.Visible = false
		resultModal.Visible = false
	end

	-- 従来の3択表示
	function api:show(data)
		local add = tonumber(data and data.rewardBank) or 2
		title.Text = ("冬 クリア！ +%d両"):format(add)
		if data and data.message and data.message ~= "" then
			desc.Text = data.message
		else
			local clears = tonumber(data and data.clears) or 0
			desc.Text = ("次の行き先を選んでください。（進捗: 通算 %d/3 クリア）"):format(clears)
		end
		-- 表示切替：3択オン／ワンボタンオフ
		btnRow.Visible = true
		finalBtn.Visible = false

		modalOverlay.Visible = true
		resultModal.Visible = true
	end

	-- 冬（最終）専用：ワンボタン表示
	function api:showFinal(titleText: string?, descText: string?, buttonText: string?, onClick: (() -> ())?)
		title.Text = titleText or "クリアおめでとう！"
		desc.Text  = descText  or "このランは終了です。メニューに戻ります。"
		finalBtn.Text = buttonText or "メニューに戻る"
		on.final = onClick

		-- 表示切替：3択オフ／ワンボタンオン
		btnRow.Visible = false
		finalBtn.Visible = true

		modalOverlay.Visible = true
		resultModal.Visible = true
	end

	-- 3択のロック設定
	function api:setLocked(nextLocked:boolean, saveLocked:boolean)
		setLocked(btnNext, nextLocked)
		setLocked(btnSave, saveLocked)
	end

	-- 3択/ワンボタンのハンドラ設定
	function api:on(handlers: Handlers)
		on.home  = handlers and handlers.home  or on.home
		on.next  = handlers and handlers.next  or on.next
		on.save  = handlers and handlers.save  or on.save
		on.final = handlers and handlers.final or on.final
	end

	-- ▼ Nav 糖衣（UI側は self._resultModal:bindNav(self.deps.Nav) だけでOK）
	function api:bindNav(nav: NavIF)
		if not nav or type(nav.next) ~= "function" then return end
		on.home  = function() nav:next("home") end
		on.next  = function() nav:next("next") end
		on.save  = function() nav:next("save") end
		on.final = function() nav:next("home") end
	end

	-- 破棄（画面遷移時のリーク防止）
	function api:destroy()
		self:hide()
		pcall(function() resultModal:Destroy() end)
		pcall(function() modalOverlay:Destroy() end)
	end

	return api
end

return M
