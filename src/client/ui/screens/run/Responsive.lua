-- StarterPlayerScripts/UI/screens/run/Responsive.lua
-- v1.1  Minimal & robust responsive helpers for RunScreen family
--  - applyScaled(inst, maxSize): TextLabel/TextButton に安全に TextScaled を適用
--  - scaleUnder(root, titleMax, bodyMax, btnMax): 配下のテキスト系へ一括適用
--  - hook(gui, applyOnce): AbsoluteSize 監視フック（解除は :Disconnect()）
--  - deviceFactor/lerp: 端末係数/線形補間（必要に応じて利用）

local M = {}

--============================
-- math helpers
--============================
function M.lerp(a, b, t)
	a = tonumber(a) or 0
	b = tonumber(b) or 0
	t = tonumber(t) or 0
	return a + (b - a) * t
end

function M.deviceFactor(guiOrW, h)
	-- 短辺 480px → 1.0、小画面ほど1寄り。1000pxで0.0
	local w, hh
	if typeof(guiOrW) == "Instance" and guiOrW.AbsoluteSize then
		w, hh = guiOrW.AbsoluteSize.X, guiOrW.AbsoluteSize.Y
	else
		w, hh = tonumber(guiOrW) or 800, tonumber(h) or 600
	end
	local shortSide = math.min(math.max(1, w), math.max(1, hh))
	local lo, hi = 480, 1000
	return 1 - math.clamp((shortSide - lo) / (hi - lo), 0, 1)
end

--============================
-- TextScaled helpers
--============================
local function _applyScaled(inst, maxSize)
	if not (typeof(inst) == "Instance" and inst:IsA("GuiObject")) then return end
	local isBtn = inst:IsA("TextButton")
	local isLbl = inst:IsA("TextLabel")
	if not (isBtn or isLbl) then return end

	inst.TextScaled = true
	-- Button は 1 行固定推奨
	if isBtn then
		inst.TextWrapped  = false
		inst.TextTruncate = Enum.TextTruncate.AtEnd
		inst.LineHeight   = 1
	end

	local lim = inst:FindFirstChildOfClass("UITextSizeConstraint")
	if not lim then
		lim = Instance.new("UITextSizeConstraint")
		lim.Parent = inst
	end
	lim.MaxTextSize = math.max(8, math.floor(tonumber(maxSize) or 18))
	if lim.MinTextSize ~= nil then
		lim.MinTextSize = 10
	end
end

-- 公開版（直接呼びたいケース向け）
function M.applyScaled(inst, maxSize)
	_applyScaled(inst, maxSize)
end

function M.scaleUnder(root, titleMax, bodyMax, btnMax)
	if not (typeof(root) == "Instance" and root.GetDescendants) then return end
	local ok, list = pcall(function() return root:GetDescendants() end)
	if not ok or type(list) ~= "table" then return end

	for _, inst in ipairs(list) do
		if typeof(inst) == "Instance" then
			if inst:IsA("TextLabel") then
				_applyScaled(inst, bodyMax)
			elseif inst:IsA("TextButton") then
				_applyScaled(inst, btnMax)
			end
		end
	end
end

--============================
-- Resize hook
--============================
function M.hook(gui, applyOnce)
	if not (typeof(gui) == "Instance" and gui.GetPropertyChangedSignal) then return nil end

	local function _applySafe()
		if typeof(applyOnce) == "function" then
			-- 例外で落ちないように
			local ok, err = pcall(applyOnce)
			if not ok then warn("[Responsive] applyOnce failed: ", err) end
		end
	end

	local conn = gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(_applySafe)
	_applySafe() -- 初回適用

	-- そのまま RBXScriptConnection を返す（:Disconnect() で解除）
	return conn
end

return M
