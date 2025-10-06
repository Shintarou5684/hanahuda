-- KitoPickView.lua（軽量・Renderer固定・SignalsはWires単一路線）
-- Cards は Renderer に一元委譲 / VM は必須 / フォールバック削除

local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local LP         = Players.LocalPlayer

-- Remotes（送信のみ直結）
local Remotes  = RS:WaitForChild("Remotes")
local EvDecide = Remotes:WaitForChild("KitoPickDecide")

-- Signals（Wires が発火する BindableEvent を購読）
local ClientSignals = RS:WaitForChild("ClientSignals")
local SigIncoming   = ClientSignals:WaitForChild("KitoPickIncoming")
local SigResult     = ClientSignals:WaitForChild("KitoPickResult")

-- Logger
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("KitoPickView")

-- Router
local UI_ROOT = script.Parent and script.Parent.Parent
local ScreenRouter = nil
pcall(function()
	if UI_ROOT then
		ScreenRouter = require(UI_ROOT:WaitForChild("ScreenRouter"))
	end
end)

-- Styles
local Styles do
	local ok, mod = pcall(function()
		return require(script.Parent.Parent:WaitForChild("styles"):WaitForChild("KitoPickStyles"))
	end)
	Styles = ok and mod or nil
end

-- ViewModel（純関数置き場・必須）
local VM = require(script.Parent.Parent:WaitForChild("viewmodels"):WaitForChild("KitoPickVM"))
local kindToJp     = assert(VM.kindToJp, "KitoPickVM.kindToJp missing")
local reasonToText = assert(VM.reasonToText, "KitoPickVM.reasonToText missing")

-- Renderer（必須・単一路）
local KitoPickRenderer = require(script.Parent.Parent
	:WaitForChild("components")
	:WaitForChild("renderers")
	:WaitForChild("KitoPickRenderer"))

-- KitoAssets（干支アイコン）
local KitoAssets do
	local ok, mod = pcall(function()
		return require(script.Parent.Parent:WaitForChild("lib"):WaitForChild("KitoAssets"))
	end)
	KitoAssets = ok and mod or nil
	if not KitoAssets then
		LOG.warn("KitoAssets not found; header icon will be disabled")
	end
end

-- ShopDefs（祈祷名/説明）
local okDefs, ShopDefs = pcall(function()
	return require(RS:WaitForChild("SharedModules"):WaitForChild("ShopDefs"))
end)

-- Id正規化（. と _ 揺らぎ吸収）
local function _normId(id)
	if not id then return nil end
	id = tostring(id)
	return id, (id:gsub("%.", "_")), (id:gsub("_", "."))
end

local function findKitoByEffectId(effectId)
	if not okDefs or not ShopDefs or not ShopDefs.POOLS or not ShopDefs.POOLS.kito then return nil end
	local a,b,c = _normId(effectId)
	for _, item in ipairs(ShopDefs.POOLS.kito) do
		local eA,eB,eC = _normId(item.effect or item.id)
		if eA == a or eA == b or eA == c or eB == a or eB == b or eB == c or eC == a or eC == b or eC == c then
			return item
		end
		local iA,iB,iC = _normId(item.id)
		if iA == a or iA == b or iA == c or iB == a or iB == b or iB == c or iC == a or iC == b or iC == c then
			return item
		end
	end
	return nil
end

local function pickDesc(item)
	if not item then return nil end
	return item.descJP or item.descEN or ""
end

-- 画面状態
local View = {}

local ui
local refs = {}
local renderer  -- { gui/root, renderCard, setCardSelected?, show?, hide? }
local _uiBuilt = false

local current = {
	sessionId    = nil,
	effectId     = nil,
	targetKind   = "bright",
	list         = {},    -- [{ uid, code, name, kind, month, image?/imageId?, eligible?, reason? }]
	eligibility  = {},    -- server map { [uid] = { ok, reason } }
	selectedUid  = nil,
	busy         = false,
}

--──────────── UI build
local function make(name, className, props, parent)
	local inst = Instance.new(className)
	inst.Name = name
	for k,v in pairs(props or {}) do inst[k] = v end
	inst.Parent = parent
	return inst
end

local function ensureGui()
	local t0 = os.clock()

	-- Rendererコンテナ作成（必須）
	if not renderer then
		local inst = KitoPickRenderer.create(Players.LocalPlayer:WaitForChild("PlayerGui"))
		assert(type(inst) == "table", "KitoPickRenderer.create must return table")
		renderer = inst
		ui = renderer.gui or renderer.root
		assert(ui ~= nil, "KitoPickRenderer must expose 'gui' or 'root'")
	end

	-- 再利用
	if ui and ui.Parent and _uiBuilt and (ui:FindFirstChild("Panel", true) ~= nil) then
		LOG.debug("ensureGui: reuse existing gui (%.2fms)", (os.clock()-t0)*1000)
		return ui
	end

	-- Styles 短縮
	local S = Styles and Styles.sizes or {}
	local C = Styles and Styles.colors or {}
	local F = Styles and Styles.fontSizes or {}
	local Z = Styles and Styles.z or {}

	-- 見た目
	local shade = make("Shade","Frame",{
		BackgroundColor3       = C.shade or Color3.new(0,0,0),
		BackgroundTransparency = S.shadeTransparency or 0.35,
		Size                   = UDim2.fromScale(1,1)
	}, ui)

	local panel = make("Panel","Frame",{
		AnchorPoint         = Vector2.new(0.5,0.5),
		Position            = UDim2.fromScale(0.5, S.panelPosYScale or 0.52),
		Size                = UDim2.fromOffset(S.panelWidth or 880, S.panelHeight or 560),
		BackgroundColor3    = C.panelBg or Color3.fromRGB(24,24,28),
		BorderSizePixel     = 0,
	}, shade)
	make("UICorner","UICorner",{CornerRadius=UDim.new(0, S.panelCorner or 18)}, panel)
	make("Padding","UIPadding",{
		PaddingTop    = UDim.new(0, S.panelPadding or 16),
		PaddingBottom = UDim.new(0, S.panelPadding or 16),
		PaddingLeft   = UDim.new(0, S.panelPadding or 16),
		PaddingRight  = UDim.new(0, S.panelPadding or 16),
	}, panel)

	make("Title","TextLabel",{
		Text                   = "KITO: Pick a card",
		Font                   = Enum.Font.GothamBold,
		TextSize               = F.title or 22,
		TextColor3             = C.titleText or Color3.fromRGB(230,230,240),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, S.titleHeight or 28),
	}, panel)

	local headerIcon = make("KitoIcon","ImageLabel",{
		Image                  = "",
		BackgroundTransparency = 1,
		Size                   = UDim2.fromOffset(S.headerIcon or 44, S.headerIcon or 44),
		Position               = UDim2.new(0, 0, 0, (S.titleHeight or 28) + (S.kitoNameTopGap or 2)),
		Visible                = false,
		ScaleType              = Enum.ScaleType.Fit,
		ZIndex                 = Z.headerIcon or 2,
	}, panel)

	local kitoName = make("KitoName","TextLabel",{
		Text                   = "",
		Font                   = Enum.Font.GothamBold,
		TextSize               = F.kitoName or 20,
		TextColor3             = C.kitoNameText or Color3.fromRGB(236,236,246),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, S.kitoNameHeight or 22),
		Position               = UDim2.new(0, (S.headerIcon or 44) + (S.headerGap or 8), 0, (S.titleHeight or 28) + (S.kitoNameTopGap or 2)),
		TextXAlignment         = Enum.TextXAlignment.Left,
	}, panel)

	local effect = make("Effect","TextLabel",{
		Text                   = "",
		Font                   = Enum.Font.Gotham,
		TextWrapped            = true,
		TextSize               = F.effect or 18,
		TextColor3             = C.effectText or Color3.fromRGB(200,200,210),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 1),
		Position               = UDim2.new(0, 0, 0, (S.titleHeight or 28) + (S.kitoNameTopGap or 2) + (S.kitoNameHeight or 22) + (S.effectTopGap or 6)),
		TextXAlignment         = Enum.TextXAlignment.Left,
	}, panel)

	local gridHolder = make("GridHolder","Frame",{
		BackgroundTransparency = 1,
		Position               = UDim2.new(0, 0, 0, (S.titleHeight or 28) + (S.effectTopGap or 6) + (S.effectInitHeight or 40) + (S.effectBelowGap or 8)),
		Size                   = UDim2.new(1, 0, 1, -((S.titleHeight or 28)+(S.effectTopGap or 6)+(S.effectInitHeight or 40)+(S.effectBelowGap or 8)) - (S.footerHeightReserve or 84)),
	}, panel)

	local scroll = make("Scroll","ScrollingFrame",{
		BackgroundTransparency = 1,
		CanvasSize             = UDim2.new(),
		ScrollBarThickness     = S.scrollBar or 6,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1,0,1,0),
	}, gridHolder)

	local gridFrame = make("Grid","Frame",{
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,1,0),
	}, scroll)

	local layout = make("UIGrid","UIGridLayout",{
		CellPadding          = UDim2.fromOffset(S.gridGap or 12, S.gridGap or 12),
		CellSize             = UDim2.fromOffset(S.gridCellW or 180, S.gridCellH or 160),
		HorizontalAlignment  = Enum.HorizontalAlignment.Left,
		SortOrder            = Enum.SortOrder.LayoutOrder,
	}, gridFrame)

	local footer = make("Footer","Frame",{
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(0.5,1),
		Position               = UDim2.new(0.5,0,1,-(S.footerBottomGap or 8)),
		Size                   = UDim2.new(1, -16, 0, S.footerHeight or 52),
	}, panel)

	local pickInfo = make("PickInfo","TextLabel",{
		Text                   = "Select 1 card",
		Font                   = Enum.Font.Gotham,
		TextSize               = F.pickInfo or 18,
		TextColor3             = C.pickInfoText or Color3.fromRGB(200,200,210),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, -(S.pickInfoRightReserve or 360), 1, 0),
		TextXAlignment         = Enum.TextXAlignment.Left,
	}, footer)

	local skipBtn = make("Skip","TextButton",{
		Text                   = "Skip",
		Font                   = Enum.Font.GothamBold,
		TextSize               = F.btn or 20,
		TextColor3             = C.skipText or Color3.fromRGB(230,230,240),
		AutoButtonColor        = true,
		BackgroundColor3       = C.skipBg or Color3.fromRGB(70,70,78),
		BackgroundTransparency = 0.05,
		Size                   = UDim2.fromOffset(S.btnSkipW or 140, S.btnH or 44),
		AnchorPoint            = Vector2.new(1,0.5),
		Position               = UDim2.new(1, -(S.btnConfirmW or 160) - (S.btnGap or 16), 0.5, 0),
	}, footer)
	make("UICorner","UICorner",{CornerRadius=UDim.new(0, S.btnCorner or 10)}, skipBtn)

	local confirm = make("Confirm","TextButton",{
		Text                   = "Confirm",
		Font                   = Enum.Font.GothamBold,
		TextSize               = F.btn or 20,
		TextColor3             = C.confirmText or Color3.fromRGB(16,16,20),
		AutoButtonColor        = true,
		BackgroundColor3       = C.confirmBg or Color3.fromRGB(120,200,120),
		BackgroundTransparency = 0.0,
		Size                   = UDim2.fromOffset(S.btnConfirmW or 160, S.btnH or 44),
		AnchorPoint            = Vector2.new(1,0.5),
		Position               = UDim2.new(1, -(S.btnRightGap or 8), 0.5, 0),
	}, footer)
	make("UICorner","UICorner",{CornerRadius=UDim.new(0, S.btnCorner or 10)}, confirm)

	refs.headerIcon = headerIcon
	refs.kitoName   = kitoName
	refs.effect     = effect
	refs.gridHolder = gridHolder
	refs.scroll     = scroll
	refs.gridFrame  = gridFrame
	refs.gridLayout = layout
	refs.confirm    = confirm
	refs.skipBtn    = skipBtn
	refs.pickInfo   = pickInfo

	_uiBuilt = true
	LOG.info("ensureGui: built gui in %.2fms (renderer=on)", (os.clock()-t0)*1000)
	return ui
end

-- 効果説明に合わせてグリッド再配置
local function relayoutByEffectHeight()
	if not (refs.effect and refs.gridHolder) then return end
	local S = Styles and Styles.sizes or {}
	local nameH     = (refs.kitoName and refs.kitoName.Text ~= "") and (S.kitoNameHeight or 22) or 0
	local topY      = (S.titleHeight or 28) + (S.kitoNameTopGap or 2) + nameH + (S.effectTopGap or 6)
	local baseBelow = S.footerHeightReserve or 84
	local effect    = refs.effect

	local needH = math.max(S.effectMinHeight or 22, math.ceil(effect.TextBounds.Y))
	effect.Size = UDim2.new(1, 0, 0, needH)

	local gridTop  = topY + needH + (S.effectBelowGap or 8)
	refs.gridHolder.Position = UDim2.new(0, 0, 0, gridTop)
	refs.gridHolder.Size     = UDim2.new(1, 0, 1, -gridTop - baseBelow)
end

local function setConfirmEnabled(enabled)
	if not refs.confirm then return end
	refs.confirm.Active                 = enabled
	refs.confirm.AutoButtonColor        = enabled
	refs.confirm.TextTransparency       = enabled and 0 or 0.4
	refs.confirm.BackgroundTransparency = enabled and 0.0 or 0.4
end

--──────────── 描画（カード生成は Renderer のみ）
local function rebuildList()
	if not ui then return end

	for _, c in ipairs(refs.gridFrame:GetChildren()) do
		if not c:IsA("UIGridLayout") then c:Destroy() end
	end

	local ineligible = 0
	for _, ent in ipairs(current.list or {}) do
		if ent.eligible == false then ineligible += 1 end

		local b = renderer.renderCard(refs.gridFrame, ent)
		if b then
			b:SetAttribute("uid", tostring(ent.uid))
			b:SetAttribute("canPick", ent.eligible ~= false)
			b:SetAttribute("reason", ent.reason or "")

			if type(renderer.setCardSelected) == "function" then
				renderer.setCardSelected(b, ent.uid == current.selectedUid)
			end

			if b:IsA("GuiButton") then
				b.MouseButton1Click:Connect(function()
					if current.busy then
						LOG.debug("click ignored (busy) uid=%s", tostring(ent.uid))
						return
					end
					if b:GetAttribute("canPick") == false then
						local reason = b:GetAttribute("reason")
						pcall(function()
							StarterGui:SetCore("SendNotification", {
								Title = "KITO",
								Text  = reasonToText(reason) or "対象外のカードです",
								Duration = 2,
							})
						end)
						LOG.debug("click blocked (ineligible) uid=%s reason=%s", tostring(ent.uid), tostring(reason))
						return
					end

					if current.selectedUid == ent.uid then
						current.selectedUid = nil
					else
						current.selectedUid = ent.uid
					end

					for _, c2 in ipairs(refs.gridFrame:GetChildren()) do
						if c2:IsA("GuiObject") and type(renderer.setCardSelected)=="function" then
							renderer.setCardSelected(c2, c2:GetAttribute("uid") == current.selectedUid)
						end
					end
					setConfirmEnabled(current.selectedUid ~= nil and not current.busy)
					LOG.debug("selected uid=%s", tostring(current.selectedUid))
				end)
			end
		end
	end

	task.defer(function()
		local content = refs.gridLayout.AbsoluteContentSize
		refs.scroll.CanvasSize = UDim2.fromOffset(content.X, content.Y)
	end)

	LOG.info("rebuildList: items=%d ineligible=%d selected=%s",
		#(current.list or {}), ineligible, tostring(current.selectedUid or "-"))
end

--──────────── 文言
local function buildEffectText(payload)
	local item = findKitoByEffectId(payload and (payload.effectId or payload.effect))
	if item then return pickDesc(item) or "" end
	if type(payload.effect)  == "string" and payload.effect  ~= "" then return payload.effect  end
	if type(payload.message) == "string" and payload.message ~= "" then return payload.message end
	if type(payload.note)    == "string" and payload.note    ~= "" then return payload.note    end
	local tgtJp = kindToJp(current.targetKind)
	return ("対象を選んでください（目標: %s）"):format(tgtJp)
end

--──────────── Open payload（SigIncoming 経由でのみ呼ばれる）
local function openPayload(payload)
	local g = ensureGui()
	if g.Parent ~= LP:WaitForChild("PlayerGui") then
		g.Parent = LP.PlayerGui
	end

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

	do
		local item = findKitoByEffectId(current.effectId or payload.effect)
		if refs.kitoName then
			refs.kitoName.Text = item and tostring(item.name or "") or ""
		end
	end

	do
		local icon = nil
		if KitoAssets then
			local eff = tostring(current.effectId or payload.effect or "")
			local canon = eff
			if okDefs and ShopDefs and type(ShopDefs.toCanonicalEffectId) == "function" then
				local okc, res = pcall(ShopDefs.toCanonicalEffectId, eff)
				canon = okc and (res or eff) or eff
			end
			icon = KitoAssets.getIcon(canon)
		end
		if refs.headerIcon then
			if icon and icon ~= "" then
				refs.headerIcon.Image = icon
				refs.headerIcon.Visible = true
			else
				refs.headerIcon.Image = ""
				refs.headerIcon.Visible = false
			end
		end
	end

	refs.effect.Text = buildEffectText(payload)
	relayoutByEffectHeight()

	refs.pickInfo.Text = "Select 1 card"
	setConfirmEnabled(false)
	refs.skipBtn.Active = true
	refs.skipBtn.AutoButtonColor = true

	rebuildList()

	g.Enabled = true
	if renderer and type(renderer.show) == "function" then pcall(function() renderer.show() end) end

	LOG.info("[open] sid=%s eff=%s tgt=%s list=%d router=%s",
		tostring(current.sessionId), tostring(current.effectId or "-"),
		tostring(current.targetKind), #(current.list or {}),
		ScreenRouter and "on" or "off"
	)
end

--──────────── Send
local function sendDecide()
	if current.busy or not current.sessionId or not current.selectedUid then
		LOG.debug("sendDecide: ignored | busy=%s sid=%s sel=%s",
			tostring(current.busy), tostring(current.sessionId), tostring(current.selectedUid))
		return
	end
	for _, e in ipairs(current.list or {}) do
		if e.uid == current.selectedUid and e.eligible == false then
			pcall(function()
				StarterGui:SetCore("SendNotification", {
					Title="KITO",
					Text= reasonToText(e.reason) or "対象外のカードです",
					Duration=2,
				})
			end)
			LOG.debug("sendDecide: abort (ineligible) uid=%s", tostring(current.selectedUid))
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
	LOG.info("[sendDecide] -> FireServer sid=%s uid=%s tgt=%s",
		tostring(current.sessionId), tostring(current.selectedUid), tostring(current.targetKind))
end

local function sendSkip()
	if current.busy or not current.sessionId then
		LOG.debug("sendSkip: ignored | busy=%s sid=%s", tostring(current.busy), tostring(current.sessionId))
		return
	end
	current.busy = true
	setConfirmEnabled(false)
	refs.skipBtn.Active = false
	refs.skipBtn.AutoButtonColor = false

	EvDecide:FireServer({
		sessionId  = current.sessionId,
		targetKind = current.targetKind,
		noChange   = true,
	})
	LOG.info("[sendSkip] -> FireServer sid=%s tgt=%s (noChange=true)",
		tostring(current.sessionId), tostring(current.targetKind))
end

--──────────── Result（SigResult 経由で閉じる）
local function onResult(res)
	if not ui then return end
	current.busy = false
	ui.Enabled = false
	if renderer and type(renderer.hide) == "function" then pcall(function() renderer.hide() end) end

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

	local function _nonEmpty(s) return type(s)=="string" and s ~= "" end
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
		body  = _nonEmpty(res.message) and res.message or "処理に失敗しました"
	end

	pcall(function()
		StarterGui:SetCore("SendNotification", { Title = title, Text = body, Duration = 3 })
	end)

	LOG.info("[result] ok=%s changed=%s uid=%s id=%s msg=%s",
		tostring(res.ok), tostring(res.changed), tostring(res.uid),
		tostring(res.id), tostring(res.message or ""))
end

-- 配線
local function wireButtons()
	if not ui then return end
	refs.confirm.MouseButton1Click:Connect(sendDecide)
	refs.skipBtn.MouseButton1Click:Connect(sendSkip)
	LOG.debug("wireButtons: connected")
end

-- 初期化
ensureGui()
wireButtons()
View.gui = ui

-- Router登録 & シグナル購読（1回だけ）
if not script:GetAttribute("booted") then
	script:SetAttribute("booted", true)

	function View:show(payload) openPayload(payload) end
	function View:hide()
		if ui then ui.Enabled = false end
		if renderer and type(renderer.hide) == "function" then pcall(function() renderer.hide() end) end
	end
	function View:onResult(res) onResult(res) end
	function View:setLang(_lang) end
	function View:setRerollCounts(_a,_b,_c) end

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

	-- ★ 単一路線：Wires が発火する ClientSignals のみ購読
	SigIncoming.Event:Connect(function(payload)
		if type(payload) ~= "table" then
			LOG.warn("SigIncoming: invalid payload type=%s", typeof(payload))
			return
		end
		if ScreenRouter and ScreenRouter.show then
			ScreenRouter.show("kitoPick", payload)
		else
			View:show(payload)
		end
		LOG.debug("SigIncoming handled")
	end)

	SigResult.Event:Connect(function(res)
		if type(res) ~= "table" then
			LOG.warn("SigResult: invalid result type=%s", typeof(res))
			return
		end
		View:onResult(res)
	end)

	LOG.info("booted | router=%s", ScreenRouter and "on" or "off")
end

return View
