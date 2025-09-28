-- ServerScriptService/ShopEffects/init.lua
-- v0.9.1 効果ディスパッチ（カテゴリ別振り分け）
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
-- 呼び出し元ヒント生成（ログ用）
--========================
local UNDERSCORE_WARNED = {}  -- 重複warn防止

-- 自分自身のフルネーム（例: "ServerScriptService.ShopEffects"）
local SELF_NAME = (function()
	local ok, name = pcall(function() return script:GetFullName() end)
	return ok and name or "ServerScriptService.ShopEffects"
end)()

local function pickExplicitSource(state, ctx)
	-- 呼び出し側が明示してくれたら最優先
	if type(ctx) == "table" then
		if ctx.source  ~= nil then return tostring(ctx.source) end
		if ctx._source ~= nil then return tostring(ctx._source) end
	end
	if type(state) == "table" then
		if state.source  ~= nil then return tostring(state.source) end
		if state._source ~= nil then return tostring(state._source) end
	end
	return nil
end

local function guessCallerFromTraceback()
	-- Luauでは debug.traceback が使えるので、最初にそれっぽい行を拾う
	local tb
	local ok, ret = pcall(function()
		return debug.traceback("", 3) -- この関数から2フレーム上を基点に取得
	end)
	if ok then tb = ret end
	if type(tb) ~= "string" then return "unknown" end

	for line in tb:gmatch("[^\n]+") do
		-- このモジュール自身や x/pcall フレームは除外
		if not line:find(SELF_NAME, 1, true)
			and not line:find("ShopEffects/init", 1, true)
			and not line:find("xpcall", 1, true)
			and not line:find("pcall", 1, true)
		then
			-- 例: ServerScriptService.ShopService:123 といった形式を優先的に抜く
			local m = line:match("([%w%._/]+:%d+)")
			       or line:match("Script '([^']+)'")
			       or line:match("([%w%._/]+)")
			if m then return m end
		end
	end
	return "unknown"
end

local function makeCallerHint(state, ctx)
	return pickExplicitSource(state, ctx) or guessCallerFromTraceback()
end

local function warnUnderscoreOnce(effectId, dotId, caller)
	local key = tostring(caller) .. "|" .. tostring(effectId)
	if UNDERSCORE_WARNED[key] then return end
	UNDERSCORE_WARNED[key] = true
	warn(("[ShopEffects] DEPRECATED underscore id: %s  → use '%s'  | caller=%s")
		:format(effectId, dotId, caller))
end

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

	-- 祈祷（kito_ または kito. の両方を受け付け）
	if effectId:sub(1,5) == "kito_" or effectId:sub(1,5) == "kito." then
		if effectId:sub(1,5) == "kito_" then
			-- アンダーバーは互換受付しつつ、置換用に呼び出し元ヒントをwarn
			local dotId  = effectId:gsub("^kito_", "kito.")
			local caller = makeCallerHint(state, ctx)
			warnUnderscoreOnce(effectId, dotId, caller)
		end
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
