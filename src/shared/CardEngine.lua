-- src/shared/CardEngine.lua
-- Compatibility shim: 旧パスを新正本（Deck/CardEngine）へ委譲
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("SharedModules")
local Deck   = Shared:WaitForChild("Deck")
return require(Deck:WaitForChild("CardEngine"))
