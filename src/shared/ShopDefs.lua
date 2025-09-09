-- v0.9.0
local ShopDefs = {}

ShopDefs.CATEGORY = { kito="kito", sai="sai", omamori="omamori" }

ShopDefs.WEIGHTS = { kito=1.0, sai=0.0, omamori=0.0 }

ShopDefs.POOLS = {
	kito = {
		{
			id="kito_ushi", name="丑：所持文を2倍", category="kito", price=5, effect="kito_ushi",
			descJP="所持文を即時2倍（上限あり）。",
			descEN="Double your current mon immediately (capped).",
		},
		{
			id="kito_tora", name="寅：取り札の得点+1", category="kito", price=4, effect="kito_tora",
			descJP="以後、取り札の得点+1（恒常バフ／スタック可）。",
			descEN="Permanent: taken cards score +1 (stackable).",
		},
		{
			id="kito_tori", name="酉：1枚を光札に変換", category="kito", price=6, effect="kito_tori",
			descJP="ラン構成の非brightを1枚brightへ（対象無しなら次季に+1繰越）。",
			descEN="Convert one non-bright in run config to Bright (or queue +1 for next season).",
		},
	},
	sai     = {},
	omamori = {},
}

return ShopDefs
