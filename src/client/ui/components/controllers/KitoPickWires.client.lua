-- src/client/ui/components/controllers/KitoPickWires.client.lua
-- 目的: KitoPick の最小配線（UIは仮。まずは自動決定で往復確認）
-- メモ:
--  - Balance.KITO_UI_ENABLED が true のときのみ動作
--  - Balance.KITO_UI_AUTO_DECIDE が true（既定）なら自動で1枚選択して送信
--  - 将来本UIが入ったら KITO_UI_AUTO_DECIDE=false にすれば自動選択は止まる

local RS = game:GetService("ReplicatedStorage")

-- 依存
local Config        = RS:WaitForChild("Config")
local Balance       = require(Config:WaitForChild("Balance"))

local Remotes       = RS:WaitForChild("Remotes")
local EvStart       = Remotes:WaitForChild("KitoPickStart")
local EvDecide      = Remotes:WaitForChild("KitoPickDecide")
local EvResult      = Remotes:WaitForChild("KitoPickResult")

local Logger        = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG           = Logger.scope("KitoPickClient")

-- ─────────────────────────────────────────────────────────────
-- 重複接続ガード（Play Solo 再起動や二重require対策）
-- ─────────────────────────────────────────────────────────────
if script:GetAttribute("wired") then
	-- 既に接続済み
	return
end
script:SetAttribute("wired", true)

-- ─────────────────────────────────────────────────────────────
-- 設定
-- ─────────────────────────────────────────────────────────────
local AUTO_DECIDE = (Balance.KITO_UI_AUTO_DECIDE ~= false)  -- 既定: true
local ENABLED     = (Balance.KITO_UI_ENABLED == true)

-- ─────────────────────────────────────────────────────────────
-- ユーティリティ
-- ─────────────────────────────────────────────────────────────
local function briefList(list)
	local n = type(list) == "table" and #list or 0
	return tostring(n)
end

-- 「最初の非 targetKind」を優先、全て targetKind なら先頭
local function chooseUid(payload)
	if type(payload) ~= "table" or type(payload.list) ~= "table" or #payload.list == 0 then
		return nil
	end
	local tk = tostring(payload.targetKind or "bright")
	for _, ent in ipairs(payload.list) do
		if ent and ent.kind ~= tk then
			return ent.uid
		end
	end
	return payload.list[1].uid
end

-- ─────────────────────────────────────────────────────────────
-- 受信: 候補提示
-- ─────────────────────────────────────────────────────────────
EvStart.OnClientEvent:Connect(function(payload)
	if not ENABLED then
		LOG.debug("[KitoPickStart] UI disabled; ignoring")
		return
	end

	local ok = type(payload) == "table" and type(payload.list) == "table"
	LOG.info("[KitoPickStart] ok=%s size=%s target=%s session=%s",
		tostring(ok), ok and briefList(payload.list) or "?",
		tostring(payload and payload.targetKind),
		tostring(payload and payload.sessionId)
	)

	if not ok or #payload.list == 0 then return end

	-- 本番UIが入るまでは自動決定で確定まで通す
	if not AUTO_DECIDE then
		-- ここでUIへ payload を流す（後付け）
		return
	end

	local pickUid = chooseUid(payload)
	if not pickUid then
		LOG.warn("[KitoPickDecide] no candidate uid")
		return
	end

	EvDecide:FireServer({
		sessionId  = payload.sessionId,
		uid        = pickUid,
		targetKind = payload.targetKind or "bright",
	})
	LOG.info("[KitoPickDecide] sent uid=%s (auto)", tostring(pickUid))
end)

-- ─────────────────────────────────────────────────────────────
-- 受信: 結果
-- ─────────────────────────────────────────────────────────────
EvResult.OnClientEvent:Connect(function(res)
	if type(res) ~= "table" then return end
	LOG.info("[KitoPickResult] ok=%s msg=%s target=%s",
		tostring(res.ok), tostring(res.message), tostring(res.targetKind))
	-- TODO: 後付けのトースト/モーダルへ通知
end)
