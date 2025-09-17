-- ServerScriptService/NavServer.lua
-- v0.9.6 P1-1 (+P1-3 Logger) Nav 集約：DecideNext を唯一線に
-- 仕様：
--   * C→S: DecideNext("home"|"next"|"save")
--   * 冬クリア後3択に対応（"next" は totalClears>=3 の解禁判定）
--   * "home"/"save" は“春スナップ”を必ず消し、HomeOpen.hasSave=false を返す
--   * 言語コードは外部 "ja"/"en"（"jp" は "ja" に正規化）
--   * print/warn → Logger に置換

local RS  = game:GetService("ReplicatedStorage")

-- Logger
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("NavServer")

local function ensureRemote(name: string)
	local rem = RS:FindFirstChild("Remotes")
	if not rem then
		rem = Instance.new("Folder")
		rem.Name = "Remotes"
		rem.Parent = RS
	end
	local e = rem:FindFirstChild(name)
	if not e then
		e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = rem
	end
	return e
end

local Remotes = {
	HomeOpen   = ensureRemote("HomeOpen"),
	DecideNext = ensureRemote("DecideNext"),
}

local function normLang(v:string?): string
	v = tostring(v or ""):lower()
	if v == "ja" or v == "jp" then return "ja" end
	if v == "en" then return "en" end
	return "en"
end

local NavServer = {}
NavServer.__index = NavServer

export type Deps = {
	StateHub: any,
	Round: any,
	ShopService: any?,
	SaveService: any?,
	HomeOpen: RemoteEvent?,      -- （任意）外から渡されたものを優先
	DecideNext: RemoteEvent?,    -- （任意）外から渡されたものを優先
}

function NavServer.init(deps: Deps)
	local self = setmetatable({ deps = deps or {}, _conns = {} }, NavServer)

	-- 外部から Remotes をもらえたら差し替え
	if deps.HomeOpen then Remotes.HomeOpen = deps.HomeOpen end
	if deps.DecideNext then Remotes.DecideNext = deps.DecideNext end

	-- 統一入口
	table.insert(self._conns, Remotes.DecideNext.OnServerEvent:Connect(function(plr, op)
		self:handle(plr, tostring(op or ""))
	end))

	LOG.info("ready (DecideNext unified)")
	return self
end

-- ★ 補助：HOMEへ戻る前に“春スナップ”を消す
local function resetRunForHome(Round, SaveService, plr: Player)
	Round.resetRun(plr) -- 実装都合で春スナップが生成される
	if SaveService and typeof(SaveService.clearActiveRun) == "function" then
		pcall(function() SaveService.clearActiveRun(plr) end)
	end
end

function NavServer:handle(plr: Player, op: string)
	local StateHub    = self.deps.StateHub
	local Round       = self.deps.Round
	local ShopService = self.deps.ShopService
	local SaveService = self.deps.SaveService

	local s = StateHub and StateHub.get and StateHub.get(plr)
	if not s then
		LOG.warn("state missing | user=%s op=%s", tostring(plr and plr.Name or "?"), tostring(op))
		return
	end

	-- 冬以外では想定外（クライアントから来ても無視）
	if (s.season or 1) ~= 4 then
		LOG.debug("DecideNext ignored (not winter) | user=%s op=%s season=%s", tostring(plr and plr.Name or "?"), tostring(op), tostring(s.season))
		return
	end

	-- 共通初期化
	s.mult = 1.0

	-- 解禁判定（例：3クリア以上で "next" 許可）
	local clears   = tonumber(s.totalClears or 0) or 0
	local unlocked = clears >= 3
	if op ~= "home" and not unlocked then
		op = "home"
	end
	LOG.info("handle | user=%s op=%s unlocked=%s clears=%d", tostring(plr and plr.Name or "?"), tostring(op), tostring(unlocked), clears)

	if op == "home" then
		resetRunForHome(Round, SaveService, plr)
		Remotes.HomeOpen:FireClient(plr, {
			hasSave = false,
			bank    = s.bank or 0,
			year    = s.year or 0,
			clears  = s.totalClears or 0,
			lang    = normLang(SaveService and SaveService.getLang and SaveService.getLang(plr)),
		})
		LOG.info("→ HOME | user=%s hasSave=false bank=%d year=%d clears=%d", plr.Name, s.bank or 0, s.year or 0, s.totalClears or 0)
		return

	elseif op == "next" then
		s.year = (s.year or 0) + 25
		if SaveService and typeof(SaveService.bumpYear) == "function" then
			SaveService.bumpYear(plr, 25)
		elseif SaveService and typeof(SaveService.setYear) == "function" then
			SaveService.setYear(plr, s.year)
		end
		s.phase = "shop"
		if ShopService and typeof(ShopService.open) == "function" then
			ShopService.open(plr, s, { reason = "after_winter" })
			LOG.info("→ NEXT (open shop) | user=%s newYear=%d", plr.Name, s.year or 0)
		else
			if StateHub and StateHub.pushState then StateHub.pushState(plr) end
			LOG.info("→ NEXT (push state only) | user=%s newYear=%d", plr.Name, s.year or 0)
		end
		return

	elseif op == "save" then
		local ok = true
		if SaveService and typeof(SaveService.flush) == "function" then
			ok = SaveService.flush(plr) == true
		end
		resetRunForHome(Round, SaveService, plr)
		Remotes.HomeOpen:FireClient(plr, {
			hasSave = false, -- ★常に START（春スナップは消去済）
			bank    = s.bank or 0,
			year    = s.year or 0,
			clears  = s.totalClears or 0,
			saved   = ok,
			lang    = normLang(SaveService and SaveService.getLang and SaveService.getLang(plr)),
		})
		LOG.info("→ SAVE→HOME | user=%s saved=%s", plr.Name, tostring(ok))
		return
	end

	LOG.warn("unknown op | user=%s op=%s", tostring(plr and plr.Name or "?"), tostring(op))
end

return NavServer
