-- ReplicatedStorage/SharedModules/score/constants.lua
-- v0.9.3-S3 定数 & 対応表（P3_matsuri_kito 用）
-- 注意：P3 は「倍率を掛ける」のではなく、係数を加点として使います。
--       MATSURI_COEFF = { mon_per_lv, pts_per_lv } として解釈されます。

local K = {}

-- 役ベース文（mon）
K.ROLE_MON = {
	five_bright       = 10,
	four_bright       = 8,
	rain_four_bright  = 7,
	three_bright      = 5,
	inoshikacho       = 5,
	red_ribbon        = 5,
	blue_ribbon       = 5,
	seeds             = 1,
	ribbons           = 1,
	chaffs            = 1,
	hanami            = 5,
	tsukimi           = 5,
}

-- 1枚あたりの点（pts）
K.CARD_PTS = {
	bright = 5,
	seed   = 2,
	ribbon = 2,
	chaff  = 1,
}

-- 祭事（festivalId → { mon_per_lv, pts_per_lv }）
-- ※ 現状の P3 実装では「倍率×」ではなく「加点+」として適用されます。
K.MATSURI_COEFF = {
	sai_kasu      = { 1.0,  1 },  -- カス祭：mon+1/Lv, pts+1/Lv
	sai_tanzaku   = { 1.0,  3 },  -- 短冊祭：mon+1/Lv, pts+3/Lv
	sai_tane      = { 1.0,  3 },  -- タネ祭：mon+1/Lv, pts+3/Lv
	sai_akatan    = { 1.5,  5 },  -- 赤短祭：mon+1.5/Lv, pts+5/Lv
	sai_aotan     = { 1.5,  5 },  -- 青短祭：mon+1.5/Lv, pts+5/Lv
	sai_inoshika  = { 2.0, 15 },  -- 猪鹿蝶祭：mon+2/Lv,   pts+15/Lv
	sai_hanami    = { 2.0, 15 },  -- 花見祭：  mon+2/Lv,   pts+15/Lv
	sai_tsukimi   = { 2.0, 15 },  -- 月見祭：  mon+2/Lv,   pts+15/Lv
	sai_sanko     = { 2.0, 20 },  -- 三光祭/雨四光：mon+2/Lv, pts+20/Lv
	sai_shiko     = { 2.0, 20 },  -- 四光祭： mon+2/Lv, pts+20/Lv
	sai_goko      = { 3.0, 30 },  -- 五光祭： mon+3/Lv, pts+30/Lv
}

-- 役キー（roles のキー）→ yaku_*（内部ヤクID）
K.ROLE_TO_YAKU = {
	chaffs           = "yaku_kasu",
	ribbons          = "yaku_tanzaku",
	seeds            = "yaku_tane",
	red_ribbon       = "yaku_akatan",
	blue_ribbon      = "yaku_aotan",
	inoshikacho      = "yaku_inoshikacho",
	hanami           = "yaku_hanami",
	tsukimi          = "yaku_tsukimi",
	three_bright     = "yaku_sanko",  -- 三光 → 三光祭
	rain_four_bright = "yaku_sanko",  -- 雨四光も三光系に合流
	four_bright      = "yaku_shiko",  -- 四光 → 四光祭
	five_bright      = "yaku_goko",   -- 五光 → 五光祭
}

-- yaku_* → 祭事ID 配列（1役に複数祭事を紐付けたい場合は配列で）
K.YAKU_TO_SAI = {
	yaku_kasu        = { "sai_kasu" },
	yaku_tanzaku     = { "sai_tanzaku" },
	yaku_tane        = { "sai_tane" },
	yaku_akatan      = { "sai_akatan", "sai_tanzaku" }, -- 赤短は短冊役にも寄与
	yaku_aotan       = { "sai_aotan",  "sai_tanzaku" }, -- 青短も短冊に寄与
	yaku_inoshikacho = { "sai_inoshika" },
	yaku_hanami      = { "sai_hanami" },
	yaku_tsukimi     = { "sai_tsukimi" },
	yaku_sanko       = { "sai_sanko" },  -- 三光/雨四光
	yaku_shiko       = { "sai_shiko" },  -- 四光
	yaku_goko        = { "sai_goko" },   -- 五光
}

return K
