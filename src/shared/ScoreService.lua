-- ReplicatedStorage/SharedModules/ScoreService.lua (ModuleScript)
-- Confirm（勝負）時の獲得計算と、到達時の遷移制御（春〜秋＝屋台／冬＝分岐）

local RS       = game:GetService("ReplicatedStorage")
local SSS      = game:GetService("ServerScriptService")

local Scoring  = require(RS.SharedModules.Scoring)
local StateHub = require(RS.SharedModules.StateHub)

-- DataStore最小実装（bank/year）
local SaveService = require(SSS:WaitForChild("SaveService"))

local Score = {}

-- GameInit から注入される：openShop(plr, s, opts)
local openShopFn : ((Player, any, {reward:number?, notice:string?, target:number?}?) -> ())? = nil

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

		local total, roles, detail = Scoring.evaluate(s.taken or {})
		local roleMon = (detail and detail.mon) or 0

		local roleCount = 0; for _ in pairs(roles or {}) do roleCount += 1 end
		if roleCount > 0 then s.chainCount = (s.chainCount or 0) + 1 end

		local multNow    = StateHub.chainMult(s.chainCount or 0)
		s.mult = multNow
		local deckLeft   = #(s.deck or {})
		local quickBonus = math.floor(math.max(deckLeft, 0) / 10) * roleMon

		local gained = (total or 0) * multNow + quickBonus
		s.seasonSum  = (s.seasonSum or 0) + gained
		s.handsLeft  = (s.handsLeft or 0) - 1

		local season = tonumber(s.season or 1)
		local tgt    = StateHub.targetForSeason(season)

		if (s.seasonSum or 0) < tgt then
			if (s.handsLeft or 0) <= 0 then
				if Remotes.StageResult then
					Remotes.StageResult:FireClient(plr, false, s.seasonSum or 0, tgt, s.mult or 1, s.bank or 0)
				end
				local Round = require(RS.SharedModules.RoundService)
				Round.resetRun(plr)
			else
				StateHub.pushState(plr)
			end
			return
		end

		-- 春〜秋は屋台へ
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

		-- 2両ボーナス（メモリ＋永続）
		local rewardBank = 2
		s.bank = (s.bank or 0) + rewardBank
		SaveService.addBank(plr, rewardBank)

		s.lastScore = { total = total or 0, roles = roles, detail = detail }
		StateHub.pushState(plr)

		-- ★ アンロック判定：帰宅回数が3回以上で Next/Save を解禁
		local homeCount = tonumber(s.homeCount or 0) or 0
		local unlocked  = homeCount >= 3

		if Remotes.StageResult then
			Remotes.StageResult:FireClient(plr, true, {
				season      = season,
				seasonSum   = s.seasonSum or 0,
				target      = tgt,
				mult        = s.mult or 1,
				bank        = s.bank or 0,
				rewardBank  = rewardBank,
				bankAdded   = rewardBank,
				canNext     = unlocked,      -- ★ ここを homeCount ベースに
				canSave     = unlocked,      -- ★ 同上
				homeCount   = homeCount,     -- （UIで進捗表示したい場合に使用可）
				message     = unlocked and
					("冬をクリア！ 2両を獲得しました。次のステージ/セーブが解禁済み（帰宅"..homeCount.."回）") or
					("冬をクリア！ 2両を獲得しました。次のステージ/セーブは『帰宅3回』で解禁（現在"..homeCount.."回）"),
				options = { -- 旧互換
					goHome   = { enabled = true,        label = "トップへ戻る" },
					goNext   = { enabled = unlocked,    label = unlocked and "次のステージへ" or "次のステージへ（ロック中）" },
					saveQuit = { enabled = unlocked,    label = unlocked and "セーブして終了" or "セーブして終了（ロック中）" },
				}
			})
		end
		-- 以降の遷移は C→S: Remotes.DecideNext("home"|"next"|"save")
	end)
end

return Score
