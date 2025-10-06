-- KitoPickRenderer.lua
-- v1.3.0: 最小責務の Renderer（create / renderCard / setCardSelected / show / hide）
-- API: create(playerGui) -> { gui, show, hide, renderCard, setCardSelected }

local RS     = game:GetService("ReplicatedStorage")
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("KitoPickRenderer")

-- Styles（存在しなくても動くようにガード）
local Styles do
	local ok, mod = pcall(function()
		return require(script.Parent.Parent.Parent
			:WaitForChild("styles")
			:WaitForChild("KitoPickStyles"))
	end)
	Styles = ok and mod or nil
end

local M = {}

-- ───────────────── 内部ヘルパ（見た目用の最小限）
local MONTH_JP = { "1月","2月","3月","4月","5月","6月","7月","8月","9月","10月","11月","12月" }

local function parseMonth(entry)
	if not entry then return nil end
	local m = tonumber(entry.month or (entry.meta and entry.meta.month))
	if m and m >= 1 and m <= 12 then return m end
	local s = tostring(entry.code or entry.uid or "")
	local two = string.match(s, "^(%d%d)")
	if not two then return nil end
	m = tonumber(two)
	if m and m >= 1 and m <= 12 then return m end
	return nil
end

local function kindToJp(k)
	local map = { bright="光札", ribbon="短冊", seed="タネ", chaff="カス" }
	return map[tostring(k or "")] or tostring(k or "?")
end

local function reasonToText(reason)
	local map = {
		["already-applied"]     = "既に適用済みです",
		["already-bright"]      = "すでに光札です",
		["already-chaff"]       = "すでにカス札です",
		["month-has-no-bright"] = "この月に光札はありません",
		["not-eligible"]        = "対象外です",
		["same-target"]         = "同一カードは選べません",
		["no-check"]            = "対象外（サーバ判定なし）",
	}
	return map[tostring(reason or "")] or nil
end

local function resolveImage(entry)
	if entry.image and type(entry.image) == "string" and #entry.image > 0 then
		return entry.image
	end
	if entry.imageId then
		return "rbxassetid://" .. tostring(entry.imageId)
	end
	return nil
end

-- ───────────────── 本体
function M.create(playerGui: Instance)
	assert(playerGui and playerGui:IsA("PlayerGui"), "create(playerGui): PlayerGui expected")

	local gui = Instance.new("ScreenGui")
	gui.Name            = "KitoPickGui"
	gui.ResetOnSpawn    = false
	gui.ZIndexBehavior  = Enum.ZIndexBehavior.Global
	gui.IgnoreGuiInset  = true
	gui.DisplayOrder    = 50
	gui.Enabled         = false
	gui.Parent          = playerGui

	local api = { gui = gui }

	function api.show()  gui.Enabled = true  end
	function api.hide()  gui.Enabled = false end

	-- カード生成（View から直接呼ばれる）
	function api.renderCard(parent: Instance, ent: table): Instance
		assert(parent and parent:IsA("Instance"), "renderCard: invalid parent")
		assert(type(ent) == "table", "renderCard: ent must be table")

		local S = (Styles and Styles.sizes) or {}
		local C = (Styles and Styles.colors) or {}
		local F = (Styles and Styles.fontSizes) or {}
		local Z = (Styles and Styles.z) or {}

		local card = Instance.new("TextButton")
		card.Name                   = tostring(ent.uid or ent.code or "card")
		card.AutoButtonColor        = true
		card.BackgroundColor3       = C.cardBg or Color3.fromRGB(40,42,54)
		card.BackgroundTransparency = 0.05
		card.BorderSizePixel        = 0
		card.Size                   = UDim2.fromOffset(S.gridCellW or 180, S.gridCellH or 160)
		card.Text                   = ""
		card.Parent                 = parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, S.btnCorner or 10)
		corner.Parent = card

		local stroke = Instance.new("UIStroke")
		stroke.Name = "SelStroke"
		stroke.Thickness = 2
		stroke.Color = C.selectedStroke or Color3.fromRGB(90,130,230)
		stroke.Enabled = false
		stroke.Parent = card

		local img = Instance.new("ImageLabel")
		img.Name                   = "Thumb"
		img.Size                   = UDim2.fromOffset(S.gridCellW or 180, S.cardImgH or 112)
		img.Position               = UDim2.new(0,0,0,0)
		img.BackgroundTransparency = 1
		img.BorderSizePixel        = 0
		img.ScaleType              = Enum.ScaleType.Fit
		img.Parent                 = card

		local src = resolveImage(ent)
		if src then
			img.Image = src
		else
			img.BackgroundTransparency = 0
			img.BackgroundColor3 = C.cardImgFallback or Color3.fromRGB(55,57,69)
			img.Image = ""
		end

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name                   = "Name"
		nameLabel.Text                   = tostring(ent.name or ent.code or ent.uid or "?")
		nameLabel.Font                   = Enum.Font.Gotham
		nameLabel.TextSize               = F.cardName or 16
		nameLabel.TextColor3             = C.cardNameText or Color3.fromRGB(232,232,240)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Size                   = UDim2.new(1, -10, 0, S.cardNameH or 18)
		nameLabel.Position               = UDim2.new(0, S.cardNameLeft or 6, 0, (S.cardImgH or 112) + (S.cardNameTopGap or 4))
		nameLabel.TextXAlignment         = Enum.TextXAlignment.Left
		nameLabel.Parent                 = card

		local m = parseMonth(ent)
		local infoText = ((m and MONTH_JP[m]) or "?月") .. " / " .. kindToJp(ent.kind)
		local info = Instance.new("TextLabel")
		info.Name                   = "Info"
		info.Text                   = infoText
		info.Font                   = Enum.Font.Gotham
		info.TextSize               = F.cardInfo or 14
		info.TextColor3             = C.cardInfoText or Color3.fromRGB(210,210,220)
		info.BackgroundTransparency = 1
		info.Size                   = UDim2.new(1, -10, 0, S.cardInfoH or 16)
		info.Position               = UDim2.new(0, S.cardInfoLeft or 6, 0, (S.gridCellH or 160) - (S.cardInfoH or 16) - (S.cardInfoBottomGap or 8))
		info.TextXAlignment         = Enum.TextXAlignment.Left
		info.Parent                 = card

		-- 対象外オーバーレイ
		local canPick = (ent.eligible ~= false)
		card:SetAttribute("canPick", canPick)
		card:SetAttribute("reason", ent.reason or "")
		if not canPick then
			card.AutoButtonColor = false

			local mask = Instance.new("Frame")
			mask.Name = "IneligibleMask"
			mask.BackgroundColor3 = C.ineligibleMask or Color3.new(0,0,0)
			mask.BackgroundTransparency = 0.45
			mask.BorderSizePixel = 0
			mask.Size = UDim2.fromScale(1,1)
			mask.ZIndex = Z.overlay or 5
			mask.Parent = card

			local tag = Instance.new("TextLabel")
			tag.BackgroundTransparency = 1
			tag.Size = UDim2.fromScale(1,0)
			tag.Position = UDim2.fromScale(0,0.45)
			tag.Text = "対象外"
			tag.Font = Enum.Font.GothamBold
			tag.TextSize = F.inelMain or 18
			tag.TextColor3 = C.ineligibleTitle or Color3.fromRGB(230,230,240)
			tag.ZIndex = Z.overlayText or 6
			tag.Parent = mask

			if ent.reason and ent.reason ~= "" then
				local sub = Instance.new("TextLabel")
				sub.BackgroundTransparency = 1
				sub.Size = UDim2.fromScale(1,0)
				sub.Position = UDim2.fromScale(0,0.65)
				sub.Text = reasonToText(ent.reason) or tostring(ent.reason)
				sub.Font = Enum.Font.Gotham
				sub.TextSize = F.inelSub or 14
				sub.TextColor3 = C.ineligibleSub or Color3.fromRGB(220,220,230)
				sub.ZIndex = Z.overlayText or 6
				sub.Parent = mask
			end
		end

		return card
	end

	function api.setCardSelected(btn: Instance, sel: boolean)
		if not (btn and btn:IsA("GuiObject")) then return end
		local C = (Styles and Styles.colors) or {}
		btn.BackgroundColor3 = sel and (C.selectedBg or Color3.fromRGB(70,110,210))
		                        or (C.cardBg     or Color3.fromRGB(40,42,54))
		local stroke = btn:FindFirstChild("SelStroke")
		if stroke and stroke:IsA("UIStroke") then
			stroke.Enabled = sel
		end
	end

	LOG.info("KitoPickRenderer ready")
	return api
end

return M
