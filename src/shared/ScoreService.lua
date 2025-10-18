-- ReplicatedStorage/SharedModules/ScoreService.lua
-- Confirm（勝負）時の獲得計算と、到達時の遷移制御（12か月一直線版）
-- 1–8月：リザルト表示（内訳明示）→OK→屋台
-- 9–11月：2択（こいこい/ホーム）
-- 12月   ：ワンボタンfinal
-- 未達はゲームオーバー（ランリセット）

local RS         = game:GetService("ReplicatedStorage")
local SSS        = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

--===== safe require helpers ============================================
local function reqShared(name)
	local shared = RS:WaitForChild("SharedModules")
	return require(shared:WaitForChild(name))
end

-- 依存
local Scoring  = reqShared("Scoring")
local StateHub = reqShared("StateHub")

-- Balance（次月ゴールの表示用 / ショップ文ノブ参照）
local Balance do
	local ok, mod = pcall(function()
		return require(RS:WaitForChild("Config"):WaitForChild("Balance"))
	end)
	if ok and type(mod)=="table" then
		Balance = mod
	else
		Balance = { getGoalForMonth = function(_) return 1 end }
	end
end

-- SaveService はサーバ専用。クライアントで誤 require されても落ちないように stub 化
local SaveService
do
	if RunService:IsServer() then
		local ok, mod = pcall(function()
			return require(SSS:WaitForChild("SaveService"))
		end)
		if ok and type(mod) == "table" then
			SaveService = mod
		else
			warn("[ScoreService] SaveService not found; using stub")
			SaveService = {
				addBank=function()end, setYear=function()end,
				bumpYear=function()end, bumpClears=function()end,
			}
		end
	else
		-- クライアント側スタブ
		SaveService = {
			addBank=function()end, setYear=function()end,
			bumpYear=function()end, bumpClears=function()end,
		}
	end
end
--=======================================================================

local Score = {}

-- GameInit から注入される：openShop(plr, s, opts)
--   opts = { reward:number?, notice:string?, target:number? }
local openShopFn = nil

-- RoundService 参照（deps から注入。無ければフォールバック require）
local RoundRef = nil

--========================================================================
-- ★ 新：ショップ文リワード計算（内訳＋合計を返す）
--   仕様：基本報酬 + ceil(Mon/分母) + 残リロール加算（場/手） + 追加ボーナス
--   * Mon は「今月の役Mon」（例: 10Mon×7Pts の 10）を使用
--   * 分母は Balance.getShopRyoDivisor(state)（下限クランプあり）
--   * 追加ボーナスは state.effects.shopRyoBonus を想定（無ければ0）
--========================================================================
local function calcShopRyoReward(state, stageMon)
	-- ステージの Mon（例: 10Mon）を因数として使用
	local mon = math.max(0, tonumber(stageMon or 0))

	local base    = (Balance and Balance.SHOP_RYO_BASE) or 5
	local divisor = (Balance and Balance.getShopRyoDivisor and Balance.getShopRyoDivisor(state))
	               or (Balance and Balance.SHOP_RYO_DIVISOR_BASE) or 20

	-- 0 のときだけ 0、それ以外は切り上げで 1 以上
	local addFromStage = (mon <= 0) and 0 or math.ceil(mon / divisor)

	local rerBoard = math.max(0, tonumber(state.rerollFieldLeft or state.rerollBoardLeft or 0))
	local rerHand  = math.max(0, tonumber(state.rerollHandLeft  or 0))
	local addRerB  = rerBoard * ((Balance and Balance.SHOP_RYO_REROLL_BOARD) or 1)
	local addRerH  = rerHand  * ((Balance and Balance.SHOP_RYO_REROLL_HAND)  or 1)

	local addBonus = 0
	if state and state.effects and tonumber(state.effects.shopRyoBonus) then
		addBonus = tonumber(state.effects.shopRyoBonus)
	end

	local total = base + addFromStage + addRerB + addRerH + addBonus
	if total < 0 then total = 0 end

	return {
		-- 表表示用の素材
		base          = base,      baseMult = 1,     baseEarn = base,
		stageMon      = mon,       divisor  = divisor, addFromStage = addFromStage,
		rerollBoard   = rerBoard,  addRerB  = addRerB,
		rerollHand    = rerHand,   addRerH  = addRerH,
		addBonus      = addBonus,
		total         = total,
	}
end
--========================================================================

function Score.bind(Remotes, deps)
	openShopFn = nil
	RoundRef   = nil

	if deps then
		if typeof(deps.openShop) == "function" then
			openShopFn = deps.openShop
		elseif deps.ShopService and typeof(deps.ShopService.open) == "function" then
			openShopFn = deps.ShopService.open
		end
		if deps.Round then
			RoundRef = deps.Round
		end
	end

	if not (Remotes and Remotes.Confirm and typeof(Remotes.Confirm.OnServerEvent) == "RBXScriptSignal") then
		warn("[ScoreService] Remotes.Confirm missing")
		return
	end

	Remotes.Confirm.OnServerEvent:Connect(function(plr)
		local s = StateHub.get(plr)
		if not s or s.phase ~= "play" then return end

		-- 採点
		local takenCards = s.taken or {}
		local total, roles, detail = Scoring.evaluate(takenCards, s)
		local roleMon = (detail and detail.mon) or 0   -- ← 例: 10Mon×7Pts の 10

		-- 役チェイン（役が1つでもあれば伸ばす）
		local roleCount = 0
		for _ in pairs(roles or {}) do
			roleCount += 1
		end
		if roleCount > 0 then
			s.chainCount = (s.chainCount or 0) + 1
		end
		local multNow = StateHub.chainMult(s.chainCount or 0)
		s.mult        = multNow

		-- 早抜けボーナス（山札残り10枚ごとに roleMon 加算）
		local deckLeft   = #(s.deck or {})
		local quickBonus = math.floor(math.max(deckLeft, 0) / 10) * roleMon

		-- 今ターンの獲得・累計
		local gained   = (total or 0) * multNow + quickBonus
		s.seasonSum    = (s.seasonSum or 0) + gained

		-- ▼ 月ゴール（StateHub.goalForMonth を正準とする）
		local tgt       = (StateHub and StateHub.goalForMonth) and StateHub.goalForMonth(s) or 1
		local curMonth  = tonumber(s.run and s.run.month or 1) or 1
		local season    = tonumber(s.season or 1) or 1

		--========================
		-- 未達：ゲームオーバー（ランリセット）
		--========================
		if (s.seasonSum or 0) < tgt then
			if Remotes.StageResult then
				-- 互換：false, sum, target, mult, bank を送る旧経路も維持
				Remotes.StageResult:FireClient(plr, false, s.seasonSum or 0, tgt, s.mult or 1, s.bank or 0)
			end
			local Round = RoundRef or reqShared("RoundService")
			Round.resetRun(plr)
			return
		end

		--========================
		-- 達成時分岐（1–12月）
		--========================

		-- 1) 1〜8月：リザルト表示（内訳明示）→ OK で屋台へ
		if curMonth < 9 then
			s.phase = "result"

			-- 新式で内訳＋合計を計算（Mon=roleMon を使用）
			local rw = calcShopRyoReward(s, roleMon)

			-- 文を確定反映（OK後にショップへ行っても数字は変わらない）
			s.mon = (s.mon or 0) + rw.total

			-- 表示/次遷移用に保存
			s.lastShopReward = rw
			s.lastScore = { total = total or 0, roles = roles, detail = detail }

			StateHub.pushState(plr)

			if Remotes.StageResult then
				local nextM   = math.min(12, curMonth + 1)
				local nextG   = (Balance and Balance.getGoalForMonth) and Balance.getGoalForMonth(nextM) or nil
				local payload = {
					kind        = "shop",             -- ★UI：屋台前リザルト
					titleText   = ("月%d クリア！"):format(curMonth),
					descText    = "獲得文の内訳を確認してください",
					buttonText  = "屋台へ",
					rewardMon   = rw.total,           -- 合計文
					breakdown   = {                   -- 表示用：そのまま描画
						base         = rw.base,
						baseMult     = rw.baseMult,
						baseEarn     = rw.baseEarn,
						stageMon     = rw.stageMon,
						divisor      = rw.divisor,
						addFromStage = rw.addFromStage,
						rerollBoard  = rw.rerollBoard,
						addRerB      = rw.addRerB,
						rerollHand   = rw.rerollHand,
						addRerH      = rw.addRerH,
						addBonus     = rw.addBonus,
					},
					nextMonth   = nextM,
					nextGoal    = nextG,
					lang        = s.lang,
				}
				-- 互換のため true,payload で送る（旧ハンドラも安全）
				Remotes.StageResult:FireClient(plr, true, payload)
			end

			-- 以降の遷移は C→S: Remotes.DecideNext("shop")（NavServer / Round 側で屋台オープン）
			return
		end

		-- 2) 9〜11月：2両付与 → 2択モーダル（こいこい/ホーム）
		if curMonth >= 9 and curMonth <= 11 then
			s.phase = "result"

			-- 2両ボーナス
			local rewardBank = 2
			s.bank = (s.bank or 0) + rewardBank
			if typeof(SaveService.addBank) == "function" then
				SaveService.addBank(plr, rewardBank)
			end

			s.lastScore = { total = total or 0, roles = roles, detail = detail }
			StateHub.pushState(plr)

			if Remotes.StageResult then
				local nextM   = math.min(12, curMonth + 1)
				local nextG   = (Balance and Balance.getGoalForMonth) and Balance.getGoalForMonth(nextM) or nil
				local payload = {
					kind        = "two",             -- UI：2択モーダル
					rewardBank  = rewardBank,        -- +2両
					nextMonth   = nextM,             -- こいこい先
					nextGoal    = nextG,             -- その目標
					message     = ("クリアおめでとう！ +%d両"):format(rewardBank),
					lang        = s.lang,
				}
				Remotes.StageResult:FireClient(plr, true, payload)
			end
			return
		end

		-- 3) 12月：2両付与 → ワンボタン（final）で終了へ
		--    ※ クリア回数(totalClears)は“ラン完走”のこのタイミングだけで +1 する
		if curMonth >= 12 then
			s.phase = "result"

			-- 2両ボーナス
			local rewardBank = 2
			s.bank = (s.bank or 0) + rewardBank
			if typeof(SaveService.addBank) == "function" then
				SaveService.addBank(plr, rewardBank)
			end

			-- クリア回数（完走）+1
			s.totalClears = (s.totalClears or 0) + 1
			if typeof(SaveService.bumpClears) == "function" then
				SaveService.bumpClears(plr, 1)
			end

			s.lastScore = { total = total or 0, roles = roles, detail = detail }
			StateHub.pushState(plr)

			if Remotes.StageResult then
				local payload = {
					kind        = "final",               -- UI：ワンボタン
					titleText   = "12月 クリアおめでとう！",
					descText    = "このランは終了です。メニューに戻ります。",
					buttonText  = "ホームへ",
					rewardBank  = rewardBank,
					lang        = s.lang,
				}
				Remotes.StageResult:FireClient(plr, true, payload)
			end
			-- 以降の遷移は C→S: Remotes.DecideNext("home"|"koikoi")
			return
		end
	end)
end

return Score
