-- ReplicatedStorage/SharedModules/PoolEditor.lua
-- DEPRECATED: Deck リファクターにより役割を終了。
-- すべてのデッキ編集は EffectsRegistry + DeckStore.transact + DeckOps に移行してください。
--
-- 互換のため public API(start/mutate/commit)は残すが、すべて no-op。
-- 誤用に気づけるよう warn を出し、安全な戻り値を返す。

local HttpService = game:GetService("HttpService")

local M = {}

local function _warn(where: string)
	warn(("[PoolEditor] DEPRECATED: '%s' was called. Use Deck/EffectsRegistry + DeckOps instead."):format(where))
end

-- セッション開始（ダミーを返す）
-- 戻り値形式は維持: { id, version, createdAt, expiresAt, uids = {}, snap = {} }
function M.start(_state: any, _k: number?)
	_warn("start")
	local now = os.time()
	return {
		id        = HttpService:GenerateGUID(false),
		version   = 0,
		createdAt = now,
		expiresAt = now, -- すぐ失効扱い
		uids      = {},
		snap      = {},
	}
end

-- mutate: 互換のため false を返す（変更なし）
function M.mutate(_sess: any, _op: any): (boolean, any?)
	_warn("mutate")
	return false, "PoolEditor is deprecated (no-op)"
end

-- commit: 互換のため false を返す（変更なし）
function M.commit(_state: any, _sess: any): (boolean, string)
	_warn("commit")
	return false, "PoolEditor is deprecated (no-op)"
end

return M
