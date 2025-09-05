-- StarterPlayerScripts/UI/lib/FormatUtil.lua
-- スコア・状態などの整形ユーティリティ

local M = {}

function M.rolesToLines(roles)
	if typeof(roles) ~= "table" then return "--" end
	local names = {
		five_bright="五光", four_bright="四光", rain_four_bright="雨四光", three_bright="三光",
		inoshikacho="猪鹿蝶", red_ribbon="赤短", blue_ribbon="青短",
		seeds="たね", ribbons="たん", chaffs="かす", hanami="花見で一杯", tsukimi="月見で一杯"
	}
	local list = {}
	for k,_ in pairs(roles) do table.insert(list, names[k] or k) end
	table.sort(list)
	return (#list > 0) and table.concat(list, " / ") or "--"
end

function M.stateLineText(st)
	local ytxt = (st and st.year and tonumber(st.year) and st.year > 0) and tostring(st.year) or "----"
	local seasonTxt = (st and (st.seasonStr or (st.season and ("季節"..tostring(st.season))))) or "季節--"
	local target = (st and st.target) or 0
	local sum    = (st and st.sum)    or 0
	local hands  = (st and st.hands)  or 0
	local reroll = (st and st.rerolls) or 0
	local mult   = (st and st.mult)   or 1
	local bank   = (st and st.bank)   or 0
	local dleft  = (st and st.deckLeft) or 0
	local hleft  = (st and st.handLeft) or 0

	return ("年:%s  季節:%s  目標:%d  合計:%d  残ハンド:%d  残リロール:%d  倍率:%.1fx  Bank:%d  山:%d  手:%d")
		:format(ytxt, seasonTxt, target, sum, hands, reroll, mult, bank, dleft, hleft)
end

return M
