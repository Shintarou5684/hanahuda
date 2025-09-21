-- ServerScriptService/KitoPickCore.lua
-- 目的: KITO ピックのセッション生成/保持/失効と候補送信の中核
local RS   = game:GetService("ReplicatedStorage")
local SSS  = game:GetService("ServerScriptService")

local Balance    = require(RS:WaitForChild("Config"):WaitForChild("Balance"))
local PoolEditor = require(RS:WaitForChild("SharedModules"):WaitForChild("PoolEditor"))
local Logger     = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG        = Logger.scope("KitoPickCore")

local Remotes   = RS:WaitForChild("Remotes")
local EvStart   = Remotes:WaitForChild("KitoPickStart") -- RemoteEvent

local Core = {}

-- ユーザー別セッション保持
local sessions: {[number]: any} = {}

-- 送信用サマリ
local function summarize(e)
	if type(e) ~= "table" then return nil end
	return { uid=e.uid, code=e.code, name=e.name, kind=e.kind, month=e.month }
end

-- 便宜: 先頭N件のUIDを "uid1,uid2,..." で返す
local function headUidList(uids: {string}?, n: number)
	local out = {}
	if type(uids) == "table" then
		for i = 1, math.min(#uids, n) do
			out[#out+1] = tostring(uids[i])
		end
	end
	return table.concat(out, ",")
end

-- 公開: 現在のセッション（あれば）を見る
function Core.peek(userId: number)
	local s = sessions[userId]
	LOG.debug("[Peek] userId=%s has=%s sess=%s ver=%s",
		tostring(userId),
		tostring(s ~= nil),
		s and tostring(s.id) or "-",
		s and tostring(s.version) or "-")
	return s
end

-- 公開: セッションを消費（取得して同時に削除）
function Core.consume(userId: number)
	local s = sessions[userId]
	if s then
		LOG.debug("[Consume] userId=%s take sess=%s ver=%s (expiresAt=%s)",
			tostring(userId), tostring(s.id), tostring(s.version), tostring(s.expiresAt))
	else
		LOG.debug("[Consume] userId=%s no-session", tostring(userId))
	end
	sessions[userId] = nil
	return s
end

-- 内部: セッションを保存（上書き）
local function put(userId: number, sess: any)
	local existed = sessions[userId] ~= nil
	sessions[userId] = sess
	LOG.debug("[Put] userId=%s replace=%s sess=%s ver=%s uids#=%s",
		tostring(userId), tostring(existed),
		tostring(sess and sess.id), tostring(sess and sess.version),
		tostring(sess and sess.uids and #sess.uids or 0))
end

-- 公開: 候補提示セッションを開始してクライアントへ送信
-- effectId: "kito_tori" / targetKind: "bright"
function Core.startFor(player: Player, state: any, effectId: string, targetKind: string)
	if Balance.KITO_UI_ENABLED ~= true then
		LOG.debug("[StartFor] UI disabled; ignored | u=%s", player and player.Name or "?")
		return false
	end
	if tostring(effectId) ~= "kito_tori" then
		LOG.debug("[StartFor] unsupported effect=%s | u=%s", tostring(effectId), player and player.Name or "?")
		return false
	end
	if type(state) ~= "table" or type(state.deck) ~= "table" or #state.deck == 0 then
		LOG.debug("[StartFor] no live deck; u=%s", player and player.Name or "?")
		return false
	end

	local k = Balance.KITO_UI_PICK_COUNT or Balance.KITO_POOL_SIZE or 12
	local sess = PoolEditor.start(state, k)
	if not (sess and type(sess.uids) == "table" and #sess.uids > 0) then
		LOG.info("[StartFor] no candidates; aborted | u=%s", player and player.Name or "?")
		return false
	end

	-- セーブ（上書き）
	put(player.UserId, sess)

	-- 要約を作成
	local list = {}
	local sameKind, otherKind = 0, 0
	local tgtKind = targetKind or "bright"
	for _, uid in ipairs(sess.uids) do
		local e = sess.snap[uid]
		if e then
			if e.kind == tgtKind then sameKind += 1 else otherKind += 1 end
			local sum = summarize(e)
			if sum then table.insert(list, sum) end
		end
	end

	-- 送信
	local payload = {
		sessionId  = sess.id,
		version    = sess.version,
		expiresAt  = sess.expiresAt,
		effectId   = effectId,
		targetKind = tgtKind,
		list       = list,
	}
	EvStart:FireClient(player, payload)

	-- 詳細ログ
	LOG.info(
		"[StartFor] u=%s sess=%s size=%d tgt=%s sameKind=%d otherKind=%d head5=[%s]",
		player and player.Name or "?",
		tostring(sess.id),
		#list,
		tostring(tgtKind),
		sameKind, otherKind,
		headUidList(sess.uids, 5)
	)

	return true
end

return Core
