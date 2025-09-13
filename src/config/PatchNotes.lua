-- ReplicatedStorage/Config/PatchNotes.lua
-- 履歴を積み上げ式で管理（RichText対応）
-- PatchNotesModal は title/body を読むだけ。このファイルを更新するだけでUIに反映されます。

local M = {}

-- ========= 注意書き（JP/EN） =========
local NOTICE = {
	jp = [[<b>⚠ 注意（開発中）</b><br/>
<font transparency="0.08">
現在この作品は開発中です。プレイして遊ぶことはできますが、難易度やバランスは仮のものです。
バグの発生、仕様の予告のない変更、到達履歴やセーブデータの削除が行われる可能性があります。
あらかじめご理解のうえ、お楽しみください。
</font>]],
	en = [[<b>⚠ Notice (In Development)</b><br/>
<font transparency="0.08">
This project is under active development. It is playable, but difficulty and balance are provisional.
Bugs may occur, features may change without notice, and your progress/save data may be reset.
Thank you for your understanding.
</font>]],
}

-- 先頭が最新。新バージョンは配列の「先頭」に追加していく。
local ENTRIES = {
	{
		ver  = "v0.9.4",
		date = "2025-09-13",
		changes = {
			{ jp = "パッチノートを別モジュール化（PatchNotesModal.lua）。Homeはボタンだけに簡素化。", en = "Split patch notes into a dedicated module (PatchNotesModal.lua). Home now only triggers the modal." },
			{ jp = "パッチ本文を Config/PatchNotes.lua に集約（このファイル）。",                    en = "Centralized patch content in Config/PatchNotes.lua (this file)." },
			{ jp = "短冊10枚（0102/0202/0302/0402/0502/0602/0702/0902/1002/1103）を定義修正。",     en = "Fixed ribbon definitions to total 10 cards (0102/0202/0302/0402/0502/0602/0702/0902/1002/1103)." },
			{ jp = "役：赤短・青短の判定を実装（各+5文）。",                                       en = "Implemented Akatan & Aotan yaku detection (+5 mon each)." },
			{ jp = "こいこい式：カス/タネ/短冊は閾値超過で+1文ずつの“超過文”方式に変更。",         en = "Koi-koi style: introduced overflow mon (+1 mon per extra card) for Kasu/Seed/Ribbon." },
			{ jp = "干支：寅の仕様を“基本点(pts)に +1/Lv”で確定。",                                 en = "Kito (Tiger): finalized as +1 to base pts per level." },
			{ jp = "BalanceDev.lua（理論値とノブ感度の簡易計測ツール）を追加。",                    en = "Added BalanceDev.lua (quick tool for theoretical max & knob sensitivity)." },
		}
	},
	{
		ver  = "v0.9.3",
		date = "2025-09-12",
		changes = {
			{ jp = "Homeにパッチノート（暫定）を追加：ボタン→前面モーダル表示の原型。",            en = "Added provisional Patch Notes in Home: button opens a front modal (prototype)." },
			{ jp = "採点：全取りケースの検証（38文×86点=3268）→ 定義修正後は3306に更新。",          en = "Scoring: validated all-taken case (38 mon × 86 pts = 3268) → updated to 3306 after fixes." },
			{ jp = "言語切替のグローバル反映（Locale.setGlobal）を改善。",                           en = "Improved global language propagation via Locale.setGlobal." },
			{ jp = "オプション：クラシックこいこい互換の“文のみ”モードの準備。",                    en = "Prepared optional classic koi-koi 'mon-only' scoring mode." },
		}
	},
	{
		ver  = "v0.9.2",
		date = "2025-09-11",
		changes = {
			{ jp = "NEW/CONTINUEを「START GAME」に統合。旧CONTINUE枠はパッチノートに変更。",        en = "Unified NEW/CONTINUE into START GAME; repurposed old slot as Patch Notes." },
			{ jp = "言語チップ（EN/JP）を追加：保存言語を優先、無ければOS言語で初期化。",            en = "Added language chips (EN/JP): prefer saved language, otherwise use OS locale." },
			{ jp = "ショップに“スペクタル”カテゴリ追加。黒天（祭事Lvを一括+1）を実装。",           en = "Added 'Spectral' shop category. Implemented Blackhole (all festival levels +1)." },
			{ jp = "ShopEffects：カテゴリ別ディスパッチを実装（kito_/sai_/spectral_）。",            en = "ShopEffects: implemented category dispatch for kito_/sai_/spectral_." },
		}
	},
	{
		ver  = "v0.9.1",
		date = "2025-09-10",
		changes = {
			{ jp = "採点に干支（寅）の上乗せを追加（初期案+1pts/Lv → 後に仕様確定）。",            en = "Added Kito (Tiger) to scoring (initial +1 pts/Lv design → later finalized)." },
			{ jp = "Kito：丑=所持文2倍 / 寅=取り札得点+1スタック / 酉=構成から非brightをbright化。", en = "Kito: Ushi=double current mon / Tora=stackable taken pts +1 / Tori=convert a non-bright to bright." },
			{ jp = "ShopDefsに祈祷（kito_）基本3種を追加。",                                         en = "ShopDefs: added the three base Kito items." },
		}
	},
	{
		ver  = "v0.9.0",
		date = "2025-09-06",
		changes = {
			{ jp = "基礎採点を実装：役→文 / 札→点。総スコア=文×点。",                                en = "Implemented base scoring: yaku → mon / card → pts. Total = mon × pts." },
			{ jp = "祭事（Matsuri）係数テーブルと役→祭事マッピングを追加。",                         en = "Added Matsuri coefficient table and yaku → festival mapping." },
			{ jp = "CardEngine：48枚デッキ定義・スナップショット機能を実装。",                        en = "CardEngine: added 48-card definitions and snapshot utility." },
			{ jp = "ShopEffects初版：安全な pcall require と委譲ラッパを整備。",                      en = "ShopEffects v1: safe pcall-require and a delegate wrapper." },
		}
	},
}

-- RichText本文を生成。言語に合わせて箇条書き記号を切替（JP: ・ / EN: –）
local function build(lang)
	lang = (lang == "jp") and "jp" or "en"
	local bullet = (lang == "jp") and "・" or "– "
	local lines = {}

	-- ① 注意書きを先頭に
	table.insert(lines, NOTICE[lang])
	table.insert(lines, '<font transparency="0.6">────────────</font>')
	table.insert(lines, "") -- 空行

	-- ② 変更履歴（最新→古い）
	for _, e in ipairs(ENTRIES) do
		table.insert(lines, string.format("<b>%s</b>  <font transparency=\"0.25\">%s</font>", e.ver, e.date))
		for _, ch in ipairs(e.changes or {}) do
			local t = ch[lang] or ch.en or ""
			table.insert(lines, bullet .. t)
		end
		table.insert(lines, "") -- 空行
	end

	return table.concat(lines, "<br/>")
end

-- PatchNotesModal が読むフィールド（互換インタフェース）
M.title = { jp = "パッチノート", en = "Patch Notes" }
M.body  = { jp = build("jp"),   en = build("en") }

-- 生データ（管理・テスト用）
M.entries = ENTRIES
M.notice  = NOTICE

return M
