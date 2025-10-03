-- ReplicatedStorage/SharedModules/ScoreService.lua
-- Confirm（勝負）時の獲得計算と、到達時の遷移制御（12か月一直線版）
-- 1–8月 達成→屋台 / 9–11月 達成→2択（こいこい/ホーム） / 12月 達成→ワンボタンfinal
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

-- Balance（次月ゴールの表示用）
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
			-- サーバでも見つからない場合は安全スタブ
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

-- 文（mon）リワード計算（従来ロジック維持）
local function calcMonReward(sum, target, season)
	-- 目標値は現在使用しないが将来の調整余地として残す
	local _ = target
	local factor = 0.20 + ((season or 1) - 1) * 0.05
	return math.max(1, math.floor((sum or 0) * factor))
end

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
		if (s.handsLeft or 0) <= 0 then return end

		-- 採点
		local takenCards = s.taken or {}
		local total, roles, detail = Scoring.evaluate(takenCards, s)
		local roleMon = (detail and detail.mon) or 0

		-- 役チェイン
		local roleCount = 0
		for _ in pairs(roles or {}) do
			roleCount += 1
		end
		if roleCount > 0 then
			s.chainCount = (s.chainCount or 0) + 1
		end

		local multNow    = StateHub.chainMult(s.chainCount or 0)
		s.mult           = multNow

		-- 早抜けボーナス
		local deckLeft   = #(s.deck or {})
		local quickBonus = math.floor(math.max(deckLeft, 0) / 10) * roleMon

		-- 今ターンの獲得
		local gained  = (total or 0) * multNow + quickBonus
		s.seasonSum   = (s.seasonSum or 0) + gained
		s.handsLeft   = (s.handsLeft or 0) - 1

		-- ▼ 月ゴール（数値）— StateHub で Balance を咬ませた値
		local tgt = (StateHub and StateHub.goalForMonth) and StateHub.goalForMonth(s) or 1
		local curMonth = tonumber(s.run and s.run.month or 1) or 1
		local season   = tonumber(s.season or 1) or 1

		--========================
		-- 未達：手が尽きたら失敗、まだなら続行
		--========================
		if (s.seasonSum or 0) < tgt then
			if (s.handsLeft or 0) <= 0 then
				-- 失敗：ゲームオーバー（ランリセット）
				if Remotes.StageResult then
					-- 互換：false, sum, target, mult, bank を送る旧経路も維持
					Remotes.StageResult:FireClient(plr, false, s.seasonSum or 0, tgt, s.mult or 1, s.bank or 0)
				end
				local Round = RoundRef or reqShared("RoundService")
				Round.resetRun(plr)
			else
				-- 続行
				StateHub.pushState(plr)
			end
			return
		end

		--========================
		-- 達成時分岐（1–12月）
		--========================

		-- 1) 1〜8月：屋台へ（文を付与）
		if curMonth < 9 then
			s.phase = "shop"
			local rewardMon = calcMonReward(s.seasonSum or 0, tgt, season)
			s.mon = (s.mon or 0) + rewardMon
			if openShopFn then
				openShopFn(plr, s, { reward = rewardMon, notice = "達成！", target = tgt })
			else
				StateHub.pushState(plr)
			end
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
				-- 互換のため true,payload で送る（旧ハンドラも安全）
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
			-- 以降の遷移は C→S: Remotes.DecideNext("home"|"koikoi")（NavServer が唯一線）
			return
		end
	end)
end

return Score
