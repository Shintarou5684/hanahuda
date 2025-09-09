-- ReplicatedStorage/SharedModules/ShopDefs.lua
-- v0.8.3（内容は現行のまま）
local ShopDefs = {}

ShopDefs.CATEGORY = { kito="kito", sai="sai", omamori="omamori" }

ShopDefs.WEIGHTS = {
	kito    = 1.0,
	sai     = 0.0,
	omamori = 0.0,
}

ShopDefs.POOLS = {
	kito = {
		{
			id       = "kito_ushi",
			name     = "丑：所持文を2倍",
			category = "kito",
			price    = 5,
			effect   = "kito_ushi",
			icon     = nil,
			descJP   = "所持文を即時2倍（上限あり）。",
			descEN   = "Double your current mon immediately (capped).",
		},
		{
			id       = "kito_tora",
			name     = "寅：取り札の得点+1",
			category = "kito",
			price    = 4,
			effect   = "kito_tora",
			icon     = nil,
			descJP   = "以後、取り札の得点+1（恒常バフ／スタック可）。",
			descEN   = "Permanent: taken cards score +1 (stackable).",
		},
		{
			id       = "kito_tori",
			name     = "酉：1枚を光札に変換",
			category = "kito",
			price    = 6,
			effect   = "kito_tori",
			icon     = nil,
			descJP   = "ランのデッキからランダム1枚を光札へ変換（候補無しなら次ラウンド開始時に1枚変換のバフを付与）。",
			descEN   = "Convert one random non-bright card in the run deck to a Bright (or queue a start-of-next-round conversion if none).",
		},
	},
	sai     = {},
	omamori = {},
}

return ShopDefs
