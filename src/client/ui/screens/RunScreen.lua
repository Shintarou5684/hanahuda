-- StarterPlayerScripts/UI/screens/RunScreen.lua
-- v0.9.7-P2-12R5 (Confirm 未達=GiveUp 連携 / Responsive pass 維持)
--  - Confirmボタン：目標未達なら GiveUp と同じ確認モーダル→abandon を送る
--  - 状態保持を追加（_state / _scoreTotal）し、onState/onScore で更新
--  - その他の挙動・UIは現状維持

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

-- ★ 追加：ハイライト機能
local MatchHighlighter = require(screensDir.Parent:WaitForChild("highlight"):WaitForChild("MatchHighlighter"))

--==================== Responsive helpers ====================
local function _shortSide(w, h) return math.min(math.max(1, w), math.max(1, h)) end
-- 端末係数: 短辺480pxで1.0、小画面ほど1寄り。1000pxで0.0。
local function deviceFactor(w, h)
	local s = _shortSide(w, h)
	local lo, hi = 480, 1000
	local t = 1 - math.clamp((s - lo) / (hi - lo), 0, 1)
	return t
end
local function lerp(a,b,t) return a + (b-a)*t end

-- TextScaled を安全に付ける
-- ※ TextButton は 1行固定（折り返し禁止・はみ出し時は末尾省略）
local function _applyScaled(inst, maxSize)
	if not (inst and typeof(inst) == "Instance" and inst:IsA("GuiObject")) then return end
	local isLabel  = inst:IsA("TextLabel")
	local isButton = inst:IsA("TextButton")
	if not (isLabel or isButton) then return end

	inst.RichText    = inst.RichText and inst.RichText or false
	inst.TextScaled  = true
	if isButton then
		inst.TextWrapped  = false
		inst.TextTruncate = Enum.TextTruncate.AtEnd
		inst.LineHeight   = 1.0
	end
	-- Label 側は既存レイアウト尊重（Wrapped 指定があれば維持）

	local lim = inst:FindFirstChildOfClass("UITextSizeConstraint")
	if not lim then
		lim = Instance.new("UITextSizeConstraint")
		lim.Parent = inst
	end
	lim.MaxTextSize = math.max(8, math.floor(maxSize))
	-- 小さすぎる端末向けの下限（任意）
	if lim.MinTextSize ~= nil then lim.MinTextSize = 10 end
end

-- 配下の TextButton / TextLabel に一括適用
local function _scaleTextsUnder(root, titleMax, bodyMax, btnMax)
	if not (root and typeof(root) == "Instance" and root.GetDescendants) then return end
	for _, inst in ipairs(root:GetDescendants()) do
		if inst:IsA("TextLabel") then
			_applyScaled(inst, bodyMax)
		elseif inst:IsA("TextButton") then
			_applyScaled(inst, btnMax) -- ←ボタンは1行固定
		end
	end
end

--==================================================
-- Lang helpers（最小限）
--==================================================

local function normLangJa(lang)
	local v = tostring(lang or ""):lower()
	if v == "jp" then
		LOG.warn("[Locale] received legacy 'jp'; normalize to 'ja'")
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
			LOG.debug("Locale.getGlobal failed (pcall)")
		end
	end
	return nil
end

--==================================================
-- 小さな翻訳ヘルパ（フォールバック付き）
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
-- 情報パネル：シンプル表示（年/月・所持金・山札）
--==================================================
local function simpleInfoText(st, lang)
	local year     = tonumber(st and st.year) or 0
	local month    = tonumber(st and st.month) or 1
	local mon      = tonumber(st and st.mon) or 0
	local deckLeft = tonumber(st and st.deckLeft) or 0

	if lang == "ja" then
		return string.format("%d年　%d月\n所持金：%d文\n山札：%d枚", year, month, mon, deckLeft)
	else
		return string.format("Year %d  Month %d\nCash: %d Mon\nDeck: %d cards", year, month, mon, deckLeft)
	end
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
	self._hlInit = false
	self._respConn = nil -- ★ 追加：リサイズ監視

	-- ★ 追加：Confirm 判定用に保持
	self._state = nil
	self._scoreTotal = 0

	-- 言語初期値
	local initialLang = safeGetGlobalLang()
	if not initialLang then
		if type(Locale.pick) == "function" then
			initialLang = normLangJa(Locale.pick()) or "en"
		else
			initialLang = "en"
		end
	end
	self._lang = initialLang
	LOG.info("boot | lang=%s", tostring(initialLang))

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
	self.buttons       = ui.buttons   -- ※多くの場合「テーブル」で来る
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
			koikoi  = function()
				if self.deps and self.deps.DecideNext then
					self.deps.DecideNext:FireServer("next")
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

	-- ====== 護符ボード（中央下段） ======
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
	end

	--- Studio専用 DevTools（維持）
	if RunService:IsStudio() then
		local r = self.deps and self.deps.remotes or nil
		local grantRyo  = (self.deps and self.deps.DevGrantRyo) or (r and r.DevGrantRyo)
		local grantRole = (self.deps and self.deps.DevGrantRole) or (r and r.DevGrantRole)
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
	self._rerollFieldLeft = 0
	self._rerollHandLeft  = 0

	--========================
	-- レンダラー適用（内部ローカル関数）
	--========================
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

		-- ★ 追加：Confirm 判定用に保持
		self._scoreTotal = tot

		if self._scoreBox then
			local rolesBody  = Format.rolesToLines(roles, self._lang)
			local rolesLabel = (self._lang == "en") and "Roles: " or "役："
			self._scoreBox.Text = self._fmtScore(tot, mon, pts, rolesLabel .. rolesBody)
		end
		LOG.debug("score | total=%s mon=%s pts=%s roles#=%d", tostring(tot), tostring(mon), tostring(pts), #roles)
	end

	--========================
	-- Responsive 適用
	--========================
	function self:_applyResponsive()
		if not self.gui then return end
		local vw, vh = self.gui.AbsoluteSize.X, self.gui.AbsoluteSize.Y
		if vw <= 1 or vh <= 1 then return end
		local f = deviceFactor(vw, vh) -- 小画面ほど 1

		-- 情報系テキストの上限サイズ（大画面で少し大きく）
		local titleMax = math.floor(lerp(26, 32, 1-f))
		local bodyMax  = math.floor(lerp(16, 20, 1-f))
		local btnMax   = math.floor(lerp(18, 22, 1-f))

		-- buttons は table/Instance の両方に対応
		local function applyToButtons(target)
			if typeof(target) == "Instance" then
				_scaleTextsUnder(target, titleMax, bodyMax, btnMax)
			elseif type(target) == "table" then
				for _, node in pairs(target) do
					if typeof(node) == "Instance" then
						_scaleTextsUnder(node, titleMax, bodyMax, btnMax)
					end
				end
			end
		end
		applyToButtons(self.buttons)

		-- 左ペインの情報/目標/スコア
		if self.info then _applyScaled(self.info, bodyMax) end
		if self.goalText then _applyScaled(self.goalText, bodyMax) end
		if self._scoreBox then _applyScaled(self._scoreBox, bodyMax) end

		-- 護符ボードは幅スケールを微調整（小画面で少し広め）
		if self._taliBoard and typeof(self._taliBoard.setWidthScale) == "function" then
			local ws = lerp(0.88, 0.94, f)
			pcall(function() self._taliBoard:setWidthScale(ws) end)
		end

		-- 既に出ている GiveUpOverlay があれば併せて更新
		local ov = self.frame and self.frame:FindFirstChild("GiveUpOverlay")
		if ov and ov:IsA("Frame") then
			ov.BackgroundTransparency = lerp(0.28, 0.46, f)
			local p = ov:FindFirstChild("ConfirmPanel")
			if p and p:IsA("Frame") then
				p.Size = UDim2.fromScale(lerp(0.36, 0.86, f), lerp(0.26, 0.46, f))
				for _, ch in ipairs(p:GetDescendants()) do
					if ch:IsA("TextLabel") or ch:IsA("TextButton") then
						_applyScaled(ch, (ch:IsA("TextButton") and btnMax) or bodyMax)
					end
				end
			end
		end
	end

	local function _ensureRespHook()
		if self._respConn then self._respConn:Disconnect() end
		if self.gui then
			self._respConn = self.gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				self:_applyResponsive()
			end)
		end
		self:_applyResponsive()
	end
	self._ensureRespHook = _ensureRespHook

	--========================
	-- 状態更新
	--========================
	local function onState(st)
		self.info.Text = simpleInfoText(st, self._lang) or ""

		-- ★ 追加：Confirm 判定用に保持
		self._state = st

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

		-- 護符：サーバ値のみ
		if self._taliBoard
			and typeof(st) == "table"
			and typeof(st.run) == "table"
			and typeof(st.run.talisman) == "table"
		then
			self._taliBoard:setLang(self._lang or "ja")
			self._taliBoard:setData(st.run.talisman)
			local u = tonumber(st.run.talisman.unlocked or 0) or 0
			local cnt = #(st.run.talisman.slots or {})
			LOG.info("state:talisman applied | unlocked=%d slots#=%d", u, cnt)
		end

		-- 残回数 UI
		if typeof(st) == "table" then
			self:setRerollCounts(st.rerollFieldLeft, st.rerollHandLeft, st.phase)
		end

		if self._awaitingInitial then
			self._overlay:hide()
			self._awaitingInitial = false
		end
		self._resultShown = false

		self:_applyResponsive()
	end

	-- ステージ結果（全シグネチャ互換）
	local function onStageResult(a, b, _c, _d, _e)
		if typeof(a) == "table" and a.close == true then
			LOG.info("result:close (server)")
			if self._resultModal then self._resultModal:hide() end
			self._resultShown = false
			return
		end

		local data = nil
		if typeof(a) == "boolean" and a == true and typeof(b) == "table" then
			data = b
		elseif typeof(a) == "table" then
			data = a
		else
			LOG.warn("result:unknown signature (ignored)")
			return
		end

		if self._resultShown then
			LOG.debug("result:already shown (ignored)")
			return
		end
		self._resultShown = true

		local canNext, canSave
		if typeof(data.ops) == "table" then
			if typeof(data.ops.next) == "table" then canNext = (data.ops.next.enabled == true) end
			if typeof(data.ops.save) == "table" then canSave = (data.ops.save.enabled == true) end
		end

		local nextLocked
		if typeof(data.locks) == "table" then
			if typeof(data.locks.nextLocked) == "boolean" then nextLocked = data.locks.nextLocked end
		end
		if nextLocked == nil and canNext ~= nil then nextLocked = (canNext ~= true) end

		local clears = tonumber(data.clears) or 0
		if clears >= 3 then nextLocked = false end

		LOG.info("result:show | nextLocked=%s clears=%d", tostring(nextLocked), clears)

		local isFinalView = (nextLocked == true)
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
		self._resultModal:setLocked(nextLocked == true)
	end

	--========================
	-- GiveUp 確認モーダル（相対化）
	--========================
	function self:_closeGiveUpOverlay()
		if not self.frame then return end
		local existed = self.frame:FindFirstChild("GiveUpOverlay")
		if existed then existed:Destroy() end
	end

	function self:_showGiveUpConfirm(onYes)
		self:_closeGiveUpOverlay()

		local vw, vh = (self.gui and self.gui.AbsoluteSize.X) or 800, (self.gui and self.gui.AbsoluteSize.Y) or 600
		local f = deviceFactor(vw, vh)

		-- レイヤ番号（親より必ず上）
		local Z_OVERLAY = 1000
		local Z_PANEL   = 1001
		local Z_TEXT    = 1002
		local Z_BTN     = 1003

		local overlay = Instance.new("Frame")
		overlay.Name = "GiveUpOverlay"
		overlay.Parent = self.frame
		overlay.Size = UDim2.fromScale(1,1)
		overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
		overlay.BackgroundTransparency = lerp(0.28, 0.46, f)
		overlay.ZIndex = Z_OVERLAY
		overlay.Active = true

		local panel = Instance.new("Frame")
		panel.Name = "ConfirmPanel"
		panel.Parent = overlay
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.Position = UDim2.fromScale(0.5, 0.5)
		panel.Size = UDim2.fromScale(lerp(0.36, 0.86, f), lerp(0.26, 0.46, f))
		panel.BackgroundColor3 =
			(Theme and Theme.COLORS and Theme.COLORS.PanelBg) or Color3.fromRGB(245,245,245)
		panel.BorderSizePixel = 0
		panel.ZIndex = Z_PANEL
		do
			local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = panel
			local s = Instance.new("UIStroke");  s.Thickness    = 1;                s.Parent  = panel
		end

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Parent = panel
		title.BackgroundTransparency = 1
		title.Text = T(self._lang, "RUN_GIVEUP_TITLE", "このランをあきらめますか？", "Abandon this run?")
		title.Font = Enum.Font.GothamBold
		title.TextColor3 = (Theme and Theme.COLORS and Theme.COLORS.TextDefault) or Color3.fromRGB(20,20,20)
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextScaled = true
		title.ZIndex = Z_TEXT
		title.Size = UDim2.fromScale(1, 0.34)
		title.Position = UDim2.fromScale(0, 0.06)

		local body = Instance.new("TextLabel")
		body.Name = "Body"
		body.Parent = panel
		body.BackgroundTransparency = 1
		body.Text = T(self._lang, "RUN_GIVEUP_BODY",
			"途中の記録は削除され、ホームに戻ります。次回はNEW GAMEから開始します。",
			"Your in-run progress will be deleted. You'll return to Home and start from NEW GAME.")
		body.Font = Enum.Font.Gotham
		body.TextWrapped = true  -- ←本文は複数行OK
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextColor3 = (Theme and Theme.COLORS and Theme.COLORS.TextDefault) or Color3.fromRGB(40,40,40)
		body.TextScaled = true
		body.ZIndex = Z_TEXT
		body.Size = UDim2.fromScale(1, 0.36)
		body.Position = UDim2.fromScale(0, 0.40)

		local btnRow = Instance.new("Frame")
		btnRow.Name = "BtnRow"
		btnRow.Parent = panel
		btnRow.BackgroundTransparency = 1
		btnRow.AnchorPoint = Vector2.new(1, 1)
		btnRow.Size = UDim2.fromScale(0.92, 0.20)
		btnRow.Position = UDim2.fromScale(0.96, 0.96)
		btnRow.ZIndex = Z_TEXT

		local yes = Instance.new("TextButton")
		yes.Name = "Yes"
		yes.Parent = btnRow
		yes.Size = UDim2.fromScale(0.48, 1)
		yes.Position = UDim2.fromScale(0, 0)
		yes.TextScaled = true
		yes.Font = Enum.Font.GothamBold
		yes.BackgroundColor3 = (Theme and Theme.COLORS and Theme.COLORS.WarnBtnBg) or Color3.fromRGB(180,50,50)
		yes.TextColor3 = (Theme and Theme.COLORS and Theme.COLORS.TextOnPrimary) or Color3.fromRGB(255,255,255)
		yes.Text = T(self._lang, "RUN_CONFIRM_YES", "はい", "YES")
		yes.ZIndex = Z_BTN
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = yes end

		local no = Instance.new("TextButton")
		no.Name = "No"
		no.Parent = btnRow
		no.Size = UDim2.fromScale(0.48, 1)
		no.Position = UDim2.fromScale(0.52, 0)
		no.TextScaled = true
		no.Font = Enum.Font.GothamBold
		no.BackgroundColor3 = (Theme and Theme.COLORS and Theme.COLORS.InfoBtnBg) or Color3.fromRGB(60,60,60)
		no.TextColor3 = (Theme and Theme.COLORS and Theme.COLORS.TextOnPrimary) or Color3.fromRGB(255,255,255)
		no.Text = T(self._lang, "RUN_CONFIRM_NO", "いいえ", "NO")
		no.ZIndex = Z_BTN
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = no end

		local btnMax = math.floor(lerp(18, 22, 1-f))
		_applyScaled(title, math.floor(lerp(26, 32, 1-f)))
		_applyScaled(body,  math.floor(lerp(16, 20, 1-f))) -- ←Labelなので折返し維持
		_applyScaled(yes,   btnMax) -- ←Buttonは1行固定
		_applyScaled(no,    btnMax)

		local function close()
			if overlay and overlay.Parent then overlay:Destroy() end
		end

		yes.MouseButton1Click:Connect(function()
			yes.Active = false; no.Active = false
			close()
			if typeof(onYes) == "function" then onYes() end
		end)
		no.MouseButton1Click:Connect(close)

		self:_applyResponsive()
	end

	-- ボタン（必要最低限）
	if self.buttons and self.buttons.yaku then
		self.buttons.yaku.MouseButton1Click:Connect(function()
			if self._yakuPanel then self._yakuPanel:open() end
		end)
	end
	if self.buttons and self.buttons.confirm then
		self.buttons.confirm.MouseButton1Click:Connect(function()
			-- ★ 変更：目標未達なら GiveUp と同じ確認フローへ
			local goal = 0
			local st = self._state
			if typeof(st) == "table" then
				goal = tonumber(st.goal or st.target or 0) or 0
			end
			local total = tonumber(self._scoreTotal or 0) or 0

			if total >= goal then
				-- 達成：従来通り Confirm → サーバに確定
				if self.deps and self.deps.Confirm then
					self.deps.Confirm:FireServer()
				end
			else
				-- 未達：GiveUpと同じ確認モーダル→abandon
				self:_showGiveUpConfirm(function()
					LOG.info("confirm:below goal -> treat as giveup (abandon)")
					local DecideNext = self.deps and self.deps.DecideNext
					if DecideNext then
						DecideNext:FireServer("abandon")
					else
						local rem = RS:FindFirstChild("Remotes")
						local ev  = rem and rem:FindFirstChild("DecideNext")
						if ev and ev:IsA("RemoteEvent") then
							ev:FireServer("abandon")
						else
							LOG.warn("confirm->giveup: no DecideNext remote found")
						end
					end
				end)
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
	-- ★ あきらめる
	if self.buttons and self.buttons.giveUp then
		self.buttons.giveUp.MouseButton1Click:Connect(function()
			LOG.info("giveup:clicked -> confirm modal")
			self:_showGiveUpConfirm(function()
				LOG.info("giveup:confirmed -> FireServer('abandon')")
				local DecideNext = self.deps and self.deps.DecideNext
				if DecideNext then
					DecideNext:FireServer("abandon")
				else
					local rem = RS:FindFirstChild("Remotes")
					local ev  = rem and rem:FindFirstChild("DecideNext")
					if ev and ev:IsA("RemoteEvent") then
						ev:FireServer("abandon")
					else
						LOG.warn("giveup: no DecideNext remote found")
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

	--===========
	-- 公開API（Router.call 直叩き用）
	--===========
	self.onHand        = function(_, hand)   renderHand(hand) end
	self.onField       = function(_, field)  renderField(field) end
	self.onTaken       = function(_, taken)  renderTaken(taken) end
	self.onScore       = function(_, total, roles, detail) onScore(total, roles, detail) end
	self.onState       = function(_, st)     onState(st) end
	self.onStageResult = function(_, a, b, c, d, e) onStageResult(a, b, c, d, e) end

	-- 言語変更イベント購読
	if typeof(Locale.changed) == "RBXScriptSignal" then
		self._langConn = Locale.changed:Connect(function(newLang)
			self:setLang(newLang)
			self:_applyResponsive()
		end)
	end

	self:_ensureRespHook()
	LOG.info("new done | lang=%s", tostring(self._lang))
	return self
end

--==================================================
-- リロール残のUI反映
--==================================================
local function _resolveCountLabels(self)
	if self._resolvedCounterRefs then return self._resolvedCounterRefs end

	local refs = { field = nil, hand = nil }

	local function pickNearbyCountLabel(btn, preferName)
		if not (btn and btn.Parent) then return nil end
		if preferName and btn.Parent:FindFirstChild(preferName) then
			local n = btn.Parent:FindFirstChild(preferName)
			if n:IsA("TextLabel") then return n end
		end
		for _, ch in ipairs(btn.Parent:GetChildren()) do
			if ch ~= btn and ch:IsA("TextLabel") then
				local nm = string.lower(ch.Name)
				if string.find(nm, "count") or string.find(nm, "reroll") then
					return ch
				end
			end
		end
		return nil
	end

	local b = self.buttons or {}
	if typeof(b.rerollAllCount) == "Instance" and b.rerollAllCount:IsA("TextLabel") then
		refs.field = b.rerollAllCount
	end
	if typeof(b.rerollHandCount) == "Instance" and b.rerollHandCount:IsA("TextLabel") then
		refs.hand = b.rerollHandCount
	end
	if not refs.field and b.rerollAll then
		refs.field = pickNearbyCountLabel(b.rerollAll, "RerollAllCount")
	end
	if not refs.hand and b.rerollHand then
		refs.hand  = pickNearbyCountLabel(b.rerollHand, "RerollHandCount")
	end

	self._resolvedCounterRefs = refs
	return refs
end

function Run:setRerollCounts(fieldLeft, handLeft, phase)
	local f = tonumber(fieldLeft or self._rerollFieldLeft or 0) or 0
	local h = tonumber(handLeft  or self._rerollHandLeft  or 0) or 0
	self._rerollFieldLeft = f
	self._rerollHandLeft  = h

	local refs = _resolveCountLabels(self)
	local fieldLabel = refs.field
	local handLabel  = refs.hand

	if fieldLabel then
		fieldLabel.Text = tostring(f)
		fieldLabel.TextTransparency = (f > 0) and 0 or 0.3
		local st = fieldLabel:FindFirstChildOfClass("UIStroke")
		if st then st.Transparency = (f > 0) and 0 or 0.3 end
		_applyScaled(fieldLabel, 20)
	end
	if handLabel then
		handLabel.Text = tostring(h)
		handLabel.TextTransparency = (h > 0) and 0 or 0.3
		local st = handLabel:FindFirstChildOfClass("UIStroke")
		if st then st.Transparency = (h > 0) and 0 or 0.3 end
		_applyScaled(handLabel, 20)
	end

	local b = self.buttons
	if b and b.rerollAll and typeof(b.rerollAll) == "Instance" and b.rerollAll:IsA("TextButton") then
		b.rerollAll.AutoButtonColor = f > 0
		b.rerollAll.Active = (f > 0)
		_applyScaled(b.rerollAll, 22)
	end
	if b and b.rerollHand and typeof(b.rerollHand) == "Instance" and b.rerollHand:IsA("TextButton") then
		b.rerollHand.AutoButtonColor = h > 0
		b.rerollHand.Active = (h > 0)
		_applyScaled(b.rerollHand, 22)
	end

	LOG.debug("rerollCounts:update (labels) | field=%d hand=%d", f, h)
end

--==================================================
-- 言語切替
--==================================================
function Run:setLang(lang)
	local n = normLangJa(lang)
	if n ~= "ja" and n ~= "en" then
		LOG.debug("setLang ignored (invalid) | in=%s", tostring(lang))
		return
	end
	if self._lang == n then
		LOG.debug("setLang ignored (same) | lang=%s", n)
		return
	end
	LOG.info("setLang | from=%s to=%s", tostring(self._lang), tostring(n))
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
	self:_applyResponsive()
end

local function extractTalismanFromPayload(payload)
	if typeof(payload) ~= "table" then return nil end
	local s = payload.state
	if typeof(s) ~= "table" then return nil end
	local r = s.run
	if typeof(r) ~= "table" then return nil end
	return r.talisman
end

function Run:show(payload)
	if self._resultModal then self._resultModal:hide() end
	self:_closeGiveUpOverlay()
	self._resultShown = false

	if payload and payload.lang then
		local n = normLangJa(payload.lang)
		if n and n ~= self._lang then
			LOG.debug("show:payload.lang=%s (cur=%s)", tostring(n), tostring(self._lang))
			self:setLang(n)
		end
	else
		local gg = safeGetGlobalLang()
		if gg and gg ~= self._lang then
			LOG.debug("show:sync from global | %s -> %s", tostring(self._lang), tostring(gg))
			self:setLang(gg)
		end
	end

	if self._taliBoard then
		self._taliBoard:setLang(self._lang or "ja")
		local tali = extractTalismanFromPayload(payload)
		if typeof(tali) == "table" then
			self._taliBoard:setData(tali)
			LOG.info("show:init talisman applied | unlocked=%s slots#=%d",
				tostring(tali.unlocked), #(tali.slots or {}))
		end
	end

	self.frame.Visible = true
	if self._remotes then
		self._remotes:disconnect()
		LOG.debug("remotes:connect")
		self._remotes:connect()
	end

	if not self._hlInit and self.handArea and self.boardRowTop and self.boardRowBottom then
		local ok = pcall(function()
			MatchHighlighter.init(self.handArea, self.boardRowTop, self.boardRowBottom)
		end)
		self._hlInit = ok and true or false
	end

	if self._ensureRespHook then self:_ensureRespHook() end
	self:_applyResponsive()
end

function Run:requestSync()
	if not self.deps or not self.deps.ReqSyncUI then return end
	self._awaitingInitial = true
	if self._overlay then self._overlay:show() end
	LOG.info("ReqSyncUI → FireServer")
	self.deps.ReqSyncUI:FireServer()
end

function Run:hide()
	self.frame.Visible = false
	self:_closeGiveUpOverlay()
	LOG.debug("remotes:disconnect (hide)")
	if self._remotes then self._remotes:disconnect() end

	if self._hlInit then
		pcall(function() MatchHighlighter.shutdown() end)
		self._hlInit = false
	end
end

function Run:destroy()
	LOG.debug("destroy:disconnect remotes & langConn, destroy gui")
	self:_closeGiveUpOverlay()

	if self._hlInit then pcall(function() MatchHighlighter.shutdown() end) self._hlInit = false end
	if self._remotes then self._remotes:disconnect() end
	if self._langConn then self._langConn:Disconnect() end
	if self._respConn then self._respConn:Disconnect() end
	if self.gui then self.gui:Destroy() end
end

return Run
