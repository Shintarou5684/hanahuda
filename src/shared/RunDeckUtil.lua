-- v0.9.0 ラン構成ユーティリティ（唯一の正本：run.configSnapshot）
-- ここだけを読み書きする。季節ごとの山札は毎季これをクローンして生成。

local RS         = game:GetService("ReplicatedStorage")
local SharedMods = RS:WaitForChild("SharedModules")
local CardEngine = require(SharedMods:WaitForChild("CardEngine"))

local M = {}

-- run.configSnapshot を返す（必要なら初期48で初期化）
local function _ensureSnapshot(state)
	state.run = state.run or {}
	if typeof(state.run.configSnapshot) == "table" then
		return state.run.configSnapshot
	end
	-- 初期化
	local base = CardEngine.buildDeck()
	local snap = CardEngine.buildSnapshot(base)
	state.run.configSnapshot = snap
	return snap
end

-- ラン構成（テーブル48枚）を返す
-- initIfMissing=true のとき、存在しなければ初期化して返す
function M.loadConfig(state, initIfMissing)
	if typeof(state) ~= "table" then return nil end
	state.run = state.run or {}
	local snap = state.run.configSnapshot
	if typeof(snap) ~= "table" then
		if initIfMissing then snap = _ensureSnapshot(state) else return nil end
	end
	return CardEngine.buildDeckFromSnapshot(snap)
end

-- 渡された deck（テーブル）で run.configSnapshot を更新
-- deck が省略された場合、既存の run.configSnapshot を再保存（整形）するだけ
function M.saveConfig(state, deck)
	if typeof(state) ~= "table" then return end
	state.run = state.run or {}
	if typeof(deck) ~= "table" or #deck == 0 then
		-- 既存スナップショットがない場合は初期化
		if typeof(state.run.configSnapshot) ~= "table" then
			state.run.configSnapshot = CardEngine.buildSnapshot(CardEngine.buildDeck())
		end
		return
	end
	state.run.configSnapshot = CardEngine.buildSnapshot(deck)
end

-- 現在のスナップショットを返す（必ず存在）
function M.snapshot(state)
	return _ensureSnapshot(state)
end

--========================
-- Matsuri Levels (Festival Levels)
--========================
function M.ensureMeta(state)
	if typeof(state) ~= "table" then return {} end
	state.run = state.run or {}
	state.run.meta = state.run.meta or {}
	state.run.meta.matsuriLevels = state.run.meta.matsuriLevels or {}
	return state.run.meta
end

-- { [festivalId]=level } を返す（無ければ空）
function M.getMatsuriLevels(state)
	local meta = M.ensureMeta(state)
	return meta.matsuriLevels
end

-- 祭事レベルを増減（通常は delta=+1）。戻り値：新レベル
function M.incMatsuri(state, festivalId, delta)
	local meta = M.ensureMeta(state)
	local t = meta.matsuriLevels
	local cur = tonumber(t[festivalId] or 0) or 0
	local nextLv = math.max(0, cur + (tonumber(delta) or 0))
	t[festivalId] = nextLv
	return nextLv
end

-- ニューゲーム時に祭事をリセット
function M.resetMatsuri(state)
	local meta = M.ensureMeta(state)
	meta.matsuriLevels = {}
end




return M
