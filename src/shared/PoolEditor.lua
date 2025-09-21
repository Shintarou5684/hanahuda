-- ReplicatedStorage/SharedModules/PoolEditor.lua
-- 目的: 「プール編集セッション」の開始/変更/確定(コミット)を提供する。
-- 依存: Balance.KITO_POOL_TTL_SEC / RunDeckUtil.* / DeckSampler.sampleUids

local RS = game:GetService("ReplicatedStorage")

local HttpService  = game:GetService("HttpService")
local Balance      = require(RS:WaitForChild("Config"):WaitForChild("Balance"))
local RunDeckUtil  = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))
local DeckSampler  = require(RS:WaitForChild("SharedModules"):WaitForChild("DeckSampler"))

local M = {}

local function now() return os.time() end
local function ttlSec()
	return tonumber(Balance.KITO_POOL_TTL_SEC or 45) or 45
end

-- セッション開始:
--   戻り値 { id, version, createdAt, expiresAt, uids[], snap={ [uid]=entryCopy } }
function M.start(state:any, k:number?)
	if typeof(state) ~= "table" then return nil end
	if typeof(state.deck) ~= "table" then return nil end

	RunDeckUtil.ensureUids(state)

	local version = RunDeckUtil.getDeckVersion(state)
	local uids    = DeckSampler.sampleUids(state, k)
	if #uids == 0 then
		return { id = HttpService:GenerateGUID(false), version = version, createdAt = now(), expiresAt = now() + ttlSec(), uids = {}, snap = {} }
	end

	-- 現在デッキのスナップショット（uid 指定で複製）
	local deck = state.deck
	local map  = RunDeckUtil.buildUidIndexMap(state)
	local snap = {}
	for _, uid in ipairs(uids) do
		local i = map[uid]
		local e = i and deck[i]
		if typeof(e) == "table" then
			snap[uid] = table.clone(e) -- uid も含めた現状コピー
		end
	end

	return {
		id        = HttpService:GenerateGUID(false),
		version   = version,
		createdAt = now(),
		expiresAt = now() + ttlSec(),
		uids      = uids,
		snap      = snap,
	}
end

-- セッション内容に手を加える
-- op.kind:
--   - "convertKind"  : 指定 uid 群を「同月の targetKind」に置換（定義に基づく安全変換）
--       fields: targetKind:string, uids?:{string}（未指定なら sess.uids 全部）
--   - "remove"       : 指定 uid 群を削除マーク（コミット時に remove 適用）
--       fields: uids:{string}
function M.mutate(sess:any, op:any): (boolean, any?)
	if typeof(sess) ~= "table" or typeof(sess.snap) ~= "table" then
		return false, "invalid session"
	end
	if typeof(op) ~= "table" or op.kind == nil then
		return false, "invalid op"
	end

	if op.kind == "convertKind" then
		local target = tostring(op.targetKind or "")
		if target == "" then return false, "targetKind required" end
		local list = (typeof(op.uids) == "table" and op.uids) or sess.uids
		local changed = 0
		for _, uid in ipairs(list) do
			local src = sess.snap[uid]
			if typeof(src) == "table" then
				local repl = RunDeckUtil.entryWithKindLike(src, target)
				if repl then
					repl.uid = uid
					sess.snap[uid] = repl
					changed += 1
				end
			end
		end
		return true, changed
	end

	if op.kind == "remove" then
		if typeof(op.uids) ~= "table" or #op.uids == 0 then
			return false, "uids required"
		end
		sess._remove = sess._remove or {}
		for _, uid in ipairs(op.uids) do
			sess._remove[uid] = true
			sess.snap[uid] = nil
		end
		return true, #op.uids
	end

	return false, "unsupported op"
end

-- コミット（楽観ロック: deckVersion が一致した場合のみ反映）
function M.commit(state:any, sess:any): (boolean, string)
	if typeof(state) ~= "table" or typeof(state.deck) ~= "table" then
		return false, "invalid state"
	end
	if typeof(sess) ~= "table" then
		return false, "invalid session"
	end
	if sess.expiresAt and now() > sess.expiresAt then
		return false, "session expired"
	end
	if RunDeckUtil.getDeckVersion(state) ~= sess.version then
		return false, "deck changed; please retry"
	end

	-- 差分作成
	local patch = { replace = {}, remove = {} }
	for _, uid in ipairs(sess.uids or {}) do
		if sess.snap[uid] then
			patch.replace[uid] = sess.snap[uid]
		elseif sess._remove and sess._remove[uid] then
			patch.remove[uid] = true
		end
	end

	local ok = RunDeckUtil.applyDeckPatchByUid(state, patch)
	return ok == true, ok and "ok" or "failed"
end

return M
