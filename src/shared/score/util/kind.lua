-- ReplicatedStorage/SharedModules/score/util/kind.lua
-- v0.9.3-S3  kind 正規化（英名へ統一 / 後方互換の別名を広めに吸収）

local VALID_KIND = { bright=true, seed=true, ribbon=true, chaff=true }

-- 後方互換の別名（英/和/ローマ字・大小文字を吸収）
local KIND_ALIAS = {
	-- 英別名
	light = "bright",

	-- ローマ字（和名）
	hikari = "bright",
	tane   = "seed",
	tan    = "ribbon",
	kasu   = "chaff",

	-- 日本語（代表的に使われがちな表記）
	["光"]     = "bright",
	["種"]     = "seed",
	["短冊"]   = "ribbon",
	["カス"]   = "chaff",
	["かす"]   = "chaff",
	["タネ"]   = "seed",
	["たね"]   = "seed",
	["タン"]   = "ribbon",
	["たん"]   = "ribbon",
}

local M = {}

-- 前後空白除去＋小文字化
local function _canon(s:any): string?
	if type(s) ~= "string" then return nil end
	-- 前後空白
	s = string.gsub(s, "^%s+", "")
	s = string.gsub(s, "%s+$", "")
	if #s == 0 then return nil end
	-- 小文字
	s = string.lower(s)
	return s
end

-- k を英名に正規化して返す（不正は nil）
function M.normKind(k:any): string?
	local key = _canon(k)
	if not key then return nil end
	-- そのまま有効？
	if VALID_KIND[key] then return key end
	-- 別名を英名へ
	local aliased = KIND_ALIAS[key]
	if aliased and VALID_KIND[aliased] then
		return aliased
	end
	return nil
end

-- 補助：英名かどうか
function M.isValid(k:any): boolean
	return M.normKind(k) ~= nil
end

-- 補助：入力が不正なら fallback を返す（fallback も正規化）
function M.ensureKind(k:any, fallback:any): string?
	return M.normKind(k) or M.normKind(fallback)
end

return M
