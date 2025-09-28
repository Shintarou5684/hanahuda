-- ReplicatedStorage/SharedModules/Deck/Effects/kito/Inu_Chaff2.lua
-- Inu (KITO): convert up to TWO target cards to "chaff" (UID-first, without replacement)
--  - Effect IDs: "kito.inu_chaff2" (primary), "kito_inu" (legacy alias), "kito.inu_two_chaff" (alias)
--  - Prioritize payload.uid / payload.uids / payload.poolUids (UID uniquely identifies one card)
--  - Fallback to codes only if no UID is provided
--  - DeckStore (v3) is immutable; use DeckStore.transact and replace entries (UID-first)
--  - RNG is separated (ctx.rng preferred, otherwise Random.new())
--  - If a month has no "chaff", do nothing for that card (meta per-target)
--  - Diagnostic logs (scope: Effects.kito.inu_chaff2)
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
			LOG = Logger.scope("Effects.kito.inu_chaff2")
		else
			LOG = { info=function(...) end, debug=function(...) end, warn=function(...) warn(string.format(...)) end }
		end
	end

	--─────────────────────────────────────────────────────
	-- Shared handler for both effect IDs
	--─────────────────────────────────────────────────────
	local function handler(ctx)
		local payload     = ctx.payload or {}
		local uidScalar   = (typeof(payload.uid)  == "string" and payload.uid)  or nil
		local uids        = (typeof(payload.uids) == "table"  and payload.uids) or nil
		local poolUids    = (typeof(payload.poolUids) == "table" and payload.poolUids) or nil
		local codes       = (typeof(payload.codes) == "table" and payload.codes) or nil -- legacy compat
		local poolCodes   = (typeof(payload.poolCodes) == "table" and payload.poolCodes) or nil -- legacy compat

		local tagMark     = tostring(payload.tag or "eff:kito_inu_chaff2")
		local preferKind  = "chaff"
		local targetCount = 2

		local runId       = ctx.runId
		local rng         = ctx.rng or Random.new()

		local function head5(list)
			if typeof(list) ~= "table" then return "-" end
			local out, n = {}, math.min(#list, 5)
			for i = 1, n do out[i] = tostring(list[i]) end
			return table.concat(out, ",")
		end

		LOG.debug("[deps] DeckStore=%s DeckOps=%s CardEngine=%s",
			tostring(ctx.DeckStore ~= nil), tostring(ctx.DeckOps ~= nil), tostring(ctx.CardEngine ~= nil))
		LOG.info("[begin] run=%s tag=%s | uid=%s uids[%s]=[%s] poolUids[%s]=[%s] codes[%s]=[%s] poolCodes[%s]=[%s]",
			tostring(runId), tagMark, tostring(uidScalar),
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

		local uidSet = listToSet(uids) or {}
		if uidScalar then uidSet[uidScalar] = true end
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

		local function monthHasKind(month:number?, kind:string): boolean
			if not month or not ctx.CardEngine or not ctx.CardEngine.cardsByMonth then return false end
			local defs = ctx.CardEngine.cardsByMonth[month]
			if typeof(defs) ~= "table" then return false end
			for _, def in ipairs(defs) do
				if tostring(def.kind or "") == kind then
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

		local function keyOf(e) return (e and e.uid and e.uid ~= "") and ("uid:"..e.uid) or ("code:"..tostring(e and e.code or "")) end

		-- sampling without replacement
		local function sampleN(list, n)
			local out = {}
			if typeof(list) ~= "table" then return out end
			local tmp = table.clone(list)
			local m = math.min(#tmp, n)
			for i = 1, m do
				local j = rng:NextInteger(1, #tmp)
				out[#out+1] = table.remove(tmp, j)
			end
			return out
		end

		--─────────────────────────────────────────────────────
		-- Target selection (up to 2 unique entries)
		-- Priority: UID → Code → pool(UID) → pool(Code) → any eligible month
		--─────────────────────────────────────────────────────
		local function buildCandidates(store, pred)
			local entries = (store and store.entries) or {}
			local list = {}
			for _, e in ipairs(entries) do if pred(e) then list[#list+1] = e end end
			return list
		end

		local function pickTargets(store)
			local chosen, seen = {}, {}
			local function takeFrom(list, howMany, randomize)
				if #chosen >= targetCount then return end
				local src = list
				if randomize then src = sampleN(list, #list) end
				for _, e in ipairs(src) do
					local k = keyOf(e)
					if not seen[k] then
						chosen[#chosen+1] = e
						seen[k] = true
						if #chosen >= targetCount then break end
					end
				end
			end

			-- predicates
			local function hasChaff(e) return e ~= nil and monthHasKind(monthFromCard(e), "chaff") end
			local function matchUid(e) return e and e.uid and uidSet and uidSet[e.uid] and hasChaff(e) end
			local function matchCode(e) return e and e.code and codeSet and codeSet[e.code] and hasChaff(e) end
			local function matchPoolUid(e) return e and e.uid and poolUidSet and poolUidSet[e.uid] and hasChaff(e) end
			local function matchPoolCode(e) return e and e.code and poolCodeSet and poolCodeSet[e.code] and hasChaff(e) end
			local function anyChaff(e) return hasChaff(e) end

			-- 0) direct UIDs
			local list0 = buildCandidates(store, matchUid)
			LOG.debug("[pick] direct-uid candidates=%d", #list0)
			takeFrom(list0, targetCount - #chosen, true)

			-- 1) direct codes
			if #chosen < targetCount then
				local list1 = buildCandidates(store, matchCode)
				LOG.debug("[pick] direct-code candidates=%d", #list1)
				takeFrom(list1, targetCount - #chosen, true)
			end

			-- 2) pool by UID
			if #chosen < targetCount then
				local list2 = buildCandidates(store, matchPoolUid)
				LOG.debug("[pick] pool-uid candidates=%d", #list2)
				takeFrom(list2, targetCount - #chosen, true)
			end

			-- 3) pool by code
			if #chosen < targetCount then
				local list3 = buildCandidates(store, matchPoolCode)
				LOG.debug("[pick] pool-code candidates=%d", #list3)
				takeFrom(list3, targetCount - #chosen, true)
			end

			-- 4) any entry whose month has "chaff"
			if #chosen < targetCount then
				local list4 = buildCandidates(store, anyChaff)
				LOG.debug("[pick] any-chaff-month candidates=%d", #list4)
				takeFrom(list4, targetCount - #chosen, true)
			end

			return chosen
		end

		--─────────────────────────────────────────────────────
		-- Replace helpers
		--─────────────────────────────────────────────────────
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

		--─────────────────────────────────────────────────────
		-- Main (DeckStore.transact)
		--─────────────────────────────────────────────────────
		local t0 = os.clock()
		LOG.debug("[transact] run=%s enter", tostring(runId))
		return ctx.DeckStore.transact(runId, function(store)
			local storeSize = (store and store.entries and #store.entries) or 0
			LOG.debug("[store] size=%s", tostring(storeSize))

			local targets = pickTargets(store)
			if not targets or #targets == 0 then
				LOG.info("[result] no-eligible-target")
				return store, { ok = true, changed = 0, meta = "no-eligible-target", picked = 0 }
			end

			LOG.debug("[targets] picked=%d %s%s",
				#targets,
				cardStr(targets[1]),
				(#targets >= 2 and (" "..cardStr(targets[2])) or "")
			)

			local changed, applied = 0, {}
			for idx, target in ipairs(targets) do
				-- Idempotency: if already tagged, skip
				if alreadyTagged(target) then
					LOG.info("[skip] already-applied uid=%s code=%s (i=%d)", tostring(target.uid), tostring(target.code), idx)
				else
					local next1 = ctx.DeckOps.convertKind(target, preferKind)
					if tostring(next1.kind or "") ~= "chaff" then
						LOG.info("[skip] month-has-no-chaff uid=%s code=%s (i=%d)", tostring(target.uid), tostring(target.code), idx)
					else
						local next2 = ctx.DeckOps.attachTag(next1, tagMark)
						if not next2.uid then next2.uid = target.uid end
						-- replace (prefer UID)
						if target.uid and target.uid ~= "" then
							store = replaceOneByUid(store, target.uid, next2)
						else
							store = replaceOneByCode(store, target.code, next2)
						end
						changed += 1
						applied[#applied+1] = { uid = target.uid, code = target.code }
						LOG.debug("[applied] #%d -> %s", idx, cardStr(next2))
					end
				end
			end

			local dt = (os.clock() - t0) * 1000
			LOG.info("[result] ok changed=%d picked=%d in %.2fms", changed, #targets, dt)
			return store, {
				ok        = true,
				changed   = changed,  -- 0..2
				picked    = #targets, -- 0..2
				applied   = applied,  -- list of {uid,code}
			}
		end)
	end

	--─────────────────────────────────────────────────────
	-- canApply（UIグレーアウト等に利用）
	--  - 単カード判定: 既タグでない ＆ まだ "chaff" でない ＆ その月に chaff 定義がある
	--    ※ 効果自体は2枚処理するが、UI側は個別カード可否の表示に使える
	--─────────────────────────────────────────────────────
	local function registerCanApply(id)
		Effects.registerCanApply(id, function(card, ctx2)
			if type(card) ~= "table" then return false, "not-eligible" end
			local tags = (type(card.tags)=="table") and card.tags or {}
			for _,t in ipairs(tags) do if t=="eff:kito_inu_chaff2" then return false, "already-applied" end end
			if tostring(card.kind) == "chaff" then return false, "already-chaff" end

			local function monthFrom(c)
				if c.month ~= nil then
					local m = tonumber(c.month); if typeof(m)=="number" then return m end
				end
				local code = tostring(c.code or ""); if #code>=2 then
					local mm = tonumber(string.sub(code,1,2)); if typeof(mm)=="number" then return mm end
				end
				return nil
			end

			local m = monthFrom(card)
			if not m then return false, "not-eligible" end

			local CE = ctx2.CardEngine
			if not CE or type(CE.cardsByMonth)~="table" then return false, "not-eligible" end
			local defs = CE.cardsByMonth[m]
			if type(defs)~="table" then return false, "month-has-no-chaff" end
			for _,d in ipairs(defs) do
				if tostring(d.kind)=="chaff" then return true end
			end
			return false, "month-has-no-chaff"
		end)
	end

	-- Primary ID
	Effects.register("kito.inu_chaff2", handler)
	registerCanApply("kito.inu_chaff2")
	-- Legacy alias
	Effects.register("kito_inu", handler)
	registerCanApply("kito_inu")
	-- Alias for ShopDefs consistency
	Effects.register("kito.inu_two_chaff", handler)
	registerCanApply("kito.inu_two_chaff")
end
