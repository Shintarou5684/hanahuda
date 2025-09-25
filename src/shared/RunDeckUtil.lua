-- ReplicatedStorage/SharedModules/RunDeckUtil.lua
-- 役割：ラン状態のユーティリティ。
-- 変更:
--  - getUnlockedTalismanSlots(state): state.run から安全に読取り、無ければ 0 を返す
--  - ensureTalisman(state, opts): 護符テーブルの存在と最低限の形を保証（不足キーのみ補完）
--  - ★ KITOプール基盤（正本=run.configSnapshot へ完全寄せ）
--      * getDeckWithUids(state)       : 一時デッキ（uid=code 付与）を生成
--      * ensureUids(state)            : no-op（互換のため残す）
--      * getDeckVersion/bumpDeckVersion: run.deckVersion に集約
--      * buildUidIndexMap(state)      : getDeckWithUids 基準で作成
--      * applyDeckPatchByUid(state,p) : decode→patch→encode（正本更新）
--      * addEffectTag/hasEffectTag    : 再適用ガード用タグ
--      * monthHasBright(month)        : 当月に光札が“定義として”存在するか判定
--      * entryWithKindLike(src, kind) : 同月で指定kindの定義エントリを返す

-- v0.9.0+ ラン構成ユーティリティ（唯一の正本：run.configSnapshot）
-- ここだけを読み書きする。季節ごとの山札は毎季これをクローンして生成。

local RS          = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

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

--==================================================
-- ★ KITOプール基盤：Deck Versioning / UID / 差分適用
--==================================================

-- 内部: snapshot から「uid=code」を付与した一時デッキを生成
local function _deckWithUidsFromSnapshot(snap)
	local deck = CardEngine.buildDeckFromSnapshot(snap)
	for _, e in ipairs(deck) do
		e.code = e.code or CardEngine.toCode(tonumber(e.month), tonumber(e.idx))
		e.uid  = e.uid  or e.code
	end
	return deck
end

-- 公開API: 現在ランの一時デッキ（uid付き）を取得
function M.getDeckWithUids(state)
	local snap = M.snapshot(state)
	return _deckWithUidsFromSnapshot(snap)
end

-- 再適用ガード用タグ
local function ensureEffectTags(state)
	state.run = state.run or {}
	state.run.meta = state.run.meta or {}
	state.run.meta.effectTags = state.run.meta.effectTags or {}
	return state.run.meta.effectTags
end

function M.addEffectTag(state, tag)
	if type(tag) ~= "string" or tag == "" then return end
	local t = ensureEffectTags(state)
	t[tag] = true
end

function M.hasEffectTag(state, tag)
	local t = ensureEffectTags(state)
	return t[tag] == true
end

-- 当月に光札が“定義として”存在するか
function M.monthHasBright(month)
	local m = tonumber(month or 0) or 0
	if m <= 0 then return false end
	local defs = CardEngine.cardsByMonth[m]
	if typeof(defs) ~= "table" then return false end
	for _, def in ipairs(defs) do
		if def and tostring(def.kind) == "hikari" then
			return true
		end
	end
	return false
end

-- Deck内の各エントリに uid を保証（旧APIは no-op に）
function M.ensureUids(_state:any)
	-- no-op（互換維持。必要なら getDeckWithUids を使用）
	return
end

-- デッキ版数を取得（run.deckVersion のみを正とする）
function M.getDeckVersion(state:any): number
	if typeof(state) ~= "table" then return 1 end
	state.run = state.run or {}
	local v = tonumber(state.run.deckVersion or 0) or 0
	if v <= 0 then v = 1 end
	state.run.deckVersion = v
	return v
end

-- デッキ版数を+1して返す
function M.bumpDeckVersion(state:any): number
	local v = M.getDeckVersion(state) + 1
	state.run.deckVersion = v
	return v
end

-- uid→index のマップを構築（スナップショット復元基準）
function M.buildUidIndexMap(state:any): {[string]:number}
	local map = {}
	local deck = M.getDeckWithUids(state)
	for i, e in ipairs(deck) do
		if typeof(e) == "table" and e.uid then
			map[e.uid] = i
		end
	end
	return map
end

-- uid 指定差分を適用（対象：run.configSnapshot）
-- patch = {
--   replace = { [uid]=entryTable, ... }?,  -- entry.uid は無視され uid を再付与
--   remove  = { [uid]=true, ... }?         -- 対象 uid のカードをデッキから削除
-- }
function M.applyDeckPatchByUid(state:any, patch:{replace:any?, remove:any?})
	if typeof(state) ~= "table" then return false end

	-- 1) decode（uid=code 付与）
	local snap = M.snapshot(state)
	local deck = _deckWithUidsFromSnapshot(snap)
	if typeof(deck) ~= "table" then return false end

	-- 2) 作業用インデックス
	local map = {}
	for i, e in ipairs(deck) do
		if typeof(e) == "table" and e.uid then
			map[e.uid] = i
		end
	end

	-- 3) 置換
	if patch and typeof(patch.replace) == "table" then
		for uid, entry in pairs(patch.replace) do
			local idx = map[uid]
			if idx then
				local src = deck[idx]
				local nextEntry = table.clone(entry)
				-- uid は維持（外部入力の uid は無視）
				nextEntry.uid = uid

				-- code が無ければ (month, idx) or kind から安全生成
				if not nextEntry.code then
					if nextEntry.month and nextEntry.idx then
						nextEntry.code = CardEngine.toCode(nextEntry.month, nextEntry.idx)
					elseif nextEntry.kind and src and src.month then
						local def = M.entryWithKindLike(src, tostring(nextEntry.kind))
						if def then
							nextEntry.month = def.month
							nextEntry.idx   = def.idx
							nextEntry.kind  = def.kind
							nextEntry.name  = def.name
							nextEntry.tags  = def.tags and table.clone(def.tags) or nil
							nextEntry.code  = def.code
						end
					end
				end
				-- 最後の保険
				nextEntry.code = nextEntry.code or (src and src.code) or uid

				deck[idx] = nextEntry
			end
		end
	end

	-- 4) 削除（降順）
	if patch and typeof(patch.remove) == "table" then
		local rm = {}
		for uid, flag in pairs(patch.remove) do
			if flag and map[uid] then table.insert(rm, map[uid]) end
		end
		table.sort(rm, function(a,b) return a>b end)
		for _, i in ipairs(rm) do
			table.remove(deck, i)
		end
	end

	-- 5) encode（正本を更新）
	M.saveConfig(state, deck)

	-- 6) 版数UP（互換: run.deckVersion）
	M.bumpDeckVersion(state)
	return true
end

-- 同月で kind が近い（=指定kind）の定義エントリに安全変換
-- src: 現在のデッキエントリ {month, idx, kind, ...}
-- 戻り値: 変換後の「定義に基づく」エントリ（uidは含まない）
function M.entryWithKindLike(src:any, targetKind:string)
	if typeof(src) ~= "table" then return nil end
	local m = tonumber(src.month or 0) or 0
	if m <= 0 then return nil end
	local defs = CardEngine.cardsByMonth[m]
	if typeof(defs) ~= "table" then return nil end
	for i, def in ipairs(defs) do
		if def and tostring(def.kind) == tostring(targetKind) then
			return {
				month = m,
				idx   = i,
				kind  = def.kind,
				name  = def.name,
				tags  = def.tags and table.clone(def.tags) or nil,
				code  = CardEngine.toCode(m, i),
			}
		end
	end
	return nil
end

return M
