-- SharedModules/Scoring.lua
-- v0.9.0 役採点＋祭事（Matsuri）上乗せ対応
-- I/F:
--   S.evaluate(takenCards: {Card}, state?: table) -> (totalScore: number, roles: table, detail: { mon: number, pts: number })
-- 備考:
--   ・従来どおり「総スコア = 文(mon) × 点(pts)」
--   ・祭事は「成立した役」に応じて文/点へ加算（= レベル×係数）
--   ・state を渡さない場合は従来スコア（祭事なし）で動作

local RS = game:GetService("ReplicatedStorage")
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))

local S = {}

--========================
-- 基本テーブル
--========================

-- 役 → 文（Mon） ＝ 従来の基礎点を「文」とみなす
local ROLE_MON = {
	five_bright = 10, four_bright = 8, rain_four_bright = 7, three_bright = 5,
	inoshikacho = 5, red_ribbon = 5, blue_ribbon = 5,
	seeds = 1, ribbons = 1, chaffs = 1,
	hanami = 5, tsukimi = 5,
}

-- 札 → 点（Pts）重み：調整しやすいように種別ごとに係数を持つ
-- 例）光=5, たね=2, たん=2, かす=1
local CARD_PTS = { bright=5, seed=2, ribbon=2, chaff=1 }

--========================
-- 祭事（Matsuri）係数テーブル
--========================
--   [festivalId] = { mult_per_lv, pts_per_lv }
local MATSURI_COEFF = {
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

-- 役コード（Scoring内部のキー）→ 抽象役ID（yaku_*）
local ROLE_TO_YAKU = {
	chaffs        = "yaku_kasu",
	ribbons       = "yaku_tanzaku",
	seeds         = "yaku_tane",
	red_ribbon    = "yaku_akatan",
	blue_ribbon   = "yaku_aotan",
	inoshikacho   = "yaku_inoshikacho",
	hanami        = "yaku_hanami",
	tsukimi       = "yaku_tsukimi",
	three_bright  = "yaku_sanko",
	-- four_bright / rain_four_bright は対象外
	five_bright   = "yaku_goko",
}

-- 抽象役ID → 関連する祭事ID（複数可）
local YAKU_TO_SAI = {
	yaku_kasu          = { "sai_kasu" },
	yaku_tanzaku       = { "sai_tanzaku" },
	yaku_tane          = { "sai_tane" },
	yaku_akatan        = { "sai_akatan",  "sai_tanzaku" },
	yaku_aotan         = { "sai_aotan",   "sai_tanzaku" },
	yaku_inoshikacho   = { "sai_inoshika" },
	yaku_hanami        = { "sai_hanami" },
	yaku_tsukimi       = { "sai_tsukimi" },
	yaku_sanko         = { "sai_sanko" },
	yaku_goko          = { "sai_goko" },
}

--========================
-- ユーティリティ
--========================
local function counts(cards)
	local c = {bright=0, seed=0, ribbon=0, chaff=0, months={}, tags={}}
	for _,card in ipairs(cards or {}) do
		c[card.kind] += 1
		c.months[card.month] = (c.months[card.month] or 0) + 1
		if card.tags then
			for t,_ in pairs(card.tags) do
				c.tags[t] = (c.tags[t] or 0) + 1
			end
		end
	end
	return c
end

--========================
-- メイン：採点
--========================
-- 戻り値： totalScore, rolesTable, detailTable{ mon=文合計, pts=点合計 }
function S.evaluate(takenCards, state)
	local c = counts(takenCards)
	local roles = {}
	local mon = 0  -- 文（役の合計）

	-- 光系
	if c.bright == 5 then roles.five_bright = ROLE_MON.five_bright
	elseif c.bright == 4 then
		if c.tags["rain"] then roles.rain_four_bright = ROLE_MON.rain_four_bright
		else roles.four_bright = ROLE_MON.four_bright end
	elseif c.bright == 3 and not c.tags["rain"] then
		roles.three_bright = ROLE_MON.three_bright
	end

	-- 名前直接（猪鹿蝶）
	local has = {}
	for _,card in ipairs(takenCards or {}) do has[card.name or ""] = true end
	if has["猪"] and has["鹿"] and has["蝶"] then
		roles.inoshikacho = ROLE_MON.inoshikacho
	end

	-- 赤短（1,2,3 の 赤+字あり）
	local ok_red = 0
	for _,m in ipairs({1,2,3}) do
		for _,card in ipairs(takenCards or {}) do
			if card.month==m and card.kind=="ribbon" and card.tags and card.tags["aka"] and card.tags["jiari"] then
				ok_red += 1; break
			end
		end
	end
	if ok_red==3 then roles.red_ribbon = ROLE_MON.red_ribbon end

	-- 青短（6,9,10 の 青+字あり）
	local ok_blue = 0
	for _,m in ipairs({6,9,10}) do
		for _,card in ipairs(takenCards or {}) do
			if card.month==m and card.kind=="ribbon" and card.tags and card.tags["ao"] and card.tags["jiari"] then
				ok_blue += 1; break
			end
		end
	end
	if ok_blue==3 then roles.blue_ribbon = ROLE_MON.blue_ribbon end

	-- 花見/月見
	if has["桜に幕"] and has["盃"] then roles.hanami = ROLE_MON.hanami end
	if has["芒に月"] and has["盃"] then roles.tsukimi = ROLE_MON.tsukimi end

	-- たね/たん/かす（閾値：5/5/10）
	if c.seed   >= 5 then roles.seeds   = ROLE_MON.seeds   end
	if c.ribbon >= 5 then roles.ribbons = ROLE_MON.ribbons end
	if c.chaff  >=10 then roles.chaffs  = ROLE_MON.chaffs  end

	-- 文合算
	for _,v in pairs(roles) do mon += v end

	-- 札 → 点合算
	local pts = 0
	for kind,count in pairs({bright=c.bright, seed=c.seed, ribbon=c.ribbon, chaff=c.chaff}) do
		local w = CARD_PTS[kind] or 0
		pts += w * (count or 0)
	end

	--========================
	-- 祭事の上乗せ（成立役に応じて文/点へ加算）
	--========================
	if typeof(state) == "table" then
		local levels = RunDeckUtil.getMatsuriLevels(state) or {}
		
		if next(levels) ~= nil then
			-- 成立役 → yaku_* のリストを作る
			local yakuList = {}
			for roleKey, v in pairs(roles) do
				if v and v > 0 then
					local yaku = ROLE_TO_YAKU[roleKey]
					if yaku then table.insert(yakuList, yaku) end
				end
			end

			-- yaku_* ごとに紐づく祭事を見て加算
			for _, yakuId in ipairs(yakuList) do
				local festivals = YAKU_TO_SAI[yakuId]
				if festivals then
					for _, fid in ipairs(festivals) do
						local lv = tonumber(levels[fid] or 0) or 0
						if lv > 0 then
							local coeff = MATSURI_COEFF[fid]
							if coeff then
								local multPerLv, ptsPerLv = coeff[1] or 0, coeff[2] or 0
								mon += (lv * multPerLv)
								pts += (lv * ptsPerLv)
							end
						end
					end
				end
			end
		end
	end

	-- 総スコア = 文 × 点
	local total = mon * pts
	return total, roles, { mon = mon, pts = pts }
end

return S
