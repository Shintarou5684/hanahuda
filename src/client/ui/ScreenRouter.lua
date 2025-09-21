-- StarterPlayerScripts/UI/ScreenRouter.lua
-- シンプルな画面ルーター：同じ画面への show は再実行しない（ちらつき対策）
-- v0.9.5 (P1-4):
--  - current==name の場合、非表示ループを完全スキップ（ちらつきゼロ）
--  - Enabled/Visible を型ガードして安全化（ScreenGui/GuiObject 両対応）
--  - setData → updateOrShow だけ行う
--  - Logger 導入（print/warn を LOG.* に置換）
--  - register(name, module) を追加（動的登録に対応）
--  - ログ例: LOG.debug("Router.show updated same screen for %s", name)

local Router = {}

--==================================================
-- 依存・状態
--==================================================
local _map       = nil   -- name -> module (table or function)
local _deps      = nil   -- 共有依存（playerGui や remotes など）
local _instances = {}    -- name -> screen instance
local _current   = nil   -- 現在の画面名

-- Locale（payload.lang 未指定時の補完に使用）
local RS     = game:GetService("ReplicatedStorage")
local Config = RS:WaitForChild("Config")
local Locale = require(Config:WaitForChild("Locale"))

-- Logger
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("ScreenRouter")

--==================================================
-- ヘルパ：可視状態の安全設定（ScreenGui/GuiObject 両対応）
--==================================================
local function setGuiActive(gui: Instance?, active: boolean)
	if not gui or typeof(gui) ~= "Instance" then return end
	if gui:IsA("ScreenGui") then
		gui.Enabled = active
	elseif gui:IsA("GuiObject") then
		gui.Visible = active
	end
end

--==================================================
-- 初期化
--==================================================
function Router.init(screenMap)
	_map = screenMap
	LOG.info("initialized")
end

function Router.setDeps(d)
	_deps = d
	-- 既に生成済みの画面 GUI が未親付けなら補修
	if _deps and _deps.playerGui then
		for _, inst in pairs(_instances) do
			if inst and inst.gui and inst.gui.Parent == nil then
				pcall(function() inst.gui.ResetOnSpawn = false end)
				inst.gui.Parent = _deps.playerGui
			end
		end
	end
	LOG.debug("deps set (playerGui=%s)", tostring(_deps and _deps.playerGui))
end

--==================================================
-- 動的登録
--==================================================
function Router.register(name: string, module)
	if type(name) ~= "string" or name == "" then
		LOG.warn("register: invalid name: %s", tostring(name))
		return false
	end
	if module == nil then
		LOG.warn("register: module is nil for '%s'", name)
		return false
	end
	_map = _map or {}
	local existed = _map[name] ~= nil
	_map[name] = module
	LOG.debug("registered screen '%s'%s", name, existed and " (overwrote)" or "")
	-- 既に生成済みのインスタンスがある場合は、そのまま維持（安全第一）
	-- 差し替えが必要なケースは、呼び出し側で Router.ensure を使って再生成するか、
	-- 旧インスタンスの明示破棄を行ってください。
	return true
end

--==================================================
-- 内部：画面生成
--==================================================
local function instantiate(mod, name)
	-- table で .new(deps)
	if typeof(mod) == "table" and type(mod.new) == "function" then
		return mod.new(_deps)
	end
	-- 関数モジュール function(deps)
	if type(mod) == "function" then
		return mod(_deps)
	end
	-- テーブルをそのままインスタンスとして使う（最低限の互換）
	if typeof(mod) == "table" then
		return mod
	end
	error(("Screen module '%s' is invalid (need table.new or function or instance table)"):format(tostring(name)))
end

local function ensure(name)
	if _instances[name] then return _instances[name] end
	local mod = _map and _map[name]
	if not mod then
		error(("Screen '%s' not registered"):format(tostring(name)))
	end
	local inst = instantiate(mod, name)
	_instances[name] = inst
	-- 画面のルートGUIを PlayerGui へ
	if inst.gui and _deps and _deps.playerGui and not inst.gui.Parent then
		pcall(function() inst.gui.ResetOnSpawn = false end)
		inst.gui.Parent = _deps.playerGui
	end
	return inst
end

--==================================================
-- 内部：payload 正規化（言語の自動注入）
--==================================================
local function normalizePayload(payload)
	payload = payload or {}
	if payload.lang == nil then
		if type(Locale.getGlobal) == "function" then
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
		inst:setLang(lang)
	end
	-- グローバルにも同期しておく（あれば）
	if lang and type(Locale.setGlobal) == "function" then
		Locale.setGlobal(lang)
	end
end

--==================================================
-- 内部：更新または再描画を呼ぶ
--==================================================
local function updateOrShow(inst, payload)
	if type(inst.update) == "function" then
		local ok, err = pcall(function() inst:update(payload) end)
		if not ok then LOG.warn("update failed: %s", tostring(err)) end
	elseif type(inst.show) == "function" then
		local ok, err = pcall(function() inst:show(payload) end)
		if not ok then LOG.warn("show(as update) failed: %s", tostring(err)) end
	end
end

--==================================================
-- 画面表示
--==================================================
function Router.show(arg, payload)
	-- 1) 互換：引数形を正規化
	local name
	if type(arg) == "table" and arg.name then
		name = arg.name
		payload = arg._payload
	else
		name = arg
	end
	if type(name) ~= "string" then
		LOG.warn("show: invalid name: %s", typeof(name))
		return
	end

	-- 2) payload を正規化（lang を必ず持たせる）
	payload = normalizePayload(payload)
	LOG.debug("Router.show -> %s | lang=%s", name, tostring(payload.lang))

	-- 3) インスタンス確保（new/create/そのままテーブルの順で対応）
	local inst
	local ok, err = pcall(function()
		inst = ensure(name)
	end)
	if not ok or type(inst) ~= "table" then
		LOG.warn("show: ensure failed for %s | %s", tostring(name), tostring(err))
		return
	end

	-- 3.5) GUI 親付けの最終確認
	if inst.gui and _deps and _deps.playerGui and inst.gui.Parent == nil then
		pcall(function() inst.gui.ResetOnSpawn = false end)
		inst.gui.Parent = _deps.playerGui
	end

	-- ★ 4) current==name：ちらつき防止モード（可視状態は触らない）
	if _current == name then
		applyLangIfPossible(inst, payload.lang)   -- 言語は即時反映
		if type(inst.setData) == "function" then  -- データは必ず渡す
			inst:setData(payload)
		end
		updateOrShow(inst, payload)               -- 差分更新 or 再描画
		LOG.debug("Router.show updated same screen for %s", name)
		return
	end

	-- 5) 全画面を安全に非表示（nil/型ガード付き）※別画面に切替時のみ
	for _, e in pairs(_instances) do
		if e and e.gui then
			setGuiActive(e.gui, false)
		end
	end

	-- 6) 言語は最優先で即時適用
	applyLangIfPossible(inst, payload.lang)

	-- 7) setData を先に渡しておく（show 前提条件）
	if type(inst.setData) == "function" then
		inst:setData(payload)
	end

	-- 8) 旧画面 hide（メソッドがあれば呼ぶ）
	if _current and _instances[_current] and type(_instances[_current].hide) == "function" then
		local prev = _instances[_current]
		local okHide, errHide = pcall(function() prev:hide() end)
		if not okHide then LOG.warn("hide failed for %s | %s", tostring(_current), tostring(errHide)) end
	end

	_current = name

	-- 9) 画面表示（メソッドがあれば呼ぶ）
	if type(inst.show) == "function" then
		local okShow, errShow = pcall(function() inst:show(payload) end)
		if not okShow then LOG.warn("show method failed for %s | %s", tostring(name), tostring(errShow)) end
	end

	-- 10) 最終的に可視化を担保（型ガード）
	if inst.gui then
		setGuiActive(inst.gui, true)
	end
end

--==================================================
-- 指定画面のメソッド呼び出し（存在すれば）
--==================================================
function Router.call(name, method, ...)
	local sc = _instances[name] or ensure(name)
	local fn = sc and sc[method]
	if type(fn) == "function" then
		return fn(sc, ...)
	end
end

--==================================================
-- 現在アクティブな画面名
--==================================================
function Router.active()
	return _current
end

-- 明示的にインスタンスを取得したい場合（必要なら利用）
function Router.ensure(name)
	return ensure(name)
end

return Router
