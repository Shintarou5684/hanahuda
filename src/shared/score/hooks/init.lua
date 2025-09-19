-- SharedModules/score/hooks/init.lua
-- v1.0 S5: talisman フックを「役加点の直前」に登録する

local M = {}

-- 既存フックの読み込み
local roleHooks     = require(script:WaitForChild("role"))         -- 例：役の加点
local multiplier    = require(script:WaitForChild("multiplier"))   -- 例：倍率処理
local bonus         = require(script:WaitForChild("bonus"))        -- 例：各種ボーナス
local talisman      = require(script:WaitForChild("talisman"))     -- ★今回追加

-- 実行順を固定化（例）:
--  1) multiplier（倍率の前処理があるなら）
--  2) talisman   ← ★役に依存する護符もあるため「役加点の直前」に置く
--  3) roleHooks
--  4) bonus（最終係数系が別ならここ）
M.ORDERED = {
	-- 例：倍率前処理
	function (tally, state, ctx) return multiplier.apply(tally, state, ctx) end,

	-- ★S5: 護符
	function (tally, state, ctx) return talisman.apply(tally, state, ctx) end,

	-- 役
	function (tally, state, ctx) return roleHooks.apply(tally, state, ctx) end,

	-- ボーナス（必要に応じて）
	function (tally, state, ctx) return bonus.apply(tally, state, ctx) end,
}

-- パイプライン実行ユーティリティ（既存があるならそれを使用）
function M.runAll(tally, state, ctx)
	local out = tally
	for _, fn in ipairs(M.ORDERED) do
		out = fn(out, state, ctx)
	end
	return out
end

return M
