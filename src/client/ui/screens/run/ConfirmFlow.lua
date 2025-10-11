-- screens/run/ConfirmFlow.lua
local M = {}

function M.handleConfirm(ctx)
	-- ctx: { state, total, lang, Locale, GiveUpConfirm, Theme, DecideNext, Confirm }
	local goal  = tonumber((ctx.state and (ctx.state.goal or ctx.state.target)) or 0) or 0
	local total = tonumber(ctx.total or 0) or 0

	if total >= goal then
		if ctx.Confirm then ctx.Confirm:FireServer() end
		return
	end

	-- 未達：GiveUp 確認モーダル
	ctx.GiveUpConfirm.show(ctx.parent, ctx.Locale, ctx.Theme, ctx.lang, function()
		if ctx.DecideNext then
			ctx.DecideNext:FireServer("abandon")
		end
	end)
end

return M
