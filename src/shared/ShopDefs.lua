-- ReplicatedStorage/SharedModules/ShopDefs.lua
-- v0.9.0 → v0.9.0-DOT S3: 「KITOはドット唯一の真実」へ統一（kito_* を廃止）
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
	-- 祈祷（★DOT ONLY）
	kito = {
		-- 子：最後の祈祷を再発火（記録は更新しない）
		{
			id = "kito.ko", name = "子：前回の祈祷を再発火", category = "kito", price = 4, effect = "kito.ko",
			descJP = "最後に成功した祈祷をもう一度発動（子自身の使用では記録は更新されません）。",
			descEN = "Replay the last successful KITO once more (using Child itself doesn’t update the last).",
		},

		-- 丑：所持文2倍（上限あり）
		{
			id = "kito.ushi", name = "丑：所持文を2倍", category = "kito", price = 5, effect = "kito.ushi",
			descJP = "所持文を即時2倍（上限あり）。",
			descEN = "Double your current mon immediately (capped).",
		},

		-- 寅：取り札の得点+1（恒常／スタック）
		{
			id = "kito.tora", name = "寅：取り札の得点+1", category = "kito", price = 4, effect = "kito.tora",
			descJP = "以後、取り札の得点+1（恒常バフ／スタック可）。",
			descEN = "Permanent: taken cards score +1 (stackable).",
		},

		-- 卯：短冊化（UIで対象選択）
		{
			id = "kito.usagi_ribbon", name = "卯：1枚を短冊に変換", category = "kito", price = 4,
			effect = "kito.usagi_ribbon",
			descJP = "ラン構成の対象札を短冊に変換（対象月に短冊が無い場合は不発）。",
			descEN = "Convert one target to a Ribbon (no effect if that month has no ribbon).",
		},

		-- 辰：写し取り（コピーして最弱候補を上書き）
		{
			id = "kito.tatsu_copy", name = "辰：1枚を写し取り", category = "kito", price = 6,
			effect = "kito.tatsu_copy",
			descJP = "選んだ札をコピーし、デッキ内の最弱候補（カス優先）1枚を上書き（枚数は不変）。",
			descEN = "Duplicate a chosen card and overwrite the weakest deck entry (chaff first). Deck size unchanged.",
		},

		-- 巳：1枚をカスに変換（UIで対象選択）
		{
			id   = "kito.mi_venom", name = "巳：1枚をカス札に変換", category = "kito", price = 2, effect = "kito.mi_venom",
			descJP = "ラン構成の対象札をカス札に変換（適用時に少額の文を即時加算）。",
			descEN = "Convert a target in the run to Chaff (grants a small immediate mon bonus).",
		},

		-- 午：タネ化（UIで対象選択）
		{
			id = "kito.uma_seed", name = "午：1枚をタネに変換", category = "kito", price = 4,
			effect = "kito.uma_seed",
			descJP = "ラン構成の対象札をタネに変換（対象月にタネが無い場合は不発）。",
			descEN = "Convert one target to a Seed (no effect if that month has no seed).",
		},

		-- 未：圧縮（山札から1枚削除、UIで対象選択）
		{
			id = "kito.hitsuji_prune", name = "未：1枚を削除（圧縮）", category = "kito", price = 6,
			effect = "kito.hitsuji_prune",
			descJP = "山札から1枚を削除（デッキ圧縮）。対象未指定なら不発。",
			descEN = "Remove one card from the deck (compression). No-op if no target specified.",
		},

		-- 申：※（将来拡張枠）
		-- { id = "kito.saru_xxx", ... },

		-- 酉：1枚を光札に変換（UIで対象選択）
		{
			id = "kito.tori_brighten", name = "酉：1枚を光札に変換", category = "kito", price = 6, effect = "kito.tori_brighten",
			descJP = "ラン構成の非brightを1枚brightへ（対象無しなら次季に+1繰越）。",
			descEN = "Convert one non-Bright in run config to Bright (or queue +1 for next season).",
		},

		-- 戌：カス化（UIで対象選択）
		{
			id = "kito.inu_chaff2", name = "戌：1枚をカス札に変換", category = "kito", price = 3,
			-- 旧 "kito.inu_chaff" / "kito.inu_two_chaff" を廃止し、正規IDに統一
			effect = "kito.inu_chaff2",
			descJP = "ラン構成の対象札をカス札に変換（既にカス札なら不発）。",
			descEN = "Convert one target in the run to Chaff (no effect if already chaff).",
		},

		-- 亥：酒化（UIで対象選択）
		{
			id = "kito.i_sake", name = "亥：1枚を酒に変換", category = "kito", price = 5,
			effect = "kito.i_sake",
			descJP = "対象札を9月の盃（タネ）に変換します。",
			descEN = "Convert target to September's Seed (Sake).",
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

----------------------------------------------------------------
-- 追加：互換ID → 正規(DOT)ID へ正規化（KITO専用の“揺らぎ吸収”）
--  - KitoAssets は「kito.<animal>...」のみ受理するため、ここで必ず正規化する
--  - 非KITO（sai_*, spectral_* 等）は入力をそのまま返す
----------------------------------------------------------------
function ShopDefs.toCanonicalEffectId(id) --: string
	if type(id) ~= "string" or id == "" then return "" end
	local s = id

	-- 正規（kito. で始まる）ならそのまま
	if s:match("^kito%.") then
		return s
	end

	-- 比較を楽にするため前処理
	local key = s:lower()
	key = key:gsub("%s+", "")           -- 空白除去
	key = key:gsub("\\", "/")           -- 区切り正規化
	key = key:gsub("%.luau?$", "")      -- 拡張子除去（.lua/.luau）
	key = key:gsub("^modules?/", "")    -- パスの先頭ノイズ除去
	key = key:gsub("^effects?/", "")
	key = key:gsub("^kito/", "")
	key = key:gsub("^kito_", "kito.")   -- 先頭の kito_ → kito.

	-- 代表的な旧名/別名のマップ（必要に応じて随時追加）
	local ALIAS = {
		-- 変換系
		["kito_tori_brighten"] = "kito.tori_brighten",
		["tori_brighten"]      = "kito.tori_brighten",
		["tori.brighten"]      = "kito.tori_brighten",

		["kito_mi_venom"]      = "kito.mi_venom",
		["mi_venom"]           = "kito.mi_venom",

		["kito_uma_seed"]      = "kito.uma_seed",
		["uma_seed"]           = "kito.uma_seed",

		["kito_inu_chaff2"]    = "kito.inu_chaff2",
		["inu_chaff2"]         = "kito.inu_chaff2",
		["kito_inu_two_chaff"] = "kito.inu_chaff2",

		["kito_i_sake"]        = "kito.i_sake",
		["i_sake"]             = "kito.i_sake",

		["kito_hitsuji_prune"] = "kito.hitsuji_prune",
		["hitsuji_prune"]      = "kito.hitsuji_prune",

		["kito_tatsu_copy"]    = "kito.tatsu_copy",
		["tatsu_copy"]         = "kito.tatsu_copy",

		["kito_usagi_ribbon"]  = "kito.usagi_ribbon",
		["usagi_ribbon"]       = "kito.usagi_ribbon",

		-- 常駐系
		["kito_tora"]          = "kito.tora",
		["tora"]               = "kito.tora",
		["kito_ushi"]          = "kito.ushi",
		["ushi"]               = "kito.ushi",
		["kito_ko"]            = "kito.ko",
		["ko"]                 = "kito.ko",
	}

	if ALIAS[key] then
		return ALIAS[key]
	end

	-- ここまでで確定できなければ一般形で正規化
	-- 1) アンダースコア → ドット
	key = key:gsub("_", ".")

	-- 2) kito. 接頭辞が無ければ付ける（動物名から始まるケースを包含）
	if not key:find("^kito%.") then
		key = "kito." .. key
	end

	-- 3) ドットの連続は1つに圧縮
	key = key:gsub("%.%.+", ".")

	return key
end

return ShopDefs
