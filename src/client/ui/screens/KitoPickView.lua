-- src/client/ui/screens/KitoPickView.lua
-- 目的: KitoPick の12枚一覧UI・効果説明＋カード画像＆情報表示・確定／スキップ
-- 仕様: KitoPickWires の ClientSignals を購読し、シグナル受信時に Router 経由で表示
-- 方針:
--   - 「選択可否の真実はサーバ」。payload.eligibility を唯一の正として
--     各候補に eligible / reason をマージし、不適格はグレーアウト＆クリック不可。
--   - 送信前にもクライアント側で eligible を再確認（多重タップ/競合のガード）。
-- ★ P1-6: 結果受信後に ScreenRouter で "shop" へ確実に戻す／追跡ログ・計測を追加

local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local LP         = Players.LocalPlayer

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
	sessionId    = nil,
	effectId     = nil,
	targetKind   = "bright",
	list         = {},     -- [{ uid, code, name, kind, month, image?/imageId?, eligible?, reason? }]
	eligibility  = {},     -- server map { [uid] = { ok, reason } }（情報保持のみ）
	selectedUid  = nil,
	busy         = false,  -- 決定/スキップの多重送信防止
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
	local t0 = os.clock()
	-- 既にあれば Parent ロスト時のみ復旧
	if ui and ui.Parent then
		LOG.debug("ensureGui: reuse existing gui (%.2fms)", (os.clock()-t0)*1000)
		return ui
	end
	ui = make("KitoPickGui", "ScreenGui", {
		ResetOnSpawn    = false,
		ZIndexBehavior  = Enum.ZIndexBehavior.Global,
		IgnoreGuiInset  = true,
		DisplayOrder    = 50,
		Enabled         = false,  -- ★初期は非表示
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

	-- Skip
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

	LOG.info("ensureGui: built gui in %.2fms", (os.clock()-t0)*1000)
	return ui
end

-- 効果説明の高さに合わせてグリッド領域を再レイアウト
local function relayoutByEffectHeight()
	local t0 = os.clock()
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
	LOG.debug("relayoutByEffectHeight: effectH=%d in %.2fms", needH, (os.clock()-t0)*1000)
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

-- 理由の日本語化（簡易）
local function reasonToText(reason: string?): string?
	local map = {
		["already-applied"]   = "既に適用済みです",
		["already-bright"]    = "すでに光札です",
		["already-chaff"]     = "すでにカス札です",
		["month-has-no-bright"] = "この月に光札はありません",
		["not-eligible"]      = "対象外です",
		["same-target"]       = "同一カードは選べません",
		["no-check"]          = "対象外（サーバ判定なし）",
	}
	return map[tostring(reason or "")] or nil
end

-- 「対象外」オーバーレイ（eligible=false 用）
local function makeIneligibleOverlay(parent, reason)
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
	tag.Size = UDim2.fromScale(1,0)
	tag.Position = UDim2.fromScale(0,0.45)
	tag.Text = "対象外"
	tag.Font = Enum.Font.GothamBold
	tag.TextSize = 18
	tag.TextColor3 = Color3.fromRGB(230,230,240)
	tag.ZIndex = 6
	tag.Parent = mask

	if reason and reason ~= "" then
		local sub = Instance.new("TextLabel")
		sub.BackgroundTransparency = 1
		sub.Size = UDim2.fromScale(1,0)
		sub.Position = UDim2.fromScale(0,0.65)
		sub.Text = reasonToText(reason) or tostring(reason)
		sub.Font = Enum.Font.Gotham
		sub.TextSize = 14
		sub.TextColor3 = Color3.fromRGB(220,220,230)
		sub.ZIndex = 6
		sub.Parent = mask
	end
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
		img.Image = ""
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
	card:SetAttribute("reason", entry.reason or "")
	if not canPick then
		card.AutoButtonColor = false
		makeIneligibleOverlay(card, entry.reason)
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
	local t0 = os.clock()
	if not ui then return end

	-- 既存カードだけ消す（レイアウトは保持）
	for _, c in ipairs(refs.gridFrame:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end

	local ineligible = 0
	for _, ent in ipairs(current.list or {}) do
		if ent.eligible == false then ineligible += 1 end
		local b = makeCard(ent)
		b.Parent = refs.gridFrame
		setCardSelected(b, ent.uid == current.selectedUid)
		b.MouseButton1Click:Connect(function()
			if current.busy then
				LOG.debug("click ignored (busy) uid=%s", tostring(ent.uid))
				return
			end

			-- ★ eligible=false はクリック無効（通知のみ）
			if b:GetAttribute("canPick") == false then
				local reason = b:GetAttribute("reason")
				local ok, err = pcall(function()
					StarterGui:SetCore("SendNotification", {
						Title = "KITO",
						Text = (reasonToText(reason) or "対象外のカードです"),
						Duration = 2,
					})
				end)
				if not ok then LOG.warn("SetCore Notify failed: %s", tostring(err)) end
				LOG.debug("click blocked (ineligible) uid=%s reason=%s", tostring(ent.uid), tostring(reason))
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
			LOG.debug("selected uid=%s", tostring(current.selectedUid))
		end)
	end

	-- Canvas 自動調整
	task.defer(function()
		local t1 = os.clock()
		local content = refs.gridLayout.AbsoluteContentSize
		refs.scroll.CanvasSize = UDim2.fromOffset(content.X, content.Y)
		LOG.debug("rebuildList: CanvasSize set to (%d,%d) in %.2fms",
			content.X, content.Y, (os.clock()-t1)*1000)
	end)

	LOG.info("rebuildList: items=%d ineligible=%d selected=%s in %.2fms",
		#(current.list or {}), ineligible, tostring(current.selectedUid or "-"),
		(os.clock()-t0)*1000
	)
end

-- 効果説明の決定
local function buildEffectText(payload)
	if type(payload.effect) == "string" and payload.effect ~= "" then
		return payload.effect
	end
	if type(payload.message) == "string" and payload.message ~= "" then
		return payload.message
	end
	if type(payload.note) == "string" and payload.note ~= "" then
		return payload.note
	end
	local tgtJp = kindToJp(current.targetKind)
	return ("対象を選んでください（目標: %s）"):format(tgtJp)
end

-- 新規 payload 表示
local function openPayload(payload)
	local g = ensureGui()
	-- 念のため、PlayerGui から外れていたら復旧
	if g.Parent ~= LP:WaitForChild("PlayerGui") then
		g.Parent = LP.PlayerGui
	end

	-- サーバの eligibility を list にマージ（唯一の正）
	local eligibility = payload.eligibility or {}
	local enriched = {}
	for _, ent in ipairs(payload.list or {}) do
		local uid = tostring(ent.uid or ent.code or "")
		local eg = eligibility[uid]
		local ok  = (type(eg)=="table" and eg.ok == true) or false
		local rsn = (type(eg)=="table" and eg.reason) or nil
		local copy = table.clone(ent)
		copy.eligible = ok
		copy.reason   = rsn
		enriched[#enriched+1] = copy
	end

	current.sessionId    = payload.sessionId
	current.effectId     = payload.effectId
	current.targetKind   = tostring(payload.targetKind or "bright")
	current.list         = enriched
	current.eligibility  = eligibility
	current.selectedUid  = nil
	current.busy         = false

	-- 効果説明テキスト
	refs.effect.Text = buildEffectText(payload)
	relayoutByEffectHeight()

	refs.pickInfo.Text = "Select 1 card"
	setConfirmEnabled(false)
	refs.skipBtn.Active = true
	refs.skipBtn.AutoButtonColor = true
	rebuildList()

	g.Enabled = true -- ★ここで可視化

	LOG.info("[open] sid=%s eff=%s tgt=%s list=%d router=%s",
		tostring(current.sessionId), tostring(current.effectId or "-"),
		tostring(current.targetKind), #(current.list or {}),
		ScreenRouter and "on" or "off"
	)
end

-- 決定送信（選択あり）
local function sendDecide()
	if current.busy or not current.sessionId or not current.selectedUid then
		LOG.debug("sendDecide: ignored | busy=%s sid=%s sel=%s",
			tostring(current.busy), tostring(current.sessionId), tostring(current.selectedUid))
		return
	end

	-- ★ 送信前の二重チェック（サーバ同期）
	for _, e in ipairs(current.list or {}) do
		if e.uid == current.selectedUid and e.eligible == false then
			local ok, err = pcall(function()
				StarterGui:SetCore("SendNotification", {
					Title="KITO",
					Text= reasonToText(e.reason) or "対象外のカードです",
					Duration=2,
				})
			end)
			if not ok then LOG.warn("SetCore Notify failed: %s", tostring(err)) end
			LOG.debug("sendDecide: abort (ineligible) uid=%s", tostring(current.selectedUid))
			return
		end
	end

	current.busy = true
	setConfirmEnabled(false)
	refs.skipBtn.Active = false
	refs.skipBtn.AutoButtonColor = false

	local t0 = os.clock()
	EvDecide:FireServer({
		sessionId  = current.sessionId,
		uid        = current.selectedUid,
		targetKind = current.targetKind,
	})
	LOG.info("[sendDecide] -> FireServer sid=%s uid=%s tgt=%s in %.2fms",
		tostring(current.sessionId), tostring(current.selectedUid),
		tostring(current.targetKind), (os.clock()-t0)*1000
	)
end

-- スキップ送信（何も選ばない＝変更なしで確定）
local function sendSkip()
	if current.busy or not current.sessionId then
		LOG.debug("sendSkip: ignored | busy=%s sid=%s", tostring(current.busy), tostring(current.sessionId))
		return
	end
	current.busy = true
	setConfirmEnabled(false)
	refs.skipBtn.Active = false
	refs.skipBtn.AutoButtonColor = false

	local t0 = os.clock()
	EvDecide:FireServer({
		sessionId  = current.sessionId,
		targetKind = current.targetKind,
		noChange   = true,          -- ★ Core/Server と合意済みのフラグ
	})
	LOG.info("[sendSkip] -> FireServer sid=%s tgt=%s (noChange=true) in %.2fms",
		tostring(current.sessionId), tostring(current.targetKind), (os.clock()-t0)*1000
	)
end

-- 結果受信
local function onResult(res)
	if not ui then return end
	current.busy = false
	ui.Enabled = false  -- ★結果受信で確実に閉じる

	-- ★ 重要：Router でショップ画面へ戻す（空白＝青画面対策）
	local routed = false
	local okShow, errShow = pcall(function()
		if ScreenRouter and ScreenRouter.show then
			ScreenRouter.show("shop")
			routed = true
		end
	end)
	if not okShow then
		LOG.warn("[result] route to 'shop' failed: %s", tostring(errShow))
	elseif routed then
		LOG.info("[result] routed back to 'shop'")
	else
		LOG.warn("[result] ScreenRouter not available; cannot route to 'shop'")
	end

	-- 通知（本文フォールバック付き）
	local function _nonEmpty(s) return type(s)=="string" and s ~= "" end
	local function _reasonToText(reason)
		local map = {
			session           = "セッションが無効です。もう一度お試しください。",
			expired           = "選択の有効期限が切れました。もう一度お試しください。",
			uid               = "対象外のカードです（同種は選べません）。",
			state             = "状態を取得できませんでした。同期してください。",
			run               = "ラン情報が見つかりませんでした。",
			effects           = "効果モジュールが利用できません。",
			["no-shopservice"]= "屋台画面を再表示できませんでした。",
			effect            = nil, -- effect は res.message を優先（無ければ最後の既定文言へ）
		}
		return map[tostring(reason or "")] or nil
	end

	local title, body
	if res.cancel then
		title = "KITO"
		body  = "取消しました"
	elseif res.ok then
		title = "KITO"
		if _nonEmpty(res.message) then
			body = res.message
		else
			body = (res.changed ~= false) and "変換が完了しました" or "選択をスキップしました"
		end
	else
		title = "KITO (failed)"
		body  = _nonEmpty(res.message)
			and res.message
			or (_reasonToText(res.reason) or ("処理に失敗しました" ..
				(res.reason and ("（"..tostring(res.reason).."）") or "")))
	end

	local ok, err = pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title    = title,
			Text     = body,
			Duration = 3,
		})
	end)
	if not ok then LOG.warn("SetCore Notify failed: %s", tostring(err)) end

	LOG.info("[result] ok=%s changed=%s uid=%s id=%s msg=%s",
		tostring(res.ok), tostring(res.changed), tostring(res.uid),
		tostring(res.id), tostring(res.message or "")
	)
	LOG.debug("[toast] title=%s text=%s reason=%s", tostring(title), tostring(body), tostring(res.reason))
end

-- ボタン配線
local function wireButtons()
	if not ui then return end
	refs.confirm.MouseButton1Click:Connect(sendDecide)
	refs.skipBtn.MouseButton1Click:Connect(sendSkip)
	LOG.debug("wireButtons: connected")
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
	if ok then
		LOG.info("ScreenRouter.register ok")
	else
		LOG.warn("ScreenRouter.register failed: %s", tostring(err))
	end

	-- Signals 購読：受信→Router 経由で表示（正道）
	SigIncoming.Event:Connect(function(payload)
		local t0 = os.clock()
		if type(payload) ~= "table" then
			LOG.warn("SigIncoming: invalid payload type=%s", typeof(payload))
			return
		end
		if ScreenRouter and ScreenRouter.show then
			ScreenRouter.show("kitoPick", payload)
			LOG.debug("SigIncoming: via Router in %.2fms", (os.clock()-t0)*1000)
		else
			View:show(payload)
			LOG.debug("SigIncoming: direct show in %.2fms", (os.clock()-t0)*1000)
		end
	end)

	SigResult.Event:Connect(function(res)
		local t0 = os.clock()
		if type(res) ~= "table" then
			LOG.warn("SigResult: invalid result type=%s", typeof(res))
			return
		end
		View:onResult(res)
		LOG.debug("SigResult: handled in %.2fms", (os.clock()-t0)*1000)
	end)

	LOG.info("booted | router=%s", ScreenRouter and "on" or "off")
end

return View
