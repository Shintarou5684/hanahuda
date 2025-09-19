-- ReplicatedStorage/SharedModules/ScoreService.lua
-- Confirm（勝負）時の獲得計算と、到達時の遷移制御（春〜秋＝屋台／冬＝分岐）

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

-- ▼ 開発トグル：二択固定（保存を出さない）＋「次」は常にロック表示
local DEV_LOCK_NEXT          = true   -- true の間は canNext=false 固定
local REMOVE_SAVE_BUTTON     = true   -- true なら保存ボタンを送らない（UI二択）

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

		local season  = tonumber(s.season or 1) or 1
		local tgt     = StateHub.targetForSeason(season)

		-- 未達：手が尽きたら失敗、まだなら続行
		if (s.seasonSum or 0) < tgt then
			if (s.handsLeft or 0) <= 0 then
				if Remotes.StageResult then
					-- 失敗パス（UI側は true & table のみ表示する想定）
					Remotes.StageResult:FireClient(plr, false, s.seasonSum or 0, tgt, s.mult or 1, s.bank or 0)
				end
				local Round = RoundRef or reqShared("RoundService")
				Round.resetRun(plr)
			else
				StateHub.pushState(plr)
			end
			return
		end

		-- ===== 達成：春〜秋は屋台へ =====
		if season < 4 then
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

		-- ===== 冬：クリア分岐 =====
		s.phase = "result"

		-- クリア回数（メモリ）
		s.totalClears = (s.totalClears or 0) + 1
		-- ★ 永続にも反映（存在すれば）
		if typeof(SaveService.bumpClears) == "function" then
			SaveService.bumpClears(plr, 1)
		end

		-- 2両ボーナス（メモリ＋永続）
		local rewardBank = 2
		s.bank = (s.bank or 0) + rewardBank
		if typeof(SaveService.addBank) == "function" then
			SaveService.addBank(plr, rewardBank)
		end

		s.lastScore = { total = total or 0, roles = roles, detail = detail }
		StateHub.pushState(plr)

		-- 旧仕様の解禁判定（参照のみ・ログ用）
		local clears   = tonumber(s.totalClears or 0) or 0
		local unlocked_by_clears = (clears >= 3)
		local canNextFinal = (not DEV_LOCK_NEXT) and unlocked_by_clears or false
		local canSaveFinal = false -- 常に保存は無効（ボタン非表示）

		-- DEBUG: 冬クリア時点のサマリ
		print(("[Score] winter clear by %s | clears=%d unlocked=%s season=%s sum=%d target=%d bank=%d")
			:format(
				plr.Name,
				clears,
				tostring(unlocked_by_clears),
				tostring(season),
				s.seasonSum or 0,
				tgt or 0,
				s.bank or 0
			))

		if Remotes.StageResult then
			-- ▼ レガシー（options）と正準（ops）を送る
			local optsLegacy = {
				goHome = { enabled = true,  label = "このランを終える" },
				goNext = { enabled = canNextFinal, label = canNextFinal and "次のステージへ" or "次のステージへ（開発中）" },
			}
			-- 保存ボタンは送らない（UI二択）。どうしてもキーが必要なUIなら以下を有効化して enabled=false で送る
			if not REMOVE_SAVE_BUTTON then
				optsLegacy.saveQuit = { enabled = false, label = "保存する（無効）" }
			end

			local ops = {
				home = optsLegacy.goHome,
				next = optsLegacy.goNext,
			}
			-- save は送らない

			local payload = {
				season      = season,
				seasonSum   = s.seasonSum or 0,
				target      = tgt,
				mult        = s.mult or 1,
				bank        = s.bank or 0,
				rewardBank  = rewardBank,
				bankAdded   = rewardBank,
				clears      = clears,

				-- ▼ UI がこの2フラグを見て分岐する旧実装にも対応
				canNext     = canNextFinal,   -- ← 開発中は常に false
				canSave     = canSaveFinal,   -- ← 常に false（保存ボタン出さない）

				message     = (canNextFinal and "冬をクリア！ 2両を獲得。『次のステージ』が解禁済み。") or
				              "冬をクリア！ 2両を獲得。『次のステージ』は開発中です。",

				options     = optsLegacy, -- 互換（レガシーUI）
				ops         = ops,        -- 正準（Nav: next('home'|'next')のみ想定）
				locks       = { nextLocked = not canNextFinal, saveLocked = true },
				lang        = s.lang,
			}

			print(("[Score] StageResult payload: canNext=%s canSave=%s")
				:format(tostring(payload.canNext), tostring(payload.canSave)))

			Remotes.StageResult:FireClient(plr, true, payload)
		end
		-- 以降の遷移は C→S: Remotes.DecideNext("home"|"next") （NavServer が唯一線）
	end)
end

return Score
