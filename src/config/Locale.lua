-- ReplicatedStorage/Config/Locale.lua
-- Home/Run 共通の簡易ローカライズ
-- P0-9: 外部I/Fの言語コードを ja/en に統一。jp は警告を出して ja に正規化。
--  1) Locale.en / Locale.ja を公開（Locale.jp は非推奨 alias）
--  2) Locale.t(lang, key) / Locale.get(lang) / Locale.pick(forced)
--  3) Locale.setGlobal(lang) / Locale.getGlobal() / Locale.changed (Signal)
--  4) jp入力時は warn を一度だけ出す（内部では常に ja に変換）
-- P0-10: OSロケール検出のスタイルを簡素化

local Locale = {}

Locale._verbose = false

-- ===== ログユーティリティ =====
local function L(tag, msg, kv)
	if not Locale._verbose then return end
	local parts = {}
	if type(kv)=="table" then
		for k,v in pairs(kv) do table.insert(parts, (tostring(k).."="..tostring(v))) end
	end
	print(("[LANG] %-14s | %s%s"):format(tag, msg or "", (#parts>0) and (" | "..table.concat(parts," ")) or ""))
end

-- ===== jp→ja 統一のための正規化 =====
local _warnedJP = false
local function _warnOnceJP(where)
	if _warnedJP then return end
	_warnedJP = true
	warn(("[Locale] '%s': language code 'jp' is DEPRECATED; using 'ja' instead."):format(where or "norm"))
end

local function _norm(lang:string?)
	local s = tostring(lang or ""):lower()
	if s == "jp" then
		_warnOnceJP("norm")
		return "ja"
	end
	if s == "ja" then return "ja" end
	if s == "en" then return "en" end
	return nil
end

-- ===== OS言語検出 =====
local Players = game:GetService("Players")

local function detectLang()
	local lp = Players.LocalPlayer
	if lp and lp.LocaleId then
		local lid = string.lower(lp.LocaleId)
		local res = (string.sub(lid, 1, 2) == "ja") and "ja" or "en"
		L("detectLang", "OS locale detected", {LocaleId=lid, resolved=res})
		return res
	end
	L("detectLang", "OS locale fallback to EN", {hasLocalPlayer=tostring(lp ~= nil)})
	return "en"
end

function Locale.pick(forced)
	local normalized = _norm(forced)
	local resolved = normalized or detectLang()
	L("pick", "pick language", {forced=forced, normalized=normalized, resolved=resolved})
	return resolved
end

--=== 辞書 ===============================================================
local en = {
	-- Home
	MAIN_TITLE   = "Gokurakuchou",
	SUBTITLE     = "Hanafuda Rogue",
	STATUS_FMT   = "Year:%s  Ryo:%d  Progress: %d/3 Clears",
	BETA_BADGE   = "BETA TEST",

	BTN_START    = "Start Game",
	BTN_SHRINE   = "Shrine (WIP)",
	BTN_ITEMS    = "Inventory (WIP)",
	BTN_SETTINGS = "Settings (WIP)",
	BTN_PATCH    = "PATCH NOTES",
	BTN_CONT     = "CONTINUE (WIP)",
	BTN_SYNCING  = "Syncing…",

	NOTIFY_SHRINE_TITLE   = "Shrine",
	NOTIFY_SHRINE_TEXT    = "Work in progress: Permanent upgrades",
	NOTIFY_ITEMS_TITLE    = "Inventory",
	NOTIFY_ITEMS_TEXT     = "Work in progress: Items",
	NOTIFY_SETTINGS_TITLE = "Settings",
	NOTIFY_SETTINGS_TEXT  = "Work in progress: Sound/UI/Controls",

	CONTINUE_STUB_TITLE = "CONTINUE",
	CONTINUE_STUB_TEXT  = "Coming next (Save not implemented yet)",
	UNSET_YEAR          = "----",

	-- RunScreen
	RUN_GOAL_TITLE       = "Goal",
	RUN_SCORE_TITLE      = "Current Score",
	RUN_TAKEN_TITLE      = "Taken Cards",
	RUN_BTN_CONFIRM      = "Confirm",
	RUN_BTN_REROLL_ALL   = "Reroll (All)",
	RUN_BTN_REROLL_HAND  = "Reroll (Hand)",
	RUN_BTN_YAKU         = "Yaku",
	RUN_HELP_LINE        = "Click hand → field to take. Confirm to finish.",
	RUN_INFO_PLACEHOLDER = "Year:----  Season:--  Target:--  Total:--  Hands:--  Rerolls:--  Mult:--  Bank:--",
	RUN_SCOREBOX_INIT    = "Score: 0\n0Mon × 0Pts\nRoles: --",

	-- Result
	RESULT_FINAL_TITLE = "Congrats!",
	RESULT_FINAL_DESC  = "Run finished. Returning to menu.",
	RESULT_FINAL_BTN   = "Back to Menu",

	-- Toast
	TOAST_TITLE = "Notice",

	-- 空役（P0-8）
	ROLES_NONE = "No roles",

	-- ===== Shop: Items (Locale-first) =====
	SHOP_ITEM_kito_ushi_NAME = "Ox: Double Mon",
	SHOP_ITEM_kito_ushi_DESC = "Double your current mon immediately (capped).",

	SHOP_ITEM_kito_tora_NAME = "Tiger: +1 point on taken cards",
	SHOP_ITEM_kito_tora_DESC = "Permanent: taken cards score +1 (stackable).",

	SHOP_ITEM_kito_tori_NAME = "Rooster: Convert to Bright",
	SHOP_ITEM_kito_tori_DESC = "Convert one non-bright in run config to Bright (or queue +1 for next season).",

	SHOP_ITEM_sai_kasu_NAME  = "Kasu Festival",
	SHOP_ITEM_sai_kasu_DESC  = "Festival: Kasu +1 level (scoring +1x and +1pt per Lv).",

	SHOP_ITEM_sai_tanzaku_NAME = "Tanzaku Festival",
	SHOP_ITEM_sai_tanzaku_DESC = "Festival: Tanzaku +1 level (scoring +1x and +3pt per Lv).",

	SHOP_ITEM_spectral_blackhole_NAME = "Black Hole",
	SHOP_ITEM_spectral_blackhole_DESC = "Instant: All festival levels +1.",

	SHOP_ITEM_tali_dev_plus1_NAME       = "Talisman: +1 pt",
	SHOP_ITEM_tali_dev_plus1_DESC       = "After scoring, add +1 point (dev).",
	SHOP_ITEM_tali_dev_gokou_plus5_NAME = "Talisman: Gokou +5",
	SHOP_ITEM_tali_dev_gokou_plus5_DESC = "+5 points only when Gokou triggers (dev).",
	SHOP_ITEM_tali_dev_sake_plus3_NAME  = "Talisman: Sake +3",
	SHOP_ITEM_tali_dev_sake_plus3_DESC  = "+3 points when Sake is involved (dev).",

	-- ===== Shop: UI (migrated from ShopI18n) =====
	SHOP_UI_TITLE                 = "Shop (MVP)",
	SHOP_UI_VIEW_DECK             = "View Deck",
	SHOP_UI_HIDE_DECK             = "Hide Deck",
	SHOP_UI_REROLL_FMT            = "Reroll (-%d)",
	SHOP_UI_INFO_TITLE            = "Item Info",
	SHOP_UI_INFO_PLACEHOLDER      = "(Hover or click an item)",
	SHOP_UI_DECK_TITLE_FMT        = "Current Deck (%d cards)",
	SHOP_UI_DECK_EMPTY            = "(no cards)",
	SHOP_UI_CLOSE_BTN             = "Close shop and next season",
	SHOP_UI_SUMMARY_CLEARED_FMT   = "Cleared! Total:%d / Target:%d\nReward: %d mon (Have: %d)\n",
	SHOP_UI_SUMMARY_ITEMS_FMT     = "Items: %d",
	SHOP_UI_SUMMARY_MONEY_FMT     = "Money: %d mon",
	SHOP_UI_LABEL_CATEGORY        = "Category: %s",
	SHOP_UI_LABEL_PRICE           = "Price: %s",
	SHOP_UI_NO_DESC               = "(no description)",
	SHOP_UI_INSUFFICIENT_SUFFIX   = " (insufficient)",

	-- Extra (for Talisman UI / toasts)
	SHOP_UI_TALISMAN_BOARD_TITLE  = "Talisman Board",
	SHOP_UI_NO_EMPTY_SLOT         = "No empty slot available",
}

local ja = {
	-- Home
	MAIN_TITLE   = "極楽蝶",
	SUBTITLE     = "Hanafuda Rogue",
	STATUS_FMT   = "年:%s  両:%d  進捗: 通算 %d/3 クリア",
	BETA_BADGE   = "BETA TEST",

	BTN_START    = "スタートゲーム",
	BTN_SHRINE   = "神社（開発中）",
	BTN_ITEMS    = "持ち物（開発中）",
	BTN_SETTINGS = "設定（開発中）",
	BTN_PATCH    = "パッチノート",
	BTN_CONT     = "CONTINUE（開発中）",
	BTN_SYNCING  = "同期中…",

	NOTIFY_SHRINE_TITLE   = "神社",
	NOTIFY_SHRINE_TEXT    = "開発中：恒久強化ショップ",
	NOTIFY_ITEMS_TITLE    = "持ち物",
	NOTIFY_ITEMS_TEXT     = "開発中：所持品一覧",
	NOTIFY_SETTINGS_TITLE = "設定",
	NOTIFY_SETTINGS_TEXT  = "開発中：サウンド/UI/操作",

	CONTINUE_STUB_TITLE = "CONTINUE",
	CONTINUE_STUB_TEXT  = "次回対応（セーブ未実装）",
	UNSET_YEAR          = "----",

	-- RunScreen
	RUN_GOAL_TITLE       = "目標スコア",
	RUN_SCORE_TITLE      = "現在スコア",
	RUN_TAKEN_TITLE      = "取り札",
	RUN_BTN_CONFIRM      = "この手で勝負",
	RUN_BTN_REROLL_ALL   = "全体リロール",
	RUN_BTN_REROLL_HAND  = "手札だけリロール",
	RUN_BTN_YAKU         = "役一覧",
	RUN_HELP_LINE        = "手札→場札をクリックで取得。Confirmで確定。",
	RUN_INFO_PLACEHOLDER = "年:----  季節:--  目標:--  合計:--  残ハンド:--  残リロール:--  倍率:--  Bank:--",
	RUN_SCOREBOX_INIT    = "得点：0\n文0×0点\n役：--",

	-- Result
	RESULT_FINAL_TITLE = "クリアおめでとう！",
	RESULT_FINAL_DESC  = "このランは終了です。メニューに戻ります。",
	RESULT_FINAL_BTN   = "メニューに戻る",

	-- Toast
	TOAST_TITLE = "通知",

	-- 空役（P0-8）
	ROLES_NONE = "役なし",

	-- ===== Shop: Items (Locale-first) =====
	SHOP_ITEM_kito_ushi_NAME = "丑：所持文を2倍",
	SHOP_ITEM_kito_ushi_DESC = "所持文を即時2倍（上限あり）。",

	SHOP_ITEM_kito_tora_NAME = "寅：取り札の得点+1",
	SHOP_ITEM_kito_tora_DESC = "以後、取り札の得点+1（恒常バフ／スタック可）。",

	SHOP_ITEM_kito_tori_NAME = "酉：1枚を光札に変換",
	SHOP_ITEM_kito_tori_DESC = "ラン構成の非brightを1枚brightへ（対象無しなら次季に+1繰越）。",

	SHOP_ITEM_sai_kasu_NAME  = "カス祭り",
	SHOP_ITEM_sai_kasu_DESC  = "カス役に祭事レベル+1（採点時に倍率+1/Lv、点+1/Lv）。",

	SHOP_ITEM_sai_tanzaku_NAME = "短冊祭り",
	SHOP_ITEM_sai_tanzaku_DESC = "短冊役に祭事レベル+1（採点時に倍率+1/Lv、点+3/Lv）。",

	SHOP_ITEM_spectral_blackhole_NAME = "黒天",
	SHOP_ITEM_spectral_blackhole_DESC = "即時：すべての祭事レベルを+1。",

	SHOP_ITEM_tali_dev_plus1_NAME       = "護符：+1点",
	SHOP_ITEM_tali_dev_plus1_DESC       = "採点後、常時+1点を加算（開発用）。",
	SHOP_ITEM_tali_dev_gokou_plus5_NAME = "護符：五光+5",
	SHOP_ITEM_tali_dev_gokou_plus5_DESC = "五光成立時のみ、+5点（開発用）。",
	SHOP_ITEM_tali_dev_sake_plus3_NAME  = "護符：酒+3",
	SHOP_ITEM_tali_dev_sake_plus3_DESC  = "酒が関与したとき、+3点（開発用）。",

	-- ===== Shop: UI (migrated from ShopI18n) =====
	SHOP_UI_TITLE                 = "屋台（MVP）",
	SHOP_UI_VIEW_DECK             = "デッキを見る",
	SHOP_UI_HIDE_DECK             = "デッキを隠す",
	SHOP_UI_REROLL_FMT            = "リロール（-%d 文）",
	SHOP_UI_INFO_TITLE            = "アイテム情報",
	SHOP_UI_INFO_PLACEHOLDER      = "（アイテムにマウスを乗せるか、クリックしてください）",
	SHOP_UI_DECK_TITLE_FMT        = "現在のデッキ（%d 枚）",
	SHOP_UI_DECK_EMPTY            = "(カード無し)",
	SHOP_UI_CLOSE_BTN             = "屋台を閉じて次の季節へ",
	SHOP_UI_SUMMARY_CLEARED_FMT   = "達成！ 合計:%d / 目標:%d\n報酬：%d 文（所持：%d 文）\n",
	SHOP_UI_SUMMARY_ITEMS_FMT     = "商品数: %d 点",
	SHOP_UI_SUMMARY_MONEY_FMT     = "所持文: %d 文",
	SHOP_UI_LABEL_CATEGORY        = "カテゴリ: %s",
	SHOP_UI_LABEL_PRICE           = "価格: %s",
	SHOP_UI_NO_DESC               = "(説明なし)",
	SHOP_UI_INSUFFICIENT_SUFFIX   = "（不足）",

	-- Extra (for Talisman UI / toasts)
	SHOP_UI_TALISMAN_BOARD_TITLE  = "護符ボード",
	SHOP_UI_NO_EMPTY_SLOT         = "空きスロットがありません",
}

Locale._data = { en = en, ja = ja }
Locale.en = en
Locale.ja = ja

-- ▼ 非推奨 alias: Locale.jp
do
	local proxy = {}
	setmetatable(proxy, {
		__index = function(_, k)
			_warnOnceJP("Locale.jp.__index")
			return ja[k]
		end,
		__newindex = function(_, k, v)
			_warnOnceJP("Locale.jp.__newindex")
			ja[k] = v
		end,
		__pairs = function()
			_warnOnceJP("Locale.jp.__pairs")
			return next, ja, nil
		end,
	})
	Locale.jp = proxy
end

--=== 共有言語と変更通知 ================================================
local _current = nil
local _changed = Instance.new("BindableEvent")
Locale.changed = _changed.Event  -- :Fire(newLang)

function Locale.setGlobal(lang)
	local before = _current
	local normalized = _norm(lang)
	if not normalized then
		normalized = detectLang()
	end
	_current = normalized
	L("setGlobal", "set shared language", {in_lang=lang, from=before, to=_current})
	if _current ~= before then
		_changed:Fire(_current)
	end
end

function Locale.getGlobal()
	local res = _current or detectLang()
	L("getGlobal", "get shared language", {stored=_current, resolved=res})
	return res
end

--=== 取得系 ============================================================
function Locale.get(lang)
	local key = _norm(lang) or Locale.pick()
	L("get", "resolve table", {in_lang=lang, resolved=key})
	return Locale._data[key] or Locale._data.en
end

function Locale.t(lang, key)
	local use = _norm(lang) or Locale.getGlobal()
	if Locale._verbose then
		L("t", "translate", {in_lang=lang, use=use, key=key})
	end
	local d = Locale.get(use)
	return (d[key] or Locale._data.en[key] or key)
end

function Locale.normalize(lang)
	return _norm(lang) or "en"
end

return Locale
