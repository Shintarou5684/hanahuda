-- ScreenRouter.lua  v0.8
local Router = {}

local map, deps = nil, nil
local instances = {}    -- name -> screen instance
local current   = nil   -- 現在の画面名

function Router.init(screenMap) map = screenMap end
function Router.setDeps(d) deps = d end

local function instantiate(mod, name)
	if typeof(mod) == "table" and type(mod.new) == "function" then
		return mod.new(deps)
	end
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
	if inst.gui and deps and deps.playerGui and not inst.gui.Parent then
		inst.gui.Parent = deps.playerGui
	end
	return inst
end

function Router.show(name, payload)
	local inst = ensure(name)
	if current == name then
		if inst.setData then inst.setData(payload) end
		return
	end
	if current and instances[current] and instances[current].hide then
		instances[current]:hide()
	end
	current = name
	if inst.show then inst:show(payload) end
end

function Router.call(name, method, ...)
	local sc = instances[name] or ensure(name)
	local fn = sc and sc[method]
	if type(fn) == "function" then
		return fn(sc, ...)
	end
end

function Router.active() return current end

return Router
