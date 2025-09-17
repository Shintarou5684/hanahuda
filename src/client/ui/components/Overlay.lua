-- StarterPlayerScripts/UI/components/Overlay.lua
-- ローディング用オーバーレイ
-- v0.9.7-P1-4: Theme に完全寄せ（色・透過のフォールバック撤去／既定文言もTheme経由）

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

local M = {}

function M.create(parent: Instance, text: string?)
	--=== 背景（入力遮断＋半透明） ======================================
	local overlay = Instance.new("Frame")
	overlay.Name = "LoadingOverlay"
	overlay.Parent = parent
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = (Theme.COLORS and Theme.COLORS.OverlayBg) or Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = (Theme.overlayBgT ~= nil) and Theme.overlayBgT or 0.35
	overlay.Visible = false
	overlay.ZIndex = 50
	overlay.Active = true            -- 入力を遮断

	--=== メッセージ =====================================================
	local msg = Instance.new("TextLabel")
	msg.Name = "Msg"
	msg.Parent = overlay
	msg.BackgroundTransparency = 1
	msg.TextScaled = true
	msg.Size = UDim2.new(0, 480, 0, 48)
	msg.Position = UDim2.new(0.5, 0, 0.5, 0)
	msg.AnchorPoint = Vector2.new(0.5, 0.5)
	msg.TextXAlignment = Enum.TextXAlignment.Center
	msg.Font = Enum.Font.GothamMedium
	msg.TextColor3 = (Theme.COLORS and (Theme.COLORS.PrimaryBtnText or Color3.fromRGB(255,255,255)))
		or Color3.fromRGB(255, 255, 255)
	msg.Text = text or Theme.loadingText or Theme.helpText or "読み込み中..."

	--=== API ============================================================
	local api = {}

	function api:show()
		overlay.Visible = true
	end

	function api:hide()
		overlay.Visible = false
	end

	function api:setText(t: string?)
		msg.Text = t or ""
	end

	function api:setTransparency(alpha: number)
		-- 0（不透明）〜1（完全透明）
		local a = tonumber(alpha)
		if a and a >= 0 and a <= 1 then
			overlay.BackgroundTransparency = a
		end
	end

	function api:destroy()
		pcall(function() overlay:Destroy() end)
	end

	return api
end

return M
