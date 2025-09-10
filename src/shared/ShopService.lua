-- v0.9.0-fix 屋台サービス（リロール=回数無制限・費用1文 / -= を安全代入に）
-- +DEBUG LOG 版
local RS  = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Http = game:GetService("HttpService")

local Remotes    = RS:WaitForChild("Remotes")
local ShopOpen   = Remotes:WaitForChild("ShopOpen")
local BuyItem    = Remotes:WaitForChild("BuyItem")
local ShopReroll = Remotes:WaitForChild("ShopReroll")

local SharedModules = RS:WaitForChild("SharedModules")
local ShopDefs      = require(SharedModules:WaitForChild("ShopDefs"))
local RunDeckUtil   = require(SharedModules:WaitForChild("RunDeckUtil"))
local CardEngine    = require(SharedModules:WaitForChild("CardEngine"))

--========================
-- 設定（バランス調整はここだけ変えればOK）
--========================
local REROLL_COST = 1           -- ★ リロール費用（現状は常に 1 文）
local REROLL_UNLIMITED = -1     -- ★ UI用センチネル：-1 なら「∞（無制限）」扱い

--========================
-- ログ支援
--========================
local function j(v) -- JSON安全化
	local ok, res = pcall(function() return Http:JSONEncode(v) end)
	if ok then return res else return tostring(v) end
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

-- 効果ローダー
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

-- ========= open =========
local function openFor(plr: Player, s: any, opts: {reward:number?, notice:string?, target:number?}?)
	s.phase = "shop"
	s.shop = s.shop or {}
	s.shop.rng   = s.shop.rng or Random.new(os.clock()*1000000)
	s.shop.stock = s.shop.stock or (function()
		local items = {}
		-- 6個引く
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
			local jx = rng:NextInteger(1, i)
			items[i], items[jx] = items[jx], items[i]
		end
		return items
	end)()

	-- ★ 回数無制限：UI用に -1 を送る（残回数の実際の管理はしない）
	local remainingRerolls = REROLL_UNLIMITED
	if s.shop.remainingRerolls ~= nil then
		-- 互換：もしサーバで別途管理しているなら数値化（なければ -1 のまま）
		remainingRerolls = tonumber(s.shop.remainingRerolls) or REROLL_UNLIMITED
	end

	local reward = (opts and opts.reward) or 0
	local notice = (opts and opts.notice) or ""
	local target = (opts and opts.target) or 0

	-- 表示用：正本 configSnapshot（必ず存在）
	local deckView = RunDeckUtil.snapshot(s)

	-- ===== DEBUG =====
	print(("[SHOP][OPEN] u=%s season=%s mon=%d rerollCost=%d remain=%d matsuri=%s stock=%s notice=%s")
		:format(tostring(plr and plr.Name or "?"), tostring(s.season), tonumber(s.mon or 0),
				REROLL_COST, remainingRerolls, matsuriJSON(s), stockBrief(s.shop.stock), notice ~= "" and notice or ""))
	-- ================

	ShopOpen:FireClient(plr, {
		season           = s.season,
		target           = target,
		seasonSum        = s.seasonSum or 0,
		rewardMon        = reward,
		totalMon         = s.mon or 0,
		stock            = s.shop.stock,
		items            = s.shop.stock,   -- 互換用（将来統合予定）
		notice           = notice,
		mon              = s.mon or 0,
		rerollCost       = REROLL_COST,    -- ★ 1 文固定
		remainingRerolls = remainingRerolls, -- ★ -1 = 無制限
		canReroll        = (s.mon or 0) >= REROLL_COST,
		currentDeck      = deckView,
	})
end

function Service.init(getStateFn: (Player)->any, pushStateFn: (Player)->())
	Service._getState  = getStateFn
	Service._pushState = pushStateFn

	print("[ShopService] init OK")

	-- 購入
	BuyItem.OnServerEvent:Connect(function(plr: Player, itemId: string)
		local s = Service._getState and Service._getState(plr)
		if not s then return end
		if s.phase ~= "shop" then
			return openFor(plr, s, { notice="現在は屋台の時間ではありません（同期します）" })
		end

		-- ===== DEBUG (pre-search) =====
		print(("[SHOP][BUY][REQ] u=%s itemId=%s mon(before)=%d stock=%s matsuri(before)=%s")
			:format(tostring(plr and plr.Name or "?"), tostring(itemId), tonumber(s.mon or 0), stockBrief(s.shop and s.shop.stock), matsuriJSON(s)))
		-- ==============================

		local foundIndex, found
		for i, it in ipairs(((s.shop and s.shop.stock) or {})) do
			if it.id == itemId then foundIndex = i; found = it; break end
		end
		if not found then
			print(("[SHOP][BUY][ERR] not found: %s"):format(tostring(itemId)))
			return openFor(plr, s, { notice="不明な商品です" })
		end
		local price = tonumber(found.price) or 0
		if (s.mon or 0) < price then
			print(("[SHOP][BUY][ERR] mon short: need=%d have=%d"):format(price, tonumber(s.mon or 0)))
			return openFor(plr, s, { notice=("文が足りません（必要:%d）"):format(price) })
		end

		-- ★ 安全代入で請求
		s.mon = (s.mon or 0) - price

		-- ===== DEBUG (before effect) =====
		print(("[SHOP][BUY][DO] item=%s(%s) price=%d mon(after charge)=%d effect=%s")
			:format(found.name or found.id, tostring(found.category), price, tonumber(s.mon or 0), tostring(found.effect or found.id)))
		-- =================================

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
		else
			effOk, effMsg = false, "効果モジュール未ロード"
		end

		-- ===== DEBUG (after effect) =====
		print(("[SHOP][BUY][RES] ok=%s msg=%s matsuri(after)=%s")
			:format(tostring(effOk), tostring(effMsg or ""), matsuriJSON(s)))
		-- =================================

		if not effOk then
			-- ロールバックも安全代入
			s.mon = (s.mon or 0) + price
			if Service._pushState then Service._pushState(plr) end
			print(("[SHOP][BUY][ROLLBACK] price=%d mon=%d"):format(price, tonumber(s.mon or 0)))
			return openFor(plr, s, { notice=("購入失敗：%s（返金）\n%s"):format(found.name or found.id, tostring(effMsg or "")) })
		end

		if s.shop and s.shop.stock and foundIndex then
			table.remove(s.shop.stock, foundIndex)
		end

		if Service._pushState then Service._pushState(plr) end

		-- ===== DEBUG (final) =====
		print(("[SHOP][BUY][OK] item=%s mon=%d stock(after)=%s")
			:format(found.name or found.id, tonumber(s.mon or 0), stockBrief(s.shop and s.shop.stock)))
		-- ==========================

		openFor(plr, s, { notice=("購入：%s（-%d 文）\n%s"):format(found.name or found.id, price, tostring(effMsg or "")) })
	end)

	-- リロール：回数制限なし／費用=REROLL_COST
	ShopReroll.OnServerEvent:Connect(function(plr: Player)
		local s = Service._getState and Service._getState(plr)
		if not s then return end
		if s.phase ~= "shop" then
			return openFor(plr, s, { notice="今はリロールできません（同期します）" })
		end
		if (s.mon or 0) < REROLL_COST then
			print(("[SHOP][REROLL][ERR] mon short: need=%d have=%d"):format(REROLL_COST, tonumber(s.mon or 0)))
			return openFor(plr, s, { notice=("リロールには %d 文が必要です"):format(REROLL_COST) })
		end

		-- ★ 請求のみ（残回数は管理しない＝無制限）
		s.mon = (s.mon or 0) - REROLL_COST

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
			local jx = rng:NextInteger(1, i)
			items[i], items[jx] = items[jx], items[i]
		end
		s.shop.stock = items

		if Service._pushState then Service._pushState(plr) end

		-- ===== DEBUG =====
		print(("[SHOP][REROLL][OK] u=%s mon=%d cost=%d stock(after)=%s matsuri=%s")
			:format(tostring(plr and plr.Name or "?"), tonumber(s.mon or 0), REROLL_COST, stockBrief(s.shop.stock), matsuriJSON(s)))
		-- =================

		openFor(plr, s, { notice=("品揃えを更新しました（-%d 文）"):format(REROLL_COST) })
	end)
end

function Service.open(plr: Player, s: any, opts: {reward:number?, notice:string?, target:number?}?)
	openFor(plr, s, opts)
end

return Service
