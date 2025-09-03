-- src/config/DisplayMode.lua
local DisplayMode = {}

DisplayMode.Current = "2D"  -- 当面は2D固定

function DisplayMode:is2D() return self.Current == "2D" end
function DisplayMode:is3D() return self.Current == "3D" end

function DisplayMode:set(mode)
	if mode == "2D" then
		self.Current = "2D"; return true
	elseif mode == "3D" then
		warn("[DisplayMode] 3Dは未実装です（当面2D固定）")
		self.Current = "2D"; return false
	else
		warn("[DisplayMode] 不明なモード: ", mode)
		return false
	end
end

return DisplayMode
