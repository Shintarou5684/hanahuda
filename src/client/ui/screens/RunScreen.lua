-- StarterPlayerScripts/UI/screens/RunScreen.lua
-- プレイ画面：手札/場/取り札/ボタン と Remotes の受信描画（new(deps) + 初回同期オーバーレイ）

local Run = {}
Run.__index = Run
local RunService = game:GetService("RunService")

local function colorForKind(kind:string)
	if kind == "bright" then return Color3.fromRGB(255,230,140)
	elseif kind == "seed"  then return Color3.fromRGB(200,240,255)
	elseif kind == "ribbon"then return Color3.fromRGB(255,200,220)
	else return Color3.fromRGB(235,235,235) end
end

local function makeLabel(parent, name, text, size, pos, anchor)
	local l = Instance.new("TextLabel")
	l.Name = name; l.Parent = parent
	l.BackgroundTransparency = 1
	l.Text = text or ""; l.TextScaled = true
	l.Size = size or UDim2.new(0,100,0,24)
	l.Position = pos or UDim2.new(0,0,0,0)
	if anchor then l.AnchorPoint = anchor end
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	return l
end

local function makeCardButton(parent, w, h, label, bg)
	local b = Instance.new("TextButton")
	b.Parent = parent
	b.Size   = UDim2.new(0,w,0,h)
	b.TextWrapped = true
	b.Text = label or ""
	b.BackgroundColor3 = bg or Color3.fromRGB(230,230,230)
	b.AutoButtonColor = true
	b.BorderSizePixel = 1
	return b
end

function Run.new(deps)
	local self = setmetatable({}, Run)
	self.deps = deps
	self._conns = {}
	self._awaitingInitial = false

	local g = Instance.new("ScreenGui")
	g.Name = "RunScreen"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 10; g.Enabled = true
	self.gui = g

	local frame = Instance.new("Frame")
	frame.Name = "Root"; frame.Parent = g; frame.Size = UDim2.fromScale(1,1); frame.BackgroundTransparency = 1; frame.Visible = false
	self.frame = frame

	-- 上部情報（右詰め）※ 年を季節の左側に追加
	local info = makeLabel(frame, "Info",
		"年:----  季節:--  目標:--  合計:--  残ハンド:--  残リロール:--  倍率:--  Bank:--",
		UDim2.new(1,-20,0,32), UDim2.new(1,-10,0,6), Vector2.new(1,0))
	info.TextXAlignment = Enum.TextXAlignment.Right
	self.info = info

	-- 左：プレイエリア
	local playArea = Instance.new("Frame"); playArea.Name="PlayArea"; playArea.Parent=frame
	playArea.BackgroundTransparency = 1; playArea.Position=UDim2.new(0,10,0,44); playArea.Size=UDim2.new(1,-360,1,-140)

	local boardArea = Instance.new("Frame"); boardArea.Name="BoardArea"; boardArea.Parent=playArea
	boardArea.BackgroundTransparency = 1; boardArea.Size=UDim2.new(1,0,0,220); boardArea.Position=UDim2.new(0,0,0,0)

	local boardRowTop = Instance.new("Frame"); boardRowTop.Name="BoardRowTop"; boardRowTop.Parent=boardArea
	boardRowTop.BackgroundTransparency = 1; boardRowTop.Size=UDim2.new(1,0,0,104); boardRowTop.Position=UDim2.new(0,0,0,0)
	local layoutTop = Instance.new("UIListLayout"); layoutTop.Parent = boardRowTop
	layoutTop.FillDirection=Enum.FillDirection.Horizontal; layoutTop.Padding=UDim.new(0,8)

	local boardRowBottom = Instance.new("Frame"); boardRowBottom.Name="BoardRowBottom"; boardRowBottom.Parent=boardArea
	boardRowBottom.BackgroundTransparency = 1; boardRowBottom.Size=UDim2.new(1,0,0,104); boardRowBottom.Position=UDim2.new(0,0,0,112)
	local layoutBottom = Instance.new("UIListLayout"); layoutBottom.Parent = boardRowBottom
	layoutBottom.FillDirection=Enum.FillDirection.Horizontal; layoutBottom.Padding=UDim.new(0,8)

	local handArea = Instance.new("Frame"); handArea.Name="HandArea"; handArea.Parent=playArea
	handArea.BackgroundTransparency = 1; handArea.Size=UDim2.new(1,0,0,136); handArea.Position=UDim2.new(0,0,0,232)
	local handLayout = Instance.new("UIListLayout"); handLayout.Parent = handArea
	handLayout.FillDirection=Enum.FillDirection.Horizontal; handLayout.Padding=UDim.new(0,8)

	-- 右：取り札+得点
	local rightPane = Instance.new("Frame"); rightPane.Name="RightPane"; rightPane.Parent=frame
	rightPane.BackgroundTransparency = 0.15; rightPane.BackgroundColor3 = Color3.fromRGB(235,240,248)
	rightPane.Size=UDim2.new(0,330,1,-140); rightPane.Position=UDim2.new(1,-340,0,44)

	local _title = makeLabel(rightPane, "TakenTitle", "取り札", UDim2.new(1,-20,0,28), UDim2.new(0,10,0,6))
	local takenBox = Instance.new("ScrollingFrame"); takenBox.Name="TakenBox"; takenBox.Parent=rightPane
	takenBox.Size=UDim2.new(1,-20,0,220); takenBox.Position=UDim2.new(0,10,0,40)
	takenBox.AutomaticCanvasSize = Enum.AutomaticSize.Y; takenBox.CanvasSize = UDim2.new(0,0,0,0); takenBox.ScrollBarThickness = 8
	takenBox.BackgroundColor3 = Color3.fromRGB(248,252,255); takenBox.BackgroundTransparency = 0.2
	local takenLayout = Instance.new("UIListLayout"); takenLayout.Parent = takenBox
	takenLayout.FillDirection=Enum.FillDirection.Vertical; takenLayout.Padding=UDim.new(0,4)

	local scoreBox = makeLabel(rightPane, "ScoreBox", "得点：0\n役：--", UDim2.new(1,-20,0,90), UDim2.new(0,10,0,270))
	scoreBox.TextYAlignment = Enum.TextYAlignment.Top

	-- 下：アクションバー
	local actionBar = Instance.new("Frame"); actionBar.Name="ActionBar"; actionBar.Parent=frame
	actionBar.BackgroundTransparency = 1; actionBar.Size=UDim2.new(1,-20,0,64); actionBar.Position=UDim2.new(0,10,1,-70); actionBar.ZIndex=5
	local function makeBtn(txt) local b=Instance.new("TextButton"); b.Text=txt; b.TextScaled=true; b.Size=UDim2.new(0.24,0,1,0); b.AutoButtonColor=true; b.BackgroundColor3=Color3.fromRGB(255,255,255); b.BorderSizePixel=1; b.ZIndex=6; b.Parent=actionBar; return b end
	local btnConfirm    = makeBtn("確定（この手で勝負）");  btnConfirm.Position    = UDim2.new(0.00,0,0,0)
	local btnRerollAll  = makeBtn("全体リロール");          btnRerollAll.Position  = UDim2.new(0.26,0,0,0)
	local btnRerollHand = makeBtn("手札だけリロール");      btnRerollHand.Position = UDim2.new(0.52,0,0,0)
	local btnClearSel   = makeBtn("選択解除");              btnClearSel.Position   = UDim2.new(0.78,0,0,0)

	-- ★ 初回同期オーバーレイ
	local overlay = Instance.new("Frame")
	overlay.Name = "LoadingOverlay"; overlay.Parent = frame
	overlay.Size = UDim2.fromScale(1,1)
	overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
	overlay.BackgroundTransparency = 0.35
	overlay.Visible = false
	overlay.ZIndex = 50
	local msg = makeLabel(overlay, "Msg", "次の季節を準備中...", UDim2.new(0,480,0,48), UDim2.new(0.5,0,0.5,0), Vector2.new(0.5,0.5))
	msg.TextXAlignment = Enum.TextXAlignment.Center

	-- ★ 冬クリア用の結果モーダル
	local resultModal = Instance.new("Frame")
	resultModal.Name = "ResultModal"; resultModal.Parent = frame
	resultModal.Visible = false
	resultModal.Size = UDim2.new(0, 520, 0, 260)
	resultModal.Position = UDim2.new(0.5, 0, 0.5, 0)
	resultModal.AnchorPoint = Vector2.new(0.5, 0.5)
	resultModal.BackgroundColor3 = Color3.fromRGB(255,255,255)
	resultModal.ZIndex = 100
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,16); corner.Parent = resultModal
	local rmTitle = makeLabel(resultModal, "RmTitle", "冬 クリア！ +2両", UDim2.new(1,-20,0,48), UDim2.new(0.5,0,0,16), Vector2.new(0.5,0))
	rmTitle.TextXAlignment = Enum.TextXAlignment.Center; rmTitle.Font = Enum.Font.GothamBold
	local rmDesc  = makeLabel(resultModal, "RmDesc", "次の行き先を選んでください。", UDim2.new(1,-40,0,32), UDim2.new(0.5,0,0,70), Vector2.new(0.5,0))
	rmDesc.TextXAlignment = Enum.TextXAlignment.Center

	local btnRow = Instance.new("Frame"); btnRow.Parent = resultModal
	btnRow.Size = UDim2.new(1,-40,0,64); btnRow.Position = UDim2.new(0.5,0,0,120); btnRow.AnchorPoint = Vector2.new(0.5,0)
	btnRow.BackgroundTransparency = 1; btnRow.ZIndex = 101
	local layout = Instance.new("UIListLayout", btnRow)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 16)

	local function makeChoice(text)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0.31, 0, 1, 0)
		b.Text = text
		b.AutoButtonColor = true
		b.BackgroundColor3 = Color3.fromRGB(240,240,240)
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = b
		b.Parent = btnRow
		b.ZIndex = 102
		b:SetAttribute("OrigText", text)
		return b
	end
	local btnHome = makeChoice("帰宅する（TOPへ）")
	local btnNext = makeChoice("次のステージへ（+25年＆屋台）")
	local btnSave = makeChoice("セーブして終了")

	local function setLocked(button, locked, reason)
		local orig = button:GetAttribute("OrigText") or button.Text
		if locked then
			button.AutoButtonColor = false
			button.BackgroundColor3 = Color3.fromRGB(220,220,220)
			button.Text = orig .. "  🔒"
			button:SetAttribute("locked", true)
			if reason then button:SetAttribute("reason", reason) end
		else
			button.AutoButtonColor = true
			button.BackgroundColor3 = Color3.fromRGB(240,240,240)
			button.Text = orig
			button:SetAttribute("locked", false)
		end
	end

	-- 内部状態
	local selectedHandIdx : number? = nil

	local function clearButtons(container)
		for _,c in ipairs(container:GetChildren()) do
			if c:IsA("TextButton") or c:IsA("TextLabel") or c:IsA("Frame") or c:IsA("ImageLabel") then
				-- ボタン行の子は消さない（ResultModalのUIは保持）
				if container ~= btnRow then
					c:Destroy()
				end
			end
		end
	end

	local function highlightHandButtons()
		for _,b in ipairs(handArea:GetChildren()) do
			if b:IsA("TextButton") then
				local myIdx = b:GetAttribute("index")
				local on = (selectedHandIdx ~= nil and myIdx == selectedHandIdx)
				b.BorderSizePixel = on and 4 or 1
				b.BorderColor3 = on and Color3.fromRGB(255,180,0) or Color3.fromRGB(0,0,0)
			end
		end
	end

	-- HandPush
	local function renderHand(hand)
		clearButtons(handArea); selectedHandIdx = nil
		for i,card in ipairs(hand or {}) do
			local txt = string.format("月%02d\n%s\n%s", tonumber(card.month or 0), tostring(card.kind or "?"), card.name or "")
			local b = makeCardButton(handArea, 180, 120, txt, colorForKind(card.kind))
			b:SetAttribute("index", i)
			b.MouseButton1Click:Connect(function()
				selectedHandIdx = (selectedHandIdx == i) and nil or i
				highlightHandButtons()
			end)
		end
		-- 初回データ到着 → オーバーレイOFF
		if self._awaitingInitial then overlay.Visible=false; self._awaitingInitial=false end
	end

	-- FieldPush
	local function renderField(field)
		clearButtons(boardRowTop); clearButtons(boardRowBottom)
		local n = #(field or {}); local split = math.ceil(n/2)
		for i,card in ipairs(field or {}) do
			local txt = string.format("場  月%02d\n%s", tonumber(card.month or 0), tostring(card.kind or "?"))
			local parentRow = (i<=split) and boardRowTop or boardRowBottom
			local b = makeCardButton(parentRow, 180, 96, txt, Color3.fromRGB(250,250,250))
			b:SetAttribute("bindex", i)
			b.MouseButton1Click:Connect(function()
				if selectedHandIdx then
					deps.ReqPick:FireServer(selectedHandIdx, i)
					selectedHandIdx = nil
					highlightHandButtons()
				end
			end)
		end
	end

	-- TakenPush
	local function renderTaken(cards)
		for _,c in ipairs(takenBox:GetChildren()) do
			if c:IsA("TextLabel") then c:Destroy() end
		end
		for _,card in ipairs(cards or {}) do
			local line = Instance.new("TextLabel")
			line.Parent = takenBox; line.Size = UDim2.new(1,-8,0,26)
			line.BackgroundTransparency = 1; line.TextScaled = true
			line.TextXAlignment = Enum.TextXAlignment.Left
			line.Text = string.format("月%02d  %s  %s", tonumber(card.month or 0), tostring(card.kind or "?"), card.name or "")
		end
	end

	-- ScorePush
	local function rolesToLines(roles)
		if type(roles) ~= "table" then
			return "--"
		end
		local names = {
			five_bright="五光", four_bright="四光", rain_four_bright="雨四光", three_bright="三光",
			inoshikacho="猪鹿蝶", red_ribbon="赤短", blue_ribbon="青短",
			seeds="たね", ribbons="たん", chaffs="かす",
			hanami="花見で一杯", tsukimi="月見で一杯"
		}
		local list = {}
		for k,_ in pairs(roles) do table.insert(list, names[k] or tostring(k)) end
		table.sort(list)
		return (#list>0) and table.concat(list, " / ") or "--"
	end

	-- 新旧どちらのpayload形式でも受理
	local function onScore(a, b, c)
		local total, roles, detail
		if typeof(a) == "table" and b == nil and c == nil then
			-- 形式A: payload table
			local p = a
			total  = tonumber(p.total) or 0
			roles  = p.roles or {}
			detail = p.detail or { mon=0, pts=0 }
		else
			-- 形式B: total, roles, detail
			total  = tonumber(a) or 0
			roles  = b or {}
			detail = c or { mon=0, pts=0 }
		end
		local mon = tonumber(detail.mon) or 0
		local pts = tonumber(detail.pts) or 0
		scoreBox.Text = ("得点：%d（文%d × 点%d）\n役：%s"):format(total, mon, pts, rolesToLines(roles))
	end

	-- StatePush（年を先頭に表示）
	local function onState(st)
		st = st or {}
		local year = tonumber(st.year or st.Year) or 0
		local ytxt = (year > 0) and tostring(year) or "----"
		info.Text = ("年:%s  季節:%s  目標:%d  合計:%d  残ハンド:%d  残リロール:%d  倍率:%.1fx  Bank:%d  山:%d  手:%d")
			:format(
				ytxt,
				st.seasonStr or ("季節"..tostring(st.season or 0)),
				tonumber(st.target) or 0, tonumber(st.sum) or 0,
				tonumber(st.hands) or 0, tonumber(st.rerolls) or 0,
				tonumber(st.mult) or 1, tonumber(st.bank) or 0,
				tonumber(st.deckLeft) or 0, tonumber(st.handLeft) or 0
			)

		-- 初回データ到着 → オーバーレイOFF
		if self._awaitingInitial then overlay.Visible=false; self._awaitingInitial=false end
	end

	-- ★ StageResult（冬クリア時の3択表示）— 新旧 payload 形式どちらでも安全
	local function onStageResult(a, b, c, d, e)
		-- 形式A（新）：isClear:boolean, data:table
		-- 形式B（旧失敗）：false, seasonSum, target, mult, bank
		if typeof(a) == "boolean" then
			local isClear = a
			local data = b
			if not isClear then
				-- 失敗リザルト（演出は将来）
				return
			end
			-- クリア（冬）
			resultModal.Visible = true
			actionBar.Visible = false

			-- タイトル/説明更新
			local add = (data and tonumber(data.rewardBank)) or 2
			rmTitle.Text = ("冬 クリア！ +%d両"):format(add)
			rmDesc.Text  = (data and data.message) or "次の行き先を選んでください。"

			-- ロック状態：options 優先、無ければ canNext/canSave を明示的に評価
			local canNext, canSave = false, false
			if typeof(data) == "table" then
				if typeof(data.options) == "table" then
					if typeof(data.options.goNext) == "table" then
						canNext = (data.options.goNext.enabled == true)
					end
					if typeof(data.options.saveQuit) == "table" then
						canSave = (data.options.saveQuit.enabled == true)
					end
				end
				if not canNext and data.canNext ~= nil then
					canNext = (data.canNext == true)
				end
				if not canSave and data.canSave ~= nil then
					canSave = (data.canSave == true)
				end
			end

			setLocked(btnNext, not canNext,  "3回『帰宅』で解放")
			setLocked(btnSave, not canSave,  "3回『帰宅』で解放")
			return
		else
			-- 旧：a が seasonSum などの数値の場合。現状は冬クリアUI対象外なので無視。
			return
		end
	end

	-- ボタン操作
	btnConfirm.MouseButton1Click:Connect(function() deps.Confirm:FireServer() end)
	btnRerollAll.MouseButton1Click:Connect(function() deps.ReqRerollAll:FireServer() end)
	btnRerollHand.MouseButton1Click:Connect(function() deps.ReqRerollHand:FireServer() end)
	btnClearSel.MouseButton1Click:Connect(function()
		selectedHandIdx=nil
		for _,b in ipairs(handArea:GetChildren()) do
			if b:IsA("TextButton") then b.BorderSizePixel=1 end
		end
	end)

	-- ★ 3択：クリックで DecideNext 送信
	local function ifNotLocked(button, fn)
		button.MouseButton1Click:Connect(function()
			if button:GetAttribute("locked") then return end
			fn()
		end)
	end
	ifNotLocked(btnHome, function()
		resultModal.Visible = false
		actionBar.Visible = true
		if deps.DecideNext then
			deps.DecideNext:FireServer("home")
		end
	end)
	ifNotLocked(btnNext, function()
		resultModal.Visible = false
		actionBar.Visible = true
		if deps.DecideNext then
			deps.DecideNext:FireServer("next")
		end
	end)
	ifNotLocked(btnSave, function()
		resultModal.Visible = false
		actionBar.Visible = true
		if deps.DecideNext then
			deps.DecideNext:FireServer("save")
		end
	end)

	-- Remote接続（画面表示時だけ）
	local function connectRemotes()
		table.insert(self._conns, deps.HandPush .OnClientEvent:Connect(renderHand))
		table.insert(self._conns, deps.FieldPush.OnClientEvent:Connect(renderField))
		table.insert(self._conns, deps.TakenPush.OnClientEvent:Connect(renderTaken))
		-- onScore は新旧両対応
		table.insert(self._conns, deps.ScorePush.OnClientEvent:Connect(function(...) onScore(...) end))
		table.insert(self._conns, deps.StatePush.OnClientEvent:Connect(onState))
		-- ★ 新規：冬クリア用の結果モーダル
		if deps.StageResult then
			table.insert(self._conns, deps.StageResult.OnClientEvent:Connect(function(...) onStageResult(...) end))
		end
	end
	local function disconnectRemotes()
		for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
		table.clear(self._conns)
	end
	self._connectRemotes = connectRemotes
	self._disconnectRemotes = disconnectRemotes

	-- Studio DEV ボタン
	if RunService:IsStudio() and (deps.DevGrantRyo or deps.DevGrantRole) then
		local devFrame = Instance.new("Frame")
		devFrame.Name = "DevRow"; devFrame.AnchorPoint = Vector2.new(0.5, 1)
		devFrame.Position = UDim2.new(0.5, 0, 0.86, 0)
		devFrame.Size = UDim2.new(0, 160, 0, 32)
		devFrame.BackgroundTransparency = 1
		devFrame.Parent = frame
		local dlayout = Instance.new("UIListLayout")
		dlayout.FillDirection = Enum.FillDirection.Horizontal
		dlayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		dlayout.Padding = UDim.new(0, 8)
		dlayout.Parent = devFrame
		local function makeDevBtn(t, fn)
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(0, 70, 1, 0)
			b.Text = t
			b.AutoButtonColor = true
			b.BackgroundColor3 = Color3.fromRGB(35,130,90)
			b.TextColor3 = Color3.fromRGB(255,255,255)
			b.Font = Enum.Font.GothamBold
			b.TextSize = 16
			b.Parent = devFrame
			local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = b
			b.Activated:Connect(fn)
		end
		if deps.DevGrantRole then makeDevBtn("+役", function() deps.DevGrantRole:FireServer() end) end
		if deps.DevGrantRyo  then makeDevBtn("+両", function() deps.DevGrantRyo:FireServer(1000) end) end
	end

	-- 参照保持
	self._takenBox = takenBox
	self._scoreBox = scoreBox
	self._overlay  = overlay

	-- ★ Router.call で呼ばれる公開メソッドをバインド
	self.onHand  = renderHand
	self.onField = renderField
	self.onTaken = renderTaken
	self.onScore = onScore
	self.onState = onState

	return self
end

function Run:show()
	self.frame.Visible = true
	self:_disconnectRemotes(); self:_connectRemotes()
end

-- ★ 外部呼び出し：新ラウンド等の直後に1回だけ再同期させる
function Run:requestSync()
	if not self.deps or not self.deps.ReqSyncUI then return end
	self._awaitingInitial = true
	if self._overlay then self._overlay.Visible = true end
	self.deps.ReqSyncUI:FireServer()
end

-- （以下 hide/destroy）
function Run:hide()
	self.frame.Visible = false
	self:_disconnectRemotes()
end

function Run:destroy()
	self:_disconnectRemotes()
	if self.gui then self.gui:Destroy() end
end

return Run
