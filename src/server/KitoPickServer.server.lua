-- ServerScriptService/KitoPickServer.lua
-- v0.9.16 KITO Pick Server
--  - server canApply + safe monDelta→mon + robust reopen + notice(+N文) + msg/bankDelta normalize
--  - ★ADD: UI経由の適用成功時に Kito.recordFromPick(...) を呼んで kito_last を記録（子 ko 再発火用）

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
local CardEngine   = require(Shared:WaitForChild("CardEngine"))

-- Remotes
local Remotes  = RS:WaitForChild("Remotes")
local EvDecide = Remotes:WaitForChild("KitoPickDecide")
local EvCancel = Remotes:FindFirstChild("KitoPickCancel")
local EvResult = Remotes:FindFirstChild("KitoPickResult") -- 任意/トースト用

-- ─ Utility: safe require
local function tryRequire(inst: Instance?)
	if not inst or not inst:IsA("ModuleScript") then return nil end
	local ok, modOrErr = pcall(function() return require(inst) end)
	if ok then return modOrErr end
	LOG.warn("[KitoPickServer] require failed for %s: %s", inst:GetFullName(), tostring(modOrErr))
	return nil
end

-- EffectsRegistry
local EffectsRegistry =
	tryRequire(Shared:FindFirstChild("Deck") and Shared.Deck:FindFirstChild("EffectsRegistry"))
	or tryRequire(Shared:FindFirstChild("EffectsRegistry"))
	or tryRequire(SSS:FindFirstChild("EffectsRegistry"))

local EffectsBootstrap = tryRequire(Shared:FindFirstChild("Deck") and Shared.Deck:FindFirstChild("EffectsRegisterAll"))

if EffectsRegistry then
	LOG.info("[KitoPickServer] EffectsRegistry wired")
else
	LOG.warn("[KitoPickServer] EffectsRegistry not found; KITO effects unavailable")
end

-- ★ Kito（kito_last 記録フック用）
local Kito = tryRequire(SSS:FindFirstChild("ShopEffects") and SSS.ShopEffects:FindFirstChild("Kito"))
		or tryRequire(SSS:FindFirstChild("Kito"))

-- ShopService 解決（複数シグネチャに対応）
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
		LOG.warn("[KitoPickServer] ShopService not found; reopen will be skipped")
	end
	return mod
end
local ShopService = resolveShopService()

-- runId 解決
local function resolveRunId(ctx:any)
	if type(ctx) ~= "table" then return nil end
	return ctx.runId or ctx.deckRunId or ctx.id or ctx.runID or ctx.deckRunID
		or (type(ctx.run)=="table" and (ctx.run.runId or ctx.run.deckRunId or ctx.run.id or ctx.run.runID or ctx.run.deckRunID))
end

-- ショップ再オープン（在庫維持）
local function reopenShopSnapshot(plr: Player, opts:any?)
	if not ShopService then
		LOG.warn("[ReopenShop] ShopService missing; skip")
		return false, "no-shopservice"
	end
	local state    = StateHub.get(plr) or {}
	local notice   = opts and opts.notice or "変換が完了しました"
	local preserve = (opts and opts.preserve) ~= false
	local tried = {}
	local function tryCall(desc, f)
		local t0 = os.clock()
		local ok, err = pcall(f)
		table.insert(tried, { desc = desc, ok = ok, err = ok and "" or tostring(err), ms = (os.clock()-t0)*1000 })
		return ok, err
	end
	if type(ShopService.openFor) == "function" then
		if select(1, tryCall("openFor(plr,state,opts)", function()
			return ShopService.openFor(plr, state, { notice = notice, preserve = preserve, reason = "kito_pick_done" })
		end)) then LOG.info("[ReopenShop] via openFor(plr,state,opts) in %.2fms", tried[#tried].ms); return true end
		if select(1, tryCall("openFor(plr,{state,...})", function()
			return ShopService.openFor(plr, { state = state, notice = notice, preserve = preserve, reason = "kito_pick_done" })
		end)) then LOG.info("[ReopenShop] via openFor(plr,{state,...}) in %.2fms", tried[#tried].ms); return true end
	end
	if type(ShopService.open) == "function" then
		if select(1, tryCall("open(plr,state,opts)", function()
			return ShopService.open(plr, state, { notice = notice, preserve = preserve, reason = "kito_pick_done" })
		end)) then LOG.info("[ReopenShop] via open(plr,state,opts) in %.2fms", tried[#tried].ms); return true end
		if select(1, tryCall("open(plr,{state,...})", function()
			return ShopService.open(plr, { state = state, notice = notice, preserve = preserve, reason = "kito_pick_done" })
		end)) then LOG.info("[ReopenShop] via open(plr,{state,...}) in %.2fms", tried[#tried].ms); return true end
	end
	for _, t in ipairs(tried) do if not t.ok then LOG.warn("[ReopenShop] tried %s → failed: %s (%.2fms)", t.desc, t.err, t.ms) end end
	return false, "no-matching-signature"
end

--─────────────────────────────────────────────────────────────
-- ★ monDelta を安全に適用（所持文）
--─────────────────────────────────────────────────────────────
local function applyMonDelta(plr: Player, delta:number?): (boolean, string?)
	if type(delta) ~= "number" or delta == 0 then return false, "no-delta" end

	for _, fnName in ipairs({ "applyMonDelta", "addMon" }) do
		if type(StateHub[fnName]) == "function" then
			local ok, err = pcall(function() StateHub[fnName](plr, delta) end)
			if ok then return true, nil end
			LOG.warn("[monDelta] %s failed: %s", fnName, tostring(err))
		end
	end

	local ok, err = pcall(function()
		local s = StateHub.get(plr) or {}
		s.mon = (type(s.mon) == "number" and s.mon or 0) + delta
	end)
	if not ok then
		return false, tostring(err)
	end
	return true, nil
end

--─────────────────────────────────────────────────────────────
-- Decide
--─────────────────────────────────────────────────────────────
local PRIMARY_NOTICE_SKIP = "選択をスキップしました"
local PRIMARY_NOTICE_DONE = "変換が完了しました"

local function onDecide(plr: Player, payload:any)
	if Balance.KITO_UI_ENABLED ~= true then return end

	local uid      = payload and payload.uid
	local sidRecv  = payload and payload.sessionId
	local noChange = (payload and payload.noChange) == true

	LOG.info("[Decide] recv u=%s sid=%s uid=%s noChange=%s",
		plr and plr.Name or "?", tostring(sidRecv), tostring(uid), tostring(noChange))

	-- 1) セッション消費
	local sess = KitoCore.consume(plr.UserId)
	if not sess or (sidRecv and sess.id ~= sidRecv) then
		if EvResult then EvResult:FireClient(plr, { ok=false, reason="session" }) end
		return
	end

	-- 2) TTL
	if type(sess.expiresAt) == "number" and os.time() > (sess.expiresAt or 0) then
		if EvResult then EvResult:FireClient(plr, { ok=false, reason="expired" }) end
		return
	end

	-- 3) 候補内チェック
	local okUid = false
	if type(uid) == "string" and type(sess.uids) == "table" then
		for _, u in ipairs(sess.uids) do if u == uid then okUid = true; break end end
	end
	if (not okUid) and (not noChange) then
		if EvResult then EvResult:FireClient(plr, { ok=false, reason="uid" }) end
		return
	end

	-- 4) state/runId
	local s = StateHub.get(plr)
	if not s then
		if EvResult then EvResult:FireClient(plr, { ok=false, reason="state" }) end
		return
	end
	local runId = resolveRunId(s) or resolveRunId(s.run)
	DeckRegistry.ensureFromContext(s)
	if not runId or runId == "" then
		if EvResult then EvResult:FireClient(plr, { ok=false, reason="run" }) end
		return
	end

	-- 5) noChange
	if noChange == true then
		reopenShopSnapshot(plr, { notice = PRIMARY_NOTICE_SKIP })
		if EvResult then EvResult:FireClient(plr, { ok=true, changed=false, uid=nil }) end
		return
	end

	-- 6) 効果ID（セッション値を使用／最低限の互換マップ）
	if not EffectsRegistry or type(EffectsRegistry.apply) ~= "function" then
		if EvResult then EvResult:FireClient(plr, { ok=false, reason="effects" }) end
		return
	end
	local effectId = tostring(sess.effectId or "")
	if effectId == "" then
		if EvResult then EvResult:FireClient(plr, { ok=false, reason="effects" }) end
		return
	end
	if effectId == "kito_tori" then effectId = "kito.tori_brighten" end

	-- 7) サーバ canApply 再確認
	local cardForUid
	do
		local store = DeckRegistry.read(runId)
		if type(store) == "table" and type(store.entries) == "table" then
			for _, e in ipairs(store.entries) do
				if e and (e.uid == uid or e.code == uid) then cardForUid = e; break end
			end
		end
	end
	if not cardForUid then
		if EvResult then EvResult:FireClient(plr, { ok=false, reason="uid" }) end
		return
	end
	if type(EffectsRegistry.canApply) == "function" then
		local canOk, canReason = EffectsRegistry.canApply(effectId, cardForUid, { CardEngine = CardEngine })
		if not canOk then
			if EvResult then EvResult:FireClient(plr, { ok=false, reason="effect", message=tostring(canReason or "not-eligible") }) end
			return
		end
	end

	-- 8) 効果適用
	local applyPayload = {
		plr      = plr,
		runId    = runId,
		uid      = uid,
		uids     = (uid and { tostring(uid) } or nil),
		poolUids = sess.uids,
		now      = os.time(),
		lang     = s.lang or "ja",
	}
	if effectId == "kito.tori_brighten" or effectId == "Tori_Brighten" then
		applyPayload.preferKind = "bright"
		applyPayload.tag        = "eff:kito_tori_bright"
	end

	local okCall, res = pcall(function()
		return EffectsRegistry.apply(runId, effectId, applyPayload)
	end)
	if not okCall then
		if EvResult then EvResult:FireClient(plr, { ok=false, reason="effect", message=tostring(res), id=effectId }) end
		return
	end

	-- 9) 正規化（messageは文字列のみ採用／bankDeltaは数値化）
	local ok       = (type(res) == "table") and (res.ok ~= false) or (res ~= nil)
	local changed  = (type(res) == "table") and (res.changed ~= 0 and res.changed ~= false) or true
	local msgStr   = ""
	if type(res) == "table" then
		if type(res.message) == "string" then
			msgStr = res.message
		elseif type(res.reason) == "string" then
			msgStr = res.reason
		end
	end
	local bankDeltaRaw = (type(res) == "table" and type(res.meta) == "table") and res.meta.bankDelta or nil
	local bankDelta = tonumber(bankDeltaRaw)

	if not ok then
		if EvResult then EvResult:FireClient(plr, { ok=false, reason="effect", message=tostring(msgStr or ""), id=effectId }) end
		return
	end

	-- 10) ★ kito_last 記録（UI経由でも子 ko が再発火できるように）
	do
		local okRec, errRec = pcall(function()
			if Kito and type(Kito.recordFromPick) == "function" then
				Kito.recordFromPick(s, effectId, applyPayload, res)
			end
		end)
		if not okRec then
			LOG.warn("[Decide] recordFromPick failed: %s", tostring(errRec))
		end
	end

	-- 11) bankDelta（= 所持文の増分）を mon に適用
	if bankDelta and bankDelta ~= 0 then
		local mOk, mErr = applyMonDelta(plr, bankDelta)
		LOG.info("[Decide] monDelta %+d applied=%s err=%s", bankDelta, tostring(mOk), mOk and "" or tostring(mErr))
	end

	-- 12) 状態同期
	local okPush, errPush = pcall(function() StateHub.pushState(plr) end)
	LOG.info("[Decide] pushState ok=%s err=%s", tostring(okPush), okPush and "" or tostring(errPush))

	-- 13) Shop 再表示（在庫維持）— notice を（+N 文）付きで
	local base = (msgStr ~= "" and msgStr) or PRIMARY_NOTICE_DONE
	local finalNotice = (bankDelta and bankDelta ~= 0)
		and string.format("%s（+%d 文）", base, bankDelta)
		or base
	reopenShopSnapshot(plr, { notice = finalNotice, preserve = true })

	-- 14) 結果通知
	if EvResult then
		local resOut = {
			ok      = true,
			changed = changed,
			uid     = tostring(uid),
			message = msgStr,
			id      = effectId,
		}
		if bankDelta then resOut.bankDelta = bankDelta end
		EvResult:FireClient(plr, resOut)
	end

	LOG.info("[Decide] OK | u=%s run=%s uid=%s eff=%s msg=%s",
		plr and plr.Name or "?", tostring(runId), tostring(uid), tostring(effectId), tostring(msgStr or ""))
end

-- Cancel（任意）
local function onCancel(plr: Player, _payload:any)
	KitoCore.consume(plr.UserId)
	reopenShopSnapshot(plr, { notice = "取消しました", preserve = true })
	if EvResult then EvResult:FireClient(plr, { ok=true, changed=false, cancel=true }) end
end

-- Wiring
local function wire()
	if EvDecide then EvDecide.OnServerEvent:Connect(onDecide) end
	if EvCancel then EvCancel.OnServerEvent:Connect(onCancel) end
	LOG.info("ready (handlers wiring)")
end
wire()
