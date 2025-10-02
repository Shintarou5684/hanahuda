-- ReplicatedStorage/SharedModules/Deck/Effects/kito/Tatsu_Copy.lua
-- 辰（DOT-ONLY）：選んだ1枚を **完全複製** し、新規UIDを割当てて、デッキ内の最弱候補（chaff優先）を **上書き**
--  - Effect ID: "kito.tatsu_copy"（DOT-ONLY）
--  - 対象選択: payload.uid / payload.uids / payload.poolUids / payload.codes（UID優先）
--  - 宛先は自動選定（sourceと同一UIDは除外）: chaff > ribbon/seed > bright
--  - DeckStore は不変扱い。置換は transact 内で **UIDごと置換**（＝新規UIDを反映）
--  - 既タグ "eff:kito.tatsu_copy" の **宛先** は no-op（冪等）
--  - 「酒」など拡張フィールドも **deep clone** で丸ごと引き継ぐ
--  - Diagnostic logs（scope: Effects.kito.tatsu_copy）

return function(Effects)
	--─────────────────────────────────────────────────────
	-- Imports / Logger
	--─────────────────────────────────────────────────────
	local RS      = game:GetService("ReplicatedStorage")
	local Shared  = RS:WaitForChild("SharedModules")

	local LOG do
		local ok, Logger = pcall(function()
			return require(Shared:WaitForChild("Logger"))
		end)
		if ok and Logger and type(Logger.scope) == "function" then
			LOG = Logger.scope("Effects.kito.tatsu_copy")
		else
			LOG = { info=function(...) end, debug=function(...) end, warn=function(...) warn(string.format(...)) end }
		end
	end

	--─────────────────────────────────────────────────────
	-- Handler
	--─────────────────────────────────────────────────────
	local function handler(ctx)
		local payload   = ctx.payload or {}
		local runId     = ctx.runId
		local rng       = ctx.rng or Random.new()

		local TAG       = "eff:kito.tatsu_copy"

		-- 受け取り（UID優先）
		local uid       = (typeof(payload.uid) == "string" and payload.uid) or nil
		local uids      = (typeof(payload.uids) == "table"  and payload.uids) or nil
		local poolUids  = (typeof(payload.poolUids) == "table" and payload.poolUids) or nil
		local codes     = (typeof(payload.codes) == "table" and payload.codes) or nil
		local poolCodes = (typeof(payload.poolCodes) == "table" and payload.poolCodes) or nil

		-- ログヘッダ
		local function head5(list)
			if typeof(list) ~= "table" then return "-" end
			local out, n = {}, math.min(#list, 5)
			for i = 1, n do out[i] = tostring(list[i]) end
			return table.concat(out, ",")
		end

		LOG.debug("[deps] DeckStore=%s DeckOps=%s CardEngine=%s",
			tostring(ctx.DeckStore ~= nil), tostring(ctx.DeckOps ~= nil), tostring(ctx.CardEngine ~= nil))
		LOG.info("[begin] run=%s | uid=%s uids[%s]=[%s] poolUids[%s]=[%s] codes[%s]=[%s] poolCodes[%s]=[%s]",
			tostring(runId), tostring(uid),
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

		local function alreadyTagged(card)
			if typeof(card) ~= "table" or typeof(card.tags) ~= "table" then return false end
			for _, t in ipairs(card.tags) do if t == TAG then return true end end
			return false
		end

		local function deepcopy(tbl, seen)
			if typeof(tbl) ~= "table" then return tbl end
			seen = seen or {}
			if seen[tbl] then return seen[tbl] end
			local out = {}
			seen[tbl] = out
			for k, v in pairs(tbl) do
				out[deepcopy(k, seen)] = deepcopy(v, seen)
			end
			return out
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

		-- UID prefix 推定（code 優先、無ければ month/idx から作成）
		local function codePrefixOf(entry)
			local code = tostring(entry.code or "")
			if code ~= "" then return code end
			local mm = tonumber(entry.month); local ii = tonumber(entry.idx)
			if typeof(mm)=="number" and typeof(ii)=="number" then
				return string.format("%02d%02d", mm, ii)
			end
			return "0000"
		end

		-- 既存UIDを走査して "CODE#NNN" の NNN の最大値+1 を採番
		local function allocNewUid(store, sourceEntry)
			local prefix = codePrefixOf(sourceEntry)
			local maxN = 0
			local entries = (store and store.entries) or {}
			for _, e in ipairs(entries) do
				local uid0 = tostring(e.uid or "")
				if string.sub(uid0, 1, #prefix + 1) == (prefix .. "#") then
					local suffix = tonumber(string.sub(uid0, #prefix + 2)) or 0
					if suffix > maxN then maxN = suffix end
				end
			end
			local nextN = math.clamp(maxN + 1, 1, 9999)
			return string.format("%s#%03d", prefix, nextN)
		end

		-- UID で1件置換（※ここで **新規UID** を反映させる）
		local function replaceOneByUidWithNew(store, oldUid, newEntryWithNewUid)
			local entries = (store and store.entries) or {}
			local n = #entries; if n == 0 then return store end
			local out = table.create(n)
			local done = false
			for i = 1, n do
				local e = entries[i]
				if (not done) and e and e.uid == oldUid then
					local c = deepcopy(newEntryWithNewUid or {})
					-- newEntry 側の uid/code/month/idx を **優先採用**（＝完全置換）
					out[i]  = c
					done    = true
				else
					out[i] = e
				end
			end
			if done then
				LOG.debug("[replaceByUid(new)] old=%s -> %s", tostring(oldUid), cardStr(newEntryWithNewUid))
			else
				LOG.warn("[replaceByUid(new)] uid=%s not found (no-op)", tostring(oldUid))
			end
			return { v = 3, entries = out }
		end

		-- code で1件置換（フォールバック／新UIDで上書き）
		local function replaceOneByCodeWithNew(store, codeX, newEntryWithNewUid)
			local entries = (store and store.entries) or {}
			local n = #entries; if n == 0 then return store end
			local out = table.create(n)
			local done = false
			for i = 1, n do
				local e = entries[i]
				if (not done) and e and e.code == codeX then
					local c = deepcopy(newEntryWithNewUid or {})
					out[i]  = c
					done    = true
				else
					out[i] = e
				end
			end
			if done then
				LOG.debug("[replaceByCode(new)] code=%s -> %s", tostring(codeX), cardStr(newEntryWithNewUid))
			else
				LOG.warn("[replaceByCode(new)] code=%s not found (no-op)", tostring(codeX))
			end
			return { v = 3, entries = out }
		end

		-- 対象（コピー元）
		local function pickSource(store)
			local entries = (store and store.entries) or {}
			if #entries == 0 then return nil, "empty-store" end

			-- 0) direct uid
			if uid and uid ~= "" then
				for _, e in ipairs(entries) do
					if e and e.uid == uid then return e, "direct-uid" end
				end
			end
			-- 1) uids set
			if uidSet then
				local cand = {}
				for _, e in ipairs(entries) do
					if e and e.uid and uidSet[e.uid] then cand[#cand+1] = e end
				end
				if #cand > 0 then return cand[rng:NextInteger(1, #cand)], "uids" end
			end
			-- 2) poolUids set
			if poolUidSet then
				local cand = {}
				for _, e in ipairs(entries) do
					if e and e.uid and poolUidSet[e.uid] then cand[#cand+1] = e end
				end
				if #cand > 0 then return cand[rng:NextInteger(1, #cand)], "poolUids" end
			end
			-- 3) codes set
			if codeSet then
				local cand = {}
				for _, e in ipairs(entries) do
					if e and e.code and codeSet[e.code] then cand[#cand+1] = e end
				end
				if #cand > 0 then return cand[rng:NextInteger(1, #cand)], "codes" end
			end
			-- 4) poolCodes set
			if poolCodeSet then
				local cand = {}
				for _, e in ipairs(entries) do
					if e and e.code and poolCodeSet[e.code] then cand[#cand+1] = e end
				end
				if #cand > 0 then return cand[rng:NextInteger(1, #cand)], "poolCodes" end
			end
			return nil, "no-candidate"
		end

		-- 宛先（最弱候補）を自動選定：chaff(1) < ribbon/seed(2) < bright(3)
		local function pickDestWeakest(store, sourceUid)
			local entries = (store and store.entries) or {}
			if #entries == 0 then return nil end
			local function prioOf(e)
				local k = tostring(e.kind or "")
				if k == "chaff" then return 1 end
				if k == "ribbon" or k == "seed" then return 2 end
				return 3
			end
			local best, bestP = nil, math.huge
			for _, e in ipairs(entries) do
				if e and e.uid ~= sourceUid then
					local p = prioOf(e)
					if p < bestP then best, bestP = e, p end
				end
			end
			return best
		end

		--─────────────────────────────────────────────────────
		-- Main（DeckStore.transact）
		--─────────────────────────────────────────────────────
		local t0 = os.clock()
		LOG.debug("[transact] run=%s enter", tostring(runId))

		return ctx.DeckStore.transact(runId, function(store)
			local storeSize = (store and store.entries and #store.entries) or 0
			LOG.debug("[store] size=%s", tostring(storeSize))

			-- 1) コピー元
			local source, via = pickSource(store)
			if not source then
				LOG.info("[result] no-source (via=%s)", tostring(via))
				return store, { ok = true, changed = 0, meta = "no-source", pickReason = via }
			end
			LOG.debug("[source] via=%s %s", tostring(via), cardStr(source))

			-- 2) 宛先（弱い候補）
			local dest = pickDestWeakest(store, source.uid)
			if not dest then
				LOG.info("[result] no-dest (store empty or single)")
				return store, { ok = true, changed = 0, meta = "no-dest" }
			end
			LOG.debug("[dest] %s", cardStr(dest))

			if alreadyTagged(dest) then
				LOG.info("[result] dest-already-applied uid=%s code=%s", tostring(dest.uid), tostring(dest.code))
				return store, { ok = true, changed = 0, meta = "already-applied", targetUid = dest.uid, targetCode = dest.code }
			end

			-- 3) 完全複製：source を deep clone（uid は付け替える）
			local copyAll = deepcopy(source)
			copyAll.uid = allocNewUid(store, source)   -- ★ 新規UIDを採番
			-- tags は複製のうえ、今回のTAGを付与（DeckOps.attachTag があればそれを使う）
			if ctx.DeckOps and ctx.DeckOps.attachTag then
				copyAll = ctx.DeckOps.attachTag(copyAll, TAG)
			else
				copyAll.tags = typeof(copyAll.tags)=="table" and copyAll.tags or {}
				table.insert(copyAll.tags, TAG)
			end

			LOG.debug("[copy(new-uid)] %s", cardStr(copyAll))

			-- 4) 置換：宛先スロットを **copyAll（新UID）** で上書き（＝サイズは不変）
			if dest.uid and dest.uid ~= "" then
				store = replaceOneByUidWithNew(store, dest.uid, copyAll)
			else
				store = replaceOneByCodeWithNew(store, dest.code, copyAll)
			end

			local dt = (os.clock() - t0) * 1000
			LOG.info("[result] ok changed=1 sourceUid=%s newUid=%s destWas=%s via=%s in %.2fms",
				tostring(source.uid), tostring(copyAll.uid), tostring(dest.uid), tostring(via), dt)

			return store, {
				ok         = true,
				changed    = 1,
				meta       = { duplicatedFrom = source.code, newUid = copyAll.uid, replacedUid = dest.uid },
				sourceUid  = source.uid,  sourceCode = source.code,
				targetUid  = copyAll.uid, targetCode = copyAll.code,
				pickReason = via,
			}
		end)
	end

	--─────────────────────────────────────────────────────
	-- canApply（UIグレーアウト等用 / DOT-ONLY）
	--  - 条件: 宛先が既タグでない（※source 側は不問）
	--─────────────────────────────────────────────────────
	local function registerCanApplyDot(id)
		Effects.registerCanApply(id, function(card, _ctx2)
			if type(card) ~= "table" then return false, "not-eligible" end
			local tags = (type(card.tags)=="table") and card.tags or {}
			for _,t in ipairs(tags) do if t == "eff:kito.tatsu_copy" then return false, "already-applied" end end
			return true
		end)
	end

	-- 登録（DOT-ONLY）
	Effects.register("kito.tatsu_copy", handler)
	registerCanApplyDot("kito.tatsu_copy")
end
