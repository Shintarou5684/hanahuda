-- ReplicatedStorage/SharedModules/Deck/Effects/kito/Mi_Venom.lua
-- "巳（Venom）"：対象札をカス化し、所持文を即時加算する
--  - Effect ID: "kito.mi_venom"（必要なら別名を追加可能）
--  - 対象選択: payload.uid / payload.uids / payload.poolUids（UID優先）
--  - 既タグ "eff:kito_mi_venom" または kind=="chaff" は no-op
--  - DeckStore は不変扱い。置換は transact 内で UID-first（無ければ code）で行う
--  - 変更があった場合のみ res.meta.bankDelta = Balance.KITO_VENOM_CASH を返す
--  - ★ Diagnostic logs（scope: Effects.kito.mi_venom）

return function(Effects)
	--─────────────────────────────────────────────────────
	-- Imports / Logger
	--─────────────────────────────────────────────────────
	local RS = game:GetService("ReplicatedStorage")
	local Shared = RS:WaitForChild("SharedModules")

	local Balance = require(RS:WaitForChild("Config"):WaitForChild("Balance"))

	local LOG do
		local ok, Logger = pcall(function()
			return require(Shared:WaitForChild("Logger"))
		end)
		if ok and Logger and type(Logger.scope) == "function" then
			LOG = Logger.scope("Effects.kito.mi_venom")
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

		local tagMark   = "eff:kito_mi_venom"
		local cashDelta = tonumber(Balance.KITO_VENOM_CASH or 5) or 5

		-- 受け取り（UID優先）
		local uid       = (typeof(payload.uid) == "string" and payload.uid) or nil
		local uids      = (typeof(payload.uids) == "table" and payload.uids) or nil
		local poolUids  = (typeof(payload.poolUids) == "table" and payload.poolUids) or nil
		local codes     = (typeof(payload.codes) == "table" and payload.codes) or nil -- 互換

		-- ログヘッダ
		local function head5(list)
			if typeof(list) ~= "table" then return "-" end
			local out, n = {}, math.min(#list, 5)
			for i = 1, n do out[i] = tostring(list[i]) end
			return table.concat(out, ",")
		end

		LOG.debug("[deps] DeckStore=%s DeckOps=%s CardEngine=%s",
			tostring(ctx.DeckStore ~= nil), tostring(ctx.DeckOps ~= nil), tostring(ctx.CardEngine ~= nil))
		LOG.info("[begin] run=%s uid=%s | uids[%s]=[%s] poolUids[%s]=[%s] codes[%s]=[%s]",
			tostring(runId), tostring(uid),
			tostring(uids and #uids or 0), head5(uids),
			tostring(poolUids and #poolUids or 0), head5(poolUids),
			tostring(codes and #codes or 0), head5(codes)
		)

		-- 小道具
		local function listToSet(list)
			if typeof(list) ~= "table" then return nil end
			local s = {}
			for _, v in ipairs(list) do s[v] = true end
			return s
		end
		local uidSet     = listToSet(uids)
		local poolUidSet = listToSet(poolUids)
		local codeSet    = listToSet(codes)

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

		-- UID で1件置換
		local function replaceOneByUid(store, uidX, newEntry)
			local entries = (store and store.entries) or {}
			local n = #entries; if n == 0 then return store end
			local out = table.create(n)
			local done = false
			for i = 1, n do
				local e = entries[i]
				if (not done) and e and e.uid == uidX then
					local c = table.clone(newEntry or {})
					-- UIDは維持し、空欄は旧値で補完
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
				LOG.debug("[replaceByUid] uid=%s -> %s", tostring(uidX), cardStr(newEntry))
			else
				LOG.warn("[replaceByUid] uid=%s not found (no-op)", tostring(uidX))
			end
			return { v = 3, entries = out }
		end

		-- code で1件置換（レガシー）
		local function replaceOneByCode(store, codeX, newEntry)
			local entries = (store and store.entries) or {}
			local n = #entries; if n == 0 then return store end
			local out = table.create(n)
			local done = false
			for i = 1, n do
				local e = entries[i]
				if (not done) and e and e.code == codeX then
					local c = table.clone(newEntry or {})
					c.uid   = e.uid    -- 可能ならUID維持
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
				LOG.debug("[replaceByCode] code=%s -> %s", tostring(codeX), cardStr(newEntry))
			else
				LOG.warn("[replaceByCode] code=%s not found (no-op)", tostring(codeX))
			end
			return { v = 3, entries = out }
		end

		-- ターゲット選択（優先度: payload.uid → uids セット → poolUids セット → codes セット）
		local function pickTarget(store)
			local entries = (store and store.entries) or {}
			if #entries == 0 then return nil, "empty-store" end

			-- 0) direct uid
			if uid and uid ~= "" then
				for _, e in ipairs(entries) do
					if e and e.uid == uid then
						return e, "direct-uid"
					end
				end
			end

			-- 1) uids set
			if uidSet then
				local cand = {}
				for _, e in ipairs(entries) do
					if e and e.uid and uidSet[e.uid] then
						cand[#cand+1] = e
					end
				end
				if #cand > 0 then
					return cand[rng:NextInteger(1, #cand)], "uids"
				end
			end

			-- 2) poolUids set
			if poolUidSet then
				local cand = {}
				for _, e in ipairs(entries) do
					if e and e.uid and poolUidSet[e.uid] then
						cand[#cand+1] = e
					end
				end
				if #cand > 0 then
					return cand[rng:NextInteger(1, #cand)], "poolUids"
				end
			end

			-- 3) codes set（レガシー）
			if codeSet then
				local cand = {}
				for _, e in ipairs(entries) do
					if e and e.code and codeSet[e.code] then
						cand[#cand+1] = e
					end
				end
				if #cand > 0 then
					return cand[rng:NextInteger(1, #cand)], "codes"
				end
			end

			-- 4) 何も指定が無ければ no-op
			return nil, "no-candidate"
		end

		--─────────────────────────────────────────────────────
		-- Main（DeckStore.transact）
		--─────────────────────────────────────────────────────
		local t0 = os.clock()
		LOG.debug("[transact] run=%s enter", tostring(runId))

		return ctx.DeckStore.transact(runId, function(store)
			local storeSize = (store and store.entries and #store.entries) or 0
			LOG.debug("[store] size=%s", tostring(storeSize))

			local target, via = pickTarget(store)
			if not target then
				LOG.info("[result] no-target (via=%s)", tostring(via))
				return store, { ok = true, changed = 0, meta = "no-target", pickReason = via }
			end

			LOG.debug("[target] via=%s %s", tostring(via), cardStr(target))

			-- 既タグ or 既カス → no-op
			if alreadyTagged(target) then
				LOG.info("[result] already-applied uid=%s code=%s", tostring(target.uid), tostring(target.code))
				return store, { ok = true, changed = 0, meta = "already-applied", targetUid = target.uid, targetCode = target.code }
			end
			if tostring(target.kind or "") == "chaff" then
				LOG.info("[result] already-chaff uid=%s code=%s", tostring(target.uid), tostring(target.code))
				return store, { ok = true, changed = 0, meta = "already-chaff", targetUid = target.uid, targetCode = target.code }
			end

			-- 変換: chaff 化 → タグ付け
			local beforeKind, beforeCode = target.kind, target.code
			local next1 = ctx.DeckOps.convertKind(target, "chaff")
			local afterKind, afterCode = next1.kind, next1.code
			LOG.debug("[convert] code:%s→%s kind:%s→%s", tostring(beforeCode), tostring(afterCode), tostring(beforeKind), tostring(afterKind))

			local next2 = ctx.DeckOps.attachTag(next1, tagMark)
			if not next2.uid then next2.uid = target.uid end
			LOG.debug("[tagged] %s", cardStr(next2))

			-- 置換（UID優先）
			if target.uid and target.uid ~= "" then
				store = replaceOneByUid(store, target.uid, next2)
			else
				store = replaceOneByCode(store, target.code, next2)
			end

			local dt = (os.clock() - t0) * 1000
			LOG.info("[result] ok changed=1 uid=%s code=%s via=%s bank:+%d in %.2fms",
				tostring(target.uid), tostring(target.code), tostring(via), cashDelta, dt)

			return store, {
				ok      = true,
				changed = 1,
				meta    = { bankDelta = cashDelta },
				targetUid  = target.uid,
				targetCode = target.code,
				pickReason = via,
			}
		end)
	end

	-- 登録
	Effects.register("kito.mi_venom", handler)
	-- （必要なら）レガシー別名を追加：
	-- Effects.register("Mi_Venom", handler)
end
