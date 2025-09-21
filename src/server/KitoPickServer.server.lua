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

-- ================= C→S: 決定（sessionId, uid?, targetKind, noChange?） =================
EvDecide.OnServerEvent:Connect(function(player: Player, payload: any)
	if Balance.KITO_UI_ENABLED ~= true then return end
	if type(payload) ~= "table" then return end

	local wantId   = tostring(payload.sessionId or "")
	local target   = tostring(payload.targetKind or "bright")
	local noChange = payload.noChange == true
	local policy   = tostring(Balance.KITO_SAME_KIND_POLICY or "block") -- "block" | "auto-skip" | "complete"

	-- uid はスキップ時は未指定でOK。空文字は nil 扱いに正規化。
	local pickUid  = payload.uid
	if type(pickUid) == "string" and pickUid == "" then
		pickUid = nil
	end
	if pickUid ~= nil then
		pickUid = tostring(pickUid)
	end

	-- sessionId は必須
	if wantId == "" then
		LOG.warn("[Decide][BADPAYLOAD] u=%s sid(empty)", player and player.Name or "?")
		return
	end

	-- Core のセッションを参照（存在＆ID一致チェック）※ここでは consume しない
	local peek = Core.peek(player.UserId)
	if not peek then
		LOG.warn("[Decide][NOSESS] u=%s sid=%s (peek=nil)", player and player.Name or "?", wantId)
		return
	end
	if peek.id ~= wantId then
		LOG.warn("[Decide][SID-MISMATCH] u=%s want=%s have=%s", player and player.Name or "?", wantId, tostring(peek.id))
		return
	end

	local state = getLiveState(player)
	if type(state) ~= "table" or type(state.deck) ~= "table" then
		LOG.warn("[Decide][NOSTATE] u=%s", player and player.Name or "?")
		return
	end

	-- ★ 分岐1: スキップ（変更なし確定）
	if noChange then
		local sess = Core.consume(player.UserId) -- セッションを閉じる
		local okCommit, reason = PoolEditor.commit(state, sess)
		local msg
		if okCommit then
			msg = "酉：変更せずに確定しました"
			LOG.info("[Decide][SKIP][OK] u=%s sid=%s tgt=%s", player and player.Name or "?", wantId, target)
		else
			msg = ("酉：変更なし確定に失敗しました（%s）"):format(tostring(reason))
			LOG.warn("[Decide][SKIP][COMMIT-NG] u=%s sid=%s reason=%s", player and player.Name or "?", wantId, tostring(reason))
		end
		EvResult:FireClient(player, { ok = okCommit == true, message = msg, targetKind = target })
		local ShopService = require(RS:WaitForChild("SharedModules"):WaitForChild("ShopService"))
		ShopService.open(player, state, { notice = msg })
		return
	end

	-- ★ 分岐2: 通常決定（カード指定が必要）
	if not pickUid then
		LOG.warn("[Decide][BADPAYLOAD] u=%s sid=%s uid=nil", player and player.Name or "?", wantId)
		EvResult:FireClient(player, { ok=false, message="対象が選ばれていません", targetKind=target })
		return
	end

	-- 候補の正当性を peek で確認（eligible チェックは“同種かどうか”でサーバ側もガード）
	local entry = peek.snap and peek.snap[pickUid]
	if not entry then
		LOG.warn("[Decide][NOTINPOOL] u=%s sid=%s uid=%s (not in snapshot)", player and player.Name or "?", wantId, pickUid)
		EvResult:FireClient(player, { ok=false, message="候補に存在しないカードです", targetKind=target })
		return
	end

	local isSameKind = tostring(entry.kind) == target

	-- ポリシー適用
	if isSameKind then
		if policy == "block" then
			-- 対象外：セッションは維持（consume しない）
			LOG.debug("[Decide][BLOCK] u=%s sid=%s uid=%s kind=%s tgt=%s",
				player and player.Name or "?", wantId, pickUid, tostring(entry.kind), target)
			EvResult:FireClient(player, {
				ok=false,
				message="対象外のカードです（同種は選べません）",
				targetKind=target,
			})
			return
		elseif policy == "auto-skip" or policy == "complete" then
			-- ノーオペ確定（セッション終了）
			local sess = Core.consume(player.UserId)
			local okCommit, reason = PoolEditor.commit(state, sess)
			local label = (entry.name or entry.code or pickUid)
			local msg
			if okCommit then
				if policy == "auto-skip" then
					msg = "酉：同種を選択したため、変更せずに確定しました"
				else
					msg = ("酉：%s を対象に実行しました（同種：変化なし）"):format(label)
				end
				LOG.info("[Decide][SAME][%s][OK] u=%s sid=%s uid=%s tgt=%s",
					policy, player and player.Name or "?", wantId, pickUid, target)
			else
				msg = ("酉：処理に失敗しました（%s）"):format(tostring(reason))
				LOG.warn("[Decide][SAME][%s][COMMIT-NG] u=%s sid=%s uid=%s tgt=%s reason=%s",
					policy, player and player.Name or "?", wantId, pickUid, target, tostring(reason))
			end
			EvResult:FireClient(player, { ok = okCommit == true, message = msg, targetKind = target })
			local ShopService = require(RS:WaitForChild("SharedModules"):WaitForChild("ShopService"))
			ShopService.open(player, state, { notice = msg })
			return
		end
	end

	-- ★ 分岐3: 異種変換（通常フロー）
	local sess  = Core.consume(player.UserId) -- ここで消費
	-- mutate（対象1枚）
	local okMut = select(1, PoolEditor.mutate(sess, {
		kind       = "convertKind",
		targetKind = target,
		uids       = { pickUid },
	}))
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
