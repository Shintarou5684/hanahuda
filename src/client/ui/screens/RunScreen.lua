-- StarterPlayerScripts/UI/screens/RunScreen.lua

local Run = {}
Run.__index = Run

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
local YakuPanel      = require(components:WaitForChild("YakuPanel")) -- ★ 役倍率パネル

local lib        = script.Parent.Parent:WaitForChild("lib")
local Format     = require(lib:WaitForChild("FormatUtil"))

local screensDir = script.Parent
local UIBuilder  = require(screensDir:WaitForChild("RunScreenUI"))
local RemotesCtl = require(screensDir:WaitForChild("RunScreenRemotes"))

-- "目標:123" or "Target:123" の数値だけ抜く
local function extractGoalFromInfoText(text)
	if type(text) ~= "string" then return nil end
	local n = string.match(text, "目標:%s*(%d+)") or string.match(text, "Target:%s*(%d+)")
	return n
end

local function mapLangForPanel(lang) -- Runは "jp"/"en"、パネルは "ja"/"en"
	return (lang == "jp") and "ja" or "en"
end

function Run.new(deps)
	local self = setmetatable({}, Run)
	self.deps = deps
	self._awaitingInitial = false
	self._resultShown = false

	-- 言語初期値
	local initialLang = (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or Locale.pick()
	self._lang = initialLang
	print("[LANG_FLOW] Run.new initialLang=", initialLang)

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
	self._ui_setLang = ui.setLang  -- 後から切替用

	-- Overlay / ResultModal
	local loadingText = Theme.loadingText or (Locale.t(initialLang, "RUN_HELP_LINE") or "Loading...")
	self._overlay     = Overlay.create(self.frame, loadingText)
	self._resultModal = ResultModal.create(self.frame)
	self._resultModal:on({
		home = function() if self.deps.GoHome  then self.deps.GoHome :FireServer() end end,
		next = function() if self.deps.GoNext  then self.deps.GoNext :FireServer() end end,
		save = function() if self.deps.SaveQuit then self.deps.SaveQuit:FireServer() end end,
	})

	-- ★ 役倍率パネル（前面ポップアップ）
	self._yakuPanel = YakuPanel.mount(self.gui)

	-- Studio専用 DevTools
	if RunService:IsStudio() and (self.deps.DevGrantRyo or self.deps.DevGrantRole) then
		DevTools.create(self.frame, self.deps, { grantRyoAmount = 1000, offsetX = 10, offsetY = 10, width = 160, height = 32 })
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

	local function onScore(total, roles, detail)
		if typeof(roles) ~= "table" then roles = {} end
		if typeof(detail) ~= "table" then detail = { mon = 0, pts = 0 } end
		local mon = tonumber(detail.mon) or 0
		local pts = tonumber(detail.pts) or 0
		local tot = tonumber(total) or 0
		local box = self._scoreBox
		if box then
			box.Text = ("得点：%d（文%d × 点%d）\n役：%s"):format(tot, mon, pts, Format.rolesToLines(roles))
		end
	end

	local function onState(st)
		-- 情報パネル更新
		local line = Format.stateLineText(st)
		self.info.Text = line

		-- 目標表示
		if self.goalText then
			local g = extractGoalFromInfoText(line)
			local label = (self._lang == "en") and "Goal:" or "目標："
			self.goalText.Text = g and (label .. tostring(g)) or (label .. "—")
		end

		-- 役倍率パネルへ現在状態を反映
		if self._yakuPanel then
			local upd = {
				lang    = mapLangForPanel(self._lang),
				matsuri = st and st.matsuri
			}
			self._yakuPanel:update(upd)
		end

		if self._awaitingInitial then self._overlay:hide(); self._awaitingInitial = false end
		self._resultShown = false
		if self.notice and self.notice.Text == "" then self.notice.Text = "" end
	end

	local function onStageResult(a, b, _c, _d, _e)
		if typeof(a) ~= "boolean" or a ~= true then return end
		if typeof(b) ~= "table" then return end
		if self._resultShown then return end
		self._resultShown = true

		local data = b
		local isFinal = false
		if data.isFinal == true or tonumber(data.season) == 4 or tostring(data.seasonStr or "") == "冬" then
			isFinal = true
		end

		if isFinal then
			self._resultModal:showFinal(
				"クリアおめでとう！",
				"このランは終了です。メニューに戻ります。",
				"メニューに戻る",
				function()
					if self.deps.GoHome then
						self.deps.GoHome:FireServer()
					elseif self.deps.DecideNext then
						self.deps.DecideNext:FireServer("home")
					end
					self._resultModal:hide()
				end
			)
			return
		end

		self._resultModal:show(data)

		local clears = tonumber(data.clears) or 0
		local canNext, canSave = false, false
		if typeof(data.options) == "table" then
			if typeof(data.options.goNext) == "table" then canNext = (data.options.goNext.enabled == true) end
			if typeof(data.options.saveQuit) == "table" then canSave = (data.options.saveQuit.enabled == true) end
		end
		if not canNext and data.canNext ~= nil then canNext = (data.canNext == true) end
		if not canSave and data.canSave ~= nil then canSave = (data.canSave == true) end
		if clears >= 3 then canNext, canSave = true, true end

		self._resultModal:setLocked(not canNext, not canSave)
	end

	-- ボタン（※Yakuは UI 側のボタンを“接続だけ”する）
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

	-- Router.call 互換
	self.onHand        = function(_, hand)                 renderHand(hand) end
	self.onField       = function(_, field)                renderField(field) end
	self.onTaken       = function(_, taken)                renderTaken(taken) end
	self.onScore       = function(_, total, roles, detail) onScore(total, roles, detail) end
	self.onState       = function(_, st)                   onState(st) end
	self.onStageResult = function(_, ...)                  onStageResult(...) end

	print("[LANG_FLOW] Run.new done | lang=", self._lang)
	return self
end

-- 言語切替
function Run:setLang(lang)
	if lang ~= "jp" and lang ~= "en" then return end
	if self._lang == lang then
		print("[LANG_FLOW] Run.setLang ignored(same) | lang=", lang)
		return
	end
	print("[LANG_FLOW] Run.setLang apply | from=", self._lang, "to=", lang)
	self._lang = lang
	if type(self._ui_setLang) == "function" then
		self._ui_setLang(lang)
	end
	-- 役パネルは ja/en
	if self._yakuPanel then
		self._yakuPanel:update({ lang = mapLangForPanel(lang) })
	end
end

function Run:show(payload)
	-- payload?.lang があれば最優先で UI に適用
	if payload and (payload.lang == "jp" or payload.lang == "en") then
		print("[LANG_FLOW] Run.show payload.lang=", payload.lang, "(cur=", self._lang,")")
		self:setLang(payload.lang)
	else
		-- 念のため、グローバルを見て差異があれば合わせる
		local g = (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or self._lang
		if g ~= self._lang then
			print("[LANG_FLOW] Run.show sync from global | from=", self._lang, "to=", g)
			self:setLang(g)
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
	if self.gui then self.gui:Destroy() end
end

return Run
