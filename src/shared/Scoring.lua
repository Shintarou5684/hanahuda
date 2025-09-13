-- SharedModules/Scoring.lua
-- v0.9.3 役採点＋祭事（Matsuri）＋干支（寅）対応／タグ配列対応／短冊(赤/青)の厳密判定
-- I/F:
--   S.evaluate(takenCards: {Card}, state?: table) -> (totalScore: number, roles: table, detail: { mon: number, pts: number })
-- 備考:
--   ・「総スコア = 文(mon) × 点(pts)」
--   ・祭事は「成立した役」に応じて文/点へ加算（= レベル×係数）
--   ・寅（干支/Kito）は総Ptsに Lv×1 を加算（役の有無に依存しない）
--   ・全札取得（バフなし）の基準値：文=38, pts=87 → 総スコア=3306

local RS = game:GetService("ReplicatedStorage")
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))

local S = {}

--========================
-- 基本テーブル
--========================
local ROLE_MON = {
	five_bright = 10, four_bright = 8, rain_four_bright = 7, three_bright = 5,
	inoshikacho = 5, red_ribbon = 5, blue_ribbon = 5,
	seeds = 1, ribbons = 1, chaffs = 1,
	hanami = 5, tsukimi = 5,
}

-- 1枚あたりpts
local CARD_PTS = { bright=5, seed=2, ribbon=2, chaff=1 }

-- 祭事（festivalId → { mult_per_lv, pts_per_lv }）
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

-- 役キー → yaku_*
local ROLE_TO_YAKU = {
	chaffs="yaku_kasu", ribbons="yaku_tanzaku", seeds="yaku_tane",
	red_ribbon="yaku_akatan", blue_ribbon="yaku_aotan",
	inoshikacho="yaku_inoshikacho", hanami="yaku_hanami", tsukimi="yaku_tsukimi",
	three_bright="yaku_sanko", five_bright="yaku_goko",
}

-- yaku_* → 祭事ID
local YAKU_TO_SAI = {
	yaku_kasu={"sai_kasu"}, yaku_tanzaku={"sai_tanzaku"}, yaku_tane={"sai_tane"},
	yaku_akatan={"sai_akatan","sai_tanzaku"}, yaku_aotan={"sai_aotan","sai_tanzaku"},
	yaku_inoshikacho={"sai_inoshika"}, yaku_hanami={"sai_hanami"}, yaku_tsukimi={"sai_tsukimi"},
	yaku_sanko={"sai_sanko"}, yaku_goko={"sai_goko"},
}

--========================
-- ユーティリティ
--========================
local VALID_KIND = { bright=true, seed=true, ribbon=true, chaff=true }
local KIND_ALIAS = { kasu="chaff", tane="seed", tan="ribbon", tanzaku="ribbon", hikari="bright", light="bright" }
local function normKind(k)
	if not k then return nil end
	k = KIND_ALIAS[k] or k
	return VALID_KIND[k] and k or nil
end

local function toTagSet(tags)
	local set = {}
	if typeof(tags) == "table" then
		for k,v in pairs(tags) do
			if typeof(k)=="number" then set[v]=true else set[k]=(v==nil) and true or v end
		end
	end
	return set
end

local function hasTags(card, names:{string})
	local set = toTagSet(card and card.tags)
	for _,name in ipairs(names or {}) do
		if not set[name] then return false end
	end
	return true
end

local function counts(cards)
	local c = {bright=0, seed=0, ribbon=0, chaff=0, months={}, tags={}}
	for _,card in ipairs(cards or {}) do
		local k = normKind(card.kind)
		if k then c[k] += 1 end
		if card.month then c.months[card.month] = (c.months[card.month] or 0) + 1 end
		local tset = toTagSet(card.tags)
		for t,_ in pairs(tset) do c.tags[t] = (c.tags[t] or 0) + 1 end
	end
	return c
end

--========================
-- メイン：採点
--========================
function S.evaluate(takenCards, state)
	local c = counts(takenCards)
	local roles, mon = {}, 0

	-- 光系
	if c.bright == 5 then
		roles.five_bright = ROLE_MON.five_bright
	elseif c.bright == 4 then
		if (c.tags["rain"] or 0) > 0 then roles.rain_four_bright = ROLE_MON.rain_four_bright
		else roles.four_bright = ROLE_MON.four_bright end
	elseif c.bright == 3 and (c.tags["rain"] or 0) == 0 then
		roles.three_bright = ROLE_MON.three_bright
	end

	-- 名前直接（猪鹿蝶・花見・月見）
	local hasName = {}
	for _,card in ipairs(takenCards or {}) do
		if card and card.name then hasName[card.name] = true end
	end
	if hasName["猪"] and hasName["鹿"] and hasName["蝶"] then roles.inoshikacho = ROLE_MON.inoshikacho end
	if hasName["桜に幕"] and hasName["盃"] then roles.hanami = ROLE_MON.hanami end
	if hasName["芒に月"] and hasName["盃"] then roles.tsukimi = ROLE_MON.tsukimi end

	-- 赤短（1,2,3 の 赤+字あり）
	do
		local ok = 0
		for _,m in ipairs({1,2,3}) do
			for _,card in ipairs(takenCards or {}) do
				if card.month==m and normKind(card.kind)=="ribbon" and hasTags(card, {"aka","jiari"}) then ok += 1; break end
			end
		end
		if ok==3 then roles.red_ribbon = ROLE_MON.red_ribbon end
	end

	-- 青短（6,9,10 の 青+字あり）
	do
		local ok = 0
		for _,m in ipairs({6,9,10}) do
			for _,card in ipairs(takenCards or {}) do
				if card.month==m and normKind(card.kind)=="ribbon" and hasTags(card, {"ao","jiari"}) then ok += 1; break end
			end
		end
		if ok==3 then roles.blue_ribbon = ROLE_MON.blue_ribbon end
	end

	-- たね/たん/かす（閾値：5/5/10）→ 超過1枚ごとに +1文
	if c.seed   >= 5  then roles.seeds   = ROLE_MON.seeds   + (c.seed   - 5)  end
	if c.ribbon >= 5  then roles.ribbons = ROLE_MON.ribbons + (c.ribbon - 5)  end
	if c.chaff  >= 10 then roles.chaffs  = ROLE_MON.chaffs  + (c.chaff  - 10) end


	-- 文合算
	for _,v in pairs(roles) do mon += v end

	-- 札 → 点合算
	local pts = 0
	for kind,count in pairs({bright=c.bright, seed=c.seed, ribbon=c.ribbon, chaff=c.chaff}) do
		pts += (CARD_PTS[kind] or 0) * (count or 0)
	end

	-- 祭事の上乗せ
	if typeof(state) == "table" then
		local levels = RunDeckUtil.getMatsuriLevels(state) or {}
		if next(levels) ~= nil then
			local yakuList = {}
			for roleKey, v in pairs(roles) do
				if v and v > 0 then
					local yaku = ROLE_TO_YAKU[roleKey]
					if yaku then table.insert(yakuList, yaku) end
				end
			end
			for _, yakuId in ipairs(yakuList) do
				local festivals = YAKU_TO_SAI[yakuId]
				if festivals then
					for _, fid in ipairs(festivals) do
						local lv = tonumber(levels[fid] or 0) or 0
						if lv > 0 then
							local coeff = MATSURI_COEFF[fid]
							if coeff then
								mon += lv * (coeff[1] or 0)
								pts += lv * (coeff[2] or 0)
							end
						end
					end
				end
			end
		end

		-- 干支：寅（Ptsに +1/Lv）
		do
			local kitoLevels = (RunDeckUtil.getKitoLevels and RunDeckUtil.getKitoLevels(state)) or state.kito or {}
			local toraLv = tonumber(kitoLevels.tora or kitoLevels["kito_tora"] or 0) or 0
			if toraLv > 0 then pts += toraLv end
		end
	end

	local total = mon * pts
	return total, roles, { mon = mon, pts = pts }
end

function S.getFestivalStat(fid, level)
	local lv = tonumber(level or 0) or 0
	local coeff = MATSURI_COEFF[fid]
	if not coeff then return 0, 0 end
	return lv * (coeff[1] or 0), lv * (coeff[2] or 0)
end

function S.getFestivalsForYaku(yakuId)
	return YAKU_TO_SAI[yakuId] or {}
end

function S.getKitoPts(effectId, level)
	if effectId == "tora" or effectId == "kito_tora" then
		return tonumber(level or 0) or 0
	end
	return 0
end

return S
