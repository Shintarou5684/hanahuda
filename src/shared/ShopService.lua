-- ReplicatedStorage/SharedModules/ShopService.lua
-- 屋台サービス：在庫ロール／購入／リロール／ShopOpen送信
-- Remotes の生成は GameInit 側で行い、ここでは WaitForChild で受け取るだけ

local RS  = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

local Remotes    = RS:WaitForChild("Remotes")
local ShopOpen   = Remotes:WaitForChild("ShopOpen")
local BuyItem    = Remotes:WaitForChild("BuyItem")
local ShopReroll = Remotes:WaitForChild("ShopReroll")

local ShopDefs   = require(RS:WaitForChild("SharedModules"):WaitForChild("ShopDefs"))

-- ShopEffects の配置は 2 パターンを許容：ServerScriptService または ReplicatedStorage.SharedModules
local ShopEffects
do
	local ok, mod = pcall(function() return require(SSS:WaitForChild("ShopEffects")) end)
	if ok and type(mod) == "table" then
		ShopEffects = mod
	else
		ShopEffects = require(RS.SharedModules.ShopEffects)
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

-- 同一IDを避けて n 個選ぶ
local function pickUnique(pool: {any}, n: number, rng: Random)
	local res, used, tries = {}, {}, 0
	while #res < n and tries < 200 do
		tries += 1
		local it = pool[rng:NextInteger(1, #pool)]
		if it and not used[it.id] then
			used[it.id] = true
			-- クライアントへ送る表示用にクローン（数値系は念のため数値化）
			local c = table.clone(it)
			c.price = tonumber(c.price) or 0
			table.insert(res, c)
		end
	end
	return res
end

local function rollStock(rng: Random, n: number)
	local items, guard = {}, 0
	while #items < n and guard < 100 do
		guard += 1
		local cat  = rollCategory(rng)
		local pool = (ShopDefs.POOLS or {})[cat]
		if pool and #pool > 0 then
			local pick = pickUnique(pool, 1, rng)[1]
			if pick then table.insert(items, pick) end
		end
	end
	return items
end

-- 150ms の簡易デバウンス（多重入力防止）
local lastActionAt: {[Player]: number} = {}
local function canAct(plr: Player): boolean
	local t = os.clock()
	if (t - (lastActionAt[plr] or 0)) < 0.15 then return false end
	lastActionAt[plr] = t
	return true
end

-- クライアントへ屋台を開く（payload構築）
local function openFor(plr: Player, s: any, opts: {reward:number?, notice:string?, target:number?}?)
	-- phase は shop を強制（ガード）。ScoreService 側の付け忘れに備える
	s.phase = "shop"

	s.shop = s.shop or {}
	s.shop.rng   = s.shop.rng or Random.new(os.time())
	s.shop.stock = s.shop.stock or rollStock(s.shop.rng, 6)

	local reward = (opts and opts.reward) or 0
	local notice = (opts and opts.notice) or ""
	local target = (opts and opts.target) or 0

	ShopOpen:FireClient(plr, {
		season    = s.season,
		target    = target,
		seasonSum = s.seasonSum or 0,
		rewardMon = reward,         -- 今回のクリアで得た文（表示用）
		totalMon  = s.mon or 0,     -- 現在の所持文
		stock     = s.shop.stock,   -- 在庫（表示用コピー）
		notice    = notice,         -- 画面内メッセージ
		canReroll = (s.mon or 0) >= 1, -- 既定では 1 文
	})
end

--========================
-- 公開 API
--========================

-- GameInit から注入：状態参照関数と pushState 関数
function Service.init(getStateFn: (Player)->any, pushStateFn: (Player)->())
	Service._getState  = getStateFn
	Service._pushState = pushStateFn

	-- ===== 購入 =====
	BuyItem.OnServerEvent:Connect(function(plr: Player, itemId: string)
		if not canAct(plr) then return end
		local s = Service._getState and Service._getState(plr)
		if not s then return end

		-- ガード：屋台中のみ
		if s.phase ~= "shop" then
			-- もし phase がズレていたら強制的に屋台UIを再度開いて整合
			return openFor(plr, s, { notice = "現在は屋台の時間ではありません（同期し直します）", reward = 0, target = 0 })
		end

		local found
		for _, it in ipairs(((s.shop and s.shop.stock) or {})) do
			if it.id == itemId then found = it; break end
		end
		if not found then
			return openFor(plr, s, { notice = "不明な商品です", reward = 0, target = 0 })
		end

		local price = tonumber(found.price) or 0
		if (s.mon or 0) < price then
			return openFor(plr, s, { notice = "文が足りません", reward = 0, target = 0 })
		end

		-- 先に課金してから効果適用
		s.mon = (s.mon or 0) - price

		-- 効果適用（ShopEffects.apply はメッセージ文字列を返す想定）
		local effectId = found.effect or found.id
		local msg = ""
		if ShopEffects and type(ShopEffects.apply) == "function" then
			msg = ShopEffects.apply(s, effectId) or ""
		end

		-- 状態をクライアントへ反映
		if Service._pushState then Service._pushState(plr) end

		-- 在庫は消費しない（一般的な常設屋台想定）。消費型にしたい場合はここで remove する
		openFor(plr, s, {
			notice = ("購入：%s（-%d 文）\n%s"):format(found.name or found.id, price, msg),
			reward = 0, target = 0
		})
	end)

	-- ===== リロール =====
	ShopReroll.OnServerEvent:Connect(function(plr: Player)
		if not canAct(plr) then return end
		local s = Service._getState and Service._getState(plr)
		if not s then return end

		if s.phase ~= "shop" then
			return openFor(plr, s, { notice = "今はリロールできません（同期し直します）", reward = 0, target = 0 })
		end

		if (s.mon or 0) < 1 then
			return openFor(plr, s, { notice = "リロールには 1 文 必要です", reward = 0, target = 0 })
		end

		s.mon -= 1
		local rng = (s.shop and s.shop.rng) or Random.new(os.time())
		s.shop = s.shop or {}
		s.shop.rng   = rng
		s.shop.stock = rollStock(rng, 6)

		if Service._pushState then Service._pushState(plr) end
		openFor(plr, s, { notice = "品揃えを更新しました（-1 文）", reward = 0, target = 0 })
	end)
end

-- ScoreService などから：屋台を開く（**ここで必ず phase=shop に遷移**）
function Service.open(plr: Player, s: any, opts: {reward:number?, notice:string?, target:number?}?)
	-- s は呼び出し元で取得/更新済み想定。ここで最終的に UI を開く。
	openFor(plr, s, opts)
end

return Service
