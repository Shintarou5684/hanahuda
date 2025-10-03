-- ReplicatedStorage/Config/Balance.lua
-- 祈祷（KITO）関連の調整用ノブ集
-- UIは後付け可能なようにフラグで切替え

local Balance = {}

----------------------------------------------------------------
-- ▼▼ ステージ（12か月一直線）設定 ここから ▼▼
----------------------------------------------------------------
-- 月関連の基本パラメータ
Balance.STAGE_START_MONTH  = 1     -- ラン開始月
Balance.STAGE_CLEAR_AT     = 9     -- 9月クリアで勝利扱い（その後は任意のEX）
Balance.STAGE_MONTHS_TOTAL = 12    -- 総月数（EX含めた最終は12月）

-- EX（10〜12月）各月のクリア報酬（両）
Balance.EX_CLEAR_REWARD_RYO = 2

-- 目標スコア：まずは動作確認用に 1〜12 の連番（後でここだけを調整すればOK）
Balance.GOAL_BY_MONTH = {
	[1]=1,  [2]=2,  [3]=3,  [4]=4,  [5]=5,  [6]=6,
	[7]=7,  [8]=8,  [9]=9,  [10]=10, [11]=11, [12]=12,
}

-- 後方互換（呼び出し側が小文字を参照しても動くようにエイリアスを提供）
Balance.goalByMonth = Balance.GOAL_BY_MONTH

-- ヘルパ：月→目標スコア（範囲外はクランプ）
function Balance.getGoalForMonth(month)
	if type(month) ~= "number" then return Balance.GOAL_BY_MONTH[1] end
	if month < 1 then month = 1 end
	if month > Balance.STAGE_MONTHS_TOTAL then month = Balance.STAGE_MONTHS_TOTAL end
	return Balance.GOAL_BY_MONTH[month] or Balance.GOAL_BY_MONTH[1]
end
----------------------------------------------------------------
-- ▲▲ ステージ（12か月一直線）設定 ここまで ▲▲
----------------------------------------------------------------

-- ▼ プールの基本設定
Balance.KITO_POOL_SIZE      = 12  -- サンプル提示枚数（UIなし時も内部で使用）
Balance.KITO_POOL_TTL_SEC   = 45  -- セッション有効秒数（開始→決定の猶予）

-- ▼ プール生成モード（Core用）
--   "any12_disable_ineligible" : ランダム12枚提示 → サーバの canApply で不適格をグレーアウト（新仕様）
--   "eligible12"               : 旧互換。適格なものだけから最大N枚を提示（フィルタ済み）
Balance.KITO_POOL_MODE      = "any12_disable_ineligible"

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

-- ▼ 効果バランス（巳：Venom）
--   Venom 適用時に即時付与する文（所持金）の増分
Balance.KITO_VENOM_CASH      = 5

-- ▼ 互換ノブ（旧Coreが参照していた場合のために残置）
--   "block": すでに同種（例: bright）ならプール除外 / "allow": 含める
--   新Core（any12 モード）では使用しないが、他所で参照されても破綻しないよう既定を置く
Balance.KITO_SAME_KIND_POLICY = "block"  -- legacy / compatibility

return Balance
