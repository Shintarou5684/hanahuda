-- SharedModules/Logger.lua
-- 使い方:
--   local RS = game:GetService("ReplicatedStorage")
--   local Logger = require(RS.SharedModules.Logger)
--   local LOG = Logger.scope("RunScreen")  -- タグ＝出所名
--   LOG.debug("boot %s", tostring(version))
--
-- 公開ビルドで抑止: どこかのブートで
--   Logger.configure({ level = Logger.WARN })  -- または Logger.ERROR

local RunService   = game:GetService("RunService")
local HttpService  = game:GetService("HttpService")

local Logger = {}
Logger.DEBUG = 10
Logger.INFO  = 20
Logger.WARN  = 30
Logger.ERROR = 40
Logger.NONE  = 99

local state = {
	level = RunService:IsStudio() and Logger.DEBUG or Logger.WARN, -- Studioは詳しめ、公開は控えめ
	timePrefix = true,
	throwOnError = false,       -- ERRORで error() したいなら true
	enabledTags = nil,          -- nil=全許可 / set型 {"NAV"=true, ...}
	disabledTags = {},          -- set型
	dupWindowSec = 0.75,        -- 同一メッセージの抑制ウィンドウ（秒）
	_last = {},                 -- [key]=lastTime
	sink = nil,                 -- カスタム出力先 (function(level, line))
}

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
	-- string.format が失敗するケース（%記号流入）に強い
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
	if state.enabledTags then
		if not state.enabledTags[tag] then return false end
	end
	if state.disabledTags and state.disabledTags[tag] then return false end
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

local function log(level, tag, msg, ...)
	if not shouldLog(tag, level) then return end
	local text = fmt(msg, ...)
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

function Logger.configure(opts)
	if typeof(opts) ~= "table" then return end
	if opts.level ~= nil then state.level = opts.level end
	if opts.timePrefix ~= nil then state.timePrefix = opts.timePrefix end
	if opts.throwOnError ~= nil then state.throwOnError = opts.throwOnError end
	if opts.dupWindowSec ~= nil then state.dupWindowSec = opts.dupWindowSec end
	if opts.sink ~= nil then state.sink = opts.sink end

	if opts.enableTags then
		local set = {}
		for _, t in ipairs(opts.enableTags) do set[t] = true end
		state.enabledTags = set
	end
	if opts.disableTags then
		for _, t in ipairs(opts.disableTags) do state.disabledTags[t] = true end
	end
end

function Logger.setLevel(lvl) state.level = lvl end
function Logger.getLevel() return state.level end

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
