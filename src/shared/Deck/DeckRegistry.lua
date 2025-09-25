-- ReplicatedStorage/SharedModules/Deck/DeckRegistry.lua
-- v0.9.3+uid +dumpSnapshot DeckRegistry（ラン別の共有レジストリ）
-- 役割:
--   - runId 単位で v3 形式の deck store（{v=3, entries=[...] }）を保持
--   - state(run.configSnapshot / state.deck など) から初期化/補完
--   - v1/v2 スナップショットも CardEngine で復元して v3 entries へ正規化
--   - ★ entries に uid を必ず付与（code 重複でも一意に識別できる）
--   - ★ UID 指定での 1枚差し替えユーティリティを提供
--   - ★ dumpSnapshot を追加（v3 store → Round.newRound(opts.deckSnapshot) 互換形式へ）

-- 依存:
--   - CardEngine（buildDeckFromSnapshot / buildSnapshot / toCode / fromCode / buildDeck）
--   - RunDeckUtil（任意）: snapshot(state) があれば使う
--   - Logger（任意）: scope("DeckRegistry")

local RS     = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("SharedModules")

local CardEngine = require(Shared:WaitForChild("CardEngine"))

local RunDeckUtil do
	local ok, mod = pcall(function()
		return require(Shared:WaitForChild("RunDeckUtil"))
	end)
	RunDeckUtil = ok and mod or nil
end

local Logger do
	local ok, mod = pcall(function()
		return require(Shared:WaitForChild("Logger"))
	end)
	Logger = ok and mod or { scope=function() return { info=function()end, warn=function()end, debug=function()end } end }
end
local LOG = Logger.scope("DeckRegistry")

local M = {}

-- メモリレジストリ: { [runId] = { v=3, entries={...} } }
local _byRunId : {[any]: any} = {}

-- ─────────────────────────────────────────────────────────────
-- 内部ユーティリティ
-- ─────────────────────────────────────────────────────────────

local function _cloneEntryLike(e:any)
	if typeof(e) ~= "table" then return nil end
	return {
		uid   = e.uid,  -- ★透過（無ければ後で採番）
		code  = tostring(e.code or ""),
		kind  = e.kind,
		month = e.month,
		idx   = e.idx,
		name  = e.name,  -- 任意
		tags  = typeof(e.tags)=="table" and table.clone(e.tags) or nil,
	}
end

local function _toV3Store(entries:any)
	local out = {}
	if typeof(entries) == "table" then
		for _, e in ipairs(entries) do
			local c = _cloneEntryLike(e)
			if c then
				-- month/idx が無いなら code から補完
				local m = tonumber(c.month or 0) or 0
				local i = tonumber(c.idx   or 0) or 0
				if (m <= 0 or i <= 0) and typeof(c.code) == "string" and #c.code >= 4 then
					local pm, pi = CardEngine.fromCode(c.code)
					if m <= 0 then c.month = pm end
					if i <= 0 then c.idx   = pi end
				end
				-- code が無いなら month/idx から生成
				if (not c.code or c.code == "") and c.month and c.idx then
					c.code = CardEngine.toCode(c.month, c.idx)
				end
				if c.code and c.code ~= "" then
					table.insert(out, c)
				end
			end
		end
	end
	return { v=3, entries=out }
end

local function _resolveRunId(ctx:any)
	if typeof(ctx) ~= "table" then return nil end
	-- 直下候補
	if ctx.runId then return ctx.runId end
	if ctx.deckRunId then return ctx.deckRunId end
	if ctx.id then return ctx.id end
	if ctx.runID then return ctx.runID end
	if ctx.deckRunID then return ctx.deckRunID end
	-- run サブツリー
	local run = ctx.run
	if typeof(run) == "table" then
		return run.runId or run.deckRunId or run.id or run.runID or run.deckRunID
	end
	return nil
end

-- state → 初期スナップ（優先順: run.configSnapshot → RunDeckUtil.snapshot(state) → state.deck）
local function _snapshotFromState(state:any)
	if typeof(state) ~= "table" then return nil end
	state.run = state.run or {}

	-- 1) 正本: run.configSnapshot
	if typeof(state.run.configSnapshot) == "table" then
		return state.run.configSnapshot
	end

	-- 2) 任意: RunDeckUtil.snapshot
	if RunDeckUtil and typeof(RunDeckUtil.snapshot) == "function" then
		local ok, snap = pcall(function() return RunDeckUtil.snapshot(state) end)
		if ok and typeof(snap) == "table" then
			return snap
		end
	end

	-- 3) 後方互換: state.deck（配列から v2 snapshot）
	if typeof(state.deck) == "table" and #state.deck > 0 then
		local ok, snap = pcall(function()
			return CardEngine.buildSnapshot(state.deck)
		end)
		if ok and typeof(snap) == "table" then
			return snap
		end
	end

	return nil
end

-- v1/v2 snapshot → entries（CardEngine が {month,idx,kind,name,tags,code} を返す想定）
local function _entriesFromSnapshot(snap:any)
	if typeof(snap) ~= "table" then return {} end
	local ok, deck = pcall(function() return CardEngine.buildDeckFromSnapshot(snap) end)
	if not ok or typeof(deck) ~= "table" then return {} end
	return deck
end

-- uid 生成: "CODE#NNN"（NNN は 001 起算の 3桁ゼロパディング）
local function _uidFor(code:string, seq:number)
	return string.format("%s#%03d", tostring(code or ""), math.max(1, math.floor(tonumber(seq) or 1)))
end

-- entries に uid を採番（既存 uid は尊重）。code ごとに連番を採番する。
local function _ensureUids(store:any)
	if typeof(store) ~= "table" or typeof(store.entries) ~= "table" then return store end
	local seqByCode = {} :: {[string]: number}
	-- 既存 uid を走査して、code ごとの最大連番を把握
	for _, e in ipairs(store.entries) do
		local code = tostring(e.code or "")
		if e.uid and typeof(e.uid) == "string" then
			local seq = tonumber(string.match(e.uid, "#(%d+)$") or "")
			if seq then
				local cur = seqByCode[code] or 0
				if seq > cur then seqByCode[code] = seq end
			end
		end
	end
	-- 未付与に順次採番
	for _, e in ipairs(store.entries) do
		if not e.uid or e.uid == "" then
			local code = tostring(e.code or "")
			local nextSeq = (seqByCode[code] or 0) + 1
			e.uid = _uidFor(code, nextSeq)
			seqByCode[code] = nextSeq
		end
	end
	return store
end

-- 旧→新への uid 継承（新 entries に uid が無い場合、code の出現順で割り当て）
local function _inheritUids(prev:any, incoming:any)
	if typeof(incoming) ~= "table" or typeof(incoming.entries) ~= "table" then return _toV3Store({}) end
	local newStore = _toV3Store(incoming.entries)

	-- 新側に uid がほぼ載っていないケース向けに、code 毎のキューを作る
	local byCodeQueues : {[string]: {any}} = {}
	if typeof(prev) == "table" and typeof(prev.entries) == "table" then
		for _, e in ipairs(prev.entries) do
			local code = tostring(e.code or "")
			byCodeQueues[code] = byCodeQueues[code] or {}
			table.insert(byCodeQueues[code], e) -- 先頭から消費
		end
	end

	for _, e in ipairs(newStore.entries) do
		if not e.uid or e.uid == "" then
			local code = tostring(e.code or "")
			local q = byCodeQueues[code]
			if q and #q > 0 then
				-- 旧から1つ借りる
				local old = table.remove(q, 1)
				e.uid = old.uid
			end
		end
	end

	-- まだ uid が空いているものは採番
	_ensureUids(newStore)
	return newStore
end

-- 文字列整形ユーティリティ（ログ用）
local function _short(e:any)
	if typeof(e) ~= "table" then return "-" end
	return string.format("uid=%s code=%s kind=%s tags=%d",
		tostring(e.uid or "?"),
		tostring(e.code or "?"),
		tostring(e.kind or "?"),
		(typeof(e.tags)=="table" and #e.tags) or 0
	)
end

-- ─────────────────────────────────────────────────────────────
-- 公開API
-- ─────────────────────────────────────────────────────────────

-- state/runCtx から runId を解決し、未登録なら v3 store を生成して登録（uid も付与）
function M.ensureFromContext(ctx:any): boolean
	local runId = _resolveRunId(ctx)
	if not runId then
		LOG.info("[DeckRegistry] ensure: missing runId in ctx; skip")
		return false
	end
	if _byRunId[runId] and typeof(_byRunId[runId].entries) == "table" and #_byRunId[runId].entries > 0 then
		return true
	end

	-- state からスナップを得て v3 化
	local snap    = _snapshotFromState(ctx)
	local entries = _entriesFromSnapshot(snap)
	local store   = _toV3Store(entries)
	_ensureUids(store)

	if typeof(store.entries) == "table" and #store.entries > 0 then
		_byRunId[runId] = store
		LOG.info("[DeckRegistry] ensure: set run=%s size=%d (from snapshot)", tostring(runId), #store.entries)
		return true
	end

	-- それでも無ければ、CardEngine.buildDeck() から初期48で作る
	local ok, deck48 = pcall(function() return CardEngine.buildDeck() end)
	if ok and typeof(deck48) == "table" then
		local s = _toV3Store(deck48)
		_ensureUids(s)
		_byRunId[runId] = s
		LOG.warn("[DeckRegistry] ensure: fallback to base 48 for run=%s", tostring(runId))
		return true
	end

	return false
end

-- 旧呼び名互換（ログにも合わせておく）
M.ensure = M.ensureFromContext

-- 直接書き込み（uid を整えて保存）
function M.write(runId:any, v3store:any)
	if not runId then return false end
	if typeof(v3store) ~= "table" or typeof(v3store.entries) ~= "table" then return false end
	local s = _toV3Store(v3store.entries)
	_ensureUids(s)
	_byRunId[runId] = s
	LOG.info("[DeckRegistry] write: run=%s size=%d", tostring(runId), #(s.entries or {}))
	return true
end

-- v2 snapshot を書き込み（移行/保存用）※uid 採番あり
function M.writeSnapshot(runId:any, snap:any)
	if not runId then return false end
	local entries = _entriesFromSnapshot(snap)
	local s = _toV3Store(entries)
	_ensureUids(s)
	_byRunId[runId] = s
	LOG.info("[DeckRegistry] writeSnapshot: run=%s size=%d", tostring(runId), #(s.entries or {}))
	return true
end

-- 読み出し
function M.read(runId:any)
	if not runId then return { v=3, entries={} } end
	local s = _byRunId[runId]
	if s and typeof(s.entries) == "table" then
		return s
	end
	return { v=3, entries={} }
end

-- 破棄
function M.clear(runId:any)
	_byRunId[runId] = nil
	LOG.info("[DeckRegistry] clear: run=%s", tostring(runId))
end

-- デバッグ/枚数
function M.size(runId:any): number
	local s = M.read(runId)
	return typeof(s.entries)=="table" and #s.entries or 0
end

-- ★ 変更コミット: 新 v3store を取り込み（uid 継承→不足採番）
function M.commit(runId:any, incoming:any)
	if not runId then return false end
	local prev = _byRunId[runId]
	local prevCount = (prev and typeof(prev.entries)=="table") and #prev.entries or 0

	local merged = _inheritUids(prev, incoming)
	_byRunId[runId] = merged

	local newCount = (merged and typeof(merged.entries)=="table") and #merged.entries or 0
	LOG.info("[DeckRegistry] commit: run=%s prev=%d new=%d", tostring(runId), prevCount, newCount)

	-- 差分（kind変化）を最大3件だけログ
	local diffs = 0
	if prev and typeof(prev.entries)=="table" and merged and typeof(merged.entries)=="table" then
		-- uid -> entry マップ
		local pmap = {}
		for _, e in ipairs(prev.entries) do
			if e and e.uid then pmap[e.uid] = e end
		end
		for _, ne in ipairs(merged.entries) do
			if diffs >= 3 then break end
			local pe = ne and ne.uid and pmap[ne.uid]
			if pe and tostring(pe.kind or "") ~= tostring(ne.kind or "") then
				LOG.info("[DeckRegistry] commit.diff: uid=%s code=%s kind:%s→%s",
					tostring(ne.uid), tostring(ne.code),
					tostring(pe.kind or "?"), tostring(ne.kind or "?"))
				diffs += 1
			end
		end
	end

	return true
end

-- ★ UID 検索（1枚）
function M.findByUid(runId:any, uid:string)
	if not runId or type(uid) ~= "string" then return nil, nil end
	local s = _byRunId[runId]; if not s or typeof(s.entries) ~= "table" then return nil, nil end
	for i, e in ipairs(s.entries) do
		if e.uid == uid then
			LOG.debug("[DeckRegistry] findByUid: run=%s %s", tostring(runId), _short(e))
			return e, i
		end
	end
	return nil, nil
end

-- ★ UID 置換（1枚）: mutator(existingEntry) -> newEntry(or nil=削除)
function M.replaceByUid(runId:any, uid:string, mutator:(any)->(any?))
	if not runId or type(uid) ~= "string" or type(mutator) ~= "function" then return false end
	local s = _byRunId[runId]; if not s or typeof(s.entries) ~= "table" then return false end

	for i, e in ipairs(s.entries) do
		if e.uid == uid then
			local before = _cloneEntryLike(e)
			local ok, newE = pcall(mutator, e)
			if not ok then return false end
			if newE == nil then
				table.remove(s.entries, i) -- 削除
				_byRunId[runId] = s
				LOG.info("[DeckRegistry] replaceByUid: run=%s uid=%s -> removed", tostring(runId), tostring(uid))
				return true
			else
				-- 置換（uid は必ず保持）
				local c = _cloneEntryLike(newE) or {}
				c.uid = e.uid
				-- コード/種別/補完
				if (not c.code or c.code=="") and c.month and c.idx then
					c.code = CardEngine.toCode(c.month, c.idx)
				end
				if (not c.month or not c.idx) and c.code then
					local pm, pi = CardEngine.fromCode(c.code)
					c.month = c.month or pm
					c.idx   = c.idx   or pi
				end
				s.entries[i] = c
				_byRunId[runId] = s

				LOG.info("[DeckRegistry] replaceByUid: run=%s before={%s} after={%s}", tostring(runId), _short(before), _short(c))
				return true
			end
		end
	end
	return false
end

-- ★ v3 store → 「構成デッキ」スナップショットに変換
-- Round.newRound(opts.deckSnapshot) の snapshotToConfigDeck が受けられる形
-- 具体的には { cards = [{month,idx,kind,name,tags,code}, ...] } を返す
function M.dumpSnapshot(runId:any)
	if not runId then return nil end
	local s = _byRunId[runId]
	if not (s and typeof(s.entries)=="table") then
		return nil
	end
	local cards = {}
	for i, e in ipairs(s.entries) do
		cards[i] = {
			month = e.month,
			idx   = e.idx,
			kind  = e.kind,
			name  = e.name,
			tags  = (typeof(e.tags)=="table" and table.clone(e.tags) or nil),
			code  = e.code,
		}
	end
	return { cards = cards }
end

-- ★ runId 解決を外部にも提供（便利）
function M.resolveRunId(ctx:any) return _resolveRunId(ctx) end

return M
