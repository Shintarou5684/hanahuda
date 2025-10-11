-- screens/run/RerollUi.lua
local M = {}

local function _resolve(self)
	if self._resolvedCounterRefs then return self._resolvedCounterRefs end
	local b = self.buttons or {}
	local r = { field=nil, hand=nil }

	local function pick(btn, prefer)
		if not (btn and btn.Parent) then return nil end
		if prefer and btn.Parent:FindFirstChild(prefer) then
			local n = btn.Parent:FindFirstChild(prefer)
			if n:IsA("TextLabel") then return n end
		end
		for _, ch in ipairs(btn.Parent:GetChildren()) do
			if ch ~= btn and ch:IsA("TextLabel") then
				local nm = string.lower(ch.Name)
				if string.find(nm,"count") or string.find(nm,"reroll") then return ch end
			end
		end
	end
	if typeof(b.rerollAllCount)=="Instance" then r.field=b.rerollAllCount end
	if typeof(b.rerollHandCount)=="Instance" then r.hand=b.rerollHandCount end
	if not r.field and b.rerollAll then r.field = pick(b.rerollAll,"RerollAllCount") end
	if not r.hand  and b.rerollHand then r.hand  = pick(b.rerollHand,"RerollHandCount") end

	self._resolvedCounterRefs = r
	return r
end

function M.setCounts(self, fieldLeft, handLeft, _phase)
	local f = tonumber(fieldLeft or 0) or 0
	local h = tonumber(handLeft  or 0) or 0
	self._rerollFieldLeft = f
	self._rerollHandLeft  = h

	local refs = _resolve(self)
	if refs.field then
		refs.field.Text = tostring(f)
		refs.field.TextTransparency = (f>0) and 0 or 0.3
	end
	if refs.hand then
		refs.hand.Text = tostring(h)
		refs.hand.TextTransparency = (h>0) and 0 or 0.3
	end

	local b = self.buttons or {}
	if b.rerollAll and b.rerollAll:IsA("TextButton") then
		b.rerollAll.AutoButtonColor = f>0; b.rerollAll.Active = (f>0)
	end
	if b.rerollHand and b.rerollHand:IsA("TextButton") then
		b.rerollHand.AutoButtonColor = h>0; b.rerollHand.Active = (h>0)
	end
end

return M
