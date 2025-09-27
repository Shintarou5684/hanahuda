-- ServerScriptService/KitoPickCore.lua
-- v0.9.7 KITO Pick Core (anyK + canApply eligibility, UID-first, EN-only)
-- Purpose:
--   - Build and send a K-card candidate pool for the picker UI (always K if available; K = KITO_UI_PICK_COUNT or KITO_POOL_SIZE)
--   - Attach server-authoritative eligibility (can/cannot apply + reason) per card
--   - Keep/expire a simple session
-- Policy:
--   - UID-first (entries[*].uid is the single source of truth; legacy decks may use code as fallback)
--   - NO pre-filtering by month/kind here: pool is random (anyK). Eligibility decides gray-out.
--   - POOL_MODE fallback: Balance.KITO_POOL_MODE = "eligible12" for legacy behavior (optional)
--   - Server is the only source of truth; client displays what server says

local RS = game:GetService("ReplicatedStorage")

-- Config / Logger
local Balance    = require(RS:WaitForChild("Config"):WaitForChild("Balance"))
local Logger     = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG        = Logger.scope("KitoPickCore")

-- Shared deps
local Shared        = RS:WaitForChild("SharedModules")
local CardEngine    = require(Shared:WaitForChild("CardEngine"))
local DeckReg       = require(Shared:WaitForChild("Deck"):WaitForChild("DeckRegistry"))
local DeckSampler   = require(Shared:WaitForChild("DeckSampler"))
local Effects       = require(Shared:WaitForChild("Deck"):WaitForChild("EffectsRegistry"))

-- 🔧 Optional bootstrap: auto-scan Deck/Effects and register handlers/canApply if available
local function tryRequire(inst: Instance?)
	if not inst or not inst:IsA("ModuleScript") then return end
	local ok, err = pcall(require, inst)
	if not ok then
		LOG.warn("[EffectsBootstrap] require failed: %s", tostring(err))
	end
end
do
	local deckFolder = Shared:FindFirstChild("Deck")
	if deckFolder then
		tryRequire(deckFolder:FindFirstChild("EffectsRegisterAll"))
	end
end

-- Remotes
local Remotes  = RS:WaitForChild("Remotes")
local EvStart  = Remotes:WaitForChild("KitoPickStart") -- RemoteEvent

-- Card image resolver (optional)
local CardImageMap do
	local ok, mod = pcall(function()
		return require(Shared:WaitForChild("CardImageMap"))
	end)
	if ok and type(mod) == "table" then
		CardImageMap = mod
	else
		CardImageMap = { get = function(_) return nil end }
		LOG.debug("CardImageMap not found; images will be omitted")
	end
end

local Core = {}

--─────────────────────────────────────────────────────────────
-- Session store (simple)
--─────────────────────────────────────────────────────────────
local sessions: {[number]: any} = {}

local function headList(list, n)
	local out = {}
	if type(list) == "table" then
		for i = 1, math.min(#list, n) do out[#out+1] = tostring(list[i]) end
	end
	return table.concat(out, ",")
end

local function now() return os.time() end
local function ttlSec()
	return tonumber(Balance.KITO_POOL_TTL_SEC or 45) or 45
end

local function put(userId: number, sess: any)
	sessions[userId] = sess
end

function Core.peek(userId: number)
	local s = sessions[userId]
	LOG.debug("[Peek] userId=%s has=%s sid=%s", tostring(userId), tostring(s~=nil), s and tostring(s.id) or "-")
	return s
end

function Core.consume(userId: number)
	local s = sessions[userId]
	if s then
		LOG.debug("[Consume] userId=%s take sid=%s", tostring(userId), tostring(s.id))
	else
		LOG.debug("[Consume] userId=%s no-session", tostring(userId))
	end
	sessions[userId] = nil
	return s
end

--─────────────────────────────────────────────────────────────
-- Helpers
--─────────────────────────────────────────────────────────────
local function resolveRunId(runCtx:any)
	if type(runCtx) ~= "table" then return nil end
	-- direct
	local direct = runCtx.runId or runCtx.deckRunId or runCtx.id or runCtx.deckRunID or runCtx.runID
	if direct then return direct end
	-- nested
	local run = runCtx.run
	if type(run) == "table" then
		return run.runId or run.deckRunId or run.id or run.deckRunID or run.runID
	end
	return nil
end

local function resolveImage(code:string?)
	local ok, got = pcall(function()
		if type(CardImageMap.get) == "function" then return CardImageMap.get(code) end
	end)
	if ok and got ~= nil then return got end
	return nil
end

local function parseMonth(entry:any): number?
	if type(entry) ~= "table" then return nil end
	local m = tonumber(entry.month)
	if m and m>=1 and m<=12 then return m end
	local s = tostring(entry.code or entry.uid or "")
	local two = string.match(s, "^(%d%d)")
	return (two and tonumber(two)) or nil
end

local function toSummary(entry:any)
	if type(entry) ~= "table" then return nil end
	local sum = {
		uid   = entry.uid or entry.code,   -- UID is the truth; fallback to code for very old entries
		code  = entry.code,
		name  = entry.name or entry.code,
		kind  = entry.kind,
		month = parseMonth(entry),
	}
	local img = resolveImage(entry.code)
	if type(img) == "string" then
		sum.image = img
	elseif type(img) == "number" or tonumber(img) then
		sum.imageId = tonumber(img)
	end
	return sum
end

local function buildUidMap(entries:{any}): {[string]: any}
	local m = {}
	for _, e in ipairs(entries) do
		local uid = e and e.uid
		if typeof(uid) == "string" and #uid > 0 then
			m[uid] = e
		elseif e and e.code then
			-- legacy fallback
			m[tostring(e.code)] = e
		end
	end
	return m
end

-- eligibility per UID using Effects.canApply
local function computeEligibility(effectId: string, uidMap:{[string]:any}, uids:{string}): ({[string]:{ok:boolean, reason:string?}}, number)
	local ctx = { DeckStore = true, DeckOps = true, CardEngine = CardEngine } -- minimal stub; Effects.canApply側で不足補完あり
	local elig = {}
	local okCount = 0
	for _, uid in ipairs(uids) do
		local card = uidMap[uid]
		local ok, reason = Effects.canApply(effectId, card, ctx)
		elig[uid] = { ok = ok == true, reason = reason }
		if ok == true then okCount += 1 end
	end
	return elig, okCount
end

-- pick anyK using DeckSampler with a synthetic state
local function sampleAnyFromStore(runId:any, store:any, K:number): {string}
	local state = { runId = runId, deck = store and store.entries or {} }
	-- DeckSampler internally ensures UIDs via RunDeckUtil.ensureUids(state)
	return DeckSampler.sampleUids(state, K)
end

-- legacy mode: pick only eligible candidates up to N
local function sampleEligible(effectId:string, entries:{any}, N:number): {string}
	local uids = {}
	for _, e in ipairs(entries) do
		local card = e
		local ok = select(1, Effects.canApply(effectId, card, { CardEngine = CardEngine }))
		if ok == true then
			uids[#uids+1] = e.uid or e.code
		end
	end
	-- shuffle uids and take first N
	local seed = math.floor((os.clock() % 1) * 1e9)
	local rng  = Random.new(seed)
	for i = #uids, 2, -1 do
		local j = rng:NextInteger(1, i)
		uids[i], uids[j] = uids[j], uids[i]
	end
	local out = {}
	for i=1, math.min(N, #uids) do out[i] = uids[i] end
	return out
end

--─────────────────────────────────────────────────────────────
-- Public: build & send K-card pool (generic effectId)
--─────────────────────────────────────────────────────────────
-- effectId: e.g. "kito.tori_brighten", "kito.mi_venom" ...
-- targetKind param is ignored (kept for compatibility)
function Core.startFor(player: Player, runCtx:any, effectId: string, targetKind: string?)
	if Balance.KITO_UI_ENABLED ~= true then
		LOG.debug("[StartFor] UI disabled; ignored | user=%s", player and player.Name or "?")
		return false
	end
	if type(effectId) ~= "string" or #effectId == 0 or not Effects.has(effectId) then
		LOG.debug("[StartFor] unsupported effect=%s | user=%s", tostring(effectId), player and player.Name or "?")
		return false
	end

	-- Resolve runId and ensure deck entries
	local runId = resolveRunId(runCtx)
	if not runId then
		local hasRun = (type(runCtx)=="table" and type(runCtx.run)=="table")
		LOG.info("[StartFor] missing runId; aborted | user=%s hasRun=%s", player and player.Name or "?", tostring(hasRun))
		return false
	end
	DeckReg.ensureFromContext(runCtx)
	local store = DeckReg.read(runId)
	if typeof(store) ~= "table" or typeof(store.entries) ~= "table" or #store.entries == 0 then
		LOG.info("[StartFor] no deck entries; aborted | user=%s run=%s", player and player.Name or "?", tostring(runId))
		return false
	end

	-- K は UI_PICK_COUNT 優先（未設定なら POOL_SIZE）
	local pickN = tonumber(Balance.KITO_UI_PICK_COUNT or Balance.KITO_POOL_SIZE or 12) or 12
	local mode  = tostring(Balance.KITO_POOL_MODE or "any12_disable_ineligible") -- "any12_disable_ineligible" | "eligible12"

	-- Build pool (UID list)
	local uids
	if mode == "eligible12" then
		uids = sampleEligible(effectId, store.entries, pickN)
	else
		-- ✅ anyK: UI_PICK_COUNT を確実に反映
		uids = sampleAnyFromStore(runId, store, pickN)
	end
	if #uids == 0 then
		LOG.info("[StartFor] empty pool; aborted | user=%s run=%s", player and player.Name or "?", tostring(runId))
		return false
	end

	-- To summaries for UI (code/kind/month/image)
	local uidMap = buildUidMap(store.entries)
	local list = {}
	for _, uid in ipairs(uids) do
		local e = uidMap[uid]
		local s = e and toSummary(e)
		if s then list[#list+1] = s end
	end
	if #list == 0 then
		LOG.info("[StartFor] no summaries; aborted | user=%s run=%s", player and player.Name or "?", tostring(runId))
		return false
	end

	-- Eligibility per UID（server-authoritative）
	local eligibility, okCount = computeEligibility(effectId, uidMap, uids)

	-- Session
	local sess = {
		id        = string.format("kito-%d-%d", player.UserId, now()),
		version   = "v3",
		createdAt = now(),
		expiresAt = now() + ttlSec(),
		runId     = runId,
		effectId  = effectId,
		uids      = uids,
	}
	put(player.UserId, sess)

	-- Client payload（list + poolUids + eligibility）
	-- list: [{uid,code,name,kind,month,image?/imageId?}]
	-- eligibility: { [uid] = { ok:boolean, reason?:string } }
	local payload = {
		sessionId   = sess.id,
		version     = sess.version,
		expiresAt   = sess.expiresAt,
		effectId    = effectId,
		list        = list,
		poolUids    = uids,
		eligibility = eligibility,
		effect      = "Select one target", -- simple EN label; UI側でi18n可
	}
	EvStart:FireClient(player, payload)

	-- Log summary
	local gray = #uids - okCount
	LOG.info("[StartFor] user=%s sid=%s size=%d ok=%d gray=%d head5=[%s] mode=%s",
		player and player.Name or "?",
		tostring(sess.id),
		#uids, okCount, gray,
		headList(sess.uids, 5),
		mode
	)

	return true
end

return Core
