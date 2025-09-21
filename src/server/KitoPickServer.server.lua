-- ServerScriptService/KitoPickServer.lua
-- 目的: KITOの「12枚提示→選択→確定」をサーバで管理（UIは後付け）

-- ── Services ─────────────────────────────────────────────────
local RS      = game:GetService("ReplicatedStorage")
local SSS     = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- ── Logger ───────────────────────────────────────────────────
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("KitoPickServer")
LOG.info("ready (handlers wiring)")

-- ── Deps ─────────────────────────────────────────────────────
local Balance     = require(RS:WaitForChild("Config"):WaitForChild("Balance"))
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))
local PoolEditor  = require(RS:WaitForChild("SharedModules"):WaitForChild("PoolEditor"))
local CardEngine  = require(RS:WaitForChild("SharedModules"):WaitForChild("CardEngine"))

-- ── Remotes ──────────────────────────────────────────────────
local Remotes  = RS:WaitForChild("Remotes")
local EvStart  = Remotes:WaitForChild("KitoPickStart")   :: RemoteEvent -- S→C (提示) / C→S (任意開始要求)
local EvDecide = Remotes:WaitForChild("KitoPickDecide")  :: RemoteEvent -- C→S 決定
local EvResult = Remotes:WaitForChild("KitoPickResult")  :: RemoteEvent -- S→C 結果通知

-- ── Core（セッション正本）/ State ───────────────────────────
local Core     = require(SSS:WaitForChild("KitoPickCore"))
local StateHub = require(RS:WaitForChild("SharedModules"):WaitForChild("StateHub"))
local function getLiveState(player: Player)
	return StateHub.get(player)
end

-- ===== 任意: C→S Start を受けた場合も Core に移譲して開始 =====
EvStart.OnServerEvent:Connect(function(player: Player, effectId: any, targetKind: any)
	if Balance.KITO_UI_ENABLED ~= true then return end
	local state = getLiveState(player)
	LOG.info("[Start][REQ] u=%s eff=%s tgt=%s deck=%s",
		player and player.Name or "?", tostring(effectId), tostring(targetKind),
		(type(state) == "table" and type(state.deck) == "table") and #state.deck or "nil"
	)
	Core.startFor(player, state, tostring(effectId or "kito_tori"), tostring(targetKind or "bright"))
end)
LOG.debug("[Wire] Start handler wired")

-- ================= C→S: 決定（sessionId, uid, targetKind） =================
EvDecide.OnServerEvent:Connect(function(player: Player, payload: any)
	if Balance.KITO_UI_ENABLED ~= true then return end
	if type(payload) ~= "table" then return end

	local wantId   = tostring(payload.sessionId or "")
	local pickUid  = tostring(payload.uid or "")
	local target   = tostring(payload.targetKind or "bright")

	if wantId == "" or pickUid == "" then
		LOG.warn("[Decide][BADPAYLOAD] u=%s sid=%s uid=%s", player and player.Name or "?", wantId, pickUid)
		return
	end

	-- Core のセッションを参照（存在＆ID一致チェック）
	local peek = Core.peek(player.UserId)
	if not peek then
		LOG.warn("[Decide][NOSESS] u=%s sid=%s (peek=nil)", player and player.Name or "?", wantId)
		return
	end
	if peek.id ~= wantId then
		LOG.warn("[Decide][SID-MISMATCH] u=%s want=%s have=%s", player and player.Name or "?", wantId, tostring(peek.id))
		return
	end

	-- 以降は消費（取り出して削除）
	local sess  = Core.consume(player.UserId)
	local state = getLiveState(player)
	if type(state) ~= "table" or type(state.deck) ~= "table" then
		LOG.warn("[Decide][NOSTATE] u=%s", player and player.Name or "?")
		return
	end

	-- 変換（対象1枚）
	local okMut, _ = PoolEditor.mutate(sess, {
		kind       = "convertKind",
		targetKind = target,
		uids       = { pickUid },
	})
	if not okMut then
		LOG.warn("[Decide][MUTATE-NG] u=%s sid=%s uid=%s tgt=%s", player and player.Name or "?", wantId, pickUid, target)
	end

	local okCommit, reason = PoolEditor.commit(state, sess)

	local label = (sess.snap and sess.snap[pickUid] and (sess.snap[pickUid].name or sess.snap[pickUid].code)) or pickUid
	local msg
	if okCommit then
		msg = ("酉：%s を %s に変換しました（確定）"):format(label, target)
		LOG.info("[Decide][OK] u=%s sid=%s uid=%s tgt=%s", player and player.Name or "?", wantId, pickUid, target)
	else
		msg = ("酉：変換に失敗しました（%s）"):format(tostring(reason))
		LOG.warn("[Decide][COMMIT-NG] u=%s sid=%s uid=%s tgt=%s reason=%s",
			player and player.Name or "?", wantId, pickUid, target, tostring(reason))
	end

	-- クライアントへ結果
	EvResult:FireClient(player, {
		ok         = okCommit == true,
		message    = msg,
		targetKind = target,
	})

-- 屋台再描画（notice に結果掲載）
local ShopService = require(RS:WaitForChild("SharedModules"):WaitForChild("ShopService"))
ShopService.open(player, state, { notice = msg })
end)
LOG.debug("[Wire] Decide handler wired")

-- ================= Cleanup =================
Players.PlayerRemoving:Connect(function(p: Player)
	Core.consume(p.UserId) -- 存在すれば破棄
	LOG.debug("[Cleanup] user left; consumed any pending session for uid=%s", tostring(p.UserId))
end)
LOG.debug("[Wire] PlayerRemoving cleanup wired")
