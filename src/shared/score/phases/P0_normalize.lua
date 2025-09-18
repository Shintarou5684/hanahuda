-- ReplicatedStorage/SharedModules/score/phases/P0_normalize.lua
-- v0.9.3-S2 P0: 正規化ヘルパ集

local Kind = require(script.Parent.Parent.util.kind)
local Tags = require(script.Parent.Parent.util.tags)

local P0 = {}

P0.normKind = Kind.normKind
P0.toTagSet = Tags.toTagSet
P0.hasTags  = Tags.hasTags

return P0
