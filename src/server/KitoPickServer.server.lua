-- ServerScriptService/KitoPickServer.lua
-- v0.9.10 KITO Pick Server (+diag logs, safe reopen with state, no reroll)
-- 変更点:
--   - reopenShopSnapshot: ShopService の想定シグネチャに合わせ state を第2引数へ
--   - open/openFor の複数シグネチャを順に試すフォールバック実装
--   - それ以外は前版踏襲（効果適用→pushState→在庫を維持したままOPEN再送）

local RS  = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

-- Logger / Config
local Logger  = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG     = Logger.scope("KitoPickServer")
local Balance = require(RS:WaitForChild("Config"):WaitForChild("Balance"))

-- Core / Registry / State
local Shared       = RS:WaitForChild("SharedModules")
local KitoCore     = require(SSS:WaitForChild("KitoPickCore"))
local DeckRegistry = require(Shared:WaitForChild("Deck"):WaitForChild("DeckRegistry"))
local StateHub     = require(Shared:WaitForChild("StateHub"))

-- Remotes
local Remotes  = RS:WaitForChild("Remotes")
local EvDecide = Remotes:WaitForChild("KitoPickDecide")
local EvCancel = Remotes:FindFirstChild("KitoPickCancel")
local EvResult = Remotes:FindFirstChild("KitoPickResult") -- 任意/トースト用

-- ─────────────────────────────────────────────────────────────
-- Utility: safe require
-- ─────────────────────────────────────────────────────────────
local function tryRequire(inst: Instance?)
	if not inst or not inst:IsA("ModuleScript") then return nil end
	local ok, mod = pcall(function() return require(inst) end)
	if ok then return mod end
	LOG.warn("[KitoPickServer] require failed: %s", tostring(mod))
	return nil
end

-- ─────────────────────────────────────────────────────────────
-- EffectsRegistry 読み込み（正しい配置を優先）
-- ─────────────────────────────────────────────────────────────
local EffectsRegistry =
	tryRequire(Shared:FindFirstChild("Deck") and Shared.Deck:FindFirstChild("EffectsRegistry"))
	or tryRequire(Shared:FindFirstChild("EffectsRegistry"))
	or tryRequire(SSS:FindFirstChild("EffectsRegistry"))

if EffectsRegistry then
	LOG.info("[KitoPickServer] EffectsRegistry wired (module loaded)")
else
	LOG.warn("[KitoPickServer] EffectsRegistry not found; brighten effect will be unavailable (server continues)")
end

-- ─────────────────────────────────────────────────────────────
-- ShopService 解決（非ブロッキング探索）
-- ─────────────────────────────────────────────────────────────
local function resolveShopService()
	local inst =
		SSS:FindFirstChild("ShopService")
		or (Shared:FindFirstChild("Shop") and Shared.Shop:FindFirstChild("ShopService"))
		or Shared:FindFirstChild("ShopService")
		or RS:FindFirstChild("ShopService")
		or (RS:FindFirstChild("SharedModules") and RS.SharedModules:FindFirstChild("ShopService"))

	local mod = tryRequire(inst)
	if mod then
		LOG.info("[KitoPickServer] ShopService wired from %s", inst:GetFullName())
	else
		LOG.warn("[KitoPickServer] ShopService not found (no ModuleScript found); reopen will be skipped")
	end
	return mod
end

local ShopService = resolveShopService()

-- ─────────────────────────────────────────────────────────────
-- runId 解決（KitoPickCore と同一規則）
-- ─────────────────────────────────────────────────────────────
local function resolveRunId(ctx:any)
	if type(ctx) ~= "table" then return nil end
	if ctx.runId then return ctx.runId end
	if ctx.deckRunId then return ctx.deckRunId end
	if ctx.id then return ctx.id end
	if ctx.runID then return ctx.runID end
	if ctx.deckRunID then return ctx.deckRunID end
	local run = ctx.run
	if type(run) == "table" then
		return run.runId or run.deckRunId or run.id or run.runID or run.deckRunID
	end
	return nil
end

-- 効果結果のゆるい解釈
local function interpretApplyResult(r1, r2)
	if type(r1) == "boolean" then
		return r1, nil, r2
	elseif type(r1) == "table" then
		local ok = (r1.ok == nil) and true or (r1.ok ~= false)
		return ok, r1.changed, r1.message or r1.meta or r1.reason or r2
	else
		return (r1 ~= nil), nil, r2
	end
end

-- ─────────────────────────────────────────────────────────────
-- 効果適用（IDフォールバック）
-- ─────────────────────────────────────────────────────────────
local PRIMARY_ID   = "kito.tori_brighten"
local FALLBACK_ID  = "Tori_Brighten"

local function applyBrighten(runId:string?, payload:any)
	if not EffectsRegistry or type(EffectsRegistry.apply) ~= "function" then
		return false, nil, "effects-registry-missing", nil
	end
	if not runId or runId == "" then
		return false, nil, "runId-missing", nil
	end

	-- primary
	LOG.debug("[Decide] call apply order=(runId,effectId,payload) id=%s run=%s", PRIMARY_ID, tostring(runId))
	local okCall, r1, r2 = pcall(function()
		return EffectsRegistry.apply(runId, PRIMARY_ID, payload)
	end)
	if not okCall then
		LOG.warn("[Decide] apply threw (primary %s): %s", PRIMARY_ID, tostring(r1))
	else
		local success, changed, message = interpretApplyResult(r1, r2)
		LOG.debug("[Decide] apply(primary) types r1=%s r2=%s → ok=%s ch=%s msg=%s",
			typeof(r1), typeof(r2), tostring(success), tostring(changed), tostring(message))
		if success then return true, changed, message, PRIMARY_ID end
	end

	-- fallback
	LOG.debug("[Decide] retry apply with fallback id=%s run=%s", FALLBACK_ID, tostring(runId))
	local okCall2, r3, r4 = pcall(function()
		return EffectsRegistry.apply(runId, FALLBACK_ID, payload)
	end)
	if not okCall2 then
		LOG.warn("[Decide] apply threw (fallback %s): %s", FALLBACK_ID, tostring(r3))
		return false, nil, tostring(r3), FALLBACK_ID
	end
	local success2, changed2, message2 = interpretApplyResult(r3, r4)
	LOG.debug("[Decide] apply(fallback) types r1=%s r2=%s → ok=%s ch=%s msg=%s",
		typeof(r3), typeof(r4), tostring(success2), tostring(changed2), tostring(message2))
	return success2, changed2, message2, FALLBACK_ID
end

-- ─────────────────────────────────────────────────────────────
-- ショップを「在庫維持で開き直す」
--   - ShopService の実装差に合わせて複数シグネチャを順に試す
-- ─────────────────────────────────────────────────────────────
local function reopenShopSnapshot(plr: Player, opts:any?)
	if not ShopService then
		LOG.warn("[ReopenShop] ShopService missing; skip")
		return false, "no-shopservice"
	end

	local state = StateHub.get(plr) or {}
	local notice = opts and opts.notice or "変換が完了しました"
	local preserve = true

	local tried = {}

	local function tryCall(desc, f)
		local t0 = os.clock()
		local ok, err = pcall(f)
		table.insert(tried, { desc = desc, ok = ok, err = ok and "" or tostring(err), ms = (os.clock()-t0)*1000 })
		return ok, err
	end

	-- 優先1: openFor(plr, state, {notice=..., preserve=true})
	if type(ShopService.openFor) == "function" then
		local ok = select(1, tryCall("openFor(plr, state, opts)", function()
			return ShopService.openFor(plr, state, { notice = notice, preserve = preserve, reason = "kito_pick_done" })
		end))
		if ok then
			LOG.info("[ReopenShop] via openFor(plr,state,opts) in %.2fms", tried[#tried].ms)
			return true
		end
		-- フォールバック: openFor(plr, { state=..., notice=..., preserve=true })
		local ok2 = select(1, tryCall("openFor(plr, {state=...,notice=...})", function()
			return ShopService.openFor(plr, { state = state, notice = notice, preserve = preserve, reason = "kito_pick_done" })
		end))
		if ok2 then
			LOG.info("[ReopenShop] via openFor(plr,{state,...}) in %.2fms", tried[#tried].ms)
			return true
		end
	end

	-- 優先2: open(plr, state, {notice=..., preserve=true})
	if type(ShopService.open) == "function" then
		local ok3 = select(1, tryCall("open(plr, state, opts)", function()
			return ShopService.open(plr, state, { notice = notice, preserve = preserve, reason = "kito_pick_done" })
		end))
		if ok3 then
			LOG.info("[ReopenShop] via open(plr,state,opts) in %.2fms", tried[#tried].ms)
			return true
		end
		-- フォールバック: open(plr, { state=..., notice=..., preserve=true })
		local ok4 = select(1, tryCall("open(plr, {state=...,notice=...})", function()
			return ShopService.open(plr, { state = state, notice = notice, preserve = preserve, reason = "kito_pick_done" })
		end))
		if ok4 then
			LOG.info("[ReopenShop] via open(plr,{state,...}) in %.2fms", tried[#tried].ms)
			return true
		end
	end

	-- すべて失敗：詳細をまとめて WARN
	for _, t in ipairs(tried) do
		if not t.ok then
			LOG.warn("[ReopenShop] tried %s → failed: %s (%.2fms)", t.desc, t.err, t.ms)
		end
	end
	return false, "no-matching-signature"
end

-- ─────────────────────────────────────────────────────────────
-- Decide（確定）
-- payload: { sessionId:string, uid:string, noChange?:boolean }
-- ─────────────────────────────────────────────────────────────
local PRIMARY_NOTICE_SKIP = "選択をスキップしました"
local PRIMARY_NOTICE_DONE = "変換が完了しました"

local function onDecide(plr: Player, payload:any)
	if Balance.KITO_UI_ENABLED ~= true then return end

	local uid      = payload and payload.uid
	local sidRecv  = payload and payload.sessionId
	local noChange = (payload and payload.noChange) == true

	-- 受信要約ログ
	LOG.info("[Decide] recv u=%s sid=%s uid=%s noChange=%s",
		plr and plr.Name or "?", tostring(sidRecv), tostring(uid), tostring(noChange))

	-- 1) セッション消費（1回限り）
	local sess = KitoCore.consume(plr.UserId)
	if not sess or (sidRecv and sess.id ~= sidRecv) then
		LOG.info("[Decide] invalid session | u=%s gotSid=%s holdSid=%s",
			plr and plr.Name or "?", tostring(sidRecv), sess and tostring(sess.id) or "-")
		if EvResult then EvResult:FireClient(plr, { ok=false, reason="session" }) end
		return
	end
	LOG.debug("[Decide] session ok sid=%s ttl=%s run?=%s",
		tostring(sess.id), tostring(sess.expiresAt), tostring(sess.runId or "-"))

	-- 2) TTL
	local now = os.time()
	if type(sess.expiresAt) == "number" and now > (sess.expiresAt or 0) then
		LOG.info("[Decide] expired | u=%s sid=%s now=%d exp=%d",
			plr and plr.Name or "?", tostring(sess.id), now, sess.expiresAt or -1)
		if EvResult then EvResult:FireClient(plr, { ok=false, reason="expired" }) end
		return
	end

	-- 3) 候補内チェック（noChange ならスキップ可）
	local okUid = false
	if type(uid) == "string" and type(sess.uids) == "table" then
		for _, u in ipairs(sess.uids) do if u == uid then okUid = true; break end end
	end
	if (not okUid) and (not noChange) then
		LOG.info("[Decide] uid not in session | u=%s sid=%s uid=%s", plr and plr.Name or "?", tostring(sess.id), tostring(uid))
		if EvResult then EvResult:FireClient(plr, { ok=false, reason="uid" }) end
		return
	end

	-- 4) state/runId/DeckRegistry 準備
	local s = StateHub.get(plr)
	if not s then
		LOG.warn("[Decide] state missing | u=%s", plr and plr.Name or "?")
		if EvResult then EvResult:FireClient(plr, { ok=false, reason="state" }) end
		return
	end
	local runId = resolveRunId(s) or resolveRunId(s.run)
	DeckRegistry.ensureFromContext(s) -- 必要時のみ snap→registry 反映
	LOG.debug("[Decide] runId=%s", tostring(runId))

	-- runId 未解決なら明確に終了
	if not runId or runId == "" then
		LOG.warn("[Decide] runId missing | u=%s", plr and plr.Name or "?")
		if EvResult then EvResult:FireClient(plr, { ok=false, reason="run" }) end
		return
	end

	-- 5) noChange: 変換せず終了 → ショップ開き直し
	if noChange == true then
		LOG.info("[Decide] noChange | u=%s sid=%s", plr and plr.Name or "?", tostring(sess.id))
		reopenShopSnapshot(plr, { notice = PRIMARY_NOTICE_SKIP })
		if EvResult then EvResult:FireClient(plr, { ok=true, changed=false, uid=nil }) end
		return
	end

	-- 6) 効果適用（UIDファースト + 後方互換 codes 同値）
	if not EffectsRegistry or type(EffectsRegistry.apply) ~= "function" then
		LOG.warn("[Decide] EffectsRegistry unavailable; cannot apply brighten | u=%s", plr and plr.Name or "?")
		if EvResult then EvResult:FireClient(plr, { ok=false, reason="effects" }) end
		return
	end

	local function isUidLike(sv:any)
		local s = (type(sv) == "string") and sv or nil
		return s and (string.find(s, "#%d+$") ~= nil) or false
	end
	if payload and type(payload.codes) == "table" and #payload.codes > 0 then
		for i, c in ipairs(payload.codes) do
			if isUidLike(c) then
				LOG.warn("[Decide] payload.codes[%d] looks like UID (%s). legacy fallback may miss.", i, tostring(c))
				break
			end
		end
	end

	local applyPayload = {
		plr        = plr,
		runId      = runId,
		uids       = (uid and { tostring(uid) } or nil),
		codes      = (uid and { tostring(uid) } or nil), -- 後方互換のため現状維持
		preferKind = "bright",
		tag        = "eff:kito_tori_bright",
		now        = os.time(),
		lang       = s.lang or "ja",
	}
	LOG.info("[Decide] apply start run=%s uid=%s uids#=%s codes#=%s",
		tostring(runId), tostring(uid),
		tostring(applyPayload.uids and #applyPayload.uids or 0),
		tostring(applyPayload.codes and #applyPayload.codes or 0)
	)

	local success, changed, message, usedId = applyBrighten(runId, applyPayload)

	if not success then
		LOG.info("[Decide] effect failed | id=%s msg=%s", tostring(usedId or PRIMARY_ID), tostring(message))
		if EvResult then
			local res = { ok=false, reason="effect", message=tostring(message), id=tostring(usedId or PRIMARY_ID) }
			EvResult:FireClient(plr, res)
			LOG.debug("[Result->C] %s", game.HttpService and game.HttpService:JSONEncode(res) or "sent")
		end
		return
	end

	-- 7) 状態同期
	local okPush, errPush = pcall(function() StateHub.pushState(plr) end)
	LOG.info("[Decide] pushState ok=%s err=%s", tostring(okPush), okPush and "" or tostring(errPush))

	-- 8) 在庫を「リロールせず」再送（OPEN）
	reopenShopSnapshot(plr, { notice = (message and tostring(message) ~= "" and tostring(message)) or PRIMARY_NOTICE_DONE })

	-- 9) 結果通知
	if EvResult then
		local res = {
			ok      = true,
			changed = (changed == nil) and true or (changed ~= 0 and changed ~= false),
			uid     = tostring(uid),
			message = tostring(message or ""),
			id      = tostring(usedId or PRIMARY_ID),
		}
		EvResult:FireClient(plr, res)
		LOG.debug("[Result->C] %s", game.HttpService and game.HttpService:JSONEncode(res) or "sent")
	end

	LOG.info("[Decide] OK | u=%s run=%s uid=%s id=%s msg=%s",
		plr and plr.Name or "?", tostring(runId), tostring(uid), tostring(usedId or PRIMARY_ID), tostring(message or ""))
end

-- ─────────────────────────────────────────────────────────────
-- Cancel（任意）
-- ─────────────────────────────────────────────────────────────
local function onCancel(plr: Player, _payload:any)
	KitoCore.consume(plr.UserId) -- セッションを無言破棄
	LOG.debug("[Cancel] u=%s", plr and plr.Name or "?")
	reopenShopSnapshot(plr, { notice = "取消しました" })
	if EvResult then EvResult:FireClient(plr, { ok=true, changed=false, cancel=true }) end
end

-- ─────────────────────────────────────────────────────────────
-- Wiring
-- ─────────────────────────────────────────────────────────────
local function wire()
	if EvDecide then EvDecide.OnServerEvent:Connect(onDecide) end
	if EvCancel then EvCancel.OnServerEvent:Connect(onCancel) end
	LOG.info("ready (handlers wiring)")
end
wire()
