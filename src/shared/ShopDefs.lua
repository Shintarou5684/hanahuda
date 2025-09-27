-- ReplicatedStorage/SharedModules/ShopDefs.lua
-- v0.9.0 → v0.9.0-TAL S3: 護符カテゴリ（talisman）を追加／Dev3種を出現プールに登録
-- 使い方：
--  ・各カテゴリの出現率は WEIGHTS.<category> を調整（相対重み。合計1でなくてOK）
--  ・商品は POOLS.<category> に配列で追加
--  ・本フェーズ（S3）は UIのみ：購入→「置き先スロ選択状態」へ。RPCはS4で実装

local ShopDefs = {}

ShopDefs.CATEGORY = {
	kito     = "kito",
	sai      = "sai",
	spectral = "spectral",
	omamori  = "omamori",
	talisman = "talisman",   -- ★ 追加：護符カテゴリ
}

-- 出現重み（相対値）
-- ※ talisman は暫定で 0.3（お好みで調整）。S3ではUI確認が目的なので少し高めでもOK
ShopDefs.WEIGHTS = {
	kito     = 1.0,
	sai      = 0.5,
	spectral = 0.2,
	omamori  = 0.0,
	talisman = 0.3,   -- ★ 追加
}

-- 商品プール
ShopDefs.POOLS = {
	-- 祈祷
	kito = {
		{
			id = "kito_ushi", name = "丑：所持文を2倍", category = "kito", price = 5, effect = "kito_ushi",
			descJP = "所持文を即時2倍（上限あり）。",
			descEN = "Double your current mon immediately (capped).",
		},
		{
			id = "kito_tora", name = "寅：取り札の得点+1", category = "kito", price = 4, effect = "kito_tora",
			descJP = "以後、取り札の得点+1（恒常バフ／スタック可）。",
			descEN = "Permanent: taken cards score +1 (stackable).",
		},
		{
			id = "kito_tori", name = "酉：1枚を光札に変換", category = "kito", price = 6, effect = "kito_tori",
			descJP = "ラン構成の非brightを1枚brightへ（対象無しなら次季に+1繰越）。",
			descEN = "Convert one non-bright in run config to Bright (or queue +1 for next season).",
		},
		-- ★ 追加：巳（Venom）
		{
			id   = "kito_mi", name = "巳：1枚をカス札に変換", category = "kito", price = 2, effect = "kito_mi",
			descJP = "ラン構成の対象札をカス札に変換（適用時に少額の文を即時加算）。",
			descEN = "Convert a target in the run to Chaff (grants a small immediate mon bonus).",
		},
	},

	-- 祭事
	sai = {
		-- 既存：カス祭
		{
			id = "sai_kasu", name = "カス祭り", category = "sai", price = 3, effect = "sai_kasu",
			descJP = "カス役に祭事レベル+1（採点時に倍率+1/Lv、点+1/Lv）。",
			descEN = "Festival: Kasu +1 level (scoring +1x and +1pt per Lv).",
		},
		-- 既存：短冊祭
		{
			id = "sai_tanzaku", name = "短冊祭り", category = "sai", price = 4, effect = "sai_tanzaku",
			descJP = "短冊役に祭事レベル+1（採点時に倍率+1/Lv、点+3/Lv）。",
			descEN = "Festival: Tanzaku +1 level (scoring +1x and +3pt per Lv).",
		},

		-- ★ 追加：タネ祭
		{
			id = "sai_seed", name = "タネ祭り", category = "sai", price = 4, effect = "sai_seed",
			descJP = "タネ役に祭事レベル+1（採点時に倍率+1/Lv、点+3/Lv）。",
			descEN = "Festival: Seeds +1 level (scoring +1x and +3pt per Lv).",
		},
		-- ★ 追加：赤短祭
		{
			id = "sai_akatan", name = "赤短祭り", category = "sai", price = 6, effect = "sai_akatan",
			descJP = "赤短役に祭事レベル+1（採点時に倍率+1.5/Lv、点+5/Lv）。",
			descEN = "Festival: Red Ribbons +1 level (+1.5x and +5pt per Lv).",
		},
		-- ★ 追加：青短祭
		{
			id = "sai_aotan", name = "青短祭り", category = "sai", price = 6, effect = "sai_aotan",
			descJP = "青短役に祭事レベル+1（採点時に倍率+1.5/Lv、点+5/Lv）。",
			descEN = "Festival: Blue Ribbons +1 level (+1.5x and +5pt per Lv).",
		},
		-- ★ 追加：猪鹿蝶祭
		{
			id = "sai_inoshika", name = "猪鹿蝶祭り", category = "sai", price = 7, effect = "sai_inoshika",
			descJP = "猪鹿蝶役に祭事レベル+1（採点時に倍率+2/Lv、点+15/Lv）。",
			descEN = "Festival: Boar–Deer–Butterfly +1 level (+2x and +15pt per Lv).",
		},
		-- ★ 追加：花見祭
		{
			id = "sai_hanami", name = "花見祭り", category = "sai", price = 7, effect = "sai_hanami",
			descJP = "「花見で一杯」に祭事レベル+1（採点時に倍率+2/Lv、点+15/Lv）。",
			descEN = "Festival: Hanami Sake +1 level (+2x and +15pt per Lv).",
		},
		-- ★ 追加：月見祭
		{
			id = "sai_tsukimi", name = "月見祭り", category = "sai", price = 7, effect = "sai_tsukimi",
			descJP = "「月見で一杯」に祭事レベル+1（採点時に倍率+2/Lv、点+15/Lv）。",
			descEN = "Festival: Tsukimi Sake +1 level (+2x and +15pt per Lv).",
		},
		-- ★ 追加：三光祭（雨四光も同じ係数で扱う前提）
		{
			id = "sai_sankou", name = "三光祭り", category = "sai", price = 8, effect = "sai_sankou",
			descJP = "三光／雨四光に祭事レベル+1（採点時に倍率+2/Lv、点+20/Lv）。",
			descEN = "Festival: Three Brights / Rain Four +1 level (+2x and +20pt per Lv).",
		},
		-- ★ 追加：四光祭
		{
			id = "sai_shikou", name = "四光祭り", category = "sai", price = 9, effect = "sai_shikou",
			descJP = "四光に祭事レベル+1（採点時に倍率+2/Lv、点+20/Lv）。",
			descEN = "Festival: Four Brights +1 level (+2x and +20pt per Lv).",
		},
		-- ★ 追加：五光祭
		{
			id = "sai_gokou", name = "五光祭り", category = "sai", price = 10, effect = "sai_gokou",
			descJP = "五光に祭事レベル+1（採点時に倍率+3/Lv、点+30/Lv）。",
			descEN = "Festival: Five Brights +1 level (+3x and +30pt per Lv).",
		},
	},

	-- スペクタル（将来系）
	spectral = {
		{
			id = "spectral_blackhole", name = "黒天", category = "spectral", price = 8, effect = "spectral_blackhole",
			descJP = "即時：すべての祭事レベルを+1。",
			descEN = "Instant: All festival levels +1.",
		},
	},

	-- お守り（恒久。今回は出現0）
	omamori = {
		-- 将来：ここに恒久お守りを追加
	},

	-- ★ 新規：護符（このラン限定の装備。ボードに置いた分だけ有効）
	--  注意：S3ではUIのみで、enabled=falseのDefでも構いません。S4以降で配置RPCに接続。
	talisman = {
		{
			id = "tali_dev_plus1", name = "護符：+1点", category = "talisman", price = 2,
			effect = "talisman", talismanId = "dev_plus1",
			descJP = "採点後、常時+1点を加算（開発用）。",
			descEN = "After scoring, add +1 point (dev).",
		},
		{
			id = "tali_dev_gokou_plus5", name = "護符：五光+5", category = "talisman", price = 3,
			effect = "talisman", talismanId = "dev_gokou_plus5",
			descJP = "五光成立時のみ、+5点（開発用）。",
			descEN = "+5 points only when Gokou triggers (dev).",
		},
		{
			id = "tali_dev_sake_plus3", name = "護符：酒+3", category = "talisman", price = 3,
			effect = "talisman", talismanId = "dev_sake_plus3",
			descJP = "酒が関与したとき、+3点（開発用）。",
			descEN = "+3 points when Sake is involved (dev).",
		},
	},
}

return ShopDefs
