-- src/client/ui/components/controllers/ShopWires.lua
-- v0.9.3-P0-5 ShopWires：Shop画面のイベント配線・UI更新のみ
-- ポリシー:
--  - リロールは「所持金>=費用」でのみ可否判定（残回数は見ない）
--  - 二重送出防止：UIを即時無効化し、nonce を付与してサーバへ送信
--  - UIの再有効化はサーバからの ShopOpen ペイロード受信時に判定して行う
--  - （重要/P0-5）ShopOpen の受信は ClientMain に一本化。本モジュールはリスナーを持たない。

local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat = require(SharedModules:WaitForChild("ShopFormat"))

local ShopI18n  = require(script.Parent.Parent:WaitForChild("i18n"):WaitForChild("ShopI18n"))

local M = {}

-- 内部: リロールボタン状態を payload から再評価して反映
local function applyRerollButtonState(self, payload)
  local p = payload or self._payload or {}
  local money = tonumber(p.mon or p.totalMon or 0) or 0
  local cost  = tonumber(p.rerollCost or 1) or 1
  local can   = (p.canReroll ~= false) and (money >= cost)
  if self._nodes and self._nodes.rerollBtn then
    self._nodes.rerollBtn.Active = can
    self._nodes.rerollBtn.AutoButtonColor = can
  end
end

function M.applyInfoPlaceholder(self)
  if not (self and self._nodes and self._nodes.infoText) then return end
  local lang = ShopFormat.normLang(self._lang)
  self._nodes.infoText.Text = ShopI18n.t(lang, "info_placeholder")
end

function M.wireButtons(self)
  local nodes = self._nodes
  if not nodes then return end

  nodes.closeBtn.Activated:Connect(function()
    if self._closing then return end
    self._closing = true
    print("[SHOP][UI] close clicked")
    self:hide()
    if self.deps and self.deps.toast then
      local lang = ShopFormat.normLang(self._lang)
      self.deps.toast(ShopI18n.t(lang, "toast_closed"), 2)
    end
    if self.deps and self.deps.remotes and self.deps.remotes.ShopDone then
      self.deps.remotes.ShopDone:FireServer()
    end
    task.delay(0.2, function() self._closing = false end)
  end)

  -- リロール：nonce 付き送信 + 即時UI無効化（解除はサーバ応答時に行う）
  local rerollBusyDebounce = 0.3
  nodes.rerollBtn.Activated:Connect(function()
    if self._rerollBusy then return end
    if not (self.deps and self.deps.remotes and self.deps.remotes.ShopReroll) then return end

    self._rerollBusy = true

    -- 即時に押下不能にする（見た目はShopUIに委譲）
    if self._nodes and self._nodes.rerollBtn then
      self._nodes.rerollBtn.Active = false
    end

    -- nonce を付与して送信
    local nonce = HttpService:GenerateGUID(false)
    self._lastRerollNonce = nonce
    print("[SHOP][UI] REROLL click → FireServer(nonce=", nonce, ")")
    self.deps.remotes.ShopReroll:FireServer(nonce)

    -- debounce経過後にbusyフラグだけ解除（UIの再有効化はサーバ側のShopOpen受信時に行う）
    task.delay(rerollBusyDebounce, function()
      self._rerollBusy = false
      -- ここで self:_render() は呼ばない（旧payloadで再度有効化されるのを防ぐ）
    end)
  end)

  nodes.deckBtn.Activated:Connect(function()
    self._deckOpen = not self._deckOpen
    print("[SHOP][UI] deck toggle ->", self._deckOpen)
    self:_render()
  end)
end

-- ⚠ 非推奨：ShopOpenのリスナー接続は行わない。ClientMainが単独で受ける。
-- 互換用に「payloadを渡すとUIだけ更新する」関数を返す。
function M.attachRemotes(self, remotes, router)
  warn("[SHOP][UI] attachRemotes is deprecated; ClientMain handles <ShopOpen>. UI will only refresh.")
  -- 互換クロージャ：外部で新payloadを受け取ったときに UI を更新するための関数
  return function(payload)
    -- 言語の注入（payload優先→既存→"en"）
    if payload and payload.lang and type(payload.lang) == "string" then
      self._lang = ShopFormat.normLang(payload.lang)
    end
    -- 画面表示＆描画（遷移はしない／Routerは使わない）
    self:show(payload)
    -- リロール可否の再評価
    applyRerollButtonState(self, payload)
  end
end

return M
