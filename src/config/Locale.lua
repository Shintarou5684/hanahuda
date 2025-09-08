-- ReplicatedStorage/Config/Locale.lua
-- Home/Run 共通の簡易ローカライズ（レガシー互換あり）
-- 互換点:
--  1) Locale.en / Locale.jp を公開（Locale[lang].KEY で参照可能）
--  2) 新API: Locale.t(lang, key), Locale.get(lang), Locale.pick(forced)
--  3) 追加API: Locale.setGlobal(lang), Locale.getGlobal()  … 現在言語をクライアント内で共有
--  4) 追加: 簡易ロガー（[LANG] タグ）。Locale._verbose=true で詳細ログON

local Locale = {}

-- ログ詳細レベル（既定: false = 控えめ）
Locale._verbose = false

--=== 内部ユーティリティ =================================================
local function _norm(lang:string?)
	lang = tostring(lang or ""):lower()
	if lang == "jp" or lang == "ja" then return "jp" end
	return (lang == "en") and "en" or nil
end

-- 共通ミニロガー：tag と key=value をそろえて出す
local function L(tag, msg, kv)
	-- kv は {k=v, ...} or nil
	local parts = {}
	if type(kv)=="table" then
		for k,v in pairs(kv) do
			table.insert(parts, (tostring(k).."="..tostring(v)))
		end
	end
	print(("[LANG] %-14s | %s%s"):format(tag, msg or "", (#parts>0) and (" | "..table.concat(parts," ")) or ""))
end

--=== 言語判定（OSロケール） ============================================
local function detectLang()
	local ok, players = pcall(game.GetService, game, "Players")
	if ok and players and players.LocalPlayer and players.LocalPlayer.LocaleId then
		local lid = string.lower(players.LocalPlayer.LocaleId)
		local isJa = (string.sub(lid, 1, 2) == "ja")
		local res = isJa and "jp" or "en"
		L("detectLang", "OS locale detected", {LocaleId=lid, resolved=res})
		return res
	end
	L("detectLang", "OS locale fallback to EN", {ok=ok})
	return "en"
end

-- 明示指定があればそれ、無ければ OS 推定
function Locale.pick(forced)
	local normalized = _norm(forced)
	local resolved = normalized or detectLang()
	L("pick", "pick language", {forced=forced, normalized=normalized, resolved=resolved})
	return resolved
end

--=== 辞書本体 ===========================================================
local en = {
	-- Home
	MAIN_TITLE   = "Gokurakuchou",
	SUBTITLE     = "Hanafuda Rogue",
	STATUS_FMT   = "Year:%s  Ryo:%d  Progress: %d/3 Clears",
	BETA_BADGE   = "BETA TEST",

	BTN_NEW      = "NEW GAME",
	BTN_SHRINE   = "Shrine (WIP)",
	BTN_ITEMS    = "Inventory (WIP)",
	BTN_SETTINGS = "Settings (WIP)",
	BTN_CONT     = "CONTINUE (WIP)",

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
	RUN_HELP_LINE        = "Click hand → field to take. Confirm to finish.",
	RUN_INFO_PLACEHOLDER = "Year:----  Season:--  Target:--  Total:--  Hands:--  Rerolls:--  Mult:--  Bank:--",
	RUN_SCOREBOX_INIT    = "Score: 0\nRoles: --",
}

local jp = {
	-- Home
	MAIN_TITLE   = "極楽蝶",
	SUBTITLE     = "Hanahuda Rogue",
	STATUS_FMT   = "年:%s  両:%d  進捗: 通算 %d/3 クリア",
	BETA_BADGE   = "BETA TEST",

	BTN_NEW      = "NEW GAME",
	BTN_SHRINE   = "神社（開発中）",
	BTN_ITEMS    = "持ち物（開発中）",
	BTN_SETTINGS = "設定（開発中）",
	BTN_CONT     = "CONTINUE（開発中）",

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
	RUN_HELP_LINE        = "手札→場札をクリックで取得。Confirmで確定。",
	RUN_INFO_PLACEHOLDER = "年:----  季節:--  目標:--  合計:--  残ハンド:--  残リロール:--  倍率:--  Bank:--",
	RUN_SCOREBOX_INIT    = "得点：0\n役：--",
}

-- 新実装用の内部保持
Locale._data = { en = en, jp = jp }

-- ★レガシー互換: Locale.en / Locale.jp をそのまま公開
Locale.en = en
Locale.jp = jp

--=== 現在言語の共有（任意・防御付きで呼ばれる想定） =================
local _current = nil  -- "jp"|"en"|nil

function Locale.setGlobal(lang)
	local before = _current
	_current = _norm(lang) or detectLang()
	L("setGlobal", "set shared language", {in_lang=lang, from=before, to=_current})
end

function Locale.getGlobal()
	local res = _current or detectLang()
	L("getGlobal", "get shared language", {stored=_current, resolved=res})
	return res
end

--=== 安全取得／翻訳参照 ================================================
function Locale.get(lang)
	local key = _norm(lang) or Locale.pick()
	L("get", "resolve table", {in_lang=lang, resolved=key})
	return Locale._data[key] or Locale._data.en
end

function Locale.t(lang, key)
	if Locale._verbose then
		L("t", "translate", {in_lang=lang, key=key})
	end
	local d = Locale.get(lang)
	return (d[key] or Locale._data.en[key] or key)
end

return Locale
