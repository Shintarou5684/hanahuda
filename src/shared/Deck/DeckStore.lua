-- SharedModules/Deck/DeckStore.lua
-- v3 Deck を **非破壊**で扱うストア（純関数API）
-- 依存: DeckSchema（v2→v3補完/1枚補完）
-- ★ 0.9.x+: すべてのエントリに一意ID(uid)を付与（code連番）し、uidでの操作を追加

local RS = game:GetService("ReplicatedStorage")
local SharedModules = RS:WaitForChild("SharedModules")
local DeckSchema = require(SharedModules:WaitForChild("Deck"):WaitForChild("DeckSchema"))

-- ★ DeckRegistry（transact で利用）
local DeckRegistry = require(SharedModules:WaitForChild("Deck"):WaitForChild("DeckRegistry"))

-- ★ code→month/idx 補完の保険（DeckSchemaで入れば不要だが互換のため同梱）
local CardEngine do
	local ok, mod = pcall(function() return require(SharedModules:WaitForChild("CardEngine")) end)
	CardEngine = ok and mod or nil
end

local bit32 = bit32

local M = {}

--==================================================
-- ユーティリティ
--==================================================

local function tableCreate(n:number)
	n = math.max(0, math.floor(tonumber(n) or 0))
	return table.create(n)
end

local function cloneArray(arr:any)
	if typeof(arr) ~= "table" then return {} end
	local n = #arr
	local out = tableCreate(n)
	for i = 1, n do
		out[i] = arr[i]
	end
	return out
end

-- ★ cloneEntry: DeckSchema.defaults の戻りを尊重しつつ uid を落とさない
local function cloneEntry(e:any)
	-- DeckSchema.defaults は新テーブルを返す想定
	local ok, res = pcall(function()
		return DeckSchema.defaults(e)
	end)
	local out
	if ok and typeof(res) == "table" then
		out = res
	else
		-- 失敗時は最小限のダミー
		out = {
			code  = e and e.code or "",
			kind  = e and e.kind or nil,
			month = e and e.month or nil,
			idx   = e and e.idx or nil,
			name  = e and e.name or nil,
			tags  = e and e.tags or nil,
		}
	end
	-- 既存uidが来ていたら保持（後段で最終確定）
	if e and e.uid and e.uid ~= "" then
		out.uid = e.uid
	end
	return out
end

-- ★ uid採番: codeごとに通番（人間可読/安定）
local function assignUids(entries:any)
	local n = #entries
	if n == 0 then return entries end

	-- code -> seq
	local seqByCode = {}

	for i = 1, n do
		local e = entries[i]
		-- code正規化
		local code = tostring(e.code or "")

		-- month/idx の保険：なければ code から復元（DeckSchemaで入っていれば何もしない）
		if (not e.month or not e.idx) and CardEngine and code ~= "" then
			local ok, m, idx = pcall(function()
				local mm, ii = CardEngine.fromCode(code)
				return mm, ii
			end)
			if ok then
				e.month = e.month or m
				e.idx   = e.idx   or idx
			end
		end

		-- codeが空のときは month/idx から生成（最悪 "0000"）
		if code == "" then
			local mm = tonumber(e.month) or 0
			local ii = tonumber(e.idx) or 0
			code = string.format("%02d%02d", mm, ii)
			e.code = code
		end

		-- 既に uid があれば尊重（重複チェックはしない：外部生成を優先）
		if not e.uid or e.uid == "" then
			seqByCode[code] = (seqByCode[code] or 0) + 1
			e.uid = string.format("%s#%03d", code, seqByCode[code])
		end
	end
	return entries
end

local function normalizeEntries(entriesLike:any)
	if typeof(entriesLike) ~= "table" then return {} end
	local n = #entriesLike
	local out = tableCreate(n)
	for i = 1, n do
		out[i] = cloneEntry(entriesLike[i])
	end
	-- ★ ここで uid を必ず付与/整える（本質ポイント）
	return assignUids(out)
end

-- Mulberry32（32bit厳守版 / bit32使用）
local function rngMulberry32(seed:any)
	local s = tonumber(seed) or 0
	s = s % 4294967296
	return function()
		s = (s + 0x6D2B79F5) % 4294967296
		local t = s
		t = bit32.bxor(t, bit32.rshift(t, 15))
		t = (t * bit32.bor(t, 1)) % 4294967296
		t = bit32.bxor(t, (t + ((bit32.bxor(t, bit32.rshift(t, 7)) * bit32.bor(t, 61)) % 4294967296)) % 4294967296)
		t = bit32.bxor(t, bit32.rshift(t, 14))
		return (t % 4294967296) / 4294967296
	end
end

--==================================================
-- 構築・スナップショット
--==================================================

function M.fromDeckV3(deckLike:any)
	local v3 = DeckSchema.normalizeDeck(deckLike)
	return {
		v = 3,
		entries = normalizeEntries(v3 and v3.entries),
	}
end

function M.toDeckV3(store:any)
	local entries = normalizeEntries(store and store.entries)
	local n = #entries
	local codes = tableCreate(n)
	for i = 1, n do
		codes[i] = entries[i].code
	end
	return {
		v = 3,
		codes = codes,
		entries = entries,
		count = n,
	}
end

--==================================================
-- 基本操作（すべて非破壊）
--==================================================

function M.size(store:any): number
	local e = store and store.entries
	return (typeof(e) == "table") and #e or 0
end

function M.peek(store:any, idx:number?) -- idx 未指定=トップ
	local n = M.size(store)
	if n == 0 then return nil end
	idx = math.clamp(math.floor(tonumber(idx or 1) or 1), 1, n)
	return store.entries[idx]
end

-- index の1枚を取り出す（戻り: newStore, takenEntry）
function M.takeAt(store:any, idx:number)
	local n = M.size(store)
	if n == 0 then return store, nil end
	idx = math.clamp(math.floor(tonumber(idx) or 1), 1, n)

	local newEntries = tableCreate(math.max(n - 1, 0))
	local k = 1
	local taken = nil
	for i = 1, n do
		local e = store.entries[i]
		if i == idx then
			taken = e
		else
			newEntries[k] = e
			k += 1
		end
	end
	return { v = 3, entries = newEntries }, taken
end

-- トップ1枚を取り出す（戻り: newStore, takenEntry）
function M.drawTop(store:any)
	return M.takeAt(store, 1)
end

-- 指定コードの最初の1枚を取り出す（後方互換：なるべく使わない）
function M.takeByCode(store:any, code:string)
	if type(code) ~= "string" then return store, nil end
	local n = M.size(store)
	if n == 0 then return store, nil end
	for i = 1, n do
		local e = store.entries[i]
		if e and e.code == code then
			return M.takeAt(store, i)
		end
	end
	return store, nil
end

-- ★ uid 検索/取り出し（推奨）
function M.findIndexByUid(store:any, uid:string): number?
	if type(uid) ~= "string" then return nil end
	for i = 1, M.size(store) do
		local e = store.entries[i]
		if e and e.uid == uid then
			return i
		end
	end
	return nil
end

function M.takeByUid(store:any, uid:string)
	local idx = M.findIndexByUid(store, uid)
	if not idx then return store, nil end
	return M.takeAt(store, idx)
end

-- 末尾に追加（複数可）
function M.addBottom(store:any, entriesLike:any)
	local base = (store and store.entries) or {}
	local add = normalizeEntries((typeof(entriesLike) == "table" and entriesLike) or { entriesLike })
	local nb, na = #base, #add
	local newEntries = tableCreate(nb + na)
	for i = 1, nb do newEntries[i] = base[i] end
	for j = 1, na do newEntries[nb + j] = add[j] end
	return { v = 3, entries = newEntries }
end

-- 先頭に追加（複数可）
function M.addTop(store:any, entriesLike:any)
	local base = (store and store.entries) or {}
	local add = normalizeEntries((typeof(entriesLike) == "table" and entriesLike) or { entriesLike })
	local nb, na = #base, #add
	local newEntries = tableCreate(nb + na)
	for i = 1, na do newEntries[i] = add[i] end
	for j = 1, nb do newEntries[na + j] = base[j] end
	return { v = 3, entries = newEntries }
end

-- 任意位置に差し替え（1枚）
function M.replaceAt(store:any, idx:number, newEntry:any)
	local n = M.size(store)
	if n == 0 then return store end
	idx = math.clamp(math.floor(tonumber(idx) or 1), 1, n)
	local e = cloneEntry(newEntry)

	local newEntries = cloneArray(store.entries)
	newEntries[idx] = e
	return { v = 3, entries = newEntries }
end

-- entries 全体を map（関数に通して置換）
-- f: (entry, index) -> CardEntryV3|nil   nil を返すと削除
function M.map(store:any, f:(any, number)->(any?))
	if type(f) ~= "function" then return store end
	local base = (store and store.entries) or {}
	local out = {}
	for i = 1, #base do
		local ok, e = pcall(f, base[i], i)
		if ok and e ~= nil then
			out[#out + 1] = cloneEntry(e)
		end
	end
	-- mapの出力にも uid を保証
	return { v = 3, entries = assignUids(out) }
end

-- コードで検索（最初の index / 見つからなければ nil）
function M.findIndexByCode(store:any, code:string): number?
	if type(code) ~= "string" then return nil end
	for i = 1, M.size(store) do
		local e = store.entries[i]
		if e and e.code == code then
			return i
		end
	end
	return nil
end

--==================================================
-- シャッフル（シード対応・非破壊）
--==================================================
-- Fisher–Yates
function M.shuffle(store:any, seed:number?)
	local n = M.size(store)
	if n <= 1 then return store end
	local rnd = rngMulberry32(seed or time() * 1000)
	local arr = cloneArray(store.entries)

	for i = n, 2, -1 do
		local j = 1 + math.floor(rnd() * i) -- 1..i
		arr[i], arr[j] = arr[j], arr[i]
	end
	return { v = 3, entries = arr }
end

--==================================================
-- ビュー（UI向け最小VM：imageId/badges/kind/month/name）
--==================================================
-- imageId は「imageOverride ?? CardImageMap.get(code)」を呼び元で解決する前提
function M.toViewModels(store:any, resolver:(any)->(any)?)
	local n = M.size(store)
	local out = tableCreate(n)
	for i = 1, n do
		local e = store.entries[i]
		local r
		if type(resolver) == "function" then
			local ok, res = pcall(resolver, e)
			if ok then r = res end
		end
		out[i] = {
			imageId = r and r.imageId or nil,
			name    = r and r.name or nil,
			badges  = r and r.badges or nil,
			kind    = e and e.kind or nil,
			month   = e and e.month or nil,
			code    = e and e.code or "",
			uid     = e and e.uid or "", -- ★ 追加：UIでも uid を参照できる
		}
	end
	return out
end

--==================================================
-- 追加: DeckStore.transact（DeckRegistry 経由でコミット）
--==================================================
-- f: (storeV3) -> newStoreV3[, resultAny]
function M.transact(runId:any, f:(any)->(any))
	if not DeckRegistry then
		error("DeckStore.transact: DeckRegistry is not available")
	end
	if runId == nil or runId == "" then
		error("DeckStore.transact: runId is required")
	end
	if type(f) ~= "function" then
		error("DeckStore.transact: callback must be function")
	end

	-- 現在のストアを読み出し
	local cur = DeckRegistry.read(runId)

	-- ユーザ関数を安全に実行（複数戻り対応）
	local ok, newStore, result = pcall(f, cur)
	if not ok then
		error(("DeckStore.transact: callback threw: %s"):format(tostring(newStore)))
	end
	if typeof(newStore) ~= "table" or typeof(newStore.entries) ~= "table" then
		error("DeckStore.transact: callback must return a v3 store table")
	end

	-- 反映（uid 継承/採番は DeckRegistry.commit 側で面倒を見る）
	DeckRegistry.commit(runId, newStore)

	-- newStore, result をそのまま返す（複数戻り）
	return newStore, result
end

return M
