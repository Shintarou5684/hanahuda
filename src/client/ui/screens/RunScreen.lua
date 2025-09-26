-- StarterPlayerScripts/UI/screens/RunScreen.lua
-- v0.9.7-P2-9
--  - StageResult の互換受信を強化（{close=true} / (true,data) / data 単体の全対応）
--  - Home等への遷移後にリザルトが残留しないよう、show() 冒頭で明示的に hide / _resultShown リセット
--  - 既存機能・UIは維持
--  - [FIX-S1] StatePush(onState)で護符を反映 / [FIX-S2] show()でnil上書きを防止
--  - 監視用ログを追加（[LOG] マーク）
--  - ★ サーバ確定の talisman をそのまま描画（クライアントで補完/推測しない）
--  - ★ 追加：ラン放棄（あきらめる）ボタン配線と確認モーダル

local Run = {}
Run.__index = Run

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RS                = ReplicatedStorage

-- Logger
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("RunScreen")

-- Modules
local Config = RS:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

-- 相対モジュール
local components     = script.Parent.Parent:WaitForChild("components")
local renderersDir   = components:WaitForChild("renderers")
local HandRenderer   = require(renderersDir:WaitForChild("HandRenderer"))
local FieldRenderer  = require(renderersDir:WaitForChild("FieldRenderer"))
local TakenRenderer  = require(renderersDir:WaitForChild("TakenRenderer"))
local ResultModal    = require(components:WaitForChild("ResultModal"))
local Overlay        = require(components:WaitForChild("Overlay"))
local DevTools       = require(components:WaitForChild("DevTools"))
local YakuPanel      = require(components:WaitForChild("YakuPanel"))
local TalismanBoard  = require(components:WaitForChild("TalismanBoard"))

local lib        = script.Parent.Parent:WaitForChild("lib")
local Format     = require(lib:WaitForChild("FormatUtil"))

local screensDir = script.Parent
local UIBuilder  = require(screensDir:WaitForChild("RunScreenUI"))
local RemotesCtl = require(screensDir:WaitForChild("RunScreenRemotes"))

--==================================================
-- Lang helpers（最小限）
--==================================================

local function normLangJa(lang: string?)
	local v = tostring(lang or ""):lower()
	if v == "jp" then
		LOG.warn("[Locale] received legacy 'jp'; normalize to 'ja'") -- [LOG]
		return "ja"
	elseif v == "ja" or v == "en" then
		return v
	end
	return nil
end

local function mapLangForPanel(lang)
	local n = normLangJa(lang)
	return (n == "ja") and "ja" or "en"
end

local function safeGetGlobalLang()
	if typeof(Locale.getGlobal) == "function" then
		local ok, v = pcall(Locale.getGlobal)
		if ok then
			local n = normLangJa(v)
			if n == "ja" or n == "en" then
				return n
			end
		else
			LOG.debug("Locale.getGlobal failed (pcall)") -- [LOG]
		end
	end
	return nil
end

--==================================================
-- 追加：小さな翻訳ヘルパ（フォールバック付き）
--==================================================
local function T(lang, key, jaFallback, enFallback)
	local txt = nil
	local ok = pcall(function() txt = Locale.t(lang, key) end)
	if ok and type(txt) == "string" and txt ~= "" and txt ~= key then
		return txt
	end
	if (lang == "ja") then return jaFallback end
	return enFallback
end

--==================================================
-- Class
--==================================================

function Run.new(deps)
	local self = setmetatable({}, Run)
	self.deps = deps
	self._awaitingInitial = false
	self._resultShown = false
	self._langConn = nil

	-- 言語初期値（安全取得 → Locale.pick() → "en"）※"jp" は "ja" に正規化
	local initialLang = safeGetGlobalLang()
	if not initialLang then
		if type(Locale.pick) == "function" then
			initialLang = normLangJa(Locale.pick()) or "en"
		else
			initialLang = "en"
		end
	end
	self._lang = initialLang
	LOG.info("boot | lang=%s", tostring(initialLang)) -- [LOG]

	-- UI 構築
	local ui = UIBuilder.build(nil, { lang = initialLang })
	self.gui           = ui.gui
	self.frame         = ui.root
	self.info          = ui.info
	self.goalText      = ui.goalText
	self.handArea      = ui.handArea
	self.boardRowTop   = ui.boardRowTop
	self.boardRowBottom= ui.boardRowBottom
	self.takenBox      = ui.takenBox
	self._scoreBox     = ui.scoreBox
	self.buttons       = ui.buttons
	self._ui_setLang   = ui.setLang
	self._fmtScore     = ui.formatScore or function(score, mons, pts, rolesText)
		if self._lang == "ja" then
			return string.format("得点：%d\n文%d×%d点\n%s", score or 0, mons or 0, pts or 0, rolesText or "役：--")
		else
			return string.format("Score: %d\n%dMon × %dPts\n%s", score or 0, mons or 0, pts or 0, rolesText or "Roles: --")
		end
	end

	-- Overlay / ResultModal
	local loadingText = Theme.loadingText or "Loading..."
	self._overlay     = Overlay.create(self.frame, loadingText)
	self._resultModal = ResultModal.create(self.frame)

	-- ResultModal → Nav（なければ DecideNext フォールバック）
	if self.deps and self.deps.Nav and type(self.deps.Nav.next) == "function" then
		self._resultModal:bindNav(self.deps.Nav)
	else
		self._resultModal:on({
			home  = function()
				if self.deps and self.deps.DecideNext then
					self.deps.DecideNext:FireServer("home")
				end
			end,
			next  = function()
				if self.deps and self.deps.DecideNext then
					self.deps.DecideNext:FireServer("next")
				end
			end,
			save  = function()
				if self.deps and self.deps.DecideNext then
					self.deps.DecideNext:FireServer("save")
				end
			end,
			final = function()
				if self.deps and self.deps.DecideNext then
					self.deps.DecideNext:FireServer("home")
				end
			end,
		})
	end

	-- 役倍率パネル
	self._yakuPanel = YakuPanel.mount(self.gui)

	-- ====== 護符ボード：中央カラムの下段に設置 ======
	do
		if ui.notice then
			local nb = ui.notice.Parent
			if nb then
				nb.Size = UDim2.fromScale(1, 0)
				nb.Visible = false
			end
		end
		if ui.help then
			local tb = ui.help.Parent
			if tb then
				tb.Size = UDim2.fromScale(1, 0)
				tb.Visible = false
			end
		end

		local center = nil
		if ui.handArea then center = ui.handArea.Parent end

		local taliArea = Instance.new("Frame")
		taliArea.Name = "TalismanArea"
		taliArea.Parent = center
		taliArea.BackgroundTransparency = 1
		taliArea.Size = UDim2.fromScale(1, 0)
		taliArea.AutomaticSize = Enum.AutomaticSize.Y
		taliArea.LayoutOrder = 5

		self._taliBoard = TalismanBoard.new(taliArea, {
			title = (self._lang == "ja") and "護符ボード" or "Talisman Board",
			widthScale = 0.9,
			padScale   = 0.01,
		})
		local inst = self._taliBoard:getInstance()
		inst.AnchorPoint = Vector2.new(0.5, 0)
		inst.Position    = UDim2.fromScale(0.5, 0)
		inst.ZIndex      = 2
		LOG.debug("talisman board mounted (center/bottom)") -- [LOG]
	end
	-- ====== ここまで ======

	--- Studio専用 DevTools（維持）
	if RunService:IsStudio() then
		local r = nil
		if self.deps then r = self.deps.remotes end

		local grantRyo  = nil
		if self.deps and (self.deps.DevGrantRyo ~= nil) then
			grantRyo = self.deps.DevGrantRyo
		elseif r and (r.DevGrantRyo ~= nil) then
			grantRyo = r.DevGrantRyo
		end

		local grantRole = nil
		if self.deps and (self.deps.DevGrantRole ~= nil) then
			grantRole = self.deps.DevGrantRole
		elseif r and (r.DevGrantRole ~= nil) then
			grantRole = r.DevGrantRole
		end

		if grantRyo or grantRole then
			DevTools.create(
				self.frame,
				{ DevGrantRyo = grantRyo, DevGrantRole = grantRole },
				{ grantRyoAmount = 1000, offsetX = 10, offsetY = 10, width = 160, height = 32 }
			)
		end
	end

	-- 内部状態
	self._selectedHandIdx = nil

	-- レンダラー適用
	local function renderHand(hand)
		HandRenderer.render(self.handArea, hand, {
			selectedIndex = self._selectedHandIdx,
			onSelect = function(i)
				if self._selectedHandIdx == i then
					self._selectedHandIdx = nil
				else
					self._selectedHandIdx = i
				end
				HandRenderer.render(self.handArea, hand, {
					selectedIndex = self._selectedHandIdx,
					onSelect = function(_) end,
				})
			end,
		})
		if self._awaitingInitial then
			LOG.debug("initial hand received → overlay hide") -- [LOG]
			self._overlay:hide()
			self._awaitingInitial = false
		end
	end

	local function renderField(field)
		FieldRenderer.render(self.boardRowTop, self.boardRowBottom, field, {
			rowPaddingScale = 0.02,
			onPick = function(bindex)
				if self._selectedHandIdx then
					self.deps.ReqPick:FireServer(self._selectedHandIdx, bindex)
					self._selectedHandIdx = nil
				end
			end,
		})
	end

	local function renderTaken(cards)
		TakenRenderer.renderTaken(self.takenBox, cards or {})
	end

	-- スコア更新
	local function onScore(total, roles, detail)
		if typeof(roles) ~= "table" then roles = {} end
		if typeof(detail) ~= "table" then detail = { mon = 0, pts = 0 } end
		local mon = tonumber(detail.mon) or 0
		local pts = tonumber(detail.pts) or 0
		local tot = tonumber(total) or 0
		if self._scoreBox then
			local rolesBody  = Format.rolesToLines(roles, self._lang)
			local rolesLabel = (self._lang == "en") and "Roles: " or "役："
			self._scoreBox.Text = self._fmtScore(tot, mon, pts, rolesLabel .. rolesBody)
		end
		LOG.debug("score | total=%s mon=%s pts=%s roles#=%d",
			tostring(tot), tostring(mon), tostring(pts), #roles) -- [LOG]
	end

	-- 状態更新
	local function onState(st)
		self.info.Text = Format.stateLineText(st, self._lang) or ""

		if self.goalText then
			local g = (typeof(st) == "table") and tonumber(st.goal) or nil
			local label = (self._lang == "en") and "Goal:" or "目標："
			self.goalText.Text = g and (label .. tostring(g)) or (label .. "—")
		end

		if self._yakuPanel then
			self._yakuPanel:update({
				lang    = mapLangForPanel(self._lang),
				matsuri = st and st.matsuri,
			})
		end

		-- [FIX-S1] StatePush から護符を即時反映（nilなら何もしない）
		if self._taliBoard
			and typeof(st) == "table"
			and typeof(st.run) == "table"
			and typeof(st.run.talisman) == "table"
		then
			self._taliBoard:setLang(self._lang or "ja")
			self._taliBoard:setData(st.run.talisman)
			local u = tonumber(st.run.talisman.unlocked or 0) or 0
			local cnt = #(st.run.talisman.slots or {})
			LOG.info("state:talisman applied | unlocked=%d slots#=%d", u, cnt) -- [LOG]
		else
			LOG.debug("state:talisman not present (skipped)") -- [LOG]
		end

		if self._awaitingInitial then
			LOG.debug("initial state received → overlay hide") -- [LOG]
			self._overlay:hide()
			self._awaitingInitial = false
		end
		self._resultShown = false
	end

	-- ステージ結果（全シグネチャ互換）
	local function onStageResult(a, b, _c, _d, _e)
		-- ① サーバからの明示クローズ {close=true}
		if typeof(a) == "table" and a.close == true then
			LOG.info("result:close (server)") -- [LOG]
			if self._resultModal then self._resultModal:hide() end
			self._resultShown = false
			return
		end

		-- ② 旧＆新シグネチャ正規化： (true,data) / data単体
		local data = nil
		if typeof(a) == "boolean" and a == true and typeof(b) == "table" then
			data = b
		elseif typeof(a) == "table" then
			data = a
		else
			LOG.warn("result:unknown signature (ignored)") -- [LOG]
			return
		end

		if self._resultShown then
			LOG.debug("result:already shown (ignored)") -- [LOG]
			return
		end
		self._resultShown = true

		-- 正準 ops/locks
		local canNext, canSave
		if typeof(data.ops) == "table" then
			if typeof(data.ops.next) == "table" then canNext = (data.ops.next.enabled == true) end
			if typeof(data.ops.save) == "table" then canSave = (data.ops.save.enabled == true) end
		end

		local nextLocked, saveLocked
		if typeof(data.locks) == "table" then
			if typeof(data.locks.nextLocked) == "boolean" then nextLocked = data.locks.nextLocked end
			if typeof(data.locks.saveLocked) == "boolean" then saveLocked = data.locks.saveLocked end
		end
		if nextLocked == nil and canNext ~= nil then nextLocked = (canNext ~= true) end
		if saveLocked == nil and canSave ~= nil then saveLocked = (canSave ~= true) end

		-- 通算クリア >=3 は強制開放
		local clears = tonumber(data.clears) or 0
		if clears >= 3 then
			nextLocked, saveLocked = false, false
			canNext, canSave = true, true
		end

		LOG.info("result:show | nextLocked=%s saveLocked=%s clears=%d",
			tostring(nextLocked), tostring(saveLocked), clears) -- [LOG]

		local isFinalView = (nextLocked == true and saveLocked == true)
		if isFinalView then
			local lang = self._lang or "en"
			local ttl  = Locale.t(lang, "RESULT_FINAL_TITLE")
			local desc = Locale.t(lang, "RESULT_FINAL_DESC")
			local btn  = Locale.t(lang, "RESULT_FINAL_BTN")

			self._resultModal:showFinal(
				ttl, desc, btn,
				function()
					local Nav = self.deps and self.deps.Nav
					if Nav and type(Nav.next) == "function" then
						Nav:next("home")
					elseif self.deps and self.deps.DecideNext then
						self.deps.DecideNext:FireServer("home")
					end
					self._resultModal:hide()
				end
			)
			return
		end

		self._resultModal:show(data)
		self._resultModal:setLocked(nextLocked == true, saveLocked == true)
	end

	--========================
	-- 追加：GiveUp 確認モーダル
	--========================
	function self:_closeGiveUpOverlay()
		if not self.frame then return end
		local existed = self.frame:FindFirstChild("GiveUpOverlay")
		if existed then existed:Destroy() end
	end

	function self:_showGiveUpConfirm(onYes)
		self:_closeGiveUpOverlay()

		local overlay = Instance.new("Frame")
		overlay.Name = "GiveUpOverlay"
		overlay.Parent = self.frame
		overlay.Size = UDim2.fromScale(1,1)
		overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
		overlay.BackgroundTransparency = 0.35
		overlay.ZIndex = 1000
		overlay.Active = true

		local panel = Instance.new("Frame")
		panel.Name = "ConfirmPanel"
		panel.Parent = overlay
		panel.Size = UDim2.new(0, 380, 0, 180)
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.Position = UDim2.fromScale(0.5, 0.5)
		panel.BackgroundColor3 =
			(Theme and Theme.COLORS and Theme.COLORS.PanelBg) or Color3.fromRGB(245,245,245)
		panel.BorderSizePixel = 0
		panel.ZIndex = 1001
		do
			local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = panel
			local s = Instance.new("UIStroke");  s.Thickness    = 1;                s.Parent  = panel
		end

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Parent = panel
		title.Size = UDim2.new(1, -24, 0, 32)
		title.Position = UDim2.new(0, 12, 0, 12)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.SourceSansBold
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = (Theme and Theme.COLORS and Theme.COLORS.TextDefault) or Color3.fromRGB(20,20,20)
		title.ZIndex = 1002
		title.Text = T(self._lang, "RUN_GIVEUP_TITLE",
			"このランをあきらめますか？",
			"Abandon this run?")

		local body = Instance.new("TextLabel")
		body.Name = "Body"
		body.Parent = panel
		body.Size = UDim2.new(1, -24, 0, 68)
		body.Position = UDim2.new(0, 12, 0, 52)
		body.BackgroundTransparency = 1
		body.Font = Enum.Font.SourceSans
		body.TextScaled = true
		body.TextWrapped = true
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextColor3 = (Theme and Theme.COLORS and Theme.COLORS.TextDefault) or Color3.fromRGB(40,40,40)
		body.ZIndex = 1002
		body.Text = T(self._lang, "RUN_GIVEUP_BODY",
			"途中の記録は削除され、ホームに戻ります。次回はNEW GAMEから開始します。",
			"Your in-run progress will be deleted. You'll return to Home and start from NEW GAME.")

		local yes = Instance.new("TextButton")
		yes.Name = "Yes"
		yes.Parent = panel
		yes.Size = UDim2.new(0.5, -18, 0, 40)
		yes.Position = UDim2.new(0, 12, 1, -52)
		yes.AnchorPoint = Vector2.new(0,1)
		yes.TextScaled = true
		yes.Font = Enum.Font.SourceSansBold
		yes.ZIndex = 1002
		yes.BackgroundColor3 = (Theme and Theme.COLORS and Theme.COLORS.WarnBtnBg) or Color3.fromRGB(180,50,50)
		yes.TextColor3 = (Theme and Theme.COLORS and Theme.COLORS.TextOnPrimary) or Color3.fromRGB(255,255,255)
		yes.Text = T(self._lang, "RUN_CONFIRM_YES", "はい", "YES")
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = yes end

		local no = Instance.new("TextButton")
		no.Name = "No"
		no.Parent = panel
		no.Size = UDim2.new(0.5, -18, 0, 40)
		no.Position = UDim2.new(1, -12, 1, -52)
		no.AnchorPoint = Vector2.new(1,1)
		no.TextScaled = true
		no.Font = Enum.Font.SourceSansBold
		no.ZIndex = 1002
		no.BackgroundColor3 = (Theme and Theme.COLORS and Theme.COLORS.InfoBtnBg) or Color3.fromRGB(60,60,60)
		no.TextColor3 = (Theme and Theme.COLORS and Theme.COLORS.TextOnPrimary) or Color3.fromRGB(255,255,255)
		no.Text = T(self._lang, "RUN_CONFIRM_NO", "いいえ", "NO")
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = no end

		local function close()
			if overlay and overlay.Parent then overlay:Destroy() end
		end

		yes.MouseButton1Click:Connect(function()
			yes.Active = false
			no.Active  = false
			close()
			if typeof(onYes) == "function" then
				onYes()
			end
		end)
		no.MouseButton1Click:Connect(close)
	end

	-- ボタン（必要最低限）
	if self.buttons and self.buttons.yaku then
		self.buttons.yaku.MouseButton1Click:Connect(function()
			if self._yakuPanel then self._yakuPanel:open() end
		end)
	end
	if self.buttons and self.buttons.confirm then
		self.buttons.confirm.MouseButton1Click:Connect(function()
			if self.deps and self.deps.Confirm then
				self.deps.Confirm:FireServer()
			end
		end)
	end
	if self.buttons and self.buttons.rerollAll then
		self.buttons.rerollAll.MouseButton1Click:Connect(function()
			if self.deps and self.deps.ReqRerollAll then
				self.deps.ReqRerollAll:FireServer()
			end
		end)
	end
	if self.buttons and self.buttons.rerollHand then
		self.buttons.rerollHand.MouseButton1Click:Connect(function()
			if self.deps and self.deps.ReqRerollHand then
				self.deps.ReqRerollHand:FireServer()
			end
		end)
	end
	-- ★ 新規：あきらめる
	if self.buttons and self.buttons.giveUp then
		self.buttons.giveUp.MouseButton1Click:Connect(function()
			LOG.info("giveup:clicked -> confirm modal") -- [LOG]
			self:_showGiveUpConfirm(function()
				LOG.info("giveup:confirmed -> FireServer('abandon')") -- [LOG]
				local DecideNext = self.deps and self.deps.DecideNext
				if DecideNext then
					DecideNext:FireServer("abandon")
				else
					-- フォールバック（依存注入なしでも動く）
					local rem = RS:FindFirstChild("Remotes")
					local ev  = rem and rem:FindFirstChild("DecideNext")
					if ev and ev:IsA("RemoteEvent") then
						ev:FireServer("abandon")
					else
						LOG.warn("giveup: no DecideNext remote found") -- [LOG]
					end
				end
			end)
		end)
	end

	-- Remotes
	self._remotes = RemotesCtl.create(self.deps, {
		onHand = renderHand,
		onField = renderField,
		onTaken = renderTaken,
		onScore = onScore,
		onState = onState,
		onStageResult = onStageResult,
	})

	-- 言語変更イベント購読
	if typeof(Locale.changed) == "RBXScriptSignal" then
		self._langConn = Locale.changed:Connect(function(newLang)
			self:setLang(newLang)
		end)
	end

	LOG.info("new done | lang=%s", tostring(self._lang)) -- [LOG]
	return self
end

-- 言語切替
function Run:setLang(lang)
	local n = normLangJa(lang)
	if n ~= "ja" and n ~= "en" then
		LOG.debug("setLang ignored (invalid) | in=%s", tostring(lang)) -- [LOG]
		return
	end
	if self._lang == n then
		LOG.debug("setLang ignored (same) | lang=%s", n) -- [LOG]
		return
	end
	LOG.info("setLang | from=%s to=%s", tostring(self._lang), tostring(n)) -- [LOG]
	self._lang = n
	if type(self._ui_setLang) == "function" then
		self._ui_setLang(n)
	end
	if self._yakuPanel then
		self._yakuPanel:update({ lang = mapLangForPanel(n) })
	end
	if self._taliBoard then
		self._taliBoard:setLang(self._lang or "ja")
	end
end

local function extractTalismanFromPayload(payload: any)
	if typeof(payload) ~= "table" then return nil end
	local s = payload.state
	if typeof(s) ~= "table" then return nil end
	local r = s.run
	if typeof(r) ~= "table" then return nil end
	return r.talisman
end

function Run:show(payload)
	-- ★ 安全網：表示直前にリザルト＆確認オーバーレイを必ず閉じる
	if self._resultModal then self._resultModal:hide() end
	self:_closeGiveUpOverlay()
	self._resultShown = false

	-- payload.lang を尊重（"jp" は "ja" に正規化）
	if payload and payload.lang then
		local n = normLangJa(payload.lang)
		if n and n ~= self._lang then
			LOG.debug("show:payload.lang=%s (cur=%s)", tostring(n), tostring(self._lang)) -- [LOG]
			self:setLang(n)
		end
	else
		local gg = safeGetGlobalLang()
		if gg and gg ~= self._lang then
			LOG.debug("show:sync from global | %s -> %s", tostring(self._lang), tostring(gg)) -- [LOG]
			self:setLang(gg)
		end
	end

	-- 護符ボードへ初期データを反映
	if self._taliBoard then
		self._taliBoard:setLang(self._lang or "ja")
		-- [FIX-S2] 初期payloadに有効なtalismanがある場合のみ反映（nilで空上書きしない）
		local tali = extractTalismanFromPayload(payload)
		if typeof(tali) == "table" then
			self._taliBoard:setData(tali)
			LOG.info("show:init talisman applied | unlocked=%s slots#=%d",
				tostring(tali.unlocked), #(tali.slots or {})) -- [LOG]
		else
			LOG.debug("show:init talisman not present (keep current)") -- [LOG]
		end
	end

	self.frame.Visible = true
	self._remotes:disconnect()
	LOG.debug("remotes:connect") -- [LOG]
	self._remotes:connect()
end

function Run:requestSync()
	if not self.deps or not self.deps.ReqSyncUI then return end
	self._awaitingInitial = true
	if self._overlay then self._overlay:show() end
	LOG.info("ReqSyncUI → FireServer") -- [LOG]
	self.deps.ReqSyncUI:FireServer()
end

function Run:hide()
	self.frame.Visible = false
	self:_closeGiveUpOverlay()
	LOG.debug("remotes:disconnect (hide)") -- [LOG]
	self._remotes:disconnect()
end

function Run:destroy()
	LOG.debug("destroy:disconnect remotes & langConn, destroy gui") -- [LOG]
	self:_closeGiveUpOverlay()
	self._remotes:disconnect()
	if self._langConn then self._langConn:Disconnect() end
	if self.gui then self.gui:Destroy() end
end

return Run
