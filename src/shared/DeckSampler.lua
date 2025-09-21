-- ReplicatedStorage/SharedModules/DeckSampler.lua
-- 目的: ラン中デッキ(state.deck)から K 枚ぶんの "uid" 候補を無作為抽出する。
-- 依存: Balance.KITO_POOL_SIZE / RunDeckUtil.ensureUids

local RS = game:GetService("ReplicatedStorage")

local Balance     = require(RS:WaitForChild("Config"):WaitForChild("Balance"))
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))

local M = {}

-- ランごとに安定しすぎない程度の RNG を取得（ない場合は時刻ベース）
local function pickRng(state:any)
	-- 将来 seed を run.meta などに保存するならここで掴む
	return Random.new(os.clock() * 1e6 % 2^31)
end

-- デッキから uid の配列を K 個ぶん返す（Kが未指定なら既定値）
function M.sampleUids(state:any, k:number?): {string}
	if typeof(state) ~= "table" then return {} end
	if typeof(state.deck) ~= "table" then return {} end

	RunDeckUtil.ensureUids(state)
	local deck = state.deck
	local total = #deck
	if total <= 0 then return {} end

	local want = tonumber(k or Balance.KITO_POOL_SIZE) or 0
	want = math.clamp(want, 0, total)
	if want <= 0 then return {} end

	-- フィッシャー–イェーツでインデックスをシャッフル → 先頭 want 件を採用
	local rng = pickRng(state)
	local idx = table.create(total)
	for i=1,total do idx[i] = i end
	for i = total, 2, -1 do
		local j = rng:NextInteger(1, i)
		idx[i], idx[j] = idx[j], idx[i]
	end

	local out = table.create(want)
	for i = 1, want do
		local e = deck[idx[i]]
		out[i] = e and e.uid or nil
	end
	return out
end

return M
