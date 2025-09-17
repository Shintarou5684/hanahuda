-- ServerScriptService/UiResync.server.lua
-- 画面を開いた直後などに、手札/場/取り札/状態/得点をまとめて再送する（安全化版）
-- 改善点:
--  1) 結果表示中 (s.phase=="result") は余計な再送を避ける
--  2) 連打/重複のデバウンス (同一プレイヤー 0.3s 以内は捨てる)
--  3) null/型の安全化（落ちないようにデフォルト値を用意）
--  4) P1-3: Logger 導入（print/warn を LOG.* に置換）

local RS = game:GetService("ReplicatedStorage")

-- Logger
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("UiResync")

-- Remotes フォルダ
local RemotesFolder = RS:FindFirstChild("Remotes") or (function()
	local f = Instance.new("Folder")
	f.Name = "Remotes"
	f.Parent = RS
	return f
end)()

local function ensureRemote(name: string)
	return RemotesFolder:FindFirstChild(name) or (function()
		local e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = RemotesFolder
		return e
	end)()
end

-- Remotes
local ReqSyncUI  = ensureRemote("ReqSyncUI")  -- C->S: 全UI再送要求
local HandPush   = ensureRemote("HandPush")
local FieldPush  = ensureRemote("FieldPush")
local TakenPush  = ensureRemote("TakenPush")
local ScorePush  = ensureRemote("ScorePush")
-- StatePush は自前で送らず、StateHub.pushState(plr) に任せる

-- 状態/採点
local StateHub = require(RS.SharedModules.StateHub)
local Scoring  = require(RS.SharedModules.Scoring)

--==================================================
-- 内部ユーティリティ
--==================================================

-- 準備できたかどうかの判定（季節が進んだ直後は数フレーム待つことがある）
local function isReadyState(s)
	if not s then return false end
	-- どれかが成立していれば「準備OK」
	if (s.target or 0) > 0 then return true end
	if s.board and #s.board > 0 then return true end
	if s.hand  and #s.hand  > 0 then return true end
	return false
end

-- 直近の再同期要求の時刻（プレイヤー毎）
local _lastSyncAt : {[Player]: number} = {}
local DEBOUNCE_SEC = 0.3

-- 安全に再採点（nilでも落ちない）
local function safeEvaluate(taken:any)
	local ok, total, roles, detail = pcall(function()
		local t, r, d = Scoring.evaluate(taken or {})
		return t or 0, r or {}, d or {mon=0, pts=0}
	end)
	if ok then
		return total, roles, detail
	else
		LOG.warn("Scoring.evaluate failed; fallback to zeros")
		return 0, {}, {mon=0, pts=0}
	end
end

--==================================================
-- 本体
--==================================================
ReqSyncUI.OnServerEvent:Connect(function(plr)
	-- デバウンス（連打・重複抑制）
	local now = os.clock()
	local prev = _lastSyncAt[plr]
	if prev and (now - prev) < DEBOUNCE_SEC then
		-- 近すぎる要求は無視（必要ならデバッグログ）
		-- LOG.debug("debounced | user=%s dt=%.2f", plr.Name, now - prev)
		return
	end
	_lastSyncAt[plr] = now

	-- 状態取得
	local s = StateHub.get(plr)
	if not s then return end

	LOG.info(
		"lens | user=%s deck=%d hand=%d board=%d taken=%d phase=%s",
		plr.Name, #(s.deck or {}), #(s.hand or {}), #(s.board or {}), #(s.taken or {}), tostring(s.phase)
	)

	-- 結果表示中は余計な再送を避ける（State だけ押し直したい場合は pushState を残す）
	if s.phase == "result" then
		-- 結果モーダル中に UI を書き換えると見た目がチラつくため抑制
		-- 必要なら StateHub.pushState(plr) を有効化
		-- StateHub.pushState(plr)
		return
	end

	-- ラウンド準備完了を軽く待機（最大 ~0.5s 程度）
	local tries = 0
	while not isReadyState(s) and tries < 30 do
		tries += 1
		task.wait(0.016) -- 1~2フレーム
		s = StateHub.get(plr)
		if not s then return end
	end

	-- 手札/場/取り札を再送
	HandPush:FireClient(plr, s.hand or {})
	FieldPush:FireClient(plr, s.board or {})
	TakenPush:FireClient(plr, s.taken or {})

	-- 得点は「現在の取り札」で再採点（季節跨ぎの残留を避ける）
	local total, roles, detail = safeEvaluate(s.taken)
	LOG.debug("ScorePush types: %s %s %s", typeof(total), typeof(roles), typeof(detail))
	ScorePush:FireClient(plr, total, roles, detail)

	-- ★ 状態は StateHub 側の正規ルートで送る（target/hands/rerolls/deckLeft などが埋まる）
	StateHub.pushState(plr)
end)
