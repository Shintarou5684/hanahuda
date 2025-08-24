-- ServerScriptService/UiResync.server.lua
-- 画面を開いた直後などに、手札/場/取り札/状態/得点をまとめて再送する

local RS = game:GetService("ReplicatedStorage")

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
local StateHub = require(RS.SharedModules.FromSrc.StateHub)
local Scoring  = require(RS.SharedModules.Scoring)

-- 準備できたかどうかの判定（季節が進んだ直後は数フレーム待つことがある）
local function isReadyState(s)
	if not s then return false end
	-- どれかが成立していれば「準備OK」
	if (s.target or 0) > 0 then return true end
	if s.board and #s.board > 0 then return true end
	if s.hand  and #s.hand  > 0 then return true end
	return false
end

ReqSyncUI.OnServerEvent:Connect(function(plr)
	-- ラウンド準備完了を軽く待機（最大 ~0.5s 程度）
	local s = StateHub.get(plr)
	local tries = 0
	while not isReadyState(s) and tries < 30 do
		tries += 1
		task.wait(0.016) -- 1~2フレーム
		s = StateHub.get(plr)
	end
	if not s then return end

	-- 手札/場/取り札を再送
	HandPush:FireClient(plr, s.hand or {})
	FieldPush:FireClient(plr, s.board or {})
	TakenPush:FireClient(plr, s.taken or {})

	-- 得点は「現在の取り札」で再採点（季節跨ぎの残留を避ける）
	local total, roles, detail = Scoring.evaluate(s.taken or {})
	ScorePush:FireClient(plr, total or 0, roles or {}, detail or {mon=0, pts=0})

	-- ★ 状態は StateHub 側の正規ルートで送る（target/hands/rerolls/deckLeft などが埋まる）
	StateHub.pushState(plr)
end)
