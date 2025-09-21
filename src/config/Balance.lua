-- ReplicatedStorage/Config/Balance.lua
-- 祈祷（KITO）関連の調整用ノブ集
-- UIは後付け可能なようにフラグで切替え

local Balance = {}

-- ▼ プールの基本設定
Balance.KITO_POOL_SIZE      = 12  -- サンプル提示枚数（UIなし時も内部で使用）
Balance.KITO_POOL_TTL_SEC   = 45  -- セッション有効秒数（開始→決定の猶予）

-- ▼ UI導入のトグル
--   false: サーバ自動選択（旧挙動／内部で即確定）
--   true : UIでプレイヤーが選択（Shop購入後に候補を提示）
Balance.KITO_UI_ENABLED     = true

-- ▼ 本UIを使うため、自動決定は無効化
--   true : 候補受信後にクライアントが自動で1枚決定→Decide送信
--   false: 自動決定をしない（本UIでの手動選択を想定）
Balance.KITO_UI_AUTO_DECIDE = false

-- ▼ 自動選択モード時の選択枚数（酉：1枚変換などは通常1）
Balance.KITO_AUTO_PICK_COUNT = 1

-- ▼ UI時に提示する枚数（未指定なら KITO_POOL_SIZE を使用）
Balance.KITO_UI_PICK_COUNT   = Balance.KITO_POOL_SIZE

return Balance
