-- ServerScriptService/ShopEffects/Spectral.lua
-- v0.9.0 スペクタル効果（MVP）
-- 公開I/F:
--   apply(effectId: string, state: table, ctx: {lang?: "ja"|"en"}) -> (ok:boolean, message:string)
--
-- いまは「黒天（Black Hole）」のみ実装：
--   すべての祭事（Matsuri）レベルを +1

local RS = game:GetService("ReplicatedStorage")
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))

local Spectral = {}

--========================
-- 設定：対応するeffectId
--========================
local ACCEPT_IDS = {
	["spectral_blackhole"] = true,  -- 本命
	["spec_blackhole"]     = true,  -- 略称
	["spectral_kuroten"]   = true,  -- 和名寄り
	["spec_kuroten"]       = true,
	["kito_spec_blackhole"]= true,  -- 互換（当面）
}

--========================
-- 祭事IDの定義（Scoring.luaに合わせる）
--========================
local FESTIVAL_IDS = {
	"sai_kasu",
	"sai_tanzaku",
	"sai_tane",
	"sai_akatan",
	"sai_aotan",
	"sai_inoshika",
	"sai_hanami",
	"sai_tsukimi",
	"sai_sanko",
	"sai_goko",
}

local function msgJa(s) return s end
local function msgEn(s) return s end

--========================
-- メイン
--========================
function Spectral.apply(effectId, state, ctx)
	local id = typeof(effectId) == "string" and string.lower(effectId) or nil
	if not id or not ACCEPT_IDS[id] then
		return false, msgJa(("未対応の効果ID: %s"):format(tostring(effectId)))
	end
	if typeof(state) ~= "table" then
		return false, msgJa("state が無効です")
	end

	-- 黒天：すべての祭事レベルを +1
	for _, fid in ipairs(FESTIVAL_IDS) do
		RunDeckUtil.incMatsuri(state, fid, 1)
	end

	local lang = (ctx and ctx.lang) or "ja"
	if lang == "en" then
		return true, msgEn("Black Hole: All festivals +1")
	else
		return true, msgJa("黒天：すべての祭事を +1")
	end
end

return Spectral
