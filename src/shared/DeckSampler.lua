-- ReplicatedStorage/SharedModules/DeckSampler.lua
-- 目的: ラン中デッキ(state.deck)から K 枚ぶんの "uid" を無作為抽出する（重複なし）。
-- 依存: Balance.KITO_POOL_SIZE / RunDeckUtil.ensureUids
-- 追記: ctx.rng があればそれを優先使用。なければ時刻ベースでフォールバック。
-- 追加: sampleAny12(state, ctx?) … 既定サイズ(KITO_POOL_SIZE)で抽出するショートカット。

local RS = game:GetService("ReplicatedStorage")

local Balance     = require(RS:WaitForChild("Config"):WaitForChild("Balance"))
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))

local M = {}

-- ───────────────── Logger（任意・無害）
local LOG do
	local ok, Logger = pcall(function()
		return require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
	end)
	if ok and Logger and type(Logger.scope) == "function" then
		LOG = Logger.scope("DeckSampler")
	else
		LOG = { info=function(...) end, debug=function(...) end, warn=function(...) warn(string.format(...)) end }
	end
end

-- ───────────────── RNG 取得（ctx.rng 優先）
-- 引数 rngOrCtx は Random か、ctxテーブル（ctx.rng を見る）か、nil を受け付ける
local function resolveRng(state:any, rngOrCtx:any?): Random
	-- 明示 Random
	if typeof(rngOrCtx) == "Random" then
		return rngOrCtx
	end
	-- ctx テーブルから
	if typeof(rngOrCtx) == "table" and typeof(rngOrCtx.rng) == "Random" then
		return rngOrCtx.rng
	end
	-- フォールバック: 時刻＋runId/seed風味
	local salt = 0
	if typeof(state) == "table" then
		local runId = tostring(state.runId or "")
		-- runId から数字だけ抽出して少しだけ安定性を持たせる（任意）
		local num = string.match(runId, "%d+")
		if num then salt = tonumber(num) or 0 end
	end
	local seed = (os.clock() * 1e6 + salt) % 2^31
	return Random.new(seed)
end

-- ───────────────── 部分フィッシャー–イェーツ: K 枚だけランダム抽出
-- 速度最適化: 全体シャッフルではなく「末尾K個をランダム化」して取り出す
local function pickKIndices(total: number, want: number, rng: Random): {number}
	-- インデックス配列 [1..total]
	local idx = table.create(total)
	for i = 1, total do
		idx[i] = i
	end
	-- i=total から total-want+1 まで部分シャッフル
	for i = total, math.max(total - want + 1, 2), -1 do
		local j = rng:NextInteger(1, i)
		idx[i], idx[j] = idx[j], idx[i]
	end
	-- 末尾 want 件を返す
	local out = table.create(want)
	local p = 1
	for i = total - want + 1, total do
		out[p] = idx[i]
		p += 1
	end
	return out
end

-- ───────────────── デッキから uid の配列を K 個ぶん返す（Kが未指定なら既定値）
-- 互換I/F: 呼び出しは従来どおり M.sampleUids(state [, k [, rngOrCtx]])
function M.sampleUids(state:any, k:number?, rngOrCtx:any?): {string}
	if typeof(state) ~= "table" then return {} end
	if typeof(state.deck) ~= "table" then return {} end

	-- UID 付与を保証
	RunDeckUtil.ensureUids(state)

	local deck = state.deck
	local total = #deck
	if total <= 0 then return {} end

	local want = tonumber(k or Balance.KITO_POOL_SIZE) or 0
	want = math.clamp(want, 0, total)
	if want <= 0 then return {} end

	local rng = resolveRng(state, rngOrCtx)

	-- K 枚だけ部分シャッフルして取得
	local indices = pickKIndices(total, want, rng)

	-- UID配列を作成（万一の欠損はスキップして詰める）
	local out = table.create(want)
	local o = 1
	for _, i in ipairs(indices) do
		local e = deck[i]
		local uid = e and e.uid
		if typeof(uid) == "string" and #uid > 0 then
			out[o] = uid
			o += 1
		else
			LOG.warn("[sampleUids] missing uid at index=%s (skipped)", tostring(i))
		end
	end
	-- 欠損があって want 未満になる場合は、余りのインデックスから補充を試みる
	if o <= want then
		for i = 1, total do
			-- 既に選んだ index は飛ばす（簡易セット）
			-- ※ want が小さい前提のため O(n) で十分
			local used = false
			for _, ii in ipairs(indices) do if ii == i then used = true break end end
			if not used then
				local e = deck[i]
				local uid = e and e.uid
				if typeof(uid) == "string" and #uid > 0 then
					out[o] = uid
					o += 1
					if o > want then break end
				end
			end
		end
	end

	-- 最終長を want に合わせる（nil が入らないよう調整）
	if #out > want then
		for i = #out, want + 1, -1 do
			out[i] = nil
		end
	end

	LOG.debug("[sampleUids] total=%d want=%d -> out=%d", total, want, #out)
	return out
end

-- ───────────────── 既定サイズ（Balance.KITO_POOL_SIZE）で抽出するショートカット
-- 計画書での any12 に相当。rng は ctx か Random を渡せる。
function M.sampleAny12(state:any, rngOrCtx:any?): {string}
	local k = tonumber(Balance.KITO_POOL_SIZE) or 12
	return M.sampleUids(state, k, rngOrCtx)
end

return M
