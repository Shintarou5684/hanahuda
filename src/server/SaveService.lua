-- ServerScriptService/SaveService (ModuleScript)
-- 最小DataStore：bank / year / asc（アセンション）を永続化
-- 使い方：
--   local SaveService = require(game.ServerScriptService.SaveService)
--   SaveService.load(player)                   -- PlayerAdded で呼ぶ（メモリに展開）
--   SaveService.addBank(player, 2)             -- 両の加算（dirty化）
--   SaveService.setYear(player, s.year)        -- 年数更新（dirty化）
--   SaveService.bumpYear(player, 25)           -- 年数を加算（例：冬クリアで +25）
--   SaveService.getAscension(player)           -- アセンション値を取得
--   SaveService.setAscension(player, 1)        -- アセンション値を設定（0以上）
--   SaveService.getBaseStartYear(player)       -- 1000 + 100*asc を返す
--   SaveService.ensureBaseYear(player)         -- 年が未設定/0なら基準年に補正
--   SaveService.flush(player)                  -- PlayerRemoving で呼ぶ（保存）

local DataStoreService = game:GetService("DataStoreService")

-- DataStore 名とキー生成
local PROFILE_DS_NAME = "ProfileV1" -- 既存と同じ名前で互換維持（version フィールドで管理）
local profileDS = DataStoreService:GetDataStore(PROFILE_DS_NAME)
local function keyForUserId(userId:number): string
	return "u:" .. tostring(userId)
end

-- デフォルト値（version 2：asc 追加・year を 1000 に）
local DEFAULT_PROFILE = {
	version = 2,
	bank = 0,     -- 両（永続通貨）
	year = 1000,  -- 初期年（アセンション 0 なら 1000）
	asc  = 0,     -- アセンション（0以上の整数）
}

-- 内部メモリ（サーバ滞在中のキャッシュ）
type Profile = {version:number, bank:number, year:number, asc:number}
local Save = {
	_profiles = {} :: {[Player]: Profile},
	_dirty    = {} :: {[Player]: boolean},
}

-- 正規化（不正値を防いで数値化・下限クリップ）
local function normalizeProfile(p:any): Profile
	local out:any = {}
	local v = tonumber(p and p.version) or 1
	out.version = (v < 2) and 2 or math.floor(v)
	out.bank    = math.max(0, math.floor(tonumber(p and p.bank) or 0))
	-- year は 0 以下なら未初期化とみなし後で補正
	local y = tonumber(p and p.year) or 0
	out.year    = math.floor(y)
	out.asc     = math.max(0, math.floor(tonumber(p and p.asc) or 0))
	return out :: Profile
end

-- 基準年：1000 + 100*asc
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

	local ok, data = pcall(function()
		return profileDS:GetAsync(key)
	end)

	local prof: Profile
	if ok and typeof(data) == "table" then
		prof = normalizeProfile(data)
	else
		prof = table.clone(DEFAULT_PROFILE) :: Profile
	end

	-- 簡易マイグレーション：
	-- - version < 2 なら version=2 に引き上げ
	-- - year <= 0 の場合は、asc に応じた基準年に補正
	local migrated = false
	if prof.version < 2 then
		prof.version = 2
		migrated = true
	end
	if (prof.year or 0) <= 0 then
		prof.year = baseStartYearForAsc(prof.asc)
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

-- 両（bank）を絶対値でセット
function Save.setBank(plr: Player, newBank:number)
	local p = Save._profiles[plr]; if not p then return end
	p.bank = math.max(0, math.floor(tonumber(newBank) or 0))
	Save._dirty[plr] = true
end

-- 両（bank）を加算（負数で減算も可）
function Save.addBank(plr: Player, delta:number)
	local p = Save._profiles[plr]; if not p then return end
	p.bank = math.max(0, math.floor((p.bank or 0) + (tonumber(delta) or 0)))
	Save._dirty[plr] = true
end

-- 年数（year）をセット
function Save.setYear(plr: Player, newYear:number)
	local p = Save._profiles[plr]; if not p then return end
	p.year = math.max(0, math.floor(tonumber(newYear) or 0))
	Save._dirty[plr] = true
end

-- 年数（year）を加算
function Save.bumpYear(plr: Player, delta:number)
	local p = Save._profiles[plr]; if not p then return end
	local cur = tonumber(p.year or 0) or 0
	p.year = math.max(0, math.floor(cur + (tonumber(delta) or 0)))
	Save._dirty[plr] = true
end

-- アセンション：取得/設定
function Save.getAscension(plr: Player): number
	local p = Save._profiles[plr]; if not p then return 0 end
	return math.max(0, math.floor(tonumber(p.asc) or 0))
end

function Save.setAscension(plr: Player, n:number)
	local p = Save._profiles[plr]; if not p then return end
	p.asc = math.max(0, math.floor(tonumber(n) or 0))
	Save._dirty[plr] = true
end

-- 基準年を返す（1000 + 100*asc）
function Save.getBaseStartYear(plr: Player): number
	local p = Save._profiles[plr]
	local asc = p and p.asc or 0
	return baseStartYearForAsc(asc)
end

-- 年が未設定/0なら基準年に補正して返す
function Save.ensureBaseYear(plr: Player): number
	local p = Save._profiles[plr]; if not p then return DEFAULT_PROFILE.year end
	if (p.year or 0) <= 0 then
		p.year = baseStartYearForAsc(p.asc or 0)
		Save._dirty[plr] = true
	end
	return p.year
end

-- 便利：StateHubの状態へ bank/year（必要なら asc も）をマージ
function Save.mergeIntoState(plr: Player, state:any)
	local p = Save._profiles[plr]
	if not p then return state end
	state = state or {}
	state.bank = p.bank
	state.year = p.year
	state.asc  = p.asc
	return state
end

-- dirty かどうか
function Save.isDirty(plr: Player): boolean
	return Save._dirty[plr] == true
end

-- DataStore へ書き出し（最小実装：UpdateAsync 1回 + 軽いリトライ）
function Save.flush(plr: Player)
	local p = Save._profiles[plr]
	if not p then return true end
	if not Save._dirty[plr] then return true end

	local uid = plr.UserId
	local key = keyForUserId(uid)

	local tries, ok, err = 0, false, nil
	repeat
		tries += 1
		ok, err = pcall(function()
			profileDS:UpdateAsync(key, function(old:any)
				-- 古い値があっても bank/year/asc はメモリの最新値で上書き（最小実装）
				local base = typeof(old) == "table" and old or {}
				base.version = 2
				base.bank    = p.bank or 0
				base.year    = p.year or 0
				base.asc     = p.asc or 0
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

-- 便利：全員分 flush（サーバ終了時などで使う想定。任意）
function Save.flushAll()
	for plr,_ in pairs(Save._profiles) do
		pcall(function() Save.flush(plr) end)
	end
end

return Save
