-- ReplicatedStorage/SharedModules/RunDeckUtil.lua
-- v0.8.3 ラン中デッキの「保存／復元」を一元化（次季へ引き継ぐ）

local RS          = game:GetService("ReplicatedStorage")
local SharedMods  = RS:WaitForChild("SharedModules")
local CardEngine  = require(SharedMods:WaitForChild("CardEngine"))

local M = {}

-- state.run.deck（テーブル）を優先して返す。
-- 次点で state.run.deckSnapshot（v2: entries優先 / v1: codes）から復元して state.run.deck に戻す。
function M.load(state: any): {any}?
	if typeof(state) ~= "table" then return nil end
	state.run = state.run or {}

	-- すでにテーブルで保持されていればそれを使う
	if typeof(state.run.deck) == "table" and #state.run.deck > 0 then
		return state.run.deck
	end

	-- スナップショットから復元
	local snap = state.run.deckSnapshot
	if typeof(snap) == "table" then
		local deck
		if snap.v == 2 then
			deck = CardEngine.buildDeckFromSnapshot(snap)
		elseif typeof(snap.codes) == "table" then
			deck = CardEngine.buildDeckFromCodes(snap.codes)
		end
		if typeof(deck) == "table" and #deck > 0 then
			state.run.deck = deck
			return deck
		end
	end

	return nil
end

-- 現在の「正本」デッキをスナップショットとして state.run.deckSnapshot に保存
-- 正本＝山・手・場・取り（＋捨て等）を合算した 48 枚を想定（entries.kind を保持）
function M.save(state: any)
	if typeof(state) ~= "table" then return end
	state.run = state.run or {}
	state.run.deckSnapshot = CardEngine.buildSnapshotFromState(state)
end

return M
