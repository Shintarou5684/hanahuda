-- ShopDefs.lua
local ShopDefs = {}

ShopDefs.CATEGORY = { kito="kito", sai="sai", omamori="omamori" }
ShopDefs.WEIGHTS  = { kito=0.50,   sai=0.35,   omamori=0.15 } -- 出現率

-- 20種ずつ自動生成（当面はダミー名/価格、iconは差し替え前提）
local function gen(prefix, display, basePrice, step)
	local t = {}
	for i=1,20 do
		table.insert(t, {
			id       = ("%s_%02d"):format(prefix, i),
			name     = ("%s %02d"):format(display, i),
			category = prefix,
			price    = basePrice + ((i-1)%5)*step,
			icon     = nil,                  -- 例: "rbxassetid://123456"
			effect   = ("%s_%02d"):format(prefix, i), -- 効果キー（個別 or 後述フォールバック）
		})
	end
	return t
end

ShopDefs.POOLS = {
	kito    = gen("kito",    "祈祷",   1, 0),
	sai     = gen("sai",     "祭事",   1, 0),
	omamori = gen("omamori", "お守り", 1, 0),
}

return ShopDefs
