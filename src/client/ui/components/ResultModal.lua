local M = {}

function M.create(parent: Instance)
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
	desc.Text = ""

	local btnRow = Instance.new("Frame")
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

	local function mkBtn(text)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0.31, 0, 1, 0)
		b.Text = text
		b.AutoButtonColor = true
		b.BackgroundColor3 = Color3.fromRGB(240,240,240)
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = b
		b.Parent = btnRow
		b.ZIndex = 102
		return b
	end
	local btnHome = mkBtn("帰宅する（TOPへ）")
	local btnNext = mkBtn("次のステージへ（+25年＆屋台）")
	local btnSave = mkBtn("セーブして終了")

	local on = { home = nil, next = nil, save = nil }

	btnHome.Activated:Connect(function() if on.home then on.home() end end)
	btnNext.Activated:Connect(function() if on.next then on.next() end end)
	btnSave.Activated:Connect(function() if on.save then on.save() end end)

	local function setLocked(button, locked)
		local base = button:GetAttribute("OrigText") or button.Text
		if locked then
			button.AutoButtonColor = false
			button.BackgroundColor3 = Color3.fromRGB(220,220,220)
			button.Text = base .. "  🔒"
		else
			button.AutoButtonColor = true
			button.BackgroundColor3 = Color3.fromRGB(240,240,240)
			button.Text = base
		end
	end

	local api = {}

	function api:show(data)
		local add = tonumber(data and data.rewardBank) or 2
		title.Text = ("冬 クリア！ +%d両"):format(add)
		if data and data.message and data.message ~= "" then
			desc.Text = data.message
		else
			local clears = tonumber(data and data.clears) or 0
			desc.Text = ("次の行き先を選んでください。（進捗: 通算 %d/3 クリア）"):format(clears)
		end
		modalOverlay.Visible = true
		resultModal.Visible = true
	end

	function api:hide()
		modalOverlay.Visible = false
		resultModal.Visible = false
	end

	function api:setLocked(nextLocked:boolean, saveLocked:boolean)
		setLocked(btnNext, nextLocked)
		setLocked(btnSave, saveLocked)
	end

	function api:on(handlers)
		on.home = handlers.home
		on.next = handlers.next
		on.save = handlers.save
	end

	return api
end

return M
