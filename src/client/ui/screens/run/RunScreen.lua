-- StarterPlayerScripts/UI/screens/run/RunScreen.lua
-- v0.9.7-P2-12R6 (mod-split)
--  - 大型化した RunScreen を分割モジュールへ委譲
--  - Confirm 未達=GiveUp は ConfirmFlow に委譲
--  - GiveUp モーダルは components/GiveUpConfirm に委譲
--  - リロール残の表示は RerollUi に委譲
--  - レスポンシブは Responsive に委譲
--  - StageResult 表示は ResultHandler に委譲
--  - ※各モジュールが無い場合は「エラーを出すだけ」でフォールバック実装は行わない

local Run = {}
Run.__index = Run

-- Services
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RS                = ReplicatedStorage

-- Logger
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("RunScreen")

-- Config
local Config = RS:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

-- UI tree roots（このファイルは screens/run 配下）
local runDir      = script.Parent                       -- .../screens/run
local screensRoot = script.Parent.Parent                -- .../screens
local uiRoot      = script.Parent.Parent.Parent         -- .../UI

-- Components / Renderers
local components     = uiRoot:WaitForChild("components")
local renderersDir   = components:WaitForChild("renderers")
local HandRenderer   = require(renderersDir:WaitForChild("HandRenderer"))
local FieldRenderer  = require(renderersDir:WaitForChild("FieldRenderer"))
local TakenRenderer  = require(renderersDir:WaitForChild("TakenRenderer"))
local ResultModal    = require(components:WaitForChild("ResultModal"))
local Overlay        = require(components:WaitForChild("Overlay"))
local DevTools       = require(components:WaitForChild("DevTools"))
local YakuPanel      = require(components:WaitForChild("YakuPanel"))
local TalismanBoard  = require(components:WaitForChild("TalismanBoard"))

-- Shared lib
local lib        = uiRoot:WaitForChild("lib")
local Format     = require(lib:WaitForChild("FormatUtil"))

-- Screen-local modules
local UIBuilder  = require(runDir:WaitForChild("RunScreenUI"))
local RemotesCtl = require(runDir:WaitForChild("RunScreenRemotes"))

-- Optional helpers（存在しない場合はエラー出力のみ）
local function _tryRequire(desc, getter)
	local ok, mod = pcall(getter)
	if ok and mod then return mod end
	LOG.error("missing module: %s (%s)", tostring(desc), tostring(mod))
	return nil
end

local MatchHighlighter = _tryRequire("highlight/MatchHighlighter", function()
	return require(uiRoot:WaitForChild("highlight"):WaitForChild("MatchHighlighter"))
end)

local GiveUpConfirm = _tryRequire("components/GiveUpConfirm", function()
	return require(components:WaitForChild("GiveUpConfirm"))
end)
local ConfirmFlow = _tryRequire("run/ConfirmFlow", function()
	return require(runDir:WaitForChild("ConfirmFlow"))
end)
local ResultHandler = _tryRequire("run/ResultHandler", function()
	return require(runDir:WaitForChild("ResultHandler"))
end)
local RerollUi = _tryRequire("run/RerollUi", function()
	return require(runDir:WaitForChild("RerollUi"))
end)
local Responsive = _tryRequire("run/Responsive", function()
	return require(runDir:WaitForChild("Responsive"))
end)
local StateCache = _tryRequire("run/StateCache", function()
	return require(runDir:WaitForChild("StateCache"))
end)

--==================== Lang helpers ====================
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
			if n == "ja" or n == "en" then return n end
		end
	end
	return nil
end

-- 情報パネル：シンプル表示
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
	self._respConn = nil

	-- 状態保持は StateCache に委譲（なければ最低限の代替テーブル）
	self._cache = (StateCache and StateCache.new and StateCache.new()) or { state=nil, total=0 }

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
			if nb then nb.Size = UDim2.fromScale(1, 0); nb.Visible = false end
		end
		if ui.help then
			local tb = ui.help.Parent
			if tb then tb.Size = UDim2.fromScale(1, 0); tb.Visible = false end
		end

		local center = ui.handArea and ui.handArea.Parent
		local taliArea = Instance.new("Frame")
		taliArea.Name = "TalismanArea"
		taliArea.Parent = center
		taliArea.BackgroundTransparency = 1
		taliArea.Size = UDim2.fromScale(1, 0)
		taliArea.AutomaticSize = Enum.AutomaticSize.Y
		taliArea.LayoutOrder = 5

		self._taliBoard = TalismanBoard.new(taliArea, {
			title      = (self._lang == "ja") and "護符ボード" or "Talisman Board",
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

	--========================
	-- レンダラー（ローカル関数）
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

		-- 状態保持
		if StateCache and StateCache.onScore then
			StateCache.onScore(self._cache, tot)
		else
			self._cache.total = tot
		end

		if self._scoreBox then
			local rolesBody  = Format.rolesToLines(roles, self._lang)
			local rolesLabel = (self._lang == "en") and "Roles: " or "役："
			self._scoreBox.Text = self._fmtScore(tot, mon, pts, rolesLabel .. rolesBody)
		end
	end

	-- 状態更新
	local function onState(st)
		self.info.Text = simpleInfoText(st, self._lang) or ""

		-- 状態保持
		if StateCache and StateCache.onState then
			StateCache.onState(self._cache, st)
		else
			self._cache.state = st
		end

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
		end

		-- リロール残（RerollUi に委譲）
		if RerollUi and RerollUi.setCounts then
			RerollUi.setCounts(self, st.rerollFieldLeft, st.rerollHandLeft, st.phase)
		else
			LOG.error("RerollUi.setCounts missing")
		end

		if self._awaitingInitial then
			self._overlay:hide()
			self._awaitingInitial = false
		end
		self._resultShown = false
	end

	-- ステージ結果（委譲）
	local function onStageResult(a, b, _c, _d, _e)
		if typeof(a) == "table" and a.close == true then
			if self._resultModal then self._resultModal:hide() end
			self._resultShown = false
			return
		end
		if self._resultShown then return end
		self._resultShown = true

		if ResultHandler and ResultHandler.handle then
			ResultHandler.handle(self._resultModal, self.deps, self._lang, a, b)
		else
			LOG.error("ResultHandler.handle missing")
		end
	end

	--========================
	-- GiveUp confirm（委譲）
	--========================
	function self:_closeGiveUpOverlay()
		if GiveUpConfirm and GiveUpConfirm.close then
			GiveUpConfirm.close(self.frame)
		else
			LOG.error("GiveUpConfirm.close missing")
		end
	end

	function self:_showGiveUpConfirm(onYes)
		if GiveUpConfirm and GiveUpConfirm.show then
			GiveUpConfirm.show(self.frame, Locale, Theme, self._lang, onYes)
		else
			LOG.error("GiveUpConfirm.show missing")
		end
	end

	--========================
	-- Buttons
	--========================
	if self.buttons and self.buttons.yaku then
		self.buttons.yaku.MouseButton1Click:Connect(function()
			if self._yakuPanel then self._yakuPanel:open() end
		end)
	end

	if self.buttons and self.buttons.confirm then
		self.buttons.confirm.MouseButton1Click:Connect(function()
			if ConfirmFlow and ConfirmFlow.handleConfirm then
				ConfirmFlow.handleConfirm({
					state   = self._cache.state,
					total   = self._cache.total,
					lang    = self._lang,
					Locale  = Locale,
					Theme   = Theme,
					GiveUpConfirm = GiveUpConfirm,
					DecideNext = self.deps and self.deps.DecideNext,
					Confirm    = self.deps and self.deps.Confirm,
					parent     = self.frame,
				})
			else
				LOG.error("ConfirmFlow.handleConfirm missing")
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

	if self.buttons and self.buttons.giveUp then
		self.buttons.giveUp.MouseButton1Click:Connect(function()
			self:_showGiveUpConfirm(function()
				local DecideNext = self.deps and self.deps.DecideNext
				if DecideNext then
					DecideNext:FireServer("abandon")
				else
					local rem = RS:FindFirstChild("Remotes")
					local ev  = rem and rem:FindFirstChild("DecideNext")
					if ev and ev:IsA("RemoteEvent") then
						ev:FireServer("abandon")
					else
						LOG.error("giveup: no DecideNext remote found")
					end
				end
			end)
		end)
	end

	--========================
	-- Remotes
	--========================
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

	-- 言語変更イベント
	if typeof(Locale.changed) == "RBXScriptSignal" then
		self._langConn = Locale.changed:Connect(function(newLang)
			self:setLang(newLang)
		end)
	end

	--========================
	-- Responsive（委譲）
	--========================
	if Responsive and Responsive.hook and Responsive.scaleUnder then
		self._respConn = Responsive.hook(self.gui, function()
			-- サイズの上限は適度な固定値（複雑な係数計算は Responsive 側に任せる想定なら調整可）
			Responsive.scaleUnder(self.frame, 30, 18, 20)
		end)
	else
		LOG.error("Responsive module missing or incomplete")
	end

	LOG.info("new done | lang=%s", tostring(self._lang))
	return self
end

--==================================================
-- Run methods
--==================================================
function Run:setRerollCounts(fieldLeft, handLeft, phase)
	if RerollUi and RerollUi.setCounts then
		RerollUi.setCounts(self, fieldLeft, handLeft, phase)
	else
		LOG.error("RerollUi.setCounts missing")
	end
end

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
		if n and n ~= self._lang then self:setLang(n) end
	else
		local gg = safeGetGlobalLang()
		if gg and gg ~= self._lang then self:setLang(gg) end
	end

	if self._taliBoard then
		self._taliBoard:setLang(self._lang or "ja")
		local tali = extractTalismanFromPayload(payload)
		if typeof(tali) == "table" then
			self._taliBoard:setData(tali)
		end
	end

	self.frame.Visible = true
	if self._remotes then
		self._remotes:disconnect()
		self._remotes:connect()
	end

	if not self._hlInit and self.handArea and self.boardRowTop and self.boardRowBottom then
		if MatchHighlighter and MatchHighlighter.init then
			local ok = pcall(function()
				MatchHighlighter.init(self.handArea, self.boardRowTop, self.boardRowBottom)
			end)
			self._hlInit = ok and true or false
		else
			LOG.error("MatchHighlighter.init missing")
		end
	end
end

function Run:requestSync()
	if not self.deps or not self.deps.ReqSyncUI then return end
	self._awaitingInitial = true
	if self._overlay then self._overlay:show() end
	self.deps.ReqSyncUI:FireServer()
end

function Run:hide()
	self.frame.Visible = false
	self:_closeGiveUpOverlay()
	if self._remotes then self._remotes:disconnect() end

	if self._hlInit then
		if MatchHighlighter and MatchHighlighter.shutdown then
			pcall(function() MatchHighlighter.shutdown() end)
		end
		self._hlInit = false
	end
end

function Run:destroy()
	self:_closeGiveUpOverlay()
	if self._hlInit then
		if MatchHighlighter and MatchHighlighter.shutdown then
			pcall(function() MatchHighlighter.shutdown() end)
		end
		self._hlInit = false
	end
	if self._remotes then self._remotes:disconnect() end
	if self._langConn then self._langConn:Disconnect() end
	if self._respConn then self._respConn:Disconnect() end
	if self.gui then self.gui:Destroy() end
end

return Run
