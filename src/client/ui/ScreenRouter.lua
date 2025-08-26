-- StarterPlayerScripts/UI/ScreenRouter.lua
-- シンプルな画面ルーター：同じ画面への show は再実行しない（ちらつき対策）
-- モジュールは table.new(deps) でも function(deps) でも受け付ける

local Router = {}

local map       = nil   -- name -> module (table or function)
local deps      = nil   -- 共有依存
local instances = {}    -- name -> screen instance
local current   = nil   -- 現在の画面名

function Router.init(screenMap)
	map = screenMap
end

function Router.setDeps(d)
	deps = d
end

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

function Router.show(name, payload)
	local inst = ensure(name)

	-- すでに表示中なら「setData」だけ渡して終了（再show/hideしない）
	if current == name then
		if inst.setData then inst.setData(payload) end
		return
	end

	-- いまの画面を隠す
	if current and instances[current] and instances[current].hide then
		instances[current]:hide()
	end

	current = name
	if inst.show then inst:show(payload) end
end

-- 指定画面のメソッド呼び出し（存在すれば）
function Router.call(name, method, ...)
	local sc = instances[name] or ensure(name)
	local fn = sc and sc[method]
	if type(fn) == "function" then
		return fn(sc, ...)
	end
end

-- 現在アクティブな画面名
function Router.active()
	return current
end

return Router
