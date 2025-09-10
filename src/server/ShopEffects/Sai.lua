-- v0.9.0 祭事：レベル管理のみ（効果数値は Scoring 側）
local RS = game:GetService("ReplicatedStorage")
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))

local Sai = {}

-- 表記揺れを festivalId に正規化
function Sai.normalize(effectId)
	if type(effectId) ~= "string" then return nil end
	-- 例: "sai_kasu", "sai_kasu_lv1", "sai_kasu_1" → "sai_kasu"
	local base = effectId:match("^(sai_%a+)")
	return base
end

local function msg(s) return s end

function Sai.apply(effectId, state, _ctx)
	if typeof(state) ~= "table" then
		return false, msg("state が無効です")
	end
	local fid = Sai.normalize(effectId)
	if not fid then
		return false, msg(("不明な祭事ID: %s"):format(tostring(effectId)))
	end
	-- Lua では +1 は不可。1 を渡す。
	local newLv = RunDeckUtil.incMatsuri(state, fid, 1)
	return true, msg(("%s Lv+1（累計Lv=%d）"):format(fid, newLv))
end

return Sai
