-- ServerScriptService/ShopEffects (ModuleScript)
-- TODO: 後で本実装に差し替え。今は待ちを解消するための最小ダミー。
local M = {}

-- 効果適用（戻り値: applied:boolean, message?:string）
function M.apply(effectId, state, ctx)
    -- effectId に応じて state を変更する想定。ひとまず何もしない。
    return false, "NYI"
end

return M
