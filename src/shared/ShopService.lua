-- ReplicatedStorage/SharedModules/ShopService.lua
-- v0.8.3 屋台サービス：在庫ロール／購入／リロール／ShopOpen送信
-- Remotes の生成は GameInit 側で行い、ここでは WaitForChild で受け取るだけ

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

--==================================================
-- ShopEffects ローダー（SRS/Folder配下init と RS/SharedModules の両対応）
--==================================================
local ShopEffects
do
	local function tryRequire()
		-- 1) ServerScriptService/ShopEffects（Folder配下に init を想定）
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
		-- 2) ReplicatedStorage/SharedModules/ShopEffects（単体 ModuleScript）
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
		warn("[ShopService] ShopEffects が見つからない/不正です（効果適用は無効）", ok, mod)
		ShopEffects = nil
	end
end

-- 依存を外部注入するためのハンドル
local Service = { _getState = nil, _pushState = nil }

--========================
-- 内部ユーティリティ
--========================

-- 出現率（重み）でカテゴリをロール（合計が1でなくてもOKに正規化）
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

-- 重複OKで n 回引き、最後に順番をシャッフルする
local function rollStock(rng: Random, n: number)
	local items = {}
	for _ = 1, n do
		local cat  = rollCategory(rng)
		local pool = (ShopDefs.POOLS or {})[cat]
		if pool and #pool > 0 then
			local src = pool[rng:NextInteger(1, #pool)]
			if src then
				local c = table.clone(src)
				c.price = tonumber(c.price) or 0
				table.insert(items, c)
			end
		end
	end
	-- Fisher-Yates
	for i = #items, 2, -1 do
		local j = rng:NextInteger(1, i)
		items[i], items[j] = items[j], items[i]
	end
	return items
end

-- 150ms の簡易デバウンス
local lastActionAt: {[Player]: number} = {}
local function canAct(plr: Player): boolean
	local t = os.clock()
	if (t - (lastActionAt[plr] or 0)) < 0.15 then return false end
	lastActionAt[plr] = t
	return true
end

local function idsList(arr)
	local s = {}
	for _, it in ipairs(arr or {}) do table.insert(s, tostring(it and it.id or "?")) end
	return table.concat(s, ",")
end

--========================
-- クライアントへ屋台を開く（payload構築）
--========================
local function openFor(plr: Player, s: any, opts: {reward:number?, notice:string?, target:number?}?)
	-- phase は shop を強制（ガード）
	s.phase = "shop"

	s.shop = s.shop or {}
	s.shop.rng   = s.shop.rng or Random.new(os.clock()*1000000)
	s.shop.stock = s.shop.stock or rollStock(s.shop.rng, 6)

	local rerollCost = 1
	local remainingRerolls = s.shop.remainingRerolls  -- nil=無制限
	if remainingRerolls ~= nil then
		remainingRerolls = tonumber(remainingRerolls) or 0
	end

	local reward = (opts and opts.reward) or 0
	local notice = (opts and opts.notice) or ""
	local target = (opts and opts.target) or 0

	-- ★ 正本スナップショット（entries.kind を保持）
	local deckView = CardEngine.buildSnapshotFromState(s)

	print(("[ShopService] openFor -> items=%d mon=%s notice=%s | order=[%s]")
		:format(#(s.shop.stock or {}), tostring(s.mon), tostring(notice), idsList(s.shop.stock)))

	ShopOpen:FireClient(plr, {
		season    = s.season,
		target    = target,
		seasonSum = s.seasonSum or 0,
		rewardMon = reward,
		totalMon  = s.mon or 0,

		-- 表示用
		stock     = s.shop.stock,
		items     = s.shop.stock,
		notice    = notice,

		-- UI が参照するフィールド
		mon               = s.mon or 0,
		rerollCost        = rerollCost,
		remainingRerolls  = remainingRerolls, -- nil=無制限のまま渡す
		canReroll         = (s.mon or 0) >= rerollCost,

		-- ★ デッキの可視化データ（ShopScreen で表示）
		currentDeck       = deckView,  -- {v=2, count, codes, histogram, entries[{code,kind}]}
	})
end

--========================
-- 公開 API
--========================

-- GameInit から注入：状態参照関数と pushState 関数
function Service.init(getStateFn: (Player)->any, pushStateFn: (Player)->())
	Service._getState  = getStateFn
	Service._pushState = pushStateFn

	print("[ShopService] init OK (handlers binding)")

	-- ===== 購入 =====
	BuyItem.OnServerEvent:Connect(function(plr: Player, itemId: string)
		if not canAct(plr) then return end
		local s = Service._getState and Service._getState(plr)
		if not s then
			warn("[ShopService] BuyItem: state not found for", plr)
			return
		end

		print(("[ShopService] BuyItem recv user=%s itemId=%s phase=%s mon=%s items=%d")
			:format(plr.Name, tostring(itemId), tostring(s.phase), tostring(s.mon), #(s.shop and s.shop.stock or {})))

		if s.phase ~= "shop" then
			print("[ShopService] BuyItem: wrong phase -> reopen shop")
			return openFor(plr, s, { notice = "現在は屋台の時間ではありません（同期し直します）", reward = 0, target = 0 })
		end

		local foundIndex, found
		for i, it in ipairs(((s.shop and s.shop.stock) or {})) do
			if it.id == itemId then foundIndex = i; found = it; break end
		end
		if not found then
			warn("[ShopService] BuyItem: item not found in current stock", itemId)
			return openFor(plr, s, { notice = "不明な商品です", reward = 0, target = 0 })
		end

		local price = tonumber(found.price) or 0
		if (s.mon or 0) < price then
			print(("[ShopService] BuyItem: not enough money need=%d have=%s"):format(price, tostring(s.mon)))
			return openFor(plr, s, { notice = "文が足りません", reward = 0, target = 0 })
		end

		-- 先に課金
		local beforeMon = s.mon or 0
		s.mon = beforeMon - price
		print(("[ShopService] BuyItem: charged %d -> mon %d -> %d"):format(price, beforeMon, s.mon))

		-- 効果適用
		local effectId = found.effect or found.id
		local effOk, effMsg = true, ""
		if ShopEffects then
			local okCall, okRet, msgRet = pcall(function()
				return ShopEffects.apply(effectId, s, {
					plr      = plr,
					lang     = (s.lang or "ja"),
					rng      = (s.shop and s.shop.rng) or Random.new(),
					price    = price,
					category = found.category,
					now      = os.time(),
				})
			end)
			if not okCall then
				effOk, effMsg = false, ("効果適用エラー: %s"):format(tostring(okRet))
				warn("[ShopService] BuyItem: effect apply threw:", okRet)
			else
				effOk, effMsg = okRet, msgRet
				print(("[ShopService] BuyItem: effect result ok=%s msg=%s"):format(tostring(effOk), tostring(effMsg)))
			end
		else
			print("[ShopService] BuyItem: ShopEffects missing -> treat as success/no-op")
		end

		-- 失敗時はロールバック
		if not effOk then
			s.mon = (s.mon or 0) + price
			print(("[ShopService] BuyItem: rollback due to effect failure -> mon %s"):format(tostring(s.mon)))
			if Service._pushState then Service._pushState(plr) end
			return openFor(plr, s, {
				notice = ("購入失敗：%s（返金）\n%s"):format(found.name or found.id, tostring(effMsg or "未実装")),
				reward = 0, target = 0
			})
		end

		-- 効果でデッキが変化した可能性 → 正本スナップショット保存
		RunDeckUtil.save(s)

		-- 在庫から除去
		if s.shop and s.shop.stock and foundIndex then
			table.remove(s.shop.stock, foundIndex)
		end

		-- 状態を先に同期
		if Service._pushState then
			print("[ShopService] BuyItem: pushState -> client")
			Service._pushState(plr)
		end

		-- 再オープン
		print("[ShopService] BuyItem: reopen shop with notice")
		openFor(plr, s, {
			notice = ("購入：%s（-%d 文）\n%s"):format(found.name or found.id, price, tostring(effMsg or "")),
			reward = 0, target = 0
		})
	end)

	-- ===== リロール =====
	ShopReroll.OnServerEvent:Connect(function(plr: Player)
		if not canAct(plr) then return end
		local s = Service._getState and Service._getState(plr)
		if not s then
			warn("[ShopService] Reroll: state not found for", plr)
			return
		end

		print(("[ShopService] Reroll recv user=%s phase=%s mon=%s"):format(plr.Name, tostring(s.phase), tostring(s.mon)))

		if s.phase ~= "shop" then
			print("[ShopService] Reroll: wrong phase -> reopen")
			return openFor(plr, s, { notice = "今はリロールできません（同期し直します）", reward = 0, target = 0 })
		end

		local rerollCost = 1
		if (s.mon or 0) < rerollCost then
			print("[ShopService] Reroll: not enough money")
			return openFor(plr, s, { notice = ("リロールには %d 文 必要です"):format(rerollCost), reward = 0, target = 0 })
		end

		s.mon -= rerollCost
		local rng = (s.shop and s.shop.rng) or Random.new(os.clock()*1000000)
		s.shop = s.shop or {}
		s.shop.rng   = rng
		s.shop.stock = rollStock(rng, 6)

		if Service._pushState then
			print("[ShopService] Reroll: pushState -> client")
			Service._pushState(plr)
		end
		openFor(plr, s, { notice = ("品揃えを更新しました（-%d 文）"):format(rerollCost), reward = 0, target = 0 })
	end)
end

-- ScoreService などから：屋台を開く
function Service.open(plr: Player, s: any, opts: {reward:number?, notice:string?, target:number?}?)
	print("[ShopService] Service.open called")
	openFor(plr, s, opts)
end

return Service
