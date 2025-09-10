-- ReplicatedStorage/SharedModules/ScoreService.lua (ModuleScript)
-- Confirm（勝負）時の獲得計算と、到達時の遷移制御（春〜秋＝屋台／冬＝分岐）

local RS       = game:GetService("ReplicatedStorage")
local SSS      = game:GetService("ServerScriptService")

local Scoring  = require(RS.SharedModules.Scoring)
local StateHub = require(RS.SharedModules.StateHub)

-- DataStore最小実装（bank/year/asc）
local SaveService = require(SSS:WaitForChild("SaveService"))

local Score = {}

-- GameInit から注入される：openShop(plr, s, opts)
--   opts = { reward:number?, notice:string?, target:number? }
local openShopFn ---@type fun(plr: Player, s: any, opts: {reward:number?, notice:string?, target:number?}?)|nil = nil

local function calcMonReward(sum:number, target:number, season:number)
	local factor = 0.20 + ((season or 1) - 1) * 0.05
	return math.max(1, math.floor((sum or 0) * factor))
end

function Score.bind(Remotes, deps)
	openShopFn = nil
	if deps then
		if typeof(deps.openShop) == "function" then
			openShopFn = deps.openShop
		elseif deps.ShopService and typeof(deps.ShopService.open) == "function" then
			openShopFn = deps.ShopService.open
		end
	end

	Remotes.Confirm.OnServerEvent:Connect(function(plr: Player)
		local s = StateHub.get(plr); if not s or s.phase ~= "play" then return end
		if (s.handsLeft or 0) <= 0 then return end

		-- 採点
		local takenCards = s.taken or {}
		local total, roles, detail = Scoring.evaluate(takenCards, s)
		local roleMon = (detail and detail.mon) or 0

		-- 役チェイン
		local roleCount = 0; for _ in pairs(roles or {}) do roleCount += 1 end
		if roleCount > 0 then s.chainCount = (s.chainCount or 0) + 1 end

		local multNow    = StateHub.chainMult(s.chainCount or 0)
		s.mult = multNow

		-- 早抜けボーナス（山の残りに応じた簡易ボーナス）
		local deckLeft   = #(s.deck or {})
		local quickBonus = math.floor(math.max(deckLeft, 0) / 10) * roleMon

		-- 今ターンの獲得
		local gained = (total or 0) * multNow + quickBonus
		s.seasonSum  = (s.seasonSum or 0) + gained
		s.handsLeft  = (s.handsLeft or 0) - 1

		local season = tonumber(s.season or 1)
		local tgt    = StateHub.targetForSeason(season)

		-- 未達：手が尽きたら失敗、まだなら続行
		if (s.seasonSum or 0) < tgt then
			if (s.handsLeft or 0) <= 0 then
				if Remotes.StageResult then
					-- 失敗パス（UI側は true & table のみ表示する想定）
					Remotes.StageResult:FireClient(plr, false, s.seasonSum or 0, tgt, s.mult or 1, s.bank or 0)
				end
				local Round = require(RS.SharedModules.RoundService)
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
		SaveService.addBank(plr, rewardBank)

		s.lastScore = { total = total or 0, roles = roles, detail = detail }
		StateHub.pushState(plr)

		-- ★ アンロック判定：通算クリア回数 >= 3
		local clears   = tonumber(s.totalClears or 0) or 0
		local unlocked = clears >= 3

		-- ★★ DEBUG: 冬クリア時点のサマリ（解禁判定を可視化）
		print(("[Score] winter clear by %s | clears=%d unlocked=%s season=%s sum=%d target=%d bank=%d")
			:format(
				plr.Name,
				clears,
				tostring(unlocked),
				tostring(season),
				s.seasonSum or 0,
				tgt or 0,
				s.bank or 0
			))

		if Remotes.StageResult then
			-- 送信ペイロードを組み立て（ログのため一度変数へ）
			local payload = {
				season      = season,
				seasonSum   = s.seasonSum or 0,
				target      = tgt,
				mult        = s.mult or 1,
				bank        = s.bank or 0,
				rewardBank  = rewardBank,
				bankAdded   = rewardBank,
				canNext     = unlocked,
				canSave     = unlocked,
				clears      = clears,  -- UI表示用（「通算◯回クリア」）
				message     = unlocked and
					("冬をクリア！ 2両を獲得。『次のステージ／セーブ』が解禁済み（通算"..clears.."回クリア）") or
					("冬をクリア！ 2両を獲得。『次のステージ／セーブ』は通算3回クリアで解禁（現在"..clears.."回）"),
				options = {
					goHome   = { enabled = true,     label = "トップへ戻る" },
					goNext   = { enabled = unlocked, label = unlocked and "次のステージへ" or "次のステージへ（ロック中）" },
					saveQuit = { enabled = unlocked, label = unlocked and "セーブして終了" or "セーブして終了（ロック中）" },
				}
			}

			-- ★★ DEBUG: 実際に送る解禁フラグ
			print(("[Score] StageResult payload: canNext=%s canSave=%s")
				:format(tostring(payload.canNext), tostring(payload.canSave)))

			Remotes.StageResult:FireClient(plr, true, payload)
		end
		-- 以降の遷移は C→S: Remotes.DecideNext("home"|"next"|"save")
	end)
end

return Score
