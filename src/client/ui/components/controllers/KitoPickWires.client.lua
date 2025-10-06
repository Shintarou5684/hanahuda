-- src/client/ui/wires/KitoPickWires.client.lua
-- 目的: KitoPick の配線（UIは ClientSignals のみ購読）
-- メモ:
--  - Balance.KITO_UI_ENABLED が true のときのみ動作
--  - Balance.KITO_UI_AUTO_DECIDE=false で本UIへ委譲（12枚一覧・グレーアウト・確定ボタン）
--  - UI層は ReplicatedStorage/ClientSignals の BindableEvent を購読する
--  - eligibility を尊重：AUTO_DECIDE 時は「選択可能(eligibility.ok)な候補のみ」から選ぶ

local RS = game:GetService("ReplicatedStorage")

-- 依存
local Config   = RS:WaitForChild("Config")
local Balance  = require(Config:WaitForChild("Balance"))

local Remotes  = RS:WaitForChild("Remotes")
local EvStart  = Remotes:WaitForChild("KitoPickStart")
local EvDecide = Remotes:WaitForChild("KitoPickDecide")
local EvResult = Remotes:WaitForChild("KitoPickResult")

local Logger   = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG      = Logger.scope("KitoPickClient")

-- ─────────────────────────────────────────────────────────────
-- 重複接続ガード（Play Solo 再起動や二重require対策）
-- ─────────────────────────────────────────────────────────────
if script:GetAttribute("wired") then
	return
end
script:SetAttribute("wired", true)

-- ─────────────────────────────────────────────────────────────
-- 設定
-- ─────────────────────────────────────────────────────────────
local AUTO_DECIDE = (Balance.KITO_UI_AUTO_DECIDE == true)   -- 明示 true のときのみ自動決定
local ENABLED     = (Balance.KITO_UI_ENABLED == true)

-- ─────────────────────────────────────────────────────────────
-- UI ブリッジ（クライアント内だけで使う BindableEvent を公開）
-- ─────────────────────────────────────────────────────────────
local function ensure(parent, name, className)
	local inst = parent:FindFirstChild(name)
	if not inst then
		inst = Instance.new(className)
		inst.Name = name
		inst.Parent = parent
	end
	return inst
end

local ClientSignals = ensure(RS, "ClientSignals", "Folder")
local SigIncoming   = ensure(ClientSignals, "KitoPickIncoming", "BindableEvent")
local SigResult     = ensure(ClientSignals, "KitoPickResult", "BindableEvent")

-- ─────────────────────────────────────────────────────────────
-- ユーティリティ
-- ─────────────────────────────────────────────────────────────
local function briefList(list)
	local n = type(list) == "table" and #list or 0
	return tostring(n)
end

-- eligible を尊重して UID を選ぶ（AUTO_DECIDE 用）
-- 1) eligible==true の中から先頭
-- 2) すべて不可なら nil（＝スキップ送信）
local function chooseEligibleUid(payload)
	if type(payload) ~= "table" or type(payload.list) ~= "table" or #payload.list == 0 then
		return nil
	end
	local elig = (type(payload.eligibility) == "table") and payload.eligibility or {}

	for _, ent in ipairs(payload.list) do
		local uid = ent and ent.uid
		if uid then
			local e = elig[uid]
			if type(e) == "table" and e.ok == true then
				return uid
			end
		end
	end
	return nil
end

local function countEligible(payload)
	if type(payload) ~= "table" or type(payload.list) ~= "table" then
		return 0, 0
	end
	local elig = (type(payload.eligibility) == "table") and payload.eligibility or {}
	local total, ok = #payload.list, 0
	for _, ent in ipairs(payload.list) do
		local e = ent and elig[ent.uid]
		if type(e) == "table" and e.ok == true then ok += 1 end
	end
	return ok, total
end

-- ─────────────────────────────────────────────────────────────
-- 受信: 候補提示 → UI へ（または AUTO_DECIDE）
-- ─────────────────────────────────────────────────────────────
EvStart.OnClientEvent:Connect(function(payload)
	if not ENABLED then
		LOG.debug("[KitoPickStart] UI disabled; ignoring")
		return
	end

	local ok = type(payload) == "table" and type(payload.list) == "table"
	local eff = ok and tostring(payload.effectId or payload.effect or "-") or "-"
	local okN, totalN = 0, 0
	if ok then okN, totalN = countEligible(payload) end

	LOG.info("[KitoPickStart] ok=%s size=%s elig=%d/%d target=%s effect=%s session=%s",
		tostring(ok), ok and briefList(payload.list) or "?",
		okN, totalN,
		tostring(payload and payload.targetKind),
		eff,
		tostring(payload and payload.sessionId)
	)
	if not ok or #payload.list == 0 then return end

	if not AUTO_DECIDE then
		-- 単一路線：UI は ClientSignals 経由でのみ開く
		SigIncoming:Fire(payload)
		return
	end

	-- AUTO_DECIDE: eligible==true の先頭を自動選択。1件も無ければ「スキップ」。
	local pickUid = chooseEligibleUid(payload)
	if not pickUid then
		LOG.warn("[KitoPickDecide] no eligible candidate; sending skip")
		local okSend, err = pcall(function()
			EvDecide:FireServer({
				sessionId  = payload.sessionId,
				targetKind = payload.targetKind or "bright",
				noChange   = true,
			})
		end)
		if not okSend then
			LOG.warn("[KitoPickDecide] skip send failed: %s", tostring(err))
		else
			LOG.info("[KitoPickDecide] sent (auto-skip)")
		end
		return
	end

	local okSend, err = pcall(function()
		EvDecide:FireServer({
			sessionId  = payload.sessionId,
			uid        = pickUid,
			targetKind = payload.targetKind or "bright",
		})
	end)
	if not okSend then
		LOG.warn("[KitoPickDecide] send failed: %s", tostring(err))
	else
		LOG.info("[KitoPickDecide] sent uid=%s (auto)", tostring(pickUid))
	end
end)

-- ─────────────────────────────────────────────────────────────
-- 受信: 結果 → UI へ
-- ─────────────────────────────────────────────────────────────
EvResult.OnClientEvent:Connect(function(res)
	if type(res) ~= "table" then return end
	LOG.info("[KitoPickResult] ok=%s changed=%s msg=%s target=%s",
		tostring(res.ok), tostring(res.changed), tostring(res.message), tostring(res.targetKind))
	SigResult:Fire(res)
end)
