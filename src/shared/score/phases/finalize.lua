-- ReplicatedStorage/SharedModules/score/phases/finalize.lua
-- v0.9.3-S9 Finalize規約（唯一の式）:
-- score = (Σmon) * (Σpts) * ((1 + ΣaddMult) * ΠmulMult)
-- 現状は add=0, mul=1 なので挙動は不変。将来の倍率は ctx.mult に集約する。

local F = {}

function F.finalize(mon: number, pts: number, ctx: any)
	local add = 0
	local mul = 1
	if ctx and typeof(ctx) == "table" and typeof(ctx.mult)=="table" then
		add = tonumber(ctx.mult.add or 0) or 0
		mul = tonumber(ctx.mult.mul or 1) or 1
	end
	local factor = (1 + add) * mul
	-- 既存I/Fでは detail は {mon, pts} を返す契約なので、mon/pts は変更しない
	local total = (mon * pts) * factor
	-- ledgerには合成係数だけ記録（将来のデバッグのため）
	if ctx and typeof(ctx.add)=="function" then
		if factor ~= 1 then
			ctx:add("P9_finalize", 0, 0, string.format("factor=%.6f (add=%.6f, mul=%.6f)", factor, add, mul))
		else
			-- factor=1 の場合は静穏でOK（必要なら上の行を有効化）
			-- ctx:add("P9_finalize", 0, 0, "factor=1.0")
		end
	end
	return total, mon, pts, factor
end

return F
