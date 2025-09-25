-- ReplicatedStorage/SharedModules/Deck/Effects/kito/Tori_Brighten.lua
-- Rooster (KITO): convert one target card to "bright" (UID-first)
--  - Effect IDs: "kito.tori_brighten" (primary), "Tori_Brighten" (legacy alias)
--  - Prioritize payload.uids / payload.poolUids (UID uniquely identifies one card)
--  - Fallback to codes only if no UID is provided
--  - DeckStore (v3) is treated as immutable; use DeckStore.transact to replace one entry (UID-first)
--  - RNG is separated (ctx.rng preferred, otherwise Random.new())
--  - If the month has no "bright", do nothing (meta returned)
--  - ★ Diagnostic logs added (scope: Effects.kito.tori_brighten)

return function(Effects)
	--─────────────────────────────────────────────────────
	-- Logger (optional)
	--─────────────────────────────────────────────────────
	local LOG do
		local ok, Logger = pcall(function()
			return require(game:GetService("ReplicatedStorage")
				:WaitForChild("SharedModules")
				:WaitForChild("Logger"))
		end)
		if ok and Logger and type(Logger.scope) == "function" then
			LOG = Logger.scope("Effects.kito.tori_brighten")
		else
			-- silent no-op logger
			LOG = {
				info  = function(...) end,
				debug = function(...) end,
				warn  = function(...) warn(string.format(...)) end,
			}
		end
	end

	--─────────────────────────────────────────────────────
	-- Shared handler for both effect IDs
	--─────────────────────────────────────────────────────
	local function handler(ctx)
		local payload    = ctx.payload or {}
		local uids       = (typeof(payload.uids)       == "table" and payload.uids)       or nil
		local poolUids   = (typeof(payload.poolUids)   == "table" and payload.poolUids)   or nil
		local codes      = (typeof(payload.codes)      == "table" and payload.codes)      or nil -- legacy compat
		local poolCodes  = (typeof(payload.poolCodes)  == "table" and payload.poolCodes)  or nil -- legacy compat
		local tagMark    = tostring(payload.tag or "eff:kito_tori_bright")
		local pref       = tostring(payload.preferKind or "bright"):lower()
		local preferKind = (pref == "bright") and "bright" or "bright" -- force EN-only "bright"
		local runId      = ctx.runId

		local rng = ctx.rng or Random.new()

		-- quick payload summary for logs
		local function head5(list)
			if typeof(list) ~= "table" then return "-" end
			local out, n = {}, math.min(#list, 5)
			for i = 1, n do out[i] = tostring(list[i]) end
			return table.concat(out, ",")
		end

		-- 依存注入の存在可否も一度だけ観測
		LOG.debug("[deps] DeckStore=%s DeckOps=%s CardEngine=%s",
			tostring(ctx.DeckStore ~= nil), tostring(ctx.DeckOps ~= nil), tostring(ctx.CardEngine ~= nil))

		LOG.info("[begin] run=%s prefer=%s tag=%s | uids[%s]=[%s] poolUids[%s]=[%s] codes[%s]=[%s] poolCodes[%s]=[%s]",
			tostring(runId), preferKind, tagMark,
			tostring(uids and #uids or 0), head5(uids),
			tostring(poolUids and #poolUids or 0), head5(poolUids),
			tostring(codes and #codes or 0), head5(codes),
			tostring(poolCodes and #poolCodes or 0), head5(poolCodes)
		)

		--─────────────────────────────────────────────────────
		-- helpers
		--─────────────────────────────────────────────────────
		local function listToSet(list)
			if typeof(list) ~= "table" then return nil end
			local s = {}
			for _, v in ipairs(list) do s[v] = true end
			return s
		end

		local uidSet      = listToSet(uids)
		local poolUidSet  = listToSet(poolUids)
		local codeSet     = listToSet(codes)
		local poolCodeSet = listToSet(poolCodes)

		local function monthFromCard(card:any): number?
			if not card then return nil end
			if card.month ~= nil then
				local m = tonumber(card.month)
				if typeof(m) == "number" then return m end
			end
			local code = tostring(card.code or "")
			if #code >= 2 then
				local mm = tonumber(string.sub(code, 1, 2))
				if typeof(mm) == "number" then return mm end
			end
			return nil
		end

		-- EN-only: a month is eligible only if it contains a "bright" definition
		local function monthHasBright(month:number?): boolean
			if not month or not ctx.CardEngine or not ctx.CardEngine.cardsByMonth then return false end
			local defs = ctx.CardEngine.cardsByMonth[month]
			if typeof(defs) ~= "table" then return false end
			for _, def in ipairs(defs) do
				if tostring(def.kind or "") == "bright" then
					return true
				end
			end
			return false
		end

		local function alreadyTagged(card)
			if typeof(card) ~= "table" or typeof(card.tags) ~= "table" then return false end
			for _, t in ipairs(card.tags) do if t == tagMark then return true end end
			return false
		end

		local function cardStr(c:any)
			if typeof(c) ~= "table" then return "<nil>" end
			return string.format("{uid=%s code=%s kind=%s month=%s idx=%s tags=%s}",
				tostring(c.uid), tostring(c.code), tostring(c.kind),
				tostring(c.month), tostring(c.idx),
				(function()
					if typeof(c.tags) ~= "table" then return "[]" end
					local t = {}
					for i,v in ipairs(c.tags) do t[i] = tostring(v) end
					return "["..table.concat(t, ",").."]"
				end)()
			)
		end

		-- Replace one entry by UID (preserve UID and core fields)
		local function replaceOneByUid(store, uid, newEntry)
			local entries = (store and store.entries) or {}
			local n = #entries; if n == 0 then return store end
			local out = table.create(n)
			local done = false
			for i = 1, n do
				local e = entries[i]
				if (not done) and e and e.uid == uid then
					local c = table.clone(newEntry or {})
					c.uid   = e.uid
					c.code  = c.code  or e.code
					c.month = c.month or e.month
					c.idx   = c.idx   or e.idx
					out[i]  = c
					done    = true
				else
					out[i] = e
				end
			end
			if done then
				LOG.debug("[replaceByUid] uid=%s -> %s", tostring(uid), cardStr(newEntry))
			else
				LOG.warn("[replaceByUid] uid=%s not found (no-op)", tostring(uid))
			end
			return { v = 3, entries = out }
		end

		-- Replace one entry by code (legacy fallback)
		local function replaceOneByCode(store, code, newEntry)
			local entries = (store and store.entries) or {}
			local n = #entries; if n == 0 then return store end
			local out = table.create(n)
			local done = false
			for i = 1, n do
				local e = entries[i]
				if (not done) and e and e.code == code then
					local c = table.clone(newEntry or {})
					c.uid   = e.uid
					c.code  = c.code  or e.code
					c.month = c.month or e.month
					c.idx   = c.idx   or e.idx
					out[i]  = c
					done    = true
				else
					out[i] = e
				end
			end
			if done then
				LOG.debug("[replaceByCode] code=%s -> %s", tostring(code), cardStr(newEntry))
			else
				LOG.warn("[replaceByCode] code=%s not found (no-op)", tostring(code))
			end
			return { v = 3, entries = out }
		end

		-- Target selection order: UID → Code → pool(UID/Code) → all
		-- In all cases, restrict to months that contain "bright".
		local function pickTarget(store)
			local entries = (store and store.entries) or {}
			-- 0) direct UID
			if uidSet then
				local list = {}
				for _, e in ipairs(entries) do
					if e and e.uid and uidSet[e.uid] then
						local m = monthFromCard(e)
						if monthHasBright(m) then list[#list+1] = e end
					end
				end
				LOG.debug("[pick] direct-uid candidates=%d", #list)
				if #list > 0 then return list[rng:NextInteger(1, #list)], "direct-uid" end
			end
			-- 1) direct code
			if codeSet then
				local list = {}
				for _, e in ipairs(entries) do
					if e and e.code and codeSet[e.code] then
						local m = monthFromCard(e)
						if monthHasBright(m) then list[#list+1] = e end
					end
				end
				LOG.debug("[pick] direct-code candidates=%d", #list)
				if #list > 0 then return list[rng:NextInteger(1, #list)], "direct-code" end
			end
			-- 2) pool by UID
			if poolUidSet then
				local cand = {}
				for _, e in ipairs(entries) do
					if e and e.uid and poolUidSet[e.uid] then
						local m = monthFromCard(e)
						if monthHasBright(m) then cand[#cand+1] = e end
					end
				end
				LOG.debug("[pick] pool-uid candidates=%d", #cand)
				if #cand > 0 then return cand[rng:NextInteger(1, #cand)], "pool-uid" end
			end
			-- 3) pool by code
			if poolCodeSet then
				local cand = {}
				for _, e in ipairs(entries) do
					if e and e.code and poolCodeSet[e.code] then
						local m = monthFromCard(e)
						if monthHasBright(m) then cand[#cand+1] = e end
					end
				end
				LOG.debug("[pick] pool-code candidates=%d", #cand)
				if #cand > 0 then return cand[rng:NextInteger(1, #cand)], "pool-code" end
			end
			-- 4) any entry whose month has "bright"
			local all = {}
			for _, e in ipairs(entries) do
				local m = monthFromCard(e)
				if monthHasBright(m) then all[#all+1] = e end
			end
			LOG.debug("[pick] any-bright-month candidates=%d", #all)
			if #all > 0 then return all[rng:NextInteger(1, #all)], "any-bright-month" end
			return nil, "none"
		end

		--─────────────────────────────────────────────────────
		-- Main (DeckStore.transact)
		--─────────────────────────────────────────────────────
		local t0 = os.clock()
		LOG.debug("[transact] run=%s enter", tostring(runId))
		return ctx.DeckStore.transact(runId, function(store)
			local storeSize = (store and store.entries and #store.entries) or 0
			LOG.debug("[store] size=%s", tostring(storeSize))

			local target, reason = pickTarget(store)
			if not target then
				LOG.info("[result] no-eligible-target (pickReason=%s)", tostring(reason))
				return store, { ok = true, changed = 0, meta = "no-eligible-target", pickReason = reason }
			end

			LOG.debug("[target] via=%s %s", tostring(reason), cardStr(target))

			if alreadyTagged(target) then
				LOG.info("[result] already-applied uid=%s code=%s (via=%s)", tostring(target.uid), tostring(target.code), tostring(reason))
				return store, { ok = true, changed = 0, meta = "already-applied", targetUid = target.uid, targetCode = target.code, pickReason = reason }
			end

			-- Convert to "bright"（同月の bright に idx を寄せる）
			local beforeIdx, beforeCode, beforeKind = target.idx, target.code, target.kind
			local next1 = ctx.DeckOps.convertKind(target, preferKind)
			local afterIdx, afterCode, afterKind = next1.idx, next1.code, next1.kind
			LOG.debug("[convert] idx:%s→%s code:%s→%s kind:%s→%s",
				tostring(beforeIdx), tostring(afterIdx),
				tostring(beforeCode), tostring(afterCode),
				tostring(beforeKind), tostring(afterKind))

			if tostring(afterKind or "") ~= "bright" then
				LOG.info("[result] month-has-no-bright uid=%s code=%s (via=%s)", tostring(target.uid), tostring(target.code), tostring(reason))
				return store, { ok = true, changed = 0, meta = "month-has-no-bright", targetUid = target.uid, targetCode = target.code, pickReason = reason }
			end

			-- Tag（UID 維持）
			local next2 = ctx.DeckOps.attachTag(next1, tagMark)
			if not next2.uid then next2.uid = target.uid end
			LOG.debug("[tagged] %s", cardStr(next2))

			-- Replace: prefer UID when available
			if target.uid and target.uid ~= "" then
				store = replaceOneByUid(store, target.uid, next2)
			else
				store = replaceOneByCode(store, target.code, next2)
			end

			local dt = (os.clock() - t0) * 1000
			LOG.info("[result] ok changed=1 uid=%s code=%s via=%s in %.2fms", tostring(target.uid), tostring(target.code), tostring(reason), dt)
			return store, { ok = true, changed = 1, targetUid = target.uid, targetCode = target.code, pickReason = reason }
		end)
	end

	-- Primary ID
	Effects.register("kito.tori_brighten", handler)
	-- Legacy alias
	Effects.register("Tori_Brighten", handler)
end
