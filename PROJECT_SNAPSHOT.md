# Project Snapshot

- Root: `C:\Users\msk_7\Documents\Roblox\hanahuda`
- Generated: 2025-09-20 01:41:36
- Max lines/file: 300

## Folder Tree

```text
hanahuda
├── _unused
│   └── src
│       └── client
│           └── _unused_dev_patch_diary_2025-09-14.md
├── BGM
│   ├── BGM.ogg
│   ├── omise.ogg
│   └── TOP.mp3
├── huda
│   ├── 0101.jpg
│   ├── 0102.jpg
│   ├── 0103.jpg
│   ├── 0104.jpg
│   ├── 0201.jpg
│   ├── 0202.jpg
│   ├── 0203.jpg
│   ├── 0204.jpg
│   ├── 0301.jpg
│   ├── 0302.jpg
│   ├── 0303.jpg
│   ├── 0304.jpg
│   ├── 0401.jpg
│   ├── 0402.jpg
│   ├── 0403.jpg
│   ├── 0404.jpg
│   ├── 0501.jpg
│   ├── 0502.jpg
│   ├── 0503.jpg
│   ├── 0504.jpg
│   ├── 0601.jpg
│   ├── 0602.jpg
│   ├── 0603.jpg
│   ├── 0604.jpg
│   ├── 0701.jpg
│   ├── 0702.jpg
│   ├── 0703.jpg
│   ├── 0704.jpg
│   ├── 0801.jpg
│   ├── 0802.jpg
│   ├── 0803.jpg
│   ├── 0804.jpg
│   ├── 0901.jpg
│   ├── 0902.jpg
│   ├── 0903.jpg
│   ├── 0904.jpg
│   ├── 1001.jpg
│   ├── 1002.jpg
│   ├── 1003.jpg
│   ├── 1004.jpg
│   ├── 1101.jpg
│   ├── 1102.jpg
│   ├── 1103.jpg
│   ├── 1104.jpg
│   ├── 1201.jpg
│   ├── 1202.jpg
│   ├── 1203.jpg
│   └── 1204.jpg
├── image
│   ├── mainimage.png
│   ├── mokume.png
│   ├── mousen.png
│   ├── samune.jpg
│   ├── shop.png
│   ├── tatami.jpg
│   ├── top.jpg
│   └── wasitu.png
├── src
│   ├── client
│   │   └── ui
│   │       ├── components
│   │       │   ├── controllers
│   │       │   │   └── ShopWires.lua
│   │       │   ├── i18n
│   │       │   │   └── ShopI18n.lua
│   │       │   ├── renderers
│   │       │   │   ├── FieldRenderer.lua
│   │       │   │   ├── HandRenderer.lua
│   │       │   │   ├── ShopRenderer.lua
│   │       │   │   └── TakenRenderer.lua
│   │       │   ├── CardNode.lua
│   │       │   ├── DevTools.lua
│   │       │   ├── Overlay.lua
│   │       │   ├── ResultModal.lua
│   │       │   ├── ShopCells.lua
│   │       │   ├── ShopUI.lua
│   │       │   ├── TalismanBoard.lua
│   │       │   ├── TutorialBanner.lua
│   │       │   ├── UiKit.lua
│   │       │   └── YakuPanel.lua
│   │       ├── lib
│   │       │   ├── FormatUtil.lua
│   │       │   └── UiUtil.lua
│   │       ├── screens
│   │       │   ├── HomeScreen.lua
│   │       │   ├── PatchNotesModal.lua
│   │       │   ├── RunScreen.lua
│   │       │   ├── RunScreenRemotes.lua
│   │       │   ├── RunScreenUI.lua
│   │       │   ├── ShopScreen.lua
│   │       │   └── ShrineScreen.lua
│   │       ├── CameraController.client.lua
│   │       ├── ClientMain.client.lua
│   │       └── ScreenRouter.lua
│   ├── config
│   │   ├── DisplayMode.lua
│   │   ├── Locale.lua
│   │   ├── PatchNotes.lua
│   │   └── Theme.lua
│   ├── remotes
│   ├── server
│   │   ├── ShopEffects
│   │   │   ├── init.lua
│   │   │   ├── Kito.lua
│   │   │   ├── Omamori.lua
│   │   │   ├── Sai.lua
│   │   │   └── Spectral.lua
│   │   ├── GameInit.server.lua
│   │   ├── NavServer.lua
│   │   ├── RemotesInit.server.lua
│   │   ├── SaveService.lua
│   │   ├── TalismanService.server.lua
│   │   └── UiResync.server.lua
│   └── shared
│       ├── score
│       │   ├── hooks
│       │   │   ├── init.lua
│       │   │   ├── omamori.lua
│       │   │   └── talisman.lua
│       │   ├── phases
│       │   │   ├── finalize.lua
│       │   │   ├── P0_normalize.lua
│       │   │   ├── P1_count.lua
│       │   │   ├── P2_roles.lua
│       │   │   ├── P3_matsuri_kito.lua
│       │   │   ├── P4_talisman.lua
│       │   │   └── P5_omamori.lua
│       │   ├── util
│       │   │   ├── kind.lua
│       │   │   └── tags.lua
│       │   ├── constants.lua
│       │   ├── ctx.lua
│       │   └── index.lua
│       ├── CardEngine.lua
│       ├── CardImageMap.lua
│       ├── LocaleUtil.lua
│       ├── Logger.lua
│       ├── Modifiers.lua
│       ├── NavClient.lua
│       ├── PickService.lua
│       ├── RerollService.lua
│       ├── RoundService.lua
│       ├── RunDeckUtil.lua
│       ├── ScoreService.lua
│       ├── Scoring.lua
│       ├── ShopDefs.lua
│       ├── ShopFormat.lua
│       ├── ShopService.lua
│       ├── StateHub.lua
│       ├── TalismanDefs.lua
│       └── TalismanState.lua
├── aftman.toml
├── default.project.json
├── README.md
└── snapshot.py
```

## Files (first 300 lines each)

### _unused/src/client/_unused_dev_patch_diary_2025-09-14.md
```md

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
```

### aftman.toml
```toml
[tools]
rojo = "rojo-rbx/rojo@7.4.0"
```

### BGM/BGM.ogg
```text
[binary file] size=2693901 bytes
```

### BGM/omise.ogg
```text
[binary file] size=2548556 bytes
```

### BGM/TOP.mp3
```text
[binary file] size=2356304 bytes
```

### default.project.json
```json
{
  "name": "hanahuda",
  "tree": {
    "$className": "DataModel",

    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",

      "Config": {
        "$className": "Folder",
        "$path": "src/config"
      },

      "SharedModules": {
        "$className": "Folder",
        "$path": "src/shared"
      },

      "Remotes": {
        "$className": "Folder",
        "$path": "src/remotes"
      }
    },

    "ServerScriptService": {
      "$className": "ServerScriptService",
      "$path": "src/server"
    },

    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "$path": "src/client"
      }
    }
  }
}
```

### huda/0101.jpg
```text
[binary file] size=438186 bytes
```

### huda/0102.jpg
```text
[binary file] size=462146 bytes
```

### huda/0103.jpg
```text
[binary file] size=379729 bytes
```

### huda/0104.jpg
```text
[binary file] size=356183 bytes
```

### huda/0201.jpg
```text
[binary file] size=690113 bytes
```

### huda/0202.jpg
```text
[binary file] size=599653 bytes
```

### huda/0203.jpg
```text
[binary file] size=490722 bytes
```

### huda/0204.jpg
```text
[binary file] size=553546 bytes
```

### huda/0301.jpg
```text
[binary file] size=594615 bytes
```

### huda/0302.jpg
```text
[binary file] size=669071 bytes
```

### huda/0303.jpg
```text
[binary file] size=616400 bytes
```

### huda/0304.jpg
```text
[binary file] size=605588 bytes
```

### huda/0401.jpg
```text
[binary file] size=594444 bytes
```

### huda/0402.jpg
```text
[binary file] size=513126 bytes
```

### huda/0403.jpg
```text
[binary file] size=451761 bytes
```

### huda/0404.jpg
```text
[binary file] size=458665 bytes
```

### huda/0501.jpg
```text
[binary file] size=546701 bytes
```

### huda/0502.jpg
```text
[binary file] size=474859 bytes
```

### huda/0503.jpg
```text
[binary file] size=409231 bytes
```

### huda/0504.jpg
```text
[binary file] size=390722 bytes
```

### huda/0601.jpg
```text
[binary file] size=668251 bytes
```

### huda/0602.jpg
```text
[binary file] size=468126 bytes
```

### huda/0603.jpg
```text
[binary file] size=508251 bytes
```

### huda/0604.jpg
```text
[binary file] size=543343 bytes
```

### huda/0701.jpg
```text
[binary file] size=729449 bytes
```

### huda/0702.jpg
```text
[binary file] size=599235 bytes
```

### huda/0703.jpg
```text
[binary file] size=576273 bytes
```

### huda/0704.jpg
```text
[binary file] size=543537 bytes
```

### huda/0801.jpg
```text
[binary file] size=174467 bytes
```

### huda/0802.jpg
```text
[binary file] size=487270 bytes
```

### huda/0803.jpg
```text
[binary file] size=287249 bytes
```

### huda/0804.jpg
```text
[binary file] size=293964 bytes
```

### huda/0901.jpg
```text
[binary file] size=644374 bytes
```

### huda/0902.jpg
```text
[binary file] size=496406 bytes
```

### huda/0903.jpg
```text
[binary file] size=549757 bytes
```

### huda/0904.jpg
```text
[binary file] size=541753 bytes
```

### huda/1001.jpg
```text
[binary file] size=718964 bytes
```

### huda/1002.jpg
```text
[binary file] size=565662 bytes
```

### huda/1003.jpg
```text
[binary file] size=587487 bytes
```

### huda/1004.jpg
```text
[binary file] size=607072 bytes
```

### huda/1101.jpg
```text
[binary file] size=639089 bytes
```

### huda/1102.jpg
```text
[binary file] size=535857 bytes
```

### huda/1103.jpg
```text
[binary file] size=423515 bytes
```

### huda/1104.jpg
```text
[binary file] size=533342 bytes
```

### huda/1201.jpg
```text
[binary file] size=613326 bytes
```

### huda/1202.jpg
```text
[binary file] size=383187 bytes
```

### huda/1203.jpg
```text
[binary file] size=374187 bytes
```

### huda/1204.jpg
```text
[binary file] size=412995 bytes
```

### image/mainimage.png
```text
[binary file] size=2635970 bytes
```

### image/mokume.png
```text
[binary file] size=283683 bytes
```

### image/mousen.png
```text
[binary file] size=1064156 bytes
```

### image/samune.jpg
```text
[binary file] size=1269022 bytes
```

### image/shop.png
```text
[binary file] size=732408 bytes
```

### image/tatami.jpg
```text
[binary file] size=887488 bytes
```

### image/top.jpg
```text
[binary file] size=1165288 bytes
```

### image/wasitu.png
```text
[binary file] size=1267489 bytes
```

### PROJECT_SNAPSHOT.md
```md
# Project Snapshot

- Root: `C:\Users\msk_7\Documents\Roblox\hanahuda`
- Generated: 2025-09-20 01:41:36
- Max lines/file: 300

## Folder Tree

```text
hanahuda
├── _unused
│   └── src
│       └── client
│           └── _unused_dev_patch_diary_2025-09-14.md
├── BGM
│   ├── BGM.ogg
│   ├── omise.ogg
│   └── TOP.mp3
├── huda
│   ├── 0101.jpg
│   ├── 0102.jpg
│   ├── 0103.jpg
│   ├── 0104.jpg
│   ├── 0201.jpg
│   ├── 0202.jpg
│   ├── 0203.jpg
│   ├── 0204.jpg
│   ├── 0301.jpg
│   ├── 0302.jpg
│   ├── 0303.jpg
│   ├── 0304.jpg
│   ├── 0401.jpg
│   ├── 0402.jpg
│   ├── 0403.jpg
│   ├── 0404.jpg
│   ├── 0501.jpg
│   ├── 0502.jpg
│   ├── 0503.jpg
│   ├── 0504.jpg
│   ├── 0601.jpg
│   ├── 0602.jpg
│   ├── 0603.jpg
│   ├── 0604.jpg
│   ├── 0701.jpg
│   ├── 0702.jpg
│   ├── 0703.jpg
│   ├── 0704.jpg
│   ├── 0801.jpg
│   ├── 0802.jpg
│   ├── 0803.jpg
│   ├── 0804.jpg
│   ├── 0901.jpg
│   ├── 0902.jpg
│   ├── 0903.jpg
│   ├── 0904.jpg
│   ├── 1001.jpg
│   ├── 1002.jpg
│   ├── 1003.jpg
│   ├── 1004.jpg
│   ├── 1101.jpg
│   ├── 1102.jpg
│   ├── 1103.jpg
│   ├── 1104.jpg
│   ├── 1201.jpg
│   ├── 1202.jpg
│   ├── 1203.jpg
│   └── 1204.jpg
├── image
│   ├── mainimage.png
│   ├── mokume.png
│   ├── mousen.png
│   ├── samune.jpg
│   ├── shop.png
│   ├── tatami.jpg
│   ├── top.jpg
│   └── wasitu.png
├── src
│   ├── client
│   │   └── ui
│   │       ├── components
│   │       │   ├── controllers
│   │       │   │   └── ShopWires.lua
│   │       │   ├── i18n
│   │       │   │   └── ShopI18n.lua
│   │       │   ├── renderers
│   │       │   │   ├── FieldRenderer.lua
│   │       │   │   ├── HandRenderer.lua
│   │       │   │   ├── ShopRenderer.lua
│   │       │   │   └── TakenRenderer.lua
│   │       │   ├── CardNode.lua
│   │       │   ├── DevTools.lua
│   │       │   ├── Overlay.lua
│   │       │   ├── ResultModal.lua
│   │       │   ├── ShopCells.lua
│   │       │   ├── ShopUI.lua
│   │       │   ├── TalismanBoard.lua
│   │       │   ├── TutorialBanner.lua
│   │       │   ├── UiKit.lua
│   │       │   └── YakuPanel.lua
│   │       ├── lib
│   │       │   ├── FormatUtil.lua
│   │       │   └── UiUtil.lua
│   │       ├── screens
│   │       │   ├── HomeScreen.lua
│   │       │   ├── PatchNotesModal.lua
│   │       │   ├── RunScreen.lua
│   │       │   ├── RunScreenRemotes.lua
│   │       │   ├── RunScreenUI.lua
│   │       │   ├── ShopScreen.lua
│   │       │   └── ShrineScreen.lua
│   │       ├── CameraController.client.lua
│   │       ├── ClientMain.client.lua
│   │       └── ScreenRouter.lua
│   ├── config
│   │   ├── DisplayMode.lua
│   │   ├── Locale.lua
│   │   ├── PatchNotes.lua
│   │   └── Theme.lua
│   ├── remotes
│   ├── server
│   │   ├── ShopEffects
│   │   │   ├── init.lua
│   │   │   ├── Kito.lua
│   │   │   ├── Omamori.lua
│   │   │   ├── Sai.lua
│   │   │   └── Spectral.lua
│   │   ├── GameInit.server.lua
│   │   ├── NavServer.lua
│   │   ├── RemotesInit.server.lua
│   │   ├── SaveService.lua
│   │   ├── TalismanService.server.lua
│   │   └── UiResync.server.lua
│   └── shared
│       ├── score
│       │   ├── hooks
│       │   │   ├── init.lua
│       │   │   ├── omamori.lua
│       │   │   └── talisman.lua
│       │   ├── phases
│       │   │   ├── finalize.lua
│       │   │   ├── P0_normalize.lua
│       │   │   ├── P1_count.lua
│       │   │   ├── P2_roles.lua
│       │   │   ├── P3_matsuri_kito.lua
│       │   │   ├── P4_talisman.lua
│       │   │   └── P5_omamori.lua
│       │   ├── util
│       │   │   ├── kind.lua
│       │   │   └── tags.lua
│       │   ├── constants.lua
│       │   ├── ctx.lua
│       │   └── index.lua
│       ├── CardEngine.lua
│       ├── CardImageMap.lua
│       ├── LocaleUtil.lua
│       ├── Logger.lua
│       ├── Modifiers.lua
│       ├── NavClient.lua
│       ├── PickService.lua
│       ├── RerollService.lua
│       ├── RoundService.lua
│       ├── RunDeckUtil.lua
│       ├── ScoreService.lua
│       ├── Scoring.lua
│       ├── ShopDefs.lua
│       ├── ShopFormat.lua
│       ├── ShopService.lua
│       ├── StateHub.lua
│       ├── TalismanDefs.lua
│       └── TalismanState.lua
├── aftman.toml
├── default.project.json
├── README.md
└── snapshot.py
```

## Files (first 300 lines each)

### _unused/src/client/_unused_dev_patch_diary_2025-09-14.md
```md

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
```

### aftman.toml
```toml
[tools]
rojo = "rojo-rbx/rojo@7.4.0"
```

### BGM/BGM.ogg
```text
[binary file] size=2693901 bytes
```

### BGM/omise.ogg
```text
[binary file] size=2548556 bytes
```

### BGM/TOP.mp3
```text
[binary file] size=2356304 bytes
```

### default.project.json
```json
{
  "name": "hanahuda",
  "tree": {
    "$className": "DataModel",

    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",

      "Config": {
        "$className": "Folder",
        "$path": "src/config"
      },

      "SharedModules": {
        "$className": "Folder",
        "$path": "src/shared"
      },

      "Remotes": {
        "$className": "Folder",
        "$path": "src/remotes"
      }
    },

    "ServerScriptService": {
      "$className": "ServerScriptService",
      "$path": "src/server"
    },

    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
... (truncated)
```

### README.md
```md
# hanahuda
Generated by [Rojo](https://github.com/rojo-rbx/rojo) 7.4.0.

## Getting Started
To build the place from scratch, use:

```bash
rojo build -o "hanahuda.rbxlx"
```

Next, open `hanahuda.rbxlx` in Roblox Studio and start the Rojo server:

```bash
rojo serve
```

For more help, check out [the Rojo documentation](https://rojo.space/docs).
```

### snapshot.py
```py
# snapshot.py
# Hanahuda プロジェクト直下に置いて実行すると、同ディレクトリ配下を走査して
# フォルダツリーと各ファイルの先頭数百行を PROJECT_SNAPSHOT.md に出力します。
# 依存なし / クロスプラットフォーム（Windows・macOS・Linux）

from __future__ import annotations
import sys
import os
from pathlib import Path
from datetime import datetime

# ===== 設定 =====
MAX_LINES = 300  # 各ファイルから拾う最大行数
OUT_NAME  = "PROJECT_SNAPSHOT.md"

# 除外（部分一致・パスに含まれていたら除外）
EXCLUDES = [
    ".git", ".vscode", "node_modules", "dist", "build", "__pycache__",
    ".DS_Store", ".idea", ".venv",
    # ロック/秘密系
    "package-lock.json", "yarn.lock", "pnpm-lock.yaml",
    ".env", ".env.", ".pem", ".key", ".crt",
]

# バイナリ扱いする拡張子（中身は読まずメタ情報のみ）
BINARY_EXT = {
    "png","jpg","jpeg","gif","webp","bmp","ico","svg",
    "mp3","wav","ogg","flac","mp4","mov","avi","mkv",
    "zip","7z","rar","gz","bz2","xz","jar",
    "rbxl","rbxlx","rbxm","rbxmx",   # Roblox
    "dll","exe","pdb",
}

# コードフェンス言語（拡張子→言語）
FENCE_BY_EXT = {
    "lua": "lua","rbxl":"", "rbxlx":"", "rbxm":"", "rbxmx":"",
    "js":"js","mjs":"js","cjs":"js",
    "ts":"ts","tsx":"tsx","jsx":"jsx",
    "json":"json","yaml":"yaml","yml":"yaml","toml":"toml",
    "py":"py","rb":"rb","go":"go","rs":"rust","java":"java","kt":"kt",
    "cs":"cs","cpp":"cpp","c":"c","h":"c","hpp":"cpp",
    "php":"php","swift":"swift","sql":"sql",
    "sh":"sh","bash":"bash","zsh":"zsh",
    "md":"md","html":"html","css":"css",
    "txt":""
}

ROOT = Path(__file__).resolve().parent

def is_excluded(p: Path) -> bool:
    rp = str(p.relative_to(ROOT)).replace("\\", "/")
    return any(x in rp for x in EXCLUDES)

def ext_of(p: Path) -> str:
    return p.suffix.lower().lstrip(".")

def is_binary(p: Path) -> bool:
    return ext_of(p) in BINARY_EXT

def read_head_lines(p: Path, limit: int) -> list[str]:
    # テキスト判定：まず utf-8 で、ダメなら errors="replace"
    lines: list[str] = []
    try:
        with p.open("r", encoding="utf-8", errors="strict") as f:
            for i, line in enumerate(f):
                if i >= limit: break
                lines.append(line.rstrip("\n"))
        return lines
    except Exception:
        try:
            with p.open("r", encoding="utf-8", errors="replace") as f:
                for i, line in enumerate(f):
                    if i >= limit: break
                    lines.append(line.rstrip("\n"))
            return lines
        except Exception:
            # 最後の砦：バイナリ扱い
            return []

def build_tree() -> str:
    # フォルダ→ファイル、名前順で擬似 tree を作る
    lines: list[str] = []
    def walk(dir: Path, prefix: str = ""):
        try:
            items = sorted(dir.iterdir(), key=lambda p: (not p.is_dir(), p.name.lower()))
        except PermissionError:
            return
        last_idx = len([it for it in items if not is_excluded(it)]) - 1
        idx = -1
        for it in items:
            if is_excluded(it): 
                continue
            idx += 1
            is_last = (idx == last_idx)
            elbow = "└── " if is_last else "├── "
            lines.append(prefix + elbow + it.name)
            if it.is_dir():
                ext_pref = "    " if is_last else "│   "
                walk(it, prefix + ext_pref)
    lines.append(ROOT.name)
    walk(ROOT)
    return "\n".join(lines)

def list_files() -> list[Path]:
    files: list[Path] = []
    for p in ROOT.rglob("*"):
        if p.is_file() and not is_excluded(p):
            files.append(p)
    # 安定ソート（相対パス）
    files.sort(key=lambda x: str(x.relative_to(ROOT)).lower())
    return files

def main():
    out = ROOT / OUT_NAME

    # Header
    header = [
        "# Project Snapshot",
        "",
        f"- Root: `{ROOT}`",
        f"- Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"- Max lines/file: {MAX_LINES}",
        "",
        "## Folder Tree",
        "",
        "```text",
        build_tree(),
        "```",
        "",
        f"## Files (first {MAX_LINES} lines each)",
        ""
    ]
    out.write_text("\n".join(header), encoding="utf-8")

    # Files
    for f in list_files():
        rel = str(f.relative_to(ROOT)).replace("\\", "/")
        with out.open("a", encoding="utf-8") as o:
            o.write(f"\n### {rel}\n")
            if is_binary(f):
                try:
                    size = f.stat().st_size
                except Exception:
                    size = -1
                o.write("```text\n")
                o.write(f"[binary file] size={size} bytes\n")
                o.write("```\n")
                continue

            fence = FENCE_BY_EXT.get(ext_of(f), "")
            o.write(f"```{fence}\n")
            lines = read_head_lines(f, MAX_LINES)
            if lines:
                o.write("\n".join(lines) + "\n")
                # もっと長いかも？を示す
                try:
                    # 速く判定：limit 行読んで still data があれば“…省略”表記
                    with f.open("r", encoding="utf-8", errors="replace") as chk:
                        for _ in range(MAX_LINES):
                            chk.readline()
                        rest = chk.readline()
                        if rest:
                            o.write("... (truncated)\n")
                except Exception:
                    pass
            else:
                o.write("[unreadable or empty]\n")
            o.write("```\n")

    print(f"Done: {out}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
```

### src/client/ui/CameraController.client.lua
```lua
-- src/client/CameraController.client.lua
-- v0.8.x: 2D固定版（3Dは将来実装）
-- 役割：DisplayMode(2D/3Dフラグ)に従い、カメラを2Dトップダウンへ固定する

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local RS          = game:GetService("ReplicatedStorage")

-- Config: ReplicatedStorage/Config/DisplayMode.lua
local DisplayMode = require(
	RS:WaitForChild("Config")
	  :WaitForChild("DisplayMode")
)

local localPlayer = Players.LocalPlayer
local camera      = workspace.CurrentCamera

--========================
-- 設定（2Dトップダウン）
--========================
local TOPDOWN_HEIGHT = 120               -- 盤面の上空高さ
local TOPDOWN_FOV    = 20                -- 擬似2D感を強める狭めFOV
local LOOK_AT        = Vector3.new(0,0,0) -- 盤面中心（必要に応じて差し替え）

--========================
-- 内部状態
--========================
local conn       -- Heartbeat接続
local lastCF     -- 最後に適用したカメラCFrame
local lastFOV    -- 最後に適用したFOV

--========================
-- 2D適用
--========================
local function apply2D()
	camera.CameraType  = Enum.CameraType.Scriptable
	camera.FieldOfView = TOPDOWN_FOV

	-- 上空から真下を見るカメラ
	local pos = Vector3.new(LOOK_AT.X, TOPDOWN_HEIGHT, LOOK_AT.Z)
	local cf  = CFrame.new(pos, LOOK_AT) * CFrame.Angles(-math.rad(90), 0, 0)
	camera.CFrame = cf

	-- ユーザー操作のズーム無効化（保険）
	localPlayer.CameraMinZoomDistance = 0.5
	localPlayer.CameraMaxZoomDistance = 0.5

	lastCF  = cf
	lastFOV = TOPDOWN_FOV
end

--========================
-- 監視ループ（軽量）
--  初回適用後、ズレが出た時だけ補正
--========================
local function enable2DGuard()
	-- 既存ループ停止
	if conn then conn:Disconnect(); conn = nil end

	-- 初回適用
	apply2D()

	-- Heartbeatで軽く監視（毎フレーム再設定はしない）
	conn = RunService.Heartbeat:Connect(function()
		if camera.CameraType ~= Enum.CameraType.Scriptable
		or camera.FieldOfView ~= lastFOV
		or (camera.CFrame.Position - lastCF.Position).Magnitude > 0.01
		then
			apply2D()
		end
	end)
end

local function disableGuard()
	if conn then conn:Disconnect(); conn = nil end
end

--========================
-- 初期化：当面は必ず2D
--========================
if not DisplayMode:is2D() then
	DisplayMode:set("2D") -- 将来3D実装時はここで分岐
end
enable2DGuard()

-- クリーンアップ
script.Destroying:Connect(disableGuard)
```

### src/client/ui/ClientMain.client.lua
```lua
-- StarterPlayerScripts/UI/ClientMain.client.lua
-- v0.9.6-P1-3 Router＋Remote結線（NavClient注入／Logger導入／vararg不使用）
-- 仕様メモ:
--   * <ShopOpen> は **ClientMainのみ** で受信し、Router.show("shop", payload) に一本化。
--   * 言語コードは外部公開を "ja"/"en" に統一（"jp" を受信した場合は "ja" へ正規化して警告）
--   * print/warn を共通 Logger に置換（公開時は閾値で抑止可能）

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes")

--========================
-- Logger
--========================
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("ClientMain")  -- ★ for → scope に変更

-- 公開ビルドで抑止したい場合は INFO/WARN へ（Studioは Logger.DEBUG にしてもOK）
Logger.configure({
	level = Logger.INFO,
	timePrefix = true,
	dupWindowSec = 0.5,
})

LOG.info("boot")

--========================
-- Locale / LocaleUtil
--========================
local okLocale, Locale = pcall(function()
	return require(RS:WaitForChild("Config"):WaitForChild("Locale"))
end)
if not okLocale or type(Locale) ~= "table" then
	LOG.warn("Locale missing; using fallback")
	local _g = "en"
	Locale = {}
	function Locale.getGlobal() return _g end
	function Locale.setGlobal(v) _g = (v=="ja" or v=="jp") and "ja" or "en" end
	function Locale.t(_, key)
		if key == "TOAST_TITLE" then
			return (_g == "ja") and "通知" or "Notice"
		end
		return key
	end
end

-- 共通ユーティリティ（jp→ja / 不明は nil）
local LocaleUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("LocaleUtil"))

--========================
-- NavClient
--========================
local NavClient = require(RS:WaitForChild("SharedModules"):WaitForChild("NavClient"))

--========================
-- S→C
--========================
local HomeOpen    = Remotes:WaitForChild("HomeOpen")
local ShopOpen    = Remotes:WaitForChild("ShopOpen")
local StatePush   = Remotes:WaitForChild("StatePush")
local HandPush    = Remotes:WaitForChild("HandPush")
local FieldPush   = Remotes:WaitForChild("FieldPush")
local TakenPush   = Remotes:WaitForChild("TakenPush")
local ScorePush   = Remotes:WaitForChild("ScorePush")
local RoundReady  = Remotes:WaitForChild("RoundReady")
local StageResult = Remotes:WaitForChild("StageResult")

--========================
-- C→S
--========================
local ReqStartNewRun = Remotes:WaitForChild("ReqStartNewRun")
local ReqContinueRun = Remotes:WaitForChild("ReqContinueRun")
local Confirm        = Remotes:WaitForChild("Confirm")
local ReqRerollAll   = Remotes:WaitForChild("ReqRerollAll")
local ReqRerollHand  = Remotes:WaitForChild("ReqRerollHand")
local ShopDone       = Remotes:WaitForChild("ShopDone")
local BuyItem        = Remotes:WaitForChild("BuyItem")
local ShopReroll     = Remotes:WaitForChild("ShopReroll")
local ReqPick        = Remotes:WaitForChild("ReqPick")
local ReqSyncUI      = Remotes:WaitForChild("ReqSyncUI")
local DecideNext     = Remotes:WaitForChild("DecideNext")
local ReqSetLang     = Remotes:WaitForChild("ReqSetLang")

-- DEV
local DevGrantRyo  = Remotes:FindFirstChild("DevGrantRyo")
local DevGrantRole = Remotes:FindFirstChild("DevGrantRole")

-- ▼ レガシー（任意）：存在すれば Nav のバックアップ経路に使う
local GoHome   = Remotes:FindFirstChild("GoHome")
local GoNext   = Remotes:FindFirstChild("GoNext")
local SaveQuit = Remotes:FindFirstChild("SaveQuit")

-- ▼ Nav の生成（正準は DecideNext、レガシーは互換のみ）
local Nav = NavClient.new(DecideNext, {
	GoHome   = GoHome,
	GoNext   = GoNext,
	SaveQuit = SaveQuit,
})

--========================
-- Router 準備
--========================
local uiRoot = script.Parent:FindFirstChild("UI") or script.Parent
local ScreenRouterModule = uiRoot:FindFirstChild("ScreenRouter") or uiRoot:WaitForChild("ScreenRouter")
local ScreensFolder      = uiRoot:FindFirstChild("screens")      or uiRoot:WaitForChild("screens")

local Router
do
	local ok, mod = pcall(require, ScreenRouterModule)
	if not ok then
		LOG.warn("require(ScreenRouter) failed; stub used: %s", tostring(mod))
		mod = {}
	end
	if type(mod) ~= "table" then mod = {} end
	mod.init    = (type(mod.init)    == "function") and mod.init    or function(_) end
	mod.setDeps = (type(mod.setDeps) == "function") and mod.setDeps or function(_) end
	mod.show    = (type(mod.show)    == "function") and mod.show    or function(_) end
	mod.call    = (type(mod.call)    == "function") and mod.call    or function() end
	Router = mod
end

local Screens = {
	home   = require(ScreensFolder:WaitForChild("HomeScreen")),
	run    = require(ScreensFolder:WaitForChild("RunScreen")),
	shop   = require(ScreensFolder:WaitForChild("ShopScreen")),
	shrine = require(ScreensFolder:WaitForChild("ShrineScreen")),
}
Router.init(Screens)

Router.setDeps({
	playerGui = Players.LocalPlayer:WaitForChild("PlayerGui"),
	Confirm=Confirm, ReqPick=ReqPick, ReqRerollAll=ReqRerollAll, ReqRerollHand=ReqRerollHand,
	ShopDone=ShopDone, BuyItem=BuyItem, ShopReroll=ShopReroll,
	ReqStartNewRun=ReqStartNewRun, ReqContinueRun=ReqContinueRun, ReqSyncUI=ReqSyncUI,
	DecideNext=DecideNext, ReqSetLang=ReqSetLang,
	HandPush=HandPush, FieldPush=FieldPush, TakenPush=TakenPush, ScorePush=ScorePush, StatePush=StatePush,
	StageResult=StageResult,

	-- ▼ 追加：UI層へ Nav を配布（ResultModal → Nav.next("home"|"next"|"save")）
	Nav = Nav,

	-- ★ P0-7: トーストタイトルをロケールで切替（"jp" は受けたら "ja" として扱う）
	toast = function(msg, dur)
		pcall(function()
			local gl   = (type(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
			local lang = LocaleUtil.norm(gl) or "en"
			local title = (type(Locale.t)=="function" and Locale.t(lang, "TOAST_TITLE"))
			              or ((lang=="ja") and "通知" or "Notice")
			game.StarterGui:SetCore("SendNotification", {
				Title    = title,
				Text     = msg,
				Duration = dur or 2,
			})
		end)
	end,

	-- 参考：既存 remotes マップ（互換のためそのまま維持）
	remotes = {
		Confirm=Confirm, ReqPick=ReqPick, ReqRerollAll=ReqRerollAll, ReqRerollHand=ReqRerollHand,
		ShopDone=ShopDone, BuyItem=BuyItem, ShopReroll=ShopReroll,
		ReqStartNewRun=ReqStartNewRun, ReqContinueRun=ReqContinueRun, ReqSyncUI=ReqSyncUI,
		HandPush=HandPush, FieldPush=FieldPush, TakenPush=TakenPush, ScorePush=ScorePush, StatePush=StatePush,
		StageResult=StageResult, DecideNext=DecideNext, ReqSetLang=ReqSetLang,
		DevGrantRyo=DevGrantRyo, DevGrantRole=DevGrantRole,
		-- （必要なら）Nav もここへ見せたい場合は次行を有効化
		-- Nav = Nav,
	},
})

--========================================
-- S→C 配線（P0-5: ShopOpenはここだけ）
--========================================
HomeOpen.OnClientEvent:Connect(function(payload)
	if payload and payload.lang and type(Locale.setGlobal)=="function" then
		local nl = LocaleUtil.norm(payload.lang) or payload.lang
		Locale.setGlobal(nl)
	end
	Router.show("home", payload)
	LOG.info("Router.show -> home")
end)

ShopOpen.OnClientEvent:Connect(function(payload)
	-- P0-5: ClientMain が唯一の <ShopOpen> 受口
	local p = payload or {}
	-- 言語が来ていない場合は共有言語、"jp" が来たら "ja" に正規化
	if p.lang == nil then
		p.lang = (Locale.getGlobal and Locale.getGlobal()) or "en"
	end
	local nl = LocaleUtil.norm(p.lang)
	if nl and nl ~= p.lang then p.lang = nl end
	Router.show("shop", p)
	LOG.info("<ShopOpen> routed once | lang=%s", tostring(p.lang))
end)

RoundReady.OnClientEvent:Connect(function()
	local gl   = (type(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
	local lang = LocaleUtil.norm(gl) or "en"
	Router.show("run")
	if Router and type(Router.call)=="function" then
		Router.call("run", "setLang", lang)
		Router.call("run", "requestSync")
	end
	LOG.info("RoundReady → run | lang=%s", lang)
end)

StatePush.OnClientEvent:Connect(function(st)
	if st and st.lang and type(Locale.setGlobal)=="function" then
		local l = LocaleUtil.norm(st.lang)
		if l then Locale.setGlobal(l) end
	end
	if Router and type(Router.call)=="function" then
		Router.call("run", "onState", st)
	end
end)

HandPush.OnClientEvent:Connect(function(hand)
	if Router and type(Router.call)=="function" then Router.call("run", "onHand", hand) end
end)

FieldPush.OnClientEvent:Connect(function(field)
	if Router and type(Router.call)=="function" then Router.call("run", "onField", field) end
end)

TakenPush.OnClientEvent:Connect(function(taken)
	if Router and type(Router.call)=="function" then Router.call("run", "onTaken", taken) end
end)

ScorePush.OnClientEvent:Connect(function(total, roles, dtl)
	if Router and type(Router.call)=="function" then Router.call("run", "onScore", total, roles, dtl) end
end)

StageResult.OnClientEvent:Connect(function(payload)
	if Router and type(Router.call)=="function" then Router.call("run", "onStageResult", payload) end
end)

LOG.info("ready")
```

### src/client/ui/components/CardNode.lua
```lua
-- StarterPlayerScripts/UI/components/CardNode.lua
-- カード画像ボタン（画像・角丸・枠・軽い拡大アニメ）
-- 右側インフォ / 下部バッジはローカライズ（JA/EN）対応
-- 依存: ReplicatedStorage/SharedModules/CardImageMap.lua
-- 任意依存: ReplicatedStorage/Config/Theme.lua, ReplicatedStorage/Config/Locale.lua
-- v0.9.7-P1-4b:
--   ① 札は“真四角”に統一（UICorner/外枠UIStrokeを生成しない）
--   ② バッジは従来どおりカード幅いっぱい（Size=UDim2.new(1,0,0,h)）
--   ③ 言語正規化を LocaleUtil に統合（"jp"→"ja" 警告は維持）

local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local CardImageMap = require(RS:WaitForChild("SharedModules"):WaitForChild("CardImageMap"))
local LocaleUtil   = require(RS:WaitForChild("SharedModules"):WaitForChild("LocaleUtil"))

-- Optional: Theme / Locale
local Theme: any = nil
local Locale: any = nil
do
	local okCfg, cfg = pcall(function() return RS:FindFirstChild("Config") end)
	if okCfg and cfg then
		if cfg:FindFirstChild("Theme") then
			local okT, t = pcall(function() return require(cfg.Theme) end)
			if okT then Theme = t end
		end
		if cfg:FindFirstChild("Locale") then
			local okL, l = pcall(function() return require(cfg.Locale) end)
			if okL then Locale = l end
		end
	end
end

local M = {}

export type Info = {
	month: number?,  -- 1..12
	kind: string?,   -- "bright"|"seed"|"ribbon"|"chaff"|…（任意）
	name: string?,   -- 札の日本語名など
}

--========================
-- Theme helpers
--========================
local function kindColorFallback(kind: string?)
	if kind == "bright" then return Color3.fromRGB(255,230,140)
	elseif kind == "seed" then return Color3.fromRGB(200,240,255)
	elseif kind == "ribbon" then return Color3.fromRGB(255,200,220)
	else return Color3.fromRGB(235,235,235) end
end

local function colorForKind(kind: string?)
	if Theme and Theme.colorForKind then
		local ok, c = pcall(function() return Theme.colorForKind(kind) end)
		if ok and typeof(c) == "Color3" then return c end
	end
	return kindColorFallback(kind)
end

local function themeColor(key: string, fallback: Color3)
	local c = fallback
	if Theme and Theme.COLORS and typeof(Theme.COLORS[key]) == "Color3" then
		c = Theme.COLORS[key]
	end
	return c
end

local function themeImage(key: string, fallback: string)
	local id = fallback
	if Theme and Theme.IMAGES and typeof(Theme.IMAGES[key]) == "string" and #Theme.IMAGES[key] > 0 then
		id = Theme.IMAGES[key]
	end
	return id
end

--========================
-- Locale helpers（LocaleUtil 統合）
--========================
local function normLangJa(v: string?): string?
	local raw = tostring(v or ""):lower()
	local n = LocaleUtil.norm(raw) -- "ja"/"en" or nil
	if raw == "jp" and n == "ja" then
		warn("[CardNode] received legacy 'jp'; normalizing to 'ja'")
	end
	return n
end

-- "ja"/"en" のみ返す（Locale.getGlobal → Locale.pick → "en"）
local function curLang(): string
	-- 1) グローバル設定
	if Locale and typeof(Locale.getGlobal) == "function" then
		local ok, v = pcall(Locale.getGlobal)
		if ok then
			local n = LocaleUtil.norm(v)
			if n then return n end
		end
	end
	-- 2) OS/環境推奨
	if Locale and typeof(Locale.pick) == "function" then
		local ok, v = pcall(Locale.pick)
		if ok then
			local n = LocaleUtil.norm(v)
			if n then return n end
		end
	end
	-- 3) 既定
	return "en"
end

local function kindJP(kind: string?, fallbackName: string?): string
	if fallbackName and #fallbackName > 0 then return fallbackName end
	if kind == "bright" then return "光"
	elseif kind == "seed" then return "タネ"
	elseif kind == "ribbon" then return "短冊"
	elseif kind == "chaff" or kind == "kasu" then return "カス"
	else return "--" end
end

local function kindEN(kind: string?, fallbackName: string?): string
	if kind == "bright" then return "Bright"
	elseif kind == "seed" then return "Seed"
	elseif kind == "ribbon" then return "Ribbon"
	elseif kind == "chaff" or kind == "kasu" then return "Chaff"
	elseif fallbackName and fallbackName:match("^[%w%p%s]+$") then
		return fallbackName
	else
		return "--"
	end
end

-- JA: "11月/タネ" / EN: "11/Seed"（ENは単位「月」を省く）
local function footerText(monthNum: number?, kind: string?, name: string?, lang: string): string
	local m = tonumber(monthNum)
	local mStr = m and tostring(m) or ""
	if lang == "ja" then
		local k = kindJP(kind, name)
		return (mStr ~= "" and (mStr .. "月/" .. k)) or k
	else
		local k = kindEN(kind, name)
		return (mStr ~= "" and (mStr .. "/" .. k)) or k
	end
end

-- 右側インフォの文言（短め）
local function sideInfoText(monthNum: number?, kind: string?, name: string?, lang: string): string
	local m = tonumber(monthNum) or 0
	if lang == "ja" then
		return string.format("%d月 %s", m, (name and #name>0) and name or kindJP(kind))
	else
		return string.format("%s %s", tostring(m), kindEN(kind))
	end
end

--========================
-- 本体API
--========================
-- 後方互換 API:
--   create(parent, code, w?, h?, info?, showInfoRight?)
-- 新API（推奨）:
--   create(parent, code, opts)
--     opts = {
--       size: UDim2, pos: UDim2, anchor: Vector2, zindex: number,
--       info: Info, showInfoRight: boolean, -- cornerRadius は無効（真四角固定）
--     }
function M.create(parent: Instance, code: string, a: any?, b: any?, c: any?, d: any?)
	-- 画像ID
	local okImg, imgId = pcall(function() return CardImageMap.get(code) end)
	local imageId = (okImg and imgId) or ""

	-- 引数解釈
	local opts: any = nil
	local legacyW: number? = nil
	local legacyH: number? = nil
	local legacyInfo: Info? = nil
	local legacyShowRight: boolean? = nil

	if typeof(a) == "table" and (a.size or a.pos or a.anchor or a.info or a.showInfoRight) then
		opts = a
	else
		legacyW, legacyH, legacyInfo, legacyShowRight = a, b, c, d
	end

	-- レイアウト方針
	local useScale = (opts == nil and legacyW == nil and legacyH == nil)
	local W_SCALE = 0.12
	local H_SCALE = 0.90

	local btn = Instance.new("ImageButton")
	btn.Name = "Card_" .. tostring(code or "????")
	btn.Parent = parent
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
	btn.Image = imageId
	btn.ScaleType = Enum.ScaleType.Fit
	btn.Active = true

	-- ZIndex
	do
		local baseZ = (parent:IsA("GuiObject") and parent.ZIndex or 1) + 1
		btn.ZIndex = (opts and tonumber(opts.zindex)) or baseZ
	end

	-- サイズ決定
	if opts and opts.size then
		btn.Size = opts.size
		useScale = false
	elseif useScale then
		btn.Size = UDim2.fromScale(W_SCALE, H_SCALE)
	else
		local w = tonumber(legacyW) or 180
		local h = tonumber(legacyH) or 120
		btn.Size = UDim2.fromOffset(w, h)
	end

	-- 位置＆アンカー（指定があれば反映）
	if opts and opts.anchor then btn.AnchorPoint = opts.anchor end
	if opts and opts.pos    then btn.Position    = opts.pos    end

	-- 最小サイズの安全弁
	do
		local min = Instance.new("UISizeConstraint")
		min.MinSize = Vector2.new(56, 78) -- 約 63:88
		min.Parent = btn
	end

	-- ★ 真四角：UICorner/外枠UIStrokeは生成しない（＝角丸なし＆縁取りなし）
	-- （ここは意図的に何もしない）

	-- 影（Theme.IMAGES.dropShadow があれば使用）
	do
		local shadow = Instance.new("ImageLabel")
		shadow.Name = "Shadow"
		shadow.Parent = btn
		shadow.BackgroundTransparency = 1
		shadow.Image = themeImage("dropShadow", "rbxassetid://1316045217")
		shadow.ImageTransparency = (Theme and Theme.HandShadowOffT) or 0.70
		shadow.ScaleType = Enum.ScaleType.Slice
		shadow.SliceCenter = Rect.new(10,10,118,118)
		shadow.Size = UDim2.fromScale(1,1)
		shadow.ZIndex = btn.ZIndex - 1
	end

	-- アスペクト固定（横:縦=63:88、高さ基準）
	do
		local ar = Instance.new("UIAspectRatioConstraint")
		ar.AspectRatio = 63/88
		ar.DominantAxis = Enum.DominantAxis.Height
		ar.Parent = btn
	end

	-- クリック感（軽い拡大アニメ）
	do
		local function tweenTo(sz) TweenService:Create(btn, TweenInfo.new(0.06), { Size = sz }):Play() end
		local baseSize: UDim2 = btn.Size

		btn.MouseEnter:Connect(function()
			baseSize = btn.Size
		end)

		local function scaleMul(sz: UDim2, mul: number): UDim2
			if sz.X.Scale > 0 or sz.Y.Scale > 0 then
				return UDim2.new(sz.X.Scale * mul, sz.X.Offset, sz.Y.Scale * mul, sz.Y.Offset)
			else
				return UDim2.fromOffset(math.max(1, sz.X.Offset * mul), math.max(1, sz.Y.Offset * mul))
			end
		end

		btn.MouseButton1Down:Connect(function()
			baseSize = btn.Size
			tweenTo(scaleMul(baseSize, 1.04))
		end)

		local function restore() tweenTo(baseSize) end
		btn.MouseButton1Up:Connect(restore)
		btn.MouseLeave:Connect(restore)
	end

	-- 右側インフォの補助ラベル（必要なときのみ）
	local showInfoRight = (opts and opts.showInfoRight) or legacyShowRight
	local info: Info?    = (opts and opts.info) or legacyInfo
	if showInfoRight and info then
		local lab = Instance.new("TextLabel")
		lab.Name = "SideInfo"
		lab.Parent = btn
		lab.BackgroundTransparency = 1
		lab.TextScaled = true
		lab.Size = UDim2.new(0, 72, 0, 22) -- サイドはpx固定で視認性を保つ
		lab.Position = UDim2.new(1, 6, 0, 0)
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.TextYAlignment = Enum.TextYAlignment.Center
		lab.Font = Enum.Font.GothamMedium
		lab.Text = sideInfoText(info.month, info.kind, info.name, curLang())
		-- 補助ラベルの色は“役色”に寄せてアクセントを付ける
		lab.TextColor3 = colorForKind(info.kind)
		lab.ZIndex = btn.ZIndex + 1
	end

	return btn
end
... (truncated)
```

### src/client/ui/components/controllers/ShopWires.lua
```lua
-- src/client/ui/components/controllers/ShopWires.lua
-- v0.9.3-P1-3 ShopWires：Shop画面のイベント配線・UI更新のみ
-- ポリシー:
--  - リロールは「所持金>=費用」でのみ可否判定（残回数は見ない）
--  - 二重送出防止：UIを即時無効化し、nonce を付与してサーバへ送信
--  - UIの再有効化はサーバからの ShopOpen ペイロード受信時に判定して行う
--  - （重要）ShopOpen の受信は ClientMain に一本化。本モジュールはリスナーを持たない。
--  - P1-3: 共通 Logger 導入（print/warn を LOG.* へ）

local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat = require(SharedModules:WaitForChild("ShopFormat"))

-- Logger
local Logger = require(SharedModules:WaitForChild("Logger"))
local LOG    = Logger.scope("ShopWires")

local ShopI18n  = require(script.Parent.Parent:WaitForChild("i18n"):WaitForChild("ShopI18n"))

local M = {}

-- 内部: リロールボタン状態を payload から再評価して反映
local function applyRerollButtonState(self, payload)
  local p = payload or self._payload or {}
  local money = tonumber(p.mon or p.totalMon or 0) or 0
  local cost  = tonumber(p.rerollCost or 1) or 1
  local can   = (p.canReroll ~= false) and (money >= cost)
  if self._nodes and self._nodes.rerollBtn then
    self._nodes.rerollBtn.Active = can
    self._nodes.rerollBtn.AutoButtonColor = can
  end
end

function M.applyInfoPlaceholder(self)
  if not (self and self._nodes and self._nodes.infoText) then return end
  local lang = ShopFormat.normLang(self._lang)
  self._nodes.infoText.Text = ShopI18n.t(lang, "info_placeholder")
end

function M.wireButtons(self)
  local nodes = self._nodes
  if not nodes then return end

  nodes.closeBtn.Activated:Connect(function()
    if self._closing then return end
    self._closing = true
    LOG.info("close clicked")
    self:hide()
    if self.deps and self.deps.toast then
      local lang = ShopFormat.normLang(self._lang)
      self.deps.toast(ShopI18n.t(lang, "toast_closed"), 2)
    end
    if self.deps and self.deps.remotes and self.deps.remotes.ShopDone then
      self.deps.remotes.ShopDone:FireServer()
    end
    task.delay(0.2, function() self._closing = false end)
  end)

  -- リロール：nonce 付き送信 + 即時UI無効化（解除はサーバ応答時に行う）
  local rerollBusyDebounce = 0.3
  nodes.rerollBtn.Activated:Connect(function()
    if self._rerollBusy then return end
    if not (self.deps and self.deps.remotes and self.deps.remotes.ShopReroll) then return end

    self._rerollBusy = true

    -- 即時に押下不能にする（見た目はShopUIに委譲）
    if self._nodes and self._nodes.rerollBtn then
      self._nodes.rerollBtn.Active = false
    end

    -- nonce を付与して送信
    local nonce = HttpService:GenerateGUID(false)
    self._lastRerollNonce = nonce
    LOG.info("REROLL click → FireServer | nonce=%s", nonce)
    self.deps.remotes.ShopReroll:FireServer(nonce)

    -- debounce経過後にbusyフラグだけ解除（UIの再有効化はサーバ側のShopOpen受信時に行う）
    task.delay(rerollBusyDebounce, function()
      self._rerollBusy = false
      -- ここで self:_render() は呼ばない（旧payloadで再度有効化されるのを防ぐ）
    end)
  end)

  nodes.deckBtn.Activated:Connect(function()
    self._deckOpen = not self._deckOpen
    LOG.debug("deck toggle -> %s", tostring(self._deckOpen))
    self:_render()
  end)
end

-- ⚠ 非推奨：ShopOpenのリスナー接続は行わない。ClientMainが単独で受ける。
-- 互換用に「payloadを渡すとUIだけ更新する」関数を返す。
function M.attachRemotes(self, remotes, router)
  LOG.warn("attachRemotes is deprecated; ClientMain handles <ShopOpen>. UI will only refresh.")
  -- 互換クロージャ：外部で新payloadを受け取ったときに UI を更新するための関数
  return function(payload)
    -- 言語の注入（payload優先→既存→"en"）
    if payload and payload.lang and type(payload.lang) == "string" then
      self._lang = ShopFormat.normLang(payload.lang)
    end
    -- 画面表示＆描画（遷移はしない／Routerは使わない）
    self:show(payload)
    -- リロール可否の再評価
    applyRerollButtonState(self, payload)
  end
end

return M
```

### src/client/ui/components/DevTools.lua
```lua
-- StarterPlayerScripts/UI/components/DevTools.lua
-- Studio 専用の開発用チートボタン（+役 / +両）を右下に表示するコンポーネント

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

local DevTools = {}

export type Options = {
	grantRyoAmount: number?, -- +両 で付与する金額（既定: 1000）
	offsetX: number?,         -- 右端からのマージン（px, 既定: 10）
	offsetY: number?,         -- 下端からのマージン（px, 既定: 10）
	width: number?,           -- 全体幅（px, 既定: 160）
	height: number?,          -- 行高さ（px, 既定: 32）
}

function DevTools.create(parent: Instance, deps: any, opts: Options?)
	opts = opts or {}
	local grantRyoAmount = opts.grantRyoAmount or 1000
	local PADX = opts.offsetX or 10
	local PADY = opts.offsetY or 10
	local W    = opts.width   or 160
	local H    = opts.height  or 32

	local C = (Theme and Theme.COLORS) or {}
	local BTN_BG   = C.DevBtnBg   or Color3.fromRGB(35,130,90)
	local BTN_TEXT = C.DevBtnText or Color3.fromRGB(255,255,255)

	local row = Instance.new("Frame")
	row.Name = "DevTools"
	row.Parent = parent
	row.AnchorPoint = Vector2.new(1, 1)
	row.Position = UDim2.new(1, -PADX, 1, -PADY)
	row.Size = UDim2.new(0, W, 0, H)
	row.BackgroundTransparency = 1
	row.ZIndex = 999

	local layout = Instance.new("UIListLayout")
	layout.Parent = row
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Padding = UDim.new(0, 8)

	local function makeBtn(txt: string, onClick: ()->())
		local b = Instance.new("TextButton")
		b.Name = "Btn"
		b.Parent = row
		b.Size = UDim2.new(0, math.floor((W-8)/2), 1, 0)
		b.BackgroundColor3 = BTN_BG
		b.TextColor3 = BTN_TEXT
		b.Text = txt
		b.Font = Enum.Font.GothamBold
		b.TextScaled = true
		b.AutoButtonColor = true
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = b
		b.Activated:Connect(function()
			if typeof(onClick) == "function" then onClick() end
		end)
		return b
	end

	-- +役
	if deps and deps.DevGrantRole then
		makeBtn("+役", function()
			deps.DevGrantRole:FireServer()
		end)
	end

	-- +両
	if deps and deps.DevGrantRyo then
		makeBtn("+両", function()
			deps.DevGrantRyo:FireServer(grantRyoAmount)
		end)
	end

	return row
end

return DevTools
```

### src/client/ui/components/i18n/ShopI18n.lua
```lua
-- src/client/ui/components/i18n/ShopI18n.lua
-- v0.9.SIMPLE Shop専用I18nアダプタ（残回数系キーを撤去）

local M = {}

local en = {
  title_mvp           = "Shop (MVP)",
  deck_btn_show       = "View Deck",
  deck_btn_hide       = "Hide Deck",
  reroll_btn_fmt      = "Reroll (-%d)",

  info_title          = "Item Info",
  info_placeholder    = "(Hover or click an item)",

  deck_title_fmt      = "Current Deck (%d cards)",
  deck_empty          = "(no cards)",

  summary_cleared_fmt = "Cleared! Total:%d / Target:%d\nReward: %d mon (Have: %d)\n",
  summary_items_fmt   = "Items: %d",
  summary_money_fmt   = "Money: %d mon",

  close_btn           = "Close shop and next season",
  toast_closed        = "Closed the shop. On to next season.",

  label_category      = "Category: %s",
  label_price         = "Price: %s",
  no_desc             = "(no description)",
  insufficient_suffix = " (insufficient)",
}

local ja = {
  title_mvp           = "屋台（MVP）",
  deck_btn_show       = "デッキを見る",
  deck_btn_hide       = "デッキを隠す",
  reroll_btn_fmt      = "リロール（-%d 文）",

  info_title          = "アイテム情報",
  info_placeholder    = "（アイテムにマウスを乗せるか、クリックしてください）",

  deck_title_fmt      = "現在のデッキ（%d 枚）",
  deck_empty          = "(カード無し)",

  summary_cleared_fmt = "達成！ 合計:%d / 目標:%d\n報酬：%d 文（所持：%d 文）\n",
  summary_items_fmt   = "商品数: %d 点",
  summary_money_fmt   = "所持文: %d 文",

  close_btn           = "屋台を閉じて次の季節へ",
  toast_closed        = "屋台を閉じました。次の季節へ。",

  label_category      = "カテゴリ: %s",
  label_price         = "価格: %s",
  no_desc             = "(説明なし)",
  insufficient_suffix = "（不足）",
}

local dict = { en = en, ja = ja }

local function pick(lang:string?)
  lang = tostring(lang or ""):lower()
  if lang == "en" then return "en" end
  if lang == "ja" or lang == "jp" then return "ja" end
  return "ja"
end

function M.t(lang:string?, key:string, ...)
  local use = pick(lang)
  local pack = dict[use] or dict.ja
  local base = (pack and pack[key]) or (dict.en and dict.en[key]) or key
  if select("#", ...) > 0 then
    local ok, res = pcall(string.format, base, ...)
    if ok then return res else return base end
  end
  return base
end

return M
```

### src/client/ui/components/Overlay.lua
```lua
-- StarterPlayerScripts/UI/components/Overlay.lua
-- ローディング用オーバーレイ
-- v0.9.7-P1-4: Theme に完全寄せ（色・透過のフォールバック撤去／既定文言もTheme経由）

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

local M = {}

function M.create(parent: Instance, text: string?)
	--=== 背景（入力遮断＋半透明） ======================================
	local overlay = Instance.new("Frame")
	overlay.Name = "LoadingOverlay"
	overlay.Parent = parent
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = (Theme.COLORS and Theme.COLORS.OverlayBg) or Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = (Theme.overlayBgT ~= nil) and Theme.overlayBgT or 0.35
	overlay.Visible = false
	overlay.ZIndex = 50
	overlay.Active = true            -- 入力を遮断

	--=== メッセージ =====================================================
	local msg = Instance.new("TextLabel")
	msg.Name = "Msg"
	msg.Parent = overlay
	msg.BackgroundTransparency = 1
	msg.TextScaled = true
	msg.Size = UDim2.new(0, 480, 0, 48)
	msg.Position = UDim2.new(0.5, 0, 0.5, 0)
	msg.AnchorPoint = Vector2.new(0.5, 0.5)
	msg.TextXAlignment = Enum.TextXAlignment.Center
	msg.Font = Enum.Font.GothamMedium
	msg.TextColor3 = (Theme.COLORS and (Theme.COLORS.PrimaryBtnText or Color3.fromRGB(255,255,255)))
		or Color3.fromRGB(255, 255, 255)
	msg.Text = text or Theme.loadingText or Theme.helpText or "読み込み中..."

	--=== API ============================================================
	local api = {}

	function api:show()
		overlay.Visible = true
	end

	function api:hide()
		overlay.Visible = false
	end

	function api:setText(t: string?)
		msg.Text = t or ""
	end

	function api:setTransparency(alpha: number)
		-- 0（不透明）〜1（完全透明）
		local a = tonumber(alpha)
		if a and a >= 0 and a <= 1 then
			overlay.BackgroundTransparency = a
		end
	end

	function api:destroy()
		pcall(function() overlay:Destroy() end)
	end

	return api
end

return M
```

### src/client/ui/components/renderers/FieldRenderer.lua
```lua
-- StarterPlayerScripts/UI/components/renderers/FieldRenderer.lua
-- 場札の描画レンダラ：上下2段に分けて配置
-- v0.9.7-P1-4: Theme 完全デフォルト化 + 札フッタを常にカード幅いっぱい
--              言語コード正規化（"jp"→"ja"）/ JP時の英語カテゴリ混入を修正

local components = script.Parent.Parent
local lib        = components.Parent:WaitForChild("lib")

local UiUtil   = require(lib:WaitForChild("UiUtil"))
local CardNode = require(components:WaitForChild("CardNode"))

-- ★ 依存
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config  = ReplicatedStorage:WaitForChild("Config")
local Locale  = require(Config:WaitForChild("Locale"))
local Theme   = require(Config:WaitForChild("Theme"))

-- 言語（"ja"/"en"）。"jp" は "ja" へ正規化、取得不可は "en"
local function _lang()
	local v
	if typeof(Locale.getGlobal) == "function" then
		local ok, g = pcall(Locale.getGlobal); if ok then v = g end
	end
	if v == nil and typeof(Locale.pick) == "function" then
		local ok, p = pcall(Locale.pick); if ok then v = p end
	end
	v = tostring(v or "en"):lower()
	if v == "jp" then return "ja" end
	if v == "ja" or v == "en" then return v end
	return "en"
end

--=== フッタ用ユーティリティ ============================================

-- カテゴリの英語ラベル（短め）
local function _catEn(src)
	src = tostring(src or ""):lower()
	if src=="光" or src=="ひかり" or src=="hikari" or src=="bright" then return "Bright" end
	if src=="タネ" or src=="種"   or src=="tane"   or src=="seed"   then return "Seed"   end
	if src=="短冊"               or src=="ribbon"                       then return "Ribbon" end
	if src=="カス" or src=="kasu" or src=="chaff"                      then return "Chaff"  end
	return src
end

-- カテゴリの日本語ラベル（英語/表記ゆれを吸収）
local function _catJa(src)
	src = tostring(src or ""):lower()
	if src=="bright" or src=="光" or src=="ひかり" or src=="hikari" then return "光"   end
	if src=="seed"   or src=="タネ" or src=="種"   or src=="tane"   then return "タネ" end
	if src=="ribbon" or src=="短冊"                                 then return "短冊" end
	if src=="chaff"  or src=="kasu" or src=="カス"                  then return "カス"  end
	return src
end

-- フッタ表示テキスト（JP: "11月/タネ" ／ EN: "11/Seed"）
local function makeFooterText(monthNum, kindOrName, lang)
	local m = tonumber(monthNum)
	local mStr = m and tostring(m) or ""
	if lang == "en" then
		local cat = _catEn(kindOrName)
		if mStr ~= "" and cat ~= "" then
			return string.format("%s/%s", mStr, cat)
		elseif mStr ~= "" then
			return mStr
		else
			return cat
		end
	else
		local cat = _catJa(kindOrName)
		if mStr ~= "" and cat ~= "" then
			return string.format("%s月/%s", mStr, cat)
		elseif mStr ~= "" then
			return (mStr .. "月")
		else
			return cat
		end
	end
end

-- カード下部にフッタバッジを追加（カード幅いっぱい）
local function addFooter(node: Instance, text: string, kindForColor: string?)
	-- 既存 Footer を除去
	local old = node:FindFirstChild("Footer")
	if old then old:Destroy() end

	local SZ   = Theme.SIZES or {}
	local COL  = Theme.COLORS or {}
	local badgeH = SZ.BadgeH or 26

	local footer = Instance.new("Frame")
	footer.Name = "Footer"
	footer.Parent = node
	footer.AnchorPoint = Vector2.new(0,1)
	footer.Position = UDim2.new(0, 0, 1, -2)              -- 下に 2px マージン
	footer.Size     = UDim2.new(1, 0, 0, badgeH)          -- ★カード幅いっぱい
	footer.BackgroundColor3 = COL.BadgeBg or Color3.fromRGB(25,28,36)
	footer.BackgroundTransparency = 0.15
	footer.BorderSizePixel = 0
	footer.ZIndex = 10
	footer.ClipsDescendants = true

	local uic = Instance.new("UICorner")
	uic.CornerRadius = UDim.new(0, Theme.PANEL_RADIUS or 10)
	uic.Parent = footer

	local stroke = Instance.new("UIStroke")
	stroke.Color = COL.BadgeStroke or Color3.fromRGB(60,65,80)
	stroke.Thickness = 1
	stroke.Parent = footer

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, 6)
	pad.PaddingRight  = UDim.new(0, 6)
	pad.PaddingTop    = UDim.new(0, 2)
	pad.PaddingBottom = UDim.new(0, 2)
	pad.Parent = footer

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Parent = footer
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = tostring(text or "")
	label.Font = Enum.Font.GothamMedium
	label.TextScaled = true
	-- 役種に応じた文字色（Theme.colorForKind）。該当なしは白っぽく。
	local txtColor = (type(Theme.colorForKind)=="function" and Theme.colorForKind(kindForColor or "")) or Color3.fromRGB(235,235,235)
	label.TextColor3 = txtColor
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 11
end
--=======================================================================

local M = {}

-- opts:
--   width:number?         -- 未指定ならスケールレイアウト（推奨）
--   height:number?        -- 未指定ならスケールレイアウト（推奨）
--   rowPaddingScale:number?  -- カード間隔（比率）。未指定は Theme.RATIOS.COL_GAP
--   onPick:(bindex:number)->()      -- 場札クリック時に呼ぶ
function M.render(topRow: Instance, bottomRow: Instance, field: {any}?, opts: {width:number?, height:number?, rowPaddingScale:number?, onPick:any}? )
	opts = opts or {}
	local useScale = (opts.width == nil and opts.height == nil)
	local W = opts.width  or 80
	local H = opts.height or 96
	local R = Theme.RATIOS or {}
	local padScale = (typeof(opts.rowPaddingScale) == "number" and opts.rowPaddingScale) or R.COL_GAP or 0.015
	local onPick = opts.onPick

	-- 既存をクリア
	UiUtil.clear(topRow, {})
	UiUtil.clear(bottomRow, {})

	-- 行レイアウト（横並び・両端にも同じ余白）
	local function ensureRowLayout(row: Instance)
		local layout = Instance.new("UIListLayout")
		layout.Parent = row
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(padScale, 0)

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft  = UDim.new(padScale, 0)
		pad.PaddingRight = UDim.new(padScale, 0)
		pad.Parent = row

		return layout, pad
	end

	ensureRowLayout(topRow)
	ensureRowLayout(bottomRow)

	local list = field or {}
	local n = #list
	local split = math.ceil(n/2) -- 前半=上段、後半=下段
	local topCount = math.min(split, n)
	local bottomCount = math.max(0, n - split)

	-- 行ごとのカード幅（scale）
	local function calcWScale(count: number): number
		if count <= 0 then return 0.12 end
		local raw = (1 - padScale * (count + 1)) / count -- 両端＋間の余白
		if raw < 0.08 then raw = 0.08 end
		if raw > 0.18 then raw = 0.18 end
		return raw
	end

	local W_TOP    = calcWScale(topCount)
	local W_BOTTOM = calcWScale(bottomCount)
	local langNow  = _lang()

	for i, card in ipairs(list) do
		local code = card.code or string.format("%02d%02d", card.month, card.idx)
		local parentRow = (i <= split) and topRow or bottomRow
		local rowWScale = (i <= split) and W_TOP or W_BOTTOM

		local node
		if useScale then
			-- スケールレイアウト：横幅は行の枚数に応じて最適化
			node = CardNode.create(parentRow, code, nil, nil, {
				month = card.month, kind = card.kind, name = card.name
			})
			node.Size = UDim2.fromScale(rowWScale, 0.90)
		else
			-- 互換：px 指定
			node = CardNode.create(parentRow, code, W, H, {
				month = card.month, kind = card.kind, name = card.name
			})
		end

		node:SetAttribute("bindex", i)
		node.LayoutOrder = i

		-- ▼ 言語対応のフッタ（EN: "11/Seed" / JP: "11月/タネ"）
		local footerText = makeFooterText(card.month, card.kind or card.name, langNow)
		addFooter(node, footerText, card.kind)

		-- クリック
		if onPick then
			node.MouseButton1Click:Connect(function()
				onPick(i)
			end)
		end
	end
end

return M
```

### src/client/ui/components/renderers/HandRenderer.lua
```lua
-- StarterPlayerScripts/UI/components/renderers/HandRenderer.lua
-- 手札を描画。selectedIndex のハイライトは内部で管理（縁取りは使わず影だけで強調）

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

local components = script.Parent.Parent
local CardNode   = require(components:WaitForChild("CardNode"))

local M = {}

--========================
-- 言語/フッタユーティリティ
--========================
local function _lang()
	-- "jp" を "ja" に正規化。取得不可時は "en"
	local v = nil
	if typeof(Locale.getGlobal) == "function" then
		local ok, g = pcall(Locale.getGlobal); if ok then v = g end
	end
	if v == nil and typeof(Locale.pick) == "function" then
		local ok, p = pcall(Locale.pick); if ok then v = p end
	end
	v = tostring(v or "en"):lower()
	if v == "jp" then return "ja" end
	if v == "ja" or v == "en" then return v end
	return "en"
end

local function _catEn(v)
	v = tostring(v or ""):lower()
	if v=="光" or v=="ひかり" or v=="hikari" or v=="bright" then return "Bright" end
	if v=="タネ" or v=="種" or v=="tane" or v=="seed"   then return "Seed"   end
	if v=="短冊" or v=="ribbon"                         then return "Ribbon" end
	if v=="カス" or v=="kasu" or v=="chaff"            then return "Chaff"  end
	return v
end

local function _catJp(v)
	v = tostring(v or ""):lower()
	if v=="bright" or v=="光"                 then return "光"   end
	if v=="seed"   or v=="タネ" or v=="種"   then return "タネ" end
	if v=="ribbon" or v=="短冊"               then return "短冊" end
	if v=="chaff"  or v=="kasu" or v=="カス" then return "カス"  end
	return v
end

-- JP: "11月/タネ" / EN: "11/Seed"（英語は「月」を省く）
local function makeFooterText(monthNum, cat, lang)
	local m = tonumber(monthNum)
	local mStr = m and tostring(m) or ""
	if lang == "en" then
		local catEn = _catEn(cat)
		if mStr ~= "" and catEn ~= "" then
			return string.format("%s/%s", mStr, catEn)
		elseif mStr ~= "" then
			return mStr
		else
			return catEn
		end
	else
		local catJp = _catJp(cat)
		if mStr ~= "" and catJp ~= "" then
			return string.format("%s月/%s", mStr, catJp)
		elseif mStr ~= "" then
			return (mStr .. "月")
		else
			return catJp
		end
	end
end

-- カード下部にフッタ（カード幅いっぱい）
local function addFooter(node: Instance, text: string, kindForColor: string?)
	-- 既存削除
	local old = node:FindFirstChild("Footer")
	if old then old:Destroy() end

	local C = (Theme and Theme.COLORS) or {}
	local badgeH = (Theme and Theme.SIZES and Theme.SIZES.BadgeH) or 26

	local footer = Instance.new("Frame")
	footer.Name = "Footer"
	footer.Parent = node
	footer.AnchorPoint = Vector2.new(0,1)
	-- 下に 2px の余白を残して、幅は常にカードと同じ
	footer.Position = UDim2.new(0, 0, 1, -2)
	footer.Size = UDim2.new(1, 0, 0, badgeH)
	footer.BackgroundColor3 = C.BadgeBg or Color3.fromRGB(25,28,36)
	footer.BackgroundTransparency = 0.15
	footer.BorderSizePixel = 0
	footer.ZIndex = 10
	footer.ClipsDescendants = true

	local uic = Instance.new("UICorner"); uic.CornerRadius = UDim.new(0, (Theme and Theme.PANEL_RADIUS) or 10); uic.Parent = footer
	local stroke = Instance.new("UIStroke"); stroke.Color = C.BadgeStroke or Color3.fromRGB(60,65,80); stroke.Thickness = 1; stroke.Parent = footer

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, 6)
	pad.PaddingRight  = UDim.new(0, 6)
	pad.PaddingTop    = UDim.new(0, 2)
	pad.PaddingBottom = UDim.new(0, 2)
	pad.Parent = footer

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Parent = footer
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = tostring(text or "")
	label.Font = Enum.Font.GothamMedium
	label.TextScaled = true
	-- 役種に応じたバッジ文字色（Theme.colorForKind）。該当なしは白。
	local badgeTextColor = (type(Theme.colorForKind)=="function" and Theme.colorForKind(kindForColor or "")) or Color3.fromRGB(235,235,235)
	label.TextColor3 = badgeTextColor
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 11
end

--========================
-- 選択ハイライト（縁取りは使わない）
--========================
local SHADOW_ON_ALPHA  = (Theme and Theme.HandShadowOnT  ~= nil) and Theme.HandShadowOnT  or 0.45  -- 0=不透明（濃い影）
local SHADOW_OFF_ALPHA = (Theme and Theme.HandShadowOffT ~= nil) and Theme.HandShadowOffT or 0.70

local function highlight(container: Instance, selectedIndex: number?)
	for _,node in ipairs(container:GetChildren()) do
		if node:IsA("ImageButton") or node:IsA("TextButton") then
			local myIdx = node:GetAttribute("index")
			local on = (selectedIndex ~= nil and myIdx == selectedIndex)

			-- 縁取りは一切使わない（UIStrokeを触らない）

			-- 影でハイライト（CardNode 側の Shadow:ImageLabel を利用）
			local shadow = node:FindFirstChild("Shadow")
			if shadow and shadow:IsA("ImageLabel") then
				shadow.ImageTransparency = on and SHADOW_ON_ALPHA or SHADOW_OFF_ALPHA
			end

			-- TextButtonの枠は常に消す
			if node:IsA("TextButton") then
				node.BorderSizePixel = 0
			end
		end
	end
end

-- 子を掃除
local function clear(container: Instance)
	for _,c in ipairs(container:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("ImageButton") or c:IsA("TextLabel")
			or c:IsA("Frame") or c:IsA("ImageLabel") or c:IsA("UIListLayout") or c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

--========================
-- API
--========================
-- render(container, hand, { width, height, selectedIndex, onSelect, paddingScale })
--  - width/height 未指定 → 比率レイアウト（各カードは高さ90%、横幅は手札枚数から自動算出）
--  - width/height 指定   → pxレイアウト（互換）
--  - paddingScale       → カード間の横間隔（比率）。既定 0.02（= 2%）
function M.render(container: Instance, hand: {any}?, opts: {width:number?, height:number?, selectedIndex:number?, onSelect:(number)->()? , paddingScale:number?})
	opts = opts or {}
	local useScale = (opts.width == nil and opts.height == nil)
	local w = opts.width  or 90
	local h = opts.height or 150
	local gapScale = (typeof(opts.paddingScale) == "number" and opts.paddingScale) or 0.02

	clear(container)

	-- 並べ方：横並び（比率Padding）＋左右にも同じ余白を付与
	local layout = Instance.new("UIListLayout")
	layout.Parent = container
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(gapScale, 0)

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft  = UDim.new(gapScale, 0)
	pad.PaddingRight = UDim.new(gapScale, 0)
	pad.Parent = container

	-- 手札枚数に応じて横幅スケールを自動算出
	local count = #(hand or {})
	local function calcWScale(n: number): number
		if n <= 0 then return 0.12 end
		local raw = (1 - gapScale * (n + 1)) / n
		if raw < 0.09 then raw = 0.09 end
		if raw > 0.16 then raw = 0.16 end
		return raw
	end
	local W_SCALE = useScale and calcWScale(count) or nil
	local H_SCALE = 0.90
	local langNow = _lang()

	-- カードを生成して並べる
	for i, card in ipairs(hand or {}) do
		local code = card.code or string.format("%02d%02d", card.month, card.idx)

		local node
		if useScale then
			node = CardNode.create(container, code, nil, nil, {
				month = card.month, kind = card.kind, name = card.name
			})
			node.Size = UDim2.fromScale(W_SCALE, H_SCALE)
		else
			node = CardNode.create(container, code, w, h, {
				month = card.month, kind = card.kind, name = card.name
			})
		end

		node:SetAttribute("index", i)

		-- ▼ 言語対応のフッタ（EN: "11/Seed" / JP: "11月/タネ"）— 幅は常にカードいっぱい
		local footerText = makeFooterText(card.month, card.kind or card.name, langNow)
		addFooter(node, footerText, card.kind)

		if typeof(opts.onSelect) == "function" then
			node.MouseButton1Click:Connect(function()
				opts.onSelect(i)
				-- 内部ハイライトも即時更新（影だけで表現）
				highlight(container, i)
			end)
		end
	end

	-- 初期ハイライト
	highlight(container, opts.selectedIndex)
end

return M
```

### src/client/ui/components/renderers/ShopRenderer.lua
```lua
-- StarterPlayerScripts/UI/screens/ShopRenderer.lua
-- v0.9.SIMPLE-7
--  - 下段 TalismanArea に護符ボードをマウント（初回のみ）
--  - payload.talisman を表示（nilならデフォルト6枠表示）
--  - items を描画前に self:isItemHidden(id) でフィルタ（既存）

local RS = game:GetService("ReplicatedStorage")
local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat = require(SharedModules:WaitForChild("ShopFormat"))

local Logger = require(SharedModules:WaitForChild("Logger"))
local LOG    = Logger.scope("ShopRenderer")

local ShopCells = require(script.Parent.Parent:WaitForChild("ShopCells"))
local ShopI18n  = require(script.Parent.Parent:WaitForChild("i18n"):WaitForChild("ShopI18n"))

-- TalismanBoard の安全取得（UI/components から辿る）
local function requireTalismanBoard()
	local uiRoot = script:FindFirstAncestor("UI")
	if not uiRoot then return nil end
	local comps = uiRoot:FindFirstChild("components")
	if not comps then return nil end
	local mod = comps:FindFirstChild("TalismanBoard")
	if mod and mod:IsA("ModuleScript") then
		local ok, tb = pcall(function() return require(mod) end)
		if ok then return tb end
	end
	return nil
end

local M = {}

local function isTalismanItem(it: any): boolean
	return typeof(it) == "table" and (it.category == "talisman") and (it.talismanId ~= nil)
end

function M.render(self)
	local nodes = self._nodes
	if not nodes then return end

	local p = self._payload or {}
	local items = p.items or p.stock or {}
	local lang = self._lang or ShopFormat.normLang(p.lang)
	local mon = tonumber(p.mon or p.totalMon or 0) or 0
	local rerollCost = tonumber(p.rerollCost or 1) or 1

	-- ★ 護符ボード（初回マウント）
	if nodes.taliArea and not self._taliBoard then
		local TB = requireTalismanBoard()
		if TB then
			self._taliBoard = TB.new(nodes.taliArea, {
				title = (lang == "ja") and "護符ボード" or "Talisman Board",
				widthScale = 0.9,
				padScale   = 0.01,
			})
			local inst = self._taliBoard:getInstance()
			inst.AnchorPoint = Vector2.new(0.5, 0)
			inst.Position    = UDim2.fromScale(0.5, 0)
			inst.ZIndex      = 2
		else
			LOG.warn("TalismanBoard module not found; skip mount")
		end
	end
	-- データ反映（存在すれば）
	if self._taliBoard then
		local langFix = (lang == "ja") and "ja" or "en"
		self._taliBoard:setLang(langFix)
		-- p.talisman が来なければ内部で defaultData() が出る想定
		self._taliBoard:setData(p.talisman)
	end

	-- ★ 一時SoldOutフィルタ
	local vis = {}
	for _, it in ipairs(items) do
		local id = it and it.id
		local hidden = false
		if typeof(self.isItemHidden) == "function" then
			local ok, h = pcall(function() return self:isItemHidden(id) end)
			hidden = ok and (h == true)
		end
		if not hidden then
			table.insert(vis, it)
		end
	end

	LOG.debug("render | lang=%s items=%d→%d mon=%d rerollCost=%d",
		tostring(lang), #items, #vis, mon, rerollCost)

	-- タイトル・ボタン
	if nodes.title then
		nodes.title.Text = ShopI18n.t(lang, "title_mvp")
	end
	if nodes.deckBtn then
		local txt = self._deckOpen and ShopI18n.t(lang, "deck_btn_hide") or ShopI18n.t(lang, "deck_btn_show")
		nodes.deckBtn.Text = txt
	end
	if nodes.rerollBtn then
		nodes.rerollBtn.Text = ShopI18n.t(lang, "reroll_btn_fmt", rerollCost)
		local can = (p.canReroll ~= false) and (mon >= rerollCost)
		nodes.rerollBtn.Active = can
		nodes.rerollBtn.AutoButtonColor = can
		nodes.rerollBtn.TextTransparency = 0
		nodes.rerollBtn.BackgroundTransparency = 0
	end
	if nodes.infoTitle then
		nodes.infoTitle.Text = ShopI18n.t(lang, "info_title")
	end
	if nodes.closeBtn then
		nodes.closeBtn.Text = ShopI18n.t(lang, "close_btn")
	end

	-- 右パネル
	do
		local deckPanel = nodes.deckPanel
		local infoPanel = nodes.infoPanel
		local deckTitle = nodes.deckTitle
		local deckText  = nodes.deckText

		if deckPanel and infoPanel then
			deckPanel.Visible = self._deckOpen
			infoPanel.Visible = not self._deckOpen
		end

		if deckPanel and deckTitle and deckText then
			local n, lst = ShopFormat.deckListFromSnapshot(p.currentDeck)
			deckTitle.Text = ShopI18n.t(lang, "deck_title_fmt", n)
			deckText.Text  = (n > 0) and lst or ShopI18n.t(lang, "deck_empty")
		end
	end

	-- 左グリッド再構築
	local scroll = nodes.scroll
	if not scroll then return end
	for _, ch in ipairs(scroll:GetChildren()) do
		if ch:IsA("GuiObject") and ch ~= nodes.grid then
			ch:Destroy()
		end
	end

	-- BUY ハンドラ
	local function onBuy(it: any)
		if self._buyBusy then return end

		if isTalismanItem(it) then
			LOG.info("BUY click (auto place) | id=%s name=%s taliId=%s",
				tostring(it.id or "?"), tostring(it.name or "?"), tostring(it.talismanId))
			if typeof(self.autoPlace) == "function" then
				self:autoPlace(it.talismanId, it)
			else
				LOG.warn("autoPlace is not available on host; skip BUY for talisman")
			end
			return
		end

		if not (self.deps and self.deps.remotes and self.deps.remotes.BuyItem) then
			LOG.warn("remotes.BuyItem is missing; cannot buy id=%s", tostring(it and it.id))
			return
		end
		self._buyBusy = true
		LOG.info("BUY click | id=%s name=%s", tostring(it.id or "?"), tostring(it.name or "?"))
		self.deps.remotes.BuyItem:FireServer(it.id)
		task.delay(0.25, function() self._buyBusy = false end)
	end

	for _, it in ipairs(vis) do
		ShopCells.create(scroll, nodes, it, lang, mon, { onBuy = onBuy })
	end

	-- CanvasSize
	task.defer(function()
		local gridObj = nodes.grid
		if not gridObj then return end
		local frameW = scroll.AbsoluteSize.X
		local cellW = gridObj.CellSize.X.Offset + gridObj.CellPadding.X.Offset
		local perRow = math.max(1, math.floor(frameW / math.max(1, cellW)))
		local rows = math.ceil(#vis / perRow)
		local cellH = gridObj.CellSize.Y.Offset + gridObj.CellPadding.Y.Offset
		local needed = rows * cellH + 8
		scroll.CanvasSize = UDim2.new(0, 0, 0, needed)
	end)

	-- サマリ
	local s = {}
	if p.seasonSum ~= nil or p.target ~= nil or p.rewardMon ~= nil then
		table.insert(s, ShopI18n.t(
			lang,
			"summary_cleared_fmt",
			tonumber(p.seasonSum or 0),
			tonumber(p.target or 0),
			tonumber(p.rewardMon or 0),
			tonumber(p.totalMon or mon or 0)
		))
	end
	table.insert(s, ShopI18n.t(lang, "summary_items_fmt", #vis))
	table.insert(s, ShopI18n.t(lang, "summary_money_fmt", mon))
	if nodes.summary then
		nodes.summary.Text = table.concat(s, "\n")
	end
end

return M
```

### src/client/ui/components/renderers/TakenRenderer.lua
```lua
-- StarterPlayerScripts/UI/components/renderers/TakenRenderer.lua
-- 取り札描画（右枠拡張版）
-- 分類: 光 / タネ / 短冊 / カス（言語で Bright / Seed / Ribbon / Chaff に自動切替）
-- 各カテゴリは 1月→12月 で並び、カードは横方向に 1/3 だけ重ねて表示
-- タグは不透明のパネル色ベース＋濃色文字、タグの“直下”からカードを開始
-- v0.9.7-P1-4: Theme 完全デフォルト化（色/角丸/余白/比率のUI側フォールバック撤去）
-- v0.9.7-P1-1: 言語コード外部I/Fを "ja"/"en" に統一（受信 "jp" は警告して "ja" へ正規化）
-- v0.9.7-P2-2: 言語正規化を LocaleUtil に統合（curLang も共通化）

local RS      = game:GetService("ReplicatedStorage")
local Config  = RS:WaitForChild("Config")
local Theme   = require(Config:WaitForChild("Theme"))
local Locale  = require(Config:WaitForChild("Locale"))
local LocaleUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("LocaleUtil"))

-- CardNode（カード1枚の描画モジュール）
local UI_ROOT  = script.Parent.Parent
local CardNode = require(UI_ROOT:WaitForChild("CardNode"))

local M = {}

-- ===== 内部 util =====
local function clearChildrenExceptLayouts(parent: Instance)
	for _, ch in ipairs(parent:GetChildren()) do
		if not ch:IsA("UIListLayout") and not ch:IsA("UIGridLayout")
			and not ch:IsA("UITableLayout") and not ch:IsA("UIPageLayout")
			and not ch:IsA("UIAspectRatioConstraint") and not ch:IsA("UISizeConstraint")
			and not ch:IsA("UITextSizeConstraint")
		then
			ch:Destroy()
		end
	end
end

-- "jp" → "ja" 正規化（LocaleUtil 統合）
local function normLangJa(v: string?): string?
	local raw = tostring(v or ""):lower()
	local n = LocaleUtil.norm(raw) -- "ja"/"en" or nil
	if raw == "jp" and n == "ja" then
		warn("[TakenRenderer] received legacy 'jp'; normalizing to 'ja'")
	end
	return n
end

-- 現在言語（"ja"/"en"。取得不可なら "en"）…LocaleUtil へ寄せる
local function curLang(): string
	-- safeGlobal が取れればそれを、なければ pickInitial（内部で pick→"en" フォールバック）
	return LocaleUtil.safeGlobal() or LocaleUtil.pickInitial() or "en"
end

-- kind名 → 表示カテゴリ名（JA/EN）
local CATEGORY_JA = { bright = "光",     seed = "タネ",   ribbon = "短冊",  chaff = "カス",   kasu = "カス" }
local CATEGORY_EN = { bright = "Bright", seed = "Seed",   ribbon = "Ribbon", chaff = "Chaff", kasu = "Chaff" }
-- 表示順（固定）
local CAT_ORDER_JA = { "光", "タネ", "短冊", "カス" }
local CAT_ORDER_EN = { "Bright", "Seed", "Ribbon", "Chaff" }

-- 役色：Theme.colorForKind を最優先（未定義時は Theme.COLORS の安全色）
local function kindColor(kind: string): Color3
	if Theme and Theme.colorForKind then
		local ok, c = pcall(function() return Theme.colorForKind(kind) end)
		if ok and typeof(c) == "Color3" then return c end
	end
	local C = Theme.COLORS
	return (C and (C.BadgeStroke or C.PanelStroke or C.TextDefault)) or Color3.new(1,1,1)
end

-- 63:88 の実寸横幅（高さから算出）
local function widthFromHeight(h: number): number
	return math.floor(h * (63/88))
end

-- 0101〜1204 の前2桁（月）
local function monthOf(code: string)
	local m = tonumber(string.sub(tostring(code or ""), 1, 2))
	return m or 99
end

--- takenCards: { {code="0101", kind="bright", month=1, name="松に鶴"}, ... }
function M.renderTaken(parent: Instance, takenCards: {any})
	if not parent or not parent.Destroy then return end
	clearChildrenExceptLayouts(parent)

	local lang      = curLang()
	local CAT_MAP   = (lang == "ja") and CATEGORY_JA or CATEGORY_EN
	local CAT_ORDER = (lang == "ja") and CAT_ORDER_JA or CAT_ORDER_EN

	-- バケット（キーは表示名で）
	local buckets = {}
	for _, key in ipairs(CAT_ORDER) do buckets[key] = {} end

	-- 仕分け
	for _, card in ipairs(takenCards or {}) do
		local kind = tostring(card.kind or "chaff")
		local catName = CAT_MAP[kind] or CAT_MAP["chaff"]
		table.insert(buckets[catName], card)
	end

	-- 1月→12月でソート
	for _, arr in pairs(buckets) do
		table.sort(arr, function(a, b) return monthOf(a.code) < monthOf(b.code) end)
	end

	-- レイアウト/見た目定数（Theme から取得）
	local S = Theme.SIZES or {}
	local C = Theme.COLORS or {}
	local R = Theme.RATIOS or {}

	-- カードは「半分サイズ」
	local baseH    = tonumber(S.HAND_H) or 168
	local cardH    = math.floor(baseH * 0.5)
	local cardW    = widthFromHeight(cardH)
	local overlap  = (R.TAKEN_OVERLAP ~= nil) and R.TAKEN_OVERLAP or 0.33
	local stepX    = math.max(1, math.floor(cardW * (1 - overlap)))

	-- 余白・寸法（Theme 寄せ）
	local padPx       = tonumber(S.PAD) or 10
	local sectionGap  = tonumber(S.ROW_GAP) or 12
	local gapBetween  = math.max(4, math.floor((S.HELP_H or 22) * 0.27)) -- タグとカード行の間
	local tagH        = tonumber(S.HELP_H) or 22
	local tagW        = tonumber(S.TAKEN_TAG_W) or 110
	local rowH        = cardH + 2
	local radiusPx    = tonumber(Theme.PANEL_RADIUS) or 10

	local usedHeight  = 0
	local parentZ     = (parent:IsA("GuiObject") and parent.ZIndex) or 1

	for _, catName in ipairs(CAT_ORDER) do
		local arr = buckets[catName]

		-- セクション枠（タグ行＋カード行の2段）
		local section = Instance.new("Frame")
		section.Name = "Section_" .. catName
		section.Parent = parent
		section.BackgroundTransparency = 1
		section.ClipsDescendants = false
		section.AutomaticSize = Enum.AutomaticSize.None
		section.Size = UDim2.new(1, -padPx*2, 0, tagH + gapBetween + rowH)
		section.Position = UDim2.new(0, padPx, 0, usedHeight)
		section.ZIndex = parentZ + 2    -- 木目より確実に前面

		-- === タグ行（不透明の PanelBg ＋ Stroke ＋ ドット） ===
		do
			local tag = Instance.new("Frame")
			tag.Name = "LabelTag"
			tag.Parent = section
			tag.BackgroundTransparency = 0
			tag.BackgroundColor3 = C.PanelBg
			tag.Position = UDim2.new(0, 0, 0, 0)
			tag.Size = UDim2.new(0, tagW, 0, tagH)
			tag.ZIndex = section.ZIndex + 1

			local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, radiusPx); cr.Parent = tag
			local st = Instance.new("UIStroke")
			st.Color = C.PanelStroke
			st.Thickness = 1
			st.Transparency = 0
			st.Parent = tag

			-- 種類の色ドット
			local kindGuess = "chaff"
			if catName == CATEGORY_JA.bright or catName == CATEGORY_EN.bright then kindGuess = "bright"
			elseif catName == CATEGORY_JA.seed or catName == CATEGORY_EN.seed then kindGuess = "seed"
			elseif catName == CATEGORY_JA.ribbon or catName == CATEGORY_EN.ribbon then kindGuess = "ribbon"
			end

			local dot = Instance.new("Frame")
			dot.Name = "KindDot"
			dot.Parent = tag
			dot.BackgroundColor3 = kindColor(kindGuess)
			dot.Size = UDim2.new(0, 10, 0, 10)
			dot.Position = UDim2.new(0, 8, 0.5, -5)
			dot.ZIndex = tag.ZIndex + 1
			local dcr = Instance.new("UICorner"); dcr.CornerRadius = UDim.new(0, 5); dcr.Parent = dot

			local lab = Instance.new("TextLabel")
			lab.Name = "Text"
			lab.Parent = tag
			lab.BackgroundTransparency = 1
			lab.Position = UDim2.new(0, 8 + 10 + 6, 0, 0)  -- ドットの右から文字
			lab.Size = UDim2.new(1, -(8 + 10 + 6 + 8), 1, 0)
			lab.TextXAlignment = Enum.TextXAlignment.Left
			lab.TextYAlignment = Enum.TextYAlignment.Center
			lab.TextSize = 14
			lab.Font = Enum.Font.GothamBold
			lab.ZIndex = tag.ZIndex + 1
			lab.Text = string.format("%s ×%d", catName, #arr)
			lab.TextColor3 = C.TextDefault
		end

		-- === カード行（タグの直下から開始） ===
		do
			local row = Instance.new("Frame")
			row.Name = "CardsRow"
			row.Parent = section
			row.BackgroundTransparency = 1
			row.Position = UDim2.new(0, 0, 0, tagH + gapBetween)
			row.Size = UDim2.new(1, 0, 0, rowH)
			row.ZIndex = section.ZIndex + 2

			local x = 0
			local z = row.ZIndex + 1
			for _, card in ipairs(arr) do
				local node
				if type(CardNode) == "table" and type(CardNode.create) == "function" then
					node = CardNode.create(row, card.code, {
						anchor = Vector2.new(0, 0),
						pos    = UDim2.new(0, x, 0, 1),
						size   = UDim2.fromOffset(cardW, cardH),
						zindex = z,
					})
				elseif type(CardNode) == "function" then
					node = CardNode(row, card.code, {
						anchor = Vector2.new(0, 0),
						pos    = UDim2.new(0, x, 0, 1),
						size   = UDim2.fromOffset(cardW, cardH),
						zindex = z,
					})
				elseif type(CardNode) == "table" and type(CardNode.new) == "function" then
					node = CardNode.new(row, card.code, {
						anchor = Vector2.new(0, 0),
						pos    = UDim2.new(0, x, 0, 1),
						size   = UDim2.fromOffset(cardW, cardH),
						zindex = z,
					})
				end

				-- 取り札カードにはフッタは付けない（見た目をすっきり）
				x += stepX
				z += 1
			end
		end

		usedHeight += (tagH + gapBetween + rowH) + sectionGap
	end

	-- ScrollingFrame の CanvasSize を手動設定（Auto でなければ）
	if parent:IsA("ScrollingFrame") then
		if parent.AutomaticCanvasSize == Enum.AutomaticSize.None then
			parent.CanvasSize = UDim2.new(0, 0, 0, usedHeight)
		end
	end

	-- 親が UIListLayout を持っている場合は、縦Paddingを詰める
	local list = parent:FindFirstChildOfClass("UIListLayout")
	if list then
		list.Padding = UDim.new(0, sectionGap)
		list.HorizontalAlignment = Enum.HorizontalAlignment.Left
		list.SortOrder = Enum.SortOrder.LayoutOrder
	end
end

return M
```

### src/client/ui/components/ResultModal.lua
```lua
-- StarterPlayerScripts/UI/components/ResultModal.lua
-- ステージ結果モーダル：3択／ワンボタン（final）両対応（Nav統一/ロック無効化対応）
-- v0.9.7-P1-4: Theme 完全デフォルト化（色／角丸／オーバーレイ透過／ボタン配色を Theme 参照に統一）

local M = {}

-- 型（Luau）
type NavIF = { next: (NavIF, string) -> () }
type Handlers = { home: (() -> ())?, next: (() -> ())?, save: (() -> ())?, final: (() -> ())? }
type ResultAPI = {
	hide: (ResultAPI) -> (),
	show: (ResultAPI, data: { rewardBank: number?, message: string?, clears: number? }?) -> (),
	showFinal: (ResultAPI, titleText: string?, descText: string?, buttonText: string?, onClick: (() -> ())?) -> (),
	setLocked: (ResultAPI, boolean, boolean) -> (),
	on: (ResultAPI, Handlers) -> (),
	bindNav: (ResultAPI, Nav: NavIF) -> (),
	destroy: (ResultAPI) -> (),
}

-- Theme 参照
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

--==================================================
-- 内部：ボタンのロック見た目
--==================================================
local function setLockedVisual(button: TextButton, locked: boolean)
	if not button then return end
	-- 初回に元色を保存
	if button:GetAttribute("OrigBG3") == nil then
		button:SetAttribute("OrigBG3", button.BackgroundColor3)
	end
	if button:GetAttribute("OrigTX3") == nil then
		button:SetAttribute("OrigTX3", button.TextColor3)
	end
	if button:GetAttribute("OrigText") == nil then
		button:SetAttribute("OrigText", button.Text)
	end

	local baseText = button:GetAttribute("OrigText") or button.Text
	if locked then
		button.AutoButtonColor = false
		button:SetAttribute("locked", true)
		-- グレー系（Cancel系）に寄せる
		local C = Theme.COLORS
		button.BackgroundColor3 = (C and (C.CancelBtnBg or C.PanelStroke)) or Color3.fromRGB(200,200,200)
		button.TextColor3       = (C and (C.CancelBtnText or C.TextDefault)) or Color3.fromRGB(40,40,40)
		button.Text = tostring(baseText) .. "  🔒"
	else
		button.AutoButtonColor = true
		button:SetAttribute("locked", false)
		-- 元色に戻す
		local bg = button:GetAttribute("OrigBG3")
		local tx = button:GetAttribute("OrigTX3")
		if typeof(bg) == "Color3" then button.BackgroundColor3 = bg end
		if typeof(tx) == "Color3" then button.TextColor3       = tx end
		button.Text = tostring(baseText)
	end
end

--==================================================
-- Factory
--==================================================
function M.create(parent: Instance): ResultAPI
	-------------------------------- オーバーレイ
	local overlay = Instance.new("TextButton")
	overlay.Name = "ResultBackdrop"
	overlay.Parent = parent
	overlay.Size = UDim2.fromScale(1,1)
	overlay.AutoButtonColor = false
	overlay.Text = ""
	overlay.Visible = false
	overlay.ZIndex = 99

	do
		local C = Theme.COLORS
		overlay.BackgroundColor3 = (C and C.OverlayBg) or Color3.fromRGB(0,0,0)
		overlay.BackgroundTransparency = (Theme.overlayBgT ~= nil) and Theme.overlayBgT or 0.35
	end

	-------------------------------- 本体フレーム
	local modal = Instance.new("Frame")
	modal.Name = "ResultModal"
	modal.Parent = parent
	modal.Visible = false
	modal.Size = UDim2.new(0, 520, 0, 260)
	modal.Position = UDim2.new(0.5, 0, 0.5, 0)
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.ZIndex = 100

	do
		local C = Theme.COLORS
		modal.BackgroundColor3 = (C and C.PanelBg) or Color3.fromRGB(255,255,255)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, Theme.PANEL_RADIUS or 10)
		corner.Parent = modal
		local stroke = Instance.new("UIStroke")
		stroke.Color = (C and C.PanelStroke) or Color3.fromRGB(210,210,210)
		stroke.Thickness = 1
		stroke.Parent = modal
	end

	-------------------------------- タイトル／説明
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Parent = modal
	title.BackgroundTransparency = 1
	title.TextScaled = true
	title.Size = UDim2.new(1,-20,0,48)
	title.Position = UDim2.new(0.5,0,0,16)
	title.AnchorPoint = Vector2.new(0.5,0)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Font = Enum.Font.GothamBold
	title.TextWrapped = true
	title.RichText = true
	title.ZIndex = 101
	title.Text = "結果"
	title.TextColor3 = (Theme.COLORS and Theme.COLORS.TextDefault) or Color3.fromRGB(25,25,25)

	local desc = Instance.new("TextLabel")
	desc.Name = "Desc"
	desc.Parent = modal
	desc.BackgroundTransparency = 1
	desc.TextScaled = true
	desc.Size = UDim2.new(1,-40,0,32)
	desc.Position = UDim2.new(0.5,0,0,70)
	desc.AnchorPoint = Vector2.new(0.5,0)
	desc.TextXAlignment = Enum.TextXAlignment.Center
	desc.TextWrapped = true
	desc.RichText = true
	desc.ZIndex = 101
	desc.Text = ""
	desc.TextColor3 = (Theme.COLORS and Theme.COLORS.TextDefault) or Color3.fromRGB(25,25,25)

	-------------------------------- 3択ボタン行
	local btnRow = Instance.new("Frame")
	btnRow.Name = "BtnRow"
	btnRow.Parent = modal
	btnRow.Size = UDim2.new(1,-40,0,64)
	btnRow.Position = UDim2.new(0.5,0,0,120)
	btnRow.AnchorPoint = Vector2.new(0.5,0)
	btnRow.BackgroundTransparency = 1
	btnRow.ZIndex = 101
	local layout = Instance.new("UIListLayout", btnRow)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 16)

	local function mkBtn(text: string, style: "primary" | "neutral" | "warn" | nil): TextButton
		local C = Theme.COLORS
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0.31, 0, 1, 0)
		b.Text = text
		b.AutoButtonColor = true
		b.TextWrapped = true
		b.RichText = true
		b.ZIndex = 102
		b.Parent = btnRow

		local bg, tx
		if style == "primary" then
			bg = C and C.PrimaryBtnBg or Color3.fromRGB(190,50,50)
			tx = C and C.PrimaryBtnText or Color3.fromRGB(255,245,240)
		elseif style == "warn" then
			bg = C and C.WarnBtnBg or Color3.fromRGB(180,80,40)
			tx = C and C.WarnBtnText or Color3.fromRGB(255,240,230)
		else
			bg = C and C.CancelBtnBg or Color3.fromRGB(120,130,140)
			tx = C and C.CancelBtnText or Color3.fromRGB(240,240,240)
		end
		b.BackgroundColor3 = bg
		b.TextColor3 = tx
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, Theme.PANEL_RADIUS or 10)
		c.Parent = b

		b:SetAttribute("OrigText", text)
		b:SetAttribute("OrigBG3", bg)
		b:SetAttribute("OrigTX3", tx)
		return b
	end

	local btnHome = mkBtn("帰宅する（TOPへ）", "neutral")
	local btnNext = mkBtn("次のステージへ（+25年＆屋台）", "primary")
	local btnSave = mkBtn("セーブして終了", "neutral")

	-------------------------------- ワンボタン（final）
	local finalBtn = Instance.new("TextButton")
	finalBtn.Name = "FinalBtn"
	finalBtn.Parent = modal
	finalBtn.Size = UDim2.new(0, 240, 0, 48)
	finalBtn.Position = UDim2.new(0.5,0,0,120)
	finalBtn.AnchorPoint = Vector2.new(0.5,0)
	finalBtn.AutoButtonColor = true
	finalBtn.TextWrapped = true
	finalBtn.RichText = true
	finalBtn.Visible = false
	finalBtn.ZIndex = 102
	do
		local C = Theme.COLORS
		finalBtn.BackgroundColor3 = (C and C.PrimaryBtnBg) or Color3.fromRGB(190,50,50)
		finalBtn.TextColor3       = (C and C.PrimaryBtnText) or Color3.fromRGB(255,245,240)
		local fcorner = Instance.new("UICorner")
		fcorner.CornerRadius = UDim.new(0, Theme.PANEL_RADIUS or 10)
		fcorner.Parent = finalBtn
	end

	-------------------------------- ハンドラ
	local on: Handlers = { home = nil, next = nil, save = nil, final = nil }

	-- クリック結線（ロック中は無視）
	btnHome.Activated:Connect(function()
		if on.home then on.home() end
	end)
	btnNext.Activated:Connect(function()
		if btnNext:GetAttribute("locked") then return end
		if on.next then on.next() end
	end)
	btnSave.Activated:Connect(function()
		if btnSave:GetAttribute("locked") then return end
		if on.save then on.save() end
	end)
	finalBtn.Activated:Connect(function()
		if on.final then on.final() end
	end)

	-- 背景クリックでは閉じない（意図的に no-op）
	overlay.Activated:Connect(function() end)

	-------------------------------- API
	local api: any = {}

	function api:hide()
		overlay.Visible = false
		modal.Visible = false
	end

	-- 従来の3択表示
	function api:show(data)
		local add = tonumber(data and data.rewardBank) or 2
		local C = Theme.COLORS
		title.TextColor3 = (C and C.TextDefault) or title.TextColor3
		desc.TextColor3  = (C and C.TextDefault) or desc.TextColor3

		title.Text = ("冬 クリア！ +%d両"):format(add)
		if data and data.message and data.message ~= "" then
			desc.Text = data.message
		else
			local clears = tonumber(data and data.clears) or 0
			desc.Text = ("次の行き先を選んでください。（進捗: 通算 %d/3 クリア）"):format(clears)
		end

		-- 表示切替：3択オン／ワンボタンオフ
		btnRow.Visible = true
		finalBtn.Visible = false

		overlay.Visible = true
		modal.Visible = true
	end

	-- 冬（最終）専用：ワンボタン表示
	function api:showFinal(titleText: string?, descText: string?, buttonText: string?, onClick: (() -> ())?)
		title.Text = titleText or "クリアおめでとう！"
		desc.Text  = descText  or "このランは終了です。メニューに戻ります。"
		finalBtn.Text = buttonText or "メニューに戻る"
		on.final = onClick

		-- 表示切替：3択オフ／ワンボタンオン
		btnRow.Visible = false
		finalBtn.Visible = true

		overlay.Visible = true
		modal.Visible = true
	end

	-- 3択のロック設定
	function api:setLocked(nextLocked:boolean, saveLocked:boolean)
		setLockedVisual(btnNext, nextLocked)
		setLockedVisual(btnSave, saveLocked)
	end

	-- 3択/ワンボタンのハンドラ設定
	function api:on(handlers: Handlers)
		on.home  = handlers and handlers.home  or on.home
		on.next  = handlers and handlers.next  or on.next
		on.save  = handlers and handlers.save  or on.save
		on.final = handlers and handlers.final or on.final
	end

	-- ▼ Nav 糖衣（UI側は self._resultModal:bindNav(self.deps.Nav) だけでOK）
	function api:bindNav(nav: NavIF)
		if not nav or type(nav.next) ~= "function" then return end
		on.home  = function() nav:next("home") end
		on.next  = function() nav:next("next") end
		on.save  = function() nav:next("save") end
		on.final = function() nav:next("home") end
	end

	-- 破棄（画面遷移時のリーク防止）
... (truncated)
```

### src/client/ui/components/ShopCells.lua
```lua
-- StarterPlayerScripts/UI/components/ShopCells.lua
-- v0.9.H ShopCells：商品カードのUIリファイン（Theme薄適用 + 軽いホバー）
-- - 角丸/ストローク/色を Theme から適用
-- - 価格バンドをダーク帯（Badge系）に
-- - ホバーでカードのストロークを少し強調
-- - 既存のクリック/説明表示/購入フローは据え置き
-- P0-12: 二重クリック対策
--  - 価格帯を TextLabel 化し、Active=false / Selectable=false（入力は親ボタンへ）
--  - Activated は本体ボタンのみ接続

local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Shared
local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat = require(SharedModules:WaitForChild("ShopFormat"))

-- Theme & I18n
local Config   = RS:WaitForChild("Config")
local Theme    = require(Config:WaitForChild("Theme"))
local ShopI18n = require(script.Parent:WaitForChild("i18n"):WaitForChild("ShopI18n"))

local M = {}

--========================
-- 小ユーティリティ
--========================
local function addCorner(gui: Instance, px: number?)
	local ok = pcall(function()
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, px or Theme.PANEL_RADIUS or 10)
		c.Parent = gui
	end)
	return ok
end

local function addStroke(gui: Instance, color: Color3?, thickness: number?, transparency: number?)
	local ok, stroke = pcall(function()
		local s = Instance.new("UIStroke")
		s.Thickness = thickness or 1
		s.Color = color or Theme.COLORS.PanelStroke
		s.Transparency = transparency or 0
		s.Parent = gui
		return s
	end)
	return ok and stroke or nil
end

local function fmtPrice(n: number?): string
	return ("%d 文"):format(tonumber(n or 0))
end

local function itemTitle(it: any): string
	if it and it.name then return tostring(it.name) end
	return tostring(it and it.id or "???")
end

local function itemDesc(it: any, lang: string): string
	if not it then return "" end
	if lang == "en" then
		return (it.descEN or it.descEn or it.name or it.id or "")
	else
		return (it.descJP or it.descJa or it.name or it.id or "")
	end
end

-- UIに出すのは “名前だけ”
local ZODIAC_NAME: {[string]: string} = {
	kito_ko="子", kito_ushi="丑", kito_tora="寅", kito_u="卯", kito_tatsu="辰", kito_mi="巳",
	kito_uma="午", kito_hitsuji="未", kito_saru="申", kito_tori="酉", kito_inu="戌", kito_i="亥",
}
local function faceName(it: any): string
	if not it then return "???" end
	if it.displayName and tostring(it.displayName) ~= "" then return tostring(it.displayName) end
	if it.short and tostring(it.short) ~= "" then return tostring(it.short) end
	if it.shortName and tostring(it.shortName) ~= "" then return tostring(it.shortName) end
	if it.id and ZODIAC_NAME[it.id] then return ZODIAC_NAME[it.id] end
	return tostring(it.name or it.id or "???")
end

--========================
-- メイン：カード生成
--========================
function M.create(parent: Instance, nodes, it: any, lang: string, mon: number, handlers)
	-- カード本体（和紙パネル風）
	local btn = Instance.new("TextButton")
	btn.Name = it.id or "Item"
	btn.Text = faceName(it)
	btn.TextSize = 28
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Theme.COLORS.TextDefault
	btn.BackgroundColor3 = Theme.COLORS.PanelBg
	btn.AutoButtonColor = true
	btn.ZIndex = 10
	btn.Parent = parent
	addCorner(btn, Theme.PANEL_RADIUS)
	local stroke = addStroke(btn, Theme.COLORS.PanelStroke, 1, 0)

	-- 価格バンド（TextLabel に変更し、入力は親へパス）
	local priceBand = Instance.new("TextLabel")
	priceBand.Name = "Price"
	priceBand.BackgroundColor3 = Theme.COLORS.BadgeBg
	priceBand.Size = UDim2.new(1,0,0,20)
	priceBand.Position = UDim2.new(0,0,1,-20)
	priceBand.Text = fmtPrice(it.price)
	priceBand.TextSize = 14
	priceBand.Font = Enum.Font.Gotham
	priceBand.TextColor3 = Color3.fromRGB(245,245,245)
	priceBand.ZIndex = 11
	priceBand.Active = false       -- ★ 入力を自身で取らない
	priceBand.Selectable = false   -- ★ 選択不可
	priceBand.Parent = btn
	addStroke(priceBand, Theme.COLORS.BadgeStroke, 1, 0.2)

	-- 購入可否の視覚
	local affordable = (tonumber(mon or 0) >= tonumber(it.price or 0))
	if not affordable then
		priceBand.Text = fmtPrice(it.price) .. ShopI18n.t(lang, "insufficient_suffix")
		priceBand.BackgroundTransparency = 0.15
		btn.AutoButtonColor = true -- クリックは許可（従来通りサーバ側で弾く）
	end

	-- ホバー：枠と背景をわずかに強調
	local ti = TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local baseBg = btn.BackgroundColor3

	local function hoverIn()
		if stroke then stroke.Thickness = 2 end
		TweenService:Create(btn, ti, { BackgroundColor3 = baseBg:Lerp(Color3.new(1,1,1), 0.06) }):Play()
	end
	local function hoverOut()
		if stroke then stroke.Thickness = 1 end
		TweenService:Create(btn, ti, { BackgroundColor3 = baseBg }):Play()
	end

	btn.MouseEnter:Connect(hoverIn)
	btn.MouseLeave:Connect(hoverOut)
	-- priceBand は Label なので個別の MouseEnter/Leave 接続は不要（親で拾える）

	-- 説明表示（Infoパネルへ）
	local function showDesc()
		local desc = itemDesc(it, lang)
		local lines = {
			("<b>%s</b>"):format(it.name or itemTitle(it)),
			ShopI18n.t(lang, "label_category", tostring(it.category or "-")),
			ShopI18n.t(lang, "label_price", fmtPrice(it.price)),
			"",
			(desc ~= "" and desc or ShopI18n.t(lang, "no_desc")),
		}
		if nodes and nodes.infoText then
			nodes.infoText.Text = table.concat(lines, "\n")
		end
	end
	btn.MouseEnter:Connect(showDesc)
	-- priceBand からの説明表示も、親の MouseEnter で一貫化

	-- 購入（Activated は本体のみ）
	local function doBuy()
		if not handlers or type(handlers.onBuy) ~= "function" then return end
		handlers.onBuy(it)
	end
	btn.Activated:Connect(doBuy)
	-- ※ 二重送出防止のため priceBand 側の Activated 接続は無し（Labelなので発火もしない）

end

return M
```

### src/client/ui/components/ShopUI.lua
```lua
-- src/client/ui/components/ShopUI.lua
-- v0.9.G TWO-ROWS: 上下2段（上=0.7 / 下=0.3）下段に TalismanArea 追加
-- - 既存ノード名は従来互換（title, rerollBtn, deckBtn, scroll, grid, summary, deckPanel, deckTitle, deckText, infoPanel, infoTitle, infoText, closeBtn）
-- - 追加ノード: taliArea

local RS = game:GetService("ReplicatedStorage")

-- Theme 読み込み（ReplicatedStorage/Config/Theme.lua を想定）
local Config = RS:WaitForChild("Config")
local Theme = require(Config:WaitForChild("Theme"))

local M = {}

-- 小ユーティリティ：角丸とストローク
local function addCorner(gui: Instance, radius: number?)
	local ok, _ = pcall(function()
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, radius or Theme.PANEL_RADIUS or 10)
		c.Parent = gui
	end)
	return ok
end

local function addStroke(gui: Instance, color: Color3?, thickness: number?)
	local ok, _ = pcall(function()
		local s = Instance.new("UIStroke")
		s.Thickness = thickness or 1
		s.Color = color or Theme.COLORS.PanelStroke
		s.Transparency = 0
		s.Parent = gui
	end)
	return ok
end

function M.build()
	-- root
	local g = Instance.new("ScreenGui")
	g.Name = "ShopScreen"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 50
	g.Enabled = false
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- modal（右ペイン風：和紙オフホワイト＋ストローク）
	local modal = Instance.new("Frame")
	modal.Name = "Modal"
	modal.AnchorPoint = Vector2.new(0.5,0.5)
	modal.Position = UDim2.new(0.5,0,0.5,0)
	modal.Size = UDim2.new(0.82,0,0.72,0)
	modal.BackgroundColor3 = Theme.COLORS.RightPaneBg
	modal.BorderSizePixel = 0
	modal.ZIndex = 1
	modal.Parent = g
	addCorner(modal)
	addStroke(modal, Theme.COLORS.RightPaneStroke, 1)

	-- header（薄いパネル色＋ストローク）
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundColor3 = Theme.COLORS.PanelBg
	header.BorderSizePixel = 0
	header.Size = UDim2.new(1,0,0,48)
	header.ZIndex = 2
	header.Parent = modal
	addStroke(header, Theme.COLORS.PanelStroke, 1)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1,-20,1,0)
	title.Position = UDim2.new(0,10,0,0)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "屋台（MVP）"
	title.TextSize = 20
	title.TextColor3 = Theme.COLORS.TextDefault
	title.ZIndex = 3
	title.Parent = header

	local deckBtn = Instance.new("TextButton")
	deckBtn.Name = "DeckBtn"
	deckBtn.Size = UDim2.new(0,140,0,32)
	deckBtn.Position = UDim2.new(1,-300,0.5,-16)
	deckBtn.Text = "デッキを見る"
	deckBtn.ZIndex = 3
	deckBtn.Parent = header
	addCorner(deckBtn, 8)
	addStroke(deckBtn, Theme.COLORS.PanelStroke, 1)

	local rerollBtn = Instance.new("TextButton")
	rerollBtn.Name = "RerollBtn"
	rerollBtn.Size = UDim2.new(0,140,0,32)
	rerollBtn.Position = UDim2.new(1,-150,0.5,-16)
	rerollBtn.Text = "リロール"
	rerollBtn.ZIndex = 3
	rerollBtn.Parent = header
	-- Warn button styling
	rerollBtn.BackgroundColor3 = Theme.COLORS.WarnBtnBg
	rerollBtn.TextColor3 = Theme.COLORS.WarnBtnText
	addCorner(rerollBtn, 8)

	-- body（上下2段）
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1,-20,1,-48-64)
	body.Position = UDim2.new(0,10,0,48)
	body.ZIndex = 1
	body.Parent = modal

	local vlist = Instance.new("UIListLayout")
	vlist.FillDirection = Enum.FillDirection.Vertical
	vlist.SortOrder = Enum.SortOrder.LayoutOrder
	vlist.Padding = UDim.new(0,8)
	vlist.Parent = body

	-- 上段（コンテンツ 70%）
	local top = Instance.new("Frame")
	top.Name = "Top"
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(1,0,0.7,0)
	top.LayoutOrder = 1
	top.ZIndex = 1
	top.Parent = body

	local left = Instance.new("Frame")
	left.Name = "Left"
	left.BackgroundTransparency = 1
	left.Size = UDim2.new(0.62,0,1,0)
	left.ZIndex = 1
	left.Parent = top

	local right = Instance.new("Frame")
	right.Name = "Right"
	right.BackgroundTransparency = 1
	right.Size = UDim2.new(0.38,0,1,0)
	right.Position = UDim2.new(0.62,0,0,0)
	right.ZIndex = 1
	right.Parent = top

	-- 左スクロール
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Size = UDim2.new(1,0,1,0)
	scroll.CanvasSize = UDim2.new(0,0,0,0)
	scroll.ScrollBarThickness = 8
	scroll.BackgroundTransparency = 1
	scroll.ZIndex = 2
	scroll.Active = true
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = left

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(96, 144)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroll

	-- 右：デッキパネル
	local deckPanel = Instance.new("Frame")
	deckPanel.Name = "DeckPanel"
	deckPanel.BackgroundColor3 = Theme.COLORS.PanelBg
	deckPanel.BorderSizePixel = 0
	deckPanel.Size = UDim2.new(1,0,0.52,0)
	deckPanel.Position = UDim2.new(0,0,0,0)
	deckPanel.Visible = false
	deckPanel.ZIndex = 2
	deckPanel.Parent = right
	addCorner(deckPanel)
	addStroke(deckPanel, Theme.COLORS.PanelStroke, 1)

	local deckTitle = Instance.new("TextLabel")
	deckTitle.Name = "DeckTitle"
	deckTitle.BackgroundTransparency = 1
	deckTitle.Size = UDim2.new(1,-10,0,24)
	deckTitle.Position = UDim2.new(0,6,0,4)
	deckTitle.TextXAlignment = Enum.TextXAlignment.Left
	deckTitle.Text = "現在のデッキ"
	deckTitle.TextSize = 18
	deckTitle.TextColor3 = Theme.COLORS.TextDefault
	deckTitle.ZIndex = 3
	deckTitle.Parent = deckPanel

	local deckText = Instance.new("TextLabel")
	deckText.Name = "DeckText"
	deckText.BackgroundTransparency = 1
	deckText.Size = UDim2.new(1,-12,1,-30)
	deckText.Position = UDim2.new(0,6,0,28)
	deckText.TextXAlignment = Enum.TextXAlignment.Left
	deckText.TextYAlignment = Enum.TextYAlignment.Top
	deckText.TextWrapped = true
	deckText.RichText = false
	deckText.Text = ""
	deckText.TextColor3 = Theme.COLORS.TextDefault
	deckText.ZIndex = 3
	deckText.Parent = deckPanel

	-- 右：カード情報
	local infoPanel = Instance.new("Frame")
	infoPanel.Name = "InfoPanel"
	infoPanel.BackgroundColor3 = Theme.COLORS.PanelBg
	infoPanel.BorderSizePixel = 0
	infoPanel.Size = UDim2.new(1,0,0.52,0)
	infoPanel.Position = UDim2.new(0,0,0,0)
	infoPanel.Visible = true
	infoPanel.ZIndex = 2
	infoPanel.Parent = right
	addCorner(infoPanel)
	addStroke(infoPanel, Theme.COLORS.PanelStroke, 1)

	local infoTitle = Instance.new("TextLabel")
	infoTitle.Name = "InfoTitle"
	infoTitle.BackgroundTransparency = 1
	infoTitle.Size = UDim2.new(1,-10,0,24)
	infoTitle.Position = UDim2.new(0,6,0,4)
	infoTitle.TextXAlignment = Enum.TextXAlignment.Left
	infoTitle.Text = "アイテム情報"
	infoTitle.TextSize = 18
	infoTitle.TextColor3 = Theme.COLORS.TextDefault
	infoTitle.ZIndex = 3
	infoTitle.Parent = infoPanel

	local infoText = Instance.new("TextLabel")
	infoText.Name = "InfoText"
	infoText.BackgroundTransparency = 1
	infoText.Size = UDim2.new(1,-12,1,-30)
	infoText.Position = UDim2.new(0,6,0,28)
	infoText.TextXAlignment = Enum.TextXAlignment.Left
	infoText.TextYAlignment = Enum.TextYAlignment.Top
	infoText.TextWrapped = true
	infoText.RichText = true   -- <b>…</b> 太字対応
	infoText.Text = "（アイテムにマウスを乗せるか、クリックしてください）"
	infoText.TextColor3 = Theme.COLORS.HelpText
	infoText.ZIndex = 3
	infoText.Parent = infoPanel

	-- 右：サマリ（下段固定）
	local summary = Instance.new("TextLabel")
	summary.Name = "Summary"
	summary.BackgroundTransparency = 1
	summary.Size = UDim2.new(1,0,0.48,0)
	summary.Position = UDim2.new(0,0,0.52,0)
	summary.TextXAlignment = Enum.TextXAlignment.Left
	summary.TextYAlignment = Enum.TextYAlignment.Top
	summary.TextWrapped = true
	summary.RichText = false
	summary.Text = ""
	summary.TextColor3 = Theme.COLORS.TextDefault
	summary.ZIndex = 1
	summary.Parent = right

	-- 下段（護符 30%）
	local bottom = Instance.new("Frame")
	bottom.Name = "Bottom"
	bottom.BackgroundTransparency = 1
	bottom.Size = UDim2.new(1,0,0.3,0)
	bottom.LayoutOrder = 2
	bottom.ZIndex = 1
	bottom.Parent = body

	local taliArea = Instance.new("Frame")
	taliArea.Name = "TalismanArea"
	taliArea.BackgroundTransparency = 1
	taliArea.Size = UDim2.fromScale(1,1)
	taliArea.Parent = bottom

	-- footer
	local footer = Instance.new("Frame")
	footer.Name = "Footer"
	footer.BackgroundTransparency = 1
	footer.Size = UDim2.new(1,0,0,64) -- レイアウトは据え置き
	footer.Position = UDim2.new(0,0,1,-64)
	footer.ZIndex = 1
	footer.Parent = modal

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0,260,0,44)
	closeBtn.Position = UDim2.new(0.5,-130,0.5,-22)
	closeBtn.Text = "屋台を閉じて次の季節へ"
	closeBtn.ZIndex = 2
	closeBtn.Parent = footer
	-- Primary button styling
	closeBtn.BackgroundColor3 = Theme.COLORS.PrimaryBtnBg
	closeBtn.TextColor3 = Theme.COLORS.PrimaryBtnText
	addCorner(closeBtn, 8)

	-- nodes 返却（従来互換＋taliArea）
	local nodes = {
		title = title, rerollBtn = rerollBtn, deckBtn = deckBtn,
		scroll = scroll, grid = grid,
		summary = summary,
		deckPanel = deckPanel, deckTitle = deckTitle, deckText = deckText,
		infoPanel = infoPanel, infoTitle = infoTitle, infoText = infoText,
		closeBtn = closeBtn,
		taliArea = taliArea,
	}

	return g, nodes
... (truncated)
```

### src/client/ui/components/TalismanBoard.lua
```lua
-- src/client/ui/components/TalismanBoard.lua
-- v1.1 RowResponsive: 横一列・比率可変・正方形スロット
--  - props: new(parentGui, { title?, widthScale?, padScale? })
--  - API : setLang(lang), setData(talisman), getInstance(), destroy()

local RS = game:GetService("ReplicatedStorage")
local Config = RS:FindFirstChild("Config") or RS

local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

local M = {}
M.__index = M

--========================================
-- helpers
--========================================
local function colorOr(defaultC3, path1, path2, fallback)
	local ok, c = pcall(function()
		return Theme.COLORS and Theme.COLORS[path1] and Theme.COLORS[path1][path2]
	end)
	if ok and typeof(c) == "Color3" then return c end
	if typeof(fallback) == "Color3" then return fallback end
	return defaultC3
end

local function makeSlot(parent, index)
	local f = Instance.new("Frame")
	f.Name = ("Slot%d"):format(index)
	-- サイズは Grid の UIGridLayout＋AspectRatio が決めるため初期値はダミー
	f.Size = UDim2.fromScale(0, 1)
	f.BackgroundColor3 = colorOr(Color3.fromRGB(30,30,30), "surface", "base", Color3.fromRGB(30,30,30))
	f.BorderSizePixel = 1
	f.Parent = parent

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = f

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(80,80,80)
	stroke.Enabled = true
	stroke.Parent = f

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.TextColor3 = Color3.fromRGB(220,220,220)
	label.Text = ""
	label.Parent = f

	return f, label, stroke
end

local function defaultData()
	return { maxSlots = 6, unlocked = 2, slots = { nil, nil, nil, nil, nil, nil } }
end

--========================================
-- class
--========================================
-- opts:
--   title?: string
--   widthScale?: number  -- 親幅に対する割合（0〜1、既定=0.6）
--   padScale?: number    -- セル間の横パディング割合（既定=0.01 = 親幅の1%）
function M.new(parentGui: Instance, opts: { title: string?, widthScale: number?, padScale: number? }?)
	local self = setmetatable({}, M)

	opts = opts or {}
	local widthScale = tonumber(opts.widthScale or 0.6) or 0.6
	local padScale   = math.clamp(tonumber(opts.padScale or 0.01) or 0.01, 0, 0.05) -- 過大な隙間を抑制
	-- 6スロ・5箇所の隙間 → 各セルの横幅スケール
	local cellScale  = (1 - 5 * padScale) / 6
	-- 正方形化のため、Grid のアスペクト比 = 1 / cellScale （幅 / 高さ）
	local gridAspect = 1 / cellScale

	local root = Instance.new("Frame")
	root.Name = "TalismanBoard"
	root.BackgroundTransparency = 1
	-- 幅は比率、縦は自動（タイトル高さ + グリッド高さ）
	root.Size = UDim2.new(widthScale, 0, 0, 0)
	root.AutomaticSize = Enum.AutomaticSize.Y
	root.Parent = parentGui
	self.root = root

	-- 縦積み（タイトル→グリッド）
	local vlayout = Instance.new("UIListLayout")
	vlayout.FillDirection = Enum.FillDirection.Vertical
	vlayout.Padding = UDim.new(0, 6)
	vlayout.SortOrder = Enum.SortOrder.LayoutOrder
	vlayout.Parent = root

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 24)
	title.BackgroundTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.Text = (opts and opts.title) or "Talisman"
	title.TextColor3 = Color3.fromRGB(235,235,235)
	title.LayoutOrder = 1
	title.Parent = root

	local gridHolder = Instance.new("Frame")
	gridHolder.Name = "Grid"
	gridHolder.BackgroundTransparency = 1
	-- 横幅100%、高さはアスペクト比で決まる（下でConstraintを付与）
	gridHolder.Size = UDim2.new(1, 0, 0, 0)
	gridHolder.AutomaticSize = Enum.AutomaticSize.Y
	gridHolder.LayoutOrder = 2
	gridHolder.Parent = root

	-- 正方形を保つための「幅：高さ」制約（高さ = 幅 / gridAspect）
	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = gridAspect
	ar.DominantAxis = Enum.DominantAxis.Width
	ar.Parent = gridHolder

	-- 横一列のグリッド
	local layout = Instance.new("UIGridLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.FillDirectionMaxCells = 6
	layout.StartCorner = Enum.StartCorner.TopLeft
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	-- 横は cellScale、縦は100%（Gridの高さ）→ 正方形になる
	layout.CellSize = UDim2.new(cellScale, 0, 1, 0)
	layout.CellPadding = UDim2.new(padScale, 0, 0, 0)
	layout.Parent = gridHolder

	self.slots   = {}
	self.labels  = {}
	self.strokes = {}

	for i = 1, 6 do
		local f, lbl, stroke = makeSlot(gridHolder, i)
		self.slots[i]   = f
		self.labels[i]  = lbl
		self.strokes[i] = stroke
	end

	self._lang = (typeof(Locale.get) == "function" and Locale.get()) or "ja"
	self:setLang(self._lang)

	self._data = defaultData()
	self:setData(nil)

	return self
end

--========================================
-- public
--========================================
function M:setLang(lang: string?)
	self._lang = (lang == "en") and "en" or "ja"
	if self.root and self.root:FindFirstChild("Title") then
		self.root.Title.Text = (self._lang == "ja") and "護符ボード" or "Talisman Board"
	end
end

-- talisman: { maxSlots=6, unlocked=2, slots={...} }
function M:setData(talisman: any)
	self._data = talisman or defaultData()

	for i = 1, 6 do
		local slot   = self.slots[i]
		local lbl    = self.labels[i]
		local stroke = self.strokes[i]

		local withinUnlock = i <= (tonumber(self._data.unlocked or 0) or 0)
		local id = self._data.slots and self._data.slots[i] or nil

		if not withinUnlock then
			-- 未開放
			slot.BackgroundColor3 = Color3.fromRGB(35,35,35)
			lbl.Text = "🔒"
			stroke.Color = Color3.fromRGB(80,80,80)
			stroke.Thickness = 1
		elseif id == nil then
			-- 空
			slot.BackgroundColor3 = Color3.fromRGB(50,50,50)
			lbl.Text = (self._lang == "ja") and "空" or "Empty"
			stroke.Color = Color3.fromRGB(80,80,80)
			stroke.Thickness = 1
		else
			-- 埋まっている
			slot.BackgroundColor3 = Color3.fromRGB(70,70,90)
			lbl.Text = tostring(id)
			stroke.Color = Color3.fromRGB(120,120,160)
			stroke.Thickness = 1
		end
	end
end

function M:getInstance()
	return self.root
end

function M:destroy()
	if self.root then self.root:Destroy() end
end

return M
```

### src/client/ui/components/TutorialBanner.lua
```lua
-- StarterPlayerScripts/UI/components/TutorialBanner.lua
local M = {}

function M.mount(parent: Instance, text: string)
	local t = Instance.new("TextLabel")
	t.Name = "TutorialBanner"
	t.Parent = parent
	t.Size = UDim2.new(1,0,0,28)
	t.Position = UDim2.new(0,0,0,0)
	t.BackgroundTransparency = 0.3
	t.BackgroundColor3 = Color3.fromRGB(20,20,20)
	t.Text = text
	t.Font = Enum.Font.GothamMedium
	t.TextSize = 18
	t.TextColor3 = Color3.fromRGB(230,230,230)
	t.ZIndex = 20
	return t
end

return M
```

### src/client/ui/components/UiKit.lua
```lua
-- StarterPlayerScripts/UI/components/UiKit.lua
local UiKit = {}

function UiKit.notify(title: string, text: string, duration: number?)
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = title, Text = text, Duration = duration or 2
		})
	end)
end

function UiKit.label(parent: Instance, name: string, text: string, size: UDim2, pos: UDim2, anchor: Vector2?)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Parent = parent
	l.BackgroundTransparency = 1
	l.Text = text or ""
	l.TextScaled = true
	l.Size = size or UDim2.new(0,100,0,24)
	l.Position = pos or UDim2.new(0,0,0,0)
	if anchor then l.AnchorPoint = anchor end
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	return l
end

function UiKit.button(parent: Instance, txt: string, size: UDim2, pos: UDim2)
	local b = Instance.new("TextButton")
	b.Parent = parent
	b.Text = txt
	b.TextScaled = true
	b.Size = size or UDim2.fromOffset(120,40)
	if pos then b.Position = pos end
	b.AutoButtonColor = true
	b.BackgroundColor3 = Color3.fromRGB(255,255,255)
	b.BorderSizePixel = 1
	return b
end

local UiKit = {}

function UiKit.makeAspectContainer(parent, aspect) -- aspect 例: 16/9
	local frame = Instance.new("Frame")
	frame.Name = "PlayArea"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = parent

	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = aspect
	ar.DominantAxis = Enum.DominantAxis.Width -- 横幅を基準に高さを決める
	ar.Parent = frame

	local uis = Instance.new("UISizeConstraint")
	uis.MinSize = Vector2.new(960, 540) -- 小さすぎ防止（任意）
	-- uis.MaxSize = Vector2.new(3840, 2160) -- 必要なら上限も
	uis.Parent = frame

	return frame
end

return UiKit
```

### src/client/ui/components/YakuPanel.lua
```lua
-- src/client/ui/components/YakuPanel.lua
-- v0.9.7b 役倍率ビュー（前面ポップアップ／開閉API）
-- 変更点:
--  ・Client側で RunDeckUtil を使って祭事Lvを“初期化”しないよう修正
--  ・StatePushの payload に入ってきた matsuri を優先し、未同梱時は既存値を保持
--  ・四光の表示説明を現仕様へ更新（雨四区別なし／任意の光4枚で四光、基礎8文）

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local Scoring       = require(RS:WaitForChild("SharedModules"):WaitForChild("Scoring"))
-- ★不要化：RunDeckUtil 経由での読み出しは初期化を誘発するため使用しない
-- local RunDeckUtil   = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))
local CardImageMap  = require(RS:WaitForChild("SharedModules"):WaitForChild("CardImageMap"))

local Config = RS:FindFirstChild("Config")
local Theme  = Config and Config:FindFirstChild("Theme") and require(Config.Theme)

local YakuPanel = {}
YakuPanel.__index = YakuPanel

--==============================
-- レイアウト定数
--==============================
-- 左のアイコン域を右寄せにして、その右に「×N」→ 役名+基本表記 → Lv → 文×点
local ICON_AREA_W = 120     -- 96→120 に拡張（横幅拡張に合わせ余裕を確保）
local REQTEXT_W   = 48      -- 「×N」テキストの幅（42→48）
local NAME_X      = ICON_AREA_W + 8 + REQTEXT_W + 14 -- 役名の開始X

--==============================
-- 表示順（UI専用の「四光」を含む）
--==============================
local YAKU_CATALOG = {
	{ id="yaku_goko",        nameJP="五光",           nameEN="Five Bright",        iconCodes={"0101","0301","0801","1101","1201"}, reqText="" },
	{ id="yaku_yonko",       nameJP="四光",           nameEN="Four Bright",        iconCodes={"0101"},   reqText="×4" }, -- UIのみ（祭事なし）
	{ id="yaku_sanko",       nameJP="三光",           nameEN="Three Bright",       iconCodes={"0101"},   reqText="×3" },
	{ id="yaku_hanami",      nameJP="花見で一杯",     nameEN="Hanami with Sake",   iconCodes={"0301","0901"}, reqText="" },
	{ id="yaku_tsukimi",     nameJP="月見で一杯",     nameEN="Tsukimi with Sake",  iconCodes={"0801","0901"}, reqText="" },
	{ id="yaku_inoshikacho", nameJP="猪鹿蝶",         nameEN="Inoshikachō",        iconCodes={"0701","1001","0601"}, reqText="" },
	{ id="yaku_tane",        nameJP="タネ",           nameEN="Seeds",              iconCodes={"0201"},   reqText="×5" },
	{ id="yaku_tanzaku",     nameJP="短冊",           nameEN="Tanzaku",            iconCodes={"0202"},   reqText="×5" },
	{ id="yaku_kasu",        nameJP="カス",           nameEN="Kasu",               iconCodes={"0103"},   reqText="×10" },
}

--==============================
-- 基本点（基礎の「文」）と閾値/超過の説明
-- ※ Scoring.lua の ROLE_MON に合わせる
--==============================
local BASE_INFO = {
	-- 光系
	yaku_goko        = { base = 10 },  -- 五光
	-- ★更新：雨四の区別をしない現仕様。任意4枚で四光＝基礎8文（注記なし）
	yaku_yonko       = { base =  8 },  -- 四光
	yaku_sanko       = { base =  5 },  -- 三光

	-- 役もの
	yaku_hanami      = { base =  5 },
	yaku_tsukimi     = { base =  5 },
	yaku_inoshikacho = { base =  5 },

	-- 枚数系（閾値超過で +1文/枚）
	yaku_tane        = { base =  1, threshold = 5  },
	yaku_tanzaku     = { base =  1, threshold = 5  },
	yaku_kasu        = { base =  1, threshold = 10 },
}

--==============================
-- ユーティリティ
--==============================
local function getLang(state)
	local lang = "ja"
	if typeof(state)=="table" and state.lang then lang = state.lang end
	return (lang=="en") and "en" or "ja"
end

-- ★修正：payload（StatePush）に同梱された値のみを読む。無いときは nil を返す。
local function getMatsuriLevelsFromPayload(state)
	if typeof(state) ~= "table" then return nil end
	-- 推奨：フラット（StatePush: payload.matsuri）
	if typeof(state.matsuri) == "table" then
		return state.matsuri
	end
	-- 保険：ネスト（state.run.meta.matsuriLevels）が来ている場合
	local run  = state.run
	local meta = run and run.meta
	local lv   = meta and meta.matsuriLevels
	if typeof(lv) == "table" then
		return lv
	end
	-- 未同梱（nilで返す）→ 呼び出し側で「上書きしない」
	return nil
end

local function t(lang, jp, en) return (lang=="en") and (en or jp) or jp end

-- 役名のあとに付ける「（基本点＋超過ルール）」テキスト
local function buildBaseSuffix(lang, yakuId)
	local info = BASE_INFO[yakuId]
	if not info then return "" end

	-- 基本点
	local basePart = (lang=="en") and ("base "..tostring(info.base).." mon") or ("基本"..tostring(info.base).."文")

	-- 超過ルール（ある場合）
	local extraPart = ""
	if info.threshold then
		if lang=="en" then
			extraPart = string.format("; +1 per card over %d", info.threshold)
		else
			extraPart = string.format("／%d枚超過ごとに+1文", info.threshold)
		end
	end

	-- 備考（※現仕様で四光は注記なし）
	local note = ""
	if info.noteJP or info.noteEN then
		note = (lang=="en") and (" "..(info.noteEN or "")) or (" "..(info.noteJP or ""))
	end

	if lang=="en" then
		return string.format(" (%s%s)%s", basePart, extraPart, note)
	else
		return string.format("（%s%s）%s", basePart, extraPart, note)
	end
end

--==============================
-- 行生成
--==============================
local function createRow(parent, yaku)
	local row = Instance.new("Frame")
	row.Name = "Row_" .. yaku.id
	row.Size = UDim2.new(1, -10, 0, 58)
	row.BackgroundColor3 = Color3.fromRGB(30,30,30)
	do
		local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,10); rc.Parent = row
		local rs = Instance.new("UIStroke"); rs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; rs.Thickness = 1; rs.Color = Color3.fromRGB(255,255,255); rs.Transparency = 0.85; rs.Parent = row
	end

	-- アイコン列（右寄せ）
	local icons = Instance.new("Frame")
	icons.Name = "Icons"
	icons.Size = UDim2.new(0, ICON_AREA_W, 1, 0)
	icons.BackgroundTransparency = 1
	icons.Parent = row

	local iconsLayout = Instance.new("UIListLayout")
	iconsLayout.FillDirection = Enum.FillDirection.Horizontal
	iconsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	iconsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	iconsLayout.Padding = UDim.new(0, 4)
	iconsLayout.Parent = icons

	-- 「×N」テキスト（任意）
	local reqTextLabel: TextLabel? = nil
	if yaku.reqText and yaku.reqText ~= "" then
		reqTextLabel = Instance.new("TextLabel")
		reqTextLabel.Name = "ReqText"
		reqTextLabel.AnchorPoint = Vector2.new(0, 0.5)
		reqTextLabel.Position = UDim2.new(0, ICON_AREA_W + 8, 0.5, 0)
		reqTextLabel.Size = UDim2.fromOffset(REQTEXT_W, 22)
		reqTextLabel.BackgroundTransparency = 1
		reqTextLabel.Text = tostring(yaku.reqText)
		reqTextLabel.Font = Enum.Font.Gotham
		reqTextLabel.TextSize = 14
		reqTextLabel.TextXAlignment = Enum.TextXAlignment.Left
		reqTextLabel.TextColor3 = Color3.fromRGB(230,230,230)
		reqTextLabel.ZIndex = 102
		reqTextLabel.Parent = row
	end

	-- 役名（あとに「（基本点/超過）」を付ける）
	local lblName = Instance.new("TextLabel")
	lblName.Name = "NameLabel"
	lblName.Position = UDim2.fromOffset(NAME_X, 0)
	lblName.Size = UDim2.new(0.54, 0, 1, 0) -- 横幅拡張に合わせて広げる
	lblName.TextXAlignment = Enum.TextXAlignment.Left
	lblName.TextYAlignment = Enum.TextYAlignment.Center
	lblName.Font = Enum.Font.Gotham
	lblName.TextSize = 16
	lblName.TextColor3 = Color3.fromRGB(255,255,255)
	lblName.BackgroundTransparency = 1
	lblName.Parent = row

	-- Lv 合計
	local lblLv = Instance.new("TextLabel")
	lblLv.Name = "LevelLabel"
	lblLv.Position = UDim2.new(0.70, 0, 0, 0) -- 右に寄せる（全体横幅拡張に対応）
	lblLv.Size = UDim2.new(0.10, 0, 1, 0)
	lblLv.TextXAlignment = Enum.TextXAlignment.Center
	lblLv.Font = Enum.Font.Gotham
	lblLv.TextSize = 16
	lblLv.TextColor3 = Color3.fromRGB(230,230,230)
	lblLv.BackgroundTransparency = 1
	lblLv.Parent = row

	-- 文×点（祭事で加わる加点の合計）
	local lblStat = Instance.new("TextLabel")
	lblStat.Name = "StatLabel"
	lblStat.Position = UDim2.new(0.80, 0, 0, 0)
	lblStat.Size = UDim2.new(0.20, 0, 1, 0)
	lblStat.TextXAlignment = Enum.TextXAlignment.Right
	lblStat.Font = Enum.Font.Gotham
	lblStat.TextSize = 16
	lblStat.TextColor3 = Color3.fromRGB(230,230,230)
	lblStat.BackgroundTransparency = 1
	lblStat.Parent = row

	-- アイコン描画
	local added = 0
	for _, code in ipairs(yaku.iconCodes or {}) do
		local imgId = CardImageMap.get(code)
		if imgId then
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.Size = UDim2.fromOffset(18,26)
			img.Image = imgId
			img.Parent = icons
			added += 1
		end
	end
	if added == 0 and Theme and Theme.IMAGES and Theme.IMAGES[yaku.id] then
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromOffset(18,26)
		img.Image = Theme.IMAGES[yaku.id]
		img.Parent = icons
		added = 1
	end
	if added == 0 then
		local txt = Instance.new("TextLabel")
		txt.BackgroundTransparency = 1
		txt.Size = UDim2.fromOffset(24,24)
		txt.Text = "—"
		txt.Font = Enum.Font.Gotham
		txt.TextSize = 12
		txt.TextColor3 = Color3.fromRGB(150,150,150)
		txt.Parent = icons
	end

	row.Parent = parent
	return row, {
		nameLabel = lblName,
		lvLabel   = lblLv,
		statLabel = lblStat,
		reqText   = reqTextLabel,
	}
end

--==============================
-- mount
--==============================
function YakuPanel.mount(parentGui)
	local self = setmetatable({}, YakuPanel)

	local parent = parentGui
	if not parent or not parent:IsA("Instance") then
		parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end

	-- 前面に出す（RunScreen.DisplayOrder=10 より上）
	local rootGui = Instance.new("ScreenGui")
	rootGui.Name = "YakuPanel"
	rootGui.ResetOnSpawn = false
	rootGui.IgnoreGuiInset = true
	rootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	rootGui.DisplayOrder = 100
	rootGui.Parent = parent
	self._root = rootGui

	-- オーバーレイ
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Visible = false
	overlay.BackgroundColor3 = Color3.new(0,0,0)
	overlay.BackgroundTransparency = 0.38
	overlay.Size = UDim2.fromScale(1,1)
	overlay.ZIndex = 100
	overlay.Parent = rootGui
	self._overlay = overlay

	-- カード：横幅を 540→756（約1.4倍）に拡張
	local card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5,0.5)
	card.Position = UDim2.fromScale(0.5,0.5)
	card.Size = UDim2.fromOffset(756, 600) -- height 少しゆとり
	card.Parent = overlay
	card.BackgroundColor3 = Color3.fromRGB(24,24,24)
	card.ZIndex = 101
	do
		local uic = Instance.new("UICorner"); uic.CornerRadius = UDim.new(0,16); uic.Parent = card
		local stroke = Instance.new("UIStroke"); stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke.Color = Color3.fromRGB(255,255,255); stroke.Transparency = 0.7; stroke.Thickness = 1; stroke.Parent = card
	end

	-- タイトルバー
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1,0,0,44)
	titleBar.Parent = card
... (truncated)
```

### src/client/ui/lib/FormatUtil.lua
```lua
-- StarterPlayerScripts/UI/lib/FormatUtil.lua
-- スコア・状態などの整形ユーティリティ（言語対応）

local RS = game:GetService("ReplicatedStorage")
local Locale = require(RS:WaitForChild("Config"):WaitForChild("Locale"))

local M = {}

-- 役名のローカライズ辞書
local ROLE_NAMES = {
  en = {
    five_bright      = "Five Brights",
    four_bright      = "Four Brights",
    rain_four_bright = "Rain Four Brights",
    three_bright     = "Three Brights",
    inoshikacho      = "Boar–Deer–Butterfly",
    red_ribbon       = "Red Ribbons",
    blue_ribbon      = "Blue Ribbons",
    seeds            = "Seeds",
    ribbons          = "Ribbons",
    chaffs           = "Chaff",
    hanami           = "Hanami Sake",
    tsukimi          = "Tsukimi Sake",
  },
  jp = {
    five_bright      = "五光",
    four_bright      = "四光",
    rain_four_bright = "雨四光",
    three_bright     = "三光",
    inoshikacho      = "猪鹿蝶",
    red_ribbon       = "赤短",
    blue_ribbon      = "青短",
    seeds            = "たね",
    ribbons          = "たん",
    chaffs           = "かす",
    hanami           = "花見で一杯",
    tsukimi          = "月見で一杯",
  }
}

-- 役集合を「a / b / c」形式の文字列に
-- roles: { [role_key]=true or number } / array でもOK（キーを拾う）
function M.rolesToLines(roles, langOpt)
  local lang = langOpt or (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or "en"
  local names = ROLE_NAMES[lang] or ROLE_NAMES.en

  if typeof(roles) ~= "table" then
    return Locale.t(lang, "ROLES_NONE")
  end

  local hasAny = false
  local list = {}

  -- roles が map でも配列でも対応
  for k,v in pairs(roles) do
    local key = (typeof(k)=="string") and k or (typeof(v)=="string" and v) or nil
    if key then
      local disp = names[key] or key
      table.insert(list, disp)
      hasAny = true
    end
  end

  if not hasAny or #list == 0 then
    return Locale.t(lang, "ROLES_NONE")
  end

  table.sort(list, function(a,b) return tostring(a) < tostring(b) end)
  return table.concat(list, " / ")
end

-- 既存の日本語固定行はそのまま（範囲外）。必要になったらi18n化する。
function M.stateLineText(st)
  local ytxt = (st and st.year and tonumber(st.year) and st.year > 0) and tostring(st.year) or "----"
  local seasonTxt = (st and (st.seasonStr or (st.season and ("季節"..tostring(st.season))))) or "季節--"
  local target = (st and st.target) or 0
  local sum    = (st and st.sum)    or 0
  local hands  = (st and st.hands)  or 0
  local reroll = (st and st.rerolls) or 0
  local mult   = (st and st.mult)   or 1
  local bank   = (st and st.bank)   or 0
  local dleft  = (st and st.deckLeft) or 0
  local hleft  = (st and st.handLeft) or 0

  return ("年:%s  季節:%s  目標:%d  合計:%d  残ハンド:%d  残リロール:%d  倍率:%.1fx  Bank:%d  山:%d  手:%d")
    :format(ytxt, seasonTxt, target, sum, hands, reroll, mult, bank, dleft, hleft)
end

return M
```

### src/client/ui/lib/UiUtil.lua
```lua
-- StarterPlayerScripts/UI/lib/UiUtil.lua
-- ラベル作成・子要素クリア・汎用ボタン作成の小物ユーティリティ
-- v0.9.7-P1-4: Theme に完全寄せ（色／角丸／枠線／余白のフォールバック撤去）
-- 既存APIは互換維持（makeLabel / clear / makeTextBtn）。加えて便利関数を少量追加。

local RS = game:GetService("ReplicatedStorage")

-- 任意 Theme（あれば使う）
local Theme: any = nil
do
	local cfg = RS:FindFirstChild("Config")
	if cfg and cfg:FindFirstChild("Theme") then
		local ok, t = pcall(function() return require(cfg.Theme) end)
		if ok then Theme = t end
	end
end

local C = (Theme and Theme.COLORS) or {}
local S = (Theme and Theme.SIZES)  or {}
local RADIUS = (Theme and Theme.PANEL_RADIUS) or 10

local U = {}

--==================================================
-- 内部ヘルパ
--==================================================
local function _addCornerStroke(frame: Instance, radiusPx: number?, strokeColor: Color3?, thickness: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radiusPx or RADIUS)
	corner.Parent = frame
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1
	s.Color = strokeColor or C.PanelStroke or Color3.fromRGB(210, 210, 210)
	s.Transparency = 0
	s.Parent = frame
	return frame
end

local function _btnPalette(style: string?): (Color3, Color3)
	style = tostring(style or "neutral")
	if style == "primary" then
		return (C.PrimaryBtnBg or Color3.fromRGB(190,50,50)),
		       (C.PrimaryBtnText or Color3.fromRGB(255,245,240))
	elseif style == "warn" then
		return (C.WarnBtnBg or Color3.fromRGB(180,80,40)),
		       (C.WarnBtnText or Color3.fromRGB(255,240,230))
	elseif style == "info" then
		return (C.InfoBtnBg or Color3.fromRGB(120,180,255)),
		       (C.TextDefault or Color3.fromRGB(25,25,25))
	elseif style == "dev" then
		return (C.DevBtnBg or Color3.fromRGB(40,100,60)),
		       (C.DevBtnText or Color3.fromRGB(255,255,255))
	elseif style == "cancel" then
		return (C.CancelBtnBg or Color3.fromRGB(120,130,140)),
		       (C.CancelBtnText or Color3.fromRGB(240,240,240))
	else -- neutral
		return (C.CancelBtnBg or Color3.fromRGB(120,130,140)),
		       (C.CancelBtnText or Color3.fromRGB(240,240,240))
	end
end

--==================================================
-- ラベル生成（RunScreen の makeLabel と同じ引数順）
--==================================================
function U.makeLabel(parent: Instance, name: string, text: string?, size: UDim2?, pos: UDim2?, anchor: Vector2?, color: Color3?)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Parent = parent
	l.BackgroundTransparency = 1
	l.Text = text or ""
	l.TextScaled = true
	l.Size = size or UDim2.new(0,100,0,24)
	l.Position = pos or UDim2.new(0,0,0,0)
	if anchor then l.AnchorPoint = anchor end
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.TextColor3 = color or C.TextDefault or Color3.fromRGB(20,20,20)
	return l
end

--==================================================
-- 子要素を全消し
-- exceptNames: {"KeepThis","AndThat"} のように残したい子の名前配列（任意）
-- ※ UIListLayout / UIPadding などレイアウト系も**全部**消します（二重生成防止）
--==================================================
function U.clear(container: Instance, exceptNames: {string}? )
	local except = {}
	if typeof(exceptNames) == "table" then
		for _,n in ipairs(exceptNames) do except[n] = true end
	end
	for _,child in ipairs(container:GetChildren()) do
		if not except[child.Name] then
			child:Destroy()
		end
	end
end

--==================================================
-- 汎用テキストボタン（角丸＋UIStroke）
-- size/pos はそのまま渡す（RunScreen 側のレイアウトに合わせる）
-- bgColor が未指定なら Theme の "neutral(=cancel系)" を既定採用
--==================================================
function U.makeTextBtn(parent: Instance, text: string, size: UDim2?, pos: UDim2?, bgColor: Color3?)
	local b = Instance.new("TextButton")
	b.Parent = parent
	b.Text = text
	b.TextScaled = true
	b.AutoButtonColor = true
	b.Size = size or UDim2.new(0,120,0,math.max(36, S.CONTROLS_H or 36))
	b.Position = pos or UDim2.new(0,0,0,0)
	b.BackgroundColor3 = bgColor or (C.CancelBtnBg or Color3.fromRGB(120,130,140))
	b.BorderSizePixel = 0
	b.TextColor3 = C.CancelBtnText or Color3.fromRGB(240,240,240)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, RADIUS); c.Parent = b
	local s = Instance.new("UIStroke"); s.Color = C.PanelStroke or Color3.fromRGB(210,210,210); s.Thickness = 1; s.Parent = b
	return b
end

--==================================================
-- 追加：ボタンスタイル適用（"primary"|"warn"|"cancel"|"info"|"dev"|"neutral"）
--==================================================
function U.styleButton(btn: TextButton, style: string?)
	if not (btn and btn:IsA("TextButton")) then return end
	local bg, tx = _btnPalette(style)
	btn.BackgroundColor3 = bg
	btn.TextColor3 = tx
	-- 元色も属性に保存（ResultModal 等のロック切替用）
	btn:SetAttribute("OrigBG3", bg)
	btn:SetAttribute("OrigTX3", tx)
end

--==================================================
-- 追加：パネル作成（角丸＋枠線つき）
-- size: UDim2（Scale/Offsetどちらでも） / layoutOrder 任意
-- titleText を渡すと左上にタイトルラベルを内包
--==================================================
function U.makePanel(parent: Instance, name: string, size: UDim2, layoutOrder: number?, titleText: string?, titleColor: Color3?)
	local f = Instance.new("Frame")
	f.Name = name
	f.Parent = parent
	f.Size = size
	f.LayoutOrder = layoutOrder or 1
	f.BackgroundColor3 = C.PanelBg or Color3.fromRGB(255,255,255)
	_addCornerStroke(f, RADIUS, C.PanelStroke, 1)

	if titleText and titleText ~= "" then
		local title = U.makeLabel(f, name.."Title", titleText, UDim2.new(1, - (S.PAD or 10)*2, 0, 24), UDim2.new(0, (S.PAD or 10), 0, (S.PAD or 10)), nil, titleColor or C.TextDefault)
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = f.ZIndex + 1
	end
	return f
end

--==================================================
-- 追加：共通 Padding（左右PADをThemeから）
--==================================================
function U.addSidePadding(frame: Instance, padPx: number?)
	local p = Instance.new("UIPadding")
	local px = padPx or (S.PAD or 10)
	p.PaddingLeft  = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = frame
	return p
end

return U
```

### src/client/ui/ScreenRouter.lua
```lua
-- StarterPlayerScripts/UI/ScreenRouter.lua
-- シンプルな画面ルーター：同じ画面への show は再実行しない（ちらつき対策）
-- v0.9.4 (P1-3 logger):
--  - current==name の場合、非表示ループを完全スキップ（ちらつきゼロ）
--  - Enabled/Visible を型ガードして安全化（ScreenGui/GuiObject 両対応）
--  - setData → updateOrShow だけ行う
--  - Logger 導入（print/warn を LOG.* に置換）
--  - ログ例: LOG.debug("Router.show updated same screen for %s", name)

local Router = {}

--==================================================
-- 依存・状態
--==================================================
local _map       = nil   -- name -> module (table or function)
local _deps      = nil   -- 共有依存（playerGui や remotes など）
local _instances = {}    -- name -> screen instance
local _current   = nil   -- 現在の画面名

-- Locale（payload.lang 未指定時の補完に使用）
local RS     = game:GetService("ReplicatedStorage")
local Config = RS:WaitForChild("Config")
local Locale = require(Config:WaitForChild("Locale"))

-- Logger
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("ScreenRouter")

--==================================================
-- ヘルパ：可視状態の安全設定（ScreenGui/GuiObject 両対応）
--==================================================
local function setGuiActive(gui: Instance?, active: boolean)
	if not gui or typeof(gui) ~= "Instance" then return end
	if gui:IsA("ScreenGui") then
		gui.Enabled = active
	elseif gui:IsA("GuiObject") then
		gui.Visible = active
	end
end

--==================================================
-- 初期化
--==================================================
function Router.init(screenMap)
	_map = screenMap
	LOG.info("initialized")
end

function Router.setDeps(d)
	_deps = d
	-- 既に生成済みの画面 GUI が未親付けなら補修
	if _deps and _deps.playerGui then
		for _, inst in pairs(_instances) do
			if inst and inst.gui and inst.gui.Parent == nil then
				pcall(function() inst.gui.ResetOnSpawn = false end)
				inst.gui.Parent = _deps.playerGui
			end
		end
	end
	LOG.debug("deps set (playerGui=%s)", tostring(_deps and _deps.playerGui))
end

--==================================================
-- 内部：画面生成
--==================================================
local function instantiate(mod, name)
	-- table で .new(deps)
	if typeof(mod) == "table" and type(mod.new) == "function" then
		return mod.new(_deps)
	end
	-- 関数モジュール function(deps)
	if type(mod) == "function" then
		return mod(_deps)
	end
	-- テーブルをそのままインスタンスとして使う（最低限の互換）
	if typeof(mod) == "table" then
		return mod
	end
	error(("Screen module '%s' is invalid (need table.new or function or instance table)"):format(tostring(name)))
end

local function ensure(name)
	if _instances[name] then return _instances[name] end
	local mod = _map and _map[name]
	if not mod then
		error(("Screen '%s' not registered"):format(tostring(name)))
	end
	local inst = instantiate(mod, name)
	_instances[name] = inst
	-- 画面のルートGUIを PlayerGui へ
	if inst.gui and _deps and _deps.playerGui and not inst.gui.Parent then
		pcall(function() inst.gui.ResetOnSpawn = false end)
		inst.gui.Parent = _deps.playerGui
	end
	return inst
end

--==================================================
-- 内部：payload 正規化（言語の自動注入）
--==================================================
local function normalizePayload(payload)
	payload = payload or {}
	if payload.lang == nil then
		if type(Locale.getGlobal) == "function" then
			payload.lang = Locale.getGlobal()
		else
			payload.lang = "en"
		end
	end
	return payload
end

--==================================================
-- 内部：言語の即時反映（inst.setLang があれば最優先で）
--==================================================
local function applyLangIfPossible(inst, lang)
	if not inst then return end
	if lang and type(inst.setLang) == "function" then
		inst:setLang(lang)
	end
	-- グローバルにも同期しておく（あれば）
	if lang and type(Locale.setGlobal) == "function" then
		Locale.setGlobal(lang)
	end
end

--==================================================
-- 内部：更新または再描画を呼ぶ
--==================================================
local function updateOrShow(inst, payload)
	if type(inst.update) == "function" then
		local ok, err = pcall(function() inst:update(payload) end)
		if not ok then LOG.warn("update failed: %s", tostring(err)) end
	elseif type(inst.show) == "function" then
		local ok, err = pcall(function() inst:show(payload) end)
		if not ok then LOG.warn("show(as update) failed: %s", tostring(err)) end
	end
end

--==================================================
-- 画面表示
--==================================================
function Router.show(arg, payload)
	-- 1) 互換：引数形を正規化
	local name
	if type(arg) == "table" and arg.name then
		name = arg.name
		payload = arg._payload
	else
		name = arg
	end
	if type(name) ~= "string" then
		LOG.warn("show: invalid name: %s", typeof(name))
		return
	end

	-- 2) payload を正規化（lang を必ず持たせる）
	payload = normalizePayload(payload)
	LOG.debug("Router.show -> %s | lang=%s", name, tostring(payload.lang))

	-- 3) インスタンス確保（new/create/そのままテーブルの順で対応）
	local inst
	local ok, err = pcall(function()
		inst = ensure(name)
	end)
	if not ok or type(inst) ~= "table" then
		LOG.warn("show: ensure failed for %s | %s", tostring(name), tostring(err))
		return
	end

	-- 3.5) GUI 親付けの最終確認
	if inst.gui and _deps and _deps.playerGui and inst.gui.Parent == nil then
		pcall(function() inst.gui.ResetOnSpawn = false end)
		inst.gui.Parent = _deps.playerGui
	end

	-- ★ 4) current==name：ちらつき防止モード（可視状態は触らない）
	if _current == name then
		applyLangIfPossible(inst, payload.lang)   -- 言語は即時反映
		if type(inst.setData) == "function" then  -- データは必ず渡す
			inst:setData(payload)
		end
		updateOrShow(inst, payload)               -- 差分更新 or 再描画
		LOG.debug("Router.show updated same screen for %s", name)
		return
	end

	-- 5) 全画面を安全に非表示（nil/型ガード付き）※別画面に切替時のみ
	for _, e in pairs(_instances) do
		if e and e.gui then
			setGuiActive(e.gui, false)
		end
	end

	-- 6) 言語は最優先で即時適用
	applyLangIfPossible(inst, payload.lang)

	-- 7) setData を先に渡しておく（show 前提条件）
	if type(inst.setData) == "function" then
		inst:setData(payload)
	end

	-- 8) 旧画面 hide（メソッドがあれば呼ぶ）
	if _current and _instances[_current] and type(_instances[_current].hide) == "function" then
		local prev = _instances[_current]
		local okHide, errHide = pcall(function() prev:hide() end)
		if not okHide then LOG.warn("hide failed for %s | %s", tostring(_current), tostring(errHide)) end
	end

	_current = name

	-- 9) 画面表示（メソッドがあれば呼ぶ）
	if type(inst.show) == "function" then
		local okShow, errShow = pcall(function() inst:show(payload) end)
		if not okShow then LOG.warn("show method failed for %s | %s", tostring(name), tostring(errShow)) end
	end

	-- 10) 最終的に可視化を担保（型ガード）
	if inst.gui then
		setGuiActive(inst.gui, true)
	end
end

--==================================================
-- 指定画面のメソッド呼び出し（存在すれば）
--==================================================
function Router.call(name, method, ...)
	local sc = _instances[name] or ensure(name)
	local fn = sc and sc[method]
	if type(fn) == "function" then
		return fn(sc, ...)
	end
end

--==================================================
-- 現在アクティブな画面名
--==================================================
function Router.active()
	return _current
end

-- 明示的にインスタンスを取得したい場合（必要なら利用）
function Router.ensure(name)
	return ensure(name)
end

return Router
```

### src/client/ui/screens/HomeScreen.lua
```lua
-- StarterPlayerScripts/UI/screens/HomeScreen.lua
-- START GAME / 神社 / 持ち物 / 設定 / パッチノート（別モジュール化）
-- 言語切替（EN/JA）対応：保存(lang)があればそれを優先、無ければOS基準
-- v0.9.5-P0-6/10:
--  - HomeOpen 到着まで START を無効化（ラベル「同期中…/Syncing…」）
--  - HomeOpen 受信後に hasSave を反映して START を有効化
--  - 言語コードは外部公開を "ja" / "en" に統一（"jp" を使わない）
--  - START文言は言語切替時に「同期中…」へ戻さない（_refreshStartButtonで一元管理）
--  - 右端の安全余白、PatchNotes分離 など従来機能は維持

local Home = {}
Home.__index = Home

--========================
-- Services / Locale
--========================
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local Locale  = require(RS:WaitForChild("Config"):WaitForChild("Locale"))
local PatchNotesModal = require(script.Parent:WaitForChild("PatchNotesModal"))

-- ★ 右端の安全余白（必要に応じて増減）
local RIGHT_SAFE_PAD = 32 -- px 例: 32/40/48 に調整可

local function detectOSLang()
	local lp  = Players.LocalPlayer
	local lid = (lp and lp.LocaleId) and string.lower(lp.LocaleId) or "en-us"
	return (string.sub(lid, 1, 2) == "ja") and "ja" or "en"
end

local function pickLang(forced)
	-- 優先: 明示指定 → Locale.pick() → OS
	if forced == "ja" or forced == "en" then return forced end
	if typeof(Locale.pick) == "function" then
		local ok, v = pcall(Locale.pick)
		if ok and (v == "ja" or v == "en") then return v end
	end
	return detectOSLang()
end

local function makeL(dict) return function(k) return dict[k] or k end end

-- 直接辞書を参照してフォールバック文字列を返すユーティリティ
local function Dget(dict, key, fallback)
	return (dict and dict[key]) or fallback
end

--========================
-- Helpers
--========================
local function setInteractable(btn: TextButton, on: boolean)
	btn.AutoButtonColor        = on
	btn.Active                 = on
	btn.BackgroundTransparency = on and 0 or 0.5
	btn.TextTransparency       = on and 0 or 0.4
end

local function notify(title: string, text: string, duration: number?)
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title    = title,
			Text     = text,
			Duration = duration or 2,
		})
	end)
end

-- ★ HomeOpen前のSTARTラベル
local function syncingLabel(lang: string, dict)
	if lang == "ja" then
		return Dget(dict, "BTN_SYNCING", "同期中…")
	else
		return Dget(dict, "BTN_SYNCING", "Syncing…")
	end
end

--========================
-- Class
--========================
function Home.new(deps)
	local self = setmetatable({}, Home)
	self.deps = deps
	self.hasSave = false -- HomeOpen から受け取って保持（STARTラベル切替に使用）

	-- 言語（初期は保存/明示→OSの順）
	self.lang = pickLang(deps and deps.lang)
	-- Locale.get を優先（ja/en の内部正規化を尊重）
	self.Dict = (typeof(Locale.get)=="function" and Locale.get(self.lang)) or Locale[self.lang] or Locale.en
	self._L   = makeL(self.Dict)
	-- ★ 現在言語をクライアント全体にも共有（Router/Run/Shopでも使う）
	if typeof(Locale.setGlobal) == "function" then
		Locale.setGlobal(self.lang)
	end

	-- ルートGUI
	local g = Instance.new("ScreenGui")
	g.Name             = "HomeScreen"
	g.ResetOnSpawn     = false
	g.IgnoreGuiInset   = true
	g.DisplayOrder     = 100
	g.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
	g.Enabled          = false
	self.gui           = g

	--========================
	-- 背景
	--========================
	local bg = Instance.new("ImageLabel")
	bg.Name                   = "Background"
	bg.Size                   = UDim2.fromScale(1,1)
	bg.Position               = UDim2.fromOffset(0,0)
	bg.BackgroundTransparency = 1
	bg.Image                  = "rbxassetid://132353504528822"
	bg.ScaleType              = Enum.ScaleType.Crop
	bg.ZIndex                 = 0
	bg.Parent                 = g

	local dim = Instance.new("Frame")
	dim.Name                   = "Dimmer"
	dim.Size                   = UDim2.fromScale(1,1)
	dim.BackgroundColor3       = Color3.fromRGB(0,0,0)
	dim.BackgroundTransparency = 0.32
	dim.ZIndex                 = 1
	dim.Parent                 = g

	local grad = Instance.new("UIGradient")
	grad.Rotation   = 90
	grad.Color      = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0,0,0)),
		ColorSequenceKeypoint.new(0.20, Color3.fromRGB(40,40,40)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(70,70,70)),
		ColorSequenceKeypoint.new(0.80, Color3.fromRGB(40,40,40)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0,0,0)),
	})
	grad.Transparency= NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 0.48),
		NumberSequenceKeypoint.new(0.20, 0.40),
		NumberSequenceKeypoint.new(0.50, 0.22),
		NumberSequenceKeypoint.new(0.80, 0.40),
		NumberSequenceKeypoint.new(1.00, 0.48),
	})
	grad.Parent = dim

	--========================
	-- 前景レイヤ
	--========================
	local ui = Instance.new("Frame")
	ui.Name                   = "UIRoot"
	ui.Size                   = UDim2.fromScale(1,1)
	ui.BackgroundTransparency = 1
	ui.ZIndex                 = 2
	ui.Parent                 = g

	-- タイトル
	self.titleJP = Instance.new("TextLabel")
	self.titleJP.Name                   = "TitleJP"
	self.titleJP.Size                   = UDim2.new(1,0,0,76)
	self.titleJP.Position               = UDim2.new(0,0,0,36)
	self.titleJP.BackgroundTransparency = 1
	self.titleJP.Font                   = Enum.Font.GothamBlack
	self.titleJP.TextScaled             = true
	self.titleJP.TextColor3             = Color3.fromRGB(245,245,245)
	self.titleJP.TextStrokeColor3       = Color3.fromRGB(0,0,0)
	self.titleJP.TextStrokeTransparency = 0.25
	self.titleJP.ZIndex                 = 2
	self.titleJP.Parent                 = ui

	self.titleEN = Instance.new("TextLabel")
	self.titleEN.Name                   = "TitleEN"
	self.titleEN.Size                   = UDim2.new(1,0,0,38)
	self.titleEN.Position               = UDim2.new(0,0,0,104)
	self.titleEN.BackgroundTransparency = 1
	self.titleEN.Font                   = Enum.Font.Gotham
	self.titleEN.TextScaled             = true
	self.titleEN.TextColor3             = Color3.fromRGB(235,235,235)
	self.titleEN.TextStrokeColor3       = Color3.fromRGB(0,0,0)
	self.titleEN.TextStrokeTransparency = 0.35
	self.titleEN.ZIndex                 = 2
	self.titleEN.Parent                 = ui

	-- ステータス
	self.statusLabel = Instance.new("TextLabel")
	self.statusLabel.Name                   = "Status"
	self.statusLabel.Size                   = UDim2.new(1,0,0,26)
	self.statusLabel.Position               = UDim2.new(0,0,0,146)
	self.statusLabel.BackgroundTransparency = 1
	self.statusLabel.Font                   = Enum.Font.Gotham
	self.statusLabel.TextSize               = 20
	self.statusLabel.TextColor3             = Color3.fromRGB(230,230,230)
	self.statusLabel.TextStrokeColor3       = Color3.fromRGB(0,0,0)
	self.statusLabel.TextStrokeTransparency = 0.6
	self.statusLabel.TextXAlignment         = Enum.TextXAlignment.Center
	self.statusLabel.ZIndex                 = 2
	self.statusLabel.Parent                 = ui

	--========================
	-- メニュー
	--========================
	local menu = Instance.new("Frame")
	menu.Name                   = "Menu"
	menu.Size                   = UDim2.new(0, 360, 0, 10)
	menu.AutomaticSize          = Enum.AutomaticSize.Y
	menu.BackgroundTransparency = 1
	menu.AnchorPoint            = Vector2.new(0.5, 0.5)
	menu.Position               = UDim2.fromScale(0.5, 0.55)
	menu.ZIndex                 = 2
	menu.Parent                 = ui

	local layout = Instance.new("UIListLayout")
	layout.Padding              = UDim.new(0, 10)
	layout.HorizontalAlignment  = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment    = Enum.VerticalAlignment.Center
	layout.SortOrder            = Enum.SortOrder.LayoutOrder
	layout.Parent               = menu

	local function makeBtn(text: string)
		local b = Instance.new("TextButton")
		b.Size                   = UDim2.new(1, 0, 0, 56)
		b.BackgroundColor3       = Color3.fromRGB(30,34,44)
		b.BackgroundTransparency = 0.12
		b.BorderSizePixel        = 0
		b.AutoButtonColor        = true
		b.Text                   = text
		b.TextColor3             = Color3.fromRGB(235,235,235)
		b.Font                   = Enum.Font.GothamMedium
		b.TextSize               = 22
		b.ZIndex                 = 2
		b.Parent                 = menu

		local uic = Instance.new("UICorner"); uic.CornerRadius = UDim.new(0, 12); uic.Parent = b
		local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(70,75,90); stroke.Thickness = 1; stroke.Parent = b
		local shadow = Instance.new("UIStroke"); shadow.Color = Color3.fromRGB(0,0,0); shadow.Thickness = 3; shadow.Transparency = 0.9; shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; shadow.Parent = b
		return b
	end

	-- ★ ボタン構成（START / SHRINE / ITEMS / SETTINGS / PATCH NOTES）
	self.btnStart     = makeBtn("") -- 文言は後で適用（HomeOpenまで同期中表示）
	self.btnShrine    = makeBtn("")
	self.btnItems     = makeBtn("")
	self.btnSettings  = makeBtn("")
	self.btnPatch     = makeBtn("")

	--========================
	-- BETA バッジ
	--========================
	local beta = Instance.new("TextLabel")
	beta.Name                   = "BetaBadge"
	beta.AnchorPoint            = Vector2.new(1,1)
	beta.Position               = UDim2.new(1, -(16 + RIGHT_SAFE_PAD), 1, -12) -- ← 右余白を追加
	beta.BackgroundTransparency = 0.25
	beta.BackgroundColor3       = Color3.fromRGB(20,22,28)
	beta.Font                   = Enum.Font.GothamBold
	beta.TextSize               = 16
	beta.TextColor3             = Color3.fromRGB(255,255,255)
	beta.ZIndex                 = 3
	beta.Parent                 = ui
	local betaCorner = Instance.new("UICorner"); betaCorner.CornerRadius = UDim.new(0, 8); betaCorner.Parent = beta
	local betaPad = Instance.new("UIPadding")
	betaPad.PaddingLeft   = UDim.new(0,10)
	betaPad.PaddingRight  = UDim.new(0,10)
	betaPad.PaddingTop    = UDim.new(0,4)
	betaPad.PaddingBottom = UDim.new(0,4)
	betaPad.Parent        = beta
	self.betaLabel = beta

	--========================
	-- 言語スイッチ（右上）
	--========================
	local langBox = Instance.new("Frame")
	langBox.Name                   = "LangBox"
	langBox.AnchorPoint            = Vector2.new(1,0)
	langBox.Position               = UDim2.new(1, -(16 + RIGHT_SAFE_PAD), 0, 16) -- ← 右余白を追加
	langBox.BackgroundColor3       = Color3.fromRGB(20,22,28)
	langBox.BackgroundTransparency = 0.25
	langBox.ZIndex                 = 3
	langBox.AutomaticSize          = Enum.AutomaticSize.XY -- 中身に合わせて自動拡張
	langBox.Parent                 = ui
	local lbCorner = Instance.new("UICorner"); lbCorner.CornerRadius = UDim.new(0, 10); lbCorner.Parent = langBox
	local lbPad    = Instance.new("UIPadding")
	lbPad.PaddingLeft   = UDim.new(0,8)
	lbPad.PaddingRight  = UDim.new(0,8)
	lbPad.PaddingTop    = UDim.new(0,4)
	lbPad.PaddingBottom = UDim.new(0,4)
	lbPad.Parent        = langBox

	local h = Instance.new("UIListLayout")
	h.FillDirection       = Enum.FillDirection.Horizontal
	h.Padding             = UDim.new(0, 6)
	h.HorizontalAlignment = Enum.HorizontalAlignment.Center
	h.VerticalAlignment   = Enum.VerticalAlignment.Center
	h.Parent              = langBox

	local function makeChip(text)
		local b = Instance.new("TextButton")
		b.Size                   = UDim2.new(0, 56, 0, 28)
		b.BackgroundColor3       = Color3.fromRGB(36,40,52)
		b.BackgroundTransparency = 0.1
		b.BorderSizePixel        = 0
		b.AutoButtonColor        = true
... (truncated)
```

### src/client/ui/screens/PatchNotesModal.lua
```lua
-- StarterPlayerScripts/UI/screens/PatchNotesModal.lua
-- v0.9.7-P2-1  Patch Notes: 前面フルスクリーンモーダル（スクロール）
-- * 外部I/F言語コードを 'ja'/'en' に統一（'jp' 受信時は 'ja' に正規化）
-- * Locale.get() を優先利用（辞書取得の堅牢化）
-- * 言語正規化/初期取得を LocaleUtil に統合

local Patch = {}
Patch.__index = Patch

local RS = game:GetService("ReplicatedStorage")

local Locale        = require(RS:WaitForChild("Config"):WaitForChild("Locale"))
local LocaleUtil    = require(RS:WaitForChild("SharedModules"):WaitForChild("LocaleUtil"))

-- PatchNotes を安全にロード（任意ファイル）
local function safeLoadPatchNotes()
	local ok, mod = pcall(function()
		local cfg = RS:FindFirstChild("Config")
		if not cfg then return nil end
		local src = cfg:FindFirstChild("PatchNotes")
		return src and require(src) or nil
	end)
	if ok and type(mod) == "table" then
		return mod
	end
	return nil
end

local function makeL(dict) return function(k) return dict[k] or k end end
local function Dget(dict, key, fallback) return (dict and dict[key]) or fallback end

-- "jp" を受けたら警告して "ja" に、その他は LocaleUtil.norm に委譲
local function normLangJa(v:string?): string
	local raw = tostring(v or ""):lower()
	local n = LocaleUtil.norm(raw) or "en"
	if raw == "jp" and n == "ja" then
		warn("[PatchNotesModal] received legacy 'jp'; normalizing to 'ja'")
	end
	return n
end

--========================
-- Ctor
--========================
-- opts = { parentGui:ScreenGui, lang:"ja"|"en" (legacy "jp" accepted) }
function Patch.new(opts)
	local self = setmetatable({}, Patch)

	self.Locale = Locale
	-- 指定 > safeGlobal > pickInitial（内部で pick→"en" フォールバック）
	self.lang   = normLangJa((opts and opts.lang) or LocaleUtil.safeGlobal() or LocaleUtil.pickInitial())

	-- Locale.get を優先（無ければテーブル直参照 → en フォールバック）
	local dict = (type(self.Locale.get)=="function" and self.Locale.get(self.lang))
		or self.Locale[self.lang] or self.Locale.en
	self.Dict   = dict
	self._L     = makeL(self.Dict)
	self.parent = opts and opts.parentGui

	self.PatchNotes = safeLoadPatchNotes()

	-- ルート（画面全体、最前面）
	local root = Instance.new("Frame")
	root.Name                   = "PatchModal"
	root.Size                   = UDim2.fromScale(1,1)
	root.BackgroundColor3       = Color3.fromRGB(0,0,0)
	root.BackgroundTransparency = 0.35
	root.ZIndex                 = 50
	root.Visible                = false
	if self.parent then root.Parent = self.parent end
	self.root = root

	-- クリック吸収
	local blocker = Instance.new("TextButton")
	blocker.Name                   = "Blocker"
	blocker.Size                   = UDim2.fromScale(1,1)
	blocker.BackgroundTransparency = 1
	blocker.Text                   = ""
	blocker.AutoButtonColor        = false
	blocker.ZIndex                 = 50
	blocker.Parent                 = root

	-- パネル
	local panel = Instance.new("Frame")
	panel.Name                   = "Panel"
	panel.AnchorPoint            = Vector2.new(0.5, 0.5)
	panel.Position               = UDim2.fromScale(0.5, 0.5)
	panel.Size                   = UDim2.new(0.84, 0, 0.78, 0)
	panel.BackgroundColor3       = Color3.fromRGB(24,26,34)
	panel.BackgroundTransparency = 0.05
	panel.ZIndex                 = 55
	panel.Parent                 = root
	local round = Instance.new("UICorner"); round.CornerRadius = UDim.new(0,16); round.Parent = panel
	local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(70,75,90); stroke.Thickness = 1; stroke.Parent = panel

	-- ヘッダ（タイトル＋閉じる）
	local header = Instance.new("Frame")
	header.Name                   = "Header"
	header.Size                   = UDim2.new(1, 0, 0, 52)
	header.BackgroundTransparency = 1
	header.ZIndex                 = 56
	header.Parent                 = panel

	local title = Instance.new("TextLabel")
	title.Name                   = "Title"
	title.Position               = UDim2.new(0, 20, 0, 8)
	title.Size                   = UDim2.new(1, -80, 1, -8)
	title.BackgroundTransparency = 1
	title.Font                   = Enum.Font.GothamBold
	title.TextSize               = 24
	title.TextXAlignment         = Enum.TextXAlignment.Left
	title.TextColor3             = Color3.fromRGB(240,240,240)
	title.ZIndex                 = 56
	title.Parent                 = header
	self.titleLbl = title

	local close = Instance.new("TextButton")
	close.Name                   = "Close"
	close.AnchorPoint            = Vector2.new(1,0)
	close.Position               = UDim2.new(1, -12, 0, 10)
	close.Size                   = UDim2.new(0, 36, 0, 32)
	close.BackgroundColor3       = Color3.fromRGB(36,40,52)
	close.BackgroundTransparency = 0.1
	close.AutoButtonColor        = true
	close.Text                   = "×"
	close.Font                   = Enum.Font.GothamBold
	close.TextSize               = 22
	close.TextColor3             = Color3.fromRGB(235,235,235)
	close.ZIndex                 = 57
	close.Parent                 = header
	local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 8); cr.Parent = close
	local cs = Instance.new("UIStroke"); cs.Color = Color3.fromRGB(70,75,90); cs.Thickness = 1; cs.Parent = close
	close.Activated:Connect(function() self:hide() end)

	-- ボディ（スクロール）
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name                    = "BodyScroll"
	scroll.AnchorPoint            = Vector2.new(0.5, 0)
	scroll.Position               = UDim2.new(0.5, 0, 0, 56)
	scroll.Size                   = UDim2.new(1, -24, 1, -66)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
	scroll.ScrollBarThickness     = 8
	scroll.AutomaticCanvasSize    = Enum.AutomaticSize.None
	scroll.ZIndex                 = 55
	scroll.Parent                 = panel
	self.scroll = scroll

	local body = Instance.new("TextLabel")
	body.Name                   = "Body"
	body.Size                   = UDim2.new(1, -20, 0, 0)
	body.Position               = UDim2.new(0, 10, 0, 6)
	body.BackgroundTransparency = 1
	body.Font                   = Enum.Font.Gotham
	body.TextSize               = 18
	body.TextXAlignment         = Enum.TextXAlignment.Left
	body.TextYAlignment         = Enum.TextYAlignment.Top
	body.TextWrapped            = true
	body.RichText               = true
	body.TextColor3             = Color3.fromRGB(235,235,235)
	body.ZIndex                 = 55
	body.Parent                 = scroll
	self.bodyLbl = body

	-- テキスト変化でリサイズ
	body:GetPropertyChangedSignal("TextBounds"):Connect(function()
		local h = math.max(0, body.TextBounds.Y)
		body.Size = UDim2.new(1, -20, 0, h + 8)
		scroll.CanvasSize = UDim2.new(0, 0, 0, h + 20)
	end)

	-- 初期テキスト反映
	self:_applyText()

	return self
end

--========================
-- 内部：文字列の決定と適用
--========================
function Patch:_getStrings()
	-- 既定値（Locale辞書）
	local title = Dget(self.Dict, "PATCH_TITLE", "Patch Notes")
	local body  = Dget(self.Dict, "PATCH_BODY", [[<b>Coming soon...</b>
We’ll post detailed changes here.]])

	-- Config/PatchNotes.lua があれば優先
	-- return { title = {ja=..., en=...}, body={ja=..., en=...} } もしくは title_ja/title_en を想定
	if self.PatchNotes then
		local lang = self.lang -- 'ja' or 'en'
		local t = self.PatchNotes.title
		if type(t) == "table" and type(t[lang]) == "string" then
			title = t[lang]
		elseif type(self.PatchNotes["title_"..lang]) == "string" then
			title = self.PatchNotes["title_"..lang]
		end
		local b = self.PatchNotes.body
		if type(b) == "table" and type(b[lang]) == "string" then
			body = b[lang]
		elseif type(self.PatchNotes["body_"..lang]) == "string" then
			body = self.PatchNotes["body_"..lang]
		end
	end
	return title, body
end

function Patch:_applyText()
	local title, body = self:_getStrings()
	if self.titleLbl then self.titleLbl.Text = title end
	if self.bodyLbl  then self.bodyLbl.Text  = body  end
	-- スクロール位置を先頭へ
	if self.scroll then self.scroll.CanvasPosition = Vector2.new(0,0) end
end

--========================
-- API
--========================
function Patch:setLanguage(lang)
	local nl = normLangJa(lang)
	if self.lang == nl then return end
	self.lang = nl
	-- Locale.get を優先
	local dict = (type(self.Locale.get)=="function" and self.Locale.get(self.lang))
		or self.Locale[self.lang] or self.Locale.en
	self.Dict = dict
	self._L   = makeL(self.Dict)
	self:_applyText()
end

function Patch:show()
	if self.root then self.root.Visible = true end
end

function Patch:hide()
	if self.root then self.root.Visible = false end
end

return Patch
```

### src/client/ui/screens/RunScreen.lua
```lua
-- StarterPlayerScripts/UI/screens/RunScreen.lua
-- v0.9.7-P2-8
--  - StageResult の互換受信を強化（{close=true} / (true,data) / data 単体の全対応）
--  - Home等への遷移後にリザルトが残留しないよう、show() 冒頭で明示的に hide / _resultShown リセット
--  - 既存機能・UIは維持
--  - [FIX-S1] StatePush(onState)で護符を反映 / [FIX-S2] show()でnil上書きを防止
--  - 監視用ログを追加（[LOG] マーク）
--  - ★ サーバ確定の talisman をそのまま描画（クライアントで補完/推測しない）

local Run = {}
Run.__index = Run

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Logger
local Logger = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("RunScreen")

-- Modules
local Config = ReplicatedStorage:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

-- 相対モジュール
local components     = script.Parent.Parent:WaitForChild("components")
local renderersDir   = components:WaitForChild("renderers")
local HandRenderer   = require(renderersDir:WaitForChild("HandRenderer"))
local FieldRenderer  = require(renderersDir:WaitForChild("FieldRenderer"))
local TakenRenderer  = require(renderersDir:WaitForChild("TakenRenderer"))
local ResultModal    = require(components:WaitForChild("ResultModal"))
local Overlay        = require(components:WaitForChild("Overlay"))
local DevTools       = require(components:WaitForChild("DevTools"))
local YakuPanel      = require(components:WaitForChild("YakuPanel"))
local TalismanBoard  = require(components:WaitForChild("TalismanBoard"))

local lib        = script.Parent.Parent:WaitForChild("lib")
local Format     = require(lib:WaitForChild("FormatUtil"))

local screensDir = script.Parent
local UIBuilder  = require(screensDir:WaitForChild("RunScreenUI"))
local RemotesCtl = require(screensDir:WaitForChild("RunScreenRemotes"))

--==================================================
-- Lang helpers（最小限）
--==================================================

local function normLangJa(lang: string?)
	local v = tostring(lang or ""):lower()
	if v == "jp" then
		LOG.warn("[Locale] received legacy 'jp'; normalize to 'ja'") -- [LOG]
		return "ja"
	elseif v == "ja" or v == "en" then
		return v
	end
	return nil
end

local function mapLangForPanel(lang)
	local n = normLangJa(lang)
	return (n == "ja") and "ja" or "en"
end

local function safeGetGlobalLang()
	if typeof(Locale.getGlobal) == "function" then
		local ok, v = pcall(Locale.getGlobal)
		if ok then
			local n = normLangJa(v)
			if n == "ja" or n == "en" then
				return n
			end
		else
			LOG.debug("Locale.getGlobal failed (pcall)") -- [LOG]
		end
	end
	return nil
end

--==================================================
-- Class
--==================================================

function Run.new(deps)
	local self = setmetatable({}, Run)
	self.deps = deps
	self._awaitingInitial = false
	self._resultShown = false
	self._langConn = nil

	-- 言語初期値（安全取得 → Locale.pick() → "en"）※"jp" は "ja" に正規化
	local initialLang = safeGetGlobalLang()
	if not initialLang then
		if type(Locale.pick) == "function" then
			initialLang = normLangJa(Locale.pick()) or "en"
		else
			initialLang = "en"
		end
	end
	self._lang = initialLang
	LOG.info("boot | lang=%s", tostring(initialLang)) -- [LOG]

	-- UI 構築
	local ui = UIBuilder.build(nil, { lang = initialLang })
	self.gui           = ui.gui
	self.frame         = ui.root
	self.info          = ui.info
	self.goalText      = ui.goalText
	self.handArea      = ui.handArea
	self.boardRowTop   = ui.boardRowTop
	self.boardRowBottom= ui.boardRowBottom
	self.takenBox      = ui.takenBox
	self._scoreBox     = ui.scoreBox
	self.buttons       = ui.buttons
	self._ui_setLang   = ui.setLang
	self._fmtScore     = ui.formatScore or function(score, mons, pts, rolesText)
		if self._lang == "ja" then
			return string.format("得点：%d\n文%d×%d点\n%s", score or 0, mons or 0, pts or 0, rolesText or "役：--")
		else
			return string.format("Score: %d\n%dMon × %dPts\n%s", score or 0, mons or 0, pts or 0, rolesText or "Roles: --")
		end
	end

	-- Overlay / ResultModal
	local loadingText = Theme.loadingText or "Loading..."
	self._overlay     = Overlay.create(self.frame, loadingText)
	self._resultModal = ResultModal.create(self.frame)

	-- ResultModal → Nav（なければ DecideNext フォールバック）
	if self.deps and self.deps.Nav and type(self.deps.Nav.next) == "function" then
		self._resultModal:bindNav(self.deps.Nav)
	else
		self._resultModal:on({
			home  = function()
				if self.deps and self.deps.DecideNext then
					self.deps.DecideNext:FireServer("home")
				end
			end,
			next  = function()
				if self.deps and self.deps.DecideNext then
					self.deps.DecideNext:FireServer("next")
				end
			end,
			save  = function()
				if self.deps and self.deps.DecideNext then
					self.deps.DecideNext:FireServer("save")
				end
			end,
			final = function()
				if self.deps and self.deps.DecideNext then
					self.deps.DecideNext:FireServer("home")
				end
			end,
		})
	end

	-- 役倍率パネル
	self._yakuPanel = YakuPanel.mount(self.gui)

	-- ====== 護符ボード：中央カラムの下段に設置 ======
	do
		if ui.notice then
			local nb = ui.notice.Parent
			if nb then
				nb.Size = UDim2.fromScale(1, 0)
				nb.Visible = false
			end
		end
		if ui.help then
			local tb = ui.help.Parent
			if tb then
				tb.Size = UDim2.fromScale(1, 0)
				tb.Visible = false
			end
		end

		local center = nil
		if ui.handArea then center = ui.handArea.Parent end

		local taliArea = Instance.new("Frame")
		taliArea.Name = "TalismanArea"
		taliArea.Parent = center
		taliArea.BackgroundTransparency = 1
		taliArea.Size = UDim2.fromScale(1, 0)
		taliArea.AutomaticSize = Enum.AutomaticSize.Y
		taliArea.LayoutOrder = 5

		self._taliBoard = TalismanBoard.new(taliArea, {
			title = (self._lang == "ja") and "護符ボード" or "Talisman Board",
			widthScale = 0.9,
			padScale   = 0.01,
		})
		local inst = self._taliBoard:getInstance()
		inst.AnchorPoint = Vector2.new(0.5, 0)
		inst.Position    = UDim2.fromScale(0.5, 0)
		inst.ZIndex      = 2
		LOG.debug("talisman board mounted (center/bottom)") -- [LOG]
	end
	-- ====== ここまで ======

	--- Studio専用 DevTools（維持）
	if RunService:IsStudio() then
		local r = nil
		if self.deps then r = self.deps.remotes end

		local grantRyo  = nil
		if self.deps and (self.deps.DevGrantRyo ~= nil) then
			grantRyo = self.deps.DevGrantRyo
		elseif r and (r.DevGrantRyo ~= nil) then
			grantRyo = r.DevGrantRyo
		end

		local grantRole = nil
		if self.deps and (self.deps.DevGrantRole ~= nil) then
			grantRole = self.deps.DevGrantRole
		elseif r and (r.DevGrantRole ~= nil) then
			grantRole = r.DevGrantRole
		end

		if grantRyo or grantRole then
			DevTools.create(
				self.frame,
				{ DevGrantRyo = grantRyo, DevGrantRole = grantRole },
				{ grantRyoAmount = 1000, offsetX = 10, offsetY = 10, width = 160, height = 32 }
			)
		end
	end

	-- 内部状態
	self._selectedHandIdx = nil

	-- レンダラー適用
	local function renderHand(hand)
		HandRenderer.render(self.handArea, hand, {
			selectedIndex = self._selectedHandIdx,
			onSelect = function(i)
				if self._selectedHandIdx == i then
					self._selectedHandIdx = nil
				else
					self._selectedHandIdx = i
				end
				HandRenderer.render(self.handArea, hand, {
					selectedIndex = self._selectedHandIdx,
					onSelect = function(_) end,
				})
			end,
		})
		if self._awaitingInitial then
			LOG.debug("initial hand received → overlay hide") -- [LOG]
			self._overlay:hide()
			self._awaitingInitial = false
		end
	end

	local function renderField(field)
		FieldRenderer.render(self.boardRowTop, self.boardRowBottom, field, {
			rowPaddingScale = 0.02,
			onPick = function(bindex)
				if self._selectedHandIdx then
					self.deps.ReqPick:FireServer(self._selectedHandIdx, bindex)
					self._selectedHandIdx = nil
				end
			end,
		})
	end

	local function renderTaken(cards)
		TakenRenderer.renderTaken(self.takenBox, cards or {})
	end

	-- スコア更新
	local function onScore(total, roles, detail)
		if typeof(roles) ~= "table" then roles = {} end
		if typeof(detail) ~= "table" then detail = { mon = 0, pts = 0 } end
		local mon = tonumber(detail.mon) or 0
		local pts = tonumber(detail.pts) or 0
		local tot = tonumber(total) or 0
		if self._scoreBox then
			local rolesBody  = Format.rolesToLines(roles, self._lang)
			local rolesLabel = (self._lang == "en") and "Roles: " or "役："
			self._scoreBox.Text = self._fmtScore(tot, mon, pts, rolesLabel .. rolesBody)
		end
		LOG.debug("score | total=%s mon=%s pts=%s roles#=%d",
			tostring(tot), tostring(mon), tostring(pts), #roles) -- [LOG]
	end

	-- 状態更新
	local function onState(st)
		self.info.Text = Format.stateLineText(st) or ""

		if self.goalText then
			local g = (typeof(st) == "table") and tonumber(st.goal) or nil
			local label = (self._lang == "en") and "Goal:" or "目標："
			self.goalText.Text = g and (label .. tostring(g)) or (label .. "—")
		end

		if self._yakuPanel then
			self._yakuPanel:update({
				lang    = mapLangForPanel(self._lang),
				matsuri = st and st.matsuri,
			})
... (truncated)
```

### src/client/ui/screens/RunScreenRemotes.lua
```lua
-- StarterPlayerScripts/UI/screens/RunScreenRemotes.lua
-- Remote 購読/解除と、UI適用の橋渡し

local M = {}

export type Handlers = {
	onHand: (any)->(),
	onField: (any)->(),
	onTaken: (any)->(),
	onScore: (total:any, roles:any, detail:any)->(),
	onState: (st:any)->(),
	onStageResult: (...any)->(),
}

function M.create(deps: any, h: Handlers)
	local self = {
		_conns = {} :: { RBXScriptConnection },
		_connected = false,
		deps = deps or {},
		h = h or ({} :: any),
	}

	-- 内部：安全に Connect するヘルパ
	local function _tryConnect(signal: any, handler: (...any)->())
		if typeof(signal) == "Instance" and signal:IsA("RemoteEvent") then
			return signal.OnClientEvent:Connect(handler)
		elseif typeof(signal) == "RBXScriptSignal" then
			-- もし将来 Bindable/Signal を使う場合の逃げ
			return signal:Connect(handler)
		end
		return nil
	end

	function self:connect()
		if self._connected then return end
		self._connected = true

		-- 必須系
		local c1 = _tryConnect(self.deps.HandPush , self.h.onHand)
		local c2 = _tryConnect(self.deps.FieldPush, self.h.onField)
		local c3 = _tryConnect(self.deps.TakenPush, self.h.onTaken)
		local c4 = _tryConnect(self.deps.ScorePush, self.h.onScore)
		local c5 = _tryConnect(self.deps.StatePush, self.h.onState)

		-- 任意：StageResult
		local c6 = nil
		if self.deps.StageResult ~= nil then
			c6 = _tryConnect(self.deps.StageResult, function(...) self.h.onStageResult(...) end)
		end

		-- つながったものだけ蓄積
		if c1 then table.insert(self._conns, c1) end
		if c2 then table.insert(self._conns, c2) end
		if c3 then table.insert(self._conns, c3) end
		if c4 then table.insert(self._conns, c4) end
		if c5 then table.insert(self._conns, c5) end
		if c6 then table.insert(self._conns, c6) end
	end

	function self:disconnect()
		for _, c in ipairs(self._conns) do
			pcall(function() c:Disconnect() end)
		end
		table.clear(self._conns)
		self._connected = false
	end

	return self
end

return M
```

### src/client/ui/screens/RunScreenUI.lua
```lua
-- StarterPlayerScripts/UI/screens/RunScreenUI.lua
-- UIビルダーは親付けしない契約（親付けは ScreenRouter の責務）
-- v0.9.7-P1-4: Theme完全デフォルト化（色・画像・透過のUI側フォールバック撤去）
-- v0.9.7-P1-3: Logger導入／言語コードを "ja"/"en" に統一（入力 "jp" は "ja" へ正規化）
-- v0.9.6-P0-11 以降：親付け除去／その他の挙動は従来どおり

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")

-- Logger
local Logger = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("RunScreenUI")

local Theme  = require(Config:WaitForChild("Theme"))
local Locale = require(Config:WaitForChild("Locale"))

local lib    = script.Parent.Parent:WaitForChild("lib")
local UiUtil = require(lib:WaitForChild("UiUtil"))

local M = {}

--=== lang helpers =======================================================
local function normLang(v: string?): string?
	local x = tostring(v or ""):lower()
	if x == "ja" or x == "en" then return x end
	if x == "jp" then
		LOG.warn("[Locale] received legacy 'jp'; normalize to 'ja'")
		return "ja"
	end
	return nil
end

local function pickInitialLang(): string
	local g = (typeof(Locale.getGlobal)=="function" and Locale.getGlobal()) or nil
	local n = normLang(g)
	if n then return n end
	local p = (type(Locale.pick)=="function" and Locale.pick()) or nil
	return normLang(p) or "en"
end
--=======================================================================

--=== helpers ============================================================
local function addCornerStroke(frame: Instance, radius: number?, strokeColor: Color3?, thickness: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or (Theme.PANEL_RADIUS or 10))
	corner.Parent = frame
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1
	if strokeColor then s.Color = strokeColor end
	s.Parent = frame
	return frame
end

local function makeList(parent: Instance, dir: Enum.FillDirection, paddingScaleOrPx: number, hAlign, vAlign)
	local l = Instance.new("UIListLayout")
	l.Parent = parent
	l.FillDirection = dir
	local isScale = paddingScaleOrPx <= 1
	l.Padding = isScale and UDim.new(paddingScaleOrPx, 0) or UDim.new(0, paddingScaleOrPx)
	l.HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left
	l.VerticalAlignment   = vAlign or Enum.VerticalAlignment.Top
	l.SortOrder = Enum.SortOrder.LayoutOrder
	return l
end

local function makePanel(parent: Instance, name: string, sizeScale: Vector2, layoutOrder: number, bgColor: Color3, strokeColor: Color3?, titleText: string?, titleColor: Color3?)
	local p = Instance.new("Frame")
	p.Name = name
	p.Parent = parent
	p.Size = UDim2.fromScale(sizeScale.X, sizeScale.Y)
	p.LayoutOrder = layoutOrder or 1
	p.BackgroundColor3 = bgColor
	addCornerStroke(p, nil, strokeColor, 1)
	if titleText and titleText ~= "" then
		local title = UiUtil.makeLabel(p, name.."Title", titleText, UDim2.new(1,-12,0,24), UDim2.new(0,6,0,6), nil, titleColor)
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 3 -- 木目より確実に前面へ
	end
	return p
end

local function makeSideBtn(parent: Instance, name: string, text: string, bg: Color3)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Parent = parent
	btn.Size = UDim2.new(1, 0, 0, 44)
	btn.AutoButtonColor = true
	btn.Text = text
	btn.TextScaled = true
	btn.BackgroundColor3 = bg
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = btn
	return btn
end
--=======================================================================

-- 言語：Global → OS 推定（"jp" は "ja" へ正規化）
local _lang = pickInitialLang()
LOG.debug("init _lang=%s", tostring(_lang))

-- ラベル適用
local function applyTexts(tRefs)
	if not tRefs then return end
	local t = function(key) return Locale.t(_lang, key) end

	-- 右カラム：取り札
	if tRefs.takenPanel and tRefs.takenPanel:FindFirstChild("TakenPanelTitle") then
		tRefs.takenPanel.TakenPanelTitle.Text = t("RUN_TAKEN_TITLE")
		tRefs.takenPanel.TakenPanelTitle.ZIndex = 3
	end

	-- 左カラム：ボタン
	if tRefs.buttons then
		if tRefs.buttons.confirm    then tRefs.buttons.confirm.Text    = t("RUN_BTN_CONFIRM") end
		if tRefs.buttons.rerollAll  then tRefs.buttons.rerollAll.Text  = t("RUN_BTN_REROLL_ALL") end
		if tRefs.buttons.rerollHand then tRefs.buttons.rerollHand.Text = t("RUN_BTN_REROLL_HAND") end
		if tRefs.buttons.yaku       then
			local lbl = Locale.t(_lang, "RUN_BTN_YAKU")
			if not lbl or lbl == "" or lbl == "RUN_BTN_YAKU" then
				lbl = (_lang == "en") and "Yaku" or "役一覧"
			end
			tRefs.buttons.yaku.Text = lbl
		end
	end

	-- ヘルプ
	if tRefs.help then
		local Tm = Theme
		local helpDefault = (Tm and Tm.helpText) and Tm.helpText or t("RUN_HELP_LINE")
		tRefs.help.Text = helpDefault
	end

	-- 情報パネル
	if tRefs.info then
		tRefs.info.Text = t("RUN_INFO_PLACEHOLDER")
	end

	-- スコア：辞書の初期値
	if tRefs.scoreBox then
		tRefs.scoreBox.Text = t("RUN_SCOREBOX_INIT")
	end
end

--[[
UIビルダーは親付けしない契約に統一：
- 第1引数 parentGui は互換のため受け取るが、**親付けには使用しない**（無視）。
- ScreenGui は生成するが、**Parent を設定しない**。親付けは ScreenRouter が行う。
]]
function M.build(_parentGuiIgnored: Instance?, opts)
	local want = opts and opts.lang or nil
	local n = normLang(want)
	if n then _lang = n end
	LOG.debug("build lang=%s (opts=%s)", tostring(_lang), tostring(want))

	--=== Theme ===========================================================
	local T       = Theme
	local C       = T.COLORS
	local R       = T.RATIOS
	local IMAGES  = T.IMAGES
	local TRANSP  = T.TRANSPARENCY

	local ASPECT     = T.ASPECT
	local PAD        = R.CENTER_PAD
	local LEFT_W     = R.LEFT_W
	local RIGHT_W    = R.RIGHT_W
	local BOARD_H    = R.BOARD_H
	local TUTORIAL_H = R.TUTORIAL_H
	local HAND_H     = R.HAND_H
	local ROW_GAP    = 0.035   -- 比率に置きづらい“視覚的間隔”。必要なら Theme.SIZES へ昇格可。
	local COL_GAP    = R.COL_GAP

	local ROOM_BG_IMAGE  = IMAGES.ROOM_BG
	local FIELD_BG_IMAGE = IMAGES.FIELD_BG
	local TAKEN_BG_IMAGE = IMAGES.TAKEN_BG

	local COLOR_TEXT           = C.TextDefault
	local COLOR_RIGHT_BG       = C.RightPaneBg
	local COLOR_RIGHT_STROKE   = C.RightPaneStroke
	local COLOR_PANEL_BG       = C.PanelBg
	local COLOR_PANEL_STROKE   = C.PanelStroke
	local COLOR_NOTICE_BG      = C.NoticeBg   or C.PanelBg        -- 未定義なら PanelBg を流用
	local COLOR_TUTORIAL_BG    = C.TutorialBg or C.PrimaryBtnBg   -- 未定義なら Primary を流用
	local BTN_PRIMARY_BG       = C.PrimaryBtnBg
	local BTN_WARN_BG          = C.WarnBtnBg
	local BTN_YAKU_BG          = C.InfoBtnBg

	--=== ScreenGui（※親付けしない） ======================================
	local g = Instance.new("ScreenGui")
	g.Name = "RunScreen"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 10
	g.Enabled = true
	-- ★ ここで Parent を設定しない（Router が playerGui に付ける）

	-- 背景
	local roomBG = Instance.new("ImageLabel")
	roomBG.Name = "RoomBG"
	roomBG.Parent = g
	roomBG.Image = ROOM_BG_IMAGE
	roomBG.BackgroundTransparency = 1
	roomBG.Size = UDim2.fromScale(1,1)
	roomBG.ScaleType = Enum.ScaleType.Crop
	roomBG.ZIndex = 0
	roomBG.ImageTransparency = TRANSP.roomBg

	-- Root
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Parent = g
	root.Size = UDim2.fromScale(1,1)
	root.BackgroundTransparency = 1
	root.Visible = false
	root.ZIndex = 1

	local playArea = Instance.new("Frame")
	playArea.Name = "PlayArea"
	playArea.Parent = root
	playArea.AnchorPoint = Vector2.new(0.5,0.5)
	playArea.Position = UDim2.fromScale(0.5,0.5)
	playArea.Size = UDim2.fromScale(1,1)
	playArea.BackgroundTransparency = 1
	playArea.ZIndex = 1
	do
		local ar = Instance.new("UIAspectRatioConstraint")
		ar.AspectRatio = ASPECT
		ar.DominantAxis = Enum.DominantAxis.Width
		ar.Parent = playArea
	end

	-- 3カラム
	local left = Instance.new("Frame")
	left.Name = "LeftSidebar"
	left.Parent = playArea
	left.BackgroundTransparency = 1
	left.Size = UDim2.fromScale(LEFT_W, 1 - PAD*2)
	left.Position = UDim2.fromScale(PAD, PAD)
	left.ZIndex = 1

	local center = Instance.new("Frame")
	center.Name = "CenterMain"
	center.Parent = playArea
	center.BackgroundTransparency = 1
	center.Size     = UDim2.fromScale(1 - LEFT_W - RIGHT_W - PAD*2 - COL_GAP*2, 1 - PAD*2)
	center.Position = UDim2.fromScale(PAD + LEFT_W + COL_GAP, PAD)
	center.ZIndex = 1

	local rightPane = Instance.new("Frame")
	rightPane.Name = "RightPane"
	rightPane.Parent = playArea
	rightPane.BackgroundColor3 = COLOR_RIGHT_BG
	rightPane.BackgroundTransparency = T.rightPaneBgT
	rightPane.Size = UDim2.fromScale(RIGHT_W, 1 - PAD*2)
	rightPane.Position = UDim2.fromScale(1 - RIGHT_W - PAD, PAD)
	rightPane.ZIndex = 1
	addCornerStroke(rightPane, nil, COLOR_RIGHT_STROKE, 1)

	-- Left：情報パネル
	makeList(left, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

	local infoPanel = makePanel(left, "InfoPanel", Vector2.new(1, 0.14), 1, COLOR_PANEL_BG, COLOR_PANEL_STROKE)
	local info = UiUtil.makeLabel(infoPanel, "Info", "--", UDim2.new(1,-12,1,-12), UDim2.new(0,6,0,6), Vector2.new(0,0), COLOR_TEXT)
	info.TextWrapped = true
	info.TextScaled = true
	info.TextXAlignment = Enum.TextXAlignment.Left

	-- 目標（見出しなし）
	local goalPanel = makePanel(left, "GoalPanel", Vector2.new(1, 0.10), 2, COLOR_PANEL_BG, COLOR_PANEL_STROKE, nil, nil)
	local goalText = UiUtil.makeLabel(goalPanel, "GoalValue", "—", UDim2.new(1,-12,1,-12), UDim2.new(0,6,0,6), nil, COLOR_TEXT)
	goalText.TextScaled = true
	goalText.TextXAlignment = Enum.TextXAlignment.Left

	-- スコア＋役一覧
	local scorePanel = makePanel(left, "ScorePanel", Vector2.new(1, 0.26), 3, COLOR_PANEL_BG, COLOR_PANEL_STROKE, nil, nil)
	local scoreStack = Instance.new("Frame"); scoreStack.Name="ScoreStack"; scoreStack.Parent=scorePanel
	scoreStack.Size = UDim2.new(1,-12,1,-12); scoreStack.Position = UDim2.new(0,6,0,6); scoreStack.BackgroundTransparency=1
	makeList(scoreStack, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)

	local scoreBox = UiUtil.makeLabel(scoreStack, "ScoreBox", "--", UDim2.new(1,0,0,96), UDim2.new(0,0,0,0), nil, COLOR_TEXT)
	scoreBox.TextYAlignment = Enum.TextYAlignment.Top
	scoreBox.TextWrapped = true
	scoreBox.TextScaled = true

	local btnYaku = makeSideBtn(scoreStack, "OpenYaku", "", BTN_YAKU_BG)

	-- コントロールボタン
	local controlsPanel = Instance.new("Frame")
	controlsPanel.Name = "ControlsPanel"
	controlsPanel.Parent = left
	controlsPanel.Size = UDim2.fromScale(1, 0)
	controlsPanel.AutomaticSize = Enum.AutomaticSize.Y
	controlsPanel.BackgroundTransparency = 1
	controlsPanel.LayoutOrder = 4
	controlsPanel.ZIndex = 1
	makeList(controlsPanel, Enum.FillDirection.Vertical, 8)

	local btnConfirm    = makeSideBtn(controlsPanel, "Confirm",    "", BTN_PRIMARY_BG)
	local btnRerollAll  = makeSideBtn(controlsPanel, "RerollAll",  "", BTN_WARN_BG)
	local btnRerollHand = makeSideBtn(controlsPanel, "RerollHand", "", BTN_WARN_BG)

... (truncated)
```

### src/client/ui/screens/ShopScreen.lua
```lua
-- StarterPlayerScripts/UI/screens/ShopScreen.lua
-- v0.9.7-P2-10 ShopScreen（Server-first talisman + jp→ja + idempotent redraw）
--  - show(payload) で payload.state.run.talisman を即時反映（サーバ確定を優先）
--  - payload.lang を尊重し "jp"→"ja" 正規化
--  - 自動配置は「護符配列が無い or 空スロットがある」時のみ（既存の空き検知で担保）
--  - 同一データの再描画を抑止（talisman シグネチャ比較）

local Shop = {}
Shop.__index = Shop

--========= 依存読込 =========
local RS = game:GetService("ReplicatedStorage")
local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat = require(SharedModules:WaitForChild("ShopFormat"))

local Config = RS:WaitForChild("Config")
local Theme  = require(Config:WaitForChild("Theme"))

local Logger = require(SharedModules:WaitForChild("Logger"))
local LOG = (typeof(Logger.scope) == "function" and Logger.scope("ShopScreen"))
	or (typeof(Logger["for"]) == "function" and Logger["for"]("ShopScreen"))
	or { debug=function()end, info=function()end, warn=function(...) warn(...) end }

-- ui/components/*
local uiRoot = script.Parent.Parent
local componentsFolder = uiRoot:WaitForChild("components")
local ShopUI        = require(componentsFolder:WaitForChild("ShopUI"))
local ShopRenderer  = require(componentsFolder:WaitForChild("renderers"):WaitForChild("ShopRenderer"))
local ShopWires     = require(componentsFolder:WaitForChild("controllers"):WaitForChild("ShopWires"))
local TalismanBoard = require(componentsFolder:WaitForChild("TalismanBoard"))

export type Payload = {
	items: {any}?,
	stock: {any}?,
	mon: number?,
	totalMon: number?,
	rerollCost: number?,
	canReroll: boolean?,
	seasonSum: number?,
	target: number?,
	rewardMon: number?,
	lang: string?,
	notice: string?,
	currentDeck: any?,
	state: any?,
}

--==================================================
-- helpers
--==================================================

local function normToJa(lang: string?)
	local v = ShopFormat.normLang(lang)
	if v == "jp" then
		LOG.warn("[Locale] received legacy 'jp'; normalize to 'ja'")
		return "ja"
	end
	return v
end

local function countItems(p: Payload?): number
	if not p then return 0 end
	if typeof(p.items) == "table" then return #p.items end
	if typeof(p.stock) == "table" then return #p.stock end
	return 0
end

local function getTalismanFromPayload(p: Payload?)
	if not p then return nil end
	local s = p.state
	if s and s.run and s.run.talisman then
		return s.run.talisman
	end
	return nil
end

local function cloneSlots6(slots)
	local s = slots or {}
	return { s[1], s[2], s[3], s[4], s[5], s[6] }
end

local function cloneTalismanData(t)
	if typeof(t) ~= "table" then
		return nil
	end
	return {
		maxSlots = tonumber(t.maxSlots or 6) or 6,
		unlocked = tonumber(t.unlocked or 0) or 0,
		slots    = cloneSlots6(t.slots),
	}
end

local function stockSignature(itemsTbl)
	if type(itemsTbl) ~= "table" then return "" end
	local ids = {}
	for i, it in ipairs(itemsTbl) do
		ids[i] = tostring(it.id or ("#"..i))
	end
	table.sort(ids)
	return table.concat(ids, "|")
end

local function talismanSignature(t)
	if typeof(t) ~= "table" then return "<nil>" end
	local parts = { tostring(tonumber(t.unlocked or 0) or 0) }
	local s = t.slots or {}
	for i = 1, 6 do
		parts[#parts+1] = tostring(s[i] or "")
	end
	return table.concat(parts, "|")
end

--==================================================
-- class
--==================================================

function Shop.new(deps)
	local self = setmetatable({}, Shop)
	self.deps = deps
	self._payload = nil
	self._closing = false
	self._buyBusy = false
	self._rerollBusy = false
	self._lang = nil
	self._deckOpen = false
	self._bg = nil
	self._taliBoard = nil

	-- プレビュー/ローカル影/シグネチャ
	self._preview = nil
	self._lastPlaced = nil
	self._localBoard = nil
	self._taliSig = "<none>"

	-- 一時SoldOut
	self._hiddenItems = {}   -- [itemId]=true
	self._stockSig = ""      -- 在庫構成署名

	-- UI生成
	local gui, nodes = ShopUI.build()
	self.gui = gui
	self._nodes = nodes

	-- 背景
	self:_ensureBg()

	-- 配線＆初期プレースホルダ
	ShopWires.wireButtons(self)
	ShopWires.applyInfoPlaceholder(self)

	-- ===== 護符ボード：下段（taliArea）に設置 =====
	do
		local parent = nodes.taliArea or gui  -- 念のためフォールバック
		self._taliBoard = TalismanBoard.new(parent, {
			title      = "護符ボード",
			widthScale = 0.95,   -- 下段にフィット
			padScale   = 0.01,
		})
		local inst = self._taliBoard:getInstance()
		inst.AnchorPoint = Vector2.new(0.5, 0)     -- 中央寄せ
		inst.Position    = UDim2.fromScale(0.5, 0) -- 上端中央
		inst.ZIndex      = 2                       -- 本文よりやや上
	end
	-- ==============================================

	-- Remotes（S4）
	self._remotes = RS:WaitForChild("Remotes", 10)
	if not self._remotes then
		LOG.warn("[ShopScreen] Remotes folder missing (timeout)")
	else
		self._placeRE = self._remotes:WaitForChild("PlaceOnSlot", 10)
		if not self._placeRE then
			LOG.warn("[ShopScreen] PlaceOnSlot missing (timeout)")
		end
		local ack = self._remotes:FindFirstChild("TalismanPlaced")
		if ack and ack:IsA("RemoteEvent") then
			ack.OnClientEvent:Connect(function(data)
				-- サーバ確定：ローカル影を更新
				local base = getTalismanFromPayload(self._payload) or { maxSlots=6, unlocked=0, slots={nil,nil,nil,nil,nil,nil} }
				self._localBoard = {
					maxSlots = base.maxSlots or 6,
					unlocked = tonumber(data and data.unlocked or base.unlocked or 0) or 0,
					slots    = (data and data.slots) or cloneSlots6(base.slots),
				}
				self._taliSig = talismanSignature(self._localBoard)
				self._preview = nil
				self._lastPlaced = nil
				if self._taliBoard then
					self._taliBoard:setData(self._localBoard)
				end
				LOG.debug("ack TalismanPlaced | idx=%s id=%s", tostring(data and data.index), tostring(data and data.id))
			end)
		end
	end

	self.LOG = LOG
	LOG.debug("boot")
	return self
end

--==================================================
-- public
--==================================================

function Shop:_snapBoard()
	return self._localBoard
		or self._preview
		or getTalismanFromPayload(self._payload)
		or { maxSlots=6, unlocked=0, slots={nil,nil,nil,nil,nil,nil} }
end

function Shop:_findFirstEmpty()
	local t = self:_snapBoard()
	local unlocked = tonumber(t.unlocked or 0) or 0
	local slots = t.slots or {}
	for i=1, math.min(unlocked, 6) do
		if slots[i] == nil then return i end
	end
	return nil
end

function Shop:_refreshStockSignature(payload: Payload?)
	local items = (payload and (payload.items or payload.stock)) or {}
	local sig = stockSignature(items)
	if sig ~= self._stockSig then
		self._stockSig = sig
		self._hiddenItems = {}
		LOG.debug("[Shop] stock changed -> clear hidden")
	end
end

function Shop:isItemHidden(id: any)
	if id == nil then return false end
	return self._hiddenItems[tostring(id)] == true
end
function Shop:hideItemTemporarily(id: any)
	if id == nil then return end
	self._hiddenItems[tostring(id)] = true
	self:_render()
end

local function maybeClearPreview(self)
	if not self._preview or not self._lastPlaced then return end
	local base = self:_snapBoard()
	if not base or not base.slots then return end
	local idx = self._lastPlaced.index
	local id  = self._lastPlaced.id
	if idx and id and base.slots[idx] == id then
		self._preview = nil
		self._lastPlaced = nil
		LOG.info("[Shop] preview cleared by server state | idx=%d id=%s", idx, id)
	end
end

-- サーバ確定 talisman をローカルへ即時反映（重複ならスキップ）
function Shop:_applyServerTalismanOnce(payload: Payload?)
	local sv = cloneTalismanData(getTalismanFromPayload(payload))
	if not sv then return end
	local sig = talismanSignature(sv)
	if sig == self._taliSig then
		-- 同一なら再描画不要
		return
	end
	self._localBoard = sv
	self._taliSig = sig
	self._preview = nil
	self._lastPlaced = nil
	if self._taliBoard then
		self._taliBoard:setData(self._localBoard)
	end
	LOG.debug("[Shop] server talisman applied | sig=%s", sig)
end

function Shop:setData(payload: Payload)
	if payload and payload.lang then
		local nl = normToJa(payload.lang)
		if nl and nl ~= payload.lang then payload.lang = nl end
		self._lang = nl or self._lang
	end
	self:_refreshStockSignature(payload)
	self._payload = payload
	maybeClearPreview(self)

	-- サーバ確定護符を優先反映（差分時のみ）
	self:_applyServerTalismanOnce(payload)

	LOG.debug("setData | items=%d lang=%s", countItems(payload), tostring(self._lang))

	if self._taliBoard then
		self._taliBoard:setLang(self._lang or "ja")
		-- ここでの setData は差分適用済み（_applyServerTalismanOnce 内）なので冪等維持
		self._taliBoard:setData(self:_snapBoard())
	end

	self:_render()
end

function Shop:show(payload: Payload?)
	if payload then
		if payload.lang then
... (truncated)
```

### src/client/ui/screens/ShrineScreen.lua
```lua
-- ShrineScreen (ModuleScript)
local Shrine = {}
Shrine.__index = Shrine

function Shrine.new(deps)
	local self = setmetatable({}, Shrine)
	self.deps = deps

	local g = Instance.new("ScreenGui")
	g.Name = "ShrineScreen"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 40
	g.Enabled = false
	self.gui = g

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,0,1,0)
	label.BackgroundTransparency = 1
	label.Text = "神社（恒久強化）- 準備中"
	label.Parent = g

	return self
end

function Shrine:show() self.gui.Enabled = true end
function Shrine:hide() self.gui.Enabled = false end

return Shrine
```

### src/config/DisplayMode.lua
```lua
-- src/config/DisplayMode.lua
local DisplayMode = {}

DisplayMode.Current = "2D"  -- 当面は2D固定

function DisplayMode:is2D() return self.Current == "2D" end
function DisplayMode:is3D() return self.Current == "3D" end

function DisplayMode:set(mode)
	if mode == "2D" then
		self.Current = "2D"; return true
	elseif mode == "3D" then
		warn("[DisplayMode] 3Dは未実装です（当面2D固定）")
		self.Current = "2D"; return false
	else
		warn("[DisplayMode] 不明なモード: ", mode)
		return false
	end
end

return DisplayMode
```

### src/config/Locale.lua
```lua
-- ReplicatedStorage/Config/Locale.lua
-- Home/Run 共通の簡易ローカライズ
-- P0-9: 外部I/Fの言語コードを ja/en に統一。jp は警告を出して ja に正規化。
--  1) Locale.en / Locale.ja を公開（Locale.jp は非推奨 alias）
--  2) Locale.t(lang, key) / Locale.get(lang) / Locale.pick(forced)
--  3) Locale.setGlobal(lang) / Locale.getGlobal() / Locale.changed (Signal)
--  4) jp入力時は warn を一度だけ出す（内部では常に ja に変換）
-- P0-10: OSロケール検出のスタイルを簡素化
--  - 変更点: pcall(game.GetService, game, "Players") → local Players = game:GetService("Players")
--  - 目的: 可読性向上（挙動は不変。LocalPlayer が無い場合は "en" フォールバック）

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

-- ===== OS言語検出（P0-10改修） =====
local Players = game:GetService("Players")

local function detectLang()
	-- Client 以外（サーバ/テスト環境）では LocalPlayer は nil → "en" フォールバック
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

-- 明示的に正規化を呼びたい場合の補助（ShopFormat 等で使用可）
function Locale.normalize(lang)
	return _norm(lang) or "en"
end

return Locale
```

### src/config/PatchNotes.lua
```lua
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
```

### src/config/Theme.lua
```lua
-- ReplicatedStorage/Config/Theme.lua
-- v0.9.7-P1-5: Theme を単一情報源に（UIフォールバック撤去用の既定値を追加）
--              + SHOP_BG（屋台背景）を追加

local Theme = {}

--==================================================
-- 画像ID（畳・毛氈・木目・屋台など）
--==================================================
Theme.IMAGES = {
	ROOM_BG  = "rbxassetid://134603580471930",   -- 和室：背景（最背面）
	FIELD_BG = "rbxassetid://112698123788404",   -- 毛氈：場札エリア（現行の既定IDを尊重）
	TAKEN_BG = "rbxassetid://93059114972102",    -- 木目：取り札エリア

	-- ▼ 追加：ショップ（屋台）背景
	SHOP_BG  = "rbxassetid://98985791814763",
}

--==================================================
-- 背景透過度（視認性調整用）
--==================================================
Theme.TRANSPARENCY = {
	roomBg  = 0.15, -- 和室背景は少し淡く
	boardBg = 0.15, -- 毛氈はほんのり
	takenBg = 0.15, -- 木目もほんのり

	-- ▼ 追加：ショップ背景のデフォルト透過
	shopBg  = 0.12,
}
-- Overlay等の半透明（UI側が使う場合あり）
Theme.overlayBgT = 0.35

-- 右ペインの透過（既存UIが T.rightPaneBgT を読むのでデフォルトを用意）
Theme.rightPaneBgT = 0

-- ヘルプ既定文（Localeが取れない/未ロード時の最終フォールバック）
Theme.helpText = "札を選んで場の札と合わせよう！Rerollで手札を入れ替え可能。"

--==================================================
-- 横基準のプレイエリア縦横比
--==================================================
Theme.ASPECT = 16/9

--==================================================
-- 比率レイアウト用の定数
--==================================================
Theme.RATIOS = {
	PAD        = 0.02,
	CENTER_PAD = 0.02,

	LEFT_W     = 0.18,
	RIGHT_W    = 0.33, -- 広め右ペイン

	BOARD_H    = 0.50,
	TUTORIAL_H = 0.08,
	HAND_H     = 0.28,

	CONTROLS_H = 0.10,
	COL_GAP    = 0.015,

	-- 取り札の横重なり比（0〜1）
	TAKEN_OVERLAP = 0.33,
}

--==================================================
-- 絶対値サイズ
--==================================================
Theme.SIZES = {
	PAD        = 10,
	BOARD_H    = 340,
	CONTROLS_H = 44,
	HELP_H     = 22,
	HAND_H     = 168,
	RIGHT_W    = 495, -- 比率と揃う広めレイアウト
	ROW_GAP    = 12,

	-- ▼ 追加：UIフォールバック排除用
	HandSelectStrokeW = 3,   -- 手札選択枠の太さ
	TAKEN_TAG_W       = 110, -- 取り札セクションのタグ幅
}

--==================================================
-- 見た目（色・角丸）
--==================================================
Theme.COLORS = {
	TextDefault        = Color3.fromRGB(25, 25, 25),
	HelpText           = Color3.fromRGB(60, 40, 20),

	-- パネル系（和紙風に寄せたオフホワイト）
	RightPaneBg        = Color3.fromRGB(250, 248, 240),
	RightPaneStroke    = Color3.fromRGB(210, 200, 190),
	PanelBg            = Color3.fromRGB(252, 250, 244),
	PanelStroke        = Color3.fromRGB(220, 210, 200),

	-- カードバッジ帯
	BadgeBg            = Color3.fromRGB(25, 28, 36),
	BadgeStroke        = Color3.fromRGB(60, 65, 80),

	-- 手札エリアの装飾
	HandHolderBg       = Color3.fromRGB(245, 248, 252),
	HandHolderStroke   = Color3.fromRGB(210, 220, 230),

	-- ボタン
	PrimaryBtnBg       = Color3.fromRGB(190, 50, 50),
	PrimaryBtnText     = Color3.fromRGB(255, 245, 240),

	WarnBtnBg          = Color3.fromRGB(180, 80, 40),
	WarnBtnText        = Color3.fromRGB(255, 240, 230),

	CancelBtnBg        = Color3.fromRGB(120, 130, 140),
	CancelBtnText      = Color3.fromRGB(240, 240, 240),

	DevBtnBg           = Color3.fromRGB(40, 100, 60),
	DevBtnText         = Color3.fromRGB(255, 255, 255),

	-- UI側フォールバックを消すために追加（役一覧ボタン等）
	InfoBtnBg          = Color3.fromRGB(120, 180, 255),

	-- ▼ 追加：RunScreenUI/Taken/HandRenderer で参照されうる既定
	NoticeBg           = Color3.fromRGB(240, 246, 255), -- Noticeバー
	TutorialBg         = Color3.fromRGB(255, 153, 0),   -- Tutorialバー
	OverlayBg          = Color3.fromRGB(0, 0, 0),       -- Overlay下地
	HandSelectStroke   = Color3.fromRGB(40, 120, 90),   -- 手札選択枠の色
}

Theme.PANEL_RADIUS = 10

-- 影の濃さ（HandRenderer が参照）
Theme.HandShadowOnT  = 0.45
Theme.HandShadowOffT = 0.70

--==================================================
-- 役種に応じたバッジ文字色
--==================================================
function Theme.colorForKind(kind: string)
	if kind == "bright" then
		return Color3.fromRGB(255, 230, 140)
	elseif kind == "seed" then
		return Color3.fromRGB(200, 240, 255)
	elseif kind == "ribbon" then
		return Color3.fromRGB(255, 200, 220)
	else
		return Color3.fromRGB(235, 235, 235)
	end
end

return Theme
```

### src/server/GameInit.server.lua
```lua
-- ServerScriptService/GameInit.server.lua
-- エントリポイント：Remotes生成／各Service初期化／永続（SaveService）連携
-- v0.9.2 → v0.9.2-langfix2 (+P1-3 logger):
--  - STARTGAME に統合（セーブがあればCONTINUE / なければNEW）
--  - SaveService.activeRun（季節開始/屋台入場）スナップからの復帰に対応
--  - HomeOpen.hasSave を正しく反映
--  - 言語保存 ReqSetLang を実装
--  - ★ 言語コードを外部公開 "ja/en" に統一（"jp" は受け取ったら "ja" に正規化）
--  - ★ 冬クリア→HOME/保存→HOME 時は“春スナップ”を残さない（hasSave=false を返す）
--  - ★ P1-1: DecideNext の実装を NavServer に一本化（本ファイルは初期化のみ）
--  - ★ P1-3: Logger 導入（print/warn を LOG.* に置換）
--  - ★ P2-10: ラン終了後は強制NEW（_forceNewOnNextStart フラグを尊重）

--==================================================
-- Services
--==================================================
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local SSS     = game:GetService("ServerScriptService")

--==================================================
-- Logger
--==================================================
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("GameInit")
Logger.configure({
	level = Logger.INFO,
	timePrefix = true,
	dupWindowSec = 0.5,
})

LOG.info("boot")

--==================================================
-- SaveService（bank/year/clears/lang/activeRun の永続化）
--==================================================
local SaveService = require(SSS:WaitForChild("SaveService"))

--==================================================
-- Remotes 生成（すべてここで先に生やす）
--==================================================
local function ensureRemote(name: string)
	local rem = RS:FindFirstChild("Remotes")
	if not rem then
		rem = Instance.new("Folder")
		rem.Name = "Remotes"
		rem.Parent = RS
	end
	local e = rem:FindFirstChild(name)
	if not e then
		e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = rem
	end
	return e
end

-- Core push系
local Remotes = {
	HandPush      = ensureRemote("HandPush"),
	FieldPush     = ensureRemote("FieldPush"),
	TakenPush     = ensureRemote("TakenPush"),
	ScorePush     = ensureRemote("ScorePush"),
	StatePush     = ensureRemote("StatePush"),

	-- 結果/遷移
	StageResult   = ensureRemote("StageResult"),
	DecideNext    = ensureRemote("DecideNext"),

	-- 操作（プレイ）
	ReqPick       = ensureRemote("ReqPick"),
	Confirm       = ensureRemote("Confirm"),
	ReqRerollAll  = ensureRemote("ReqRerollAll"),
	ReqRerollHand = ensureRemote("ReqRerollHand"),

	-- 屋台（ショップ）
	ShopOpen      = ensureRemote("ShopOpen"),
	ShopDone      = ensureRemote("ShopDone"),
	BuyItem       = ensureRemote("BuyItem"),
	ShopReroll    = ensureRemote("ShopReroll"),

	-- 同期（C→S：再同期要求。実処理は UiResync.server.lua）
	ReqSyncUI     = ensureRemote("ReqSyncUI"),
}

-- Top/Home 系
local HomeOpen        = ensureRemote("HomeOpen")        -- S→C: トップを開く
local ReqStartNewRun  = ensureRemote("ReqStartNewRun")  -- C→S: ★後方互換（NEW強制）
local ReqContinueRun  = ensureRemote("ReqContinueRun")  -- C→S: ★後方互換（CONTINUE推奨）
local ReqStartGame    = ensureRemote("ReqStartGame")    -- C→S: ★統合エントリ（NEW or CONTINUE 自動）
local RoundReady      = ensureRemote("RoundReady")      -- S→C: 新ラウンド準備完了
local ReqSetLang      = ensureRemote("ReqSetLang")      -- C→S: 言語保存

-- Remotes からも参照できるように追加
Remotes.HomeOpen        = HomeOpen
Remotes.ReqStartNewRun  = ReqStartNewRun
Remotes.ReqContinueRun  = ReqContinueRun
Remotes.ReqStartGame    = ReqStartGame
Remotes.RoundReady      = RoundReady
Remotes.ReqSetLang      = ReqSetLang

--==================================================
-- Server-side modules
--==================================================
local StateHub = require(RS.SharedModules.StateHub)
local Scoring  = require(RS.SharedModules.Scoring)

local Round        = require(RS.SharedModules.RoundService)
local PickService  = require(RS.SharedModules.PickService)
local Reroll       = require(RS.SharedModules.RerollService)
local Score        = require(RS.SharedModules.ScoreService)
local ShopService  = require(RS.SharedModules.ShopService)

-- ★ P1-1: NavServer を導入（DecideNext の唯一線）
local NavServer    = require(SSS:WaitForChild("NavServer"))

--==================================================
-- DEV Remotes（Studio向け：+両 / +役 付与）
--==================================================
local DevGrantRyo  = ensureRemote("DevGrantRyo")
local DevGrantRole = ensureRemote("DevGrantRole")

DevGrantRyo.OnServerEvent:Connect(function(plr, amount)
	amount = tonumber(amount) or 1000
	local s = StateHub.get(plr); if not s then return end
	s.bank = (s.bank or 0) + amount
	StateHub.pushState(plr)
	SaveService.addBank(plr, amount)
	LOG.debug("DevGrantRyo | user=%s amount=%d bank=%d", plr.Name, amount, s.bank or -1)
end)

local function ensureTable(t) return (type(t)=="table") and t or {} end
local function takeByPredOrStub(s, pred, stub)
	s.board = ensureTable(s.board); s.taken = ensureTable(s.taken)
	for i,card in ipairs(s.board) do
		if pred(card) then
			table.insert(s.taken, card); table.remove(s.board, i); return
		end
	end
	local c = table.clone(stub)
	c.id = c.id or ("dev_"..(c.name or ("m"..(c.month or 0))))
	c.tags = c.tags or {}
	table.insert(s.taken, c)
end

DevGrantRole.OnServerEvent:Connect(function(plr)
	local s = StateHub.get(plr); if not s then return end

	takeByPredOrStub(s,
		function(c) return c.month==9 and ((c.tags and table.find(c.tags,"sake")) or c.name=="盃") end,
		{month=9, kind="seed", name="盃", tags={"thing","sake"}}
	)
	takeByPredOrStub(s, function(c) return c.month==8 and c.kind=="bright" end, {month=8, kind="bright", name="芒に月"})
	takeByPredOrStub(s, function(c) return c.month==3 and c.kind=="bright" end, {month=3, kind="bright", name="桜に幕"})

	local total, roles, detail = Scoring.evaluate(s.taken or {}, s)
	s.lastScore = { total = total or 0, roles = roles, detail = detail }
	StateHub.pushState(plr)
	LOG.debug("DevGrantRole | user=%s total=%s", plr.Name, tostring(total))
end)

--==================================================
-- 言語ユーティリティ（ja/en 正規化）
--==================================================
local function normLang(v:string?): string?
	v = tostring(v or ""):lower()
	if v == "ja" or v == "jp" then return "ja" end
	if v == "en" then return "en" end
	return nil
end

--==================================================
-- 初期化／バインド
--==================================================
StateHub.init(Remotes)

if PickService and typeof(PickService.bind) == "function" then
	PickService.bind(Remotes)
else
	LOG.warn("PickService.bind が見つかりません")
end

if Reroll and typeof(Reroll.bind) == "function" then
	Reroll.bind(Remotes)
else
	LOG.warn("Reroll.bind が見つかりません")
end

if Score and typeof(Score.bind) == "function" then
	Score.bind(Remotes, { openShop = ShopService and ShopService.open })
else
	LOG.warn("Score.bind が見つかりません")
end

if ShopService and typeof(ShopService.init) == "function" then
	ShopService.init(
		function(plr) return StateHub.get(plr) end,
		function(plr) StateHub.pushState(plr) end
	)
else
	LOG.warn("ShopService.init が見つかりません")
end

-- ★ P1-1: NavServer を初期化（DecideNext の唯一線）。依存はここで注入。
NavServer.init({
	StateHub    = StateHub,
	Round       = Round,
	ShopService = ShopService,
	SaveService = SaveService,
	HomeOpen    = HomeOpen,           -- S→C push（NavServerで使用）
	DecideNext  = Remotes.DecideNext, -- C→S pull（同上）
})

--==================================================
-- Player lifecycle：永続ロード/保存 + 言語ログ
--==================================================
Players.PlayerAdded:Connect(function(plr)
	LOG.info("PlayerAdded | begin load profile | user=%s userId=%d", plr.Name, plr.UserId)

	local prof = SaveService.load(plr)
	LOG.debug(
		"Profile loaded | user=%s bank=%s year=%s asc=%s clears=%s lang=%s",
		plr.Name,
		tostring(prof and prof.bank), tostring(prof and prof.year),
		tostring(prof and prof.asc),  tostring(prof and prof.clears),
		tostring(prof and prof.lang)
	)

	local s = StateHub.get(plr) or {}
	local savedLang = normLang(SaveService.getLang(plr)) or "en"

	s.bank        = prof.bank   or 0
	s.year        = prof.year   or 0
	s.totalClears = prof.clears or 0
	s.lang        = savedLang
	-- 念のため NEW強制フラグは初期状態では無効化
	s._forceNewOnNextStart = false

	StateHub.set(plr, s)

	LOG.debug(
		"State set | user=%s lang=%s bank=%d year=%d clears=%d",
		plr.Name, s.lang, s.bank or 0, s.year or 0, s.totalClears or 0
	)

	local hasSave = SaveService.getActiveRun(plr) ~= nil
	LOG.info(
		"HomeOpen → C | user=%s lang=%s hasSave=%s bank=%d year=%d clears=%d",
		plr.Name, s.lang, tostring(hasSave), s.bank or 0, s.year or 0, s.totalClears or 0
	)

	HomeOpen:FireClient(plr, {
		hasSave = hasSave,
		bank    = s.bank,
		year    = s.year,
		clears  = s.totalClears or 0,
		lang    = s.lang, -- "ja" or "en"
	})
end)

Players.PlayerRemoving:Connect(function(plr)
	LOG.info("PlayerRemoving | flush profile | user=%s", plr.Name)
	SaveService.flush(plr)
end)

game:BindToClose(function()
	LOG.info("BindToClose | flushAll begin")
	pcall(function() SaveService.flushAll() end)
	LOG.info("BindToClose | flushAll end")
end)

--==================================================
-- 言語保存（C→S）
--==================================================
ReqSetLang.OnServerEvent:Connect(function(plr, lang)
	local n = normLang(lang)
	if not n then
		LOG.warn("ReqSetLang invalid | user=%s from=%s", plr.Name, tostring(lang))
		return
	end
	SaveService.setLang(plr, n)

	local s = StateHub.get(plr) or {}
	s.lang = n
	StateHub.set(plr, s)

	LOG.info("setLang | saved & state updated | user=%s lang=%s", plr.Name, n)
end)

--==================================================
-- ラン開始/続き（RoundReady → RunScreen.requestSync → UiResync）
--==================================================
local function fireReadySoon(plr)
	task.delay(0.05, function()
		Remotes.RoundReady:FireClient(plr)
	end)
end

local function startNewRun(plr)
	-- NEW 開始前に続きスナップは必ず破棄
... (truncated)
```

### src/server/NavServer.lua
```lua
-- v0.9.7 P1-3 Nav 集約：DecideNext を唯一線に（保存廃止 / 次ステージロック可）
-- 追加修正:
--  - ラン終了時に StageResult を強制クローズ通知（残存モーダル対策）
--  - 次回スタートを強制NEWさせるフラグ s._forceNewOnNextStart = true を付与
--  - "home" は “このランを終了” として扱い、保留結果やスナップを全消去
--  - Round.resetRun() は呼ばず state を直接クリア（春スナップ生成を防止）
--  - HomeOpen は hasSave=false を必ず返す（常に New Game になる）
--  - "save" は受け取っても即 "home" に変換（保存ボタン廃止の保険）
--  - 次のステージは開発中ロックをフラグで制御（LOCAL_DEV_NEXT_LOCKED）

local RS  = game:GetService("ReplicatedStorage")

-- ===== 開発用トグル ===============================================
-- true : つねに「次のステージ」をロック（押してもHOMEに倒す）
-- false: 既存どおり「通算3回クリアで解禁」
local LOCAL_DEV_NEXT_LOCKED = true
-- ================================================================

-- Logger
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("NavServer")

local function ensureRemote(name: string)
	local rem = RS:FindFirstChild("Remotes")
	if not rem then
		rem = Instance.new("Folder")
		rem.Name = "Remotes"
		rem.Parent = RS
	end
	local e = rem:FindFirstChild(name)
	if not e then
		e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = rem
	end
	return e
end

local Remotes = {
	HomeOpen    = ensureRemote("HomeOpen"),
	DecideNext  = ensureRemote("DecideNext"),
	StageResult = ensureRemote("StageResult"), -- ★ 追加: 強制クローズ用
}

local function normLang(v:string?): string
	v = tostring(v or ""):lower()
	if v == "ja" or v == "jp" then return "ja" end
	if v == "en" then return "en" end
	return "en"
end

local NavServer = {}
NavServer.__index = NavServer

export type Deps = {
	StateHub: any,
	Round: any,
	ShopService: any?,
	SaveService: any?,
	HomeOpen: RemoteEvent?,      -- （任意）外から渡されたものを優先
	DecideNext: RemoteEvent?,    -- （任意）外から渡されたものを優先
}

function NavServer.init(deps: Deps)
	local self = setmetatable({ deps = deps or {}, _conns = {} }, NavServer)

	-- 外部から Remotes をもらえたら差し替え
	if deps.HomeOpen then Remotes.HomeOpen = deps.HomeOpen end
	if deps.DecideNext then Remotes.DecideNext = deps.DecideNext end

	-- 統一入口
	table.insert(self._conns, Remotes.DecideNext.OnServerEvent:Connect(function(plr, op)
		self:handle(plr, tostring(op or ""))
	end))

	LOG.info("ready (DecideNext unified)")
	return self
end

-- ★ “ランを終了”させるハードリセット（春スナップを新規生成しない）
local function endRunAndClean(StateHub, SaveService, plr: Player)
	local s = StateHub and StateHub.get and StateHub.get(plr)
	if not s then return end

	-- ラン関連・結果保留・遷移ロックを全て破棄
	s.phase         = "home"
	s.run           = nil
	s.shop          = nil
	s.ops           = nil
	s.options       = nil
	s.resultPending = nil
	s.stageResult   = nil
	s.decideLocks   = nil
	s.mult          = 1.0
	-- 念のため季節関連も切る（サーバ復元やUIの誤判定を防止）
	s.season        = nil
	s.round         = nil

	-- 次回開始は必ずNEW（GameInit.startGameAuto で見る）
	s._forceNewOnNextStart = true

	-- 「続き」用スナップも破棄（DataStore側）
	if SaveService and typeof(SaveService.clearActiveRun) == "function" then
		pcall(function() SaveService.clearActiveRun(plr) end)
	end

	-- クライアントの結果モーダルを明示的に閉じさせる（残存対策）
	-- Client側は {close=true} を受け取ったらモーダルを閉じる実装にしておく
	pcall(function()
		Remotes.StageResult:FireClient(plr, { close = true })
	end)

	-- クライアントへ最新 state を押し出して視覚的にも“切る”
	if StateHub and StateHub.pushState then
		pcall(function() StateHub.pushState(plr) end)
	end
end

function NavServer:handle(plr: Player, op: string)
	local StateHub    = self.deps.StateHub
	local Round       = self.deps.Round         -- 参照は残すが "home" では使わない
	local ShopService = self.deps.ShopService
	local SaveService = self.deps.SaveService

	local s = StateHub and StateHub.get and StateHub.get(plr)
	if not s then
		LOG.warn("state missing | user=%s op=%s", tostring(plr and plr.Name or "?"), tostring(op))
		return
	end

	-- 冬以外では想定外（クライアントから来ても無視）
	if (s.season or 1) ~= 4 then
		LOG.debug("DecideNext ignored (not winter) | user=%s op=%s season=%s", tostring(plr and plr.Name or "?"), tostring(op), tostring(s.season))
		return
	end

	-- 互換: "save" を送ってきてもすべて "home" として扱う（保存機能は廃止）
	if op == "save" then
		op = "home"
	end

	-- 共通初期化
	s.mult = 1.0

	-- 解禁判定（既定: 3クリアで "next" 許可）
	local clears   = tonumber(s.totalClears or 0) or 0
	local unlocked = (not LOCAL_DEV_NEXT_LOCKED) and (clears >= 3) or false

	if op ~= "home" and not unlocked then
		-- ロック中に "next" を送ってきても HOME へ倒す（改造クライアント対策）
		op = "home"
	end

	LOG.info(
		"handle | user=%s op=%s unlocked=%s clears=%d",
		tostring(plr and plr.Name or "?"), tostring(op), tostring(unlocked), clears
	)

	if op == "home" then
		-- ★ ランを終了（続き無し）→ Home
		endRunAndClean(StateHub, SaveService, plr)

		Remotes.HomeOpen:FireClient(plr, {
			hasSave = false, -- ★常に New Game
			bank    = s.bank or 0,
			year    = s.year or 0,
			clears  = s.totalClears or 0,
			lang    = normLang(SaveService and SaveService.getLang and SaveService.getLang(plr)),
		})
		LOG.info(
			"→ HOME(end-run) | user=%s hasSave=false bank=%d year=%d clears=%d",
			plr.Name, s.bank or 0, s.year or 0, s.totalClears or 0
		)
		return

	elseif op == "next" then
		-- 次の年へ（解禁済のみ到達）
		s.year = (s.year or 0) + 25
		if SaveService and typeof(SaveService.bumpYear) == "function" then
			SaveService.bumpYear(plr, 25)
		elseif SaveService and typeof(SaveService.setYear) == "function" then
			SaveService.setYear(plr, s.year)
		end
		s.phase = "shop"
		if ShopService and typeof(ShopService.open) == "function" then
			ShopService.open(plr, s, { reason = "after_winter" })
			LOG.info("→ NEXT (open shop) | user=%s newYear=%d", plr.Name, s.year or 0)
		else
			if StateHub and StateHub.pushState then StateHub.pushState(plr) end
			LOG.info("→ NEXT (push state only) | user=%s newYear=%d", plr.Name, s.year or 0)
		end
		return
	end

	LOG.warn("unknown op | user=%s op=%s", tostring(plr and plr.Name or "?"), tostring(op))
end

return NavServer
```

### src/server/RemotesInit.server.lua
```lua
-- ServerScriptService/RemotesInit.server.lua
local RS = game:GetService("ReplicatedStorage")

local function ensureFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local function ensureRE(parent, name)
	local ev = parent:FindFirstChild(name)
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = parent
	end
	return ev
end

local remotes = ensureFolder(RS, "Remotes")
ensureRE(remotes, "PlaceOnSlot")     -- C→S
ensureRE(remotes, "TalismanPlaced")  -- S→C (ACK)

print("[RemotesInit] Remotes ready →", remotes:GetFullName())
```

### src/server/SaveService.lua
```lua
-- ServerScriptService/SaveService (ModuleScript)
-- 最小DataStore：bank / year / asc / clears / lang / activeRun を永続化（version=4据え置き）
-- 使い方：
--   local SaveService = require(game.ServerScriptService.SaveService)
--   SaveService.load(player)                      -- PlayerAdded で呼ぶ（メモリに展開）
--   SaveService.addBank(player, 2)                -- 両の加算（dirty化）
--   SaveService.setYear(player, s.year)           -- 年数更新（dirty化）
--   SaveService.bumpYear(player, 25)              -- 年数を加算（例：冬クリアで +25）
--   SaveService.getAscension(player)              -- アセンション値を取得
--   SaveService.setAscension(player, 1)           -- アセンション値を設定（0以上）
--   SaveService.getBaseStartYear(player)          -- 1000 + 100*asc を返す
--   SaveService.ensureBaseYear(player)            -- 年が未設定/0なら基準年に補正
--   SaveService.getClears(player)                 -- 通算クリア回数を取得
--   SaveService.setClears(player, n)              -- 通算クリア回数を設定
--   SaveService.bumpClears(player, 1)             -- 通算クリア回数を加算
--   SaveService.getLang(player)                   -- 保存言語("ja"|"en")を取得（保存>OS）
--   SaveService.setLang(player, "ja"|"en")        -- 保存言語を設定（dirty化）
--   SaveService.mergeIntoState(player, state)     -- bank/year/asc/clears/lang を state に反映
--   -- ★ アクティブ・ラン（続き用スナップ）
--   SaveService.getActiveRun(player)              -- 現在のスナップを取得（nil可）
--   SaveService.setActiveRun(player, snap)        -- スナップを設定（dirty化）
--   SaveService.clearActiveRun(player)            -- スナップを破棄（dirty化）
--   SaveService.snapSeasonStart(player, state, n) -- 季節開始スナップ（簡易ヘルパ）
--   SaveService.snapShopEnter(player, state)      -- 屋台入場スナップ（簡易ヘルパ）
--   -- 保存
--   SaveService.flush(player)                     -- PlayerRemoving で呼ぶ（保存）
--   SaveService.flushAll()                        -- サーバ終了時の保険

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
-- SaveService.lua (先頭付近)
local RS = game:GetService("ReplicatedStorage")
-- 旧: local TalismanState = require(RS:WaitForChild("TalismanState"))
local SharedModules = RS:WaitForChild("SharedModules")
local TalismanState = require(SharedModules:WaitForChild("TalismanState"))

--=== 設定 =========================================================
local PROFILE_DS_NAME = "ProfileV1" -- 互換維持：version でのマイグレーション
local USE_MEMORY_IN_STUDIO = true   -- Studioではメモリのみで動かす（API許可が無くても動作）

--=== DataStore / Studioメモリ ====================================
local isStudio = RunService:IsStudio()
local profileDS = nil
if not (isStudio and USE_MEMORY_IN_STUDIO) then
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore(PROFILE_DS_NAME)
	end)
	if ok then
		profileDS = ds
	else
		warn("[SaveService] DataStore init failed; fallback to memory.")
	end
end

--=== キー生成 =====================================================
local function keyForUserId(userId:number): string
	return "u:" .. tostring(userId)
end

--=== 言語正規化（外部I/Fは "ja" / "en" に統一） ==================
local function normLang(s:any): string
	s = tostring(s or ""):lower()
	if s == "jp" or s == "ja" then return "ja" end
	return "en"
end

--=== デフォルト（version 4：lang / activeRun を含む） =============
local DEFAULT_PROFILE = {
	version = 4,
	bank = 0,       -- 両（永続通貨）
	year = 1000,    -- 初期年（アセンション 0 なら 1000）
	asc  = 0,       -- アセンション（0以上の整数）
	clears = 0,     -- 通算クリア回数
	lang = "en",    -- 保存言語（"ja"|"en"）
	activeRun = nil,-- ★ 続き用スナップ（{version,season,atShop,bank,mon,deckSeed,shopStock?,effects?}）
}

--=== 内部メモリ（サーバ滞在中のキャッシュ） ======================
type Profile = {
	version:number, bank:number, year:number, asc:number, clears:number,
	lang:string,
	activeRun:any?, -- ★ 追加
}
local Save = {
	_profiles = {} :: {[Player]: Profile},
	_dirty    = {} :: {[Player]: boolean},
}

--=== 補助：OSロケール→"ja"/"en" 推定 =============================
local function detectLangFromLocaleId(plr: Player?): string
	local ok, lid = pcall(function()
		return (plr and plr.LocaleId or "en-us"):lower()
	end)
	if ok and string.sub(lid,1,2) == "ja" then return "ja" end
	return "en"
end

--=== 正規化（不正値の矯正） =====================================
local function normalizeProfile(p:any): Profile
	local out:any = {}
	local v = tonumber(p and p.version) or 1
	out.version = (v < 4) and 4 or math.floor(v)

	out.bank   = math.max(0, math.floor(tonumber(p and p.bank) or 0))
	local y    = tonumber(p and p.year) or 0
	out.year   = math.floor(y)
	out.asc    = math.max(0, math.floor(tonumber(p and p.asc) or 0))
	out.clears = math.max(0, math.floor(tonumber(p and p.clears) or 0))

	local rawL = tostring(p and p.lang or ""):lower()
	out.lang = normLang(rawL) -- "jp" 既存値は "ja" に正規化

	-- ★ activeRun はテーブルなら素通し、それ以外は nil
	out.activeRun = (type(p and p.activeRun) == "table") and p.activeRun or nil

	return out :: Profile
end

--=== 補助：基準年 ================================================
local function baseStartYearForAsc(asc:number): number
	return 1000 + (math.max(0, math.floor(asc or 0)) * 100)
end

--==================================================
-- 公開API
--==================================================

-- プロフィールをロードしてメモリに展開（無ければ既定値）
function Save.load(plr: Player): Profile
	local uid = plr.UserId
	local key = keyForUserId(uid)

	local data = nil
	if profileDS then
		local ok, res = pcall(function()
			return profileDS:GetAsync(key)
		end)
		if ok then data = res else warn("[SaveService] GetAsync failed") end
	end
	-- StudioでAPI無効 or 取得失敗時は data=nil のまま（デフォルト適用）

	local prof: Profile
	if typeof(data) == "table" then
		prof = normalizeProfile(data)
	else
		prof = table.clone(DEFAULT_PROFILE) :: Profile
	end

	-- 簡易マイグレーション：
	-- - version < 4 なら 4 に引き上げ
	-- - year <= 0 の場合は、asc に応じた基準年に補正
	-- - clears 欠損は 0 補完
	-- - lang 欠損は OS ロケールから初期化（"ja"/"en"）
	-- - "jp" が残っていたら "ja" に正規化
	-- - activeRun は既存値を尊重（nil可）
	local migrated = false
	if prof.version < 4 then
		prof.version = 4
		migrated = true
	end
	if (prof.year or 0) <= 0 then
		prof.year = baseStartYearForAsc(prof.asc)
		migrated = true
	end
	if prof.clears == nil then
		prof.clears = 0
		migrated = true
	end
	if not prof.lang or (prof.lang ~= "ja" and prof.lang ~= "en") then
		prof.lang = detectLangFromLocaleId(plr)
		migrated = true
	end
	-- 旧データが "jp" だった場合に備えてもう一度正規化（上の分岐を通らない可能性に備える）
	local nlang = normLang(prof.lang)
	if nlang ~= prof.lang then
		prof.lang = nlang
		migrated = true
	end

	Save._profiles[plr] = prof
	Save._dirty[plr]    = migrated -- マイグレーションしたら保存対象に

	return prof
end

-- メモリ上のプロフィール参照（存在しなければ nil）
function Save.get(plr: Player): Profile?
	return Save._profiles[plr]
end

--=== bank =========================================================
function Save.setBank(plr: Player, newBank:number)
	local p = Save._profiles[plr]; if not p then return end
	p.bank = math.max(0, math.floor(tonumber(newBank) or 0))
	Save._dirty[plr] = true
end

function Save.addBank(plr: Player, delta:number)
	local p = Save._profiles[plr]; if not p then return end
	p.bank = math.max(0, math.floor((p.bank or 0) + (tonumber(delta) or 0)))
	Save._dirty[plr] = true
end

--=== year =========================================================
function Save.setYear(plr: Player, newYear:number)
	local p = Save._profiles[plr]; if not p then return end
	p.year = math.max(0, math.floor(tonumber(newYear) or 0))
	Save._dirty[plr] = true
end

function Save.bumpYear(plr: Player, delta:number)
	local p = Save._profiles[plr]; if not p then return end
	local cur = tonumber(p.year or 0) or 0
	p.year = math.max(0, math.floor(cur + (tonumber(delta) or 0)))
	Save._dirty[plr] = true
end

--=== ascension ====================================================
function Save.getAscension(plr: Player): number
	local p = Save._profiles[plr]; if not p then return 0 end
	return math.max(0, math.floor(tonumber(p.asc) or 0))
end

function Save.setAscension(plr: Player, n:number)
	local p = Save._profiles[plr]; if not p then return end
	p.asc = math.max(0, math.floor(tonumber(n) or 0))
	Save._dirty[plr] = true
end

--=== clears =======================================================
function Save.getClears(plr: Player): number
	local p = Save._profiles[plr]; if not p then return 0 end
	return math.max(0, math.floor(tonumber(p.clears) or 0))
end

function Save.setClears(plr: Player, n:number)
	local p = Save._profiles[plr]; if not p then return end
	p.clears = math.max(0, math.floor(tonumber(n) or 0))
	Save._dirty[plr] = true
end

function Save.bumpClears(plr: Player, delta:number)
	local p = Save._profiles[plr]; if not p then return end
	local cur = tonumber(p.clears or 0) or 0
	p.clears = math.max(0, math.floor(cur + (tonumber(delta) or 0)))
	Save._dirty[plr] = true
end

--=== lang =========================================================
function Save.getLang(plr: Player): string
	local p = Save._profiles[plr]
	if p and (p.lang == "ja" or p.lang == "en") then
		return p.lang                      -- ★保存があれば保存優先
	end
	return detectLangFromLocaleId(plr)     -- 保存が無い/不正なら OS 推定
end

function Save.setLang(plr: Player, lang:string)
	lang = normLang(lang) -- "jp" 受信時も "ja" へ正規化
	local p = Save._profiles[plr]; if not p then return end
	if p.lang ~= lang then
		p.lang = lang
		Save._dirty[plr] = true
	end
end

--=== 基準年ユーティリティ =========================================
function Save.getBaseStartYear(plr: Player): number
	local p = Save._profiles[plr]
	local asc = p and p.asc or 0
	return baseStartYearForAsc(asc)
end

function Save.ensureBaseYear(plr: Player): number
	local p = Save._profiles[plr]; if not p then return DEFAULT_PROFILE.year end
	if (p.year or 0) <= 0 then
		p.year = baseStartYearForAsc(p.asc or 0)
		Save._dirty[plr] = true
	end
	return p.year
end

--=== State へのマージ =============================================
-- UI/状態整合のため、clears は state.totalClears にも反映
function Save.mergeIntoState(plr: Player, state:any)
	local p = Save._profiles[plr]
	if not p then return state end
	state = state or {}
	state.bank        = p.bank
	state.year        = p.year
	state.asc         = p.asc
	state.clears      = p.clears
	state.totalClears = p.clears
	state.lang        = (p.lang == "ja") and "ja" or "en"

	-- ▼ 追加：アカウント側の護符解放数（無ければ2枠）を state.account に橋渡し
	state.account = state.account or {}
	state.account.talismanUnlock = state.account.talismanUnlock or { unlocked = (p.talismanUnlocked or 2) }

... (truncated)
```

### src/server/ShopEffects/init.lua
```lua
-- ServerScriptService/ShopEffects/init.lua
-- v0.9.0 効果ディスパッチ（カテゴリ別振り分け）
-- 公開I/F:
--   apply(effectId, state, ctx) -> (ok:boolean, message:string)

local M = {}

--========================
-- サブモジュールの読込（安全なpcall）
--========================
local function safeRequire(container, childName)
	local ok, mod = pcall(function()
		return require(container:WaitForChild(childName))
	end)
	if ok and type(mod) == "table" then
		return mod
	else
		warn("[ShopEffects.init] module not found or invalid:", childName, mod)
		return nil
	end
end

local Kito     = safeRequire(script, "Kito")
local Sai      = safeRequire(script, "Sai")
local Spectral = safeRequire(script, "Spectral") -- ★追加

-- 直接呼びたい場合のエクスポート
M.Kito     = Kito
M.Sai      = Sai
M.Spectral = Spectral

local function msgJa(s) return s end

--========================
-- 内部：委譲呼び出し（共通ラッパ）
--========================
local function delegate(mod, fx, effectId, state, ctx, tag)
	if not (mod and type(mod[fx]) == "function") then
		return false, msgJa(tag .. "モジュールが見つかりません")
	end
	local okCall, okRet, msgRet = pcall(function()
		return mod[fx](effectId, state, ctx)
	end)
	if not okCall then
		warn(("[ShopEffects.init] %s.apply threw: %s"):format(tag, tostring(okRet)))
		return false, msgJa(tag .. "適用中にエラーが発生しました")
	end
	return okRet == true, tostring(msgRet or "")
end

--========================
-- メインディスパッチ
--========================
function M.apply(effectId, state, ctx)
	if type(effectId) ~= "string" then
		return false, msgJa("効果IDが不正です")
	end

	-- 祈祷（kito_）
	if effectId:sub(1,5) == "kito_" then
		return delegate(Kito, "apply", effectId, state, ctx, "祈祷")
	end

	-- 祭事（sai_）
	if effectId:sub(1,4) == "sai_" then
		return delegate(Sai, "apply", effectId, state, ctx, "祭事")
	end

	-- ★ スペクタル（spectral_/spec_/互換kito_spec_）
	if effectId:sub(1,9) == "spectral_" or effectId:sub(1,5) == "spec_" or effectId:sub(1,11) == "kito_spec_" then
		return delegate(Spectral, "apply", effectId, state, ctx, "スペクタル")
	end

	return false, msgJa(("未対応の効果ID: %s"):format(effectId))
end

return M
```

### src/server/ShopEffects/Kito.lua
```lua
-- v0.9.1 祈祷：ラン構成(config)を直接更新する安全設計（寅Lvをstate.kitoへ反映）
-- I/F:
--   Kito.apply(effectId, state, ctx) -> (ok:boolean, message:string)

local RS = game:GetService("ReplicatedStorage")
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))
local CardEngine  = require(RS:WaitForChild("SharedModules"):WaitForChild("CardEngine"))

local Kito = {}

Kito.ID = {
	USHI = "kito_ushi",   -- 所持文を即時2倍（上限あり）
	TORA = "kito_tora",   -- 取り札の得点+1（恒常バフ）
	TORI = "kito_tori",   -- ランダム1枚を bright へ変換（候補無し→次季に繰越）
}

local DEFAULTS = { CAP_MON = 999999 }

local function msg(s) return s end

local function ensureBonus(state)
	state.bonus = state.bonus or {}
	return state.bonus
end

local function ensureKito(state)
	state.kito = state.kito or {}
	return state.kito
end

-- 丑：所持文2倍（プレイヤー状態のみ変更）
local function effect_ushi(state, ctx)
	local cap = (ctx and ctx.capMon) or DEFAULTS.CAP_MON
	local before = tonumber(state.mon or 0) or 0
	local after = math.min(before * 2, cap)
	state.mon = after
	return true, msg(("丑：所持文2倍（%d → %d, 上限=%d）"):format(before, after, cap))
end

-- 寅：取り札の得点+1（恒常）
-- ※ UI後方互換のため bonus.takenPointPlus も増やすが、参照の唯一真実は state.kito.tora
local function effect_tora(state, _ctx)
	-- 後方互換（旧UI/計算で利用している可能性あり）
	local b = ensureBonus(state)
	b.takenPointPlus = (b.takenPointPlus or 0) + 1

	-- 採点（Scoring）側が参照する干支レベル
	local k = ensureKito(state)
	k.tora = (tonumber(k.tora) or 0) + 1

	return true, msg(("寅：取り札の得点+1（累計+%d / Lv=%d）"):format(b.takenPointPlus, k.tora))
end

-- 酉：ラン構成の非brightを1枚brightへ
-- 候補無しなら queueBrightNext を +1（次季で消化）
local function effect_tori(state, ctx)
	-- ラン構成（48枚）をロード（無ければ初期化）
	local deck = RunDeckUtil.loadConfig(state, true) -- true=必要なら初期化
	if not deck or #deck == 0 then
		local b = ensureBonus(state)
		b.queueBrightNext = (b.queueBrightNext or 0) + 1
		return true, msg("酉：構成が空のため、次の季節開始時に1枚brightへ変換（+1スタック）")
	end

	local ok, idx = CardEngine.convertRandomNonBrightToBright(deck, ctx and ctx.rng)
	if not ok then
		local b = ensureBonus(state)
		b.queueBrightNext = (b.queueBrightNext or 0) + 1
		return true, msg("酉：対象無し。次の季節開始時に1枚brightへ変換（+1スタック）")
	end

	local label = deck[idx].name or deck[idx].code
	RunDeckUtil.saveConfig(state, deck)
	return true, msg(("酉：%s を bright に変換しました"):format(label))
end

local DISPATCH = {
	[Kito.ID.USHI] = effect_ushi,
	[Kito.ID.TORA] = effect_tora,
	[Kito.ID.TORI] = effect_tori,
}

function Kito.apply(effectId, state, ctx)
	local fn = DISPATCH[effectId]
	if not fn then
		return false, msg(("不明な祈祷ID: %s"):format(tostring(effectId)))
	end
	if typeof(state) ~= "table" then
		return false, msg("state が無効です")
	end
	local ok, message = fn(state, ctx)
	return ok == true, tostring(message or "")
end

return Kito
```

### src/server/ShopEffects/Omamori.lua
```lua
[unreadable or empty]
```

### src/server/ShopEffects/Sai.lua
```lua
-- v0.9.0 祭事：レベル管理のみ（効果数値は Scoring 側）
local RS = game:GetService("ReplicatedStorage")
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))

local Sai = {}

-- 表記揺れを festivalId に正規化
function Sai.normalize(effectId)
	if type(effectId) ~= "string" then return nil end
	-- 例: "sai_kasu", "sai_kasu_lv1", "sai_kasu_1" → "sai_kasu"
	local base = effectId:match("^(sai_%a+)")
	return base
end

local function msg(s) return s end

function Sai.apply(effectId, state, _ctx)
	if typeof(state) ~= "table" then
		return false, msg("state が無効です")
	end
	local fid = Sai.normalize(effectId)
	if not fid then
		return false, msg(("不明な祭事ID: %s"):format(tostring(effectId)))
	end
	-- Lua では +1 は不可。1 を渡す。
	local newLv = RunDeckUtil.incMatsuri(state, fid, 1)
	return true, msg(("%s Lv+1（累計Lv=%d）"):format(fid, newLv))
end

return Sai
```

### src/server/ShopEffects/Spectral.lua
```lua
-- ServerScriptService/ShopEffects/Spectral.lua
-- v0.9.0 スペクタル効果（MVP）
-- 公開I/F:
--   apply(effectId: string, state: table, ctx: {lang?: "ja"|"en"}) -> (ok:boolean, message:string)
--
-- いまは「黒天（Black Hole）」のみ実装：
--   すべての祭事（Matsuri）レベルを +1

local RS = game:GetService("ReplicatedStorage")
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))

local Spectral = {}

--========================
-- 設定：対応するeffectId
--========================
local ACCEPT_IDS = {
	["spectral_blackhole"] = true,  -- 本命
	["spec_blackhole"]     = true,  -- 略称
	["spectral_kuroten"]   = true,  -- 和名寄り
	["spec_kuroten"]       = true,
	["kito_spec_blackhole"]= true,  -- 互換（当面）
}

--========================
-- 祭事IDの定義（Scoring.luaに合わせる）
--========================
local FESTIVAL_IDS = {
	"sai_kasu",
	"sai_tanzaku",
	"sai_tane",
	"sai_akatan",
	"sai_aotan",
	"sai_inoshika",
	"sai_hanami",
	"sai_tsukimi",
	"sai_sanko",
	"sai_goko",
}

local function msgJa(s) return s end
local function msgEn(s) return s end

--========================
-- メイン
--========================
function Spectral.apply(effectId, state, ctx)
	local id = typeof(effectId) == "string" and string.lower(effectId) or nil
	if not id or not ACCEPT_IDS[id] then
		return false, msgJa(("未対応の効果ID: %s"):format(tostring(effectId)))
	end
	if typeof(state) ~= "table" then
		return false, msgJa("state が無効です")
	end

	-- 黒天：すべての祭事レベルを +1
	for _, fid in ipairs(FESTIVAL_IDS) do
		RunDeckUtil.incMatsuri(state, fid, 1)
	end

	local lang = (ctx and ctx.lang) or "ja"
	if lang == "en" then
		return true, msgEn("Black Hole: All festivals +1")
	else
		return true, msgJa("黒天：すべての祭事を +1")
	end
end

return Spectral
```

### src/server/TalismanService.server.lua
```lua
-- ServerScriptService/TalismanService.server.lua
-- v0.9.7-P2a  Talisman server bridge（正本：サーバのみが更新）
--  - C->S: PlaceOnSlot(index:number, talismanId:string)
--  - S->C: TalismanPlaced({ unlocked:number, slots:{string?} })
--  - 正本: state.run.talisman を RunDeckUtil.ensureTalisman で必ず用意し、唯一ここで更新
--  - 他モジュール用API: TalismanService.ensureFor(player, reason?) を公開（起動/入店時などから呼ぶ）
--  - Remotes が無い場合は ReplicatedStorage.Remotes に生成

local RS        = game:GetService("ReplicatedStorage")
local Players   = game:GetService("Players")

-- ===== Logger =====================================================
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("TalismanService")

-- ===== Dependencies ==============================================
local SharedModules = RS:WaitForChild("SharedModules")
local StateHub      = require(SharedModules:WaitForChild("StateHub"))
local RunDeckUtil   = require(SharedModules:WaitForChild("RunDeckUtil"))

-- ===== Remotes folder / events ===================================
local RemotesFolder = RS:FindFirstChild("Remotes") or (function()
  local f = Instance.new("Folder")
  f.Name = "Remotes"
  f.Parent = RS
  return f
end)()

local function ensureRemote(name: string): RemoteEvent
  local ex = RemotesFolder:FindFirstChild(name)
  if ex and ex:IsA("RemoteEvent") then return ex end
  local e = Instance.new("RemoteEvent")
  e.Name = name
  e.Parent = RemotesFolder
  return e
end

local PlaceOnSlotRE    = ensureRemote("PlaceOnSlot")     -- C->S
local TalismanPlacedRE = ensureRemote("TalismanPlaced")  -- S->C (ACK)

-- ===== Defaults / helpers ========================================

local DEFAULT_MAX     = 6
local DEFAULT_UNLOCK  = 2

local function toInt(n:any, def:number)
  local v = tonumber(n)
  if not v then return def end
  return math.floor(v)
end

local function clone6(src:{any}?): {any}
  local s = src or {}
  return { s[1], s[2], s[3], s[4], s[5], s[6] }
end

-- RunDeckUtil を使って正本を必ず用意
local function ensureBoardOnState(s:any)
  -- ensureTalisman は「不足キーを補うだけ」で既存値は壊さない前提
  local b = RunDeckUtil.ensureTalisman(s, { minUnlocked = DEFAULT_UNLOCK, maxSlots = DEFAULT_MAX })
  -- 念のため型ガード
  if typeof(b) ~= "table" then
    -- フォールバック：極小限の形
    s.run = s.run or {}
    s.run.talisman = {
      maxSlots = DEFAULT_MAX,
      unlocked = DEFAULT_UNLOCK,
      slots    = { nil, nil, nil, nil, nil, nil },
    }
    b = s.run.talisman
  end
  -- 丸め（max/unlocked/slots）
  b.maxSlots = toInt(b.maxSlots, DEFAULT_MAX)
  b.unlocked = math.max(0, math.min(b.maxSlots, toInt(b.unlocked, DEFAULT_UNLOCK)))
  if typeof(b.slots) ~= "table" then
    b.slots = { nil, nil, nil, nil, nil, nil }
  else
    b.slots = clone6(b.slots)
  end
  return b
end

local function isIndexPlaceable(b:any, idx:number)
  if typeof(b) ~= "table" or typeof(idx) ~= "number" then return false end
  if idx < 1 then return false end
  local max = toInt(b.maxSlots, DEFAULT_MAX)
  local unl = toInt(b.unlocked , DEFAULT_UNLOCK)
  if idx > max or idx > unl then return false end
  return true
end

-- ===== Public API (他サービスから呼べる) =========================
local Service = {}

-- 起動/新規ラン開始/ショップ入店前などで呼ぶ想定
function Service.ensureFor(plr: Player, reason: string?)
  local s = StateHub.get(plr)
  if not s then
    LOG.debug("ensureFor skipped (no state yet) | user=%s reason=%s", plr and plr.Name or "?", tostring(reason or ""))
    return
  end
  local b = ensureBoardOnState(s)
  LOG.debug("ensureFor | user=%s unlocked=%d max=%d reason=%s", plr.Name, toInt(b.unlocked,0), toInt(b.maxSlots,0), tostring(reason or ""))
end

-- ===== Server wiring =============================================

-- PlaceOnSlot: 唯一の“確定”経路。ここでのみ正本を更新する
PlaceOnSlotRE.OnServerEvent:Connect(function(plr: Player, idx:any, talismanId:any)
  local s = StateHub.get(plr)
  if not s then
    LOG.warn("ignored: no state | user=%s", plr and plr.Name or "?")
    return
  end

  -- 正本を必ず用意（不足キーだけ補う）
  local board = ensureBoardOnState(s)

  local index = toInt(idx, -1)
  local id    = tostring(talismanId or "")
  if id == "" then
    LOG.warn("ignored: invalid id | user=%s idx=%s id=%s", plr.Name, tostring(idx), tostring(talismanId))
    -- 現状をACKしてクライアントのプレビューを解消
    if TalismanPlacedRE then
      TalismanPlacedRE:FireClient(plr, { unlocked = board.unlocked, slots = clone6(board.slots) })
    end
    return
  end

  if not isIndexPlaceable(board, index) then
    LOG.info("rejected: out-of-range | user=%s idx=%d unlocked=%s max=%s",
      plr.Name, index, tostring(board.unlocked), tostring(board.maxSlots))
    if TalismanPlacedRE then
      TalismanPlacedRE:FireClient(plr, { unlocked = board.unlocked, slots = clone6(board.slots) })
    end
    return
  end

  -- 既に埋まっていたら上書きしない（クライアント側は空スロットにしか送らない想定）
  if board.slots[index] ~= nil then
    LOG.info("noop: slot already filled | user=%s idx=%d id(existing)=%s",
      plr.Name, index, tostring(board.slots[index]))
    if TalismanPlacedRE then
      TalismanPlacedRE:FireClient(plr, { unlocked = board.unlocked, slots = clone6(board.slots) })
    end
    return
  end

  -- ===== 正本を更新（唯一の更新点） =====
  board.slots[index] = id
  LOG.info("placed | user=%s idx=%d id=%s unlocked=%d", plr.Name, index, id, toInt(board.unlocked, DEFAULT_UNLOCK))

  -- ACK: 最新の board 断面
  if TalismanPlacedRE then
    TalismanPlacedRE:FireClient(plr, { unlocked = board.unlocked, slots = clone6(board.slots) })
  end

  -- 状態を即時にクライアントへ（RunScreen/ShopScreen は st.run.talisman を参照）
  local okPush, err = pcall(function() StateHub.pushState(plr) end)
  if not okPush then
    LOG.warn("StateHub.pushState failed: %s", tostring(err))
  end
end)

-- 起動時の軽い保険：プロフィール/state が載り次第 ensure
Players.PlayerAdded:Connect(function(plr: Player)
  -- StateHub.get が準備できるまで少しだけ待つ（最大 ~3秒 / 6回）
  task.defer(function()
    for i=1,6 do
      local s = StateHub.get(plr)
      if s then
        Service.ensureFor(plr, "PlayerAdded")
        return
      end
      task.wait(0.5)
    end
    LOG.debug("PlayerAdded ensure skipped (no state by timeout) | user=%s", plr.Name)
  end)
end)

LOG.info("ready (PlaceOnSlot/TalismanPlaced wired)")

return Service
```

### src/server/UiResync.server.lua
```lua
-- ServerScriptService/UiResync.server.lua
-- 画面を開いた直後などに、手札/場/取り札/状態/得点をまとめて再送する（安全化版）
-- 改善点:
--  1) 結果表示中 (s.phase=="result") は余計な再送を避ける
--  2) 連打/重複のデバウンス (同一プレイヤー 0.3s 以内は捨てる)
--  3) null/型の安全化（落ちないようにデフォルト値を用意）
--  4) P1-3: Logger 導入（print/warn を LOG.* に置換）

local RS = game:GetService("ReplicatedStorage")

-- Logger
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("UiResync")

-- Remotes フォルダ
local RemotesFolder = RS:FindFirstChild("Remotes") or (function()
	local f = Instance.new("Folder")
	f.Name = "Remotes"
	f.Parent = RS
	return f
end)()

local function ensureRemote(name: string)
	return RemotesFolder:FindFirstChild(name) or (function()
		local e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = RemotesFolder
		return e
	end)()
end

-- Remotes
local ReqSyncUI  = ensureRemote("ReqSyncUI")  -- C->S: 全UI再送要求
local HandPush   = ensureRemote("HandPush")
local FieldPush  = ensureRemote("FieldPush")
local TakenPush  = ensureRemote("TakenPush")
local ScorePush  = ensureRemote("ScorePush")
-- StatePush は自前で送らず、StateHub.pushState(plr) に任せる

-- 状態/採点
local StateHub = require(RS.SharedModules.StateHub)
local Scoring  = require(RS.SharedModules.Scoring)

--==================================================
-- 内部ユーティリティ
--==================================================

-- 準備できたかどうかの判定（季節が進んだ直後は数フレーム待つことがある）
local function isReadyState(s)
	if not s then return false end
	-- どれかが成立していれば「準備OK」
	if (s.target or 0) > 0 then return true end
	if s.board and #s.board > 0 then return true end
	if s.hand  and #s.hand  > 0 then return true end
	return false
end

-- 直近の再同期要求の時刻（プレイヤー毎）
local _lastSyncAt : {[Player]: number} = {}
local DEBOUNCE_SEC = 0.3

-- 安全に再採点（nilでも落ちない）
local function safeEvaluate(taken:any)
	local ok, total, roles, detail = pcall(function()
		local t, r, d = Scoring.evaluate(taken or {})
		return t or 0, r or {}, d or {mon=0, pts=0}
	end)
	if ok then
		return total, roles, detail
	else
		LOG.warn("Scoring.evaluate failed; fallback to zeros")
		return 0, {}, {mon=0, pts=0}
	end
end

--==================================================
-- 本体
--==================================================
ReqSyncUI.OnServerEvent:Connect(function(plr)
	-- デバウンス（連打・重複抑制）
	local now = os.clock()
	local prev = _lastSyncAt[plr]
	if prev and (now - prev) < DEBOUNCE_SEC then
		-- 近すぎる要求は無視（必要ならデバッグログ）
		-- LOG.debug("debounced | user=%s dt=%.2f", plr.Name, now - prev)
		return
	end
	_lastSyncAt[plr] = now

	-- 状態取得
	local s = StateHub.get(plr)
	if not s then return end

	LOG.info(
		"lens | user=%s deck=%d hand=%d board=%d taken=%d phase=%s",
		plr.Name, #(s.deck or {}), #(s.hand or {}), #(s.board or {}), #(s.taken or {}), tostring(s.phase)
	)

	-- 結果表示中は余計な再送を避ける（State だけ押し直したい場合は pushState を残す）
	if s.phase == "result" then
		-- 結果モーダル中に UI を書き換えると見た目がチラつくため抑制
		-- 必要なら StateHub.pushState(plr) を有効化
		-- StateHub.pushState(plr)
		return
	end

	-- ラウンド準備完了を軽く待機（最大 ~0.5s 程度）
	local tries = 0
	while not isReadyState(s) and tries < 30 do
		tries += 1
		task.wait(0.016) -- 1~2フレーム
		s = StateHub.get(plr)
		if not s then return end
	end

	-- 手札/場/取り札を再送
	HandPush:FireClient(plr, s.hand or {})
	FieldPush:FireClient(plr, s.board or {})
	TakenPush:FireClient(plr, s.taken or {})

	-- 得点は「現在の取り札」で再採点（季節跨ぎの残留を避ける）
	local total, roles, detail = safeEvaluate(s.taken)
	LOG.debug("ScorePush types: %s %s %s", typeof(total), typeof(roles), typeof(detail))
	ScorePush:FireClient(plr, total, roles, detail)

	-- ★ 状態は StateHub 側の正規ルートで送る（target/hands/rerolls/deckLeft などが埋まる）
	StateHub.pushState(plr)
end)
```

### src/shared/CardEngine.lua
```lua
-- SharedModules/CardEngine.lua
-- v0.9.1 カードエンジン：48枚定義（1103 を ribbon に修正）
local M = {}

-- 48枚の定義
M.cardsByMonth = {
	[1]  = { {kind="bright", name="松に鶴", tags={"animal","crane"}}, {kind="ribbon", name="赤短(字あり)", tags={"aka","jiari"}}, {kind="chaff"}, {kind="chaff"} },
	[2]  = { {kind="seed",   name="鶯", tags={"animal"}},            {kind="ribbon", name="赤短(字あり)", tags={"aka","jiari"}}, {kind="chaff"}, {kind="chaff"} },
	[3]  = { {kind="bright", name="桜に幕"},                          {kind="ribbon", name="赤短(字あり)", tags={"aka","jiari"}}, {kind="chaff"}, {kind="chaff"} },
	[4]  = { {kind="seed",   name="ホトトギス", tags={"animal"}},    {kind="ribbon", name="赤短(無地)",  tags={"aka"}},          {kind="chaff"}, {kind="chaff"} },
	[5]  = { {kind="seed",   name="八つ橋", tags={"thing"}},         {kind="ribbon", name="赤短(無地)",  tags={"aka"}},          {kind="chaff"}, {kind="chaff"} },
	[6]  = { {kind="seed",   name="蝶", tags={"animal"}},            {kind="ribbon", name="青短(字あり)", tags={"ao","jiari"}},  {kind="chaff"}, {kind="chaff"} },
	[7]  = { {kind="seed",   name="猪", tags={"animal"}},            {kind="ribbon", name="赤短(無地)",  tags={"aka"}},          {kind="chaff"}, {kind="chaff"} },
	[8]  = { {kind="bright", name="芒に月"},                          {kind="seed",   name="雁", tags={"animal"}},                {kind="chaff"}, {kind="chaff"} },
	[9]  = { {kind="seed",   name="盃", tags={"thing","sake"}},       {kind="ribbon", name="青短(字あり)", tags={"ao","jiari"}},  {kind="chaff"}, {kind="chaff"} },
	[10] = { {kind="seed",   name="鹿", tags={"animal"}},            {kind="ribbon", name="青短(字あり)", tags={"ao","jiari"}},  {kind="chaff"}, {kind="chaff"} },
	[11] = { {kind="bright", name="柳に雨", tags={"rain"}},          {kind="seed",   name="燕", tags={"animal"}},                {kind="ribbon", name="短冊(無地)"}, {kind="chaff"} }, -- ★ 1103 を ribbon に
	[12] = { {kind="bright", name="桐に鳳凰", tags={"animal","phoenix"}}, {kind="chaff"}, {kind="chaff"}, {kind="chaff"} },
}

-- ===== 基本操作 =====
function M.toCode(month, idx) return string.format("%02d%02d", month, idx) end
function M.fromCode(code) return tonumber(code:sub(1,2)), tonumber(code:sub(3,4)) end

-- 初期48枚
function M.buildDeck()
	local deck = {}
	for m=1,12 do
		for i,c in ipairs(M.cardsByMonth[m]) do
			table.insert(deck, {
				month=m, idx=i, kind=c.kind, name=c.name, tags=c.tags and table.clone(c.tags) or nil,
				code = M.toCode(m,i),
			})
		end
	end
	return deck
end

-- シャッフル
function M.shuffle(deck, seed)
	local rng = seed and Random.new(seed) or Random.new()
	for i = #deck, 2, -1 do
		local j = rng:NextInteger(1, i)
		deck[i], deck[j] = deck[j], deck[i]
	end
end

-- n枚引き（末尾から）
function M.draw(deck, n)
	local hand = {}
	for i=1,n do hand[i] = table.remove(deck) end
	return hand
end

-- ===== スナップショット（唯一の正本：v2 entries） =====
function M.buildSnapshot(deck)
	local codes, hist, entries = {}, {}, {}
	for _, c in ipairs(deck or {}) do
		local code = c.code or M.toCode(c.month, c.idx)
		table.insert(codes, code)
		hist[code] = (hist[code] or 0) + 1
		table.insert(entries, { code = code, kind = c.kind })
	end
	return { v=2, count=#codes, codes=codes, histogram=hist, entries=entries }
end

function M.buildDeckFromSnapshot(snap)
	if typeof(snap) ~= "table" then return {} end
	if typeof(snap.entries) == "table" and #snap.entries > 0 then
		local out = {}
		for _, e in ipairs(snap.entries) do
			local m,i = M.fromCode(tostring(e.code))
			local defM = M.cardsByMonth[m]
			local def  = defM and defM[i]
			if def then
				table.insert(out, {
					month=m, idx=i, kind=e.kind or def.kind, name=def.name,
					tags=def.tags and table.clone(def.tags) or nil, code=M.toCode(m,i),
				})
			end
		end
		return out
	end
	-- v1 後方互換
	local out = {}
	for _, code in ipairs(snap.codes or {}) do
		local m,i = M.fromCode(tostring(code))
		local defM = M.cardsByMonth[m]
		local def  = defM and defM[i]
		if def then
			table.insert(out, {
				month=m, idx=i, kind=def.kind, name=def.name,
				tags=def.tags and table.clone(def.tags) or nil, code=M.toCode(m,i),
			})
		end
	end
	return out
end

-- ===== デッキ変換ユーティリティ =====
local function isNonBright(card) return card and card.kind ~= "bright" end

function M.pickRandomIndex(deck, predicate, rng)
	local idxs = {}
	for i,c in ipairs(deck) do if predicate(c) then table.insert(idxs,i) end end
	if #idxs == 0 then return nil end
	local r = rng and rng:NextInteger(1, #idxs) or math.random(1, #idxs)
	return idxs[r]
end

function M.convertRandomNonBrightToBright(deck, rng)
	local idx = M.pickRandomIndex(deck, isNonBright, rng)
	if not idx then return false, nil end
	deck[idx].kind = "bright"
	return true, idx
end

return M
```

### src/shared/CardImageMap.lua
```lua
-- CardImageMap.lua
-- 花札カードコード "MMKK" → 画像アセットID を返す

local M = {}

local MAP = {
    ["0101"] = "rbxassetid://110167745897883",
    ["0102"] = "rbxassetid://93498789800334",
    ["0103"] = "rbxassetid://133103780529932",
    ["0104"] = "rbxassetid://136642428171395",
    ["0201"] = "rbxassetid://132367699583326",
    ["0202"] = "rbxassetid://134345351537648",
    ["0203"] = "rbxassetid://135460725123644",
    ["0204"] = "rbxassetid://89684082664904",
    ["0301"] = "rbxassetid://73087713183501",
    ["0302"] = "rbxassetid://81006823565341",
    ["0303"] = "rbxassetid://77095165720075",
    ["0304"] = "rbxassetid://85687753998090",
    ["0401"] = "rbxassetid://101221945021316",
    ["0402"] = "rbxassetid://77347428563752",
    ["0403"] = "rbxassetid://127837226730063",
    ["0404"] = "rbxassetid://79125904590127",
    ["0501"] = "rbxassetid://87645273830323",
    ["0502"] = "rbxassetid://94073795568801",
    ["0503"] = "rbxassetid://124341314863776",
    ["0504"] = "rbxassetid://132896106155044",
    ["0601"] = "rbxassetid://132616480451100",
    ["0602"] = "rbxassetid://124641940516424",
    ["0603"] = "rbxassetid://79357236000602",
    ["0604"] = "rbxassetid://135731147846223",
    ["0701"] = "rbxassetid://132491564698284",
    ["0702"] = "rbxassetid://91828122936676",
    ["0703"] = "rbxassetid://86256620341158",
    ["0704"] = "rbxassetid://82894930779013",
    ["0801"] = "rbxassetid://87397718241868",
    ["0802"] = "rbxassetid://128009125288955",
    ["0803"] = "rbxassetid://131676198229808",
    ["0804"] = "rbxassetid://87762677221025",
    ["0901"] = "rbxassetid://88046091737846",
    ["0902"] = "rbxassetid://71524569266527",
    ["0903"] = "rbxassetid://83957385030032",
    ["0904"] = "rbxassetid://128219000509304",
    ["1001"] = "rbxassetid://74033195147455",
    ["1002"] = "rbxassetid://73399886152412",
    ["1003"] = "rbxassetid://88813065287954",
    ["1004"] = "rbxassetid://110394629504663",
    ["1101"] = "rbxassetid://84968179943715",
    ["1102"] = "rbxassetid://71616531834256",
    ["1103"] = "rbxassetid://86303293761445",
    ["1104"] = "rbxassetid://119930258214285",
    ["1201"] = "rbxassetid://127632446804292",
    ["1202"] = "rbxassetid://103521315547130",
    ["1203"] = "rbxassetid://123439248481137",
    ["1204"] = "rbxassetid://119065326867849",
}

function M.get(code)
    return MAP[code]
end

function M.getByMonthIdx(month, idx)
    return MAP[string.format("%02d%02d", month, idx)]
end

return M
```

### src/shared/LocaleUtil.lua
```lua
-- LocaleUtil.lua (client/shared)
local RS = game:GetService("ReplicatedStorage")
local Locale = require(RS:WaitForChild("Config"):WaitForChild("Locale"))

local M = {}

function M.norm(v:string?)
	v = tostring(v or ""):lower()
	if v=="ja" or v=="en" then return v end
	if v=="jp" then return "ja" end
	return nil
end

function M.safeGlobal()
	if typeof(Locale.getGlobal)=="function" then
		local ok, val = pcall(Locale.getGlobal)
		if ok then return M.norm(val) end
	end
	return nil
end

function M.pickInitial()
	return M.safeGlobal()
	    or (type(Locale.pick)=="function" and (M.norm(Locale.pick()) or "en"))
	    or "en"
end

return M
```

### src/shared/Logger.lua
```lua
-- SharedModules/Logger.lua
-- 使い方:
--   local RS = game:GetService("ReplicatedStorage")
--   local Logger = require(RS.SharedModules.Logger)
--   local LOG = Logger.scope("RunScreen")  -- タグ＝出所名
--   LOG.debug("boot %s", tostring(version))
--
-- 公開ビルドで抑止: どこかのブートで
--   Logger.configure({ level = Logger.WARN })  -- または Logger.ERROR

local RunService   = game:GetService("RunService")
local HttpService  = game:GetService("HttpService")

local Logger = {}
Logger.DEBUG = 10
Logger.INFO  = 20
Logger.WARN  = 30
Logger.ERROR = 40
Logger.NONE  = 99

local state = {
	level = RunService:IsStudio() and Logger.DEBUG or Logger.WARN, -- Studioは詳しめ、公開は控えめ
	timePrefix = true,
	throwOnError = false,       -- ERRORで error() したいなら true
	enabledTags = nil,          -- nil=全許可 / set型 {"NAV"=true, ...}
	disabledTags = {},          -- set型
	dupWindowSec = 0.75,        -- 同一メッセージの抑制ウィンドウ（秒）
	_last = {},                 -- [key]=lastTime
	sink = nil,                 -- カスタム出力先 (function(level, line))
}

local LVL_NAME = {
	[Logger.DEBUG] = "D",
	[Logger.INFO]  = "I",
	[Logger.WARN]  = "W",
	[Logger.ERROR] = "E",
}

local function nowMs()
	return os.clock()
end

local function safeJson(v)
	local ok, s = pcall(function()
		-- Instance を避けて簡易シリアライズ
		local function scrub(x, depth)
			depth = depth or 0
			if depth > 3 then return "<depth-limit>" end
			if typeof(x) == "Instance" then
				return ("<Instance:%s:%s>"):format(x.ClassName, x.Name)
			elseif typeof(x) == "table" then
				local t = {}
				local i = 0
				for k, vv in pairs(x) do
					i += 1
					if i > 32 then t["<truncated>"] = true; break end
					t[tostring(k)] = scrub(vv, depth + 1)
				end
				return t
			else
				return x
			end
		end
		return HttpService:JSONEncode(scrub(v))
	end)
	if ok then return s end
	return tostring(v)
end

local function fmt(msg, ...)
	if select("#", ...) == 0 then
		return tostring(msg)
	end
	-- string.format が失敗するケース（%記号流入）に強い
	local ok, out = pcall(string.format, tostring(msg), ...)
	if ok then return out end
	-- フォーマット不可なら素朴に連結
	local parts = { tostring(msg) }
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		table.insert(parts, (typeof(v) == "table") and safeJson(v) or tostring(v))
	end
	return table.concat(parts, " | ")
end

local function shouldLog(tag, level)
	if level < state.level then return false end
	if state.enabledTags then
		if not state.enabledTags[tag] then return false end
	end
	if state.disabledTags and state.disabledTags[tag] then return false end
	return true
end

local function sideLetter()
	if RunService:IsServer() then return "S" end
	if RunService:IsClient() then return "C" end
	return "-"
end

local function output(level, tag, text)
	local prefixT = ""
	if state.timePrefix then
		-- hh:mm:ss（ざっくり）
		local t = os.time() % 86400
		local h = math.floor(t/3600)
		local m = math.floor((t%3600)/60)
		local s = t%60
		prefixT = string.format("%02d:%02d:%02d ", h, m, s)
	end
	local line = string.format("[%s]%s[%s][%s] %s",
		LVL_NAME[level] or "?", prefixT, sideLetter(), tag, text)

	if state.sink then
		local ok = pcall(state.sink, level, line)
		if ok then return end
	end

	if level >= Logger.WARN then
		warn(line)
	else
		print(line)
	end

	if level >= Logger.ERROR and state.throwOnError then
		error(line)
	end
end

local function dupKey(level, tag, text)
	return string.format("%d|%s|%s", level, tag, text)
end

local function log(level, tag, msg, ...)
	if not shouldLog(tag, level) then return end
	local text = fmt(msg, ...)
	-- 連打抑制
	local key = dupKey(level, tag, text)
	local t = nowMs()
	local last = state._last[key]
	if last and (t - last) < state.dupWindowSec then
		return
	end
	state._last[key] = t
	output(level, tag, text)
end

-- ========= Public API =========

function Logger.configure(opts)
	if typeof(opts) ~= "table" then return end
	if opts.level ~= nil then state.level = opts.level end
	if opts.timePrefix ~= nil then state.timePrefix = opts.timePrefix end
	if opts.throwOnError ~= nil then state.throwOnError = opts.throwOnError end
	if opts.dupWindowSec ~= nil then state.dupWindowSec = opts.dupWindowSec end
	if opts.sink ~= nil then state.sink = opts.sink end

	if opts.enableTags then
		local set = {}
		for _, t in ipairs(opts.enableTags) do set[t] = true end
		state.enabledTags = set
	end
	if opts.disableTags then
		for _, t in ipairs(opts.disableTags) do state.disabledTags[t] = true end
	end
end

function Logger.setLevel(lvl) state.level = lvl end
function Logger.getLevel() return state.level end

-- タグ別ロガー（推奨）
function Logger.scope(tag)  -- ← 予約語回避（旧: Logger.for）
	tag = tostring(tag or "APP")
	local proxy = {}
	function proxy.debug(msg, ...) log(Logger.DEBUG, tag, msg, ...) end
	function proxy.info (msg, ...) log(Logger.INFO , tag, msg, ...) end
	function proxy.warn (msg, ...) log(Logger.WARN , tag, msg, ...) end
	function proxy.error(msg, ...) log(Logger.ERROR, tag, msg, ...) end
	-- printf 風エイリアス
	function proxy.debugf(...) proxy.debug(...) end
	function proxy.infof (...) proxy.info (...) end
	function proxy.warnf (...) proxy.warn (...) end
	function proxy.errorf(...) proxy.error(...) end
	return proxy
end
Logger.forTag = Logger.scope   -- 互換用の別名

-- グローバル呼び出し（あまり推奨しない）
local ROOT = Logger.scope("APP")
function Logger.debug(...) ROOT.debug(...) end
function Logger.info (...) ROOT.info (...) end
function Logger.warn (...) ROOT.warn (...) end
function Logger.error(...) ROOT.error(...) end

return Logger
```

### src/shared/Modifiers.lua
```lua
local M = {}
-- TODO: 祭事（十干）・お守り効果（加点/倍率）
return M
```

### src/shared/NavClient.lua
```lua
-- ReplicatedStorage/SharedModules/NavClient.lua
-- v0.9.3 Nav ラッパ：UI は Nav:next("home"|"next"|"save") だけ呼ぶ

local M = {}
M.__index = M

-- legacy = { GoHome: RemoteEvent?, GoNext: RemoteEvent?, SaveQuit: RemoteEvent? }
function M.new(decideNext, legacy)
	local self = setmetatable({}, M)
	self.DecideNext = decideNext
	self.legacy = legacy or {}
	return self
end

function M:next(op)
	-- ロガー整備前の暫定：DoD用ログ
	print("NAV: next " .. tostring(op))

	-- 正準
	if self.DecideNext and typeof(self.DecideNext.FireServer) == "function" then
		self.DecideNext:FireServer(op)
		return
	end

	-- レガシー互換（段階的廃止）
	local lg = self.legacy or {}
	if op == "home" and lg.GoHome then lg.GoHome:FireServer(); return end
	if op == "next" and lg.GoNext then lg.GoNext:FireServer(); return end
	if op == "save" and lg.SaveQuit then lg.SaveQuit:FireServer(); return end

	warn("[NavClient] No route for op=", op)
end

return M
```

### src/shared/PickService.lua
```lua
-- ReplicatedStorage/SharedModules/PickService.lua
local RS = game:GetService("ReplicatedStorage")
local StateHub = require(RS.SharedModules.StateHub)

local Pick = {}

local function countSameMonth(list, month)
	local idxs = {}
	for i,card in ipairs(list) do if card.month == month then table.insert(idxs, i) end end
	return idxs
end

local function sweepFourOnBoard(s)
	local seen = {}
	for i,card in ipairs(s.board) do
		local m = card.month; seen[m] = seen[m] or {}; table.insert(seen[m], i)
	end
	for _,idxs in pairs(seen) do
		if #idxs >= 4 then
			table.sort(idxs, function(a,b) return a>b end)
			for _,bi in ipairs(idxs) do
				table.insert(s.dump, table.remove(s.board, bi))
			end
		end
	end
end

local function takeFromBoardByMonth(s, month, howMany)
	local takenCount = 0
	for i = #s.board, 1, -1 do
		if s.board[i].month == month then
			table.insert(s.taken, table.remove(s.board, i))
			takenCount += 1
			if howMany and takenCount >= howMany then break end
		end
	end
	return takenCount
end

local function drawOneFromDeck(s)
	if #s.deck <= 0 then return nil end
	local c = table.remove(s.deck)
	table.insert(s.board, c)
	return c
end

function Pick.bind(Remotes)
	Remotes.ReqPick.OnServerEvent:Connect(function(plr: Player, handIdx: number, boardIdx: number?)
		local s = StateHub.get(plr); if not s or s.phase~="play" then return end
		if not handIdx or not s.hand[handIdx] then return end

		local playCard = table.remove(s.hand, handIdx)

		local idxsOnBoard = countSameMonth(s.board, playCard.month)
		if #idxsOnBoard == 3 then
			table.insert(s.taken, playCard)
			takeFromBoardByMonth(s, playCard.month, 3)
		else
			if #idxsOnBoard >= 1 then
				local matched = false
				if boardIdx and s.board[boardIdx] and s.board[boardIdx].month == playCard.month then
					table.insert(s.taken, playCard)
					table.insert(s.taken, table.remove(s.board, boardIdx))
					matched = true
				end
				if not matched then
					table.insert(s.taken, playCard)
					takeFromBoardByMonth(s, playCard.month, 1)
				end
			else
				table.insert(s.board, playCard)
			end
		end
		sweepFourOnBoard(s)

		local flip = drawOneFromDeck(s)
		if flip then
			local idxs2 = countSameMonth(s.board, flip.month)
			if #idxs2 >= 2 then
				local takenOne = false
				for i = #s.board, 1, -1 do
					if s.board[i].month == flip.month and s.board[i] ~= flip then
						table.insert(s.taken, table.remove(s.board, i))
						takenOne = true; break
					end
				end
				for i = #s.board, 1, -1 do
					if s.board[i] == flip then
						table.insert(s.taken, table.remove(s.board, i))
						break
					end
				end
			end
			sweepFourOnBoard(s)
		end

		StateHub.pushState(plr)
	end)
end

return Pick
```

### src/shared/RerollService.lua
```lua
-- ReplicatedStorage/SharedModules/RerollService.lua
local RS = game:GetService("ReplicatedStorage")
local CardEngine = require(RS.SharedModules.CardEngine)
local StateHub   = require(RS.SharedModules.StateHub)

local Reroll = {}

local function shuffleDeck(deck) CardEngine.shuffle(deck, os.time()) end
local function rebuildDeckWith(parts)
	local deck = {}
	local function push(list) if list then for i=1,#list do table.insert(deck, list[i]) end end end
	push(parts.deck); push(parts.hand); push(parts.board); push(parts.dump)
	return deck
end

local function doRerollAll(s)
	local newDeck = rebuildDeckWith({ deck=s.deck, hand=s.hand, board=s.board, dump=s.dump })
	s.hand, s.board, s.dump = {}, {}, {}
	shuffleDeck(newDeck)
	for i=1,5 do if #newDeck>0 then table.insert(s.hand,  table.remove(newDeck)) end end
	for i=1,8 do if #newDeck>0 then table.insert(s.board, table.remove(newDeck)) end end
	s.deck = newDeck
end

local function doRerollHand(s)
	local newDeck = rebuildDeckWith({ deck=s.deck, hand=s.hand })
	s.hand = {}
	shuffleDeck(newDeck)
	for i=1,5 do if #newDeck>0 then table.insert(s.hand, table.remove(newDeck)) end end
	s.deck = newDeck
end

function Reroll.bind(Remotes, sweepFourOnBoardFn) -- sweepはPickServiceの同等処理を使うなら渡さなくてもOK
	Remotes.ReqRerollAll.OnServerEvent:Connect(function(plr)
		local s = StateHub.get(plr); if not s or s.phase~="play" then return end
		if s.rerollsLeft <= 0 then return end
		doRerollAll(s); s.rerollsLeft -= 1
		if sweepFourOnBoardFn then sweepFourOnBoardFn(s) end
		StateHub.pushState(plr)
	end)
	Remotes.ReqRerollHand.OnServerEvent:Connect(function(plr)
		local s = StateHub.get(plr); if not s or s.phase~="play" then return end
		if s.rerollsLeft <= 0 then return end
		doRerollHand(s); s.rerollsLeft -= 1
		if sweepFourOnBoardFn then sweepFourOnBoardFn(s) end
		StateHub.pushState(plr)
	end)
end

return Reroll
```

### src/shared/RoundService.lua
```lua
-- v0.9.1 季節開始ロジック（configSnapshot → 当季デッキ → ★季節開始スナップ保存）
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

local CardEngine   = require(RS.SharedModules.CardEngine)
local StateHub     = require(RS.SharedModules.StateHub)
local RunDeckUtil  = require(RS.SharedModules.RunDeckUtil)

-- ★ SaveService（サーバ専用：失敗してもゲームは継続）
local SaveService do
	local ok, mod = pcall(function() return require(SSS:WaitForChild("SaveService")) end)
	if ok then SaveService = mod else
		warn("[RoundService] SaveService not available; season snapshots will be skipped.")
		SaveService = nil
	end
end

local Round = {}

local MAX_HANDS   = 3
local MAX_REROLLS = 5

local function makeSeasonSeed(seasonNum: number?)
	local guid = HttpService:GenerateGUID(false)
	local mixed = string.format("%s-%s-%.6f", guid, tostring(seasonNum or 0), os.clock())
	local num = tonumber((mixed:gsub("%D","")):sub(1,9)) or math.random(1, 10^9)
	return num
end

-- 次季に繰り越された bright 変換スタックを消化（ラン構成に反映）
local function consumeQueuedConversions(state, rng)
	local bonus = state.bonus
	local n = tonumber(bonus and bonus.queueBrightNext or 0) or 0
	if n <= 0 then return end
	local cfg = RunDeckUtil.loadConfig(state, true)
	local converted = 0
	for _=1,n do
		local ok = CardEngine.convertRandomNonBrightToBright(cfg, rng)
		if not ok then break end
		converted += 1
	end
	if converted > 0 then
		RunDeckUtil.saveConfig(state, cfg)
		bonus.queueBrightNext = math.max(0, n - converted)
	end
end

-- 季節開始（1=春, 2=夏, ...）
function Round.newRound(plr: Player, seasonNum: number)
	local s = StateHub.get(plr) or {}

	-- 1) ラン構成をロード（無ければ初期化）
	consumeQueuedConversions(s, Random.new())
	local configDeck = RunDeckUtil.loadConfig(s, true) -- 48枚

	-- 2) 当季デッキを構成からクローン
	local seasonDeck = {}
	for i, c in ipairs(configDeck) do
		seasonDeck[i] = {
			month=c.month, idx=c.idx, kind=c.kind, name=c.name,
			tags=c.tags and table.clone(c.tags) or nil, code=c.code,
		}
	end

	-- 2.5) ★ シードを明示管理（復元用に state に保持）
	local seed = makeSeasonSeed(seasonNum)
	CardEngine.shuffle(seasonDeck, seed)

	-- 3) 初期配り
	local hand  = CardEngine.draw(seasonDeck, 5)
	local board = {}
	for i=1,8 do table.insert(board, table.remove(seasonDeck)) end

	-- 4) 状態保存（命名統一：board/dump）
	s.run         = s.run or {}
	s.deck        = seasonDeck
	s.hand        = hand
	s.board       = board
	s.taken       = {}
	s.dump        = {}
	s.season      = seasonNum
	s.handsLeft   = MAX_HANDS
	s.rerollsLeft = MAX_REROLLS
	s.seasonSum   = 0
	s.chainCount  = 0
	s.mult        = s.mult or 1.0
	s.bank        = s.bank or 0
	s.mon         = s.mon or 0
	s.phase       = "play"
	s.deckSeed    = seed            -- ★ 復元用に保持

	StateHub.set(plr, s)
	StateHub.pushState(plr)

	-- 5) ★ 季節開始スナップを保存（CONTINUE用）
	if SaveService and SaveService.snapSeasonStart then
		-- 失敗してもゲームは継続（pcallで保護）
		pcall(function()
			SaveService.snapSeasonStart(plr, s, seasonNum)
		end)
	end
end

-- ランを完全リセット（構成も初期48へ戻す）
function Round.resetRun(plr: Player)
	local prev = StateHub.get(plr)
	local keepBank   = (prev and prev.bank) or 0
	local keepYear   = (prev and prev.year) or 0
	local keepClears = (prev and prev.totalClears) or 0

	local fresh = {
		bank = keepBank, year = keepYear, totalClears = keepClears,
		mult = 1.0, mon = 0, phase = "play",
		run = { configSnapshot = nil }, -- 次で自動初期化
	}
	StateHub.set(plr, fresh)

	-- ★ 新ラン開始（newRound 内でスナップも作成される）
	Round.newRound(plr, 1)
end

return Round
```

### src/shared/RunDeckUtil.lua
```lua
-- ReplicatedStorage/SharedModules/RunDeckUtil.lua
-- 役割：ラン状態のユーティリティ。
-- 変更:
--  - getUnlockedTalismanSlots(state): state.run から安全に読取り、無ければ 0 を返す
--  - ensureTalisman(state, opts): 護符テーブルの存在と最低限の形を保証（不足キーのみ補完）

-- v0.9.0 ラン構成ユーティリティ（唯一の正本：run.configSnapshot）
-- ここだけを読み書きする。季節ごとの山札は毎季これをクローンして生成。

local RS         = game:GetService("ReplicatedStorage")
local SharedMods = RS:WaitForChild("SharedModules")
local CardEngine = require(SharedMods:WaitForChild("CardEngine"))

local M = {}

--========================
-- Deck snapshot
--========================

-- run.configSnapshot を返す（必要なら初期48で初期化）
local function _ensureSnapshot(state)
	state.run = state.run or {}
	if typeof(state.run.configSnapshot) == "table" then
		return state.run.configSnapshot
	end
	-- 初期化
	local base = CardEngine.buildDeck()
	local snap = CardEngine.buildSnapshot(base)
	state.run.configSnapshot = snap
	return snap
end

-- ラン構成（テーブル48枚）を返す
-- initIfMissing=true のとき、存在しなければ初期化して返す
function M.loadConfig(state, initIfMissing)
	if typeof(state) ~= "table" then return nil end
	state.run = state.run or {}
	local snap = state.run.configSnapshot
	if typeof(snap) ~= "table" then
		if initIfMissing then snap = _ensureSnapshot(state) else return nil end
	end
	return CardEngine.buildDeckFromSnapshot(snap)
end

-- 渡された deck（テーブル）で run.configSnapshot を更新
-- deck が省略された場合、既存の run.configSnapshot を再保存（整形）するだけ
function M.saveConfig(state, deck)
	if typeof(state) ~= "table" then return end
	state.run = state.run or {}
	if typeof(deck) ~= "table" or #deck == 0 then
		-- 既存スナップショットがない場合は初期化
		if typeof(state.run.configSnapshot) ~= "table" then
			state.run.configSnapshot = CardEngine.buildSnapshot(CardEngine.buildDeck())
		end
		return
	end
	state.run.configSnapshot = CardEngine.buildSnapshot(deck)
end

-- 現在のスナップショットを返す（必ず存在）
function M.snapshot(state)
	return _ensureSnapshot(state)
end

--========================
-- Matsuri Levels (Festival Levels)
--========================
function M.ensureMeta(state)
	if typeof(state) ~= "table" then return {} end
	state.run = state.run or {}
	state.run.meta = state.run.meta or {}
	state.run.meta.matsuriLevels = state.run.meta.matsuriLevels or {}
	return state.run.meta
end

-- { [festivalId]=level } を返す（無ければ空）
function M.getMatsuriLevels(state)
	local meta = M.ensureMeta(state)
	return meta.matsuriLevels
end

-- 祭事レベルを増減（通常は delta=+1）。戻り値：新レベル
function M.incMatsuri(state, festivalId, delta)
	local meta = M.ensureMeta(state)
	local t = meta.matsuriLevels
	local cur = tonumber(t[festivalId] or 0) or 0
	local nextLv = math.max(0, cur + (tonumber(delta) or 0))
	t[festivalId] = nextLv
	return nextLv
end

-- ニューゲーム時に祭事をリセット
function M.resetMatsuri(state)
	local meta = M.ensureMeta(state)
	meta.matsuriLevels = {}
end

--========================
-- Talisman（護符）ユーティリティ
--========================

local function _clone6(src:{any}?): {any}
	local s = src or {}
	return { s[1], s[2], s[3], s[4], s[5], s[6] }
end

-- 内部: 護符のアンロック数をできるだけ多くの互換キーから読み取る
local function _readUnlockedFromRun(run)
	-- 最優先: run.unlocked / run.talismanUnlocked / run.talisman.unlocked
	if typeof(run.unlocked) == "number" then
		return math.max(0, math.floor(run.unlocked))
	end
	if typeof(run.talismanUnlocked) == "number" then
		return math.max(0, math.floor(run.talismanUnlocked))
	end
	if typeof(run.talisman) == "table" and typeof(run.talisman.unlocked) == "number" then
		return math.max(0, math.floor(run.talisman.unlocked))
	end

	-- 配列風 talisman の最大インデックスを推定
	if typeof(run.talisman) == "table" then
		local maxIdx = 0
		for k, _ in pairs(run.talisman) do
			if typeof(k) == "number" and k > maxIdx then
				maxIdx = k
			end
		end
		if maxIdx > 0 then
			return maxIdx
		end
	end

	return 0
end

-- 公開API: アンロック済み護符スロット数を返す（見つからなければ 0）
function M.getUnlockedTalismanSlots(state)
	if typeof(state) ~= "table" then return 0 end
	state.run = state.run or {}
	return _readUnlockedFromRun(state.run)
end

-- 公開API: 護符テーブル（run.talisman）の存在と最低限の形を保証
-- opts: { minUnlocked: number?, maxSlots: number? }
-- 既存値は尊重し、不足キーだけ補う（unlocked は整合性のため 0..maxSlots に丸め）
function M.ensureTalisman(state, opts)
	if typeof(state) ~= "table" then return nil end
	state.run = state.run or {}

	local minUnlocked = tonumber(opts and opts.minUnlocked) or 2
	local maxSlots    = tonumber(opts and opts.maxSlots) or 6
	minUnlocked = math.max(0, math.floor(minUnlocked))
	maxSlots    = math.max(1, math.floor(maxSlots))

	local b = state.run.talisman
	if typeof(b) ~= "table" then
		-- 新規生成（既存が無い場合のみ）
		b = {
			maxSlots = maxSlots,
			unlocked = math.min(maxSlots, minUnlocked),
			slots    = { nil, nil, nil, nil, nil, nil },
		}
		state.run.talisman = b
	else
		-- 既存を尊重しつつ不足補完
		if typeof(b.maxSlots) ~= "number" then
			b.maxSlots = maxSlots
		else
			b.maxSlots = math.max(1, math.floor(b.maxSlots))
		end

		if typeof(b.unlocked) ~= "number" then
			b.unlocked = math.min(b.maxSlots, minUnlocked)
		else
			b.unlocked = math.floor(b.unlocked)
			-- 整合性のためだけに丸め（増減の意思決定はしない）
			if b.unlocked < 0 then b.unlocked = 0 end
			if b.unlocked > b.maxSlots then b.unlocked = b.maxSlots end
		end

		if typeof(b.slots) ~= "table" then
			b.slots = { nil, nil, nil, nil, nil, nil }
		else
			b.slots = _clone6(b.slots)
		end
	end

	return b
end

return M
```

### src/shared/score/constants.lua
```lua
-- ReplicatedStorage/SharedModules/score/constants.lua
-- v0.9.3-S2 定数 & 対応表（現行Scoring.luaと同値）

local K = {}

-- 役ベース文（mon）
K.ROLE_MON = {
	five_bright = 10, four_bright = 8, rain_four_bright = 7, three_bright = 5,
	inoshikacho = 5, red_ribbon = 5, blue_ribbon = 5,
	seeds = 1, ribbons = 1, chaffs = 1,
	hanami = 5, tsukimi = 5,
}

-- 1枚あたりの点（pts）
K.CARD_PTS = { bright=5, seed=2, ribbon=2, chaff=1 }

-- 祭事（festivalId → { mult_per_lv, pts_per_lv }）
K.MATSURI_COEFF = {
	sai_kasu      = { 1.0,  1 },
	sai_tanzaku   = { 1.0,  3 },
	sai_tane      = { 1.0,  3 },
	sai_akatan    = { 1.5,  5 },
	sai_aotan     = { 1.5,  5 },
	sai_inoshika  = { 2.0, 15 },
	sai_hanami    = { 2.0, 15 },
	sai_tsukimi   = { 2.0, 15 },
	sai_sanko     = { 2.0, 20 },
	sai_goko      = { 3.0, 30 },
}

-- 役キー → yaku_*
K.ROLE_TO_YAKU = {
	chaffs="yaku_kasu", ribbons="yaku_tanzaku", seeds="yaku_tane",
	red_ribbon="yaku_akatan", blue_ribbon="yaku_aotan",
	inoshikacho="yaku_inoshikacho", hanami="yaku_hanami", tsukimi="yaku_tsukimi",
	three_bright="yaku_sanko", five_bright="yaku_goko",
}

-- yaku_* → 祭事ID
K.YAKU_TO_SAI = {
	yaku_kasu={"sai_kasu"}, yaku_tanzaku={"sai_tanzaku"}, yaku_tane={"sai_tane"},
	yaku_akatan={"sai_akatan","sai_tanzaku"}, yaku_aotan={"sai_aotan","sai_tanzaku"},
	yaku_inoshikacho={"sai_inoshika"}, yaku_hanami={"sai_hanami"}, yaku_tsukimi={"sai_tsukimi"},
	yaku_sanko={"sai_sanko"}, yaku_goko={"sai_goko"},
}

return K
```

### src/shared/score/ctx.lua
```lua
-- ReplicatedStorage/SharedModules/score/ctx.lua
-- v0.9.3-S9 計算用コンテキスト
-- ・ledger で各フェーズの寄与を記録
-- ・equipped（S-8）：護符/お守りの装備ID群を通す
-- ・mult（S-9）：将来の倍率合成先（add=加算倍率総和, mul=乗算倍率積）

local Ctx = {}
Ctx.__index = Ctx

function Ctx.new()
	return setmetatable({
		mon = 0,
		pts = 0,
		roles = {},
		ledger = {}, -- { {phase="P2_roles", dmon=+X, dpts=+Y, note="..."} , ... }
		equipped = { talisman = {}, omamori = {} }, -- S-8
		mult = { add = 0, mul = 1 }, -- S-9 finalize用（現状add=0,mul=1で挙動不変）
	}, Ctx)
end

function Ctx:add(phase: string, dmon: number?, dpts: number?, note: string?)
	table.insert(self.ledger, {
		phase = phase,
		dmon  = dmon or 0,
		dpts  = dpts or 0,
		note  = note,
	})
end

-- S-8: 装備IDセット（配列 or set を許容）
local function toIdList(v)
	local out = {}
	if typeof(v) ~= "table" then return out end
	local n = 0
	for k, val in pairs(v) do
		if typeof(k)=="number" then
			-- 配列
			if val ~= nil then
				n += 1; out[n] = tostring(val)
			end
		else
			-- set/dict
			if val then
				n += 1; out[n] = tostring(k)
			end
		end
	end
	return out
end

function Ctx:setEquipped(e)
	if typeof(e) ~= "table" then return end
	self.equipped = {
		talisman = toIdList(e.talisman or e.talismans or e.tlmn or {}),
		omamori  = toIdList(e.omamori  or e.oma      or e.omo  or {}),
	}
end

return Ctx
```

### src/shared/score/hooks/init.lua
```lua
-- SharedModules/score/hooks/init.lua
-- v1.0 S5: talisman フックを「役加点の直前」に登録する

local M = {}

-- 既存フックの読み込み
local roleHooks     = require(script:WaitForChild("role"))         -- 例：役の加点
local multiplier    = require(script:WaitForChild("multiplier"))   -- 例：倍率処理
local bonus         = require(script:WaitForChild("bonus"))        -- 例：各種ボーナス
local talisman      = require(script:WaitForChild("talisman"))     -- ★今回追加

-- 実行順を固定化（例）:
--  1) multiplier（倍率の前処理があるなら）
--  2) talisman   ← ★役に依存する護符もあるため「役加点の直前」に置く
--  3) roleHooks
--  4) bonus（最終係数系が別ならここ）
M.ORDERED = {
	-- 例：倍率前処理
	function (tally, state, ctx) return multiplier.apply(tally, state, ctx) end,

	-- ★S5: 護符
	function (tally, state, ctx) return talisman.apply(tally, state, ctx) end,

	-- 役
	function (tally, state, ctx) return roleHooks.apply(tally, state, ctx) end,

	-- ボーナス（必要に応じて）
	function (tally, state, ctx) return bonus.apply(tally, state, ctx) end,
}

-- パイプライン実行ユーティリティ（既存があるならそれを使用）
function M.runAll(tally, state, ctx)
	local out = tally
	for _, fn in ipairs(M.ORDERED) do
		out = fn(out, state, ctx)
	end
	return out
end

return M
```

### src/shared/score/hooks/omamori.lua
```lua
-- hooks/omamori.lua — S-3 no-op。将来ここにお守りの効果を追加。
local M = {}

function M.apply(roles, mon, pts, state)
	return roles, mon, pts
end

return M
```

### src/shared/score/hooks/talisman.lua
```lua
-- ReplicatedStorage/SharedModules/score/hooks/talisman.lua
-- v0.9.4-S5: 護符の効果をスコア（mon）へ反映
-- 公開I/F:
--   readEquipped(state) -> { {id="..."}, ... }
--   apply(roles, mon, pts, state, ctx) -> roles, mon, pts
-- 互換: 既存の roles/mon/pts の型を変更しない（mon のみ加算）


local RS = game:GetService("ReplicatedStorage")
local SharedModules = RS:WaitForChild("SharedModules")
local TalismanState = require(SharedModules:WaitForChild("TalismanState"))

-- TalismanDefs は配置が「Shared/TalismanDefs.lua」想定。
-- プロジェクト差に備えてフォールバックも用意。
local function requireTalismanDefs()
	-- 1) ReplicatedStorage/Shared/TalismanDefs
	local Shared = RS:FindFirstChild("Shared")
	if Shared and Shared:FindFirstChild("TalismanDefs") then
		return require(Shared.TalismanDefs)
	end
	-- 2) ReplicatedStorage/SharedModules/TalismanDefs
	if SharedModules:FindFirstChild("TalismanDefs") then
		return require(SharedModules.TalismanDefs)
	end
	error("TalismanDefs not found under RS/Shared or RS/SharedModules")
end

local TalismanDefs = requireTalismanDefs()

local M = {}

--==================================================
-- utils
--==================================================

local function cloneArray(t)
	if table.clone then return table.clone(t or {}) end
	local r = {}
	for i,v in ipairs(t or {}) do r[i] = v end
	return r
end

-- roles は {"gokou","shikou",...} or {gokou=true,...} の両対応
local function hasRole(roles, key)
	if type(roles) ~= "table" or not key then return false end
	if roles[key] == true then return true end
	for _, v in ipairs(roles) do
		if v == key then return true end
	end
	return false
end

local function anyRole(roles, keys)
	for _, k in ipairs(keys or {}) do
		if hasRole(roles, k) then return true end
	end
	return false
end

--==================================================
-- API
--==================================================

-- state.run.talisman.slots を唯一の情報源として読み取り、
-- ctx.equipped.talisman 向けの正規形（配列 { {id=...}, ... }）に変換
function M.readEquipped(state)
	local ids = TalismanState.getEquippedIds(state) -- { "id", ... } or {}
	local out = {}
	if typeof(ids) ~= "table" then return out end
	for i = 1, #ids do
		local id = ids[i]
		if id ~= nil then
			table.insert(out, { id = tostring(id) })
		end
	end
	return out
end

-- S5: 護符効果を mon に反映（roles/pts は不変）
-- ・純関数的に動作（副作用なし）。ログ出力だけ任意で対応（ctx.log があれば）。
-- ・Defs 仕様:
--    - enabled == false なら無効
--    - stack == false なら同一IDは1回まで
--    - limit が数値ならその回数まで適用
--    - effect:
--        type="add_mon", amount=+N
--        type="add_role_mon", role="gokou", amount=+N
--        type="add_any_role_mon", roles={...}, amount=+N
function M.apply(roles, mon, pts, state, ctx)
	-- 安全な既定値
	local r   = roles or {}
	local m   = tonumber(mon) or 0
	local p   = pts   -- そのまま返す
	local ids = TalismanState.getEquippedIds(state) or {}

	if type(ids) ~= "table" or #ids == 0 then
		return r, m, p
	end

	-- スタック制御
	local appliedCount = {}
	local totalAdd = 0

	for _, id in ipairs(ids) do
		if type(id) == "string" and #id > 0 then
			-- Defs.get(id) 優先（存在しない場合は registry 直参照を許容）
			local def = nil
			if type(TalismanDefs.get) == "function" then
				def = TalismanDefs.get(id)
			elseif TalismanDefs.registry then
				def = TalismanDefs.registry[id]
				if def and def.enabled == false then def = nil end
			end

			if def then
				-- スタック／上限
				local cnt = appliedCount[def.id] or 0
				if def.stack == false and cnt >= 1 then
					-- 何もしない
				elseif type(def.limit) == "number" and cnt >= def.limit then
					-- 何もしない
				else
					local eff = def.effect or {}
					local delta = 0

					if eff.type == "add_mon" then
						delta = tonumber(eff.amount) or 0

					elseif eff.type == "add_role_mon" then
						if eff.role and hasRole(r, eff.role) then
							delta = tonumber(eff.amount) or 0
						end

					elseif eff.type == "add_any_role_mon" then
						if anyRole(r, eff.roles) then
							delta = tonumber(eff.amount) or 0
						end
					end

					if delta ~= 0 then
						appliedCount[def.id] = cnt + 1
						totalAdd = totalAdd + delta
						if ctx and type(ctx.log) == "function" then
							pcall(ctx.log, "[P5_score] talisman=%s delta=%d", def.id, delta)
						end
					end
				end
			end
		end
	end

	if totalAdd ~= 0 then
		m = m + totalAdd
	end

	return r, m, p
end

return M
```

### src/shared/score/index.lua
```lua
-- ReplicatedStorage/SharedModules/score/index.lua
-- v0.9.3-S10 P4_talisman no-op配管＋equipped受け渡し（挙動不変）

local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local K   = require(script.Parent.constants)
local Ctx = require(script.Parent.ctx)

local P1 = require(script.Parent.phases.P1_count)
local P2 = require(script.Parent.phases.P2_roles)
local P3 = require(script.Parent.phases.P3_matsuri_kito)
local P4 = require(script.Parent.phases.P4_talisman)    -- ← no-op 実体
local P5 = require(script.Parent.phases.P5_omamori)     -- ← no-op（既存/無ければ本回答のstubを使用）
local PF = require(script.Parent.phases.finalize)

-- hooks
local TalHook = require(script.Parent.hooks.talisman)   -- ← ★ 新設フック

-- スコープ付きロガー（タグ=Score）
local LOG = nil
do
	local ok, Logger = pcall(function()
		local SharedModules = RS:WaitForChild("SharedModules")
		return require(SharedModules:WaitForChild("Logger"))
	end)
	if ok and Logger and typeof(Logger.scope) == "function" then
		LOG = Logger.scope("Score")
	end
end

local function devLog(msg)
	if not RunService:IsStudio() then return end
	if LOG and typeof(LOG.info) == "function" then
		LOG.info(msg)
	else
		warn("[Score][DEV] " .. tostring(msg))
	end
end

local M = {}

function M.evaluate(takenCards, state)
	local ctx = Ctx.new()

	-- S2: state → ctx.equipped へ“正式形”で転記（talismanのみ・他は将来拡張）
	--     旧来の state.equipped/loadout 等があっても、talismanは run.talisman から読むのを優先
	do
		local equipped = {}
		equipped.talisman = TalHook.readEquipped(state) -- => { {id=...}, ... } or {}
		-- 互換: 既存の他スロットがあれば温存
		local legacy = (typeof(state)=="table") and (state.equipped or state.loadout or state.equip) or nil
		if typeof(legacy)=="table" then
			for k,v in pairs(legacy) do
				if k ~= "talisman" then
					equipped[k] = v
				end
			end
		end
		if typeof(ctx.setEquipped) == "function" then
			ctx:setEquipped(equipped)
		else
			ctx.equipped = equipped
		end
	end

	-- P1: カウント
	local c = P1.counts(takenCards)

	-- P2: 役 → mon/pts 基礎
	local roles, mon, pts = P2.evaluateRoles(takenCards, c, ctx)

	-- P3: 祭事/寅の上乗せ
	mon, pts = P3.applyMatsuriAndKito(roles, mon, pts, state, ctx)

	-- P4: 護符（no-op: 装備数ログとledger追記のみ。数値は不変）
	roles, mon, pts = P4.applyTalisman(roles, mon, pts, state, ctx)

	-- P5: お守り（no-op/将来ON）
	roles, mon, pts = P5.applyOmamori(roles, mon, pts, state, ctx)

	-- Dev: ledger出力（Studioのみ）
	if RunService:IsStudio() then
		for _,line in ipairs(ctx.ledger) do
			devLog(string.format("%s: dmon=%.3f dpts=%.3f %s",
				tostring(line.phase),
				tonumber(line.dmon or 0),
				tonumber(line.dpts or 0),
				tostring(line.note or "")
			))
		end
	end

	-- finalize（唯一式）— 現状 factor=1 で挙動不変
	local total, _mon, _pts, factor = PF.finalize(mon, pts, ctx)
	return total, roles, { mon = mon, pts = pts }
end

-- 互換API
function M.getFestivalStat(fid, level)
	local lv = tonumber(level or 0) or 0
	local coeff = K.MATSURI_COEFF[fid]
	if not coeff then return 0, 0 end
	return lv * (coeff[1] or 0), lv * (coeff[2] or 0)
end

function M.getFestivalsForYaku(yakuId)
	return K.YAKU_TO_SAI[yakuId] or {}
end

function M.getKitoPts(effectId, level)
	if effectId == "tora" or effectId == "kito_tora" then
		return tonumber(level or 0) or 0
	end
	return 0
end

return M
```

### src/shared/score/phases/finalize.lua
```lua
-- ReplicatedStorage/SharedModules/score/phases/finalize.lua
-- v0.9.3-S9 Finalize規約（唯一の式）:
-- score = (Σmon) * (Σpts) * ((1 + ΣaddMult) * ΠmulMult)
-- 現状は add=0, mul=1 なので挙動は不変。将来の倍率は ctx.mult に集約する。

local F = {}

function F.finalize(mon: number, pts: number, ctx: any)
	local add = 0
	local mul = 1
	if ctx and typeof(ctx) == "table" and typeof(ctx.mult)=="table" then
		add = tonumber(ctx.mult.add or 0) or 0
		mul = tonumber(ctx.mult.mul or 1) or 1
	end
	local factor = (1 + add) * mul
	-- 既存I/Fでは detail は {mon, pts} を返す契約なので、mon/pts は変更しない
	local total = (mon * pts) * factor
	-- ledgerには合成係数だけ記録（将来のデバッグのため）
	if ctx and typeof(ctx.add)=="function" then
		if factor ~= 1 then
			ctx:add("P9_finalize", 0, 0, string.format("factor=%.6f (add=%.6f, mul=%.6f)", factor, add, mul))
		else
			-- factor=1 の場合は静穏でOK（必要なら上の行を有効化）
			-- ctx:add("P9_finalize", 0, 0, "factor=1.0")
		end
	end
	return total, mon, pts, factor
end

return F
```

### src/shared/score/phases/P0_normalize.lua
```lua
-- ReplicatedStorage/SharedModules/score/phases/P0_normalize.lua
-- v0.9.3-S2 P0: 正規化ヘルパ集

local Kind = require(script.Parent.Parent.util.kind)
local Tags = require(script.Parent.Parent.util.tags)

local P0 = {}

P0.normKind = Kind.normKind
P0.toTagSet = Tags.toTagSet
P0.hasTags  = Tags.hasTags

return P0
```

### src/shared/score/phases/P1_count.lua
```lua
-- ReplicatedStorage/SharedModules/score/phases/P1_count.lua
-- v0.9.3-S2 P1: 枚数/月/タグ集計（現行countsと同値）

local P0 = require(script.Parent.P0_normalize)

local P1 = {}

function P1.counts(cards: {any}?): {bright:number, seed:number, ribbon:number, chaff:number, months:any, tags:any}
	local c = {bright=0, seed=0, ribbon=0, chaff=0, months={}, tags={}}
	for _,card in ipairs(cards or {}) do
		local k = P0.normKind(card and card.kind)
		if k then c[k] += 1 end
		if card and card.month then
			c.months[card.month] = (c.months[card.month] or 0) + 1
		end
		local tset = P0.toTagSet(card and card.tags)
		for t,_ in pairs(tset) do
			c.tags[t] = (c.tags[t] or 0) + 1
		end
	end
	return c
end

return P1
```

### src/shared/score/phases/P2_roles.lua
```lua
-- ReplicatedStorage/SharedModules/score/phases/P2_roles.lua
-- v0.9.3-S4 P2: 役判定 → mon加算 / pts基礎（ledger対応）

local K  = require(script.Parent.Parent.constants)
local P0 = require(script.Parent.P0_normalize)

local P2 = {}

-- 入力: takenCards, counts, ctx?
-- 出力: roles(table), monBase(number), ptsBase(number)
function P2.evaluateRoles(takenCards: {any}?, c: any, ctx: any)
	local roles, mon = {}, 0

	-- 光系
	if c.bright == 5 then
		roles.five_bright = K.ROLE_MON.five_bright
	elseif c.bright == 4 then
		-- 任意の光4枚は常に「四光」扱い（雨札の有無は無視）
		roles.four_bright = K.ROLE_MON.four_bright
	elseif c.bright == 3 and (c.tags["rain"] or 0) == 0 then
		roles.three_bright = K.ROLE_MON.three_bright
	end

	-- 名前直接（猪鹿蝶・花見・月見）
	local hasName = {}
	for _,card in ipairs(takenCards or {}) do
		if card and card.name then hasName[card.name] = true end
	end
	if hasName["猪"] and hasName["鹿"] and hasName["蝶"] then roles.inoshikacho = K.ROLE_MON.inoshikacho end
	if hasName["桜に幕"] and hasName["盃"] then roles.hanami = K.ROLE_MON.hanami end
	if hasName["芒に月"] and hasName["盃"] then roles.tsukimi = K.ROLE_MON.tsukimi end

	-- 赤短（1,2,3 の 赤+字あり）
	do
		local ok = 0
		for _,m in ipairs({1,2,3}) do
			for _,card in ipairs(takenCards or {}) do
				if card.month==m and P0.normKind(card.kind)=="ribbon" and P0.hasTags(card, {"aka","jiari"}) then
					ok += 1; break
				end
			end
		end
		if ok==3 then roles.red_ribbon = K.ROLE_MON.red_ribbon end
	end

	-- 青短（6,9,10 の 青+字あり）
	do
		local ok = 0
		for _,m in ipairs({6,9,10}) do
			for _,card in ipairs(takenCards or {}) do
				if card.month==m and P0.normKind(card.kind)=="ribbon" and P0.hasTags(card, {"ao","jiari"}) then
					ok += 1; break
				end
			end
		end
		if ok==3 then roles.blue_ribbon = K.ROLE_MON.blue_ribbon end
	end

	-- たね/たん/かす（閾値：5/5/10）→ 超過1枚ごとに +1文
	if c.seed   >= 5  then roles.seeds   = K.ROLE_MON.seeds   + (c.seed   - 5)  end
	if c.ribbon >= 5  then roles.ribbons = K.ROLE_MON.ribbons + (c.ribbon - 5)  end
	if c.chaff  >= 10 then roles.chaffs  = K.ROLE_MON.chaffs  + (c.chaff  - 10) end

	-- 文合算
	for _,v in pairs(roles) do mon += v end

	-- 札→点合算（基礎pts）
	local pts = 0
	for kind,count in pairs({bright=c.bright, seed=c.seed, ribbon=c.ribbon, chaff=c.chaff}) do
		pts += (K.CARD_PTS[kind] or 0) * (count or 0)
	end

	-- ledger: P2の寄与（基礎 mon/pts）
	if ctx and typeof(ctx.add) == "function" then
		ctx:add("P2_roles", mon, pts, "base roles & card pts")
	end

	return roles, mon, pts
end

return P2
```

### src/shared/score/phases/P3_matsuri_kito.lua
```lua
-- ReplicatedStorage/SharedModules/score/phases/P3_matsuri_kito.lua
-- v0.9.3-S4 P3: 祭事/寅の上乗せ（ledger対応）

local RS = game:GetService("ReplicatedStorage")
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil"))
local K = require(script.Parent.Parent.constants)

local P3 = {}

-- 入力: roles(table), monBase(number), ptsBase(number), state(table?), ctx?
-- 出力: mon(number), pts(number)
function P3.applyMatsuriAndKito(roles: any, mon: number, pts: number, state: any, ctx: any)
	local mon0, pts0 = mon, pts

	if typeof(state) == "table" then
		-- 祭事
		local levels = RunDeckUtil.getMatsuriLevels(state) or {}
		if next(levels) ~= nil then
			local yakuList = {}
			for roleKey, v in pairs(roles) do
				if v and v > 0 then
					local yaku = K.ROLE_TO_YAKU[roleKey]
					if yaku then table.insert(yakuList, yaku) end
				end
			end
			for _, yakuId in ipairs(yakuList) do
				local festivals = K.YAKU_TO_SAI[yakuId]
				if festivals then
					for _, fid in ipairs(festivals) do
						local lv = tonumber(levels[fid] or 0) or 0
						if lv > 0 then
							local coeff = K.MATSURI_COEFF[fid]
							if coeff then
								mon += lv * (coeff[1] or 0)
								pts += lv * (coeff[2] or 0)
							end
						end
					end
				end
			end
		end

		-- 干支：寅（Ptsに +1/Lv）
		do
			local kitoLevels = (RunDeckUtil.getKitoLevels and RunDeckUtil.getKitoLevels(state)) or state.kito or {}
			local toraLv = tonumber(kitoLevels.tora or kitoLevels["kito_tora"] or 0) or 0
			if toraLv > 0 then pts += toraLv end
		end
	end

	-- ledger: P3の寄与（差分）
	if ctx and typeof(ctx.add) == "function" then
		ctx:add("P3_matsuri_kito", mon - mon0, pts - pts0, "matsuri/kito add-ons")
	end

	return mon, pts
end

return P3
```

### src/shared/score/phases/P4_talisman.lua
```lua
-- ReplicatedStorage/SharedModules/score/phases/P4_talisman.lua
-- v0.9.3-S10: P4 受け口の堅牢化（ID正規化＋ledger no-op）
-- ・Hooks.apply があれば呼ぶ（安全 pcall）
-- ・無くても no-op で ledger に記録
-- ・ctx.equipped.talisman は { "id", ... } / { {id="..."}, ... } の両方を許容

local RS = game:GetService("ReplicatedStorage")

-- optional: Logger（StudioのみINFO）
local LOG = nil
do
	local ok, Logger = pcall(function()
		local SharedModules = RS:WaitForChild("SharedModules")
		return require(SharedModules:WaitForChild("Logger"))
	end)
	if ok and Logger and typeof(Logger.scope) == "function" then
		LOG = Logger.scope("Score")
	end
end

-- optional: Hooks（ある場合のみ使用）
local Hooks_Talisman = nil
do
	local ok, mod = pcall(function()
		local SharedModules = RS:WaitForChild("SharedModules")
		local Hooks = SharedModules:FindFirstChild("hooks")
		if not Hooks then return nil end
		return require(Hooks:WaitForChild("talisman"))
	end)
	if ok and mod then Hooks_Talisman = mod end
end

local function toIdList(eq)
	-- eq: { "dev_plus1", ... } or { {id="dev_plus1"}, ... }
	local out = {}
	if typeof(eq) ~= "table" then return out end
	for i = 1, #eq do
		local v = eq[i]
		if typeof(v) == "string" then
			table.insert(out, v)
		elseif typeof(v) == "table" and v.id ~= nil then
			table.insert(out, tostring(v.id))
		end
	end
	return out
end

local function addLedger(ctx, dmon, dpts, note)
	ctx = ctx or {}
	if typeof(ctx.add) == "function" then
		ctx:add("P4_talisman", dmon or 0, dpts or 0, note or "")
	else
		ctx.ledger = ctx.ledger or {}
		table.insert(ctx.ledger, { phase = "P4_talisman", dmon = dmon or 0, dpts = dpts or 0, note = note or "" })
	end
end

local P4 = {}

function P4.applyTalisman(roles, mon, pts, state, ctx)
	local mon0, pts0 = mon, pts

	-- 1) 可能なら Hooks.apply を呼ぶ（no-opでもOK）
	if Hooks_Talisman and typeof(Hooks_Talisman.apply) == "function" then
		local ok, r_roles, r_mon, r_pts = pcall(Hooks_Talisman.apply, roles, mon, pts, state, ctx)
		if ok and r_roles ~= nil and r_mon ~= nil and r_pts ~= nil then
			roles, mon, pts = r_roles, r_mon, r_pts
		end
	end

	-- 2) 装備IDのログ（no-op）。両形式に対応してCSV化
	local eq = (ctx and ctx.equipped and ctx.equipped.talisman) or {}
	local ids = toIdList(eq)
	local note = "no-op"
	if #ids > 0 then
		note = ("no-op IDs=%s"):format(table.concat(ids, ","))
	end

	-- 3) ledger 追記（差分0か、Hooksが数値変更していればその差分）
	local dmon, dpts = (mon - mon0), (pts - pts0)
	addLedger(ctx, dmon, dpts, note)

	-- 4) Studioログ
	local RunService = game:GetService("RunService")
	if LOG and RunService:IsStudio() then
		LOG.info(("[P4_talisman] equipped=%d %s dmon=%.3f dpts=%.3f"):format(#ids, note, dmon, dpts))
	end

	return roles, mon, pts
end

return P4
```

### src/shared/score/phases/P5_omamori.lua
```lua
-- P5: Omamori（お守り）受け口 — いまは no-op（ledger対応＋S-8: 装備ID表示）
local RS = game:GetService("ReplicatedStorage")

local Hooks_Omamori = nil
do
	local ok, mod = pcall(function()
		local SharedModules = RS:WaitForChild("SharedModules")
		local Hooks = SharedModules:FindFirstChild("hooks")
		if not Hooks then return nil end
		return require(Hooks:WaitForChild("omamori"))
	end)
	if ok and mod then Hooks_Omamori = mod end
end

local P5 = {}

function P5.applyOmamori(roles, mon, pts, state, ctx)
	local mon0, pts0 = mon, pts
	if Hooks_Omamori and typeof(Hooks_Omamori.apply) == "function" then
		local ok, r_roles, r_mon, r_pts = pcall(Hooks_Omamori.apply, roles, mon, pts, state, ctx)
		if ok and r_roles ~= nil and r_mon ~= nil and r_pts ~= nil then
			roles, mon, pts = r_roles, r_mon, r_pts
		end
	end
	-- S-8: 装備IDログ（no-op）
	local ids = (ctx and ctx.equipped and ctx.equipped.omamori) or {}
	local note = "omamori effects"
	if typeof(ids)=="table" and #ids > 0 then
		note = note .. " IDs=" .. table.concat(ids, ",")
	end
	if ctx and typeof(ctx.add) == "function" then
		ctx:add("P5_omamori", mon - mon0, pts - pts0, note)
	end
	return roles, mon, pts
end

return P5
```

### src/shared/score/util/kind.lua
```lua
-- ReplicatedStorage/SharedModules/score/util/kind.lua
-- v0.9.3-S2 kind正規化（現行同等）

local VALID_KIND = { bright=true, seed=true, ribbon=true, chaff=true }
local KIND_ALIAS = { kasu="chaff", tane="seed", tan="ribbon", tanzaku="ribbon", hikari="bright", light="bright" }

local M = {}

function M.normKind(k: any): string?
	if not k then return nil end
	local v = KIND_ALIAS[k] or k
	return VALID_KIND[v] and v or nil
end

return M
```

### src/shared/score/util/tags.lua
```lua
-- ReplicatedStorage/SharedModules/score/util/tags.lua
-- v0.9.3-S2 タグ集合（現行同等）

local M = {}

function M.toTagSet(tags: any): {[string]: boolean}
	local set: {[string]: boolean} = {}
	if typeof(tags) == "table" then
		for k,v in pairs(tags) do
			if typeof(k) == "number" then
				set[v] = true
			else
				set[k] = (v == nil) and true or v
			end
		end
	end
	return set
end

function M.hasTags(card: any, names: {string}?): boolean
	local set = M.toTagSet(card and card.tags)
	for _,name in ipairs(names or {}) do
		if not set[name] then return false end
	end
	return true
end

return M
```

### src/shared/ScoreService.lua
```lua
-- ReplicatedStorage/SharedModules/ScoreService.lua
-- Confirm（勝負）時の獲得計算と、到達時の遷移制御（春〜秋＝屋台／冬＝分岐）

local RS         = game:GetService("ReplicatedStorage")
local SSS        = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

--===== safe require helpers ============================================
local function reqShared(name)
	local shared = RS:WaitForChild("SharedModules")
	return require(shared:WaitForChild(name))
end

-- 依存
local Scoring  = reqShared("Scoring")
local StateHub = reqShared("StateHub")

-- SaveService はサーバ専用。クライアントで誤 require されても落ちないように stub 化
local SaveService
do
	if RunService:IsServer() then
		local ok, mod = pcall(function()
			return require(SSS:WaitForChild("SaveService"))
		end)
		if ok and type(mod) == "table" then
			SaveService = mod
		else
			-- サーバでも見つからない場合は安全スタブ
			warn("[ScoreService] SaveService not found; using stub")
			SaveService = {
				addBank=function()end, setYear=function()end,
				bumpYear=function()end, bumpClears=function()end,
			}
		end
	else
		-- クライアント側スタブ
		SaveService = {
			addBank=function()end, setYear=function()end,
			bumpYear=function()end, bumpClears=function()end,
		}
	end
end
--=======================================================================

local Score = {}

-- GameInit から注入される：openShop(plr, s, opts)
--   opts = { reward:number?, notice:string?, target:number? }
local openShopFn = nil

-- RoundService 参照（deps から注入。無ければフォールバック require）
local RoundRef = nil

-- ▼ 開発トグル：二択固定（保存を出さない）＋「次」は常にロック表示
local DEV_LOCK_NEXT          = true   -- true の間は canNext=false 固定
local REMOVE_SAVE_BUTTON     = true   -- true なら保存ボタンを送らない（UI二択）

local function calcMonReward(sum, target, season)
	-- 目標値は現在使用しないが将来の調整余地として残す
	local _ = target
	local factor = 0.20 + ((season or 1) - 1) * 0.05
	return math.max(1, math.floor((sum or 0) * factor))
end

function Score.bind(Remotes, deps)
	openShopFn = nil
	RoundRef   = nil

	if deps then
		if typeof(deps.openShop) == "function" then
			openShopFn = deps.openShop
		elseif deps.ShopService and typeof(deps.ShopService.open) == "function" then
			openShopFn = deps.ShopService.open
		end
		if deps.Round then
			RoundRef = deps.Round
		end
	end

	if not (Remotes and Remotes.Confirm and typeof(Remotes.Confirm.OnServerEvent) == "RBXScriptSignal") then
		warn("[ScoreService] Remotes.Confirm missing")
		return
	end

	Remotes.Confirm.OnServerEvent:Connect(function(plr)
		local s = StateHub.get(plr)
		if not s or s.phase ~= "play" then return end
		if (s.handsLeft or 0) <= 0 then return end

		-- 採点
		local takenCards = s.taken or {}
		local total, roles, detail = Scoring.evaluate(takenCards, s)
		local roleMon = (detail and detail.mon) or 0

		-- 役チェイン
		local roleCount = 0
		for _ in pairs(roles or {}) do
			roleCount += 1
		end
		if roleCount > 0 then
			s.chainCount = (s.chainCount or 0) + 1
		end

		local multNow    = StateHub.chainMult(s.chainCount or 0)
		s.mult           = multNow

		-- 早抜けボーナス
		local deckLeft   = #(s.deck or {})
		local quickBonus = math.floor(math.max(deckLeft, 0) / 10) * roleMon

		-- 今ターンの獲得
		local gained  = (total or 0) * multNow + quickBonus
		s.seasonSum   = (s.seasonSum or 0) + gained
		s.handsLeft   = (s.handsLeft or 0) - 1

		local season  = tonumber(s.season or 1) or 1
		local tgt     = StateHub.targetForSeason(season)

		-- 未達：手が尽きたら失敗、まだなら続行
		if (s.seasonSum or 0) < tgt then
			if (s.handsLeft or 0) <= 0 then
				if Remotes.StageResult then
					-- 失敗パス（UI側は true & table のみ表示する想定）
					Remotes.StageResult:FireClient(plr, false, s.seasonSum or 0, tgt, s.mult or 1, s.bank or 0)
				end
				local Round = RoundRef or reqShared("RoundService")
				Round.resetRun(plr)
			else
				StateHub.pushState(plr)
			end
			return
		end

		-- ===== 達成：春〜秋は屋台へ =====
		if season < 4 then
			s.phase = "shop"
			local rewardMon = calcMonReward(s.seasonSum or 0, tgt, season)
			s.mon = (s.mon or 0) + rewardMon
			if openShopFn then
				openShopFn(plr, s, { reward = rewardMon, notice = "達成！", target = tgt })
			else
				StateHub.pushState(plr)
			end
			return
		end

		-- ===== 冬：クリア分岐 =====
		s.phase = "result"

		-- クリア回数（メモリ）
		s.totalClears = (s.totalClears or 0) + 1
		-- ★ 永続にも反映（存在すれば）
		if typeof(SaveService.bumpClears) == "function" then
			SaveService.bumpClears(plr, 1)
		end

		-- 2両ボーナス（メモリ＋永続）
		local rewardBank = 2
		s.bank = (s.bank or 0) + rewardBank
		if typeof(SaveService.addBank) == "function" then
			SaveService.addBank(plr, rewardBank)
		end

		s.lastScore = { total = total or 0, roles = roles, detail = detail }
		StateHub.pushState(plr)

		-- 旧仕様の解禁判定（参照のみ・ログ用）
		local clears   = tonumber(s.totalClears or 0) or 0
		local unlocked_by_clears = (clears >= 3)
		local canNextFinal = (not DEV_LOCK_NEXT) and unlocked_by_clears or false
		local canSaveFinal = false -- 常に保存は無効（ボタン非表示）

		-- DEBUG: 冬クリア時点のサマリ
		print(("[Score] winter clear by %s | clears=%d unlocked=%s season=%s sum=%d target=%d bank=%d")
			:format(
				plr.Name,
				clears,
				tostring(unlocked_by_clears),
				tostring(season),
				s.seasonSum or 0,
				tgt or 0,
				s.bank or 0
			))

		if Remotes.StageResult then
			-- ▼ レガシー（options）と正準（ops）を送る
			local optsLegacy = {
				goHome = { enabled = true,  label = "このランを終える" },
				goNext = { enabled = canNextFinal, label = canNextFinal and "次のステージへ" or "次のステージへ（開発中）" },
			}
			-- 保存ボタンは送らない（UI二択）。どうしてもキーが必要なUIなら以下を有効化して enabled=false で送る
			if not REMOVE_SAVE_BUTTON then
				optsLegacy.saveQuit = { enabled = false, label = "保存する（無効）" }
			end

			local ops = {
				home = optsLegacy.goHome,
				next = optsLegacy.goNext,
			}
			-- save は送らない

			local payload = {
				season      = season,
				seasonSum   = s.seasonSum or 0,
				target      = tgt,
				mult        = s.mult or 1,
				bank        = s.bank or 0,
				rewardBank  = rewardBank,
				bankAdded   = rewardBank,
				clears      = clears,

				-- ▼ UI がこの2フラグを見て分岐する旧実装にも対応
				canNext     = canNextFinal,   -- ← 開発中は常に false
				canSave     = canSaveFinal,   -- ← 常に false（保存ボタン出さない）

				message     = (canNextFinal and "冬をクリア！ 2両を獲得。『次のステージ』が解禁済み。") or
				              "冬をクリア！ 2両を獲得。『次のステージ』は開発中です。",

				options     = optsLegacy, -- 互換（レガシーUI）
				ops         = ops,        -- 正準（Nav: next('home'|'next')のみ想定）
				locks       = { nextLocked = not canNextFinal, saveLocked = true },
				lang        = s.lang,
			}

			print(("[Score] StageResult payload: canNext=%s canSave=%s")
				:format(tostring(payload.canNext), tostring(payload.canSave)))

			Remotes.StageResult:FireClient(plr, true, payload)
		end
		-- 以降の遷移は C→S: Remotes.DecideNext("home"|"next") （NavServer が唯一線）
	end)
end

return Score
```

### src/shared/Scoring.lua
```lua
-- SharedModules/Scoring.lua
-- v0.9.3-S7 互換ラッパ：実体は SharedModules/score/index.lua に集約
-- I/F（据え置き）:
--   S.evaluate(takenCards: {Card}, state?: table) -> (totalScore: number, roles: table, detail: { mon: number, pts: number })
--   S.getFestivalStat(fid, lv) -> (dmon, dpts)
--   S.getFestivalsForYaku(yakuId) -> { festivalId, ... }
--   S.getKitoPts(effectId, lv) -> number

local RS = game:GetService("ReplicatedStorage")

-- 新実装へ委譲（一本化）
local function loadScoreModule()
	local ok, mod = pcall(function()
		local SharedModules = RS:WaitForChild("SharedModules")
		local ScoreFolder  = SharedModules:WaitForChild("score")
		return require(ScoreFolder:WaitForChild("index"))
	end)
	if ok and mod then
		return mod
	end
	-- フォールバック：万一ロード失敗してもゲームを落とさない最小スタブ
	warn("[Scoring] failed to load score/index.lua; using safe fallback (always 0)")
	local S = {}
	function S.evaluate() return 0, {}, { mon = 0, pts = 0 } end
	function S.getFestivalStat() return 0, 0 end
	function S.getFestivalsForYaku() return {} end
	function S.getKitoPts() return 0 end
	return S
end

return loadScoreModule()
```

### src/shared/ShopDefs.lua
```lua
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
	},

	-- 祭事
	sai = {
		{
			id = "sai_kasu", name = "カス祭り", category = "sai", price = 3, effect = "sai_kasu",
			descJP = "カス役に祭事レベル+1（採点時に倍率+1/Lv、点+1/Lv）。",
			descEN = "Festival: Kasu +1 level (scoring +1x and +1pt per Lv).",
		},
		{
			id = "sai_tanzaku", name = "短冊祭り", category = "sai", price = 4, effect = "sai_tanzaku",
			descJP = "短冊役に祭事レベル+1（採点時に倍率+1/Lv、点+3/Lv）。",
			descEN = "Festival: Tanzaku +1 level (scoring +1x and +3pt per Lv).",
		},
		-- TODO: akatan/aotan/inoshika 等追加
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
```

### src/shared/ShopFormat.lua
```lua
-- ReplicatedStorage/SharedModules/ShopFormat.lua
-- v0.9.A ShopFormat：SHOP向けの整形系ユーティリティを集約（挙動は従来通り）
local ShopFormat = {}

--==================================================
-- 言語正規化（"en" / "ja"）
--==================================================
function ShopFormat.normLang(s: string?): string
	if s == "en" then return "en" end
	if s == "ja" or s == "jp" then return "ja" end
	return "ja"
end

--==================================================
-- 価格表記（※従来通り「文」固定。英語UIでもここはそのまま）
--==================================================
function ShopFormat.fmtPrice(n: number?): string
	return ("%d 文"):format(tonumber(n or 0))
end

--==================================================
-- タイトル/説明
--==================================================
function ShopFormat.itemTitle(it: any): string
	if it and it.name then return tostring(it.name) end
	return tostring(it and it.id or "???")
end

function ShopFormat.itemDesc(it: any, lang: string): string
	if not it then return "" end
	if lang == "en" then
		return (it.descEN or it.descEn or it.name or it.id or "")
	else
		return (it.descJP or it.descJa or it.name or it.id or "")
	end
end

--==================================================
-- “名前だけ”フェイス表示（干支ID→短名）
--==================================================
local ZODIAC_NAME: {[string]: string} = {
	kito_ko="子", kito_ushi="丑", kito_tora="寅", kito_u="卯", kito_tatsu="辰", kito_mi="巳",
	kito_uma="午", kito_hitsuji="未", kito_saru="申", kito_tori="酉", kito_inu="戌", kito_i="亥",
}

function ShopFormat.faceName(it: any): string
	if not it then return "???" end
	-- 1) 明示の短名を優先
	if it.displayName and tostring(it.displayName) ~= "" then return tostring(it.displayName) end
	if it.short and tostring(it.short) ~= "" then return tostring(it.short) end
	if it.shortName and tostring(it.shortName) ~= "" then return tostring(it.shortName) end
	-- 2) 干支IDは固定辞書
	if it.id and ZODIAC_NAME[it.id] then return ZODIAC_NAME[it.id] end
	-- 3) 最後に name / id をそのまま
	return tostring(it.name or it.id or "???")
end

--==================================================
-- デッキスナップショット → リスト文字列
--==================================================
function ShopFormat.deckListFromSnapshot(snap: any): (integer, string)
	if typeof(snap) ~= "table" then return 0, "" end
	local countMap: {[string]: number} = {}
	local order = {}
	local entries = snap.entries
	if typeof(entries) == "table" and #entries > 0 then
		for _, e in ipairs(entries) do
			local code = tostring(e.code)
			if not countMap[code] then table.insert(order, code) end
			countMap[code] = (countMap[code] or 0) + 1
		end
	else
		for _, code in ipairs(snap.codes or {}) do
			code = tostring(code)
			if not countMap[code] then table.insert(order, code) end
			countMap[code] = (countMap[code] or 0) + 1
		end
	end
	table.sort(order, function(a,b) return a < b end)
	local parts = {}
	for _, code in ipairs(order) do
		local n = countMap[code] or 0
		table.insert(parts, (n > 1) and ("%s x%d"):format(code, n) or code)
	end
	return tonumber(snap.count or 0) or 0, table.concat(parts, ", ")
end

return ShopFormat
```

### src/shared/ShopService.lua
```lua
-- ServerScriptService/ShopService.lua
-- v0.9.2 → v0.9.2c 屋台サービス（SIMPLE+NONCE + Talisman payload）
-- 変更点:
--  - リロールは回数無制限・費用1文（残回数概念は撤去済み）
--  - 在庫は満杯でも必ず強制再生成
--  - SaveService のスナップ対応は従来どおり（存在しなくても続行）
--  - ShopEffects ローダー復活済み
--  - ★ リロール多重送出防止: クライアントnonceをサーバで検証（TTL付き）
--  - ★ P1-3: Logger 導入（print/warn を LOG.* に置換）
--  - ★ v0.9.2c: ShopOpen ペイロードに talisman を同梱（state.run.talisman をそのまま搭載）
--               ※補完/推測は一切しない（真実は TalismanService/StateHub が管理）

local RS   = game:GetService("ReplicatedStorage")
local SSS  = game:GetService("ServerScriptService")
local Http = game:GetService("HttpService")

-- Logger
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("ShopService")

local Remotes    = RS:WaitForChild("Remotes")
local ShopOpen   = Remotes:WaitForChild("ShopOpen")
local BuyItem    = Remotes:WaitForChild("BuyItem")
local ShopReroll = Remotes:WaitForChild("ShopReroll")

local SharedModules = RS:WaitForChild("SharedModules")
local ShopDefs      = require(SharedModules:WaitForChild("ShopDefs"))
local RunDeckUtil   = require(SharedModules:WaitForChild("RunDeckUtil"))
local CardEngine    = require(SharedModules:WaitForChild("CardEngine"))

-- ★ 護符の正本はサーバ一元管理（不足キー補完のみ）
local TaliService   = require(SSS:WaitForChild("TalismanService"))

-- ★ SaveService（存在しなくてもゲームは動作継続）
local SaveService do
	local ok, mod = pcall(function() return require(SSS:WaitForChild("SaveService")) end)
	if ok then
		SaveService = mod
	else
		LOG.warn("SaveService not available; shop snapshots will be skipped.")
		SaveService = nil
	end
end

--========================
-- 設定
--========================
local MAX_STOCK   = 6   -- 並べる最大数
local REROLL_COST = 1   -- リロール費用

--========================
-- nonce（リロール多重送出防止）
--========================
local REROLL_NONCE_TTL = 120 -- 秒（メモリ掃除用）
local rerollNonceByUser: {[number]: {[string]: number}} = {}

local function pruneNonces(userId: number, now: number)
	local box = rerollNonceByUser[userId]
	if not box then return end
	for n, t in pairs(box) do
		if (now - (t or 0)) > REROLL_NONCE_TTL then
			box[n] = nil
		end
	end
end

local function checkAndAddNonce(userId: number, nonce: string?): boolean
	-- レガシー互換: nonce が無い場合は許容（必要なら false にして強制）
	if type(nonce) ~= "string" or nonce == "" then
		return true
	end
	local now = os.time()
	pruneNonces(userId, now)
	local box = rerollNonceByUser[userId]
	if not box then
		box = {}
		rerollNonceByUser[userId] = box
	end
	if box[nonce] then
		return false
	end
	box[nonce] = now
	return true
end

--========================
-- ログ支援
--========================
local function j(v)
	local ok, res = pcall(function() return Http:JSONEncode(v) end)
	return ok and res or tostring(v)
end

local function matsuriJSON(state)
	local levels = RunDeckUtil.getMatsuriLevels(state)
	return j(levels or {})
end

local function stockBrief(stock)
	local n = (stock and #stock) or 0
	local cats = {}
	if stock then
		for _,it in ipairs(stock) do
			local c = it and it.category or "?"
			cats[c] = (cats[c] or 0) + 1
		end
	end
	return ("%d items %s"):format(n, j(cats))
end

--========================
-- スナップ保存（屋台シーン用）
--========================
local function snapShop(plr: Player, s: any)
	if not SaveService or not SaveService.snapShopEnter then return end
	pcall(function() SaveService.snapShopEnter(plr, s) end)
end

--========================
-- 効果ローダー
--========================
local ShopEffects
do
	local function tryRequire()
		local node = SSS:FindFirstChild("ShopEffects")
		if node then
			if node:IsA("Folder") then
				local initMod = node:FindFirstChild("init")
				if initMod and initMod:IsA("ModuleScript") then
					return require(initMod)
				end
			elseif node:IsA("ModuleScript") then
				return require(node)
			end
		end
		local mod = SharedModules:FindFirstChild("ShopEffects")
		if mod and mod:IsA("ModuleScript") then
			return require(mod)
		end
		return nil
	end
	local ok, mod = pcall(tryRequire)
	if ok and type(mod) == "table" and type(mod.apply) == "function" then
		ShopEffects = mod
		LOG.info("ShopEffects loaded OK")
	else
		LOG.warn("ShopEffects missing/invalid | ok=%s err=%s", tostring(ok), tostring(mod))
		ShopEffects = nil
	end
end

--========================
-- 在庫生成
--========================
local function rollCategory(rng: Random)
	local weights = ShopDefs.WEIGHTS or {}
	local total = 0
	for _, w in pairs(weights) do total += (w or 0) end
	if total <= 0 then return "kito" end
	local r, acc = rng:NextNumber(0, total), 0
	for cat, w in pairs(weights) do
		acc += (w or 0)
		if r <= acc then return cat end
	end
	return "kito"
end

local function generateStock(rng: Random, count: number)
	local items = {}
	local pools = ShopDefs.POOLS or {}
	for _=1, count do
		local cat  = rollCategory(rng)
		local pool = pools[cat]
		if pool and #pool > 0 then
			table.insert(items, table.clone(pool[rng:NextInteger(1, #pool)]))
		end
	end
	-- フィッシャー–イェーツシャッフル
	for i = #items, 2, -1 do
		local jx = rng:NextInteger(1, i)
		items[i], items[jx] = items[jx], items[i]
	end
	return items
end

--========================
-- talisman 抽出（整形/補完はしない）
--========================
local function readRunTalisman(s:any)
	if type(s) ~= "table" then return nil end
	if type(s.run) == "table" and type(s.run.talisman) == "table" then
		return s.run.talisman
	end
	return nil
end

--========================
-- 本体
--========================
local Service = { _getState=nil, _pushState=nil }

-- ========= open =========
local function openFor(plr: Player, s: any, opts: {reward:number?, notice:string?, target:number?}?)
	-- 開店直前に、正本の talisman を必ず準備（不足キーのみ補う）
	pcall(function() TaliService.ensureFor(plr, "ShopOpen") end)

	s.phase = "shop"
	s.shop = s.shop or {}
	s.shop.rng = s.shop.rng or Random.new(os.clock()*1000000)

	-- 初回オープン時：在庫が無ければ MAX_STOCK で生成
	if not s.shop.stock then
		s.shop.stock = generateStock(s.shop.rng, MAX_STOCK)
	end

	local reward = (opts and opts.reward) or 0
	local notice = (opts and opts.notice) or ""
	local target = (opts and opts.target) or 0
	local money  = tonumber(s.mon or 0) or 0

	local deckView = RunDeckUtil.snapshot(s)

	-- ★ talisman は state.run.talisman を“そのまま”搭載（補完や推測はしない）
	local tali = readRunTalisman(s)

	-- ===== LOG =====
	LOG.info(
		"[OPEN] u=%s season=%s mon=%d rerollCost=%d matsuri=%s stock=%s notice=%s talisman#=%s",
		tostring(plr and plr.Name or "?"),
		tostring(s.season), money, REROLL_COST,
		matsuriJSON(s), stockBrief(s.shop.stock),
		(notice ~= "" and notice) or "",
		tostring(type(tali)=="table" and #(tali.slots or {}) or 0)
	)

	-- 入場スナップ
	snapShop(plr, s)

	ShopOpen:FireClient(plr, {
		season       = s.season,
		target       = target,
		seasonSum    = s.seasonSum or 0,
		rewardMon    = reward,
		totalMon     = money,
		mon          = money,              -- 互換（クライアントは mon/totalMon のどちらでも読める）
		stock        = s.shop.stock,
		items        = s.shop.stock,       -- 互換
		notice       = notice,
		rerollCost   = REROLL_COST,
		canReroll    = money >= REROLL_COST,
		currentDeck  = deckView,

		-- UI支援（参照していれば活用 / 不要ならクライアント側で無視）
		maxStock     = MAX_STOCK,
		stockCount   = #(s.shop.stock or {}),

		-- ★ 護符データ（nil 許容、上書き/補完なし）
		talisman     = tali,

		-- 互換用：State を抱えておく（ShopScreen が state.run.talisman を参照できるように）
		state = {
			run = { talisman = tali },
			lang = s.lang,
		},
	})
end

function Service.init(getStateFn: (Player)->any, pushStateFn: (Player)->())
	Service._getState  = getStateFn
	Service._pushState = pushStateFn
	LOG.info("init OK")

	-- 購入
	BuyItem.OnServerEvent:Connect(function(plr: Player, itemId: string)
		local s = Service._getState and Service._getState(plr)
		if not s then return end
		if s.phase ~= "shop" then
			return openFor(plr, s, { notice="現在は屋台の時間ではありません（同期します）" })
		end

		-- ===== pre-search =====
		LOG.debug(
			"[BUY][REQ] u=%s itemId=%s mon(before)=%d stock=%s matsuri(before)=%s",
			tostring(plr and plr.Name or "?"),
			tostring(itemId), tonumber(s.mon or 0),
			stockBrief(s.shop and s.shop.stock), matsuriJSON(s)
		)

		local foundIndex, found
		for i, it in ipairs(((s.shop and s.shop.stock) or {})) do
			if it.id == itemId then foundIndex = i; found = it; break end
		end
		if not found then
			LOG.warn("[BUY][ERR] not found: %s", tostring(itemId))
			return openFor(plr, s, { notice="不明な商品です" })
		end
		local price = tonumber(found.price) or 0
		if (s.mon or 0) < price then
			LOG.warn("[BUY][ERR] mon short: need=%d have=%d", price, tonumber(s.mon or 0))
			return openFor(plr, s, { notice=("文が足りません（必要:%d）"):format(price) })
... (truncated)
```

### src/shared/StateHub.lua
```lua
-- ReplicatedStorage/SharedModules/StateHub.lua
-- サーバ専用：プレイヤー状態を一元管理し、Remotes経由でクライアントへ送信する
-- P0-11: StatePush の payload に goal:number を追加（UI側の文字列パース依存を排除）
-- P1-3: Logger 導入（print/warn を LOG.* に置換）

local RS = game:GetService("ReplicatedStorage")

-- Logger
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("StateHub")

-- 依存モジュール
local Scoring     = require(RS:WaitForChild("SharedModules"):WaitForChild("Scoring"))
local RunDeckUtil = require(RS:WaitForChild("SharedModules"):WaitForChild("RunDeckUtil")) -- ★追加

local StateHub = {}

--========================
-- 内部状態（Server専用）
--========================
type PlrState = {
	deck: {any}?,
	hand: {any}?,
	board: {any}?,
	taken: {any}?,
	dump: {any}?,

	season: number?,        -- 1=春, 2=夏, 3=秋, 4=冬
	handsLeft: number?,
	rerollsLeft: number?,

	seasonSum: number?,     -- 今季の合計(表示用)
	chainCount: number?,    -- 連続役数
	mult: number?,          -- 表示用倍率

	bank: number?,          -- 両（周回通貨）
	mon: number?,           -- 文（季節通貨）

	phase: string?,         -- "play" / "shop" / "result"(冬後)
	year: number?,          -- 周回年数（25年進行で+25）
	homeReturns: number?,   -- 「ホームへ戻る」回数（アンロック条件用）

	lang: string?,          -- ★任意：言語（"ja"/"en"）
	lastScore: any?,        -- 任意：デバッグ/結果表示

	run: any?,              -- RunDeckUtil が内部で利用（meta/matsuriLevels 等）
}

local stateByPlr : {[Player]: PlrState} = {}

--========================
-- 季節/目標/倍率
--========================
local SEASON_NAMES = { [1]="春", [2]="夏", [3]="秋", [4]="冬" }
local MULT   = {1, 2, 4, 8} -- 春→夏→秋→冬の目標倍率
local X_BASE = 1            -- 目標の基準値

local Remotes : {
	StatePush: RemoteEvent?,
	ScorePush: RemoteEvent?,
	HandPush:  RemoteEvent?,
	FieldPush: RemoteEvent?,
	TakenPush: RemoteEvent?,
} | nil = nil

local function targetForSeason(season:number?): number
	local idx = tonumber(season) or 1
	return (MULT[idx] or MULT[#MULT]) * X_BASE
end

local function seasonName(n:number?): string
	return SEASON_NAMES[tonumber(n) or 0] or "?"
end

local function chainMult(n: number?): number
	local x = tonumber(n) or 0
	if x <= 1 then return 1.0
	elseif x == 2 then return 1.5
	elseif x == 3 then return 2.0
	else return 3.0 + (x - 4) * 0.5
	end
end

--========================
-- 初期化（Remotes 注入）
--========================
function StateHub.init(remotesTable:any)
	Remotes = remotesTable
	LOG.info("initialized")
end

--========================
-- 基本API
--========================
function StateHub.get(plr: Player): PlrState?
	return stateByPlr[plr]
end

function StateHub.set(plr: Player, s: PlrState)
	stateByPlr[plr] = s
end

function StateHub.clear(plr: Player)
	stateByPlr[plr] = nil
end

--（任意）存在チェック／デバッグ用
function StateHub.exists(plr: Player): boolean
	return stateByPlr[plr] ~= nil
end

-- サーバ内ユーティリティ：欠損プロパティの安全な既定値
local function ensureDefaults(s: PlrState)
	s.season      = s.season or 1
	s.handsLeft   = s.handsLeft or 0
	s.rerollsLeft = s.rerollsLeft or 0
	s.seasonSum   = s.seasonSum or 0
	s.chainCount  = s.chainCount or 0
	s.mult        = s.mult or 1.0
	s.bank        = s.bank or 0
	s.mon         = s.mon or 0
	s.phase       = s.phase or "play"
	s.year        = s.year or 1
	s.homeReturns = s.homeReturns or 0
	s.deck        = s.deck or {}
	s.hand        = s.hand or {}
	s.board       = s.board or {}
	s.taken       = s.taken or {}
	-- lang / run は任意
end

--========================
-- クライアント送信（状態/得点/札）
--========================
function StateHub.pushState(plr: Player)
	if not Remotes then return end
	local s = stateByPlr[plr]; if not s then return end
	ensureDefaults(s)

	-- サマリー算出（Scoring は state（=s）内の祭事レベルも参照可能）
	local takenCards = s.taken or {}
	local total, roles, detail = Scoring.evaluate(takenCards, s) -- detail={mon,pts}

	-- 祭事レベル（UI用にフラットで同梱）
	local matsuriLevels = RunDeckUtil.getMatsuriLevels(s) or {} -- ★追加

	-- 状態（HUD/UI用）
	if Remotes.StatePush then
		local goalVal = targetForSeason(s.season) -- ★P0-11: 数値ゴールを一度だけ算出
		Remotes.StatePush:FireClient(plr, {
			-- 基本
			season      = s.season,
			seasonStr   = seasonName(s.season),       -- 仕様に沿って季節名も送る
			target      = goalVal,                    -- 既存フィールド（互換維持）
			goal        = goalVal,                    -- ★追加：UIが直接参照する数値ゴール

			-- 残り系
			hands       = s.handsLeft or 0,
			rerolls     = s.rerollsLeft or 0,

			-- 経済/表示
			sum         = s.seasonSum or 0,
			mult        = s.mult or 1.0,
			bank        = s.bank or 0,
			mon         = s.mon or 0,

			-- 進行/年数
			phase       = s.phase or "play",
			year        = s.year or 1,
			homeReturns = s.homeReturns or 0,

			-- 言語（UIで利用）
			lang        = s.lang,                     -- ★任意

			-- 祭事レベル（YakuPanel 等のUIで利用）
			matsuri     = matsuriLevels,              -- ★追加（{ [fid]=lv }）

			-- ▼▼ 追加：Run 側のスナップショット（護符ボード反映用）
			run         = {                           -- ★追加
				talisman = (s.run and s.run.talisman) or nil
			},

			-- 山/手の残枚数（UIの安全表示用）
			deckLeft    = #(s.deck or {}),
			handLeft    = #(s.hand or {}),
		})
	end

	-- スコア（リスト/直近役表示）
	if Remotes.ScorePush then
		LOG.debug("ScorePush types: %s %s %s", typeof(total), typeof(roles), typeof(detail))
		Remotes.ScorePush:FireClient(plr, total, roles, detail) -- detail={mon,pts}
	end

	-- 札（手/場/取り）
	if Remotes.HandPush  then Remotes.HandPush:FireClient(plr, s.hand  or {}) end
	if Remotes.FieldPush then Remotes.FieldPush:FireClient(plr, s.board or {}) end
	if Remotes.TakenPush then Remotes.TakenPush:FireClient(plr, s.taken or {}) end
end

--========================
-- 共有ユーティリティ（他モジュールから利用）
--========================
StateHub.targetForSeason = targetForSeason
StateHub.seasonName      = seasonName
StateHub.chainMult       = chainMult

return StateHub
```

### src/shared/TalismanDefs.lua
```lua
-- shared/TalismanDefs.lua
-- v0.2 S5: 効果定義つき。必要に応じて enabled=true を段階解放
local M = {}

-- scope: "run"（ラン全体）/ "hand"（手番限定）/ "role"（役成立時のみ）…将来拡張用
-- stack: 同一IDの重ね掛け可否（true=可）
-- limit: 適用上限回数（nil=制限なし）
-- effect:
--   type="add_mon", amount=+N                                  … 常時 文 加算
--   type="add_role_mon", role="gokou", amount=+N               … 特定役成立時に 文 加算
--   type="add_any_role_mon", roles={...}, amount=+N            … 複数役のいずれか成立時
M.registry = {
	-- 開発用サンプル（まずは dev_plus1 だけ有効化して動作確認）
	dev_plus1 = {
		id="dev_plus1",
		nameJa="開発+1",
		nameEn="Dev +1",
		enabled=true,
		tags={"dev","basic"},
		stack=false,
		limit=nil,
		scope="run",
		effect={ type="add_mon", amount=1 },
	},

	dev_gokou_plus5 = {
		id="dev_gokou_plus5",
		nameJa="五光+5",
		nameEn="Gokou +5",
		enabled=false, -- 段階解放：回帰が取れたら true に
		tags={"dev","role"},
		stack=false,
		limit=nil,
		scope="role",
		effect={ type="add_role_mon", role="gokou", amount=5 },
	},

	dev_sake_plus3 = {
		id="dev_sake_plus3",
		nameJa="酒+3",
		nameEn="Sake +3",
		enabled=false, -- 段階解放：回帰が取れたら true に
		tags={"dev","role"},
		stack=true,
		limit=1, -- 例：最大1回まで
		scope="role",
		effect={ type="add_any_role_mon", roles={"sake","inoshikacho"}, amount=3 },
	},
}

function M.get(id)
	local d = M.registry[id]
	if not d or d.enabled == false then return nil end
	return d
end

function M.allEnabled()
	local t = {}
	for id, d in pairs(M.registry) do
		if d.enabled ~= false then
			table.insert(t, d)
		end
	end
	return t
end

return M
```

### src/shared/TalismanState.lua
```lua
-- shared/TalismanState.lua
-- v0.1 Step0: ラン側ボードの初期化と装備ID抽出
local M = {}

local function clamp(n, lo, hi)
	if math.clamp then return math.clamp(n, lo, hi) end
	if n < lo then return lo elseif n > hi then return hi else return n end
end

function M.ensureRunBoard(state: any)
	state.run = state.run or {}
	local accUnlocked = 2
	if state.account and state.account.talismanUnlock and tonumber(state.account.talismanUnlock.unlocked) then
		accUnlocked = clamp(tonumber(state.account.talismanUnlock.unlocked), 0, 6)
	end

	local t = state.run.talisman
	if type(t) ~= "table" then
		t = {
			maxSlots = 6,
			unlocked = accUnlocked,
			slots = {nil,nil,nil,nil,nil,nil},
			bag = {},
		}
		state.run.talisman = t
	else
		t.maxSlots = 6
		t.unlocked = clamp(tonumber(t.unlocked or accUnlocked), 0, 6)
		local s = t.slots or {}
		-- 長さを6に正規化
		t.slots = { s[1], s[2], s[3], s[4], s[5], s[6] }
	end
	return state.run.talisman
end

function M.getEquippedIds(state: any): {string}
	local t = state and state.run and state.run.talisman
	if not t or not t.slots then return {} end
	local out = {}
	for i=1, math.min(6, #t.slots) do
		local id = t.slots[i]
		if id ~= nil then table.insert(out, id) end
	end
	return out
end

return M
```
