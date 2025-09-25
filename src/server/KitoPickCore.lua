-- ServerScriptService/KitoPickCore.lua
-- v0.9.5 KITO Pick Core (DeckRegistry + UID consistent, EN-only)
-- Purpose:
--   - Build and send a 12-card candidate pool for the picker UI
--   - Keep/expire a simple session
-- Policy:
--   - UID-first (entries[*].uid is the single source of truth; legacy decks may use code as fallback)
--   - Exclude months that do not have a "bright" card
--   - KITO_SAME_KIND_POLICY: "block" (exclude already-bright) / "allow" (include)

local RS = game:GetService("ReplicatedStorage")

-- Config / Logger
local Balance    = require(RS:WaitForChild("Config"):WaitForChild("Balance"))
local Logger     = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG        = Logger.scope("KitoPickCore")

-- Deck APIs
local Shared     = RS:WaitForChild("SharedModules")
local CardEngine = require(Shared:WaitForChild("CardEngine"))
local DeckReg    = require(Shared:WaitForChild("Deck"):WaitForChild("DeckRegistry"))

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
-- Resolve runId from context
--─────────────────────────────────────────────────────────────
local function resolveRunId(runCtx:any)
	if type(runCtx) ~= "table" then return nil end
	-- direct
	local direct = runCtx.runId or runCtx.deckRunId or runCtx.id or runCtx.deckRunID or runCtx.runID
	if direct then return direct end
	-- nested run
	local run = runCtx.run
	if type(run) == "table" then
		return run.runId or run.deckRunId or run.id or run.deckRunID or run.runID
	end
	return nil
end

--─────────────────────────────────────────────────────────────
-- Helpers: month/image/eligibility
--─────────────────────────────────────────────────────────────
local function parseMonth(entry:any): number?
	if type(entry) ~= "table" then return nil end
	local m = tonumber(entry.month)
	if m and m>=1 and m<=12 then return m end
	local s = tostring(entry.code or entry.uid or "")
	local two = string.match(s, "^(%d%d)")
	return (two and tonumber(two)) or nil
end

-- Only check for "bright" existence in the month (EN-only)
local function monthHasBright(month:number): boolean
	local defs = CardEngine.cardsByMonth[month]
	if typeof(defs) ~= "table" then return false end
	for _, def in ipairs(defs) do
		if tostring(def.kind or "") == "bright" then
			return true
		end
	end
	return false
end

local function resolveImage(code:string?)
	local ok, got = pcall(function()
		if type(CardImageMap.get) == "function" then return CardImageMap.get(code) end
	end)
	if ok and got ~= nil then return got end
	return nil
end

local function toSummary(entry:any, targetKind:string, sameKindPolicy:string)
	if type(entry) ~= "table" then return nil end
	local m = parseMonth(entry)
	if not m or not monthHasBright(m) then return nil end

	local same = tostring(entry.kind or "") == tostring(targetKind or "")
	if sameKindPolicy == "block" and same then
		-- already the same kind ("bright") -> exclude from pool
		return nil
	end

	local sum = {
		uid      = entry.uid or entry.code,   -- UID is the truth; legacy may fallback to code
		code     = entry.code,                -- for display/image lookup
		name     = entry.name or entry.code,
		kind     = entry.kind,
		month    = m,
		eligible = true,
	}
	local img = resolveImage(entry.code)
	if type(img) == "string" then
		sum.image = img
	elseif type(img) == "number" or tonumber(img) then
		sum.imageId = tonumber(img)
	end
	return sum
end

--─────────────────────────────────────────────────────────────
-- Public: build & send 12-card pool (KITO: Rooster/bright)
--─────────────────────────────────────────────────────────────
-- effectId: "kito_tori" / targetKind: "bright"
function Core.startFor(player: Player, runCtx:any, effectId: string, targetKind: string)
	if Balance.KITO_UI_ENABLED ~= true then
		LOG.debug("[StartFor] UI disabled; ignored | user=%s", player and player.Name or "?")
		return false
	end
	if tostring(effectId) ~= "kito_tori" then
		LOG.debug("[StartFor] unsupported effect=%s | user=%s", tostring(effectId), player and player.Name or "?")
		return false
	end

	-- Resolve runId and ensure entries in DeckRegistry
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

	-- EN-only target kind
	local tgtKind = "bright"
	local policy  = tostring(Balance.KITO_SAME_KIND_POLICY or "block") -- "block"|"allow"
	local pickN   = tonumber(Balance.KITO_UI_PICK_COUNT or Balance.KITO_POOL_SIZE or 12) or 12

	-- Build pool (UID-first)
	local pool = {}
	for _, e in ipairs(store.entries) do
		local s = toSummary(e, tgtKind, policy)
		if s then table.insert(pool, s) end
	end
	if #pool == 0 then
		LOG.info("[StartFor] no candidates; aborted | user=%s run=%s", player and player.Name or "?", tostring(runId))
		return false
	end

	-- Shuffle and take first N (independent RNG)
	local seed = math.floor((os.clock() % 1) * 1e9)
	local rng  = Random.new(seed)
	for i = #pool, 2, -1 do
		local j = rng:NextInteger(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local list = {}
	for i = 1, math.min(#pool, pickN) do
		list[#list+1] = pool[i]
	end

	-- Session
	local sess = {
		id        = string.format("kito-%d-%d", player.UserId, now()),
		version   = "v3",
		createdAt = now(),
		expiresAt = now() + ttlSec(),
		runId     = runId,
		effectId  = effectId,
		uids      = (function()
			local t = {}
			for _, s in ipairs(list) do t[#t+1] = s.uid end
			return t
		end)(),
	}
	put(player.UserId, sess)

	-- Client payload (EN-only)
	local payload = {
		sessionId  = sess.id,
		version    = sess.version,
		expiresAt  = sess.expiresAt,
		effectId   = effectId,
		targetKind = tgtKind,
		list       = list,    -- {uid,code?,name,kind,month,image?/imageId?,eligible}
		effect     = ("Select one target (goal: %s)"):format("Bright"),
	}
	EvStart:FireClient(player, payload)

	-- Log summary
	local same, other = 0, 0
	for _, s in ipairs(list) do
		if tostring(s.kind or "") == tgtKind then same += 1 else other += 1 end
	end
	LOG.info("[StartFor] user=%s sid=%s size=%d tgt=%s same=%d other=%d head5=[%s]",
		player and player.Name or "?",
		tostring(sess.id),
		#list, tgtKind, same, other,
		headList(sess.uids, 5)
	)

	return true
end

return Core
