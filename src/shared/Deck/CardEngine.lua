-- src/shared/Deck/CardEngine.lua
-- v0.9.3 Deck/CardEngine（Deck所有・月札48 + month/idx 同梱スナップショット）
-- 目的：
--  - CardEngine を Deck 階層へ移管（Deck が正本）
--  - snapshot.entries に {code, kind, month, idx} を同梱（v=2のまま後方互換）
--  - buildDeckFromSnapshot() は month/idx を優先、無ければ code から復元

local M = {}

-- 48枚の定義（1103 を ribbon に修正済）
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
	[11] = { {kind="bright", name="柳に雨", tags={"rain"}},          {kind="seed",   name="燕", tags={"animal"}},                {kind="ribbon", name="短冊(無地)"}, {kind="chaff"} },
	[12] = { {kind="bright", name="桐に鳳凰", tags={"animal","phoenix"}}, {kind="chaff"}, {kind="chaff"}, {kind="chaff"} },
}

-- ── 基本ユーティリティ ──────────────────────────
function M.toCode(month, idx) return string.format("%02d%02d", month, idx) end
function M.fromCode(code)
	code = tostring(code or "")
	return tonumber(code:sub(1,2)), tonumber(code:sub(3,4))
end

-- 初期48枚デッキを構築
function M.buildDeck()
	local deck = {}
	for m=1,12 do
		for i,c in ipairs(M.cardsByMonth[m]) do
			table.insert(deck, {
				month=m, idx=i, kind=c.kind, name=c.name,
				tags=c.tags and table.clone(c.tags) or nil,
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

-- ── スナップショット（正本 v2）────────────────────
-- v2: entries = { {code, kind, month, idx}, ... }  ← month/idx を**同梱**
function M.buildSnapshot(deck)
	local codes, hist, entries = {}, {}, {}
	for _, c in ipairs(deck or {}) do
		local m = tonumber(c.month or 0) or 0
		local i = tonumber(c.idx   or 0) or 0
		local code = c.code or ((m>0 and i>0) and M.toCode(m,i) or nil)
		if code then
			table.insert(codes, code)
			hist[code] = (hist[code] or 0) + 1
			table.insert(entries, {
				code  = code,
				kind  = c.kind,
				month = (m>0) and m or nil,
				idx   = (i>0) and i or nil,
			})
		end
	end
	return { v=2, count=#codes, codes=codes, histogram=hist, entries=entries }
end

-- v2 を優先（month/idx を使い、無ければ code から復元）→ 完全デッキへ
function M.buildDeckFromSnapshot(snap)
	if typeof(snap) ~= "table" then return {} end

	-- v2 entries 優先
	if typeof(snap.entries) == "table" and #snap.entries > 0 then
		local out = {}
		for _, e in ipairs(snap.entries) do
			local m = tonumber(e.month or 0) or 0
			local i = tonumber(e.idx   or 0) or 0
			local code = e.code
			if (m<=0 or i<=0) and type(code)=="string" then
				local pm, pi = M.fromCode(code)
				m = (m>0 and m) or pm
				i = (i>0 and i) or pi
			end
			if m and i and m>=1 and m<=12 and i>=1 and i<=4 then
				local def = M.cardsByMonth[m] and M.cardsByMonth[m][i]
				if def then
					table.insert(out, {
						month=m, idx=i,
						kind = e.kind or def.kind,
						name = def.name,
						tags = def.tags and table.clone(def.tags) or nil,
						code = M.toCode(m,i),
					})
				end
			end
		end
		return out
	end

	-- v1 互換（codes 配列のみ）
	local out = {}
	for _, code in ipairs(snap.codes or {}) do
		local m,i = M.fromCode(code)
		local def = (M.cardsByMonth[m] or {})[i]
		if def then
			table.insert(out, {
				month=m, idx=i, kind=def.kind, name=def.name,
				tags=def.tags and table.clone(def.tags) or nil, code=M.toCode(m,i),
			})
		end
	end
	return out
end

-- ── 変換ユーティリティ ───────────────────────────
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
