-- StarterPlayerScripts/UI/ScreenRouter.lua
-- シンプルな画面ルーター：同じ画面への show は再実行しない（ちらつき対策）
-- v0.9:
--  - show は `"name", payload` と `{ name="...", _payload=... }` の両方を受け付ける
--  - 画面インスタンス生成/親付け/Enabled 切替を安全に実施（nil ガード付き）
--  - payload.lang を最優先で inst.setLang に適用し、未指定時は Locale.getGlobal() を補完
--  - current==name の再表示スキップ時でも setData は適用
--  - setDeps 後に既存インスタンスの gui.Parent を補修
-- v0.9.1:
--  - current==name でも (inst.update or inst.show)(payload) を呼び、差分更新/再描画を実施

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

--==================================================
-- 初期化
--==================================================
function Router.init(screenMap)
	_map = screenMap
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
		if not ok then warn("[ScreenRouter] update failed:", err) end
	elseif type(inst.show) == "function" then
		local ok, err = pcall(function() inst:show(payload) end)
		if not ok then warn("[ScreenRouter] show (as update) failed:", err) end
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
		warn("[ScreenRouter] show: invalid name:", typeof(name))
		return
	end

	-- 2) payload を正規化（lang を必ず持たせる）
	payload = normalizePayload(payload)
	print("[LANG_FLOW] Router.show ->", name, "payload.lang=", payload.lang)

	-- 3) インスタンス確保（new/create/そのままテーブルの順で対応）
	local inst
	local ok, err = pcall(function()
		inst = ensure(name)
	end)
	if not ok or type(inst) ~= "table" then
		warn("[ScreenRouter] show: failed to ensure instance for", name, err)
		return
	end

	-- 3.5) GUI 親付けの最終確認
	if inst.gui and _deps and _deps.playerGui and inst.gui.Parent == nil then
		pcall(function() inst.gui.ResetOnSpawn = false end)
		inst.gui.Parent = _deps.playerGui
	end

	-- 4) 全画面を安全に非表示（nil ガード付き）
	for n, e in pairs(_instances) do
		if e and e.gui then
			e.gui.Enabled = false
		end
	end

	-- 5) 言語は最優先で即時適用
	applyLangIfPossible(inst, payload.lang)

	-- 6) current==name でもデータは渡す（取りこぼし防止）
	if type(inst.setData) == "function" then
		inst:setData(payload)
	end

	-- 7) current==name のときは差分更新 or 再描画を実施して終了（ちらつき防止）
	if _current == name then
		updateOrShow(inst, payload) -- ★追加：差分更新 or 再描画
		if inst.gui then inst.gui.Enabled = true end
		print("[LANG_FLOW] Router.show updated same screen for", name)
		return
	end

	-- 8) 旧画面 hide（メソッドがあれば呼ぶ）
	if _current and _instances[_current] and type(_instances[_current].hide) == "function" then
		local prev = _instances[_current]
		local okHide, errHide = pcall(function() prev:hide() end)
		if not okHide then warn("[ScreenRouter] hide failed for", _current, errHide) end
	end

	_current = name

	-- 9) 画面表示（メソッドがあれば呼ぶ）
	if type(inst.show) == "function" then
		local okShow, errShow = pcall(function() inst:show(payload) end)
		if not okShow then warn("[ScreenRouter] show method failed for", name, errShow) end
	end

	-- 10) 最終的に可視化を担保
	if inst.gui then inst.gui.Enabled = true end
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
