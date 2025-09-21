-- src/client/ui/screens/KitoPickView.lua
-- 目的: KitoPick の12枚一覧UI・効果説明＋カード画像＆情報表示・確定／スキップ
-- 仕様: KitoPickWires の ClientSignals を購読し、シグナル受信時に Router 経由で表示
-- 方針: 「選択可否の真実はサーバ」。各候補の entry.eligible を厳守して UI でブロックする。

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local LP      = Players.LocalPlayer

-- Remotes
local Remotes  = RS:WaitForChild("Remotes")
local EvDecide = Remotes:WaitForChild("KitoPickDecide")

-- Signals from KitoPickWires（存在しなければ Wires 側で ensure 済み）
local ClientSignals = RS:WaitForChild("ClientSignals")
local SigIncoming   = ClientSignals:WaitForChild("KitoPickIncoming")
local SigResult     = ClientSignals:WaitForChild("KitoPickResult")

-- Logger
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("KitoPickView")

-- Router（ui配下）。無ければ落ちないように pcall
local UI_ROOT = script.Parent and script.Parent.Parent  -- StarterPlayerScripts/ui
local ScreenRouter = nil
pcall(function()
	if UI_ROOT then
		ScreenRouter = require(UI_ROOT:WaitForChild("ScreenRouter"))
	end
end)

-- ─────────────────────────────────────────────────────────────
-- 内部状態
-- ─────────────────────────────────────────────────────────────
local View = {} -- ScreenRouter に登録する公開I/F（このテーブルが「画面インスタンス」扱い）

local ui         -- ScreenGui
local refs = {}  -- 参照置き場（ScreenGui にフィールドは生やさない）

local current = {
	sessionId   = nil,
	targetKind  = "bright",
	list        = {},
	selectedUid = nil,
	busy        = false,   -- 決定/スキップの多重送信防止
}

-- 表示用ラベルマップ
local KIND_JP = {
	bright = "光札",
	ribbon = "短冊",
	seed   = "タネ",
	chaff  = "カス",
}
local MONTH_JP = { "1月","2月","3月","4月","5月","6月","7月","8月","9月","10月","11月","12月" }

local function parseMonth(entry)
	-- Core から渡される month を最優先 → code/uid 先頭2桁を推定
	local m = tonumber(entry.month or (entry.meta and entry.meta.month))
	if m and m>=1 and m<=12 then return m end
	local s = tostring(entry.code or entry.uid or "")
	local two = string.match(s, "^(%d%d)")
	if not two then return nil end
	m = tonumber(two)
	if m and m>=1 and m<=12 then return m end
	return nil
end

local function kindToJp(k)
	return KIND_JP[tostring(k or "")] or tostring(k or "?")
end

-- ─────────────────────────────────────────────────────────────
-- UI ビルド
-- ─────────────────────────────────────────────────────────────
local function make(text, className, props, parent)
	local inst = Instance.new(className)
	inst.Name = text
	for k,v in pairs(props or {}) do inst[k] = v end
	inst.Parent = parent
	return inst
end

local function ensureGui()
	if ui and ui.Parent then return ui end
	ui = make("KitoPickGui", "ScreenGui", {
		ResetOnSpawn    = false,
		ZIndexBehavior  = Enum.ZIndexBehavior.Global,
		IgnoreGuiInset  = true,
	}, LP:WaitForChild("PlayerGui"))

	local shade = make("Shade","Frame",{
		BackgroundColor3       = Color3.new(0,0,0),
		BackgroundTransparency = 0.35,
		Size                   = UDim2.fromScale(1,1)
	}, ui)

	local panel = make("Panel","Frame",{
		AnchorPoint         = Vector2.new(0.5,0.5),
		Position            = UDim2.fromScale(0.5,0.52),
		Size                = UDim2.fromOffset(880, 560),
		BackgroundColor3    = Color3.fromRGB(24,24,28),
		BorderSizePixel     = 0,
	}, shade)
	make("UICorner","UICorner",{CornerRadius=UDim.new(0,18)}, panel)
	make("Padding","UIPadding",{
		PaddingTop    = UDim.new(0,16),
		PaddingBottom = UDim.new(0,16),
		PaddingLeft   = UDim.new(0,16),
		PaddingRight  = UDim.new(0,16),
	}, panel)

	-- タイトル
	make("Title","TextLabel",{
		Text                   = "KITO: Pick a card",
		Font                   = Enum.Font.GothamBold,
		TextSize               = 22,
		TextColor3             = Color3.fromRGB(230,230,240),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 28),
	}, panel)

	-- 効果説明（可変長）
	local effect = make("Effect","TextLabel",{
		Text                   = "",
		Font                   = Enum.Font.Gotham,
		TextWrapped            = true,
		TextSize               = 18,
		TextColor3             = Color3.fromRGB(200,200,210),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 1), -- 高さは後で調整
		Position               = UDim2.new(0, 0, 0, 28+6),
		TextXAlignment         = Enum.TextXAlignment.Left,
	}, panel)

	local gridHolder = make("GridHolder","Frame",{
		BackgroundTransparency = 1,
		Position               = UDim2.new(0, 0, 0, 28 + 6 + 40 + 8), -- 仮（effect 実高さで後更新）
		Size                   = UDim2.new(1, 0, 1, -(28+6+40+8) - 84),
	}, panel)

	local scroll = make("Scroll","ScrollingFrame",{
		BackgroundTransparency = 1,
		CanvasSize             = UDim2.new(),
		ScrollBarThickness     = 6,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1,0,1,0),
	}, gridHolder)

	-- レイアウト専用コンテナ（固定）
	local gridFrame = make("Grid","Frame",{
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,1,0),
	}, scroll)

	-- 画像＋情報カード用
	local layout = make("UIGrid","UIGridLayout",{
		CellPadding          = UDim2.fromOffset(12,12),
		CellSize             = UDim2.fromOffset(180, 160),
		HorizontalAlignment  = Enum.HorizontalAlignment.Left,
		SortOrder            = Enum.SortOrder.LayoutOrder,
	}, gridFrame)

	local footer = make("Footer","Frame",{
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5,1),
		Position               = UDim2.new(0.5,0,1,-8),
		Size                   = UDim2.new(1, -16, 0, 52),
	}, panel)

	local pickInfo = make("PickInfo","TextLabel",{
		Text                   = "Select 1 card",
		Font                   = Enum.Font.Gotham,
		TextSize               = 18,
		TextColor3             = Color3.fromRGB(200,200,210),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, -360, 1, 0),
		TextXAlignment         = Enum.TextXAlignment.Left,
	}, footer)

	-- Skip（何も選ばない）
	local skipBtn = make("Skip","TextButton",{
		Text                   = "Skip",
		Font                   = Enum.Font.GothamBold,
		TextSize               = 20,
		TextColor3             = Color3.fromRGB(230,230,240),
		AutoButtonColor        = true,
		BackgroundColor3       = Color3.fromRGB(70,70,78),
		BackgroundTransparency = 0.05,
		Size                   = UDim2.fromOffset(140, 44),
		AnchorPoint            = Vector2.new(1,0.5),
		Position               = UDim2.new(1, -176, 0.5, 0),
	}, footer)
	make("UICorner","UICorner",{CornerRadius=UDim.new(0,10)}, skipBtn)

	-- Confirm
	local confirm = make("Confirm","TextButton",{
		Text                   = "Confirm",
		Font                   = Enum.Font.GothamBold,
		TextSize               = 20,
		TextColor3             = Color3.fromRGB(16,16,20),
		AutoButtonColor        = true,
		BackgroundColor3       = Color3.fromRGB(120,200,120),
		BackgroundTransparency = 0.0,
		Size                   = UDim2.fromOffset(160, 44),
		AnchorPoint            = Vector2.new(1,0.5),
		Position               = UDim2.new(1, -8, 0.5, 0),
	}, footer)
	make("UICorner","UICorner",{CornerRadius=UDim.new(0,10)}, confirm)

	-- 参照
	refs.effect     = effect
	refs.gridHolder = gridHolder
	refs.scroll     = scroll
	refs.gridFrame  = gridFrame
	refs.gridLayout = layout
	refs.confirm    = confirm
	refs.skipBtn    = skipBtn
	refs.pickInfo   = pickInfo

	return ui
end

-- 効果説明の高さに合わせてグリッド領域を再レイアウト
local function relayoutByEffectHeight()
	if not (refs.effect and refs.gridHolder) then return end
	local topY      = 28 + 6
	local baseBelow = 84 -- フッタ確保高さ
	local effect    = refs.effect

	-- 実高さ（TextWrapped=true → TextBounds.Y 利用）
	local needH = math.max(22, math.ceil(effect.TextBounds.Y))
	effect.Size = UDim2.new(1, 0, 0, needH)

	local gridTop  = topY + needH + 8
	refs.gridHolder.Position = UDim2.new(0, 0, 0, gridTop)
	refs.gridHolder.Size     = UDim2.new(1, 0, 1, -gridTop - baseBelow)
end

-- 画像ソースを決定（rbxassetid:// またはそのまま文字列）
local function resolveImage(entry)
	if entry.image and type(entry.image) == "string" and #entry.image>0 then
		return entry.image
	end
	if entry.imageId then
		return "rbxassetid://" .. tostring(entry.imageId)
	end
	return nil
end

-- カードの選択見た目（UIStroke で選択枠）
local function setCardSelected(btn: Instance, sel: boolean)
	if not btn or not btn:IsA("TextButton") then return end
	btn.BackgroundColor3 = sel and Color3.fromRGB(70,110,210) or Color3.fromRGB(40,42,54)
	local stroke = btn:FindFirstChild("SelStroke")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Enabled = sel
	end
end

-- 「対象外」オーバーレイ（eligible=false 用）
local function makeIneligibleOverlay(parent)
	local mask = Instance.new("Frame")
	mask.Name = "IneligibleMask"
	mask.BackgroundColor3 = Color3.new(0,0,0)
	mask.BackgroundTransparency = 0.45
	mask.BorderSizePixel = 0
	mask.Size = UDim2.fromScale(1,1)
	mask.ZIndex = 5
	mask.Parent = parent

	local tag = Instance.new("TextLabel")
	tag.BackgroundTransparency = 1
	tag.Size = UDim2.fromScale(1,1)
	tag.Text = "対象外"
	tag.Font = Enum.Font.GothamBold
	tag.TextSize = 18
	tag.TextColor3 = Color3.fromRGB(230,230,240)
	tag.ZIndex = 6
	tag.Parent = mask
end

-- カードボタン作成（画像＋情報）
local function makeCard(entry)
	local card = Instance.new("TextButton")
	card.Name                   = entry.uid
	card.AutoButtonColor        = true
	card.BackgroundColor3       = Color3.fromRGB(40,42,54)
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel        = 0
	card.Size                   = UDim2.fromOffset(180, 160)
	card.Text                   = ""
	Instance.new("UICorner", card).CornerRadius = UDim.new(0,12)

	-- 選択枠（非表示で用意）
	local stroke = Instance.new("UIStroke")
	stroke.Name = "SelStroke"
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(90,130,230)
	stroke.Enabled = false
	stroke.Parent = card

	-- 画像
	local img = Instance.new("ImageLabel")
	img.Name                   = "Thumb"
	img.Size                   = UDim2.fromOffset(180, 112)
	img.Position               = UDim2.new(0,0,0,0)
	img.BackgroundTransparency = 1
	img.BorderSizePixel        = 0
	img.ScaleType              = Enum.ScaleType.Fit
	img.Parent                 = card
	local src = resolveImage(entry)
	if src then
		img.Image = src
	else
		img.BackgroundTransparency = 0
		img.BackgroundColor3 = Color3.fromRGB(55,57,69)
	end

	-- 名称
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name                   = "Name"
	nameLabel.Text                   = tostring(entry.name or entry.code or entry.uid or "?")
	nameLabel.Font                   = Enum.Font.Gotham
	nameLabel.TextSize               = 16
	nameLabel.TextColor3             = Color3.fromRGB(232,232,240)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size                   = UDim2.new(1, -10, 0, 18)
	nameLabel.Position               = UDim2.new(0, 6, 0, 116)
	nameLabel.TextXAlignment         = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	-- 情報（例: 11月 / タネ）
	local monthNum = parseMonth(entry)
	local infoText = ((monthNum and MONTH_JP[monthNum]) or "?月") .. " / " .. kindToJp(entry.kind)
	local info = Instance.new("TextLabel")
	info.Name                    = "Info"
	info.Text                    = infoText
	info.Font                    = Enum.Font.Gotham
	info.TextSize                = 14
	info.TextColor3              = Color3.fromRGB(210,210,220)
	info.BackgroundTransparency  = 1
	info.Size                    = UDim2.new(1, -10, 0, 16)
	info.Position                = UDim2.new(0, 6, 0, 136)
	info.TextXAlignment          = Enum.TextXAlignment.Left
	info.Parent = card

	-- ★ サーバの真実: eligible を尊重
	local canPick = (entry.eligible ~= false)
	card:SetAttribute("canPick", canPick)
	if not canPick then
		card.AutoButtonColor = false
		makeIneligibleOverlay(card)
	end

	return card
end

local function setConfirmEnabled(enabled)
	if not refs.confirm then return end
	refs.confirm.Active                 = enabled
	refs.confirm.AutoButtonColor        = enabled
	refs.confirm.TextTransparency       = enabled and 0 or 0.4
	refs.confirm.BackgroundTransparency = enabled and 0.0 or 0.4
end

-- リスト再描画（選択ハイライトのみ）
local function rebuildList()
	if not ui then return end

	-- 既存カードだけ消す（レイアウトは保持）
	for _, c in ipairs(refs.gridFrame:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end

	for _, ent in ipairs(current.list or {}) do
		local b = makeCard(ent)
		b.Parent = refs.gridFrame
		setCardSelected(b, ent.uid == current.selectedUid)
		b.MouseButton1Click:Connect(function()
			if current.busy then return end

			-- ★ eligible=false はクリック無効（通知のみ）
			if b:GetAttribute("canPick") == false then
				game:GetService("StarterGui"):SetCore("SendNotification", {
					Title = "KITO",
					Text = "対象外のカードです（同種は選べません）",
					Duration = 2,
				})
				return
			end

			-- 切り替え選択
			if current.selectedUid == ent.uid then
				current.selectedUid = nil
			else
				current.selectedUid = ent.uid
			end
			-- すべてのボタンの見た目更新
			for _, c in ipairs(refs.gridFrame:GetChildren()) do
				if c:IsA("TextButton") then
					setCardSelected(c, c.Name == current.selectedUid)
				end
			end
			setConfirmEnabled(current.selectedUid ~= nil and not current.busy)
		end)
	end

	-- Canvas 自動調整
	task.defer(function()
		local content = refs.gridLayout.AbsoluteContentSize
		refs.scroll.CanvasSize = UDim2.fromOffset(content.X, content.Y)
	end)
end

-- 新規 payload 表示
local function openPayload(payload)
	current.sessionId   = payload.sessionId
	current.targetKind  = tostring(payload.targetKind or "bright")
	current.list        = payload.list or {}
	current.selectedUid = nil
	current.busy        = false

	local g = ensureGui()
	g.Enabled = true

	-- 効果説明テキスト（優先度: effect > message > note > デフォルト）
	local desc = payload.effect or payload.message or payload.note
	if not desc then
		local tgtJp = kindToJp(current.targetKind)
		desc = ("対象を選んでください（目標: %s）"):format(tgtJp)
	end
	refs.effect.Text = tostring(desc)
	relayoutByEffectHeight()

	refs.pickInfo.Text = "Select 1 card"
	setConfirmEnabled(false)
	refs.skipBtn.Active = true
	refs.skipBtn.AutoButtonColor = true
	rebuildList()

	LOG.info("[KitoPickView] open sid=%s tgt=%s list=%s",
		tostring(current.sessionId), tostring(current.targetKind), tostring(#current.list))
end

-- 決定送信（選択あり）
local function sendDecide()
	if current.busy or not current.sessionId or not current.selectedUid then return end

	-- ★ 念のため「送信前」にも eligible を二重チェック（サーバと完全同期）
	for _, e in ipairs(current.list or {}) do
		if e.uid == current.selectedUid and e.eligible == false then
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title="KITO", Text="対象外のカードです（同種は選べません）", Duration=2,
			})
			return
		end
	end

	current.busy = true
	setConfirmEnabled(false)
	refs.skipBtn.Active = false
	refs.skipBtn.AutoButtonColor = false

	EvDecide:FireServer({
		sessionId  = current.sessionId,
		uid        = current.selectedUid,
		targetKind = current.targetKind,
	})
	LOG.info("[KitoPickView] Decide sent sid=%s uid=%s tgt=%s",
		tostring(current.sessionId), tostring(current.selectedUid), tostring(current.targetKind))
end

-- スキップ送信（何も選ばない＝変更なしで確定）
local function sendSkip()
	if current.busy or not current.sessionId then return end
	current.busy = true
	setConfirmEnabled(false)
	refs.skipBtn.Active = false
	refs.skipBtn.AutoButtonColor = false

	EvDecide:FireServer({
		sessionId  = current.sessionId,
		targetKind = current.targetKind,
		noChange   = true,          -- ★ Core/Server と合意済みのフラグ
	})
	LOG.info("[KitoPickView] Skip sent sid=%s tgt=%s (noChange=true)",
		tostring(current.sessionId), tostring(current.targetKind))
end

-- 結果受信
local function onResult(res)
	if not ui then return end
	current.busy = false
	ui.Enabled = false

	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title    = res.ok and "KITO" or "KITO (failed)",
		Text     = tostring(res.message or ""),
		Duration = 3,
	})
end

-- ボタン配線
local function wireButtons()
	if not ui then return end
	refs.confirm.MouseButton1Click:Connect(sendDecide)
	refs.skipBtn.MouseButton1Click:Connect(sendSkip)
end

-- 初期化：GUI作成だけ先にやってボタンを配線＆Router可視対象として gui を公開
ensureGui()
wireButtons()
View.gui = ui  -- Router が Enabled/Visible を管理できるように公開

-- ─────────────────────────────────────────────────────────────
-- ScreenRouter にセルフ登録（1回だけ）＋ Signals を購読して Router 経由で表示
-- ─────────────────────────────────────────────────────────────
if not script:GetAttribute("booted") then
	script:SetAttribute("booted", true)

	-- Router から呼ばれる公開メソッド（コロンで self 受け取り）
	function View:show(payload) openPayload(payload) end
	function View:hide()        if ui then ui.Enabled = false end end
	function View:onResult(res) onResult(res) end

	-- ルーターに登録
	local ok, err = pcall(function()
		if ScreenRouter and ScreenRouter.register then
			ScreenRouter.register("kitoPick", View)
		end
	end)
	if not ok then
		LOG.warn("ScreenRouter.register failed: %s", tostring(err))
	end

	-- Signals 購読：受信→Router 経由で表示（正道）
	SigIncoming.Event:Connect(function(payload)
		if type(payload) ~= "table" then return end
		if ScreenRouter and ScreenRouter.show then
			ScreenRouter.show("kitoPick", payload)
		else
			View:show(payload)
		end
	end)

	SigResult.Event:Connect(function(res)
		if type(res) ~= "table" then return end
		View:onResult(res)
	end)
end

return View
