-- SharedModules/Scoring.lua
-- v0.9.3-S7 互換ラッパ：実体は SharedModules/score/index.lua に集約
-- I/F（据え置き）:
--   S.evaluate(takenCards: {Card}, state?: table) -> (totalScore: number, roles: table, detail: { mon: number, pts: number })
--   S.getFestivalStat(fid, lv) -> (dmon, dpts)
--   S.getFestivalsForYaku(yakuId) -> { festivalId, ... }
--   S.getKitoPts(effectId, lv) -> number

local RS = game:GetService("ReplicatedStorage")

-- 新実装へ委譲（一本化）
local function loadScoreModule()
	local ok, mod = pcall(function()
		local SharedModules = RS:WaitForChild("SharedModules")
		local ScoreFolder  = SharedModules:WaitForChild("score")
		return require(ScoreFolder:WaitForChild("index"))
	end)
	if ok and mod then
		return mod
	end
	-- フォールバック：万一ロード失敗してもゲームを落とさない最小スタブ
	warn("[Scoring] failed to load score/index.lua; using safe fallback (always 0)")
	local S = {}
	function S.evaluate() return 0, {}, { mon = 0, pts = 0 } end
	function S.getFestivalStat() return 0, 0 end
	function S.getFestivalsForYaku() return {} end
	function S.getKitoPts() return 0 end
	return S
end

return loadScoreModule()
