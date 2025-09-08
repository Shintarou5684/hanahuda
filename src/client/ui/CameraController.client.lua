-- src/client/CameraController.client.lua
-- v0.8.x: 2D固定版（3Dは将来実装）
-- 役割：DisplayMode(2D/3Dフラグ)に従い、カメラを2Dトップダウンへ固定する

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local RS          = game:GetService("ReplicatedStorage")

-- Config: ReplicatedStorage/Config/DisplayMode.lua
local DisplayMode = require(
	RS:WaitForChild("Config")
	  :WaitForChild("DisplayMode")
)

local localPlayer = Players.LocalPlayer
local camera      = workspace.CurrentCamera

--========================
-- 設定（2Dトップダウン）
--========================
local TOPDOWN_HEIGHT = 120               -- 盤面の上空高さ
local TOPDOWN_FOV    = 20                -- 擬似2D感を強める狭めFOV
local LOOK_AT        = Vector3.new(0,0,0) -- 盤面中心（必要に応じて差し替え）

--========================
-- 内部状態
--========================
local conn       -- Heartbeat接続
local lastCF     -- 最後に適用したカメラCFrame
local lastFOV    -- 最後に適用したFOV

--========================
-- 2D適用
--========================
local function apply2D()
	camera.CameraType  = Enum.CameraType.Scriptable
	camera.FieldOfView = TOPDOWN_FOV

	-- 上空から真下を見るカメラ
	local pos = Vector3.new(LOOK_AT.X, TOPDOWN_HEIGHT, LOOK_AT.Z)
	local cf  = CFrame.new(pos, LOOK_AT) * CFrame.Angles(-math.rad(90), 0, 0)
	camera.CFrame = cf

	-- ユーザー操作のズーム無効化（保険）
	localPlayer.CameraMinZoomDistance = 0.5
	localPlayer.CameraMaxZoomDistance = 0.5

	lastCF  = cf
	lastFOV = TOPDOWN_FOV
end

--========================
-- 監視ループ（軽量）
--  初回適用後、ズレが出た時だけ補正
--========================
local function enable2DGuard()
	-- 既存ループ停止
	if conn then conn:Disconnect(); conn = nil end

	-- 初回適用
	apply2D()

	-- Heartbeatで軽く監視（毎フレーム再設定はしない）
	conn = RunService.Heartbeat:Connect(function()
		if camera.CameraType ~= Enum.CameraType.Scriptable
		or camera.FieldOfView ~= lastFOV
		or (camera.CFrame.Position - lastCF.Position).Magnitude > 0.01
		then
			apply2D()
		end
	end)
end

local function disableGuard()
	if conn then conn:Disconnect(); conn = nil end
end

--========================
-- 初期化：当面は必ず2D
--========================
if not DisplayMode:is2D() then
	DisplayMode:set("2D") -- 将来3D実装時はここで分岐
end
enable2DGuard()

-- クリーンアップ
script.Destroying:Connect(disableGuard)
