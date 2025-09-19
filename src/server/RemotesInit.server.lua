-- ServerScriptService/RemotesInit.server.lua
local RS = game:GetService("ReplicatedStorage")

local function ensureFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local function ensureRE(parent, name)
	local ev = parent:FindFirstChild(name)
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = parent
	end
	return ev
end

local remotes = ensureFolder(RS, "Remotes")
ensureRE(remotes, "PlaceOnSlot")     -- C→S
ensureRE(remotes, "TalismanPlaced")  -- S→C (ACK)

print("[RemotesInit] Remotes ready →", remotes:GetFullName())
