-- src/client/ui/components/controllers/ShopWires.lua
-- v0.9.G ShopWires：Shop画面のイベント配線・Remotes・プレースホルダ適用

local RS = game:GetService("ReplicatedStorage")
local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat = require(SharedModules:WaitForChild("ShopFormat"))

local ShopI18n  = require(script.Parent.Parent:WaitForChild("i18n"):WaitForChild("ShopI18n"))

local M = {}

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

  local rerollBusyDebounce = 0.3
  nodes.rerollBtn.Activated:Connect(function()
    if self._rerollBusy then return end
    if not (self.deps and self.deps.remotes and self.deps.remotes.ShopReroll) then return end
    self._rerollBusy = true
    print("[SHOP][UI] REROLL click → FireServer()")
    self.deps.remotes.ShopReroll:FireServer()
    task.delay(rerollBusyDebounce, function() self._rerollBusy = false end)
  end)

  nodes.deckBtn.Activated:Connect(function()
    self._deckOpen = not self._deckOpen
    print("[SHOP][UI] deck toggle ->", self._deckOpen)
    self:_render()
  end)
end

function M.attachRemotes(self, remotes, router)
  if not remotes or not remotes.ShopOpen then
    warn("[SHOP][UI] attachRemotes: invalid remotes")
    return
  end
  remotes.ShopOpen.OnClientEvent:Connect(function(payload)
    print("[SHOP][UI] <ShopOpen> received payload, items=",
      (payload and (payload.items and #payload.items or payload.stock and #payload.stock)) or 0)
    if router and type(router.show) == "function" then
      router:show("shop", payload)
    end
    self:show(payload)
  end)
  print("[SHOP][UI] attachRemotes: OK")
end

return M
