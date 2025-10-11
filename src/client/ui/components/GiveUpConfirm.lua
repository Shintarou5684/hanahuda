-- components/GiveUpConfirm.lua
local M = {}

local function T(Locale, lang, key, ja, en)
	local ok, s = pcall(function() return Locale.t(lang, key) end)
	if ok and type(s)=="string" and s ~= "" and s ~= key then return s end
	return (lang=="ja") and ja or en
end

function M.close(parent)
	if not parent then return end
	local ov = parent:FindFirstChild("GiveUpOverlay")
	if ov then ov:Destroy() end
end

function M.show(parent, Locale, Theme, lang, onYes)
	M.close(parent)

	local overlay = Instance.new("Frame")
	overlay.Name = "GiveUpOverlay"
	overlay.Size = UDim2.fromScale(1,1)
	overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
	overlay.BackgroundTransparency = 0.35
	overlay.ZIndex = 1000
	overlay.Active = true
	overlay.Parent = parent

	local p = Instance.new("Frame")
	p.Name = "ConfirmPanel"
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.Position = UDim2.fromScale(0.5, 0.5)
	p.Size = UDim2.fromScale(0.5, 0.32)
	p.BackgroundColor3 = (Theme and Theme.COLORS and Theme.COLORS.PanelBg) or Color3.fromRGB(245,245,245)
	p.BorderSizePixel = 0
	p.ZIndex = 1001
	p.Parent = overlay
	do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,12); c.Parent=p end
	do local s=Instance.new("UIStroke");  s.Thickness=1; s.Parent=p end

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Text = T(Locale, lang, "RUN_GIVEUP_TITLE", "このランをあきらめますか？", "Abandon this run?")
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.Size = UDim2.fromScale(1, 0.34)
	title.Position = UDim2.fromScale(0, 0.06)
	title.ZIndex = 1002
	title.Parent = p

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.TextWrapped = true
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Text = T(Locale, lang, "RUN_GIVEUP_BODY",
		"途中の記録は削除され、ホームに戻ります。次回はNEW GAMEから開始します。",
		"Your in-run progress will be deleted. You'll return to Home and start from NEW GAME.")
	body.Font = Enum.Font.Gotham
	body.TextScaled = true
	body.Size = UDim2.fromScale(1, 0.36)
	body.Position = UDim2.fromScale(0, 0.40)
	body.ZIndex = 1002
	body.Parent = p

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(1,1)
	row.Size = UDim2.fromScale(0.92, 0.20)
	row.Position = UDim2.fromScale(0.96, 0.96)
	row.ZIndex = 1002
	row.Parent = p

	local yes = Instance.new("TextButton")
	yes.Size = UDim2.fromScale(0.48, 1)
	yes.TextScaled = true
	yes.Font = Enum.Font.GothamBold
	yes.BackgroundColor3 = (Theme and Theme.COLORS and Theme.COLORS.WarnBtnBg) or Color3.fromRGB(180,50,50)
	yes.TextColor3 = (Theme and Theme.COLORS and Theme.COLORS.TextOnPrimary) or Color3.fromRGB(255,255,255)
	yes.Text = T(Locale, lang, "RUN_CONFIRM_YES", "はい", "YES")
	yes.ZIndex = 1003
	yes.Parent = row
	do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=yes end

	local no = yes:Clone()
	no.Name = "No"
	no.Position = UDim2.fromScale(0.52, 0)
	no.Text = T(Locale, lang, "RUN_CONFIRM_NO", "いいえ", "NO")
	no.BackgroundColor3 = (Theme and Theme.COLORS and Theme.COLORS.InfoBtnBg) or Color3.fromRGB(60,60,60)
	no.Parent = row

	yes.MouseButton1Click:Connect(function()
		M.close(parent)
		if typeof(onYes)=="function" then onYes() end
	end)
	no.MouseButton1Click:Connect(function() M.close(parent) end)
end

return M
