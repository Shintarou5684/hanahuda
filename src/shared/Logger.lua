-- SharedModules/Logger.lua
-- =========================================================
-- ▼▼▼ ここだけ編集すればOK（保存式・手動切替） ▼▼▼
-- ログ量: 1=少ない(WARN/ERROR) / 2=そこそこ(INFO以上) / 3=全部(DEBUGまで)
local USER_VERBOSITY = 2  -- ★ここを 1 / 2 / 3 に変更して保存

-- 「大量に出ているログ」を DEBUG に“降格”するルール
-- 例: ScoreタグのINFOをDEBUGに落とす → infoToDebugTags = { "Score" }
--     文言に "P2_roles" を含むINFOをDEBUGへ → infoToDebugContains = { "P2_roles" }
--     Luaパターンで "[P%d+_.*]" を含むINFOをDEBUGへ → infoToDebugPatterns = { "P%d+_%w+" }
local USER_DOWNGRADE = {
	infoToDebugTags      = { "Score" },  -- ←デフォはScoreだけ降格。不要なら消してOK
	infoToDebugContains  = {
		-- "P2_roles", "P3_matsuri_kito", "P4_talisman", "P5_omamori",
	},
	infoToDebugPatterns  = {
		-- "P%d+_%w+",             -- 例: P2_xxx/P3_xxx...にマッチ
		-- "pushState%.begin",     -- 例: StateHubのbegin行を落とす
	},
}
-- ▲▲▲ ここだけ編集すればOK ▲▲▲
-- =========================================================
--
-- 使い方:
--   local RS = game:GetService("ReplicatedStorage")
--   local Logger = require(RS.SharedModules.Logger)
--   local LOG = Logger.scope("RunScreen")
--   LOG.debug("boot %s", tostring(version))
--
-- ※コードから明示的に変えたい場合:
--   Logger.setVerbosity(3)
--   Logger.configure({
--     verbosity = 1,
--     infoToDebugTags = { "Score", "StateHub" },
--     infoToDebugContains = { "P2_roles" },
--     infoToDebugPatterns = { "pushState%%.begin" },
--   })
--
-- 既存APIの互換:
--   Logger.setLevel/Logger.getLevel, Logger.scope, Logger.configure 等はそのまま

local RunService   = game:GetService("RunService")
local HttpService  = game:GetService("HttpService")

local Logger = {}
Logger.DEBUG = 10
Logger.INFO  = 20
Logger.WARN  = 30
Logger.ERROR = 40
Logger.NONE  = 99

-- 1/2/3 → ログ閾値
local VERBOSITY_TO_LEVEL = {
	[1] = Logger.WARN,  -- 少ない: WARN/ERROR
	[2] = Logger.INFO,  -- そこそこ: INFO/WARN/ERROR
	[3] = Logger.DEBUG, -- 全部: DEBUG含む
}

-- 初期レベル: USER_VERBOSITY優先。未設定/不正なら Studio=DEBUG / 公開=WARN
local function _initialLevel()
	local v = tonumber(USER_VERBOSITY)
	if v and VERBOSITY_TO_LEVEL[v] then
		return VERBOSITY_TO_LEVEL[v], v
	end
	local lvl = RunService:IsStudio() and Logger.DEBUG or Logger.WARN
	return lvl, nil
end

local _initLevel, _initVerbosity = _initialLevel()

local state = {
	level = _initLevel,          -- 初期レベル
	verbosity = _initVerbosity,  -- 1/2/3（USER_VERBOSITYが有効なら入る）
	timePrefix = true,
	throwOnError = false,        -- ERRORで error() したいなら true
	enabledTags = nil,           -- nil=全許可 / set型 {"NAV"=true, ...}
	disabledTags = {},           -- set型
	dupWindowSec = 0.75,         -- 同一メッセージ抑制ウィンドウ（秒）
	_last = {},                  -- [key]=lastTime
	sink = nil,                  -- カスタム出力先 (function(level, line))

	-- 降格ルール（初期値はUSER_DOWNGRADEで与える）
	infoToDebugTags = {},
	infoToDebugContains = {},
	infoToDebugPatterns = {},
}

-- USER_DOWNGRADE を state に反映（テーブルコピー）
do
	if type(USER_DOWNGRADE) == "table" then
		if type(USER_DOWNGRADE.infoToDebugTags) == "table" then
			for _, t in ipairs(USER_DOWNGRADE.infoToDebugTags) do
				state.infoToDebugTags[tostring(t)] = true
			end
		end
		if type(USER_DOWNGRADE.infoToDebugContains) == "table" then
			for _, s in ipairs(USER_DOWNGRADE.infoToDebugContains) do
				table.insert(state.infoToDebugContains, tostring(s))
			end
		end
		if type(USER_DOWNGRADE.infoToDebugPatterns) == "table" then
			for _, p in ipairs(USER_DOWNGRADE.infoToDebugPatterns) do
				table.insert(state.infoToDebugPatterns, tostring(p))
			end
		end
	end
end

local LVL_NAME = {
	[Logger.DEBUG] = "D",
	[Logger.INFO]  = "I",
	[Logger.WARN]  = "W",
	[Logger.ERROR] = "E",
}

local function nowMs()
	return os.clock()
end

local function safeJson(v)
	local ok, s = pcall(function()
		-- Instance を避けて簡易シリアライズ
		local function scrub(x, depth)
			depth = depth or 0
			if depth > 3 then return "<depth-limit>" end
			if typeof(x) == "Instance" then
				return ("<Instance:%s:%s>"):format(x.ClassName, x.Name)
			elseif typeof(x) == "table" then
				local t = {}
				local i = 0
				for k, vv in pairs(x) do
					i += 1
					if i > 32 then t["<truncated>"] = true; break end
					t[tostring(k)] = scrub(vv, depth + 1)
				end
				return t
			else
				return x
			end
		end
		return HttpService:JSONEncode(scrub(v))
	end)
	if ok then return s end
	return tostring(v)
end

local function fmt(msg, ...)
	if select("#", ...) == 0 then
		return tostring(msg)
	end
	-- string.format が失敗（%流入等）するケースにも強い
	local ok, out = pcall(string.format, tostring(msg), ...)
	if ok then return out end
	-- フォーマット不可なら素朴に連結
	local parts = { tostring(msg) }
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		table.insert(parts, (typeof(v) == "table") and safeJson(v) or tostring(v))
	end
	return table.concat(parts, " | ")
end

local function shouldLog(tag, level)
	if level < state.level then return false end
	if state.enabledTags and not state.enabledTags[tag] then
		return false
	end
	if state.disabledTags and state.disabledTags[tag] then
		return false
	end
	return true
end

local function sideLetter()
	if RunService:IsServer() then return "S" end
	if RunService:IsClient() then return "C" end
	return "-"
end

local function output(level, tag, text)
	local prefixT = ""
	if state.timePrefix then
		-- hh:mm:ss（ざっくり）
		local t = os.time() % 86400
		local h = math.floor(t/3600)
		local m = math.floor((t%3600)/60)
		local s = t%60
		prefixT = string.format("%02d:%02d:%02d ", h, m, s)
	end
	local line = string.format("[%s]%s[%s][%s] %s",
		LVL_NAME[level] or "?", prefixT, sideLetter(), tag, text)

	if state.sink then
		local ok = pcall(state.sink, level, line)
		if ok then return end
	end

	if level >= Logger.WARN then
		warn(line)
	else
		print(line)
	end

	if level >= Logger.ERROR and state.throwOnError then
		error(line)
	end
end

local function dupKey(level, tag, text)
	return string.format("%d|%s|%s", level, tag, text)
end

-- INFOをDEBUGへ“降格”するかを判定
local function maybeDowngrade(level, tag, text)
	if level ~= Logger.INFO then return level end

	-- タグ指定
	if state.infoToDebugTags and state.infoToDebugTags[tag] then
		return Logger.DEBUG
	end

	-- 含む文字列
	if state.infoToDebugContains then
		for _, s in ipairs(state.infoToDebugContains) do
			if s ~= "" and string.find(text, s, 1, true) then
				return Logger.DEBUG
			end
		end
	end

	-- Luaパターン
	if state.infoToDebugPatterns then
		for _, p in ipairs(state.infoToDebugPatterns) do
			if p ~= "" and string.find(text, p) then
				return Logger.DEBUG
			end
		end
	end

	return level
end

local function log(level, tag, msg, ...)
	-- 先に整形（降格で text を使うため）
	local text = fmt(msg, ...)

	-- 降格判定（主にINFO→DEBUG）
	level = maybeDowngrade(level, tag, text)

	if not shouldLog(tag, level) then return end

	-- 連打抑制
	local key = dupKey(level, tag, text)
	local t = nowMs()
	local last = state._last[key]
	if last and (t - last) < state.dupWindowSec then
		return
	end
	state._last[key] = t
	output(level, tag, text)
end

-- ========= Public API =========

-- 1/2/3 の簡易モード設定
function Logger.setVerbosity(n)
	n = tonumber(n)
	if not n or not VERBOSITY_TO_LEVEL[n] then return end
	state.verbosity = n
	state.level = VERBOSITY_TO_LEVEL[n]
end

function Logger.getVerbosity()
	return state.verbosity
end

function Logger.configure(opts)
	if typeof(opts) ~= "table" then return end

	-- verbosity があれば最優先（USER_VERBOSITYより後で呼ぶと上書き）
	if opts.verbosity ~= nil then
		Logger.setVerbosity(opts.verbosity)
	end

	-- level の直接指定も可（verbosity 未指定/無効時はこちらが効く）
	if opts.level ~= nil then
		state.level = opts.level
	end

	if opts.timePrefix ~= nil then state.timePrefix = opts.timePrefix end
	if opts.throwOnError ~= nil then state.throwOnError = opts.throwOnError end
	if opts.dupWindowSec ~= nil then state.dupWindowSec = opts.dupWindowSec end
	if opts.sink ~= nil then state.sink = opts.sink end

	if opts.enableTags then
		local set = {}
		for _, t in ipairs(opts.enableTags) do set[tostring(t)] = true end
		state.enabledTags = set
	end
	if opts.disableTags then
		for _, t in ipairs(opts.disableTags) do state.disabledTags[tostring(t)] = true end
	end

	-- ▼ 降格ルール（configureでも上書き可能）
	if opts.infoToDebugTags then
		state.infoToDebugTags = {}
		for _, t in ipairs(opts.infoToDebugTags) do
			state.infoToDebugTags[tostring(t)] = true
		end
	end
	if opts.infoToDebugContains then
		state.infoToDebugContains = {}
		for _, s in ipairs(opts.infoToDebugContains) do
			table.insert(state.infoToDebugContains, tostring(s))
		end
	end
	if opts.infoToDebugPatterns then
		state.infoToDebugPatterns = {}
		for _, p in ipairs(opts.infoToDebugPatterns) do
			table.insert(state.infoToDebugPatterns, tostring(p))
		end
	end
end

function Logger.setLevel(lvl)
	state.level = lvl
	-- 明示的に level を上書きした場合、verbosity の値は保持（混在運用OK）
end

function Logger.getLevel()
	return state.level
end

-- タグ別ロガー（推奨）
function Logger.scope(tag)  -- ← 予約語回避（旧: Logger.for）
	tag = tostring(tag or "APP")
	local proxy = {}
	function proxy.debug(msg, ...) log(Logger.DEBUG, tag, msg, ...) end
	function proxy.info (msg, ...) log(Logger.INFO , tag, msg, ...) end
	function proxy.warn (msg, ...) log(Logger.WARN , tag, msg, ...) end
	function proxy.error(msg, ...) log(Logger.ERROR, tag, msg, ...) end
	-- printf 風エイリアス
	function proxy.debugf(...) proxy.debug(...) end
	function proxy.infof (...) proxy.info (...) end
	function proxy.warnf (...) proxy.warn (...) end
	function proxy.errorf(...) proxy.error(...) end
	return proxy
end
Logger.forTag = Logger.scope   -- 互換用の別名

-- グローバル呼び出し（あまり推奨しない）
local ROOT = Logger.scope("APP")
function Logger.debug(...) ROOT.debug(...) end
function Logger.info (...) ROOT.info (...) end
function Logger.warn (...) ROOT.warn (...) end
function Logger.error(...) ROOT.error(...) end

return Logger
