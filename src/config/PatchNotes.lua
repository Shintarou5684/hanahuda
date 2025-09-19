-- ReplicatedStorage/Config/PatchNotes.lua
-- 公開向けパッチノート（RichText対応）
-- PatchNotesModal は title/body を読むだけ。このファイルを更新するだけでUIに反映されます。

local M = {}

-- ========= 注意書き（JA/EN） =========
local NOTICE = {
	ja = [[<b>⚠ 注意（開発中）</b><br/>
<font transparency="0.08">
現在この作品は開発中です。プレイは可能ですが、難易度やバランスは暫定です。
不具合の発生、仕様の予告ない変更、到達履歴やセーブデータのリセットが行われる場合があります。
ご了承のうえお楽しみください。
</font>]],
	en = [[<b>⚠ Notice (In Development)</b><br/>
<font transparency="0.08">
The game is in active development. It is playable, but difficulty and balance are provisional.
Bugs may occur, features may change without notice, and progress/save data may be reset.
Thank you for your understanding.
</font>]],
}

-- 先頭が最新。新バージョンは配列の「先頭」に追加していく。
local ENTRIES = {
	-- ★ 0.9.6 を外部向けトーンで追加（0.9.5 以前は変更なし）
	{
		ver  = "v0.9.6.1",
		date = "2025-09-19",
		changes = {
			{ ja = "護符（Talisman）を屋台に追加。購入するとボードに自動配置され、状態が画面に分かりやすく反映されます。",
			  en = "Added Talisman to the Shop. Buying one now auto-places it on your board with clear on-screen feedback." },
			{ ja = "護符ボードを横一列・比率可変の表示に刷新。端末サイズに合わせてスロットが見やすく並びます（現段階では表示のみ）。",
			  en = "Refreshed the Talisman Board: single-row, responsive layout for consistent viewing across devices (display-only for now)." },
			{ ja = "購入した商品は屋台から即時に非表示に。リロール時は品揃えがクリーンに更新されます。",
			  en = "Purchased items now disappear from the Shop immediately. Reroll updates the lineup cleanly." },
			{ ja = "屋台更新時のちらつきや一時的な表示ズレを軽減し、操作感を安定化。",
			  en = "Reduced flicker and transient layout shifts during Shop updates for a smoother experience." },
			{ ja = "採点（スコア計算）の挙動は今回変更なし。護符の実効果は今後のアップデートで段階的に追加予定です。",
			  en = "No scoring changes this update. Talisman effects will roll out in future releases." },
		}
	},

	-- ここから下は既存（変更なし）
	{
		ver  = "v0.9.6",
		date = "2025-09-17",
		changes = {
			{ ja = "Fix-All P0 を完了（P0-1〜P0-12）。UI遷移・表記・入力安定性を全体的に改善。",
			  en = "Completed Fix-All P0 (P0-1 to P0-12). Broad improvements to navigation, text, and input stability." },
			{ ja = "画面遷移を Nav.next(\"home\"|\"next\"|\"save\") に統一（内部は DecideNext）。",
			  en = "Unified navigation to Nav.next(\"home\"|\"next\"|\"save\") with a single DecideNext remote inside." },
			{ ja = "同一画面の再表示でちらつかないよう Router を最適化。",
			  en = "Optimized Router to avoid flicker when re-showing the same screen." },
			{ ja = "UI の表示切替を型安全化（ScreenGui.Enabled / GuiObject.Visible を自動判別）。",
			  en = "Hardened UI toggling (auto-select ScreenGui.Enabled vs GuiObject.Visible safely)." },
			{ ja = "Run：目標スコアは payload の数値 goal を参照（文字列パースを撤廃）。",
			  en = "Run: Goal now taken from numeric payload field 'goal' (removed string parsing)." },
			{ ja = "Shop：価格帯の二重クリックを解消（価格帯はラベル化・1クリック=1送信）。",
			  en = "Shop: Removed double-activation by making price band a label; one click = one send." },
			{ ja = "トースト＆結果モーダルの文言を i18n 化（英語フォールバック対応）。",
			  en = "Localized Toast title & Final modal strings with English fallback." },
			{ ja = "言語コードを外部 I/F で ja/en に統一（jp は警告の上 ja に正規化）。",
			  en = "Standardized external language codes to ja/en (normalize legacy 'jp' → 'ja' with warning)." },
		}
	},
	{
		ver  = "v0.9.5",
		date = "2025-09-14",
		changes = {
			{ ja = "屋台UIの構造を整理し、操作の一貫性と安定性を向上。", 
			  en = "Streamlined Shop UI structure for more consistent and stable interactions." },
			{ ja = "屋台の見た目を微調整（角丸・淡い枠・価格帯の視認性・ホバー強調）。",
			  en = "Visual polish in the Shop (rounded corners, subtle borders, clearer price bands, hover emphasis)." },
			{ ja = "言語テキストの取り回しを改善。将来的な多言語対応に備えた下地を追加。",
			  en = "Improved string handling in preparation for future multi-language support." },
			{ ja = "画面切替の最適化により、屋台更新時のちらつきを軽減。",
			  en = "Optimized screen transitions to reduce flicker when the Shop updates." },
			{ ja = "リロールは“1文でいつでも”に整理（暫定）。残回数の表示は当面省略。",
			  en = "Reroll clarified to 'anytime for 1 mon' (temporary). Remaining-count UI omitted for now." },
			{ ja = "一部環境で発生していた屋台UIの読み込み不具合を修正。",
			  en = "Fixed a Shop UI loading issue observed in certain environments." },
			{ ja = "購入/リロール後の通知を調整し、結果が分かりやすくなるよう改善。",
			  en = "Tuned notifications after purchases and rerolls for clearer feedback." },
		}
	},
	{
		ver  = "v0.9.4",
		date = "2025-09-13",
		changes = {
			{ ja = "ホームからパッチノートを開けるように改善。", 
			  en = "Patch Notes are now accessible from Home." },
			{ ja = "短冊の定義を見直し、役判定が期待通りになるよう修正。",
			  en = "Reviewed ribbon definitions to ensure expected yaku detection." },
			{ ja = "役：赤短・青短の判定を実装（各+5文）。",
			  en = "Implemented Akatan and Aotan yaku (+5 mon each)." },
			{ ja = "こいこい式の“超過文”を導入（カス/タネ/短冊の閾値超過で+1文）。",
			  en = "Introduced koi-koi style overflow mon (+1 per extra Kasu/Seed/Ribbon)." },
			{ ja = "干支：寅の効果を“基本点に+1/レベル”で確定。",
			  en = "Kito (Tiger) finalized as +1 to base points per level." },
			{ ja = "内部のバランス調整作業を効率化（将来の調整速度を向上）。",
			  en = "Improved internal balancing workflow for faster future tuning." },
		}
	},
	{
		ver  = "v0.9.3",
		date = "2025-09-12",
		changes = {
			{ ja = "ホームのパッチノート導線を追加（前面モーダル）。",
			  en = "Added Patch Notes entry on Home (front modal)." },
			{ ja = "スコア算出の端ケースを見直し、想定値に合わせて調整。",
			  en = "Reviewed edge cases in scoring and aligned with expected values." },
			{ ja = "言語切替の反映を改善し、画面間の一貫性を向上。",
			  en = "Improved language propagation for consistent UI across screens." },
			{ ja = "オプション準備：クラシックこいこい互換の“文のみ”モード。",
			  en = "Preparation for an optional classic koi-koi 'mon-only' mode." },
		}
	},
	{
		ver  = "v0.9.2",
		date = "2025-09-11",
		changes = {
			{ ja = "スタート導線を整理（NEW/CONTINUEの統合）。",
			  en = "Unified start flow (NEW/CONTINUE integration)." },
			{ ja = "言語チップ（EN/JP）を追加。保存言語を優先、無ければOS言語で初期化。",
			  en = "Added EN/JP language chips. Prefer saved language; fallback to OS locale." },
			{ ja = "屋台にレア枠を追加。全祭事に影響する強力な効果を実装。",
			  en = "Added a rare Shop category with a powerful effect impacting all festivals." },
			{ ja = "効果処理の安定性を向上（将来拡張に備えた土台）。",
			  en = "Hardened effect handling to support future expansions." },
		}
	},
	{
		ver  = "v0.9.1",
		date = "2025-09-10",
		changes = {
			{ ja = "干支の効果を追加：丑（所持文2倍）／寅（取り札の得点+1, スタック可）／酉（1枚を光札化）。",
			  en = "Added Kito effects: Ushi (double current mon) / Tora (+1 taken pts, stackable) / Tori (convert one card to bright)." },
			{ ja = "屋台の品揃えに上記効果を追加。",
			  en = "These effects are now available in the Shop lineup." },
		}
	},
	{
		ver  = "v0.9.0",
		date = "2025-09-06",
		changes = {
			{ ja = "基礎採点を実装：役→文、札→点。総スコア＝文×点。",
			  en = "Implemented base scoring: yaku → mon, cards → pts. Total = mon × pts." },
			{ ja = "祭事ボーナスと役→祭事の紐づけを追加。",
			  en = "Added festival bonuses and yaku-to-festival mapping." },
			{ ja = "デッキ定義と内部ツールを整備（安定性と測定性の向上）。",
			  en = "Refined deck definitions and internal tooling for stability and measurability." },
			{ ja = "屋台効果の処理を堅牢化。",
			  en = "Hardened Shop effect processing." },
		}
	},
}

-- lang 正規化（'jp' を受けたら 'ja' に正規化し警告）
local function normLang(lang)
	local s = tostring(lang or ""):lower()
	if s == "jp" then
		warn("[PatchNotes] received legacy 'jp'; normalizing to 'ja'")
		return "ja"
	end
	if s == "ja" or s == "en" then return s end
	return "en"
end

-- RichText本文を生成。言語に合わせて箇条書き記号を切替（JA: ・ / EN: –）
local function build(lang)
	lang = normLang(lang)
	local bullet = (lang == "ja") and "・" or "– "
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
M.title = { ja = "パッチノート", en = "Patch Notes" }
M.body  = { ja = build("ja"),   en = build("en") }

-- 生データ（管理・テスト用）
M.entries = ENTRIES
M.notice  = NOTICE

return M
