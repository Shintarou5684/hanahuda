-- KitoPickVM.lua
-- KitoPick の ViewModel（View/Renderer から共有する純関数の置き場）
-- 依存：なし（Roblox API 非依存）

local VM = {}

-- kind → 表示名
local KIND_JP = {
	bright = "光札",
	ribbon = "短冊",
	seed   = "タネ",
	chaff  = "カス",
}
function VM.kindToJp(k)
	return KIND_JP[tostring(k or "")] or tostring(k or "?")
end

-- month 推定（payload.entry から）
function VM.parseMonth(entry)
	if not entry then return nil end
	local m = tonumber(entry.month or (entry.meta and entry.meta.month))
	if m and m>=1 and m<=12 then return m end
	local s = tostring(entry.code or entry.uid or "")
	local two = string.match(s, "^(%d%d)")
	if not two then return nil end
	m = tonumber(two)
	if m and m>=1 and m<=12 then return m end
	return nil
end

-- サーバ理由の表示文言
local REASON_JP = {
	["already-applied"]     = "既に適用済みです",
	["already-bright"]      = "すでに光札です",
	["already-chaff"]       = "すでにカス札です",
	["month-has-no-bright"] = "この月に光札はありません",
	["not-eligible"]        = "対象外です",
	["same-target"]         = "同一カードは選べません",
	["no-check"]            = "対象外（サーバ判定なし）",
}
function VM.reasonToText(reason)
	return REASON_JP[tostring(reason or "")] or nil
end

return VM
