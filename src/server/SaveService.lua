-- ServerScriptService/SaveService (ModuleScript)
-- 最小DataStore：bank / year / asc / clears / lang を永続化（version=4）
-- 使い方：
--   local SaveService = require(game.ServerScriptService.SaveService)
--   SaveService.load(player)                    -- PlayerAdded で呼ぶ（メモリに展開）
--   SaveService.addBank(player, 2)              -- 両の加算（dirty化）
--   SaveService.setYear(player, s.year)         -- 年数更新（dirty化）
--   SaveService.bumpYear(player, 25)            -- 年数を加算（例：冬クリアで +25）
--   SaveService.getAscension(player)            -- アセンション値を取得
--   SaveService.setAscension(player, 1)         -- アセンション値を設定（0以上）
--   SaveService.getBaseStartYear(player)        -- 1000 + 100*asc を返す
--   SaveService.ensureBaseYear(player)          -- 年が未設定/0なら基準年に補正
--   SaveService.getClears(player)               -- 通算クリア回数を取得
--   SaveService.setClears(player, n)            -- 通算クリア回数を設定
--   SaveService.bumpClears(player, 1)           -- 通算クリア回数を加算
--   SaveService.getLang(player)                 -- 保存言語("jp"|"en")を取得（保存>OS）
--   SaveService.setLang(player, "jp"|"en")      -- 保存言語を設定（dirty化）
--   SaveService.mergeIntoState(player, state)   -- bank/year/asc/clears/lang を state に反映
--   SaveService.flush(player)                   -- PlayerRemoving で呼ぶ（保存）
--   SaveService.flushAll()                      -- サーバ終了時の保険

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")

--=== 設定 =========================================================
local PROFILE_DS_NAME = "ProfileV1" -- 互換維持：version でのマイグレーション
local USE_MEMORY_IN_STUDIO = true   -- Studioではメモリのみで動かす（API許可が無くても動作）

--=== DataStore / Studioメモリ ====================================
local isStudio = RunService:IsStudio()
local profileDS = nil
if not (isStudio and USE_MEMORY_IN_STUDIO) then
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore(PROFILE_DS_NAME)
	end)
	if ok then
		profileDS = ds
	else
		warn("[SaveService] DataStore init failed; fallback to memory.")
	end
end

--=== キー生成 =====================================================
local function keyForUserId(userId:number): string
	return "u:" .. tostring(userId)
end

--=== デフォルト（version 4：lang 追加） ==========================
local DEFAULT_PROFILE = {
	version = 4,
	bank = 0,       -- 両（永続通貨）
	year = 1000,    -- 初期年（アセンション 0 なら 1000）
	asc  = 0,       -- アセンション（0以上の整数）
	clears = 0,     -- 通算クリア回数
	lang = "en",    -- 保存言語（"jp"|"en"）
}

--=== 内部メモリ（サーバ滞在中のキャッシュ） ======================
type Profile = {
	version:number, bank:number, year:number, asc:number, clears:number,
	lang:string,
}
local Save = {
	_profiles = {} :: {[Player]: Profile},
	_dirty    = {} :: {[Player]: boolean},
}

--=== 補助：OSロケール→"jp"/"en" 推定 =============================
local function detectLangFromLocaleId(plr: Player?): string
	local ok, lid = pcall(function()
		return (plr and plr.LocaleId or "en-us"):lower()
	end)
	if ok and string.sub(lid,1,2) == "ja" then return "jp" end
	return "en"
end

--=== 正規化（不正値の矯正） =====================================
local function normalizeProfile(p:any): Profile
	local out:any = {}
	local v = tonumber(p and p.version) or 1
	out.version = (v < 4) and 4 or math.floor(v)

	out.bank   = math.max(0, math.floor(tonumber(p and p.bank) or 0))
	local y    = tonumber(p and p.year) or 0
	out.year   = math.floor(y)
	out.asc    = math.max(0, math.floor(tonumber(p and p.asc) or 0))
	out.clears = math.max(0, math.floor(tonumber(p and p.clears) or 0))

	local l = tostring(p and p.lang or ""):lower()
	if l ~= "jp" and l ~= "en" then l = "en" end
	out.lang = l

	return out :: Profile
end

--=== 補助：基準年 ================================================
local function baseStartYearForAsc(asc:number): number
	return 1000 + (math.max(0, math.floor(asc or 0)) * 100)
end

--==================================================
-- 公開API
--==================================================

-- プロフィールをロードしてメモリに展開（無ければ既定値）
function Save.load(plr: Player): Profile
	local uid = plr.UserId
	local key = keyForUserId(uid)

	local data = nil
	if profileDS then
		local ok, res = pcall(function()
			return profileDS:GetAsync(key)
		end)
		if ok then data = res else warn("[SaveService] GetAsync failed") end
	end
	-- StudioでAPI無効 or 取得失敗時は data=nil のまま（デフォルト適用）

	local prof: Profile
	if typeof(data) == "table" then
		prof = normalizeProfile(data)
	else
		prof = table.clone(DEFAULT_PROFILE) :: Profile
	end

	-- 簡易マイグレーション：
	-- - version < 4 なら 4 に引き上げ
	-- - year <= 0 の場合は、asc に応じた基準年に補正
	-- - clears 欠損は 0 補完
	-- - lang 欠損は OS ロケールから初期化
	local migrated = false
	if prof.version < 4 then
		prof.version = 4
		migrated = true
	end
	if (prof.year or 0) <= 0 then
		prof.year = baseStartYearForAsc(prof.asc)
		migrated = true
	end
	if prof.clears == nil then
		prof.clears = 0
		migrated = true
	end
	if prof.lang == nil or (prof.lang ~= "jp" and prof.lang ~= "en") then
		prof.lang = detectLangFromLocaleId(plr) -- ★保存なし→OSで初期化
		migrated = true
	end

	Save._profiles[plr] = prof
	Save._dirty[plr]    = migrated -- マイグレーションしたら保存対象に

	return prof
end

-- メモリ上のプロフィール参照（存在しなければ nil）
function Save.get(plr: Player): Profile?
	return Save._profiles[plr]
end

--=== bank =========================================================
function Save.setBank(plr: Player, newBank:number)
	local p = Save._profiles[plr]; if not p then return end
	p.bank = math.max(0, math.floor(tonumber(newBank) or 0))
	Save._dirty[plr] = true
end

function Save.addBank(plr: Player, delta:number)
	local p = Save._profiles[plr]; if not p then return end
	p.bank = math.max(0, math.floor((p.bank or 0) + (tonumber(delta) or 0)))
	Save._dirty[plr] = true
end

--=== year =========================================================
function Save.setYear(plr: Player, newYear:number)
	local p = Save._profiles[plr]; if not p then return end
	p.year = math.max(0, math.floor(tonumber(newYear) or 0))
	Save._dirty[plr] = true
end

function Save.bumpYear(plr: Player, delta:number)
	local p = Save._profiles[plr]; if not p then return end
	local cur = tonumber(p.year or 0) or 0
	p.year = math.max(0, math.floor(cur + (tonumber(delta) or 0)))
	Save._dirty[plr] = true
end

--=== ascension ====================================================
function Save.getAscension(plr: Player): number
	local p = Save._profiles[plr]; if not p then return 0 end
	return math.max(0, math.floor(tonumber(p.asc) or 0))
end

function Save.setAscension(plr: Player, n:number)
	local p = Save._profiles[plr]; if not p then return end
	p.asc = math.max(0, math.floor(tonumber(n) or 0))
	Save._dirty[plr] = true
end

--=== clears =======================================================
function Save.getClears(plr: Player): number
	local p = Save._profiles[plr]; if not p then return 0 end
	return math.max(0, math.floor(tonumber(p.clears) or 0))
end

function Save.setClears(plr: Player, n:number)
	local p = Save._profiles[plr]; if not p then return end
	p.clears = math.max(0, math.floor(tonumber(n) or 0))
	Save._dirty[plr] = true
end

function Save.bumpClears(plr: Player, delta:number)
	local p = Save._profiles[plr]; if not p then return end
	local cur = tonumber(p.clears or 0) or 0
	p.clears = math.max(0, math.floor(cur + (tonumber(delta) or 0)))
	Save._dirty[plr] = true
end

--=== lang =========================================================
function Save.getLang(plr: Player): string
	local p = Save._profiles[plr]
	if p and (p.lang == "jp" or p.lang == "en") then
		return p.lang                      -- ★保存があれば保存優先
	end
	return detectLangFromLocaleId(plr)     -- 保存が無い/不正なら OS 推定
end

function Save.setLang(plr: Player, lang:string)
	if lang ~= "jp" and lang ~= "en" then return end
	local p = Save._profiles[plr]; if not p then return end
	if p.lang ~= lang then
		p.lang = lang
		Save._dirty[plr] = true
	end
end

--=== 基準年ユーティリティ =========================================
function Save.getBaseStartYear(plr: Player): number
	local p = Save._profiles[plr]
	local asc = p and p.asc or 0
	return baseStartYearForAsc(asc)
end

function Save.ensureBaseYear(plr: Player): number
	local p = Save._profiles[plr]; if not p then return DEFAULT_PROFILE.year end
	if (p.year or 0) <= 0 then
		p.year = baseStartYearForAsc(p.asc or 0)
		Save._dirty[plr] = true
	end
	return p.year
end

--=== State へのマージ =============================================
-- UI/状態整合のため、clears は state.totalClears にも反映
function Save.mergeIntoState(plr: Player, state:any)
	local p = Save._profiles[plr]
	if not p then return state end
	state = state or {}
	state.bank        = p.bank
	state.year        = p.year
	state.asc         = p.asc
	state.clears      = p.clears
	state.totalClears = p.clears
	state.lang        = (p.lang == "jp" and "jp") or "en" -- ★有効化
	return state
end

--=== dirty 判定 ===================================================
function Save.isDirty(plr: Player): boolean
	return Save._dirty[plr] == true
end

--=== 保存（DataStore / Studioメモリ） =============================
-- DataStore へ書き出し（最小実装：UpdateAsync 1回 + 軽いリトライ）
function Save.flush(plr: Player)
	local p = Save._profiles[plr]
	if not p then return true end
	if not Save._dirty[plr] then return true end

	-- Studioメモリ運用時はメモリクリアだけ（成功扱い）
	if (isStudio and USE_MEMORY_IN_STUDIO) or (not profileDS) then
		Save._dirty[plr] = false
		return true
	end

	local uid = plr.UserId
	local key = keyForUserId(uid)

	local tries, ok, err = 0, false, nil
	repeat
		tries += 1
		ok, err = pcall(function()
			profileDS:UpdateAsync(key, function(old:any)
				local base = typeof(old) == "table" and old or {}
				base.version = 4
				base.bank    = p.bank   or 0
				base.year    = p.year   or 0
				base.asc     = p.asc    or 0
				base.clears  = p.clears or 0
				base.lang    = (p.lang == "jp" and "jp") or "en"
				return base
			end)
		end)
		if not ok then
			warn(string.format("[SaveService] flush failed (try %d): %s", tries, tostring(err)))
			if tries < 2 then task.wait(0.3) end
		end
	until ok or tries >= 2

	if ok then
		Save._dirty[plr] = false
	end
	return ok
end

-- サーバ終了時などの保険
function Save.flushAll()
	for plr,_ in pairs(Save._profiles) do
		pcall(function() Save.flush(plr) end)
	end
end

return Save
