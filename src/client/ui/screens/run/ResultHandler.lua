-- screens/run/ResultHandler.lua
local M = {}

-- modal: ResultModal インスタンス（components/ResultModal.lua）
-- deps : { Nav?, DecideNext? } のどちらか（Nav.next(choice) or Remotes.DecideNext:FireServer(choice)）
-- lang : 文字列（現状未使用だが将来の文言分岐で利用可）
-- dataA,dataB : サーバからの StageResult 引数（true,payload） or （payload 単体）
function M.handle(modal, deps, lang, dataA, dataB)
	-- 署名解決（true,payload／payloadどちらでもOKにする）
	local data
	if typeof(dataA) == "boolean" and dataA == true and typeof(dataB) == "table" then
		data = dataB
	elseif typeof(dataA) == "table" then
		data = dataA
	else
		return
	end
	if not data or type(data) ~= "table" then return end

	-- 遷移ヘルパ：Nav.next があればそれを、無ければ DecideNext("choice")
	local function decide(choice: string)
		if deps and deps.Nav and type(deps.Nav.next) == "function" then
			deps.Nav:next(choice)
		elseif deps and deps.DecideNext then
			-- Remotes.DecideNext:FireServer("home"|"koikoi"|"shop")
			deps.DecideNext:FireServer(choice)
		end
	end

	-- ===== 分岐 =====
	-- サーバ側（ScoreService.lua）が送る payload.kind:
	--  - "shop"  : 1〜8月  屋台前リザルト（内訳明示）→ OK で "shop"
	--  - "two"   : 9〜11月 2択（こいこい／ホーム）
	--  - "final" : 12月     ワンボタン（終了→ホーム）
	local kind = tostring(data.kind or "")

	if kind == "shop" then
		-- 屋台前リザルト（内訳→OK→屋台）
		-- ResultModal v0.9.9 で追加した showBreakdown を使用
		if modal and type(modal.showBreakdown) == "function" then
			modal:on({
				shop  = function() decide("shop") end, -- 「屋台へ」
				home  = function() decide("home") end, --（保険：UIから呼ばれない想定）
				koikoi= function() decide("koikoi") end, --（保険）
				final = function() decide("home") end,
			})
			modal:showBreakdown({
				titleText = data.titleText or ("月%d クリア！"):format(tonumber(data.nextMonth or 0) - 1),
				descText  = data.descText  or "獲得文の内訳を確認してください",
				buttonText= data.buttonText or "屋台へ",
				rewardMon = tonumber(data.rewardMon or 0),
				breakdown = data.breakdown or {},
			})
		else
			-- フォールバック：API未導入なら通常 show に流してしまう
			if modal and type(modal.show) == "function" then
				modal:on({ home=function() decide("shop") end, koikoi=function() decide("shop") end })
				modal:show({
					titleText = data.titleText or "クリア！",
					descText  = "屋台に進みます。",
					rewardBank= nil,
				})
			end
		end
		return
	end

	if kind == "two" then
		-- 2択（こいこい／ホーム）
		if modal and type(modal.show) == "function" then
			modal:on({
				home   = function() decide("home") end,
				koikoi = function() decide("koikoi") end,
			})
			modal:show({
				rewardBank = tonumber(data.rewardBank or 2),
				titleText  = data.titleText,
				descText   = data.descText,
				nextMonth  = tonumber(data.nextMonth or 0),
				nextGoal   = tonumber(data.nextGoal  or 0),
			})
		end
		return
	end

	if kind == "final" then
		-- ワンボタン（終了→ホーム）
		if modal and type(modal.showFinal) == "function" then
			modal:on({ final = function() decide("home") end })
			modal:showFinal(
				data.titleText or "12月 クリアおめでとう！",
				data.descText  or "このランは終了です。メニューに戻ります。",
				data.buttonText or "ホームへ",
				function() decide("home") end
			)
		end
		return
	end

	-- kind が来ていない旧互換（安全側：2択として描画）
	if modal and type(modal.show) == "function" then
		modal:on({
			home   = function() decide("home") end,
			koikoi = function() decide("koikoi") end,
		})
		modal:show(data)
	end
end

return M
