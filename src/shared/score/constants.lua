-- ReplicatedStorage/SharedModules/score/constants.lua
-- v0.9.3-S2 定数 & 対応表（現行Scoring.luaと同値）

local K = {}

-- 役ベース文（mon）
K.ROLE_MON = {
	five_bright = 10, four_bright = 8, rain_four_bright = 7, three_bright = 5,
	inoshikacho = 5, red_ribbon = 5, blue_ribbon = 5,
	seeds = 1, ribbons = 1, chaffs = 1,
	hanami = 5, tsukimi = 5,
}

-- 1枚あたりの点（pts）
K.CARD_PTS = { bright=5, seed=2, ribbon=2, chaff=1 }

-- 祭事（festivalId → { mult_per_lv, pts_per_lv }）
K.MATSURI_COEFF = {
	sai_kasu      = { 1.0,  1 },
	sai_tanzaku   = { 1.0,  3 },
	sai_tane      = { 1.0,  3 },
	sai_akatan    = { 1.5,  5 },
	sai_aotan     = { 1.5,  5 },
	sai_inoshika  = { 2.0, 15 },
	sai_hanami    = { 2.0, 15 },
	sai_tsukimi   = { 2.0, 15 },
	sai_sanko     = { 2.0, 20 },
	sai_goko      = { 3.0, 30 },
}

-- 役キー → yaku_*
K.ROLE_TO_YAKU = {
	chaffs="yaku_kasu", ribbons="yaku_tanzaku", seeds="yaku_tane",
	red_ribbon="yaku_akatan", blue_ribbon="yaku_aotan",
	inoshikacho="yaku_inoshikacho", hanami="yaku_hanami", tsukimi="yaku_tsukimi",
	three_bright="yaku_sanko", five_bright="yaku_goko",
}

-- yaku_* → 祭事ID
K.YAKU_TO_SAI = {
	yaku_kasu={"sai_kasu"}, yaku_tanzaku={"sai_tanzaku"}, yaku_tane={"sai_tane"},
	yaku_akatan={"sai_akatan","sai_tanzaku"}, yaku_aotan={"sai_aotan","sai_tanzaku"},
	yaku_inoshikacho={"sai_inoshika"}, yaku_hanami={"sai_hanami"}, yaku_tsukimi={"sai_tsukimi"},
	yaku_sanko={"sai_sanko"}, yaku_goko={"sai_goko"},
}

return K
