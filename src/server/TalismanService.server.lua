-- ServerScriptService/TalismanService.server.lua
-- v0.9.7-P2  Talisman server bridge
--  - C->S: PlaceOnSlot(index:number, talismanId:string)
--  - S->C: TalismanPlaced({ unlocked:number, slots:{string?} })
--  - サーバ状態 state.run.talisman を安全に更新し、StateHub.pushState で即時UIへ反映
--  - Remotes が無い場合は ReplicatedStorage.Remotes に生成

local RS        = game:GetService("ReplicatedStorage")
local Players   = game:GetService("Players")

-- ===== Logger =====================================================
local Logger = require(RS:WaitForChild("SharedModules"):WaitForChild("Logger"))
local LOG    = Logger.scope("TalismanService")

-- ===== Dependencies ==============================================
local SharedModules = RS:WaitForChild("SharedModules")
local StateHub      = require(SharedModules:WaitForChild("StateHub"))
local TaliState     = require(SharedModules:WaitForChild("TalismanState"))

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

local PlaceOnSlotRE   = ensureRemote("PlaceOnSlot")     -- C->S
local TalismanPlacedRE= ensureRemote("TalismanPlaced")  -- S->C (ACK)

-- ===== Helpers ====================================================

local DEFAULT_MAX     = 6
local DEFAULT_UNLOCK  = 2

local function toInt(n:any, def:number)
  local v = tonumber(n)
  if not v then return def end
  v = math.floor(v)
  return v
end

local function clone6(src:{any}?): {any}
  local s = src or {}
  return { s[1], s[2], s[3], s[4], s[5], s[6] }
end

-- state.run.talisman の存在と最低限の形を保証
local function ensureBoard(s:any)
  s.run = s.run or {}
  local b = s.run.talisman
  if typeof(b) ~= "table" then
    -- 可能ならモジュールの初期化ヘルパに委譲
    local ok = pcall(function() TaliState.ensureRunBoard(s) end)
    if ok and s.run and typeof(s.run.talisman) == "table" then
      return s.run.talisman
    end
    -- フォールバック（最低限の既定形）
    b = {
      maxSlots = DEFAULT_MAX,
      unlocked = DEFAULT_UNLOCK,
      slots    = { nil, nil, nil, nil, nil, nil },
    }
    s.run.talisman = b
  else
    -- 欠損補完
    b.maxSlots = toInt(b.maxSlots, DEFAULT_MAX)
    b.unlocked = math.max(0, math.min(b.maxSlots, toInt(b.unlocked, DEFAULT_UNLOCK)))
    local slots = b.slots
    if typeof(slots) ~= "table" then
      b.slots = { nil, nil, nil, nil, nil, nil }
    else
      -- 6レングスに丸める（多すぎ/少なすぎ両対応）
      b.slots = clone6(slots)
    end
  end
  return b
end

-- index が有効か（1..unlocked かつ <= maxSlots）
local function isIndexPlaceable(b:any, idx:number)
  if typeof(b) ~= "table" then return false end
  if typeof(idx) ~= "number" then return false end
  if idx < 1 then return false end
  local max = toInt(b.maxSlots, DEFAULT_MAX)
  local unl = toInt(b.unlocked , DEFAULT_UNLOCK)
  if idx > max or idx > unl then return false end
  return true
end

-- ===== Core: handler =============================================

PlaceOnSlotRE.OnServerEvent:Connect(function(plr: Player, idx:any, talismanId:any)
  local s = StateHub.get(plr)
  if not s then
    LOG.warn("ignored: no state | user=%s", plr and plr.Name or "?")
    return
  end

  local index = toInt(idx, -1)
  local id    = tostring(talismanId or "")
  if id == "" then
    LOG.warn("ignored: invalid id | user=%s idx=%s id=%s", plr.Name, tostring(idx), tostring(talismanId))
    return
  end

  local board = ensureBoard(s)
  if not isIndexPlaceable(board, index) then
    LOG.info("rejected: out-of-range | user=%s idx=%d unlocked=%s max=%s",
      plr.Name, index, tostring(board.unlocked), tostring(board.maxSlots))
    -- それでもACKは返す（クライアントのローカル影を正に寄せる）
    if TalismanPlacedRE then
      TalismanPlacedRE:FireClient(plr, { unlocked = board.unlocked, slots = clone6(board.slots) })
    end
    return
  end

  -- 既に埋まっていたら上書きしない（UIは常に空スロットを送るはず）
  if board.slots[index] ~= nil then
    LOG.info("noop: slot already filled | user=%s idx=%d id(existing)=%s",
      plr.Name, index, tostring(board.slots[index]))
    if TalismanPlacedRE then
      TalismanPlacedRE:FireClient(plr, { unlocked = board.unlocked, slots = clone6(board.slots) })
    end
    return
  end

  board.slots[index] = id
  LOG.info("placed | user=%s idx=%d id=%s unlocked=%d", plr.Name, index, id, toInt(board.unlocked, DEFAULT_UNLOCK))

  -- ACK: 最新の board 断面
  if TalismanPlacedRE then
    TalismanPlacedRE:FireClient(plr, { unlocked = board.unlocked, slots = clone6(board.slots) })
  end

  -- 状態を即反映（RunScreen は StatePush の st.run.talisman を見る）
  local okPush, err = pcall(function() StateHub.pushState(plr) end)
  if not okPush then
    LOG.warn("StateHub.pushState failed: %s", tostring(err))
  end
end)

LOG.info("ready (PlaceOnSlot/TalismanPlaced wired)")
