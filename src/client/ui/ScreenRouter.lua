-- StarterPlayerScripts/UI/ScreenRouter.lua
-- シンプルな画面ルーター：同じ画面への show は再実行しない（ちらつき対策）
-- モジュールは table.new(deps) でも function(deps) でも受け付ける
-- v0.8.x:
--  - show(name, payload) 受信時、payload.lang を最優先で該当画面インスタンスへ適用（inst.setLang があれば即時実行）
--  - payload.lang 未指定時は Locale.getGlobal() を自動補完
--  - current==name の再表示スキップ時も setLang / setData は適用して取りこぼし防止

local Router = {}

--==================================================
-- 依存・状態
--==================================================
local map       = nil   -- name -> module (table or function)
local deps      = nil   -- 共有依存（playerGui や remotes など）
local instances = {}    -- name -> screen instance
local current   = nil   -- 現在の画面名

-- Locale（payload.lang 未指定時の補完に使用）
local RS     = game:GetService("ReplicatedStorage")
local Config = RS:WaitForChild("Config")
local Locale = require(Config:WaitForChild("Locale"))

--==================================================
-- 初期化
--==================================================
function Router.init(screenMap)
	map = screenMap
end

function Router.setDeps(d)
	deps = d
end

--==================================================
-- 内部：画面生成
--==================================================
local function instantiate(mod, name)
	-- table で .new(deps)
	if typeof(mod) == "table" and type(mod.new) == "function" then
		return mod.new(deps)
	end
	-- 関数モジュール function(deps)
	if type(mod) == "function" then
		return mod(deps)
	end
	error(("Screen module '%s' is invalid (need table.new or function)"):format(tostring(name)))
end

local function ensure(name)
	if instances[name] then return instances[name] end
	local mod = map and map[name]
	if not mod then error(("Screen '%s' not registered"):format(tostring(name))) end
	local inst = instantiate(mod, name)
	instances[name] = inst
	-- 画面のルートGUIを PlayerGui へ
	if inst.gui and deps and deps.playerGui and not inst.gui.Parent then
		inst.gui.Parent = deps.playerGui
	end
	return inst
end

--==================================================
-- 内部：payload 正規化（言語の自動注入）
--==================================================
local function normalizePayload(payload)
	payload = payload or {}
	if payload.lang == nil then
		-- 保存言語があればそれを、なければ OS ロケール推定（Locale 側の実装に準拠）
		if typeof(Locale.getGlobal) == "function" then
			payload.lang = Locale.getGlobal()
		else
			payload.lang = "en"
		end
	end
	return payload
end

--==================================================
-- 内部：言語の即時反映（inst.setLang があれば最優先で）
--==================================================
local function applyLangIfPossible(inst, lang)
	if not inst then return end
	if lang and type(inst.setLang) == "function" then
		-- 画面インスタンスに最優先で反映
		inst:setLang(lang)
	end
	-- グローバルにも同期しておく（あれば）
	if lang and typeof(Locale.setGlobal) == "function" then
		Locale.setGlobal(lang)
	end
end

--==================================================
-- 画面表示
--==================================================
function Router.show(name, payload)
	-- payload を正規化（lang を必ず持たせる）
	payload = normalizePayload(payload)
	print("[LANG_FLOW] Router.show ->", name, "payload.lang=", payload.lang)

	local inst = ensure(name)

	-- ★ 言語は最優先で即時適用（初回 show でも取りこぼさない）
	applyLangIfPossible(inst, payload.lang)

	-- current==name の最適化前に、データは渡しておく（表示スキップでも状態更新はする）
	if current == name then
		if type(inst.setData) == "function" then
			inst:setData(payload)
		end
		print("[LANG_FLOW] Router.show skipped re-show for", name)
		return
	end

	-- 旧画面 hide
	if current and instances[current] and type(instances[current].hide) == "function" then
		instances[current]:hide()
	end

	current = name

	-- 画面表示
	if type(inst.show) == "function" then
		inst:show(payload)
	end
end

--==================================================
-- 指定画面のメソッド呼び出し（存在すれば）
--==================================================
function Router.call(name, method, ...)
	local sc = instances[name] or ensure(name)
	local fn = sc and sc[method]
	if type(fn) == "function" then
		return fn(sc, ...)
	end
end

--==================================================
-- 現在アクティブな画面名
--==================================================
function Router.active()
	return current
end

-- 明示的にインスタンスを取得したい場合（必要なら利用）
function Router.ensure(name)
	return ensure(name)
end

return Router
