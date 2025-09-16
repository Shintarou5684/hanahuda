
## 注意（社内・開発向け）
この文書には内部ファイル名や実装詳細が含まれます。外部共有前に公開用パッチノートへ要サニタイズ。

---

## 更新記録 / Change Log

### v0.9.5 — 2025-09-17
- **Fix-All P0 完了**：P0-1〜P0-12 を一括修正 — (Completed all P0 blockers).
- **ResultModal / Nav 統一**：UI は `Nav.next("home"|"next"|"save")` のみ呼ぶ。内部は `DecideNext` に集約 — (Unified navigation on client; single remote).
- **Router のちらつき解消**：同一画面の `show` は `Enabled/Visible` を変更せず、表示更新のみ実行 — (No disable/enable loop on same screen).
- **Enabled/Visible の安全切替**：`ScreenGui.Enabled` / `GuiObject.Visible` を型で分岐 — (Safe toggling across types).
- **ResultModal 文言の i18n**：`Locale.t` キー（`RESULT_FINAL_*`）で切替、英語フォールバック — (Final dialog localized).
- **ShopOpen リスナーを1本化**：`ClientMain` に集約し、二重描画・二重遷移を排除 — (Consolidated ShopOpen handling).
- **Home Start の同期待ち**：`HomeOpen` 着弾まで Start を無効化（「同期中…」表示）— (Gate Start until payload arrives).
- **トーストのタイトル i18n**：`Locale.t(lang, "TOAST_TITLE")` — (Toast title localized).
- **Run の負債返済**：no-op 削除、空役は `Locale.t("ROLES_NONE")` に統一 — (Removed no-ops; empty roles string via Locale).
- **言語コード統一**：外部 I/F は `ja/en`。`jp` 受信時は警告の上 `ja` に正規化 — (Normalize `jp` → `ja`).
- **OSロケール検出の簡素化**：`game:GetService("Players")` を素直に使用 — (Simpler, clear detection code).
- **Run の目標スコア**：`StatePush` に `goal:number` を追加。Run は `st.goal` のみ参照（文字列パース撤廃）— (Robust goal display).
- **ShopCells 二重クリック対策**：価格帯を `TextLabel` 化し `Active=false/Selectable=false`。`Activated` は本体のみ — (1 click = 1 send).
- **その他**：Start/Continue の表示不具合を修正 — (Fixed Start/Continue visibility issue).

### v0.9.4 — 2025-09-14
- SHOP UI **4分割**：`ShopScreen` / `ShopCells` / `ShopRenderer` / `ShopWires` へ分離 — (SHOP UI split into four files).
- **Theme 薄適用**：`Config/Theme.lua` の `COLORS`/`SIZES` を SHOP に反映 — (Applied Theme thinly to SHOP).
- **i18n アダプタ**：SHOP 内はローカル鍵で暫定対応 → 後で `Config/Locale.lua` に移行予定 — (Local keys in SHOP, migrate later).
- `PatchNotesModal.lua` を追加。`HomeScreen` はモーダル起動のみへ簡素化 — (Added PatchNotesModal; Home just opens it).
- `Config/PatchNotes.lua` を**公開用**に再構成（ファイル名など内部情報を非表示に）— (Reworked for public notes).
- **短冊定義の修正**：`0102/0202/0302/0402/0502/0602/0702/0902/1002/1103` の10枚に統一 — (Ribbon set fixed to 10 cards).
- **Akatan/Aotan**（各 +5 文）を `Scoring.lua` に実装、`FormatUtil` に表示行を追加 — (Implemented yaku detection and display).
- **超過文（Koi-koi 互換）**：カス/タネ/短冊で閾値超過毎に +1 文 — (Overflow-mon implemented).
- **Kito: 寅（Tora）** 仕様を **pts+1/Lv** に確定（丑/酉は現行維持）— (Finalize Tora).
- `BalanceDev.lua` 追加：理論上限/ノブ感度の試算ツール — (Added balance helper).

### v0.9.3 — 2025-09-12
- Home に**暫定パッチノート**追加（ボタン→モーダル原型）。
- **採点全取りケース**検証：定義修正前 3268 → 修正後 **3306**。
- `Locale.setGlobal` の反映範囲を拡張（Home→Run/Shop へ伝播）。
- **クラシック“文のみ”モード**の下準備。

### v0.9.2 — 2025-09-11
- NEW/CONTINUE を **START GAME に統合**。旧 CONTINUE 枠は**パッチノート**へ。
- **言語チップ（EN/JP）**追加：保存言語優先、なければ OS ロケール初期化。
- `ShopDefs`：**spectral** カテゴリ追加、**黒天**（全祭事 +1）を実装。
- `ShopEffects` 初期化ディスパッチに `kito_/sai_/spectral_` を追加。

### v0.9.1 — 2025-09-10
- 採点に**寅（取り札 pts+1/Lv 候補）**を試験導入 → 後日仕様確定。
- `ShopDefs` に **Kito 基本3種（丑/寅/酉）**を追加。

### v0.9.0 — 2025-09-06
- **基礎採点**：役→文 / 札→点、総スコア = 文 × 点 を実装。
- **祭事テーブル**と**役→祭事マッピング**を追加。
- `CardEngine`：**48枚デッキ**定義と**スナップショット**機能。
- `ShopEffects v1`：安全な **pcall require** と委譲ラッパー。

---

### 追記ルール（メモ）
- 先頭が最新。新しい更新は上に追記。
- 社外公開が必要になったら、公開用 `PatchNotes.lua` へ転記＆サニタイズ。
