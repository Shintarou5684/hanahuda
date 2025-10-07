-- StarterPlayerScripts/UI/components/renderers/KitoPickRenderer.lua
-- v1.4.2 (Overlay Z fix + bigger info text)
--  - 対象外オーバーレイの ZIndex をカード基準で強制的に最前面へ
--  - 情報行（◯月/種族 名前）の MaxTextSize は v1.4.1 同様 24px 既定
--  - API: create(playerGui) -> { gui, show, hide, renderCard, setCardSelected }

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

--───────────────────────── ユーティリティ（表示用） ─────────────────────────
local MONTH_JP = { "1月","2月","3月","4月","5月","6月","7月","8月","9月","10月","11月","12月" }
local CARD_AR  = 0.62 -- 花札のアスペクト（幅/高さ）の目安

local function parseMonth(entry)
	if not entry then return nil end
	local m = tonumber(entry.month or (entry.meta and entry.meta.month))
	if m and m >= 1 and m <= 12 then return m end
	local s = tostring(entry.code or entry.uid or "")
	local two = string.match(s, "^(%d%d)")
	m = tonumber(two); if m and m >= 1 and m <= 12 then return m end
	return nil
end

local function kindToJp(k)
	local map = { bright="光", ribbon="短", seed="タネ", chaff="カス", plain="カス", animal="タネ" }
	return map[tostring(k or ""):lower()] or tostring(k or "?")
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

-- 色の既定値（Styles があれば上書き）
local COLOR = {
	slotBg       = Color3.fromRGB(40, 42, 54),
	slotStroke   = Color3.fromRGB(64, 68, 80),
	textMain     = Color3.fromRGB(232,232,240),
	textSub      = Color3.fromRGB(210,210,220),
	imgFallback  = Color3.fromRGB(55,57,69),
	overlayEdge  = Color3.fromRGB(230,230,240),
	selectStroke = Color3.fromRGB(255,210,110),
}
do
	local C = Styles and Styles.colors or {}
	COLOR.slotBg       = C.cardBg          or COLOR.slotBg
	COLOR.slotStroke   = C.cardStroke      or COLOR.slotStroke
	COLOR.textMain     = C.cardNameText    or COLOR.textMain
	COLOR.textSub      = C.cardInfoText    or COLOR.textSub
	COLOR.imgFallback  = C.cardImgFallback or COLOR.imgFallback
	COLOR.overlayEdge  = C.ineligibleTitle or COLOR.overlayEdge
	COLOR.selectStroke = C.selectedStroke  or COLOR.selectStroke
end

--────────────────────────────── 本体 ──────────────────────────────
function M.create(playerGui: Instance)
	assert(playerGui and playerGui:IsA("PlayerGui"), "create(playerGui): PlayerGui expected")

	local gui = Instance.new("ScreenGui")
	gui.Name           = "KitoPickGui"
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	gui.IgnoreGuiInset = true
	gui.DisplayOrder   = 50
	gui.Enabled        = false
	gui.Parent         = playerGui

	local api = { gui = gui }
	function api.show() gui.Enabled = true end
	function api.hide() gui.Enabled = false end

	--──────────────── セル（カード）生成 ────────────────
	-- ent: { uid, code, name, kind, month, image?/imageId?, eligible?, reason? }
	function api.renderCard(parent: Instance, ent: table): Instance
		assert(parent and parent:IsA("Instance"), "renderCard: invalid parent")
		assert(type(ent) == "table", "renderCard: ent must be table")

		local S = (Styles and Styles.sizes) or {}
		local F = (Styles and Styles.fontSizes) or {}
		local Z = (Styles and Styles.z) or {}

		-- ルート（灰スロット）
		local card = Instance.new("TextButton")
		card.Name                   = tostring(ent.uid or ent.code or "card")
		card.AutoButtonColor        = true
		card.BackgroundColor3       = COLOR.slotBg
		card.BackgroundTransparency = 0.05
		card.BorderSizePixel        = 0
		card.Size                   = UDim2.fromScale(1,1) -- Grid 側でサイズ管理
		card.Text                   = ""
		card.ZIndex                 = 10
		card.Parent                 = parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, S.btnCorner or 12)
		corner.Parent = card

		local stroke = Instance.new("UIStroke")
		stroke.Name = "SelStroke"
		stroke.Thickness = 3
		stroke.Color = COLOR.selectStroke
		stroke.Enabled = false
		stroke.Parent = card

		-- 画像：セル中央フィット（高さ優先・等比）
		local img = Instance.new("ImageLabel")
		img.Name                   = "Thumb"
		img.BackgroundTransparency = 1
		img.BorderSizePixel        = 0
		img.ScaleType              = Enum.ScaleType.Fit
		img.AnchorPoint            = Vector2.new(0.5, 0.5)
		img.Position               = UDim2.fromScale(0.5, 0.50)
		img.Size                   = UDim2.fromScale(1, 0.82)
		img.ZIndex                 = 12
		img.Parent                 = card
		local ar = Instance.new("UIAspectRatioConstraint")
		ar.AspectRatio  = 0.62
		ar.DominantAxis = Enum.DominantAxis.Height
		ar.Parent = img

		local src = resolveImage(ent)
		if src then
			img.Image = src
		else
			img.Image = ""
			img.BackgroundTransparency = 0
			img.BackgroundColor3 = COLOR.imgFallback
		end

		-- 左下インフォ（「◯月/種族 名前」を1行）
		local info = Instance.new("TextLabel")
		info.Name                   = "Info"
		info.BackgroundTransparency = 1
		info.TextXAlignment         = Enum.TextXAlignment.Left
		info.TextYAlignment         = Enum.TextYAlignment.Bottom
		info.AnchorPoint            = Vector2.new(0,1)
		info.Position               = UDim2.fromScale(0, 1)
		info.Size                   = UDim2.fromScale(1, 0.22)
		info.Font                   = Enum.Font.Gotham
		info.TextColor3             = COLOR.textMain
		info.TextScaled             = true
		info.TextWrapped            = false
		info.LineHeight             = 1
		info.TextTruncate           = Enum.TextTruncate.AtEnd
		info.ZIndex                 = 14
		local lim = Instance.new("UITextSizeConstraint")
		lim.MaxTextSize = (F.cardInfoMax or F.cardInfo or 24) -- ★ 情報行の上限フォント（既定24px）
		lim.Parent = info
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft   = UDim.new(0, 10)
		pad.PaddingBottom = UDim.new(0, 8)
		pad.Parent = info
		do
			local m = parseMonth(ent)
			local monthText = m and MONTH_JP[m] or "?月"
			local kindText  = kindToJp(ent.kind)
			local nameText  = tostring(ent.name or ent.code or ent.uid or "?")
			info.Text = string.format("%s/%s %s", monthText, kindText, nameText)
		end
		info.Parent = card

		-- 不可選オーバーレイ（常に最前面へ）
		local canPick = (ent.eligible ~= false)
		card:SetAttribute("canPick", canPick)
		card:SetAttribute("reason", ent.reason or "")
		if not canPick then
			card.AutoButtonColor = false

			-- ★ ZIndex をカード基準で強制的に最前面に
			local OVERLAY_Z = (card.ZIndex or 0) + 100

			local mask = Instance.new("Frame")
			mask.Name = "IneligibleMask"
			mask.BackgroundColor3 = Color3.new(0,0,0)
			mask.BackgroundTransparency = 0.45
			mask.BorderSizePixel = 0
			mask.Size = UDim2.fromScale(1,1)
			mask.ZIndex = OVERLAY_Z
			mask.Active = false -- 入力はボタンへ通す
			mask.Parent = card

			local tag = Instance.new("TextLabel")
			tag.BackgroundTransparency = 1
			tag.Size = UDim2.fromScale(1,0)
			tag.Position = UDim2.fromScale(0,0.44)
			tag.Text = "対象外"
			tag.Font = Enum.Font.GothamBold
			tag.TextScaled = true
			tag.TextColor3 = COLOR.overlayEdge
			tag.ZIndex = OVERLAY_Z + 1
			local tl = Instance.new("UITextSizeConstraint")
			tl.MaxTextSize = ((Styles and Styles.fontSizes and Styles.fontSizes.inelMain) or 22)
			tl.Parent = tag
			tag.Parent = mask

			if ent.reason and ent.reason ~= "" then
				local sub = Instance.new("TextLabel")
				sub.BackgroundTransparency = 1
				sub.Size = UDim2.fromScale(1,0)
				sub.Position = UDim2.fromScale(0,0.62)
				sub.Text = reasonToText(ent.reason) or tostring(ent.reason)
				sub.Font = Enum.Font.Gotham
				sub.TextScaled = true
				sub.TextColor3 = COLOR.overlayEdge
				sub.ZIndex = OVERLAY_Z + 1
				local sl = Instance.new("UITextSizeConstraint")
				sl.MaxTextSize = ((Styles and Styles.fontSizes and Styles.fontSizes.inelSub) or 16)
				sl.Parent = sub
				sub.Parent = mask
			end
		end

		return card
	end

	-- 選択ハイライト（枠だけ光らせる）
	function api.setCardSelected(btn: Instance, sel: boolean)
		if not (btn and btn:IsA("GuiObject")) then return end
		local stroke = btn:FindFirstChild("SelStroke")
		if stroke and stroke:IsA("UIStroke") then
			stroke.Enabled = sel and true or false
		end
	end

	LOG.info("KitoPickRenderer ready")
	return api
end

return M
