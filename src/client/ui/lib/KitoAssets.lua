-- StarterPlayerScripts/UI/lib/KitoAssets.lua
-- v1.3.2-diag (ShopDefs S3 DOT 対応)
--  - animal 抽出を frontier(%f) 非依存に変更（kito.<animal>_... でも確実にヒット）
--  - 厳格: "kito.<animal>" 始まりのみ受理
--  - 揺らぎ: ko→nezumi / usagi→u を吸収
--  - 失敗時は parse-miss / icon-miss を軽量ログ

local RS = game:GetService("ReplicatedStorage")

-- Logger（なければ静かに動く）
local Logger do
	local ok, mod = pcall(function()
		return require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
	end)
	Logger = ok and mod or { scope=function() return {info=function()end, warn=function()end} end }
end
local LOG = Logger.scope("KitoAssets")

local M = {}

-- アイコン割当（提供の定義をそのまま使用）
local ICON = {
	nezumi = "rbxassetid://138080758976905", -- 子（ねずみ）
	ushi   = "rbxassetid://98072025493160",  -- 丑
	tora   = "rbxassetid://115144405199625", -- 寅
	u      = "rbxassetid://120370272971127", -- 卯（う・うさぎ）
	tatsu  = "rbxassetid://116982196318196", -- 辰
	mi     = "rbxassetid://74939201459038",  -- 巳（み・へび）
	uma    = "rbxassetid://115729062347409", -- 午
	hitsuji= "rbxassetid://75272554575317",  -- 未
	saru   = "rbxassetid://124239193079274", -- 申
	tori   = "rbxassetid://124637162606181", -- 酉
	inu    = "rbxassetid://119847873888690", -- 戌
	i      = "rbxassetid://127826167495847", -- 亥（い・いのしし）
}

-- ShopDefs の animal トークン → ICON キーへの正規化
--  ko(=子)→nezumi / usagi→u 以外は 1:1
local ALIAS = {
	ko      = "nezumi",
	usagi   = "u",

	-- 1:1（明示）
	ushi="ushi", tora="tora", u="u", tatsu="tatsu", mi="mi",
	uma="uma", hitsuji="hitsuji", saru="saru", tori="tori", inu="inu", i="i",
}

-- 12支ホワイトリスト（安全のため）
local VALID = {
	nezumi=true, ushi=true, tora=true, u=true, tatsu=true, mi=true,
	uma=true, hitsuji=true, saru=true, tori=true, inu=true, i=true,
	ko=true, usagi=true, -- エイリアス側も受理
}

-- "kito.<animal>..." の animal を抽出（%f 使わず堅牢に）
local function parseAnimal(effectId: string): string?
	if type(effectId) ~= "string" then return nil end
	local s = effectId:lower()
	local prefix = "kito."
	if s:sub(1, #prefix) ~= prefix then
		return nil
	end
	-- "kito." 直後から英字のみを animal として抜き出す
	local rest = s:sub(#prefix + 1)
	local animal = rest:match("^([a-z]+)")
	if not animal or animal == "" then
		LOG.warn("[parse-miss] effect=%s (starts with 'kito.' but animal not parsed)", tostring(effectId))
		return nil
	end
	-- エイリアス正規化
	local key = ALIAS[animal] or animal
	-- 知らないキーは弾く（将来拡張時は VALID を更新）
	if not VALID[key] then
		LOG.warn("[parse-miss] effect=%s animal=%s (alias=%s) not in VALID", tostring(effectId), tostring(animal), tostring(key))
		return nil
	end
	return key
end

-- effectId（kito.<animal>...）→ rbxassetid（nil 可）
function M.getIcon(effectId: string): string?
	local key = parseAnimal(effectId)
	if not key then
		-- kito.* 以外 or 解析失敗は静かめに
		return nil
	end
	local asset = ICON[key]
	if not asset then
		LOG.warn("[icon-miss] effect=%s animalKey=%s (no ICON mapping)", tostring(effectId), tostring(key))
	end
	return asset
end

-- 直接キー取得（"tora" 等）。エイリアスも受理
function M.getIconByKey(key: string): string?
	if type(key) ~= "string" or key == "" then return nil end
	local k = ALIAS[key:lower()] or key:lower()
	return ICON[k]
end

-- 起動時ダンプ（軽量）
do
	local count=0; for _ in pairs(ICON) do count+=1 end
	local path = nil; pcall(function() path = script and script:GetFullName() end)
	LOG.info("[boot] v1.3.2-diag | animals=%d | module=%s", count, tostring(path or "<unknown>"))
end

return M
