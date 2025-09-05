-- StarterPlayerScripts/UI/screens/RunScreen.lua

local Run = {}
Run.__index = Run

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

-- 相対モジュール
local components     = script.Parent.Parent:WaitForChild("components")
local renderersDir   = components:WaitForChild("renderers")
local HandRenderer   = require(renderersDir:WaitForChild("HandRenderer"))
local FieldRenderer  = require(renderersDir:WaitForChild("FieldRenderer"))
local TakenRenderer  = require(renderersDir:WaitForChild("TakenRenderer"))
local ResultModal    = require(components:WaitForChild("ResultModal"))
local Overlay        = require(components:WaitForChild("Overlay"))
local DevTools       = require(components:WaitForChild("DevTools"))

local lib        = script.Parent.Parent:WaitForChild("lib")
local Format     = require(lib:WaitForChild("FormatUtil"))

local screensDir = script.Parent
local UIBuilder  = require(screensDir:WaitForChild("RunScreenUI"))
local RemotesCtl = require(screensDir:WaitForChild("RunScreenRemotes"))

function Run.new(deps)
	local self = setmetatable({}, Run)
	self.deps = deps
	self._awaitingInitial = false
	self._resultShown = false

	-- UI構築
	local ui = UIBuilder.build(nil) -- ScreenGui込みで作る
	self.gui      = ui.gui
	self.frame    = ui.root
	self.info     = ui.info
	self.handArea = ui.handArea
	self.boardRowTop    = ui.boardRowTop
	self.boardRowBottom = ui.boardRowBottom
	self.takenBox = ui.takenBox
	self._scoreBox = ui.scoreBox
	self.buttons  = ui.buttons
	self.ROW_H    = ui.metrics.ROW_H

	-- Overlay / ResultModal
	self._overlay     = Overlay.create(self.frame, Theme.loadingText or "次の季節を準備中...")
	self._resultModal = ResultModal.create(self.frame)
	self._resultModal:on({
		home = function() if self.deps.GoHome  then self.deps.GoHome :FireServer() end end,
		next = function() if self.deps.GoNext  then self.deps.GoNext :FireServer() end end,
		save = function() if self.deps.SaveQuit then self.deps.SaveQuit:FireServer() end end,
	})

	-- Studio専用 DevTools
	if RunService:IsStudio() and (self.deps.DevGrantRyo or self.deps.DevGrantRole) then
		DevTools.create(self.frame, self.deps, { grantRyoAmount = 1000, offsetX = 10, offsetY = 10, width = 160, height = 32 })
	end

	-- 内部状態
	self._selectedHandIdx = nil

	-- レンダラー適用
	local function renderHand(hand)
		HandRenderer.render(self.handArea, hand, {
			width = 90, height = 150,
			selectedIndex = self._selectedHandIdx,
			onSelect = function(i)
				-- ★ MisleadingAndOr 対応（トグルを if-else で明示）
				if self._selectedHandIdx == i then
					self._selectedHandIdx = nil
				else
					self._selectedHandIdx = i
				end

				-- 再ハイライト（最小で済ませるため再呼び出し）
				HandRenderer.render(self.handArea, hand, {
					width = 90, height = 150,
					selectedIndex = self._selectedHandIdx,
					onSelect = function(ii)
						-- ★ MisleadingAndOr 対応（こちらも if-else）
						if self._selectedHandIdx == ii then
							self._selectedHandIdx = nil
						else
							self._selectedHandIdx = ii
						end
						HandRenderer.render(self.handArea, hand, {
							width = 90, height = 150,
							selectedIndex = self._selectedHandIdx,
							onSelect = function(...) end
						})
					end
				})
			end
		})
		if self._awaitingInitial then self._overlay:hide(); self._awaitingInitial = false end
	end

	local function renderField(field)
		FieldRenderer.render(self.boardRowTop, self.boardRowBottom, field, {
			width = 80, height = (self.ROW_H - 16),
			onPick = function(bindex)
				if self._selectedHandIdx then
					self.deps.ReqPick:FireServer(self._selectedHandIdx, bindex)
					self._selectedHandIdx = nil
					-- 手札のハイライトも解除したいので、直近ハンドで再描画はScore/State/HandPushの次イベントに任せる
				end
			end
		})
	end

	local function renderTaken(cards)
		TakenRenderer.render(self.takenBox, cards, { cellW = 80, cellH = 112 })
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
		self.info.Text = Format.stateLineText(st)
		if self._awaitingInitial then self._overlay:hide(); self._awaitingInitial = false end
		self._resultShown = false
	end

	local function onStageResult(a, b, _c, _d, _e)
		if typeof(a) ~= "boolean" or a ~= true then return end
		if typeof(b) ~= "table" then return end
		if self._resultShown then return end
		self._resultShown = true

		local data = b
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

	-- ボタン
	self.buttons.confirm.MouseButton1Click:Connect(function() self.deps.Confirm:FireServer() end)
	self.buttons.rerollAll.MouseButton1Click:Connect(function() self.deps.ReqRerollAll:FireServer() end)
	self.buttons.rerollHand.MouseButton1Click:Connect(function() self.deps.ReqRerollHand:FireServer() end)
	self.buttons.clearSel.MouseButton1Click:Connect(function()
		self._selectedHandIdx = nil
		-- 実際のハイライト解除は、次の HandPush で再描画されると自然に消える
	end)

	-- Remotes 接続管理
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

	return self
end

function Run:show()
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
