-- v0.9.0 効果ディスパッチ（カテゴリ別振り分け）
-- 公開I/F:
--   apply(effectId, state, ctx)   -> (ok:boolean, message:string)

local M = {}

--========================
-- サブモジュールの読込
--========================
local Kito
do
	local ok, mod = pcall(function()
		return require(script:WaitForChild("Kito"))
	end)
	if ok and type(mod) == "table" then
		Kito = mod
	else
		warn("[ShopEffects.init] Kito module not found or invalid:", mod)
	end
end

M.Kito = Kito -- 直接呼びたい場合用

local function msgJa(s) return s end

function M.apply(effectId, state, ctx)
	if type(effectId) ~= "string" then
		return false, msgJa("効果IDが不正です")
	end
	if effectId:sub(1,5) == "kito_" then
		if Kito and type(Kito.apply) == "function" then
			local okCall, okRet, msgRet = pcall(function()
				return Kito.apply(effectId, state, ctx)
			end)
			if not okCall then
				warn("[ShopEffects.init] Kito.apply threw:", okRet)
				return false, msgJa("祈祷適用中にエラーが発生しました")
			end
			return okRet == true, tostring(msgRet or "")
		else
			return false, msgJa("祈祷モジュールが見つかりません")
		end
	end
	return false, msgJa(("未対応の効果ID: %s"):format(effectId))
end

return M
