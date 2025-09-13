-- SharedModules/CardEngine.lua
-- v0.9.1 カードエンジン：48枚定義（1103 を ribbon に修正）
local M = {}

-- 48枚の定義
M.cardsByMonth = {
	[1]  = { {kind="bright", name="松に鶴", tags={"animal","crane"}}, {kind="ribbon", name="赤短(字あり)", tags={"aka","jiari"}}, {kind="chaff"}, {kind="chaff"} },
	[2]  = { {kind="seed",   name="鶯", tags={"animal"}},            {kind="ribbon", name="赤短(字あり)", tags={"aka","jiari"}}, {kind="chaff"}, {kind="chaff"} },
	[3]  = { {kind="bright", name="桜に幕"},                          {kind="ribbon", name="赤短(字あり)", tags={"aka","jiari"}}, {kind="chaff"}, {kind="chaff"} },
	[4]  = { {kind="seed",   name="ホトトギス", tags={"animal"}},    {kind="ribbon", name="赤短(無地)",  tags={"aka"}},          {kind="chaff"}, {kind="chaff"} },
	[5]  = { {kind="seed",   name="八つ橋", tags={"thing"}},         {kind="ribbon", name="赤短(無地)",  tags={"aka"}},          {kind="chaff"}, {kind="chaff"} },
	[6]  = { {kind="seed",   name="蝶", tags={"animal"}},            {kind="ribbon", name="青短(字あり)", tags={"ao","jiari"}},  {kind="chaff"}, {kind="chaff"} },
	[7]  = { {kind="seed",   name="猪", tags={"animal"}},            {kind="ribbon", name="赤短(無地)",  tags={"aka"}},          {kind="chaff"}, {kind="chaff"} },
	[8]  = { {kind="bright", name="芒に月"},                          {kind="seed",   name="雁", tags={"animal"}},                {kind="chaff"}, {kind="chaff"} },
	[9]  = { {kind="seed",   name="盃", tags={"thing","sake"}},       {kind="ribbon", name="青短(字あり)", tags={"ao","jiari"}},  {kind="chaff"}, {kind="chaff"} },
	[10] = { {kind="seed",   name="鹿", tags={"animal"}},            {kind="ribbon", name="青短(字あり)", tags={"ao","jiari"}},  {kind="chaff"}, {kind="chaff"} },
	[11] = { {kind="bright", name="柳に雨", tags={"rain"}},          {kind="seed",   name="燕", tags={"animal"}},                {kind="ribbon", name="短冊(無地)"}, {kind="chaff"} }, -- ★ 1103 を ribbon に
	[12] = { {kind="bright", name="桐に鳳凰", tags={"animal","phoenix"}}, {kind="chaff"}, {kind="chaff"}, {kind="chaff"} },
}

-- ===== 基本操作 =====
function M.toCode(month, idx) return string.format("%02d%02d", month, idx) end
function M.fromCode(code) return tonumber(code:sub(1,2)), tonumber(code:sub(3,4)) end

-- 初期48枚
function M.buildDeck()
	local deck = {}
	for m=1,12 do
		for i,c in ipairs(M.cardsByMonth[m]) do
			table.insert(deck, {
				month=m, idx=i, kind=c.kind, name=c.name, tags=c.tags and table.clone(c.tags) or nil,
				code = M.toCode(m,i),
			})
		end
	end
	return deck
end

-- シャッフル
function M.shuffle(deck, seed)
	local rng = seed and Random.new(seed) or Random.new()
	for i = #deck, 2, -1 do
		local j = rng:NextInteger(1, i)
		deck[i], deck[j] = deck[j], deck[i]
	end
end

-- n枚引き（末尾から）
function M.draw(deck, n)
	local hand = {}
	for i=1,n do hand[i] = table.remove(deck) end
	return hand
end

-- ===== スナップショット（唯一の正本：v2 entries） =====
function M.buildSnapshot(deck)
	local codes, hist, entries = {}, {}, {}
	for _, c in ipairs(deck or {}) do
		local code = c.code or M.toCode(c.month, c.idx)
		table.insert(codes, code)
		hist[code] = (hist[code] or 0) + 1
		table.insert(entries, { code = code, kind = c.kind })
	end
	return { v=2, count=#codes, codes=codes, histogram=hist, entries=entries }
end

function M.buildDeckFromSnapshot(snap)
	if typeof(snap) ~= "table" then return {} end
	if typeof(snap.entries) == "table" and #snap.entries > 0 then
		local out = {}
		for _, e in ipairs(snap.entries) do
			local m,i = M.fromCode(tostring(e.code))
			local defM = M.cardsByMonth[m]
			local def  = defM and defM[i]
			if def then
				table.insert(out, {
					month=m, idx=i, kind=e.kind or def.kind, name=def.name,
					tags=def.tags and table.clone(def.tags) or nil, code=M.toCode(m,i),
				})
			end
		end
		return out
	end
	-- v1 後方互換
	local out = {}
	for _, code in ipairs(snap.codes or {}) do
		local m,i = M.fromCode(tostring(code))
		local defM = M.cardsByMonth[m]
		local def  = defM and defM[i]
		if def then
			table.insert(out, {
				month=m, idx=i, kind=def.kind, name=def.name,
				tags=def.tags and table.clone(def.tags) or nil, code=M.toCode(m,i),
			})
		end
	end
	return out
end

-- ===== デッキ変換ユーティリティ =====
local function isNonBright(card) return card and card.kind ~= "bright" end

function M.pickRandomIndex(deck, predicate, rng)
	local idxs = {}
	for i,c in ipairs(deck) do if predicate(c) then table.insert(idxs,i) end end
	if #idxs == 0 then return nil end
	local r = rng and rng:NextInteger(1, #idxs) or math.random(1, #idxs)
	return idxs[r]
end

function M.convertRandomNonBrightToBright(deck, rng)
	local idx = M.pickRandomIndex(deck, isNonBright, rng)
	if not idx then return false, nil end
	deck[idx].kind = "bright"
	return true, idx
end

return M
