-- ServerScriptService/ShopEffects/init.lua
-- v0.9.0 効果ディスパッチ（カテゴリ別振り分け）
-- 公開I/F:
--   apply(effectId, state, ctx) -> (ok:boolean, message:string)

local M = {}

--========================
-- サブモジュールの読込（安全なpcall）
--========================
local function safeRequire(container, childName)
	local ok, mod = pcall(function()
		return require(container:WaitForChild(childName))
	end)
	if ok and type(mod) == "table" then
		return mod
	else
		warn("[ShopEffects.init] module not found or invalid:", childName, mod)
		return nil
	end
end

local Kito     = safeRequire(script, "Kito")
local Sai      = safeRequire(script, "Sai")
local Spectral = safeRequire(script, "Spectral") -- ★追加

-- 直接呼びたい場合のエクスポート
M.Kito     = Kito
M.Sai      = Sai
M.Spectral = Spectral

local function msgJa(s) return s end

--========================
-- 内部：委譲呼び出し（共通ラッパ）
--========================
local function delegate(mod, fx, effectId, state, ctx, tag)
	if not (mod and type(mod[fx]) == "function") then
		return false, msgJa(tag .. "モジュールが見つかりません")
	end
	local okCall, okRet, msgRet = pcall(function()
		return mod[fx](effectId, state, ctx)
	end)
	if not okCall then
		warn(("[ShopEffects.init] %s.apply threw: %s"):format(tag, tostring(okRet)))
		return false, msgJa(tag .. "適用中にエラーが発生しました")
	end
	return okRet == true, tostring(msgRet or "")
end

--========================
-- メインディスパッチ
--========================
function M.apply(effectId, state, ctx)
	if type(effectId) ~= "string" then
		return false, msgJa("効果IDが不正です")
	end

	-- 祈祷（kito_）
	if effectId:sub(1,5) == "kito_" then
		return delegate(Kito, "apply", effectId, state, ctx, "祈祷")
	end

	-- 祭事（sai_）
	if effectId:sub(1,4) == "sai_" then
		return delegate(Sai, "apply", effectId, state, ctx, "祭事")
	end

	-- ★ スペクタル（spectral_/spec_/互換kito_spec_）
	if effectId:sub(1,9) == "spectral_" or effectId:sub(1,5) == "spec_" or effectId:sub(1,11) == "kito_spec_" then
		return delegate(Spectral, "apply", effectId, state, ctx, "スペクタル")
	end

	return false, msgJa(("未対応の効果ID: %s"):format(effectId))
end

return M
