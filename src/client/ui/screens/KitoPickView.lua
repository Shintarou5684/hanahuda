-- StarterPlayerScripts/UI/screens/KitoPickView.lua
-- v0.9.RESP-4 (Header-right buttons / no footer)
--  - Skip / Confirm をヘッダー右上へ（解説と同じ行）
--  - フッター廃止（FOOTER_H=0）/ グリッド領域を拡大
--  - Scroll/Grid は ClipsDescendants=false（説明テキストが隠れない）
--  - 2段×6列の相対グリッドは維持

local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local LP         = Players.LocalPlayer

-- Remotes
local Remotes  = RS:WaitForChild("Remotes")
local EvDecide = Remotes:WaitForChild("KitoPickDecide")

-- Signals
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

-- Styles（任意）
local Styles do
	local ok, mod = pcall(function()
		return require(script.Parent.Parent:WaitForChild("styles"):WaitForChild("KitoPickStyles"))
	end)
	Styles = ok and mod or nil
end

-- VM
local VM = require(script.Parent.Parent:WaitForChild("viewmodels"):WaitForChild("KitoPickVM"))
local kindToJp     = assert(VM.kindToJp, "KitoPickVM.kindToJp missing")
local reasonToText = assert(VM.reasonToText, "KitoPickVM.reasonToText missing")

-- Renderer
local KitoPickRenderer = require(script.Parent.Parent
	:WaitForChild("components")
	:WaitForChild("renderers")
	:WaitForChild("KitoPickRenderer"))

-- ShopDefs（祈祷の名称/説明参照）
local okDefs, ShopDefs = pcall(function()
	return require(RS:WaitForChild("SharedModules"):WaitForChild("ShopDefs"))
end)

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
		if eA==a or eA==b or eA==c or eB==a or eB==b or eB==c or eC==a or eC==b or eC==c then return item end
		local iA,iB,iC = _normId(item.id)
		if iA==a or iA==b or iA==c or iB==a or iB==b or iB==c or iC==a or iC==b or iC==c then return item end
	end
	return nil
end

local function pickDesc(item)
	if not item then return nil end
	return item.descJP or item.descEN or ""
end

-- 状態
local View, ui = {}, nil
local refs, renderer, _uiBuilt = {}, nil, false
local current = {
	sessionId=nil, effectId=nil, targetKind="bright",
	list={}, eligibility={}, selectedUid=nil, busy=false,
}

--========= レイアウト係数 =========--
local GRID_COLS = 6
local GRID_ROWS = 2
local PAD_X     = 0.008   -- 横ギャップ
local PAD_Y     = 0.012   -- 縦ギャップ
local HEADER_H  = 0.16    -- ヘッダー（左:説明 / 右:ボタン）
local FOOTER_H  = 0.0     -- フッター廃止
local MARGIN_Y  = 0.02

-- 画面に応じてパネル幅/高さ（相対）を決める：縦を広めに
local function calcPanelWH(viewW, viewH)
	local ar = viewW / math.max(1, viewH)
	local targetW = 0.98
	local targetAR = math.clamp(ar * 0.95, 1.45, 1.85)  -- W/H
	local targetH  = targetW * (ar / targetAR)
	targetH = math.clamp(targetH, 0.68, 0.90)
	return targetW, targetH
end

local function _addTextScaledMax(label: TextLabel|TextButton, maxSize:number)
	label.TextScaled = true
	local lim = Instance.new("UITextSizeConstraint")
	lim.MaxTextSize = maxSize
	lim.Parent = label
	return lim
end

--========= UI build =========--
local function make(name, className, props, parent)
	local inst = Instance.new(className); inst.Name = name
	for k,v in pairs(props or {}) do inst[k] = v end
	inst.Parent = parent; return inst
end

local function ensureGui()
	if not renderer then
		local inst = KitoPickRenderer.create(Players.LocalPlayer:WaitForChild("PlayerGui"))
		assert(type(inst) == "table", "KitoPickRenderer.create must return table")
		renderer = inst; ui = renderer.gui or renderer.root
		assert(ui, "KitoPickRenderer must expose 'gui' or 'root'")
	end
	if ui and ui.Parent and _uiBuilt and (ui:FindFirstChild("Panel", true) ~= nil) then
		return ui
	end

	local C = Styles and Styles.colors or {}

	local shade = make("Shade","Frame",{
		BackgroundColor3=C.shade or Color3.new(0,0,0),
		BackgroundTransparency=0.35,
		Size=UDim2.fromScale(1,1)
	}, ui)

	local panel = make("Panel","Frame",{
		AnchorPoint=Vector2.new(0.5,0.5),
		Position=UDim2.fromScale(0.5,0.5),
		Size=UDim2.fromScale(0.98,0.70), -- 初期。後で再計算
		BackgroundColor3=C.panelBg or Color3.fromRGB(24,24,28),
		BorderSizePixel=0,
	}, shade)
	make("UICorner","UICorner",{CornerRadius=UDim.new(0,18)}, panel)
	make("UIPadding","UIPadding",{
		PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,12),
		PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12),
	}, panel)

	-- ===== ヘッダ：左＝説明 / 右＝ボタンバー =====
	local header = make("Header","Frame",{BackgroundTransparency=1}, panel)

	-- 左カラム（解説）
	local headLeft = make("HeadLeft","Frame",{BackgroundTransparency=1}, header)

	local kitoName = make("KitoName","TextLabel",{
		Text="",
		Font=Enum.Font.GothamBold,
		TextColor3=C.kitoNameText or Color3.fromRGB(236,236,246),
		BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left,
	}, headLeft); _addTextScaledMax(kitoName, 30)

	local effect = make("Effect","TextLabel",{
		Text="",
		Font=Enum.Font.Gotham, TextWrapped=true,
		TextColor3=C.effectText or Color3.fromRGB(200,200,210),
		BackgroundTransparency=1,
		TextXAlignment=Enum.TextXAlignment.Left,
		TextYAlignment=Enum.TextYAlignment.Top,
	}, headLeft); _addTextScaledMax(effect, 22)

	-- 参考表示（選択数など）※ヘッダ左の下辺に薄く
	local pickInfo = make("PickInfo","TextLabel",{
		Text="Select 1 card",
		Font=Enum.Font.Gotham,
		TextColor3=C.pickInfoText or Color3.fromRGB(200,200,210),
		BackgroundTransparency=1,
		TextXAlignment=Enum.TextXAlignment.Left,
	}, headLeft); _addTextScaledMax(pickInfo, 20)

	-- 右カラム（ボタンバー）
	local btnRow = make("BtnRow","Frame",{BackgroundTransparency=1}, header)

	local hlist = Instance.new("UIListLayout")
	hlist.FillDirection = Enum.FillDirection.Horizontal
	hlist.HorizontalAlignment = Enum.HorizontalAlignment.Right
	hlist.VerticalAlignment = Enum.VerticalAlignment.Center
	hlist.Padding = UDim.new(0, 10)
	hlist.Parent = btnRow

	local skipBtn = make("Skip","TextButton",{
		Text="Skip", Font=Enum.Font.GothamBold,
		TextColor3=C.skipText or Color3.fromRGB(230,230,240),
		AutoButtonColor=true, BackgroundColor3=C.skipBg or Color3.fromRGB(70,70,78),
		BackgroundTransparency=0.05,
		Size = UDim2.fromScale(0.48, 0.86),
	}, btnRow); make("UICorner","UICorner",{CornerRadius=UDim.new(0,10)}, skipBtn); _addTextScaledMax(skipBtn, 26)

	local confirm = make("Confirm","TextButton",{
		Text="Confirm", Font=Enum.Font.GothamBold,
		TextColor3=C.confirmText or Color3.fromRGB(16,16,20),
		AutoButtonColor=true, BackgroundColor3=C.confirmBg or Color3.fromRGB(120,200,120),
		BackgroundTransparency=0.0,
		Size = UDim2.fromScale(0.48, 0.86),
	}, btnRow); make("UICorner","UICorner",{CornerRadius=UDim.new(0,10)}, confirm); _addTextScaledMax(confirm, 26)

	-- ===== グリッド（2段×6列）=====
	local gridHolder = make("GridHolder","Frame",{BackgroundTransparency=1}, panel)
	local scroll = make("Scroll","ScrollingFrame",{
		BackgroundTransparency=1, CanvasSize=UDim2.new(),
		ScrollBarThickness=6, BorderSizePixel=0,
		ScrollingDirection=Enum.ScrollingDirection.X,
		ClipsDescendants=false, -- ★ テキストのクリップ防止
	}, gridHolder)
	local gridFrame = make("Grid","Frame",{
		BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
		ClipsDescendants=false, -- ★ テキストのクリップ防止
	}, scroll)
	local layout = make("UIGrid","UIGridLayout",{
		HorizontalAlignment=Enum.HorizontalAlignment.Left,
		SortOrder=Enum.SortOrder.LayoutOrder,
		FillDirection=Enum.FillDirection.Vertical,
		FillDirectionMaxCells=GRID_ROWS,
	}, gridFrame)

	refs.panel      = panel
	refs.header     = header
	refs.headLeft   = headLeft
	refs.kitoName   = kitoName
	refs.effect     = effect
	refs.pickInfo   = pickInfo
	refs.btnRow     = btnRow
	refs.skipBtn    = skipBtn
	refs.confirm    = confirm
	refs.gridHolder = gridHolder
	refs.scroll     = scroll
	refs.gridFrame  = gridFrame
	refs.gridLayout = layout

	_uiBuilt = true
	return ui
end

--========= レスポンシブ適用 =========--
local function applyPanelAndGrid()
	if not (ui and refs.panel and refs.header and refs.gridHolder and refs.btnRow and refs.headLeft) then return end
	local vw, vh = math.max(1, ui.AbsoluteSize.X), math.max(1, ui.AbsoluteSize.Y)

	local pw, ph = calcPanelWH(vw, vh)
	refs.panel.Size = UDim2.fromScale(pw, ph)

	-- 縦配分
	local headerH = HEADER_H
	local bodyTop = headerH
	local bodyH   = 1 - headerH - FOOTER_H

	-- ヘッダー全体
	refs.header.Position = UDim2.fromScale(0, 0)
	refs.header.Size     = UDim2.fromScale(1, headerH)

	-- ヘッダー左右割り
	local btnWidthScale = 0.42 -- 右のボタンバー幅（好みで）
	refs.btnRow.AnchorPoint = Vector2.new(1, 0.5)
	refs.btnRow.Position     = UDim2.fromScale(1, 0.5)
	refs.btnRow.Size         = UDim2.fromScale(btnWidthScale, 0.9)

	refs.headLeft.Position = UDim2.fromScale(0, 0)
	refs.headLeft.Size     = UDim2.fromScale(1 - btnWidthScale - 0.02, 1)

	-- 左内訳（タイトル/説明/補足）
	refs.kitoName.Position = UDim2.fromScale(0, 0.00)
	refs.kitoName.Size     = UDim2.fromScale(1, 0.40)

	refs.effect.Position   = UDim2.fromScale(0, 0.38)
	refs.effect.Size       = UDim2.fromScale(1, 0.44)

	refs.pickInfo.AnchorPoint = Vector2.new(0,1)
	refs.pickInfo.Position    = UDim2.fromScale(0, 1)
	refs.pickInfo.Size        = UDim2.fromScale(1, 0.20)

	-- グリッド
	refs.gridHolder.Position = UDim2.fromScale(0, bodyTop)
	refs.gridHolder.Size     = UDim2.fromScale(1, bodyH)

	refs.scroll.Size = UDim2.new(1, 0, 1, 0) -- フッター無しなので全域

	-- 2段×6列のセルサイズ（Scale）
	local cellW = (1 - PAD_X * (GRID_COLS - 1)) / GRID_COLS
	local cellH = (1 - PAD_Y * (GRID_ROWS - 1)) / GRID_ROWS
	refs.gridLayout.CellSize    = UDim2.new(cellW, 0, cellH, 0)
	refs.gridLayout.CellPadding = UDim2.new(PAD_X, 0, PAD_Y, 0)

	-- CanvasSize 更新
	task.defer(function()
		local content = refs.gridLayout.AbsoluteContentSize
		refs.scroll.CanvasSize = UDim2.fromOffset(content.X, content.Y)
	end)
end

--========= 便利 =========--
local function setConfirmEnabled(enabled)
	if not refs.confirm then return end
	refs.confirm.Active = enabled
	refs.confirm.AutoButtonColor = enabled
	refs.confirm.TextTransparency = enabled and 0 or 0.4
	refs.confirm.BackgroundTransparency = enabled and 0.0 or 0.4
end

--========= 描画（カードは Renderer） =========--
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
					if current.busy then return end
					if b:GetAttribute("canPick") == false then
						local reason = b:GetAttribute("reason")
						pcall(function()
							StarterGui:SetCore("SendNotification", {
								Title="KITO", Text=reasonToText(reason) or "対象外のカードです", Duration=2,
							})
						end)
						return
					end
					current.selectedUid = (current.selectedUid == ent.uid) and nil or ent.uid
					for _, c2 in ipairs(refs.gridFrame:GetChildren()) do
						if c2:IsA("GuiObject") and type(renderer.setCardSelected)=="function" then
							renderer.setCardSelected(c2, c2:GetAttribute("uid") == current.selectedUid)
						end
					end
					setConfirmEnabled(current.selectedUid ~= nil and not current.busy)
				end)
			end
		end
	end
	applyPanelAndGrid()
	LOG.info("rebuildList: items=%d ineligible=%d selected=%s",
		#(current.list or {}), ineligible, tostring(current.selectedUid or "-"))
end

--========= 文言 =========--
local function buildEffectText(payload)
	local item = findKitoByEffectId(payload and (payload.effectId or payload.effect))
	if item then return pickDesc(item) or "" end
	if type(payload.effect)  == "string" and payload.effect  ~= "" then return payload.effect  end
	if type(payload.message) == "string" and payload.message ~= "" then return payload.message end
	if type(payload.note)    == "string" and payload.note    ~= "" then return payload.note    end
	local tgtJp = kindToJp(current.targetKind)
	return ("対象を選んでください（目標: %s）"):format(tgtJp)
end

--========= Open（Wires） =========--
local function openPayload(payload)
	local g = ensureGui()
	if g.Parent ~= LP:WaitForChild("PlayerGui") then g.Parent = LP.PlayerGui end

	current.sessionId   = payload.sessionId
	current.effectId    = payload.effectId
	current.targetKind  = tostring(payload.targetKind or "bright")
	current.selectedUid = nil
	current.busy        = false

	local eligibility = payload.eligibility or {}
	local enriched = {}
	for _, ent in ipairs(payload.list or {}) do
		local uid = tostring(ent.uid or ent.code or "")
		local eg  = eligibility[uid]
		local ok  = (type(eg)=="table" and eg.ok == true) or false
		local rsn = (type(eg)=="table" and eg.reason) or nil
		local copy = table.clone(ent); copy.eligible = ok; copy.reason = rsn
		enriched[#enriched+1] = copy
	end
	current.list, current.eligibility = enriched, eligibility

	local item = findKitoByEffectId(current.effectId or payload.effect)
	refs.kitoName.Text = item and tostring(item.name or "") or ""
	refs.effect.Text   = buildEffectText(payload)
	refs.pickInfo.Text = "Select 1 card"

	setConfirmEnabled(false)
	refs.skipBtn.Active = true
	refs.skipBtn.AutoButtonColor = true

	rebuildList()
	g.Enabled = true
	if renderer and type(renderer.show) == "function" then pcall(function() renderer.show() end) end
end

--========= Send =========--
local function sendDecide()
	if current.busy or not current.sessionId or not current.selectedUid then return end
	for _, e in ipairs(current.list or {}) do
		if e.uid == current.selectedUid and e.eligible == false then
			pcall(function()
				StarterGui:SetCore("SendNotification", {Title="KITO", Text=reasonToText(e.reason) or "対象外のカードです", Duration=2})
			end)
			return
		end
	end
	current.busy = true; setConfirmEnabled(false)
	refs.skipBtn.Active = false; refs.skipBtn.AutoButtonColor = false
	EvDecide:FireServer({ sessionId=current.sessionId, uid=current.selectedUid, targetKind=current.targetKind })
end

local function sendSkip()
	if current.busy or not current.sessionId then return end
	current.busy = true; setConfirmEnabled(false)
	refs.skipBtn.Active = false; refs.skipBtn.AutoButtonColor = false
	EvDecide:FireServer({ sessionId=current.sessionId, targetKind=current.targetKind, noChange=true })
end

--========= Result =========--
local function onResult(res)
	if not ui then return end
	current.busy = false; ui.Enabled = false
	if renderer and type(renderer.hide) == "function" then pcall(function() renderer.hide() end) end
	local function _nonEmpty(s) return type(s)=="string" and s~="" end
	local title, body
	if res.cancel then title, body = "KITO", "取消しました"
	elseif res.ok then title = "KITO"; body = _nonEmpty(res.message) and res.message or ((res.changed ~= false) and "変換が完了しました" or "選択をスキップしました")
	else title, body = "KITO (failed)", (_nonEmpty(res.message) and res.message or "処理に失敗しました") end
	pcall(function() StarterGui:SetCore("SendNotification",{Title=title, Text=body, Duration=3}) end)
	if ScreenRouter and ScreenRouter.show then pcall(function() ScreenRouter.show("shop") end) end
end

--========= 配線/初期化 =========--
local function wireButtons()
	if not ui then return end
	refs.confirm.MouseButton1Click:Connect(sendDecide)
	refs.skipBtn.MouseButton1Click:Connect(sendSkip)
	if not refs._viewConn then
		refs._viewConn = ui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyPanelAndGrid)
	end
end

ensureGui()
wireButtons()
View.gui = ui

if not script:GetAttribute("booted") then
	script:SetAttribute("booted", true)
	function View:show(payload) openPayload(payload) end
	function View:hide()
		if ui then ui.Enabled=false end
		if renderer and type(renderer.hide)=="function" then pcall(function() renderer.hide() end) end
	end
	function View:onResult(res) onResult(res) end
	function View:setLang(_) end
	function View:setRerollCounts(_,_,_) end

	local ok = pcall(function()
		if ScreenRouter and ScreenRouter.register then
			ScreenRouter.register("kitoPick", View)
		end
	end)
	if ok then LOG.info("ScreenRouter.register ok") else LOG.warn("ScreenRouter.register failed") end

	SigIncoming.Event:Connect(function(payload)
		if type(payload)~="table" then
			LOG.warn("SigIncoming: invalid payload"); return
		end
		if ScreenRouter and ScreenRouter.show then
			ScreenRouter.show("kitoPick", payload)
		else
			View:show(payload)
		end
	end)

	SigResult.Event:Connect(function(res)
		if type(res)~="table" then
			LOG.warn("SigResult: invalid result"); return
		end
		View:onResult(res)
	end)
end

return View
