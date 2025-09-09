-- v0.9.0-fix 屋台サービス（-= を安全代入に変更）

local RS  = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

local Remotes    = RS:WaitForChild("Remotes")
local ShopOpen   = Remotes:WaitForChild("ShopOpen")
local BuyItem    = Remotes:WaitForChild("BuyItem")
local ShopReroll = Remotes:WaitForChild("ShopReroll")

local SharedModules = RS:WaitForChild("SharedModules")
local ShopDefs      = require(SharedModules:WaitForChild("ShopDefs"))
local RunDeckUtil   = require(SharedModules:WaitForChild("RunDeckUtil"))
local CardEngine    = require(SharedModules:WaitForChild("CardEngine"))

-- 効果ローダー（略…前回提示のまま）
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
		print("[ShopService] ShopEffects loaded OK")
	else
		warn("[ShopService] ShopEffects missing/invalid", ok, mod)
		ShopEffects = nil
	end
end

local Service = { _getState=nil, _pushState=nil }

--（rollCategory / rollStock / canAct / idsList は前回提示のまま。省略）

-- ========= open =========
local function openFor(plr: Player, s: any, opts: {reward:number?, notice:string?, target:number?}?)
	s.phase = "shop"
	s.shop = s.shop or {}
	s.shop.rng   = s.shop.rng or Random.new(os.clock()*1000000)
	s.shop.stock = s.shop.stock or (function()
		local items = {}
		-- 6個引く（rollCategory/rollStock をインライン化してもOK）
		local function rollCategory(rng: Random)
			local total = 0
			for _, w in pairs(ShopDefs.WEIGHTS or {}) do total += (w or 0) end
			if total <= 0 then return "kito" end
			local r, acc = rng:NextNumber(0, total), 0
			for cat, w in pairs(ShopDefs.WEIGHTS or {}) do
				acc += (w or 0)
				if r <= acc then return cat end
			end
			return "kito"
		end
		local rng = s.shop.rng
		for _=1,6 do
			local cat  = rollCategory(rng)
			local pool = (ShopDefs.POOLS or {})[cat]
			if pool and #pool > 0 then
				table.insert(items, table.clone(pool[rng:NextInteger(1, #pool)]))
			end
		end
		for i = #items, 2, -1 do
			local j = rng:NextInteger(1, i)
			items[i], items[j] = items[j], items[i]
		end
		return items
	end)()

	local rerollCost = 1
	local remainingRerolls = s.shop.remainingRerolls
	if remainingRerolls ~= nil then remainingRerorolls = tonumber(remainingRerolls) or 0 end

	local reward = (opts and opts.reward) or 0
	local notice = (opts and opts.notice) or ""
	local target = (opts and opts.target) or 0

	-- 表示用：正本 configSnapshot（必ず存在）
	local deckView = RunDeckUtil.snapshot(s)

	ShopOpen:FireClient(plr, {
		season    = s.season,
		target    = target,
		seasonSum = s.seasonSum or 0,
		rewardMon = reward,
		totalMon  = s.mon or 0,
		stock     = s.shop.stock,
		items     = s.shop.stock,
		notice    = notice,
		mon               = s.mon or 0,
		rerollCost        = rerollCost,
		remainingRerolls  = remainingRerolls,
		canReroll         = (s.mon or 0) >= rerollCost,
		currentDeck       = deckView,
	})
end

function Service.init(getStateFn: (Player)->any, pushStateFn: (Player)->())
	Service._getState  = getStateFn
	Service._pushState = pushStateFn

	print("[ShopService] init OK")

	-- 購入
	BuyItem.OnServerEvent:Connect(function(plr: Player, itemId: string)
		-- …（前回提示のロジックそのまま）…
		-- 料金控除は -= ではなく安全代入で
		-- s.mon = (s.mon or 0) - price
		-- ロールバック時:
		-- s.mon = (s.mon or 0) + price
		local s = Service._getState and Service._getState(plr)
		if not s then return end
		if s.phase ~= "shop" then
			return openFor(plr, s, { notice="現在は屋台の時間ではありません（同期します）" })
		end

		local foundIndex, found
		for i, it in ipairs(((s.shop and s.shop.stock) or {})) do
			if it.id == itemId then foundIndex = i; found = it; break end
		end
		if not found then
			return openFor(plr, s, { notice="不明な商品です" })
		end
		local price = tonumber(found.price) or 0
		if (s.mon or 0) < price then
			return openFor(plr, s, { notice=("文が足りません（必要:%d）"):format(price) })
		end

		s.mon = (s.mon or 0) - price

		local effOk, effMsg = true, ""
		if ShopEffects then
			local okCall, okRet, msgRet = pcall(function()
				return ShopEffects.apply(found.effect or found.id, s, {
					plr=plr, lang=(s.lang or "ja"),
					rng=(s.shop and s.shop.rng) or Random.new(),
					price=price, category=found.category, now=os.time(),
				})
			end)
			if not okCall then
				effOk, effMsg = false, ("効果適用エラー: %s"):format(tostring(okRet))
				warn("[ShopService] effect threw:", okRet)
			else
				effOk, effMsg = okRet, msgRet
			end
		end

		if not effOk then
			s.mon = (s.mon or 0) + price
			if Service._pushState then Service._pushState(plr) end
			return openFor(plr, s, { notice=("購入失敗：%s（返金）\n%s"):format(found.name or found.id, tostring(effMsg or "")) })
		end

		if s.shop and s.shop.stock and foundIndex then table.remove(s.shop.stock, foundIndex) end

		if Service._pushState then Service._pushState(plr) end
		openFor(plr, s, { notice=("購入：%s（-%d 文）\n%s"):format(found.name or found.id, price, tostring(effMsg or "")) })
	end)

	-- リロール（-= を廃止）
	ShopReroll.OnServerEvent:Connect(function(plr: Player)
		local s = Service._getState and Service._getState(plr)
		if not s then return end
		if s.phase ~= "shop" then
			return openFor(plr, s, { notice="今はリロールできません（同期します）" })
		end
		local rerollCost = 1
		if (s.mon or 0) < rerollCost then
			return openFor(plr, s, { notice=("リロールには %d 文が必要です"):format(rerollCost) })
		end
		s.mon = (s.mon or 0) - rerollCost
		local rng = (s.shop and s.shop.rng) or Random.new(os.clock()*1000000)
		s.shop = s.shop or {}
		s.shop.rng   = rng
		-- 在庫引き直し（6件）
		local items = {}
		local function rollCategory(rng2: Random)
			local total = 0
			for _, w in pairs(ShopDefs.WEIGHTS or {}) do total += (w or 0) end
			if total <= 0 then return "kito" end
			local r, acc = rng2:NextNumber(0, total), 0
			for cat, w in pairs(ShopDefs.WEIGHTS or {}) do
				acc += (w or 0)
				if r <= acc then return cat end
			end
			return "kito"
		end
		for _=1,6 do
			local cat  = rollCategory(rng)
			local pool = (ShopDefs.POOLS or {})[cat]
			if pool and #pool > 0 then
				table.insert(items, table.clone(pool[rng:NextInteger(1, #pool)]))
			end
		end
		for i = #items, 2, -1 do
			local j = rng:NextInteger(1, i)
			items[i], items[j] = items[j], items[i]
		end
		s.shop.stock = items

		if Service._pushState then Service._pushState(plr) end
		openFor(plr, s, { notice=("品揃えを更新しました（-%d 文）"):format(rerollCost) })
	end)
end

function Service.open(plr: Player, s: any, opts: {reward:number?, notice:string?, target:number?}?)
	openFor(plr, s, opts)
end

return Service
