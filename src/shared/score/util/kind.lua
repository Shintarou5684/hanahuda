-- ReplicatedStorage/SharedModules/score/util/kind.lua
-- v0.9.3-S2 kind正規化（現行同等）

local VALID_KIND = { bright=true, seed=true, ribbon=true, chaff=true }
local KIND_ALIAS = { kasu="chaff", tane="seed", tan="ribbon", tanzaku="ribbon", hikari="bright", light="bright" }

local M = {}

function M.normKind(k: any): string?
	if not k then return nil end
	local v = KIND_ALIAS[k] or k
	return VALID_KIND[v] and v or nil
end

return M
