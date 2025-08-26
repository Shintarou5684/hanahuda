-- ReplicatedStorage/SharedModules/CardEngine.lua
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
            local card = {month=m, idx=i, kind=c.kind, name=c.name, tags=c.tags}
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

return M
