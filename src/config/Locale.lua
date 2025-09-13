-- ReplicatedStorage/Config/Locale.lua
-- Home/Run 共通の簡易ローカライズ（レガシー互換あり）
--  1) Locale.en / Locale.jp を公開
--  2) Locale.t(lang, key) / Locale.get(lang) / Locale.pick(forced)
--  3) Locale.setGlobal(lang) / Locale.getGlobal() / Locale.changed (Signal)
--  4) ログ: Locale._verbose = true で詳細

local Locale = {}

Locale._verbose = false

local function _norm(lang:string?)
	lang = tostring(lang or ""):lower()
	if lang == "jp" or lang == "ja" then return "jp" end
	return (lang == "en") and "en" or nil
end

local function L(tag, msg, kv)
	if not Locale._verbose then return end
	local parts = {}
	if type(kv)=="table" then
		for k,v in pairs(kv) do table.insert(parts, (tostring(k).."="..tostring(v))) end
	end
	print(("[LANG] %-14s | %s%s"):format(tag, msg or "", (#parts>0) and (" | "..table.concat(parts," ")) or ""))
end

local function detectLang()
	local ok, players = pcall(game.GetService, game, "Players")
	if ok and players and players.LocalPlayer and players.LocalPlayer.LocaleId then
		local lid = string.lower(players.LocalPlayer.LocaleId)
		local res = (string.sub(lid, 1, 2) == "ja") and "jp" or "en"
		L("detectLang", "OS locale detected", {LocaleId=lid, resolved=res})
		return res
	end
	L("detectLang", "OS locale fallback to EN", {ok=ok})
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
	-- ↓ 3行表示：Score / Mon×Pts / Roles
	RUN_SCOREBOX_INIT    = "Score: 0\n0Mon × 0Pts\nRoles: --",
}

local jp = {
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
	-- ↓ 3行表示：得点 / 文×点 / 役
	RUN_SCOREBOX_INIT    = "得点：0\n文0×0点\n役：--",
}

Locale._data = { en = en, jp = jp }
Locale.en = en
Locale.jp = jp

--=== 共有言語と変更通知 ================================================
local _current = nil
local _changed = Instance.new("BindableEvent")
Locale.changed = _changed.Event  -- :Fire(newLang)

function Locale.setGlobal(lang)
	local before = _current
	_current = _norm(lang) or detectLang()
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

return Locale
