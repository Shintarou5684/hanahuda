-- StarterPlayerScripts/ClientGuiController (LocalScript, v0.8.0 koi-koi)
print("[UI] ready")

--==================================================
-- Services / Remotes
--==================================================
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes")

-- 後方互換つき Remote 取得ヘルパ
local function getRemote(name: string)
	-- まず Remotes フォルダ内を優先、無ければ直下（旧版互換）、最後に Remotes:WaitForChild
	return Remotes:FindFirstChild(name) or RS:FindFirstChild(name) or Remotes:WaitForChild(name)
end

-- 受信（互換ヘルパで取得）
local HandPush   = getRemote("HandPush")
local FieldPush  = getRemote("FieldPush")
local TakenPush  = getRemote("TakenPush")
local ScorePush  = getRemote("ScorePush")
local StatePush  = getRemote("StatePush")
local ShopOpen   = getRemote("ShopOpen")

-- 送信（互換ヘルパで取得）
local Confirm        = getRemote("Confirm")
local ReqPick        = getRemote("ReqPick")
local ReqRerollAll   = getRemote("ReqRerollAll")
local ReqRerollHand  = getRemote("ReqRerollHand")
local ShopDone       = getRemote("ShopDone")
local BuyItem        = getRemote("BuyItem")       -- ★ 購入
local ShopReroll     = getRemote("ShopReroll")    -- ★ リロール

local player = Players.LocalPlayer

-- PlayerGui/Main が無い環境でも動くようにフォールバック作成
local pg = player:WaitForChild("PlayerGui")
local gui = pg:FindFirstChild("Main")
if not gui then
	gui = Instance.new("ScreenGui")
	gui.Name = "Main"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = pg
end

--==================================================
-- カラー/ユーティリティ
--==================================================
local function colorForKind(kind:string)
	if kind == "bright" then return Color3.fromRGB(255,230,140)
	elseif kind == "seed" then return Color3.fromRGB(200,240,255)
	elseif kind == "ribbon" then return Color3.fromRGB(255,200,220)
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

local function makeCardButton(parent, width, height, label, bg)
	local b = Instance.new("TextButton")
	b.Parent = parent
	b.Size   = UDim2.new(0,width,0,height)
	b.TextWrapped = true
	b.Text = label
	b.BackgroundColor3 = bg or Color3.fromRGB(230,230,230)
	b.AutoButtonColor = true
	b.BorderSizePixel = 1
	return b
end

local function clearChildrenButtons(frame)
	for _,c in ipairs(frame:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("TextLabel") or c:IsA("Frame") or c:IsA("ImageLabel") then
			c:Destroy()
		end
	end
end


--==================================================
-- 画面レイアウト（大枠）
--==================================================
-- infoバー（最上段）
local info = makeLabel(gui, "Info",
	"季節:--  目標スコア:--  合計:--  残ハンド:--  残リロール:--  倍率:--  Bank:--",
	UDim2.new(1,-20,0,32), UDim2.new(0,10,0,6))

-- 左：プレイエリア（場札 2段 + 手札1段 を同じ枠に収容）
local playArea = Instance.new("Frame")
playArea.Name = "PlayArea"; playArea.Parent = gui
playArea.BackgroundTransparency = 1
playArea.Position = UDim2.new(0,10,0,44)
playArea.Size     = UDim2.new(1,-360,1,-140)

-- └─ 場札（2段）
local boardArea = Instance.new("Frame")
boardArea.Name = "BoardArea"; boardArea.Parent = playArea
boardArea.BackgroundTransparency = 1
boardArea.Size = UDim2.new(1,0,0,220)
boardArea.Position = UDim2.new(0,0,0,0)

local boardRowTop = Instance.new("Frame")
boardRowTop.Name = "BoardRowTop"; boardRowTop.Parent = boardArea
boardRowTop.BackgroundTransparency = 1
boardRowTop.Size = UDim2.new(1,0,0,104)
boardRowTop.Position = UDim2.new(0,0,0,0)
local brtList = Instance.new("UIListLayout", boardRowTop)
brtList.FillDirection = Enum.FillDirection.Horizontal
brtList.Padding       = UDim.new(0,8)

local boardRowBottom = Instance.new("Frame")
boardRowBottom.Name = "BoardRowBottom"; boardRowBottom.Parent = boardArea
boardRowBottom.BackgroundTransparency = 1
boardRowBottom.Size = UDim2.new(1,0,0,104)
boardRowBottom.Position = UDim2.new(0,0,0,112)
local brbList = Instance.new("UIListLayout", boardRowBottom)
brbList.FillDirection = Enum.FillDirection.Horizontal
brbList.Padding       = UDim.new(0,8)

-- └─ 手札（同じプレイエリア内・下段）
local handArea = Instance.new("Frame")
handArea.Name = "HandArea"; handArea.Parent = playArea
handArea.BackgroundTransparency = 1
handArea.Size = UDim2.new(1,0,0,136)
handArea.Position = UDim2.new(0,0,0,232)
local handList = Instance.new("UIListLayout", handArea)
handList.FillDirection = Enum.FillDirection.Horizontal
handList.Padding       = UDim.new(0,8)

-- 右：取り札 + 得点（別枠）
local rightPane = Instance.new("Frame")
rightPane.Name = "RightPane"; rightPane.Parent = gui
rightPane.BackgroundTransparency = 0.15
rightPane.BackgroundColor3 = Color3.fromRGB(235,240,248)
rightPane.Size     = UDim2.new(0,330,1,-140)
rightPane.Position = UDim2.new(1,-340,0,44)

local takenTitle = makeLabel(rightPane, "TakenTitle", "取り札", UDim2.new(1,-20,0,28), UDim2.new(0,10,0,6))
local takenBox = Instance.new("ScrollingFrame")
takenBox.Name = "TakenBox"; takenBox.Parent = rightPane
takenBox.Size  = UDim2.new(1,-20,0,220)
takenBox.Position = UDim2.new(0,10,0,40)
takenBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
takenBox.CanvasSize = UDim2.new(0,0,0,0)
takenBox.ScrollBarThickness = 8
takenBox.BackgroundColor3 = Color3.fromRGB(248,252,255)
takenBox.BackgroundTransparency = 0.2
local takenList = Instance.new("UIListLayout", takenBox)
takenList.FillDirection = Enum.FillDirection.Vertical
takenList.Padding       = UDim.new(0,4)

local scoreBox = makeLabel(rightPane, "ScoreBox", "スコア：0\n役：--", UDim2.new(1,-20,0,90), UDim2.new(0,10,0,270))
scoreBox.TextYAlignment = Enum.TextYAlignment.Top

--==================================================
-- 下段：アクションバー（横一列）
--==================================================
local actionBar = Instance.new("Frame")
actionBar.Name = "ActionBar"; actionBar.Parent = gui
actionBar.BackgroundTransparency = 1
actionBar.Size = UDim2.new(1,-20,0,64)
actionBar.Position = UDim2.new(0,10,1,-70)
actionBar.ZIndex = 5

local function makeBtn(txt)
	local b = Instance.new("TextButton")
	b.Text = txt; b.TextScaled = true
	b.Size = UDim2.new(0.24,0,1,0)
	b.AutoButtonColor = true
	b.BackgroundColor3 = Color3.fromRGB(255,255,255)
	b.BorderSizePixel = 1
	b.ZIndex = 6
	return b
end

local btnConfirm    = makeBtn("清算");  btnConfirm.Parent    = actionBar; btnConfirm.Position    = UDim2.new(0.00,0,0,0)
local btnRerollAll  = makeBtn("リロール");          btnRerollAll.Parent  = actionBar; btnRerollAll.Position  = UDim2.new(0.26,0,0,0)
local btnRerollHand = makeBtn("手札を引き直す");      btnRerollHand.Parent = actionBar; btnRerollHand.Position = UDim2.new(0.52,0,0,0)
local btnClearSel   = makeBtn("選択解除");              btnClearSel.Parent   = actionBar; btnClearSel.Position   = UDim2.new(0.78,0,0,0)

--==================================================
-- 表示用の作業変数
--==================================================
local currentHand  = {}         -- {card}
local selectedHandIdx : number? = nil
local currentField = {}         -- {card}
local currentTaken = {}         -- {card}

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

--==================================================
-- レンダリング：手札
--==================================================
local function renderHand(hand)
	currentHand = hand or {}
	clearChildrenButtons(handArea)
	selectedHandIdx = nil

	for i,card in ipairs(currentHand) do
		local txt = string.format("月%02d\n%s\n%s", card.month, card.kind, card.name or "")
		local b = makeCardButton(handArea, 180, 120, txt, colorForKind(card.kind))
		b:SetAttribute("index", i)
		b.MouseButton1Click:Connect(function()
			selectedHandIdx = (selectedHandIdx == i) and nil or i
			highlightHandButtons()
		end)
	end
end
HandPush.OnClientEvent:Connect(renderHand)

--==================================================
-- レンダリング：場札（2段に自動分割）
--==================================================
local function renderField(field)
	currentField = field or {}
	clearChildrenButtons(boardRowTop)
	clearChildrenButtons(boardRowBottom)

	local n = #currentField
	local split = math.ceil(n/2)

	for i,card in ipairs(currentField) do
		local txt = string.format("場  月%02d\n%s", card.month, card.kind)
		local parentRow = (i<=split) and boardRowTop or boardRowBottom
		local b = makeCardButton(parentRow, 180, 96, txt, Color3.fromRGB(250,250,250))
		b:SetAttribute("bindex", i)
		b.MouseButton1Click:Connect(function()
			if selectedHandIdx then
				-- boardIdx を指定してサーバへ。サーバ側で月一致なら取得、違えば場に置く。
				ReqPick:FireServer(selectedHandIdx, i)
				selectedHandIdx = nil
				highlightHandButtons()
			end
		end)
	end
end
FieldPush.OnClientEvent:Connect(renderField)

--==================================================
-- レンダリング：取り札（右パネル）
--==================================================
local function renderTaken(cards)
	currentTaken = cards or {}
	for _,c in ipairs(takenBox:GetChildren()) do
		if c:IsA("TextLabel") then c:Destroy() end
	end
	for _,card in ipairs(currentTaken) do
		local line = Instance.new("TextLabel")
		line.Parent = takenBox
		line.Size = UDim2.new(1, -8, 0, 26)
		line.BackgroundTransparency = 1
		line.TextScaled = true
		line.TextXAlignment = Enum.TextXAlignment.Left
		line.Text = string.format("月%02d  %s  %s", card.month, card.kind, card.name or "")
	end
end
TakenPush.OnClientEvent:Connect(renderTaken)

--==================================================
-- 得点/役・状態
--==================================================
local function rolesToLines(roles)
	local names = {
		five_bright="五光", four_bright="四光", rain_four_bright="雨四光", three_bright="三光",
		inoshikacho="猪鹿蝶", red_ribbon="赤短", blue_ribbon="青短",
		seeds="たね", ribbons="たん", chaffs="かす",
		hanami="花見で一杯", tsukimi="月見で一杯"
	}
	local list = {}
	for k,_ in pairs(roles or {}) do table.insert(list, names[k] or k) end
	table.sort(list)
	return (#list>0) and table.concat(list, " / ") or "--"
end

-- ScorePush は total, roles, detail{mon,pts} を受け取る
ScorePush.OnClientEvent:Connect(function(total, roles, detail)
	local mon = (detail and detail.mon) or 0
	local pts = (detail and detail.pts) or 0

	scoreBox.Text = ("得点：%d（文%d × 点%d）\n役：%s")
		:format(total or 0, mon, pts, rolesToLines(roles))

	-- ボタンの半無効化ロジックは total 基準に
	local active = (total or 0) > 0
	btnConfirm.AutoButtonColor = active
	btnConfirm.BackgroundColor3 = active and Color3.fromRGB(235,244,255) or Color3.fromRGB(230,230,230)
	btnConfirm.Text = active and "確定（この手で勝負）" or "確定（役ができていません）"
end)

-- 状態更新
StatePush.OnClientEvent:Connect(function(st)
	-- fallbackで数値表記にも対応
	local seasonDisp = st.seasonStr or ("季節"..tostring(st.season or 0))
	info.Text = ("季節:%s  目標:%d  合計:%d  残ハンド:%d  残リロール:%d  倍率:%.1fx  Bank:%d  山:%d  手:%d")
		:format(seasonDisp, st.target or 0, st.sum or 0,
			st.hands or st.handsLeft or 0, st.rerolls or 0, st.mult or 1,
			st.bank or 0, st.deckLeft or 0, st.handLeft or st.hands or st.handsLeft or 0)

	local canReroll = (st.rerolls or 0) > 0
	for _,b in ipairs({btnRerollAll, btnRerollHand}) do
		b.AutoButtonColor = canReroll
		b.BackgroundColor3 = canReroll and Color3.fromRGB(255,255,255) or Color3.fromRGB(230,230,230)
		b.Active = canReroll
	end
end)

--==================================================
-- 操作（ボタン）
--==================================================
btnConfirm.MouseButton1Click:Connect(function()
	Confirm:FireServer()
end)

btnRerollAll.MouseButton1Click:Connect(function()
	ReqRerollAll:FireServer()
end)

btnRerollHand.MouseButton1Click:Connect(function()
	ReqRerollHand:FireServer()
end)

btnClearSel.MouseButton1Click:Connect(function()
	selectedHandIdx = nil
	highlightHandButtons()
end)

--==================================================
-- 屋台（モーダル）
--==================================================
local shopModal = Instance.new("Frame")
shopModal.Name = "ShopModal"; shopModal.Parent = gui
shopModal.Size = UDim2.new(0.7,0,0.6,0)
shopModal.Position = UDim2.new(0.5,0,0.5,0)
shopModal.AnchorPoint = Vector2.new(0.5,0.5)
shopModal.BackgroundColor3 = Color3.fromRGB(255,255,255)
shopModal.BorderSizePixel = 2
shopModal.Visible = false
shopModal.ZIndex = 50

local shopTitle = makeLabel(shopModal, "Title", "屋台", UDim2.new(1,-20,0,36), UDim2.new(0,10,0,10))
shopTitle.TextXAlignment = Enum.TextXAlignment.Center
shopTitle.ZIndex = 51

local shopInfo = makeLabel(shopModal, "Info", "", UDim2.new(1,-20,0,60), UDim2.new(0,10,0,54))
shopInfo.ZIndex = 51

local shopList = Instance.new("ScrollingFrame")
shopList.Name = "List"; shopList.Parent = shopModal
shopList.Size = UDim2.new(1,-20,1,-150)
shopList.Position = UDim2.new(0,10,0,120)
shopList.BackgroundTransparency = 1
shopList.CanvasSize = UDim2.new(0,0,0,0)
shopList.ScrollBarThickness = 8
shopList.ZIndex = 51
local shopLayout = Instance.new("UIListLayout", shopList)
shopLayout.Padding = UDim.new(0,6)

-- リロールボタン（1文）
local rerollBtn = Instance.new("TextButton")
rerollBtn.Parent = shopModal
rerollBtn.Size = UDim2.new(0,200,0,36)
rerollBtn.Position = UDim2.new(0,12,1,-56)
rerollBtn.Text = "品揃えを更新（1文）"
rerollBtn.TextScaled = true
rerollBtn.BackgroundColor3 = Color3.fromRGB(244,244,244)
rerollBtn.ZIndex = 51
rerollBtn.MouseButton1Click:Connect(function()
	ShopReroll:FireServer()
end)

local closeShopBtn = Instance.new("TextButton")
closeShopBtn.Parent = shopModal
closeShopBtn.Size = UDim2.new(0,220,0,44)
closeShopBtn.Position = UDim2.new(0.5, -110, 1, -56)
closeShopBtn.Text = "屋台を閉じて次の季節へ"
closeShopBtn.TextScaled = true
closeShopBtn.BackgroundColor3 = Color3.fromRGB(235,244,255)
closeShopBtn.ZIndex = 51

-- 屋台を開く
-- payload = {
--   season, target, seasonSum, rewardMon, totalMon,
--   stock=[{id,name,category,price,icon,effect},...],
--   notice=?, canReroll=?
-- }
ShopOpen.OnClientEvent:Connect(function(payload)
	local infoTxt = ("達成！ 合計:%d / 目標:%d\n報酬：%d 文 を受け取りました（所持：%d 文）")
		:format(payload.seasonSum or 0, payload.target or 0, payload.rewardMon or 0, payload.totalMon or 0)
	if payload.notice and #tostring(payload.notice) > 0 then
		infoTxt = infoTxt .. "\n" .. tostring(payload.notice)
	end
	shopInfo.Text = infoTxt

	-- ボタン群を無効化してモーダルに集中
	actionBar.Visible = false

	-- 屋台の商品リスト再描画（購入可能かで見た目変更）
	clearChildrenButtons(shopList)
	local money = payload.totalMon or 0

	for _,it in ipairs(payload.stock or {}) do
		local row = Instance.new("Frame")
		row.Parent = shopList
		row.Size = UDim2.new(1, -4, 0, 48)
		row.BackgroundTransparency = 1
		row.ZIndex = 51

		local btn = Instance.new("TextButton")
		btn.Parent = row
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.ZIndex = 52
		btn.TextScaled = true

		local tag = ({kito="祈祷", sai="祭事", omamori="お守り"})[it.category] or it.category or ""
		local price = it.price or 0
		local canBuy = money >= price
		btn.Text = string.format("[%s] %s  -  %d 文", tag, it.name or it.id, price)
		btn.AutoButtonColor = canBuy
		btn.Active = canBuy
		btn.BackgroundColor3 = canBuy and Color3.fromRGB(248,252,255) or Color3.fromRGB(235,235,235)

		btn.MouseButton1Click:Connect(function()
			if canBuy then
				BuyItem:FireServer(it.id)
			end
		end)
	end

	task.wait()
	shopList.CanvasSize = UDim2.new(0,0,0, shopLayout.AbsoluteContentSize.Y + 8)

	shopModal.Visible = true

	-- リロールボタンの有効/無効（サーバ判定）
	local canR = payload.canReroll == true
	rerollBtn.Active = canR
	rerollBtn.AutoButtonColor = canR
	rerollBtn.BackgroundColor3 = canR and Color3.fromRGB(244,244,244) or Color3.fromRGB(230,230,230)
end)

-- 屋台を閉じて次へ
closeShopBtn.MouseButton1Click:Connect(function()
	shopModal.Visible = false
	actionBar.Visible = true
	ShopDone:FireServer()
end)

--==================================================
-- DEV ボタン（Studio のみ）
--==================================================
local RunService = game:GetService("RunService")
local DEV_VISIBLE = RunService:IsStudio()

if DEV_VISIBLE then
	-- ★ Remotes フォルダ優先 + 後方互換
	local DevGrantRole = getRemote("DevGrantRole")
	local DevGrantRyo  = getRemote("DevGrantRyo")

	local sg = Instance.new("ScreenGui")
	sg.Name = "DevRowGui"
	sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 50
	sg.Parent = pg

	local frame = Instance.new("Frame")
	frame.Name = "DevRow"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 0.86, 0)  -- 手札と下段コマンドの間
	frame.Size = UDim2.new(0, 160, 0, 32)
	frame.BackgroundTransparency = 1
	frame.Active = false
	frame.Parent = sg

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = frame

	local function makeDevBtn(t, fn)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 70, 1, 0)
		b.Text = t
		b.AutoButtonColor = true
		b.BackgroundColor3 = Color3.fromRGB(35,130,90)
		b.TextColor3 = Color3.fromRGB(255,255,255)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 16
		b.Parent = frame
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = b
		b.Activated:Connect(fn)
	end

	-- 【+役】…取り札に「酒・月・花」を注入（花見酒＋月見酒）
	makeDevBtn("+役", function()
		DevGrantRole:FireServer()
	end)

	-- 【+両】…Bank を +1000
	makeDevBtn("+両", function()
		DevGrantRyo:FireServer(1000)
	end)
end
