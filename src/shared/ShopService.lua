-- ServerScriptService/ShopService.lua
-- v0.9.2d 屋台サービス（SIMPLE+NONCE + Talisman payload）
-- 変更点（d）:
--  - ★ ShopEffects.apply へ必ず ctx.player を付与（UI系効果の必須引数漏れを修正）
--  - ★ KITO の UI 経路を拡張：酉/巳 に加えて 卯/午/戌/亥 も KitoPick に統一
--  - ★ toCanonicalEffectId を拡張（kito_* / Module名 を正規 effectId へ統一変換）
--
-- 既存（c）からの変更点は上記のみ。その他の仕様は従来通り。
--  - リロールは回数無制限・費用1文（残回数概念は撤去済み）
--  - 在庫は満杯でも必ず強制再生成
--  - SaveService のスナップ対応は従来どおり（存在しなくても続行）
--  - ShopEffects ローダー復活済み
--  - ★ リロール多重送出防止: クライアントnonceをサーバで検証（TTL付き）
--  - ★ P1-3: Logger 導入（print/warn を LOG.* に置換）
--  - ★ v0.9.2c: ShopOpen ペイロードに talisman を同梱（state.run.talisman をそのまま搭載）
--               ※補完/推測は一切しない（真実は TalismanService/StateHub が管理）
--  - ★ KITO（酉/巳 など）を UI 経路に統一（正規effectIdへ正規化して KitoPickCore へ移譲）

local RS   = game:GetService("ReplicatedStorage")
local SSS  = game:GetService("ServerScriptService")
local Http = game:GetService("HttpService")

-- Logger
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("ShopService")

local Remotes    = RS:WaitForChild("Remotes")
local ShopOpen   = Remotes:WaitForChild("ShopOpen")
local BuyItem    = Remotes:WaitForChild("BuyItem")
local ShopReroll = Remotes:WaitForChild("ShopReroll")

-- ★ UI分岐用の Balance と、候補通知 Remote（RemotesInit で生成済みを待つ）
local Balance       = require(RS:WaitForChild("Config"):WaitForChild("Balance"))
local SharedModules = RS:WaitForChild("SharedModules")
local ShopDefs      = require(SharedModules:WaitForChild("ShopDefs"))

-- ★ RunDeckUtil（安全ロード／無ければ nil）
local RunDeckUtil do
	local ok, mod = pcall(function()
		return require(SharedModules:WaitForChild("RunDeckUtil"))
	end)
	if ok then
		RunDeckUtil = mod
	else
		RunDeckUtil = nil
		LOG.warn("RunDeckUtil not available; deck snapshot/matsuri logs will be limited.")
	end
end

-- ★ 候補生成/送信の一元管理（セッション保持含む）
local KitoPickCore  = require(SSS:WaitForChild("KitoPickCore"))

-- ★ 護符の正本はサーバ一元管理（不足キー補完のみ）
local TaliService   = require(SSS:WaitForChild("TalismanService"))

-- ★ SaveService（存在しなくてもゲームは動作継続）
local SaveService do
	local ok, mod = pcall(function() return require(SSS:WaitForChild("SaveService")) end)
	if ok then
		SaveService = mod
	else
		LOG.warn("SaveService not available; shop snapshots will be skipped.")
		SaveService = nil
	end
end

--========================
-- 設定
--========================
local MAX_STOCK   = 6   -- 並べる最大数
local REROLL_COST = 1   -- リロール費用

--========================
-- nonce（リロール多重送出防止）
--========================
local REROLL_NONCE_TTL = 120 -- 秒（メモリ掃除用）
local rerollNonceByUser: {[number]: {[string]: number}} = {}

local function pruneNonces(userId: number, now: number)
	local box = rerollNonceByUser[userId]
	if not box then return end
	for n, t in pairs(box) do
		if (now - (t or 0)) > REROLL_NONCE_TTL then
			box[n] = nil
		end
	end
end

local function checkAndAddNonce(userId: number, nonce: string?): boolean
	-- レガシー互換: nonce が無い場合は許容（必要なら false にして強制）
	if type(nonce) ~= "string" or nonce == "" then
		return true
	end
	local now = os.time()
	pruneNonces(userId, now)
	local box = rerollNonceByUser[userId]
	if not box then
		box = {}
		rerollNonceByUser[userId] = box
	end
	if box[nonce] then
		return false
	end
	box[nonce] = now
	return true
end

-- 置換後（★ run.id を唯一源泉に）
local function ensureRunId(state:any): string
	state.run = state.run or {}
	local id = state.run.id
	if type(id) ~= "string" or id == "" then
		id = Http:GenerateGUID(false)
		state.run.id = id
	end
	return id
end

--========================
-- KITO: ID 正規化 & ラベル
--========================
local function toCanonicalEffectId(eid: string?): string
	if type(eid) ~= "string" or eid == "" then return "" end

	-- 既存
	if eid == "kito_tori" or eid == "Tori_Brighten" then return "kito.tori_brighten" end
	if eid == "kito_mi"   or eid == "Mi_Venom"      then return "kito.mi_venom"      end

	-- ★ 追加（卯/午/戌/亥）
	if eid == "kito_usagi" or eid == "Usagi_Ribbonize" then return "kito.usagi_ribbon"   end
	if eid == "kito_uma"   or eid == "Uma_Seedize"     then return "kito.uma_seed"       end
	-- Inu は別名2種を同一に扱う
	if eid == "kito_inu"   or eid == "Inu_Chaff2" or eid == "kito.inu_chaff2" then
		return "kito.inu_two_chaff"
	end
	if eid == "kito_i"     or eid == "I_Sakeify"       then return "kito.i_sake"         end

	return eid
end

local function kitoLabel(eid: string?): string
	local id = toCanonicalEffectId(eid)
	if id == "kito.tori_brighten" then return "酉" end
	if id == "kito.mi_venom"      then return "巳" end
	if id == "kito.usagi_ribbon"  then return "卯" end
	if id == "kito.uma_seed"      then return "午" end
	if id == "kito.inu_two_chaff" then return "戌" end
	if id == "kito.i_sake"        then return "亥" end
	return "KITO"
end

-- ★ どの Kito が「選択 UI（KitoPick）」必須か
local SELECT_KITO: {[string]: boolean} = {
	["kito.tori_brighten"] = true,
	["kito.mi_venom"]      = true,
	["kito.usagi_ribbon"]  = true,
	["kito.uma_seed"]      = true,
	["kito.inu_two_chaff"] = true,
	["kito.i_sake"]        = true,
	-- 別名も保険で許容
	["kito.inu_chaff2"]    = true,
}

local function requiresKitoPick(canonical: string): boolean
	return SELECT_KITO[canonical] == true
end

--========================
-- ログ支援
--========================
local function j(v)
	local ok, res = pcall(function() return Http:JSONEncode(v) end)
	return ok and res or tostring(v)
end

local function matsuriJSON(state)
	-- RunDeckUtil が無い場合は {} を返す（ログ用途のため挙動非影響）
	if RunDeckUtil and typeof(RunDeckUtil.getMatsuriLevels) == "function" then
		local levels = RunDeckUtil.getMatsuriLevels(state)
		return j(levels or {})
	end
	return j({})
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

--========================
-- スナップ保存（屋台シーン用）
--========================
local function snapShop(plr: Player, s: any)
	if not SaveService or not SaveService.snapShopEnter then return end
	pcall(function() SaveService.snapShopEnter(plr, s) end)
end

--========================
-- 効果ローダー
--========================
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
		LOG.info("ShopEffects loaded OK")
	else
		LOG.warn("ShopEffects missing/invalid | ok=%s err=%s", tostring(ok), tostring(mod))
		ShopEffects = nil
	end
end

--========================
-- 在庫生成
--========================
local function rollCategory(rng: Random)
	local weights = ShopDefs.WEIGHTS or {}
	local total = 0
	for _, w in pairs(weights) do total += (w or 0) end
	if total <= 0 then return "kito" end
	local r, acc = rng:NextNumber(0, total), 0
	for cat, w in pairs(weights) do
		acc += (w or 0)
		if r <= acc then return cat end
	end
	return "kito"
end

local function generateStock(rng: Random, count: number)
	local items = {}
	local pools = ShopDefs.POOLS or {}
	for _=1, count do
		local cat  = rollCategory(rng)
		local pool = pools[cat]
		if pool and #pool > 0 then
			table.insert(items, table.clone(pool[rng:NextInteger(1, #pool)]))
		end
	end
	-- フィッシャー–イェーツシャッフル
	for i = #items, 2, -1 do
		local jx = rng:NextInteger(1, i)
		items[i], items[jx] = items[jx], items[i]
	end
	return items
end

--========================
-- talisman 抽出（整形/補完はしない）
--========================
local function readRunTalisman(s:any)
	if type(s) ~= "table" then return nil end
	if type(s.run) == "table" and type(s.run.talisman) == "table" then
		return s.run.talisman
	end
	return nil
end

--========================
-- 本体
--========================
local Service = { _getState=nil, _pushState=nil }

-- ========= open =========
local function openFor(plr: Player, s: any, opts: {reward:number?, notice:string?, target:number?}?)
	-- 開店直前に、正本の talisman を必ず準備（不足キーのみ補う）
	pcall(function() TaliService.ensureFor(plr, "ShopOpen") end)

	s.phase = "shop"
	s.shop = s.shop or {}
	s.shop.rng = s.shop.rng or Random.new(os.clock()*1000000)

	-- 初回オープン時：在庫が無ければ MAX_STOCK で生成
	if not s.shop.stock then
		s.shop.stock = generateStock(s.shop.rng, MAX_STOCK)
	end

	local reward = (opts and opts.reward) or 0
	local notice = (opts and opts.notice) or ""
	local target = (opts and opts.target) or 0
	local money  = tonumber(s.mon or 0) or 0

	-- ★ RunDeckUtil が読めない環境でも nil 許容
	local deckView = nil
	if RunDeckUtil and typeof(RunDeckUtil.snapshot) == "function" then
		deckView = RunDeckUtil.snapshot(s)
	end

	-- ★ talisman は state.run.talisman を“そのまま”搭載（補完や推測はしない）
	local tali = readRunTalisman(s)

	-- ===== LOG =====
	LOG.info(
		"[OPEN] u=%s season=%s mon=%d rerollCost=%d matsuri=%s stock=%s notice=%s talisman#=%s",
		tostring(plr and plr.Name or "?"),
		tostring(s.season), money, REROLL_COST,
		matsuriJSON(s), stockBrief(s.shop.stock),
		(notice ~= "" and notice) or "",
		tostring(type(tali)=="table" and #(tali.slots or {}) or 0)
	)

	-- 入場スナップ
	snapShop(plr, s)

	ShopOpen:FireClient(plr, {
		season       = s.season,
		target       = target,
		seasonSum    = s.seasonSum or 0,
		rewardMon    = reward,
		totalMon     = money,
		mon          = money,              -- 互換（クライアントは mon/totalMon のどちらでも読める）
		stock        = s.shop.stock,
		items        = s.shop.stock,       -- 互換
		notice       = notice,
		rerollCost   = REROLL_COST,
		canReroll    = money >= REROLL_COST,
		currentDeck  = deckView,

		-- UI支援（参照していれば活用 / 不要ならクライアント側で無視）
		maxStock     = MAX_STOCK,
		stockCount   = #(s.shop.stock or {}),

		-- ★ 護符データ（nil 許容、上書き/補完なし）
		talisman     = tali,

		-- 互換用：State を抱えておく（ShopScreen が state.run.talisman を参照できるように）
		state = {
			run = { talisman = tali },
			lang = s.lang,
		},
	})
end

function Service.init(getStateFn: (Player)->any, pushStateFn: (Player)->())
	Service._getState  = getStateFn
	Service._pushState = pushStateFn
	LOG.info("init OK")

	-- 購入
	BuyItem.OnServerEvent:Connect(function(plr: Player, itemId: string)
		local s = Service._getState and Service._getState(plr)
		if not s then return end
		if s.phase ~= "shop" then
			return openFor(plr, s, { notice="現在は屋台の時間ではありません（同期します）" })
		end

		-- ===== pre-search =====
		LOG.debug(
			"[BUY][REQ] u=%s itemId=%s mon(before)=%d stock=%s matsuri(before)=%s",
			tostring(plr and plr.Name or "?"),
			tostring(itemId), tonumber(s.mon or 0),
			stockBrief(s.shop and s.shop.stock), matsuriJSON(s)
		)

		local foundIndex, found
		for i, it in ipairs(((s.shop and s.shop.stock) or {})) do
			if it.id == itemId then foundIndex = i; found = it; break end
		end
		if not found then
			LOG.warn("[BUY][ERR] not found: %s", tostring(itemId))
			return openFor(plr, s, { notice="不明な商品です" })
		end
		local price = tonumber(found.price) or 0
		if (s.mon or 0) < price then
			LOG.warn("[BUY][ERR] mon short: need=%d have=%d", price, tonumber(s.mon or 0))
			return openFor(plr, s, { notice=("文が足りません（必要:%d）"):format(price) })
		end

		-- ★ 安全代入で請求
		s.mon = (s.mon or 0) - price

		-- ===== before effect =====
		LOG.info(
			"[BUY][DO] item=%s(%s) price=%d mon(after charge)=%d effect=%s",
			found.name or found.id, tostring(found.category), price, tonumber(s.mon or 0),
			tostring(found.effect or found.id)
		)

		-- ★ UI 分岐：KITO は「選択が必要なもの」を KitoPick に送る
		if Balance.KITO_UI_ENABLED == true and (found.category == "kito") then
			local canonical = toCanonicalEffectId(found.effect or found.id)
			if requiresKitoPick(canonical) then
				-- 在庫を減らして保存（購入は完了）
				if s.shop and s.shop.stock and foundIndex then
					table.remove(s.shop.stock, foundIndex)
				end
				if Service._pushState then Service._pushState(plr) end
				snapShop(plr, s)

				ensureRunId(s)
				local started = false
				if canonical ~= "" then
					started = KitoPickCore.startFor(plr, s, canonical)
				else
					LOG.warn("[BUY][WARN] KITO item without effect id: %s", tostring(found.id))
				end

				local prefix = kitoLabel(canonical)
				local uiMsg = started and (prefix.."：対象を選んでください（候補を表示中…）")
									or  (prefix.."：選択候補が用意できませんでした")

				LOG.info("[BUY][RES] ok=true msg=%s matsuri(after)=%s", uiMsg, matsuriJSON(s))
				openFor(plr, s, { notice=("購入：%s（-%d 文）\n%s"):format(found.name or found.id, price, uiMsg) })
				return
			end
			-- ※ 選択不要の KITO はこの if を抜けて従来 apply フローへ
		end
		-- ★ 分岐ここまで（UI OFF なら従来どおり効果適用へ）

		local effOk, effMsg = true, ""
		if ShopEffects then
			local okCall, okRet, msgRet = pcall(function()
				return ShopEffects.apply(found.effect or found.id, s, {
					-- ★必須: UI系効果は ctx.player を要求する
					player   = plr,
					-- 互換キー（古いコードが読む場合用）
					plr      = plr,

					lang     = (s.lang or "ja"),
					rng      = (s.shop and s.shop.rng) or Random.new(),
					price    = price,
					category = found.category,
					now      = os.time(),
					source   = "ShopService.BUY",
				})
			end)
			if not okCall then
				effOk, effMsg = false, ("効果適用エラー: %s"):format(tostring(okRet))
				LOG.warn("effect threw: %s", tostring(okRet))
			else
				effOk, effMsg = okRet, msgRet
			end
		else
			effOk, effMsg = false, "効果モジュール未ロード"
		end

		-- ===== after effect =====
		LOG.info("[BUY][RES] ok=%s msg=%s matsuri(after)=%s", tostring(effOk), tostring(effMsg or ""), matsuriJSON(s))

		if not effOk then
			-- ロールバックも安全代入
			s.mon = (s.mon or 0) + price
			if Service._pushState then Service._pushState(plr) end
			LOG.warn("[BUY][ROLLBACK] price=%d mon=%d", price, tonumber(s.mon or 0))
			return openFor(plr, s, { notice=("購入失敗：%s（返金）\n%s"):format(found.name or found.id, tostring(effMsg or "")) })
		end

		if s.shop and s.shop.stock and foundIndex then
			table.remove(s.shop.stock, foundIndex)
		end

		if Service._pushState then Service._pushState(plr) end

		-- 購入成功時点スナップ
		snapShop(plr, s)

		-- ===== final =====
		LOG.info("[BUY][OK] item=%s mon=%d stock(after)=%s", found.name or found.id, tonumber(s.mon or 0), stockBrief(s.shop and s.shop.stock))

		openFor(plr, s, { notice=("購入：%s（-%d 文）\n%s"):format(found.name or found.id, price, tostring(effMsg or "")) })
	end)

	-- リロール：回数制限なし／費用=REROLL_COST（★満杯でも常に再抽選）
	ShopReroll.OnServerEvent:Connect(function(plr: Player, nonce: any)
		-- ★ nonce 検証（重複は黙って無視）
		local nonceStr = (typeof(nonce) == "string") and nonce or tostring(nonce or "")
		if not checkAndAddNonce(plr.UserId, nonceStr) then
			LOG.debug("[REROLL][IGNORED] duplicate nonce from %s", plr.Name)
			return
		end

		local s = Service._getState and Service._getState(plr)
		if not s then return end
		if s.phase ~= "shop" then
			return openFor(plr, s, { notice="今はリロールできません（同期します）" })
		end
		if (s.mon or 0) < REROLL_COST then
			LOG.warn("[REROLL][ERR] mon short: need=%d have=%d", REROLL_COST, tonumber(s.mon or 0))
			return openFor(plr, s, { notice=("リロールには %d 文が必要です"):format(REROLL_COST) })
		end

		-- ★ 請求
		s.mon = (s.mon or 0) - REROLL_COST

		-- ★ 満杯かどうかに関係なく「強制再生成」
		local rng = (s.shop and s.shop.rng) or Random.new(os.clock()*1000000)
		s.shop = s.shop or {}
		s.shop.rng   = rng
		s.shop.stock = generateStock(rng, MAX_STOCK)

		if Service._pushState then Service._pushState(plr) end

		-- リロール後スナップ
		snapShop(plr, s)

		-- ===== LOG =====
		LOG.info(
			"[REROLL][OK] u=%s mon=%d cost=%d stock(after)=%s matsuri=%s",
			tostring(plr and plr.Name or "?"), tonumber(s.mon or 0),
			REROLL_COST, stockBrief(s.shop.stock), matsuriJSON(s)
		)

		openFor(plr, s, { notice=("品揃えを更新しました（-%d 文）"):format(REROLL_COST) })
	end)
end

function Service.open(plr: Player, s: any, opts: {reward:number?, notice:string?, target:number?}?)
	openFor(plr, s, opts)
end

return Service
