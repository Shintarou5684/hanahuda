-- shared/TalismanDefs.lua
-- v0.2 S5: 効果定義つき。必要に応じて enabled=true を段階解放
local M = {}

-- scope: "run"（ラン全体）/ "hand"（手番限定）/ "role"（役成立時のみ）…将来拡張用
-- stack: 同一IDの重ね掛け可否（true=可）
-- limit: 適用上限回数（nil=制限なし）
-- effect:
--   type="add_mon", amount=+N                                  … 常時 文 加算
--   type="add_role_mon", role="gokou", amount=+N               … 特定役成立時に 文 加算
--   type="add_any_role_mon", roles={...}, amount=+N            … 複数役のいずれか成立時
M.registry = {
	-- 開発用サンプル（まずは dev_plus1 だけ有効化して動作確認）
	dev_plus1 = {
		id="dev_plus1",
		nameJa="開発+1",
		nameEn="Dev +1",
		enabled=true,
		tags={"dev","basic"},
		stack=false,
		limit=nil,
		scope="run",
		effect={ type="add_mon", amount=1 },
	},

	dev_gokou_plus5 = {
		id="dev_gokou_plus5",
		nameJa="五光+5",
		nameEn="Gokou +5",
		enabled=false, -- 段階解放：回帰が取れたら true に
		tags={"dev","role"},
		stack=false,
		limit=nil,
		scope="role",
		effect={ type="add_role_mon", role="gokou", amount=5 },
	},

	dev_sake_plus3 = {
		id="dev_sake_plus3",
		nameJa="酒+3",
		nameEn="Sake +3",
		enabled=false, -- 段階解放：回帰が取れたら true に
		tags={"dev","role"},
		stack=true,
		limit=1, -- 例：最大1回まで
		scope="role",
		effect={ type="add_any_role_mon", roles={"sake","inoshikacho"}, amount=3 },
	},
}

function M.get(id)
	local d = M.registry[id]
	if not d or d.enabled == false then return nil end
	return d
end

function M.allEnabled()
	local t = {}
	for id, d in pairs(M.registry) do
		if d.enabled ~= false then
			table.insert(t, d)
		end
	end
	return t
end

return M
