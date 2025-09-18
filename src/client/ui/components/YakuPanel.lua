-- src/client/ui/components/YakuPanel.lua
-- v0.9.7b 役倍率ビュー（前面ポップアップ／開閉API）
-- 変更点:
--  ・Client側で RunDeckUtil を使って祭事Lvを“初期化”しないよう修正
--  ・StatePushの payload に入ってきた matsuri を優先し、未同梱時は既存値を保持
--  ・四光の表示説明を現仕様へ更新（雨四区別なし／任意の光4枚で四光、基礎8文）

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local Scoring       = require(RS:WaitForChild("SharedModules"):WaitForChild("Scoring"))
-- ★不要化：RunDeckUtil 経由での読み出しは初期化を誘発するため使用しない
-- local RunDeckUtil   = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))
local CardImageMap  = require(RS:WaitForChild("SharedModules"):WaitForChild("CardImageMap"))

local Config = RS:FindFirstChild("Config")
local Theme  = Config and Config:FindFirstChild("Theme") and require(Config.Theme)

local YakuPanel = {}
YakuPanel.__index = YakuPanel

--==============================
-- レイアウト定数
--==============================
-- 左のアイコン域を右寄せにして、その右に「×N」→ 役名+基本表記 → Lv → 文×点
local ICON_AREA_W = 120     -- 96→120 に拡張（横幅拡張に合わせ余裕を確保）
local REQTEXT_W   = 48      -- 「×N」テキストの幅（42→48）
local NAME_X      = ICON_AREA_W + 8 + REQTEXT_W + 14 -- 役名の開始X

--==============================
-- 表示順（UI専用の「四光」を含む）
--==============================
local YAKU_CATALOG = {
	{ id="yaku_goko",        nameJP="五光",           nameEN="Five Bright",        iconCodes={"0101","0301","0801","1101","1201"}, reqText="" },
	{ id="yaku_yonko",       nameJP="四光",           nameEN="Four Bright",        iconCodes={"0101"},   reqText="×4" }, -- UIのみ（祭事なし）
	{ id="yaku_sanko",       nameJP="三光",           nameEN="Three Bright",       iconCodes={"0101"},   reqText="×3" },
	{ id="yaku_hanami",      nameJP="花見で一杯",     nameEN="Hanami with Sake",   iconCodes={"0301","0901"}, reqText="" },
	{ id="yaku_tsukimi",     nameJP="月見で一杯",     nameEN="Tsukimi with Sake",  iconCodes={"0801","0901"}, reqText="" },
	{ id="yaku_inoshikacho", nameJP="猪鹿蝶",         nameEN="Inoshikachō",        iconCodes={"0701","1001","0601"}, reqText="" },
	{ id="yaku_tane",        nameJP="タネ",           nameEN="Seeds",              iconCodes={"0201"},   reqText="×5" },
	{ id="yaku_tanzaku",     nameJP="短冊",           nameEN="Tanzaku",            iconCodes={"0202"},   reqText="×5" },
	{ id="yaku_kasu",        nameJP="カス",           nameEN="Kasu",               iconCodes={"0103"},   reqText="×10" },
}

--==============================
-- 基本点（基礎の「文」）と閾値/超過の説明
-- ※ Scoring.lua の ROLE_MON に合わせる
--==============================
local BASE_INFO = {
	-- 光系
	yaku_goko        = { base = 10 },  -- 五光
	-- ★更新：雨四の区別をしない現仕様。任意4枚で四光＝基礎8文（注記なし）
	yaku_yonko       = { base =  8 },  -- 四光
	yaku_sanko       = { base =  5 },  -- 三光

	-- 役もの
	yaku_hanami      = { base =  5 },
	yaku_tsukimi     = { base =  5 },
	yaku_inoshikacho = { base =  5 },

	-- 枚数系（閾値超過で +1文/枚）
	yaku_tane        = { base =  1, threshold = 5  },
	yaku_tanzaku     = { base =  1, threshold = 5  },
	yaku_kasu        = { base =  1, threshold = 10 },
}

--==============================
-- ユーティリティ
--==============================
local function getLang(state)
	local lang = "ja"
	if typeof(state)=="table" and state.lang then lang = state.lang end
	return (lang=="en") and "en" or "ja"
end

-- ★修正：payload（StatePush）に同梱された値のみを読む。無いときは nil を返す。
local function getMatsuriLevelsFromPayload(state)
	if typeof(state) ~= "table" then return nil end
	-- 推奨：フラット（StatePush: payload.matsuri）
	if typeof(state.matsuri) == "table" then
		return state.matsuri
	end
	-- 保険：ネスト（state.run.meta.matsuriLevels）が来ている場合
	local run  = state.run
	local meta = run and run.meta
	local lv   = meta and meta.matsuriLevels
	if typeof(lv) == "table" then
		return lv
	end
	-- 未同梱（nilで返す）→ 呼び出し側で「上書きしない」
	return nil
end

local function t(lang, jp, en) return (lang=="en") and (en or jp) or jp end

-- 役名のあとに付ける「（基本点＋超過ルール）」テキスト
local function buildBaseSuffix(lang, yakuId)
	local info = BASE_INFO[yakuId]
	if not info then return "" end

	-- 基本点
	local basePart = (lang=="en") and ("base "..tostring(info.base).." mon") or ("基本"..tostring(info.base).."文")

	-- 超過ルール（ある場合）
	local extraPart = ""
	if info.threshold then
		if lang=="en" then
			extraPart = string.format("; +1 per card over %d", info.threshold)
		else
			extraPart = string.format("／%d枚超過ごとに+1文", info.threshold)
		end
	end

	-- 備考（※現仕様で四光は注記なし）
	local note = ""
	if info.noteJP or info.noteEN then
		note = (lang=="en") and (" "..(info.noteEN or "")) or (" "..(info.noteJP or ""))
	end

	if lang=="en" then
		return string.format(" (%s%s)%s", basePart, extraPart, note)
	else
		return string.format("（%s%s）%s", basePart, extraPart, note)
	end
end

--==============================
-- 行生成
--==============================
local function createRow(parent, yaku)
	local row = Instance.new("Frame")
	row.Name = "Row_" .. yaku.id
	row.Size = UDim2.new(1, -10, 0, 58)
	row.BackgroundColor3 = Color3.fromRGB(30,30,30)
	do
		local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,10); rc.Parent = row
		local rs = Instance.new("UIStroke"); rs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; rs.Thickness = 1; rs.Color = Color3.fromRGB(255,255,255); rs.Transparency = 0.85; rs.Parent = row
	end

	-- アイコン列（右寄せ）
	local icons = Instance.new("Frame")
	icons.Name = "Icons"
	icons.Size = UDim2.new(0, ICON_AREA_W, 1, 0)
	icons.BackgroundTransparency = 1
	icons.Parent = row

	local iconsLayout = Instance.new("UIListLayout")
	iconsLayout.FillDirection = Enum.FillDirection.Horizontal
	iconsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	iconsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	iconsLayout.Padding = UDim.new(0, 4)
	iconsLayout.Parent = icons

	-- 「×N」テキスト（任意）
	local reqTextLabel: TextLabel? = nil
	if yaku.reqText and yaku.reqText ~= "" then
		reqTextLabel = Instance.new("TextLabel")
		reqTextLabel.Name = "ReqText"
		reqTextLabel.AnchorPoint = Vector2.new(0, 0.5)
		reqTextLabel.Position = UDim2.new(0, ICON_AREA_W + 8, 0.5, 0)
		reqTextLabel.Size = UDim2.fromOffset(REQTEXT_W, 22)
		reqTextLabel.BackgroundTransparency = 1
		reqTextLabel.Text = tostring(yaku.reqText)
		reqTextLabel.Font = Enum.Font.Gotham
		reqTextLabel.TextSize = 14
		reqTextLabel.TextXAlignment = Enum.TextXAlignment.Left
		reqTextLabel.TextColor3 = Color3.fromRGB(230,230,230)
		reqTextLabel.ZIndex = 102
		reqTextLabel.Parent = row
	end

	-- 役名（あとに「（基本点/超過）」を付ける）
	local lblName = Instance.new("TextLabel")
	lblName.Name = "NameLabel"
	lblName.Position = UDim2.fromOffset(NAME_X, 0)
	lblName.Size = UDim2.new(0.54, 0, 1, 0) -- 横幅拡張に合わせて広げる
	lblName.TextXAlignment = Enum.TextXAlignment.Left
	lblName.TextYAlignment = Enum.TextYAlignment.Center
	lblName.Font = Enum.Font.Gotham
	lblName.TextSize = 16
	lblName.TextColor3 = Color3.fromRGB(255,255,255)
	lblName.BackgroundTransparency = 1
	lblName.Parent = row

	-- Lv 合計
	local lblLv = Instance.new("TextLabel")
	lblLv.Name = "LevelLabel"
	lblLv.Position = UDim2.new(0.70, 0, 0, 0) -- 右に寄せる（全体横幅拡張に対応）
	lblLv.Size = UDim2.new(0.10, 0, 1, 0)
	lblLv.TextXAlignment = Enum.TextXAlignment.Center
	lblLv.Font = Enum.Font.Gotham
	lblLv.TextSize = 16
	lblLv.TextColor3 = Color3.fromRGB(230,230,230)
	lblLv.BackgroundTransparency = 1
	lblLv.Parent = row

	-- 文×点（祭事で加わる加点の合計）
	local lblStat = Instance.new("TextLabel")
	lblStat.Name = "StatLabel"
	lblStat.Position = UDim2.new(0.80, 0, 0, 0)
	lblStat.Size = UDim2.new(0.20, 0, 1, 0)
	lblStat.TextXAlignment = Enum.TextXAlignment.Right
	lblStat.Font = Enum.Font.Gotham
	lblStat.TextSize = 16
	lblStat.TextColor3 = Color3.fromRGB(230,230,230)
	lblStat.BackgroundTransparency = 1
	lblStat.Parent = row

	-- アイコン描画
	local added = 0
	for _, code in ipairs(yaku.iconCodes or {}) do
		local imgId = CardImageMap.get(code)
		if imgId then
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.Size = UDim2.fromOffset(18,26)
			img.Image = imgId
			img.Parent = icons
			added += 1
		end
	end
	if added == 0 and Theme and Theme.IMAGES and Theme.IMAGES[yaku.id] then
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromOffset(18,26)
		img.Image = Theme.IMAGES[yaku.id]
		img.Parent = icons
		added = 1
	end
	if added == 0 then
		local txt = Instance.new("TextLabel")
		txt.BackgroundTransparency = 1
		txt.Size = UDim2.fromOffset(24,24)
		txt.Text = "—"
		txt.Font = Enum.Font.Gotham
		txt.TextSize = 12
		txt.TextColor3 = Color3.fromRGB(150,150,150)
		txt.Parent = icons
	end

	row.Parent = parent
	return row, {
		nameLabel = lblName,
		lvLabel   = lblLv,
		statLabel = lblStat,
		reqText   = reqTextLabel,
	}
end

--==============================
-- mount
--==============================
function YakuPanel.mount(parentGui)
	local self = setmetatable({}, YakuPanel)

	local parent = parentGui
	if not parent or not parent:IsA("Instance") then
		parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end

	-- 前面に出す（RunScreen.DisplayOrder=10 より上）
	local rootGui = Instance.new("ScreenGui")
	rootGui.Name = "YakuPanel"
	rootGui.ResetOnSpawn = false
	rootGui.IgnoreGuiInset = true
	rootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	rootGui.DisplayOrder = 100
	rootGui.Parent = parent
	self._root = rootGui

	-- オーバーレイ
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Visible = false
	overlay.BackgroundColor3 = Color3.new(0,0,0)
	overlay.BackgroundTransparency = 0.38
	overlay.Size = UDim2.fromScale(1,1)
	overlay.ZIndex = 100
	overlay.Parent = rootGui
	self._overlay = overlay

	-- カード：横幅を 540→756（約1.4倍）に拡張
	local card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5,0.5)
	card.Position = UDim2.fromScale(0.5,0.5)
	card.Size = UDim2.fromOffset(756, 600) -- height 少しゆとり
	card.Parent = overlay
	card.BackgroundColor3 = Color3.fromRGB(24,24,24)
	card.ZIndex = 101
	do
		local uic = Instance.new("UICorner"); uic.CornerRadius = UDim.new(0,16); uic.Parent = card
		local stroke = Instance.new("UIStroke"); stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke.Color = Color3.fromRGB(255,255,255); stroke.Transparency = 0.7; stroke.Thickness = 1; stroke.Parent = card
	end

	-- タイトルバー
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1,0,0,44)
	titleBar.Parent = card
	titleBar.BackgroundColor3 = Color3.fromRGB(18,18,18)
	titleBar.ZIndex = 102
	do local tUic = Instance.new("UICorner"); tUic.CornerRadius = UDim.new(0,16); tUic.Parent = titleBar end

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1,-44,1,0)
	titleLabel.Position = UDim2.fromOffset(16,0)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = "役の倍率一覧"
	titleLabel.Font = Enum.Font.Gotham
	titleLabel.TextSize = 18
	titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
	titleLabel.BackgroundTransparency = 1
	titleLabel.ZIndex = 103
	titleLabel.Parent = titleBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.Size = UDim2.fromOffset(32,32)
	closeBtn.Position = UDim2.new(1,-40,0,6)
	closeBtn.Text = "×"
	closeBtn.Font = Enum.Font.Gotham
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = Color3.fromRGB(230,230,230)
	closeBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
	closeBtn.ZIndex = 103
	closeBtn.Parent = titleBar
	do local cUic = Instance.new("UICorner"); cUic.CornerRadius = UDim.new(0,10); cUic.Parent = closeBtn end

	-- スクロール
	local listArea = Instance.new("ScrollingFrame")
	listArea.Name = "List"
	listArea.Position = UDim2.fromOffset(0, 50)
	listArea.Size = UDim2.new(1,0,1,-50)
	listArea.CanvasSize = UDim2.fromOffset(0,0)
	listArea.ScrollBarThickness = 6
	listArea.Parent = card
	listArea.BackgroundTransparency = 1
	listArea.ZIndex = 101

	local uiList = Instance.new("UIListLayout")
	uiList.FillDirection = Enum.FillDirection.Vertical
	uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uiList.VerticalAlignment   = Enum.VerticalAlignment.Top
	uiList.Padding = UDim.new(0, 8)
	uiList.SortOrder = Enum.SortOrder.LayoutOrder
	uiList.Parent = listArea

	local uiPad = Instance.new("UIPadding")
	uiPad.PaddingLeft = UDim.new(0, 10)
	uiPad.PaddingRight = UDim.new(0, 10)
	uiPad.PaddingTop = UDim.new(0, 10)
	uiPad.PaddingBottom = UDim.new(0, 12)
	uiPad.Parent = listArea

	self._titleLabel = titleLabel
	self._listArea   = listArea
	self._uiList     = uiList

	self._rows    = {}
	self._rowRefs = {}

	for idx, y in ipairs(YAKU_CATALOG) do
		local row, refs = createRow(listArea, y)
		row.ZIndex = 101
		row.LayoutOrder = idx
		self._rows[y.id]    = row
		self._rowRefs[y.id] = refs
	end

	local function refreshCanvas()
		listArea.CanvasSize = UDim2.new(0,0,0, self._uiList.AbsoluteContentSize.Y + 24)
	end
	self._uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)
	refreshCanvas()

	closeBtn.MouseButton1Click:Connect(function() self:close() end)
	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local pos = input.Position
			local p = card.AbsolutePosition
			local s = card.AbsoluteSize
			if pos.X < p.X or pos.X > p.X + s.X or pos.Y < p.Y or pos.Y > p.Y + s.Y then
				self:close()
			end
		end
	end)

	self._state = { lang="ja", matsuri={} }
	self:_redraw()

	return self
end

function YakuPanel:open()  if self._overlay then self._overlay.Visible = true end end
function YakuPanel:close() if self._overlay then self._overlay.Visible = false end end

function YakuPanel:update(state)
	if typeof(state) ~= "table" then return end
	self._state.lang = getLang(state)

	-- ★重要: matsuri が payload に含まれているときだけ更新（未同梱なら保持）
	local lv = getMatsuriLevelsFromPayload(state)
	if lv then
		self._state.matsuri = lv
	end

	self:_redraw()
end

function YakuPanel:destroy()
	if self._root then self._root:Destroy() end
end

--==============================
-- 再描画（数値は Scoring の計算に準拠）
--==============================
function YakuPanel:_redraw()
	local lang = getLang(self._state)
	self._titleLabel.Text = t(lang, "役の倍率一覧", "Yaku Multipliers")

	for _, y in ipairs(YAKU_CATALOG) do
		local refs = self._rowRefs[y.id]
		if refs and refs.nameLabel and refs.lvLabel and refs.statLabel then
			-- 役名 + （基本点／超過ルール）
			local nameCore = (lang=="en") and (y.nameEN or y.nameJP) or y.nameJP
			local suffix   = buildBaseSuffix(lang, y.id)
			refs.nameLabel.Text = nameCore .. suffix

			if refs.reqText then refs.reqText.Text = tostring(y.reqText or "") end

			-- Scoring 側に未登録の yaku（UI-only の四光など）は空配列
			local fests = (typeof(Scoring.getFestivalsForYaku)=="function" and Scoring.getFestivalsForYaku(y.id)) or {}
			if typeof(fests) ~= "table" then fests = {} end

			local lvSum, addMonSum, addPtsSum = 0, 0, 0
			for _, fid in ipairs(fests) do
				local lv = tonumber(self._state.matsuri[fid] or 0) or 0
				local addMon, addPts = 0, 0
				if typeof(Scoring.getFestivalStat)=="function" then
					addMon, addPts = Scoring.getFestivalStat(fid, lv) -- Scoring準拠
				end
				lvSum     += lv
				addMonSum += (addMon or 0)
				addPtsSum += (addPts or 0)
			end

			refs.lvLabel.Text   = ("Lv%d"):format(lvSum)
			refs.statLabel.Text = (lang=="en")
				and (("%d mon × %d pts"):format(addMonSum, addPtsSum))
				or  (("%d文 × %d点"):format(addMonSum, addPtsSum))
		end
	end
end

return YakuPanel
