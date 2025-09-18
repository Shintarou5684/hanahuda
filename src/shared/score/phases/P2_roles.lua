-- ReplicatedStorage/SharedModules/score/phases/P2_roles.lua
-- v0.9.3-S4 P2: 役判定 → mon加算 / pts基礎（ledger対応）

local K  = require(script.Parent.Parent.constants)
local P0 = require(script.Parent.P0_normalize)

local P2 = {}

-- 入力: takenCards, counts, ctx?
-- 出力: roles(table), monBase(number), ptsBase(number)
function P2.evaluateRoles(takenCards: {any}?, c: any, ctx: any)
	local roles, mon = {}, 0

	-- 光系
	if c.bright == 5 then
		roles.five_bright = K.ROLE_MON.five_bright
	elseif c.bright == 4 then
		-- 任意の光4枚は常に「四光」扱い（雨札の有無は無視）
		roles.four_bright = K.ROLE_MON.four_bright
	elseif c.bright == 3 and (c.tags["rain"] or 0) == 0 then
		roles.three_bright = K.ROLE_MON.three_bright
	end

	-- 名前直接（猪鹿蝶・花見・月見）
	local hasName = {}
	for _,card in ipairs(takenCards or {}) do
		if card and card.name then hasName[card.name] = true end
	end
	if hasName["猪"] and hasName["鹿"] and hasName["蝶"] then roles.inoshikacho = K.ROLE_MON.inoshikacho end
	if hasName["桜に幕"] and hasName["盃"] then roles.hanami = K.ROLE_MON.hanami end
	if hasName["芒に月"] and hasName["盃"] then roles.tsukimi = K.ROLE_MON.tsukimi end

	-- 赤短（1,2,3 の 赤+字あり）
	do
		local ok = 0
		for _,m in ipairs({1,2,3}) do
			for _,card in ipairs(takenCards or {}) do
				if card.month==m and P0.normKind(card.kind)=="ribbon" and P0.hasTags(card, {"aka","jiari"}) then
					ok += 1; break
				end
			end
		end
		if ok==3 then roles.red_ribbon = K.ROLE_MON.red_ribbon end
	end

	-- 青短（6,9,10 の 青+字あり）
	do
		local ok = 0
		for _,m in ipairs({6,9,10}) do
			for _,card in ipairs(takenCards or {}) do
				if card.month==m and P0.normKind(card.kind)=="ribbon" and P0.hasTags(card, {"ao","jiari"}) then
					ok += 1; break
				end
			end
		end
		if ok==3 then roles.blue_ribbon = K.ROLE_MON.blue_ribbon end
	end

	-- たね/たん/かす（閾値：5/5/10）→ 超過1枚ごとに +1文
	if c.seed   >= 5  then roles.seeds   = K.ROLE_MON.seeds   + (c.seed   - 5)  end
	if c.ribbon >= 5  then roles.ribbons = K.ROLE_MON.ribbons + (c.ribbon - 5)  end
	if c.chaff  >= 10 then roles.chaffs  = K.ROLE_MON.chaffs  + (c.chaff  - 10) end

	-- 文合算
	for _,v in pairs(roles) do mon += v end

	-- 札→点合算（基礎pts）
	local pts = 0
	for kind,count in pairs({bright=c.bright, seed=c.seed, ribbon=c.ribbon, chaff=c.chaff}) do
		pts += (K.CARD_PTS[kind] or 0) * (count or 0)
	end

	-- ledger: P2の寄与（基礎 mon/pts）
	if ctx and typeof(ctx.add) == "function" then
		ctx:add("P2_roles", mon, pts, "base roles & card pts")
	end

	return roles, mon, pts
end

return P2
