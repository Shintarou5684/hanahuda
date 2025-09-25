-- ServerScriptService/SaveService (ModuleScript)
-- 最小DataStore：bank / year / asc / clears / lang / activeRun を永続化（version=4据え置き）
-- 使い方：
--   local SaveService = require(game.ServerScriptService.SaveService)
--   SaveService.load(player)                      -- PlayerAdded で呼ぶ（メモリに展開）
--   SaveService.addBank(player, 2)                -- 両の加算（dirty化）
--   SaveService.setYear(player, s.year)           -- 年数更新（dirty化）
--   SaveService.bumpYear(player, 25)              -- 年数を加算（例：冬クリアで +25）
--   SaveService.getAscension(player)              -- アセンション値を取得
--   SaveService.setAscension(player, 1)           -- アセンション値を設定（0以上）
--   SaveService.getBaseStartYear(player)          -- 1000 + 100*asc を返す
--   SaveService.ensureBaseYear(player)            -- 年が未設定/0なら基準年に補正
--   SaveService.getClears(player)                 -- 通算クリア回数を取得
--   SaveService.setClears(player, n)              -- 通算クリア回数を設定
--   SaveService.bumpClears(player, 1)             -- 通算クリア回数を加算
--   SaveService.getLang(player)                   -- 保存言語("ja"|"en")を取得（保存>OS）
--   SaveService.setLang(player, "ja"|"en")        -- 保存言語を設定（dirty化）
--   SaveService.mergeIntoState(player, state)     -- bank/year/asc/clears/lang を state に反映
--   -- ★ アクティブ・ラン（続き用スナップ）
--   SaveService.getActiveRun(player)              -- 現在のスナップを取得（nil可）
--   SaveService.setActiveRun(player, snap)        -- スナップを設定（dirty化）
--   SaveService.clearActiveRun(player)            -- スナップを破棄（dirty化）
--   SaveService.snapSeasonStart(player, state, n) -- 季節開始スナップ（簡易ヘルパ）
--   SaveService.snapShopEnter(player, state)      -- 屋台入場スナップ（簡易ヘルパ）
--   -- 保存
--   SaveService.flush(player)                     -- PlayerRemoving で呼ぶ（保存）
--   SaveService.flushAll()                        -- サーバ終了時の保険

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
-- SaveService.lua (先頭付近)
local RS = game:GetService("ReplicatedStorage")
-- 旧: local TalismanState = require(RS:WaitForChild("TalismanState"))
local SharedModules = RS:WaitForChild("SharedModules")
local TalismanState = require(SharedModules:WaitForChild("TalismanState"))

-- ▼ 追加：DeckSchema（未配置でも落ちないように pcall で保護）
local DeckSchema = nil
do
	local ok, mod = pcall(function()
		local DeckFolder = SharedModules:FindFirstChild("Deck")
		if DeckFolder then
			return require(DeckFolder:WaitForChild("DeckSchema"))
		end
		return nil
	end)
	if ok then DeckSchema = mod else DeckSchema = nil end
end

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

--=== 言語正規化（外部I/Fは "ja" / "en" に統一） ==================
local function normLang(s:any): string
	s = tostring(s or ""):lower()
	if s == "jp" or s == "ja" then return "ja" end
	return "en"
end

--=== デフォルト（version 4：lang / activeRun を含む） =============
local DEFAULT_PROFILE = {
	version = 4,
	bank = 0,       -- 両（永続通貨）
	year = 1000,    -- 初期年（アセンション 0 なら 1000）
	asc  = 0,       -- アセンション（0以上の整数）
	clears = 0,     -- 通算クリア回数
	lang = "en",    -- 保存言語（"ja"|"en"）
	activeRun = nil,-- ★ 続き用スナップ（{version,season,atShop,bank,mon,deckSeed,shopStock?,effects?, deck?}）
}

--=== 内部メモリ（サーバ滞在中のキャッシュ） ======================
type Profile = {
	version:number, bank:number, year:number, asc:number, clears:number,
	lang:string,
	activeRun:any?, -- ★ 追加
}
local Save = {
	_profiles = {} :: {[Player]: Profile},
	_dirty    = {} :: {[Player]: boolean},
}

--=== 補助：OSロケール→"ja"/"en" 推定 =============================
local function detectLangFromLocaleId(plr: Player?): string
	local ok, lid = pcall(function()
		return (plr and plr.LocaleId or "en-us"):lower()
	end)
	if ok and string.sub(lid,1,2) == "ja" then return "ja" end
	return "en"
end

-- ▼ 追加：activeRun 内の deck/currentDeck を v3 に“自然治癒”させる
local function normalizeActiveRun(ar:any): any
	if type(ar) ~= "table" then return nil end
	-- DeckSchema が無い環境では素通し
	if not DeckSchema then return ar end

	local out = table.clone(ar)
	-- 一般的なフィールド名の両対応
	local deckFieldNames = { "deck", "currentDeck" }
	for _, fname in ipairs(deckFieldNames) do
		if type(out[fname]) == "table" then
			local upgraded, changed = DeckSchema.upgradeToV3(out[fname])
			out[fname] = upgraded
		end
	end
	return out
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

	local rawL = tostring(p and p.lang or ""):lower()
	out.lang = normLang(rawL) -- "jp" 既存値は "ja" に正規化

	-- ★ activeRun はテーブルなら v3 補完をかけて保持（将来 deck を持つ場合に対応）
	if type(p and p.activeRun) == "table" then
		out.activeRun = normalizeActiveRun(p.activeRun)
	else
		out.activeRun = nil
	end

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
	-- - lang 欠損は OS ロケールから初期化（"ja"/"en"）
	-- - "jp" が残っていたら "ja" に正規化
	-- - activeRun は v3 補完をかけたものを保持（将来 deck を含む場合）
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
	if not prof.lang or (prof.lang ~= "ja" and prof.lang ~= "en") then
		prof.lang = detectLangFromLocaleId(plr)
		migrated = true
	end
	local nlang = normLang(prof.lang)
	if nlang ~= prof.lang then
		prof.lang = nlang
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
	if p and (p.lang == "ja" or p.lang == "en") then
		return p.lang
	end
	return detectLangFromLocaleId(plr)
end

function Save.setLang(plr: Player, lang:string)
	lang = normLang(lang)
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
function Save.mergeIntoState(plr: Player, state:any)
	local p = Save._profiles[plr]
	if not p then return state end
	state = state or {}
	state.bank        = p.bank
	state.year        = p.year
	state.asc         = p.asc
	state.clears      = p.clears
	state.totalClears = p.clears
	state.lang        = (p.lang == "ja") and "ja" or "en"

	state.account = state.account or {}
	state.account.talismanUnlock = state.account.talismanUnlock or { unlocked = (p.talismanUnlocked or 2) }

	TalismanState.ensureRunBoard(state)

	return state
end

--=== activeRun（続き用スナップ） =================================
function Save.getActiveRun(plr: Player)
	local p = Save._profiles[plr]; return p and p.activeRun or nil
end

function Save.setActiveRun(plr: Player, snap: table)
	if type(snap) ~= "table" then return end
	local p = Save._profiles[plr]; if not p then return end
	-- ▼ 追加：受け取り時にも v3 補完を適用（将来 deck を持つケース）
	p.activeRun = normalizeActiveRun(snap)
	Save._dirty[plr] = true
end

function Save.clearActiveRun(plr: Player)
	local p = Save._profiles[plr]; if not p then return end
	if p.activeRun ~= nil then
		p.activeRun = nil
		Save._dirty[plr] = true
	end
end

-- 簡易スナップ・ヘルパ（必要最小のフィールドのみ）
function Save.snapSeasonStart(plr: Player, state:any, season:number)
	local s = state or {}
	Save.setActiveRun(plr, {
		version = 1,
		season  = tonumber(season) or 1,
		atShop  = false,
		bank    = tonumber(s.bank or 0) or 0,
		mon     = tonumber(s.mon or 0) or 0,
		deckSeed= s.deckSeed,
		effects = s.effects,            -- { [effectId]=stacks } など（nil可）
		-- deck/currentDeck を持つようになったらここに追加で OK（setActiveRun 側で補完）
	})
end

function Save.snapShopEnter(plr: Player, state:any)
	local s = state or {}
	local shop = s.shop
	Save.setActiveRun(plr, {
		version  = 1,
		season   = tonumber(s.season or 1) or 1,
		atShop   = true,
		bank     = tonumber(s.bank or 0) or 0,
		mon      = tonumber(s.mon or 0) or 0,
		deckSeed = s.deckSeed,
		effects  = s.effects,
		shopStock= (shop and shop.stock) or nil, -- 軽量化のためID/必要最小だけを持つのが理想
		-- deck/currentDeck を持つようになったらここに追加で OK（setActiveRun 側で補完）
	})
end

--=== dirty 判定 ===================================================
function Save.isDirty(plr: Player): boolean
	return Save._dirty[plr] == true
end

--=== 保存（DataStore / Studioメモリ） =============================
function Save.flush(plr: Player)
	local p = Save._profiles[plr]
	if not p then return true end
	if not Save._dirty[plr] then return true end

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
				base.version   = 4
				base.bank      = p.bank    or 0
				base.year      = p.year    or 0
				base.asc       = p.asc     or 0
				base.clears    = p.clears  or 0
				base.lang      = (p.lang == "ja") and "ja" or "en"
				base.activeRun = p.activeRun -- ★ 続きスナップも保存（nil可）
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

function Save.flushAll()
	for plr,_ in pairs(Save._profiles) do
		pcall(function() Save.flush(plr) end)
	end
end

return Save
