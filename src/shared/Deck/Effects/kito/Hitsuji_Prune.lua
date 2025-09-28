-- ReplicatedStorage/SharedModules/Deck/Effects/kito/Hitsuji_Prune.lua
-- Sheep (KITO): prune one target card from the deck (UID-first)
--  - Effect IDs: "kito.hitsuji_prune" (primary), "kito_hitsuji" (legacy alias)
--  - Target selection order: payload.uid / payload.uids / payload.poolUids / payload.codes / payload.poolCodes
--  - DeckStore (v3) is immutable; use DeckStore.transact to return a new store
--  - No random fallback removal if no target is provided (safety-first)
--  - Diagnostic logs (scope: Effects.kito.hitsuji_prune)

return function(Effects)
	-- Logger (optional)
	local LOG do
		local ok, Logger = pcall(function()
			return require(game:GetService("ReplicatedStorage")
				:WaitForChild("SharedModules")
				:WaitForChild("Logger"))
		end)
		if ok and Logger and type(Logger.scope) == "function" then
			LOG = Logger.scope("Effects.kito.hitsuji_prune")
		else
			LOG = { info=function(...) end, debug=function(...) end, warn=function(...) warn(string.format(...)) end }
		end
	end

	-- canApply（現状は常に許可。将来ロック等を導入するならここで判定）
	local function canApply(_card:any, _ctx:any)
		return true, nil
	end

	local function handler(ctx)
		local payload   = ctx.payload or {}
		local uidScalar = (typeof(payload.uid)  == "string" and payload.uid)  or nil
		local uids      = (typeof(payload.uids) == "table"  and payload.uids) or nil
		local poolUids  = (typeof(payload.poolUids) == "table" and payload.poolUids) or nil
		local codes     = (typeof(payload.codes) == "table" and payload.codes) or nil -- legacy compat
		local poolCodes = (typeof(payload.poolCodes) == "table" and payload.poolCodes) or nil -- legacy compat
		local tagMark   = tostring(payload.tag or "eff:kito_hitsuji_prune")
		local runId     = ctx.runId

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

		local function listToSet(list)
			if typeof(list) ~= "table" then return nil end
			local s = {}
			for _, v in ipairs(list) do s[v] = true end
			return s
		end

		local uidSet      = listToSet(uids) or {}
		if uidScalar then uidSet[uidScalar] = true end
		local poolUidSet  = listToSet(poolUids)
		local codeSet     = listToSet(codes)
		local poolCodeSet = listToSet(poolCodes)

		-- pick target（無指定なら削除しない＝安全運用）
		local function pickTarget(store)
			local entries = (store and store.entries) or {}
			-- 0) direct UID(s)
			if uidSet and next(uidSet) ~= nil then
				for _, e in ipairs(entries) do if e and e.uid and uidSet[e.uid] then return e, "direct-uid" end end
			end
			-- 1) direct code(s)
			if codeSet and next(codeSet) ~= nil then
				for _, e in ipairs(entries) do if e and e.code and codeSet[e.code] then return e, "direct-code" end end
			end
			-- 2) pool by UID
			if poolUidSet and next(poolUidSet) ~= nil then
				for _, e in ipairs(entries) do if e and e.uid and poolUidSet[e.uid] then return e, "pool-uid" end end
			end
			-- 3) pool by code
			if poolCodeSet and next(poolCodeSet) ~= nil then
				for _, e in ipairs(entries) do if e and e.code and poolCodeSet[e.code] then return e, "pool-code" end end
			end
			return nil, "no-target"
		end

		local function storeSize(store) return (store and store.entries and #store.entries) or 0 end

		local function removeByUidImmutable(store, uid)
			local entries = (store and store.entries) or {}
			local n = #entries
			if n == 0 then return store, nil end
			local out, removed = table.create(n), nil
			for i = 1, n do
				local e = entries[i]
				if (not removed) and e and e.uid == uid then
					removed = e -- skip copy
				else
					out[#out+1] = e
				end
			end
			return removed and { v = 3, entries = out } or store, removed
		end

		local function removeByCodeImmutable(store, code)
			local entries = (store and store.entries) or {}
			local n = #entries
			if n == 0 then return store, nil end
			local out, removed = table.create(n), nil
			for i = 1, n do
				local e = entries[i]
				if (not removed) and e and e.code == code then
					removed = e
				else
					out[#out+1] = e
				end
			end
			return removed and { v = 3, entries = out } or store, removed
		end

		local t0 = os.clock()
		LOG.debug("[transact] run=%s enter", tostring(runId))
		return ctx.DeckStore.transact(runId, function(store)
			LOG.debug("[store] size=%s", tostring(storeSize(store)))

			local target, reason = pickTarget(store)
			if not target then
				LOG.info("[result] no-target (pickReason=%s)", tostring(reason))
				return store, { ok = true, changed = 0, meta = "no-target", pickReason = reason }
			end

			LOG.debug("[target] via=%s {uid=%s code=%s kind=%s month=%s idx=%s}",
				tostring(reason), tostring(target.uid), tostring(target.code),
				tostring(target.kind), tostring(target.month), tostring(target.idx))

			-- remove（UID優先、なければcode）
			local nextStore, removed
			if target.uid and target.uid ~= "" then
				nextStore, removed = removeByUidImmutable(store, target.uid)
			else
				nextStore, removed = removeByCodeImmutable(store, target.code)
			end

			if not removed then
				LOG.warn("[remove] not-found (no-op) uid=%s code=%s", tostring(target.uid), tostring(target.code))
				return store, { ok = true, changed = 0, meta = "not-found", targetUid = target.uid, targetCode = target.code, pickReason = reason }
			end

			local dt = (os.clock() - t0) * 1000
			LOG.info("[result] ok changed=1 uid=%s code=%s via=%s in %.2fms",
				tostring(removed.uid), tostring(removed.code), tostring(reason), dt)
			return nextStore, {
				ok         = true,
				changed    = 1,
				targetUid  = removed.uid,
				targetCode = removed.code,
				pickReason = reason,
				tag        = tagMark,
			}
		end)
	end

	-- 登録（本体＋canApply）
	Effects.register("kito.hitsuji_prune", handler)
	Effects.register("kito_hitsuji",      handler) -- legacy
	Effects.registerCanApply("kito.hitsuji_prune", canApply)
	Effects.registerCanApply("kito_hitsuji",      canApply)
end
