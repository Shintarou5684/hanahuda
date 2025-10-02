-- ReplicatedStorage/SharedModules/Deck/Effects/kito/Usagi_Ribbonize.lua
-- Usagi (KITO / DOT-ONLY): convert one target card to "ribbon" (UID-first)
--  - Effect ID: "kito.usagi_ribbon"（唯一の真実）
--  - Prioritize payload.uid / payload.uids / payload.poolUids (UID uniquely identifies one card)
--  - Fallback to codes only if no UID is provided
--  - DeckStore (v3) is treated as immutable; use DeckStore.transact to replace one entry (UID-first)
--  - RNG is separated (ctx.rng preferred, otherwise Random.new())
--  - If the month has no "ribbon", do nothing (meta returned)
--  - Diagnostic logs (scope: Effects.kito.usagi_ribbon)

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
			LOG = Logger.scope("Effects.kito.usagi_ribbon")
		else
			LOG = { info=function(...) end, debug=function(...) end, warn=function(...) warn(string.format(...)) end }
		end
	end

	--─────────────────────────────────────────────────────
	-- Handler (DOT-ONLY)
	--─────────────────────────────────────────────────────
	local function handler(ctx)
		local payload     = ctx.payload or {}
		local uidScalar   = (typeof(payload.uid)  == "string" and payload.uid)  or nil
		local uids        = (typeof(payload.uids) == "table"  and payload.uids) or nil
		local poolUids    = (typeof(payload.poolUids) == "table" and payload.poolUids) or nil
		local codes       = (typeof(payload.codes) == "table" and payload.codes) or nil -- code指定のみ互換
		local poolCodes   = (typeof(payload.poolCodes) == "table" and payload.poolCodes) or nil -- 互換

		-- ★ DOT-ONLY タグ表記（Kito.apply_via_effects の tag="eff:<moduleId>" と一致）
		local tagMark     = tostring(payload.tag or "eff:kito.usagi_ribbon")
		local preferKind  = "ribbon"

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

		--──────────────── helpers ────────────────
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

		-- Target selection order: UID → Code → pool(UID/Code) → any eligible month
		local function pickTarget(store)
			local entries = (store and store.entries) or {}
			-- 0) direct UID(s)
			if uidSet and next(uidSet) ~= nil then
				local list = {}
				for _, e in ipairs(entries) do
					if e and e.uid and uidSet[e.uid] and monthHasKind(monthFromCard(e), "ribbon") then
						list[#list+1] = e
					end
				end
				LOG.debug("[pick] direct-uid candidates=%d", #list)
				if #list > 0 then return list[rng:NextInteger(1, #list)], "direct-uid" end
			end
			-- 1) direct code(s)
			if codeSet then
				local list = {}
				for _, e in ipairs(entries) do
					if e and e.code and codeSet[e.code] and monthHasKind(monthFromCard(e), "ribbon") then
						list[#list+1] = e
					end
				end
				LOG.debug("[pick] direct-code candidates=%d", #list)
				if #list > 0 then return list[rng:NextInteger(1, #list)], "direct-code" end
			end
			-- 2) pool by UID
			if poolUidSet then
				local cand = {}
				for _, e in ipairs(entries) do
					if e and e.uid and poolUidSet[e.uid] and monthHasKind(monthFromCard(e), "ribbon") then
						cand[#cand+1] = e
					end
				end
				LOG.debug("[pick] pool-uid candidates=%d", #cand)
				if #cand > 0 then return cand[rng:NextInteger(1, #cand)], "pool-uid" end
			end
			-- 3) pool by code
			if poolCodeSet then
				local cand = {}
				for _, e in ipairs(entries) do
					if e and e.code and poolCodeSet[e.code] and monthHasKind(monthFromCard(e), "ribbon") then
						cand[#cand+1] = e
					end
				end
				LOG.debug("[pick] pool-code candidates=%d", #cand)
				if #cand > 0 then return cand[rng:NextInteger(1, #cand)], "pool-code" end
			end
			-- 4) any entry whose month has "ribbon"
			local all = {}
			for _, e in ipairs(entries) do
				if monthHasKind(monthFromCard(e), "ribbon") then all[#all+1] = e end
			end
			LOG.debug("[pick] any-ribbon-month candidates=%d", #all)
			if #all > 0 then return all[rng:NextInteger(1, #all)], "any-ribbon-month" end
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

			-- If already tagged, skip (idempotent)
			if alreadyTagged(target) then
				LOG.info("[result] already-applied uid=%s code=%s (via=%s)", tostring(target.uid), tostring(target.code), tostring(reason))
				return store, { ok = true, changed = 0, meta = "already-applied", targetUid = target.uid, targetCode = target.code, pickReason = reason }
			end

			-- Convert to "ribbon"（同月の ribbon に idx を寄せる）
			local beforeIdx, beforeCode, beforeKind = target.idx, target.code, target.kind
			local next1 = ctx.DeckOps.convertKind(target, preferKind)
			local afterIdx, afterCode, afterKind = next1.idx, next1.code, next1.kind
			LOG.debug("[convert] idx:%s→%s code:%s→%s kind:%s→%s",
				tostring(beforeIdx), tostring(afterIdx),
				tostring(beforeCode), tostring(afterCode),
				tostring(beforeKind), tostring(afterKind))

			if tostring(afterKind or "") ~= "ribbon" then
				LOG.info("[result] month-has-no-ribbon uid=%s code=%s (via=%s)", tostring(target.uid), tostring(target.code), tostring(reason))
				return store, { ok = true, changed = 0, meta = "month-has-no-ribbon", targetUid = target.uid, targetCode = target.code, pickReason = reason }
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
			LOG.info("[result] ok changed=1 uid=%s code=%s via=%s in %.2fms",
				tostring(target.uid), tostring(target.code), tostring(reason), dt)
			return store, {
				ok         = true,
				changed    = 1,
				targetUid  = target.uid,
				targetCode = target.code,
				pickReason = reason,
			}
		end)
	end

	--─────────────────────────────────────────────────────
	-- canApply（UIグレーアウト等に利用） DOT-ONLY
	--  - 条件: まだ "ribbon" でない ＆ 対象月に ribbon 定義がある ＆ 既タグなし
	--─────────────────────────────────────────────────────
	local function registerCanApplyDot(id)
		Effects.registerCanApply(id, function(card, ctx2)
			if type(card) ~= "table" then return false, "not-eligible" end
			local tags = (type(card.tags)=="table") and card.tags or {}
			for _,t in ipairs(tags) do if t=="eff:kito.usagi_ribbon" then return false, "already-applied" end end
			if tostring(card.kind) == "ribbon" then return false, "already-ribbon" end

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
			if type(defs)~="table" then return false, "month-has-no-ribbon" end
			for _,d in ipairs(defs) do
				if tostring(d.kind)=="ribbon" then return true end
			end
			return false, "month-has-no-ribbon"
		end)
	end

	-- ★ DOT-ONLY 登録（レガシー別名は登録しない）
	Effects.register("kito.usagi_ribbon", handler)
	registerCanApplyDot("kito.usagi_ribbon")
end
