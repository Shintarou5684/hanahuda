-- ReplicatedStorage/SharedModules/CardEngine.lua
-- v0.8.3 カードエンジン（画像コード対応版＋デッキ変換ユーティリティ拡充）
local M = {}

-- 48枚の定義（month=1..12, kind=bright/seed/ribbon/chaff）
-- seed は動物・物を含む。tags で細分類（animal / thing / aka/ao / jiari など）
M.cardsByMonth = {
    [1]  = { {kind="bright", name="松に鶴", tags={"animal","crane"}},
             {kind="ribbon", name="赤短(字あり)", tags={"aka","jiari"}},
             {kind="chaff"}, {kind="chaff"} },

    [2]  = { {kind="seed",   name="鶯", tags={"animal"}},
             {kind="ribbon", name="赤短(字あり)", tags={"aka","jiari"}},
             {kind="chaff"}, {kind="chaff"} },

    [3]  = { {kind="bright", name="桜に幕"},
             {kind="ribbon", name="赤短(字あり)", tags={"aka","jiari"}},
             {kind="chaff"}, {kind="chaff"} },

    [4]  = { {kind="seed",   name="ホトトギス", tags={"animal"}},
             {kind="ribbon", name="赤短(無地)",  tags={"aka"}},
             {kind="chaff"}, {kind="chaff"} },

    [5]  = { {kind="seed",   name="八つ橋", tags={"thing"}},
             {kind="ribbon", name="赤短(無地)", tags={"aka"}},
             {kind="chaff"}, {kind="chaff"} },

    [6]  = { {kind="seed",   name="蝶", tags={"animal"}},
             {kind="ribbon", name="青短(字あり)", tags={"ao","jiari"}},
             {kind="chaff"}, {kind="chaff"} },

    [7]  = { {kind="seed",   name="猪", tags={"animal"}},
             {kind="ribbon", name="赤短(無地)", tags={"aka"}},
             {kind="chaff"}, {kind="chaff"} },

    [8]  = { {kind="bright", name="芒に月"},
             {kind="seed",   name="雁", tags={"animal"}},
             {kind="chaff"}, {kind="chaff"} },

    [9]  = { {kind="seed",   name="盃", tags={"thing","sake"}},
             {kind="ribbon", name="青短(字あり)", tags={"ao","jiari"}},
             {kind="chaff"}, {kind="chaff"} },

    [10] = { {kind="seed",   name="鹿", tags={"animal"}},
             {kind="ribbon", name="青短(字あり)", tags={"ao","jiari"}},
             {kind="chaff"}, {kind="chaff"} },

    [11] = { {kind="bright", name="柳に雨", tags={"rain"}},
             {kind="seed",   name="燕", tags={"animal"}},
             {kind="chaff"}, {kind="chaff"} },

    [12] = { {kind="bright", name="桐に鳳凰", tags={"animal","phoenix"}},
             {kind="chaff"}, {kind="chaff"}, {kind="chaff"} },
}

-- 全48枚のフラットリストを生成
function M.buildDeck()
    local deck = {}
    for m=1,12 do
        for i,c in ipairs(M.cardsByMonth[m]) do
            local card = {
                month = m,
                idx   = i,
                kind  = c.kind,
                name  = c.name,
                tags  = c.tags,
                code  = string.format("%02d%02d", m, i), -- 画像コード
            }
            table.insert(deck, card)
        end
    end
    return deck
end

-- Fisher-Yates シャッフル
function M.shuffle(deck, seed)
    local rng = seed and Random.new(seed) or Random.new()
    for i = #deck, 2, -1 do
        local j = rng:NextInteger(1, i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

-- n枚引く（山の末尾から）
function M.draw(deck, n)
    local hand = {}
    for i=1,n do
        hand[i] = table.remove(deck)
    end
    return hand
end

-- ユーティリティ
function M.toCode(month, idx)
    return string.format("%02d%02d", month, idx)
end

function M.fromCode(code)
    local m = tonumber(code:sub(1,2))
    local i = tonumber(code:sub(3,4))
    return m, i
end

----------------------------------------------------------------
-- 追加ユーティリティ（デッキ途中変換用：最小ブロック）
----------------------------------------------------------------

-- 条件に合うインデックスを収集
function M.collectIndices(deck, predicate)
    local idxs = {}
    for i, c in ipairs(deck) do
        if predicate(c) then
            table.insert(idxs, i)
        end
    end
    return idxs
end

-- デッキ中から条件に合う1枚をランダムに選ぶ（見つからなければ nil）
-- rng は Random 型（任意）。未指定なら math.random を使用。
function M.pickRandomIndex(deck, predicate, rng)
    local idxs = M.collectIndices(deck, predicate)
    if #idxs == 0 then return nil end
    local r = rng and rng:NextInteger(1, #idxs) or math.random(1, #idxs)
    return idxs[r]
end

-- 1枚の kind/tags を安全に更新（tagsは任意）
-- opts.addTags = {"tagA","tagB"} のように追加可能
-- opts.removeTag = "xyz" で一致する単一タグを削除（必要に応じて拡張可）
function M.setKind(card, newKind, opts)
    card.kind = newKind
    if opts and opts.addTags then
        card.tags = card.tags or {}
        for _, t in ipairs(opts.addTags) do
            table.insert(card.tags, t)
        end
    end
    if opts and opts.removeTag then
        if card.tags then
            local out = {}
            for _, t in ipairs(card.tags) do
                if t ~= opts.removeTag then table.insert(out, t) end
            end
            card.tags = out
        end
    end
end

----------------------------------------------------------------
-- v0.8.3 追加ヘルパ（祈祷と屋台表示向け）
----------------------------------------------------------------

-- 種別判定
function M.isBright(card)    return card and card.kind == "bright" end
function M.isNonBright(card) return card and card.kind ~= "bright" end

-- 定義から1枚クローンを生成（code="MMII"）
function M.cloneCardFromCode(code)
    if type(code) ~= "string" or #code < 4 then return nil end
    local m, i = M.fromCode(code)
    if not (m and i) then return nil end
    local defM = M.cardsByMonth[m]
    local def  = defM and defM[i]
    if not def then return nil end
    return {
        month = m,
        idx   = i,
        kind  = def.kind,
        name  = def.name,
        tags  = def.tags and table.clone(def.tags) or nil,
        code  = M.toCode(m, i),
    }
end

-- codes 配列からデッキを再構築（存在しないcodeはスキップ）
function M.buildDeckFromCodes(codes)
    local deck = {}
    for _, code in ipairs(codes or {}) do
        local card = M.cloneCardFromCode(tostring(code))
        if card then table.insert(deck, card) end
    end
    return deck
end

-- 非brightをランダムに1枚brightへ変換。成功時は (true, index) を返す。
function M.convertRandomNonBrightToBright(deck, rng)
    local idx = M.pickRandomIndex(deck, M.isNonBright, rng)
    if not idx then return false, nil end
    local before = deck[idx]
    M.setKind(before, "bright")
    return true, idx
end

-- 内部：柔軟にコード抽出
local function _normalizeCode(v)
    local t = typeof(v)
    if t == "string" or t == "number" then return tostring(v) end
    if t == "table" then
        if v.code then return tostring(v.code) end
        if v.id   then return tostring(v.id)   end
        if v.card then
            local c = v.card
            local ct = typeof(c)
            if ct == "table" and c.id then return tostring(c.id) end
            if ct == "string" or ct == "number" then return tostring(c) end
        end
        if v.month and v.idx then
            local m = tonumber(v.month) or 0
            local i = tonumber(v.idx) or 0
            return string.format("%02d%02d", m, i)
        end
    end
    return "?"
end

-- ★ スナップショット（正本：全置き場合算）— entries に kind を保持
function M.buildSnapshotFromState(state)
    local function appendTo(acc, arr)
        if typeof(arr) ~= "table" then return end
        for _, v in ipairs(arr) do table.insert(acc, v) end
    end

    local all = {}
    if typeof(state) == "table" then
        if typeof(state.run) == "table" then
            appendTo(all, state.run.deck)
            appendTo(all, state.run.hand)
            appendTo(all, state.run.field)
            appendTo(all, state.run.taken)
            appendTo(all, state.run.discard)
            appendTo(all, state.run.grave)
        end
        appendTo(all, state.deck)
        appendTo(all, state.hand)
        appendTo(all, state.field)
        appendTo(all, state.taken)
        appendTo(all, state.discard)
        appendTo(all, state.grave)
    end

    local codes, hist, entries = {}, {}, {}
    for _, v in ipairs(all) do
        local code = _normalizeCode(v)
        local kind = (typeof(v)=="table" and v.kind) or nil
        table.insert(codes, code)
        hist[code] = (hist[code] or 0) + 1
        table.insert(entries, { code = code, kind = kind })
    end
    return { v = 2, count = #codes, codes = codes, histogram = hist, entries = entries }
end

-- ★ deck からのスナップショット（entries付与）
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

-- ★ スナップショットからの復元（entries 優先）
function M.buildDeckFromSnapshot(snap)
    if typeof(snap) ~= "table" then return {} end
    if typeof(snap.entries) == "table" and #snap.entries > 0 then
        local out = {}
        for _, e in ipairs(snap.entries) do
            local card = M.cloneCardFromCode(tostring(e.code))
            if card then
                if e.kind then card.kind = e.kind end
                table.insert(out, card)
            end
        end
        return out
    end
    return M.buildDeckFromCodes(snap.codes or {})
end

return M
