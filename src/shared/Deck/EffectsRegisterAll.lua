-- ReplicatedStorage/SharedModules/Deck/EffectsRegisterAll.lua
-- Deck/Effects 以下の ModuleScript を自動スキャンして EffectsRegistry に一括登録する
--
-- サポートするモジュールの返り値（3通りすべて対応）:
--   1) ビルダー関数: function(Effects) -> ()           -- ← NEW: Effects.register(...) を内部で呼ぶ
--   2) ハンドラ関数: function(ctx) -> ...              -- 旧来: 直接適用される関数
--   3) 設定テーブル: { id|name, apply|run|exec|call }  -- 旧来: idと関数をテーブルで返す
--
-- 登録キーの決定優先度:
--   テーブル返り値: payload.id > payload.name > module._id > ModuleScript.Name
--   関数返り値(ハンドラ扱い): module._id > ModuleScript.Name
--
-- ビルダー関数を検出した場合は、Effects.register をプロキシして捕捉し、内部で実レジストリへ中継登録する。
-- これにより、モジュール内で "kito.xxx" のような命名規約を自律的に採用可能。

local RS = game:GetService("ReplicatedStorage")

-- Logger は任意（無ければダミー）
local function getLogger()
	local ok, Logger = pcall(function()
		return require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
	end)
	if ok and Logger then
		return Logger.scope("EffectsBootstrap")
	end
	return {
		info  = function(...) end,
		warn  = function(...) warn(string.format(...)) end,
		debug = function(...) end,
	}
end
local LOG = getLogger()

local DeckFolder = script.Parent
local Registry = require(DeckFolder:WaitForChild("EffectsRegistry"))

--====================
-- 内部 util
--====================
local function tryRequire(mod: Instance)
	local ok, res = pcall(require, mod)
	if not ok then
		LOG.warn("require failed: %s | err=%s", mod:GetFullName(), tostring(res))
		return nil
	end
	return res
end

local function pickFn(from:any)
	if type(from) == "function" then
		return from
	end
	if type(from) == "table" then
		for _, k in ipairs({ "apply", "run", "exec", "call" }) do
			if type(from[k]) == "function" then
				return from[k]
			end
		end
	end
	return nil
end

local function pickId(modInst: Instance, payload:any)
	-- 明示指定があれば最優先（テーブル返り値）
	if type(payload) == "table" then
		if type(payload.id) == "string"   and #payload.id   > 0 then return payload.id   end
		if type(payload.name) == "string" and #payload.name > 0 then return payload.name end
	end
	-- モジュールが _id を持っていたら（ハンドラ関数返し時にも参照）
	if type(payload) == "table" and type(payload._id) == "string" and #payload._id > 0 then
		return payload._id
	end
	-- それも無ければ ModuleScript の名前
	return modInst.Name
end

-- Effects.register をプロキシして捕捉し、本体 Registry に中継
local function buildEffectsProxy(modInst: Instance)
	local captured = {}  -- { {id=id, fn=fn}, ... }
	local Effects = {}

	function Effects.register(id: string, fn: any)
		local ok, err = pcall(function()
			Registry.register(id, fn)
		end)
		if not ok then
			LOG.warn("register failed via builder: id=%s mod=%s | err=%s",
				tostring(id), modInst:GetFullName(), tostring(err))
			return
		end
		table.insert(captured, { id = id, fn = fn })
		LOG.info("registered: id=%s from=%s", tostring(id), modInst:GetFullName())
	end

	-- 任意: ビルダーがログを使いたい場合
	function Effects.log(msg: string, ...)
		LOG.debug("[effects:%s] "..tostring(msg), modInst.Name, ...)
	end

	return Effects, captured
end

local function registerAsBuilder(modInst: Instance, builderFn: any): boolean
	local Effects, captured = buildEffectsProxy(modInst)
	local ok, err = pcall(function()
		-- ビルダーは副作用として Effects.register を呼ぶ想定
		builderFn(Effects)
	end)
	if not ok then
		LOG.warn("builder call failed: %s | err=%s", modInst:GetFullName(), tostring(err))
		return false
	end
	return #captured > 0
end

local function registerAsTable(modInst: Instance, payload: table): boolean
	local fn = pickFn(payload)
	if type(fn) ~= "function" then
		LOG.warn("skip (no callable) : %s", modInst:GetFullName())
		return false
	end
	local id = pickId(modInst, payload)
	if type(id) ~= "string" or #id == 0 then
		LOG.warn("skip (no id) : %s", modInst:GetFullName())
		return false
	end
	local ok, err = pcall(function()
		Registry.register(id, fn)
	end)
	if not ok then
		LOG.warn("register failed: id=%s mod=%s | err=%s", tostring(id), modInst:GetFullName(), tostring(err))
		return false
	end
	LOG.info("registered: id=%s from=%s", id, modInst:GetFullName())
	return true
end

local function registerAsHandler(modInst: Instance, handlerFn: any): boolean
	-- 関数返り値が「ctxハンドラ」前提の旧流儀
	local fakePayload = { _id = nil }
	local id = pickId(modInst, fakePayload) -- _id が無ければファイル名
	if type(id) ~= "string" or #id == 0 then
		id = modInst.Name
	end
	local ok, err = pcall(function()
		Registry.register(id, handlerFn)
	end)
	if not ok then
		LOG.warn("register failed: id=%s mod=%s | err=%s", tostring(id), modInst:GetFullName(), tostring(err))
		return false
	end
	LOG.info("registered: id=%s from=%s", id, modInst:GetFullName())
	return true
end

local function registerOne(modInst: Instance)
	local payload = tryRequire(modInst)
	if payload == nil then return false end

	-- 優先: 関数返り値はまず「ビルダー」として試す
	if type(payload) == "function" then
		if registerAsBuilder(modInst, payload) then
			-- ビルダーとして 1件以上の register を捕捉できた
			return true
		end
		-- 捕捉できなかった場合は旧流儀の「ctxハンドラ関数」として登録を試みる
		return registerAsHandler(modInst, payload)
	end

	-- テーブル返り値は従来どおり
	if type(payload) == "table" then
		return registerAsTable(modInst, payload)
	end

	LOG.warn("skip (unsupported export type=%s) : %s", typeof(payload), modInst:GetFullName())
	return false
end

local function isModuleScript(x: Instance): boolean
	return x and x:IsA("ModuleScript")
end

local function scanAndRegister(root: Instance)
	local count = 0
	-- 深さ優先で下にある ModuleScript を全て対象にする
	local stack = { root }
	while #stack > 0 do
		local cur = table.remove(stack)
		for _, ch in ipairs(cur:GetChildren()) do
			if isModuleScript(ch) then
				if registerOne(ch) then
					count += 1
				end
			else
				-- フォルダ/サブツリーも潜る
				table.insert(stack, ch)
			end
		end
	end
	return count
end

--====================
-- エントリ
--====================
-- 規約: Deck/Effects 以下をスキャン（無ければ何もせず成功扱い）
local effectsRoot = DeckFolder:FindFirstChild("Effects")
local total = 0
if effectsRoot then
	total = scanAndRegister(effectsRoot)
else
	LOG.warn("Deck/Effects not found under %s (no effects registered)", DeckFolder:GetFullName())
end

LOG.info("EffectsRegistry initialized: %d module(s) registered", total)

return true
