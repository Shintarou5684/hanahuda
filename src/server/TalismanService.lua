-- ServerScriptService/TalismanService.server.lua
-- v0.9.7-P2a  Talisman server bridge（正本：サーバのみが更新）
--  - C->S: PlaceOnSlot(index:number, talismanId:string)
--  - S->C: TalismanPlaced({ unlocked:number, slots:{string?} })
--  - 正本: state.run.talisman を RunDeckUtil.ensureTalisman で必ず用意し、唯一ここで更新
--  - 他モジュール用API: TalismanService.ensureFor(player, reason?) を公開（起動/入店時などから呼ぶ）
--  - Remotes が無い場合は ReplicatedStorage.Remotes に生成

local RS        = game:GetService("ReplicatedStorage")
local Players   = game:GetService("Players")

-- ===== Logger =====================================================
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("TalismanService")

-- ===== Dependencies ==============================================
local SharedModules = RS:WaitForChild("SharedModules")
local StateHub      = require(SharedModules:WaitForChild("StateHub"))
local RunDeckUtil   = require(SharedModules:WaitForChild("RunDeckUtil"))

-- ===== Remotes folder / events ===================================
local RemotesFolder = RS:FindFirstChild("Remotes") or (function()
  local f = Instance.new("Folder")
  f.Name = "Remotes"
  f.Parent = RS
  return f
end)()

local function ensureRemote(name: string): RemoteEvent
  local ex = RemotesFolder:FindFirstChild(name)
  if ex and ex:IsA("RemoteEvent") then return ex end
  local e = Instance.new("RemoteEvent")
  e.Name = name
  e.Parent = RemotesFolder
  return e
end

local PlaceOnSlotRE    = ensureRemote("PlaceOnSlot")     -- C->S
local TalismanPlacedRE = ensureRemote("TalismanPlaced")  -- S->C (ACK)

-- ===== Defaults / helpers ========================================

local DEFAULT_MAX     = 6
local DEFAULT_UNLOCK  = 2

local function toInt(n:any, def:number)
  local v = tonumber(n)
  if not v then return def end
  return math.floor(v)
end

local function clone6(src:{any}?): {any}
  local s = src or {}
  return { s[1], s[2], s[3], s[4], s[5], s[6] }
end

-- RunDeckUtil を使って正本を必ず用意
local function ensureBoardOnState(s:any)
  -- ensureTalisman は「不足キーを補うだけ」で既存値は壊さない前提
  local b = RunDeckUtil.ensureTalisman(s, { minUnlocked = DEFAULT_UNLOCK, maxSlots = DEFAULT_MAX })
  -- 念のため型ガード
  if typeof(b) ~= "table" then
    -- フォールバック：極小限の形
    s.run = s.run or {}
    s.run.talisman = {
      maxSlots = DEFAULT_MAX,
      unlocked = DEFAULT_UNLOCK,
      slots    = { nil, nil, nil, nil, nil, nil },
    }
    b = s.run.talisman
  end
  -- 丸め（max/unlocked/slots）
  b.maxSlots = toInt(b.maxSlots, DEFAULT_MAX)
  b.unlocked = math.max(0, math.min(b.maxSlots, toInt(b.unlocked, DEFAULT_UNLOCK)))
  if typeof(b.slots) ~= "table" then
    b.slots = { nil, nil, nil, nil, nil, nil }
  else
    b.slots = clone6(b.slots)
  end
  return b
end

local function isIndexPlaceable(b:any, idx:number)
  if typeof(b) ~= "table" or typeof(idx) ~= "number" then return false end
  if idx < 1 then return false end
  local max = toInt(b.maxSlots, DEFAULT_MAX)
  local unl = toInt(b.unlocked , DEFAULT_UNLOCK)
  if idx > max or idx > unl then return false end
  return true
end

-- ===== Public API (他サービスから呼べる) =========================
local Service = {}

-- 起動/新規ラン開始/ショップ入店前などで呼ぶ想定
function Service.ensureFor(plr: Player, reason: string?)
  local s = StateHub.get(plr)
  if not s then
    LOG.debug("ensureFor skipped (no state yet) | user=%s reason=%s", plr and plr.Name or "?", tostring(reason or ""))
    return
  end
  local b = ensureBoardOnState(s)
  LOG.debug("ensureFor | user=%s unlocked=%d max=%d reason=%s", plr.Name, toInt(b.unlocked,0), toInt(b.maxSlots,0), tostring(reason or ""))
end

-- ===== Server wiring =============================================

-- PlaceOnSlot: 唯一の“確定”経路。ここでのみ正本を更新する
PlaceOnSlotRE.OnServerEvent:Connect(function(plr: Player, idx:any, talismanId:any)
  local s = StateHub.get(plr)
  if not s then
    LOG.warn("ignored: no state | user=%s", plr and plr.Name or "?")
    return
  end

  -- 正本を必ず用意（不足キーだけ補う）
  local board = ensureBoardOnState(s)

  local index = toInt(idx, -1)
  local id    = tostring(talismanId or "")
  if id == "" then
    LOG.warn("ignored: invalid id | user=%s idx=%s id=%s", plr.Name, tostring(idx), tostring(talismanId))
    -- 現状をACKしてクライアントのプレビューを解消
    if TalismanPlacedRE then
      TalismanPlacedRE:FireClient(plr, { unlocked = board.unlocked, slots = clone6(board.slots) })
    end
    return
  end

  if not isIndexPlaceable(board, index) then
    LOG.info("rejected: out-of-range | user=%s idx=%d unlocked=%s max=%s",
      plr.Name, index, tostring(board.unlocked), tostring(board.maxSlots))
    if TalismanPlacedRE then
      TalismanPlacedRE:FireClient(plr, { unlocked = board.unlocked, slots = clone6(board.slots) })
    end
    return
  end

  -- 既に埋まっていたら上書きしない（クライアント側は空スロットにしか送らない想定）
  if board.slots[index] ~= nil then
    LOG.info("noop: slot already filled | user=%s idx=%d id(existing)=%s",
      plr.Name, index, tostring(board.slots[index]))
    if TalismanPlacedRE then
      TalismanPlacedRE:FireClient(plr, { unlocked = board.unlocked, slots = clone6(board.slots) })
    end
    return
  end

  -- ===== 正本を更新（唯一の更新点） =====
  board.slots[index] = id
  LOG.info("placed | user=%s idx=%d id=%s unlocked=%d", plr.Name, index, id, toInt(board.unlocked, DEFAULT_UNLOCK))

  -- ACK: 最新の board 断面
  if TalismanPlacedRE then
    TalismanPlacedRE:FireClient(plr, { unlocked = board.unlocked, slots = clone6(board.slots) })
  end

  -- 状態を即時にクライアントへ（RunScreen/ShopScreen は st.run.talisman を参照）
  local okPush, err = pcall(function() StateHub.pushState(plr) end)
  if not okPush then
    LOG.warn("StateHub.pushState failed: %s", tostring(err))
  end
end)

-- 起動時の軽い保険：プロフィール/state が載り次第 ensure
Players.PlayerAdded:Connect(function(plr: Player)
  -- StateHub.get が準備できるまで少しだけ待つ（最大 ~3秒 / 6回）
  task.defer(function()
    for i=1,6 do
      local s = StateHub.get(plr)
      if s then
        Service.ensureFor(plr, "PlayerAdded")
        return
      end
      task.wait(0.5)
    end
    LOG.debug("PlayerAdded ensure skipped (no state by timeout) | user=%s", plr.Name)
  end)
end)

LOG.info("ready (PlaceOnSlot/TalismanPlaced wired)")

return Service
