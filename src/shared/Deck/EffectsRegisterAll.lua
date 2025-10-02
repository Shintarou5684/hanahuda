-- ReplicatedStorage/SharedModules/Deck/EffectsRegisterAll.lua
-- Deck/Effects 以下の ModuleScript を自動スキャンして EffectsRegistry に一括登録する
--
-- サポートするモジュールの返り値（3通りすべて対応）:
--   1) ビルダー関数: function(Effects) -> ()           -- ← 推奨: builder内で Effects.register(...) などを呼ぶ
--   2) ハンドラ関数: function(ctx) -> ...              -- 旧来: 直接適用される関数
--   3) 設定テーブル: { id|name, apply|run|exec|call }  -- 旧来: idと関数をテーブルで返す
--
-- 登録キーの決定優先度:
--   テーブル返り値: payload.id > payload.name > module._id > ModuleScript.Name
--   関数返り値(ハンドラ扱い): module._id > ModuleScript.Name
--
-- 追加: canApply 登録の標準化
--   - Effects.registerCanApply(id, fn) をビルダーからも呼べるようプロキシを提供
--   - 本ファイルでも酉/巳の canApply を中央登録する（UIグレーアウト/サーバ最終判定の唯一の正）
--
-- ★ ドット化ポリシー（KITO専用）:
--   - kito 系の登録キーは「kito.*」のみを受け付ける（kito_ やレガシー別名は登録しない）

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

local Shared     = RS:WaitForChild("SharedModules")
local DeckFolder = script.Parent
local Registry   = require(DeckFolder:WaitForChild("EffectsRegistry"))

-- 依存（canApply用）
local CardEngine = require(Shared:WaitForChild("CardEngine"))

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

-- ★ KITO の登録キーの妥当性チェック（ドット唯一）
local function isKitoDot(id:string?): boolean
	id = tostring(id or "")
	return id:sub(1,5) == "kito."
end
local function isKitoUnderscore(id:string?): boolean
	id = tostring(id or "")
	return id:sub(1,5) == "kito_"
end
local function isKitoLike(id:string?): boolean
	id = tostring(id or "")
	return id:sub(1,4) == "kito"
end

local function assertKitoDotOrReject(id:string, modFullName:string): boolean
	if isKitoUnderscore(id) then
		LOG.warn("[DOT-ONLY] reject underscore id: %s (from %s)", id, modFullName)
		return false
	end
	-- 「kito なのにドットでもアンダーバーでもない」（例: "Tori_Brighten"）は弾く
	if isKitoLike(id) and (not isKitoDot(id)) then
		LOG.warn("[DOT-ONLY] reject non-dot kito id: %s (from %s)", id, modFullName)
		return false
	end
	return true
end

-- Effects.register / registerCanApply をプロキシして捕捉し、本体 Registry に中継
local function buildEffectsProxy(modInst: Instance)
	local captured = {}  -- { {id=id, fn=fn}, ... } ※register だけ捕捉（canApply は捕捉しなくてもOK）
	local Effects = {}

	function Effects.register(id: string, fn: any)
		-- ★ KITO はドットのみ受理
		if not assertKitoDotOrReject(id, modInst:GetFullName()) then
			return
		end
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

	-- ★ canApply のプロキシ（ビルダーがここから登録できる）
	function Effects.registerCanApply(id: string, fn: any)
		-- canApply も KITO の場合はドットのみ受理
		if not assertKitoDotOrReject(id, modInst:GetFullName()) then
			return
		end
		local ok, err = pcall(function()
			Registry.registerCanApply(id, fn)
		end)
		if not ok then
			LOG.warn("registerCanApply failed via builder: id=%s mod=%s | err=%s",
				tostring(id), modInst:GetFullName(), tostring(err))
			return
		end
		LOG.info("registered canApply: id=%s from=%s", tostring(id), modInst:GetFullName())
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
		-- ビルダーは副作用として Effects.register / registerCanApply を呼ぶ想定
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
	-- ★ KITO はドットのみ受理
	if not assertKitoDotOrReject(id, modInst:GetFullName()) then
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
	-- ★ KITO はドットのみ受理（モジュール名由来のレガシー別名は登録しない）
	if not assertKitoDotOrReject(id, modInst:GetFullName()) then
		return false
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
-- canApply（酉/巳）の中央登録（★DOT ONLY）
--====================
local function hasTag(card:any, mark:string): boolean
	if typeof(card) ~= "table" or typeof(card.tags) ~= "table" then return false end
	for _, t in ipairs(card.tags) do
		if t == mark then return true end
	end
	return false
end

local function monthHasBright(month:number?): boolean
	if not month or not CardEngine or not CardEngine.cardsByMonth then return false end
	local defs = CardEngine.cardsByMonth[month]
	if typeof(defs) ~= "table" then return false end
	for _, def in ipairs(defs) do
		if tostring(def.kind or "") == "bright" then
			return true
		end
	end
	return false
end

local function parseMonthFromCard(card:any): number?
	if typeof(card) ~= "table" then return nil end
	if card.month ~= nil then
		local m = tonumber(card.month)
		if typeof(m) == "number" then return m end
	end
	local code = tostring(card.code or "")
	if #code >= 2 then
		local mm = tonumber(string.sub(code, 1, 2))
		if typeof(mm) == "number" then return mm end
	end
	return nil
end

local function registerBuiltinCanApply()
	-- 酉（Brighten）
	local ToriId = "kito.tori_brighten"
	local toriTag = "eff:kito.tori_brighten" -- ★ DOT ONLY: Kito.apply_via_effects 由来の tag 形式に合わせる

	local function toriCan(card:any, _ctx:any)
		if typeof(card) ~= "table" then return false, "not-eligible" end
		if tostring(card.kind or "") == "bright" then
			return false, "already-bright"
		end
		if hasTag(card, toriTag) then
			return false, "already-applied"
		end
		local m = parseMonthFromCard(card)
		if not monthHasBright(m) then
			return false, "month-has-no-bright"
		end
		return true, nil
	end

	-- 巳（Venom）
	local MiId  = "kito.mi_venom"
	local miTag = "eff:kito.mi_venom" -- ★ DOT ONLY

	local function miCan(card:any, _ctx:any)
		if typeof(card) ~= "table" then return false, "not-eligible" end
		if tostring(card.kind or "") == "chaff" then
			return false, "already-chaff"
		end
		if hasTag(card, miTag) then
			return false, "already-applied"
		end
		return true, nil
	end

	-- 登録（存在チェックは EffectsRegistry 側で持つためそのまま上書きOK）
	local ok1, err1 = pcall(function()
		Registry.registerCanApply(ToriId, toriCan)
	end)
	if not ok1 then
		LOG.warn("registerCanApply(tori) failed: %s", tostring(err1))
	end

	local ok2, err2 = pcall(function()
		Registry.registerCanApply(MiId, miCan)
	end)
	if not ok2 then
		LOG.warn("registerCanApply(mi) failed: %s", tostring(err2))
	end

	LOG.info("builtin canApply registered (dot-only): tori + mi")
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

-- canApply 中央登録を最後に実行
registerBuiltinCanApply()

LOG.info("EffectsRegistry initialized (dot-only kito): %d module(s) registered", total)

return true
