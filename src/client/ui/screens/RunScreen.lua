-- StarterPlayerScripts/UI/screens/RunScreen.lua
-- v0.9.7-P1-3
--  - ログを共通 Logger に統一（print/warn を撤去）
--  - 以降の変更点は先頭コメント参照
-- v0.9.6-P0-9 言語コード外部I/Fを "ja"/"en" に統一（受信 "jp" は警告して "ja" へ正規化）
-- v0.9.5 ResultModal final文言をLocale化（英語フォールバックあり）＋Nav統一
--        MisleadingAndOr を if-then-else に置換（静的解析対応）
--        P0-8: no-op削除／_G依存排除／役なしは Locale.t("ROLES_NONE")
-- v0.9.6-P0-11 goal 数値を payload から参照（情報行パースは撤廃）
-- v0.9.7-P1-1  ResultModal を Nav 単一点に直結（bindNav）。final/3択の判定を canNext/canSave/locks で統一。

local Run = {}
Run.__index = Run

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Logger
local Logger = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("RunScreen")

-- Modules
local Config = ReplicatedStorage:WaitForChild("Config")
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
local YakuPanel      = require(components:WaitForChild("YakuPanel")) -- 役倍率パネル

local lib        = script.Parent.Parent:WaitForChild("lib")
local Format     = require(lib:WaitForChild("FormatUtil"))

local screensDir = script.Parent
local UIBuilder  = require(screensDir:WaitForChild("RunScreenUI"))
local RemotesCtl = require(screensDir:WaitForChild("RunScreenRemotes"))

--==================================================
-- Lang helpers (P0-9)
--==================================================

local function normLangJa(lang: string?)
	local v = tostring(lang or ""):lower()
	if v == "jp" then
		LOG.warn("[Locale] received legacy 'jp'; normalize to 'ja'")
		return "ja"
	elseif v == "ja" then
		return "ja"
	elseif v == "en" then
		return "en"
	end
	return nil
end

-- Runは "ja"/"en" を使用。役パネルも "ja"/"en" 前提。
local function mapLangForPanel(lang)
	local n = normLangJa(lang)
	return (n == "ja") and "ja" or "en"
end

-- JPの情報ラインをENに置換する簡易マッパ（HUDの表示用。数値ロジックでは使用しない）
local function jpLineToEn(lineJP)
	if type(lineJP) ~= "string" then return "" end
	local s = lineJP
	s = s:gsub("年:", "Year:")
	     :gsub("季節:", "Season:")
	     :gsub("目標:", "Target:")
	     :gsub("合計:", "Total:")
	     :gsub("残ハンド:", "Hands:")
	     :gsub("残リロール:", "Rerolls:")
	     :gsub("倍率:", "Mult:")
	     :gsub("山:", "Deck:")
	     :gsub("手:", "Hand:")
	-- 季節表記も英語へ
	s = s:gsub("春", "Spring"):gsub("夏", "Summer"):gsub("秋", "Autumn"):gsub("冬", "Winter")
	return s
end

-- Locale.getGlobal() を安全取得（"ja"/"en" 以外は nil を返す／"jp" は "ja" に正規化）
local function safeGetGlobalLang()
	if typeof(Locale.getGlobal) == "function" then
		local ok, v = pcall(Locale.getGlobal)
		if ok then
			local n = normLangJa(v)
			if n == "ja" or n == "en" then
				return n
			end
		end
	end
	return nil
end

-- フォールバック付きの言語解決（self._lang→Locale.getGlobal→"en"）
local function resolveLangOrDefault(current)
	local n = normLangJa(current)
	if n == "ja" or n == "en" then
		return n
	end
	local g = safeGetGlobalLang()
	if g then return g end
	return "en"
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
	LOG.debug("init lang=%s", tostring(initialLang))

	-- UI 構築
	local ui = UIBuilder.build(nil, { lang = initialLang })
	self.gui      = ui.gui
	self.frame    = ui.root
	self.info     = ui.info
	self.goalText = ui.goalText
	self.notice   = ui.notice
	self.handArea = ui.handArea
	self.boardRowTop    = ui.boardRowTop
	self.boardRowBottom = ui.boardRowBottom
	self.takenBox = ui.takenBox
	self._scoreBox = ui.scoreBox
	self.buttons  = ui.buttons
	self._ui_setLang = ui.setLang
	self._fmtScore   = ui.formatScore or function(score, mons, pts, rolesText)
		if self._lang == "ja" then
			return string.format("得点：%d\n文%d×%d点\n%s", score or 0, mons or 0, pts or 0, rolesText or "役：--")
		else
			return string.format("Score: %d\n%dMon × %dPts\n%s", score or 0, mons or 0, pts or 0, rolesText or "Roles: --")
		end
	end

	-- Overlay / ResultModal
	local helpText = Locale.t(initialLang, "RUN_HELP_LINE")
	if type(helpText) ~= "string" or helpText == "" then helpText = "Loading..." end
	local loadingText = Theme.loadingText or helpText

	self._overlay     = Overlay.create(self.frame, loadingText)
	self._resultModal = ResultModal.create(self.frame)

	-- ▼ P1-1: ResultModal → Nav 単一点（Nav がなければ DecideNext でフォールバック）
	if self.deps and self.deps.Nav and type(self.deps.Nav.next) == "function" then
		self._resultModal:bindNav(self.deps.Nav)
	else
		self._resultModal:on({
			home = function()
				if self.deps and self.deps.DecideNext then self.deps.DecideNext:FireServer("home") end
			end,
			next = function()
				if self.deps and self.deps.DecideNext then self.deps.DecideNext:FireServer("next") end
			end,
			save = function()
				if self.deps and self.deps.DecideNext then self.deps.DecideNext:FireServer("save") end
			end,
			final = function()
				if self.deps and self.deps.DecideNext then self.deps.DecideNext:FireServer("home") end
			end,
		})
	end

	-- 役倍率パネル
	self._yakuPanel = YakuPanel.mount(self.gui)

	--- Studio専用 DevTools
	if RunService:IsStudio() then
		local r = self.deps and self.deps.remotes
		local grantRyo  = (self.deps and self.deps.DevGrantRyo)  or (r and r.DevGrantRyo)
		local grantRole = (self.deps and self.deps.DevGrantRole) or (r and r.DevGrantRole)
		if grantRyo or grantRole then
			DevTools.create(self.frame, { DevGrantRyo = grantRyo, DevGrantRole = grantRole }, {
				grantRyoAmount = 1000, offsetX = 10, offsetY = 10, width = 160, height = 32
			})
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
					onSelect = function(_) end
				})
			end
		})
		if self._awaitingInitial then self._overlay:hide(); self._awaitingInitial = false end
	end

	local function renderField(field)
		FieldRenderer.render(self.boardRowTop, self.boardRowBottom, field, {
			rowPaddingScale = 0.02,
			onPick = function(bindex)
				if self._selectedHandIdx then
					self.deps.ReqPick:FireServer(self._selectedHandIdx, bindex)
					self._selectedHandIdx = nil
				end
			end
		})
	end

	local function renderTaken(cards)
		TakenRenderer.renderTaken(self.takenBox, cards or {})
	end

	-- ★ 言語対応したスコア更新（P0-8: _G依存排除／空役はLocaleで安定化）
	local function onScore(total, roles, detail)
		if typeof(roles) ~= "table" then roles = {} end
		if typeof(detail) ~= "table" then detail = { mon = 0, pts = 0 } end
		local mon = tonumber(detail.mon) or 0
		local pts = tonumber(detail.pts) or 0
		local tot = tonumber(total) or 0
		if self._scoreBox then
			local rolesBody  = Format.rolesToLines(roles, self._lang) -- 空なら Locale.t(lang,"ROLES_NONE")
			local rolesLabel = (self._lang == "en") and "Roles: " or "役："
			self._scoreBox.Text = self._fmtScore(tot, mon, pts, rolesLabel .. rolesBody)
		end
	end

	local function onState(st)
		-- 情報パネル（JP→EN 変換）※表示専用、数値は payload を参照
		local lineJP = Format.stateLineText(st)
		local line = (self._lang == "en") and jpLineToEn(lineJP) or lineJP
		self.info.Text = line

		-- 目標表示：payload の数値 goal のみ使用（P0-11 完了）
		if self.goalText then
			local g = (typeof(st) == "table") and tonumber(st.goal) or nil
			local label = (self._lang == "en") and "Goal:" or "目標："
			self.goalText.Text = g and (label .. tostring(g)) or (label .. "—")
		end

		-- 役倍率パネルへ現在状態を反映
		if self._yakuPanel then
			self._yakuPanel:update({
				lang    = mapLangForPanel(self._lang),
				matsuri = st and st.matsuri
			})
		end

		if self._awaitingInitial then self._overlay:hide(); self._awaitingInitial = false end
		self._resultShown = false
	end

	local function onStageResult(a, b, _c, _d, _e)
		if typeof(a) ~= "boolean" or a ~= true then return end
		if typeof(b) ~= "table" then return end
		if self._resultShown then return end
		self._resultShown = true

		local data = b

		-- ▼ 可否情報の収集（ops/locks を優先、なければ options / canX を後方互換で）
		local canNext, canSave
		-- 正準 ops
		if typeof(data.ops) == "table" then
			if typeof(data.ops.next) == "table" then canNext = (data.ops.next.enabled == true) end
			if typeof(data.ops.save) == "table" then canSave = (data.ops.save.enabled == true) end
		end
		-- 互換 options
		if canNext == nil and typeof(data.options) == "table" and typeof(data.options.goNext) == "table" then
			canNext = (data.options.goNext.enabled == true)
		end
		if canSave == nil and typeof(data.options) == "table" and typeof(data.options.saveQuit) == "table" then
			canSave = (data.options.saveQuit.enabled == true)
		end
		-- さらに互換（bool）
		if canNext == nil and data.canNext ~= nil then canNext = (data.canNext == true) end
		if canSave == nil and data.canSave ~= nil then canSave = (data.canSave == true) end

		-- locks が届いていればそれを優先（UI用に計算済み）
		local nextLocked, saveLocked
		if typeof(data.locks) == "table" then
			if typeof(data.locks.nextLocked) == "boolean" then nextLocked = data.locks.nextLocked end
			if typeof(data.locks.saveLocked) == "boolean" then saveLocked = data.locks.saveLocked end
		end
		if nextLocked == nil and canNext ~= nil then nextLocked = (canNext ~= true) end
		if saveLocked == nil and canSave ~= nil then saveLocked = (canSave ~= true) end

		-- 通算クリア >=3 の場合は強制開放（サーバと二重に守る）
		local clears = tonumber(data.clears) or 0
		if clears >= 3 then
			nextLocked, saveLocked = false, false
			canNext, canSave = true, true
		end

		-- ▼ final（ワンボタン） or 3択 の決定
		local isFinalView = (nextLocked == true and saveLocked == true)

		if isFinalView then
			-- Locale化ワンボタン
			local lang = resolveLangOrDefault(self._lang)
			local ttl  = Locale.t(lang, "RESULT_FINAL_TITLE")
			local desc = Locale.t(lang, "RESULT_FINAL_DESC")
			local btn  = Locale.t(lang, "RESULT_FINAL_BTN")

			self._resultModal:showFinal(
				ttl, desc, btn,
				function()
					-- Nav: 単一点（フォールバックは create 時に設定済み）
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

		-- 3択表示（必要に応じてロック）
		self._resultModal:show(data)
		self._resultModal:setLocked(nextLocked == true, saveLocked == true)
	end

	-- ボタン
	if self.buttons.yaku then
		self.buttons.yaku.MouseButton1Click:Connect(function()
			if self._yakuPanel then self._yakuPanel:open() end
		end)
	end
	self.buttons.confirm.MouseButton1Click:Connect(function() if self.deps.Confirm       then self.deps.Confirm:FireServer()       end end)
	self.buttons.rerollAll.MouseButton1Click:Connect(function() if self.deps.ReqRerollAll then self.deps.ReqRerollAll:FireServer() end end)
	self.buttons.rerollHand.MouseButton1Click:Connect(function() if self.deps.ReqRerollHand then self.deps.ReqRerollHand:FireServer() end end)
	if self.buttons.clearSel then
		self.buttons.clearSel.MouseButton1Click:Connect(function() self._selectedHandIdx = nil end)
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

	-- 言語変更イベント購読（Home 側の切替を即反映）
	if typeof(Locale.changed) == "RBXScriptSignal" then
		self._langConn = Locale.changed:Connect(function(newLang)
			self:setLang(newLang)
		end)
	end

	-- Router.call 互換
	self.onHand        = function(_, hand)                 renderHand(hand) end
	self.onField       = function(_, field)                renderField(field) end
	self.onTaken       = function(_, taken)                renderTaken(taken) end
	self.onScore       = function(_, total, roles, detail) onScore(total, roles, detail) end
	self.onState       = function(_, st)                   onState(st) end
	self.onStageResult = function(_, ...)                  onStageResult(...) end

	LOG.debug("new done | lang=%s", tostring(self._lang))
	return self
end

-- 言語切替（"ja"/"en" のみ受理。受信 "jp" は "ja" に正規化）
function Run:setLang(lang)
	local n = normLangJa(lang)
	if n ~= "ja" and n ~= "en" then return end
	if self._lang == n then
		LOG.debug("setLang ignored (same) | lang=%s", n)
		return
	end
	LOG.debug("setLang apply | from=%s to=%s", tostring(self._lang), tostring(n))
	self._lang = n
	if type(self._ui_setLang) == "function" then
		self._ui_setLang(n)
	end
	-- 役パネルは ja/en
	if self._yakuPanel then
		self._yakuPanel:update({ lang = mapLangForPanel(n) })
	end
end

function Run:show(payload)
	-- payload?.lang があれば最優先で UI に適用（"jp" は "ja" に正規化）
	if payload and payload.lang then
		local n = normLangJa(payload.lang)
		if n and n ~= self._lang then
			LOG.debug("show payload.lang=%s (cur=%s)", tostring(n), tostring(self._lang))
			self:setLang(n)
		end
	else
		local gg = safeGetGlobalLang()
		if gg and gg ~= self._lang then
			LOG.debug("show sync from global | from=%s to=%s", tostring(self._lang), tostring(gg))
			self:setLang(gg)
		end
	end

	self.frame.Visible = true
	self._remotes:disconnect()
	self._remotes:connect()
end

function Run:requestSync()
	if not self.deps or not self.deps.ReqSyncUI then return end
	self._awaitingInitial = true
	if self._overlay then self._overlay:show() end
	self.deps.ReqSyncUI:FireServer()
end

function Run:hide()
	self.frame.Visible = false
	self._remotes:disconnect()
end

function Run:destroy()
	self._remotes:disconnect()
	if self._langConn then self._langConn:Disconnect() end
	if self.gui then self.gui:Destroy() end
end

return Run
