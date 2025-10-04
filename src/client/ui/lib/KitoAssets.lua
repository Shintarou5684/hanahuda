-- src/client/ui/lib/KitoAssets.lua
-- v1.1.0 干支アイコン（厳格版: kito.<animal> のみ受理）

local M = {}

-- 子→亥（いただいた順）で確定割当
local ICON = {
	nezumi = "rbxassetid://138080758976905", -- 子
	ushi   = "rbxassetid://98072025493160",  -- 丑
	tora   = "rbxassetid://115144405199625", -- 寅
	u      = "rbxassetid://120370272971127", -- 卯
	tatsu  = "rbxassetid://116982196318196", -- 辰
	mi     = "rbxassetid://74939201459038",  -- 巳
	uma    = "rbxassetid://115729062347409", -- 午
	hitsuji= "rbxassetid://75272554575317",  -- 未
	saru   = "rbxassetid://124239193079274", -- 申
	tori   = "rbxassetid://124637162606181", -- 酉
	inu    = "rbxassetid://119847873888690", -- 戌
	i      = "rbxassetid://127826167495847", -- 亥
}

-- "kito.<animal>..." の <animal> を厳格抽出（揺らぎ非対応）
local function parseAnimalStrict(effectId: string): string?
	if type(effectId) ~= "string" then return nil end
	local animal = effectId:match("^kito%.([a-z]+)%f[^a-z]?")
	if animal and ICON[animal] then
		return animal
	end
	return nil
end

-- effectId（kito.<animal>...）→ rbxassetid
function M.getIcon(effectId: string): string?
	local animal = parseAnimalStrict(effectId)
	return animal and ICON[animal] or nil
end

-- 直接キー取得（"tora" 等）。存在しなければ nil
function M.getIconByKey(key: string): string?
	return ICON[key]
end

return M
