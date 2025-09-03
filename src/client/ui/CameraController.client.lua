-- src/client/CameraController.client.lua
-- v0.8.x: 2D固定版（3Dは将来実装）
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local RS          = game:GetService("ReplicatedStorage")

-- Config の場所を SharedModules/Config に明示
local RS = game:GetService("ReplicatedStorage")
local DisplayMode = require(
  RS:WaitForChild("Config")
    :WaitForChild("DisplayMode")
)

local localPlayer = Players.LocalPlayer
local camera      = workspace.CurrentCamera

-- 2Dカメラ設定（トップダウン）
local TOPDOWN_HEIGHT = 120          -- 必要に応じて調整
local TOPDOWN_FOV    = 20           -- 擬似2D感
local LOOK_AT        = Vector3.new(0, 0, 0) -- 盤面中心（必要なら差し替え）

local conn

local function apply2D()
	camera.CameraType  = Enum.CameraType.Scriptable
	camera.FieldOfView = TOPDOWN_FOV

	-- 上空から見下ろし
	local pos = Vector3.new(LOOK_AT.X, TOPDOWN_HEIGHT, LOOK_AT.Z)
	local cf  = CFrame.new(pos, LOOK_AT) * CFrame.Angles(-math.rad(90), 0, 0)
	camera.CFrame = cf

	-- ユーザー操作のズーム無効化（保険）
	localPlayer.CameraMinZoomDistance = 0.5
	localPlayer.CameraMaxZoomDistance = 0.5
end

local function enable2DLoop()
	if conn then conn:Disconnect() end
	conn = RunService.RenderStepped:Connect(apply2D)
end

local function disableLoop()
	if conn then conn:Disconnect(); conn = nil end
end

-- 初期：必ず2Dで動かす
if not DisplayMode:is2D() then
	DisplayMode:set("2D")
end
enable2DLoop()

script.Destroying:Connect(disableLoop)
