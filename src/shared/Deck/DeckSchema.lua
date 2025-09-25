-- SharedModules/Deck/DeckSchema.lua
-- v3 schema 定義 + v2→v3 補完（Load時に一括）
-- ✅ 正式 kind は英語 4 種のみ: "bright" | "seed" | "ribbon" | "chaff"
--    旧/和名は入力時だけエイリアスとして受理し、内部では必ず英語へ正規化

local RS = game:GetService("ReplicatedStorage")

local M = {}

--==============================
-- 定数・規約（確定）
--==============================
M.KINDS = { bright=true, seed=true, ribbon=true, chaff=true } -- ✅英語のみ
M.HIKARI_MONTHS = { [1]=true, [3]=true, [8]=true, [11]=true, [12]=true }

-- 旧/和名 → 正式英語 の対応
local KIND_ALIAS = {
	-- 日本語/旧称 → 英語
	hikari = "bright",
	tane   = "seed",
	tan    = "ribbon",
	kas    = "chaff",

	-- つづり揺れ・互換（念のため）
	light  = "bright",
	bright = "bright",
	seed   = "seed",
	ribbon = "ribbon",
	chaff  = "chaff",
}

-- 公開: kind 正規化（他モジュールでも使えるように）
function M.normalizeKind(k:any): string
	local s = tostring(k or ""):lower()
	local norm = KIND_ALIAS[s]
	if norm and M.KINDS[norm] then return norm end
	-- 不正は chaff にフォールバック（※ここで bright を潰さない）
	return "chaff"
end

--==============================
-- ユーティリティ
--==============================
local function cloneShallow(t)
	if type(t) ~= "table" then return t end
	local out = {}
	for k,v in pairs(t) do out[k] = v end
	return out
end

local function toMonth(n)
	n = tonumber(n)
	if not n then return nil end
	if n >= 1 and n <= 12 then return n end
	return nil
end

local function deriveMonthFromCode(code: string?)
	if type(code) ~= "string" or #code < 2 then return nil end
	local mm = tonumber(string.sub(code, 1, 2))
	return toMonth(mm)
end

--==============================
-- defaults（1枚分）
--==============================
export type CardEntryV3 = {
	code: string,
	kind: string,           -- "bright" | "seed" | "ribbon" | "chaff"
	month: number,          -- 1..12
	tags: {string},         -- []
	effects: {string},      -- []
	imageOverride: string?, -- nil or rbxassetid://...
}

function M.defaults(entryLike: any): CardEntryV3
	local src = typeof(entryLike) == "table" and entryLike or {}
	local dst = {}

	dst.code = (type(src.code) == "string" and src.code) or ""

	dst.month = toMonth(src.month) or deriveMonthFromCode(dst.code) or 1

	-- ✅ kind は必ず英語4種へ正規化（未知は chaff）
	dst.kind = M.normalizeKind(src.kind)

	-- tags
	local tags = src.tags
	if typeof(tags) ~= "table" then tags = {} end
	dst.tags = {}
	for _, v in ipairs(tags) do
		if type(v) == "string" then table.insert(dst.tags, v) end
	end

	-- effects
	local effects = src.effects
	if typeof(effects) ~= "table" then effects = {} end
	dst.effects = {}
	for _, v in ipairs(effects) do
		if type(v) == "string" then table.insert(dst.effects, v) end
	end

	-- imageOverride
	if src.imageOverride == nil or src.imageOverride == "" then
		dst.imageOverride = nil
	else
		dst.imageOverride = tostring(src.imageOverride)
	end

	return dst
end

--==============================
-- デッキ全体の補完（v2→v3）
--==============================
export type DeckV3 = {
	v: number,             -- 3
	codes: {string}?,      -- 既存踏襲
	entries: {CardEntryV3},
	count: number?,
}

function M.normalizeDeck(deckLike: any): DeckV3
	local src = typeof(deckLike) == "table" and deckLike or {}
	local out = {}

	out.v = 3
	out.codes = (typeof(src.codes) == "table") and cloneShallow(src.codes) or nil

	local entries = {}
	if typeof(src.entries) == "table" then
		for i, ent in ipairs(src.entries) do
			entries[i] = M.defaults(ent)
		end
	else
		if typeof(src.codes) == "table" then
			for i, code in ipairs(src.codes) do
				entries[i] = M.defaults({ code = code })
			end
		else
			entries = {}
		end
	end
	out.entries = entries
	out.count = typeof(src.count) == "number" and src.count or #entries

	return out
end

function M.upgradeToV3(deckLike: any)
	local before = typeof(deckLike) == "table" and deckLike or {}
	local after = M.normalizeDeck(before)

	local changed = (before.v ~= 3)
		or (typeof(before.entries) ~= "table")
		or (#(before.entries or {}) ~= #after.entries)

	return after, changed
end

return M
