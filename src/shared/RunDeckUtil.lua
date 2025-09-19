-- ReplicatedStorage/SharedModules/RunDeckUtil.lua
-- 役割：ラン状態のユーティリティ。
-- 変更:
--  - getUnlockedTalismanSlots(state): state.run から安全に読取り、無ければ 0 を返す
--  - ensureTalisman(state, opts): 護符テーブルの存在と最低限の形を保証（不足キーのみ補完）

-- v0.9.0 ラン構成ユーティリティ（唯一の正本：run.configSnapshot）
-- ここだけを読み書きする。季節ごとの山札は毎季これをクローンして生成。

local RS         = game:GetService("ReplicatedStorage")
local SharedMods = RS:WaitForChild("SharedModules")
local CardEngine = require(SharedMods:WaitForChild("CardEngine"))

local M = {}

--========================
-- Deck snapshot
--========================

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

--========================
-- Talisman（護符）ユーティリティ
--========================

local function _clone6(src:{any}?): {any}
	local s = src or {}
	return { s[1], s[2], s[3], s[4], s[5], s[6] }
end

-- 内部: 護符のアンロック数をできるだけ多くの互換キーから読み取る
local function _readUnlockedFromRun(run)
	-- 最優先: run.unlocked / run.talismanUnlocked / run.talisman.unlocked
	if typeof(run.unlocked) == "number" then
		return math.max(0, math.floor(run.unlocked))
	end
	if typeof(run.talismanUnlocked) == "number" then
		return math.max(0, math.floor(run.talismanUnlocked))
	end
	if typeof(run.talisman) == "table" and typeof(run.talisman.unlocked) == "number" then
		return math.max(0, math.floor(run.talisman.unlocked))
	end

	-- 配列風 talisman の最大インデックスを推定
	if typeof(run.talisman) == "table" then
		local maxIdx = 0
		for k, _ in pairs(run.talisman) do
			if typeof(k) == "number" and k > maxIdx then
				maxIdx = k
			end
		end
		if maxIdx > 0 then
			return maxIdx
		end
	end

	return 0
end

-- 公開API: アンロック済み護符スロット数を返す（見つからなければ 0）
function M.getUnlockedTalismanSlots(state)
	if typeof(state) ~= "table" then return 0 end
	state.run = state.run or {}
	return _readUnlockedFromRun(state.run)
end

-- 公開API: 護符テーブル（run.talisman）の存在と最低限の形を保証
-- opts: { minUnlocked: number?, maxSlots: number? }
-- 既存値は尊重し、不足キーだけ補う（unlocked は整合性のため 0..maxSlots に丸め）
function M.ensureTalisman(state, opts)
	if typeof(state) ~= "table" then return nil end
	state.run = state.run or {}

	local minUnlocked = tonumber(opts and opts.minUnlocked) or 2
	local maxSlots    = tonumber(opts and opts.maxSlots) or 6
	minUnlocked = math.max(0, math.floor(minUnlocked))
	maxSlots    = math.max(1, math.floor(maxSlots))

	local b = state.run.talisman
	if typeof(b) ~= "table" then
		-- 新規生成（既存が無い場合のみ）
		b = {
			maxSlots = maxSlots,
			unlocked = math.min(maxSlots, minUnlocked),
			slots    = { nil, nil, nil, nil, nil, nil },
		}
		state.run.talisman = b
	else
		-- 既存を尊重しつつ不足補完
		if typeof(b.maxSlots) ~= "number" then
			b.maxSlots = maxSlots
		else
			b.maxSlots = math.max(1, math.floor(b.maxSlots))
		end

		if typeof(b.unlocked) ~= "number" then
			b.unlocked = math.min(b.maxSlots, minUnlocked)
		else
			b.unlocked = math.floor(b.unlocked)
			-- 整合性のためだけに丸め（増減の意思決定はしない）
			if b.unlocked < 0 then b.unlocked = 0 end
			if b.unlocked > b.maxSlots then b.unlocked = b.maxSlots end
		end

		if typeof(b.slots) ~= "table" then
			b.slots = { nil, nil, nil, nil, nil, nil }
		else
			b.slots = _clone6(b.slots)
		end
	end

	return b
end

return M
