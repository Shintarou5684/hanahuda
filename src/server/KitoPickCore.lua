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

-- 画像ルックアップ（存在しない環境でも落ちないようにフォールバック）
local CardImageMap do
	local ok, mod = pcall(function()
		return require(RS:WaitForChild("SharedModules"):WaitForChild("CardImageMap"))
	end)
	if ok and type(mod) == "table" then
		CardImageMap = mod
	else
		CardImageMap = { get = function(_) return nil end }
		LOG.debug("CardImageMap not found; images will be omitted")
	end
end

local Core = {}

-- ユーザー別セッション保持
local sessions: {[number]: any} = {}

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

-- 月の推定（code/uid の先頭2桁から 1..12 を推定、無ければ nil）
local function guessMonth(e: any): number?
	local s = tostring((e and (e.code or e.uid)) or "")
	local two = string.match(s, "^(%d%d)")
	if not two then return nil end
	local n = tonumber(two)
	if n and n >= 1 and n <= 12 then return n end
	return nil
end

-- 送信用サマリ（画像＋eligible付与）
local function summarize(e: any, tgtKind: string, policy: string)
	if type(e) ~= "table" then return nil end
	local code = tostring(e.code or "")

	-- 画像の解決（CardImageMap.get は "rbxassetid://..." 文字列 or 数値ID を想定）
	local img = nil
	local ok, got = pcall(function()
		if type(CardImageMap.get) == "function" then
			return CardImageMap.get(code)
		end
	end)
	if ok then img = got end

	-- eligible（同種かつ"block"なら不可）
	local same = tostring(e.kind) == tostring(tgtKind or "")
	local eligible = true
	if policy == "block" then
		eligible = not same
	end

	local sum = {
		uid      = e.uid,
		code     = code,
		name     = e.name,
		kind     = e.kind,
		month    = e.month or guessMonth(e),
		eligible = eligible,
	}

	if type(img) == "string" then
		sum.image = img                  -- 例: "rbxassetid://123456" or https://...
	elseif type(img) == "number" or tonumber(img) then
		sum.imageId = tonumber(img)      -- 数値IDなら imageId で渡す（クライアントで rbxassetid:// を付与）
	end

	return sum
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

	-- 要約を作成（画像＋eligible付き）
	local list = {}
	local sameKind, otherKind = 0, 0
	local tgtKind = targetKind or "bright"
	local policy  = Balance.KITO_SAME_KIND_POLICY or "block"

	for _, uid in ipairs(sess.uids) do
		local e = sess.snap[uid]
		if e then
			if e.kind == tgtKind then sameKind += 1 else otherKind += 1 end
			local sum = summarize(e, tgtKind, policy)
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
		list       = list, -- ← 各要素に image / imageId / eligible を含む
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
