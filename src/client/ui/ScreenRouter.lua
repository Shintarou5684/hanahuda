-- StarterPlayerScripts/UI/ScreenRouter.lua
-- シンプルな画面ルーター：同じ画面への show は再実行しない（ちらつき対策）
-- v0.9.6 (P1-5):
--  - ★同一画面への show で payload が「空 or langのみ」の場合は setData を呼ばない（状態保護）
--  - ★payload=nil の場合は {} を作らず、そのまま nil を維持（既存状態を壊さない）
--  - current==name では setLang だけ即時反映し、update(nil) で安全に再描画
--  - それ以外の仕様は従来通り（register/ensure/可視制御など）
-- v0.9.7-P1-6:
--  - ★ Remotes.StatePush を購読し、Run 画面（setRerollCounts が定義されている画面）に
--      リロール残回数（場/手）を即時反映する汎用ハンドラを追加

local Router = {}

--==================================================
-- 依存・状態
--==================================================
local _map       = nil   -- name -> module (table or function)
local _deps      = nil   -- 共有依存（playerGui や remotes など）
local _instances = {}    -- name -> screen instance
local _current   = nil   -- 現在の画面名

-- Locale（payload.lang 未指定時の補完やログで使用）
local RS     = game:GetService("ReplicatedStorage")
local Config = RS:WaitForChild("Config")
local Locale = require(Config:WaitForChild("Locale"))

-- Logger
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("ScreenRouter")

-- Remotes購読コネクション（重複接続防止）
local _remotesConn : RBXScriptConnection? = nil

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
-- 内部：StatePush → アクティブ画面へ反映（リロール残）
--==================================================
local function handleStatePush(payload:any)
	-- 現在の画面インスタンスが setRerollCounts を持っていれば反映
	local inst = _current and _instances[_current] or nil
	if not inst then return end
	local fn = inst.setRerollCounts
	if type(fn) ~= "function" then return end

	-- 新キー優先 → 旧キーへフォールバック
	local fieldLeft = payload.rerollField or payload.rerollFieldLeft or payload.rerolls or 0
	local handLeft  = payload.rerollHand  or payload.rerollHandLeft  or payload.hands   or 0
	local phase     = payload.phase

	local f = tonumber(fieldLeft or 0) or 0
	local h = tonumber(handLeft  or 0) or 0

	-- 例外安全で画面側に流す
	local ok, err = pcall(function() fn(inst, f, h, phase) end)
	if not ok then
		LOG.warn("handleStatePush: setRerollCounts failed: %s", tostring(err))
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

	-- ★ Remotes.StatePush の購読を（まだなら）張る
	if _remotesConn then
		_remotesConn:Disconnect()
		_remotesConn = nil
	end
	local remFolder = RS:FindFirstChild("Remotes")
	if remFolder and remFolder:FindFirstChild("StatePush") then
		local ev = remFolder.StatePush
		_remotesConn = ev.OnClientEvent:Connect(handleStatePush)
		LOG.info("Remotes.StatePush handler wired")
	else
		LOG.warn("Remotes.StatePush not found; reroll counters won't auto-update")
	end
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
-- 内部：payload 正規化（※nilのときはnilのまま返す）
--==================================================
local function normalizePayload(payload)
	if payload == nil then return nil end
	if payload.lang == nil then
		if type(Locale.getGlobal) == "function" then
			payload.lang = Locale.getGlobal()
		else
			payload.lang = "en"
		end
	end
	return payload
end

-- 「lang 以外の有意なフィールドが存在するか」を判定（汎用）
local function hasNonLangFields(t)
	if type(t) ~= "table" then return false end
	for k, _ in pairs(t) do
		if k ~= "lang" then return true end
	end
	return false
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
local function updateOrShow(inst, payloadOrNil)
	if type(inst.update) == "function" then
		local ok, err = pcall(function() inst:update(payloadOrNil) end)
		if not ok then LOG.warn("update failed: %s", tostring(err)) end
	elseif type(inst.show) == "function" then
		local ok, err = pcall(function() inst:show(payloadOrNil) end)
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

	-- 2) payload を正規化（※nilのままの場合もある）
	local p = normalizePayload(payload)
	-- ログ用の lang ヒント
	local langHint = (p and p.lang)
		or (type(Locale.getGlobal) == "function" and Locale.getGlobal())
		or "en"
	LOG.debug("Router.show -> %s | lang=%s (payload=%s)", name, tostring(langHint), (p and "table") or "nil")

	-- 3) インスタンス確保
	local inst
	local okEnsure, errEnsure = pcall(function() inst = ensure(name) end)
	if not okEnsure or type(inst) ~= "table" then
		LOG.warn("show: ensure failed for %s | %s", tostring(name), tostring(errEnsure))
		return
	end

	-- 3.5) GUI 親付けの最終確認
	if inst.gui and _deps and _deps.playerGui and inst.gui.Parent == nil then
		pcall(function() inst.gui.ResetOnSpawn = false end)
		inst.gui.Parent = _deps.playerGui
	end

	-- ★ 4) current==name：ちらつき防止＆状態保護モード
	if _current == name then
		-- 言語だけは即反映
		applyLangIfPossible(inst, langHint)

		-- payload が「空 or langのみ」なら setData は呼ばない（既存 state を保護）
		if p and hasNonLangFields(p) then
			if type(inst.setData) == "function" then
				local okSD, errSD = pcall(function() inst:setData(p) end)
				if not okSD then LOG.warn("setData(same-screen) failed: %s", tostring(errSD)) end
			end
			updateOrShow(inst, p)  -- 有意データがあるなら渡す
		else
			updateOrShow(inst, nil) -- 有意データがない → 既存状態で再描画
		end

		LOG.debug("Router.show updated same screen for %s (protected)", name)
		return
	end

	-- 5) 全画面を安全に非表示（別画面に切替時のみ）
	for _, e in pairs(_instances) do
		if e and e.gui then setGuiActive(e.gui, false) end
	end

	-- 6) 言語は最優先で即時適用
	applyLangIfPossible(inst, langHint)

	-- 7) setData は payload が有意データを持つ場合のみ
	if p and hasNonLangFields(p) and type(inst.setData) == "function" then
		local okSD, errSD = pcall(function() inst:setData(p) end)
		if not okSD then LOG.warn("setData failed for %s | %s", tostring(name), tostring(errSD)) end
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
		local okShow, errShow = pcall(function() inst:show(p) end)
		if not okShow then LOG.warn("show method failed for %s | %s", tostring(name), tostring(errShow)) end
	end

	-- 10) 最終的に可視化を担保
	if inst.gui then setGuiActive(inst.gui, true) end
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

-- 明示的にインスタンスを取得したい場合
function Router.ensure(name)
	return (ensure(name))
end

return Router
