-- src/client/ui/components/renderers/ShopRenderer.lua
-- v0.9.G ShopRenderer：Shop画面の描画処理（_render 相当）

local RS = game:GetService("ReplicatedStorage")
local SharedModules = RS:WaitForChild("SharedModules")
local ShopFormat = require(SharedModules:WaitForChild("ShopFormat"))

-- renderers から 1つ上に戻って components のモジュールを参照
local ShopCells = require(script.Parent.Parent:WaitForChild("ShopCells"))
local ShopI18n  = require(script.Parent.Parent:WaitForChild("i18n"):WaitForChild("ShopI18n"))

local M = {}

function M.render(self)
  local nodes = self._nodes
  if not nodes then return end

  local p = self._payload or {}
  local items = p.items or p.stock or {}
  local lang = self._lang or ShopFormat.normLang(p.lang)
  local mon = tonumber(p.mon or p.totalMon or 0)
  local rerollCost = tonumber(p.rerollCost or 1)

  -- 残回数：nil または 負数なら「無制限」
  local remainingRaw = p.remainingRerolls
  local remaining = (remainingRaw ~= nil) and tonumber(remainingRaw) or nil
  local unlimited = (remaining == nil) or (remaining < 0)

  print(("[SHOP][UI] render lang=%s items=%d mon=%d rerollCost=%d unlimited=%s remaining=%s")
    :format(lang, #items, mon, rerollCost, tostring(unlimited), tostring(remaining)))

  -- タイトル・ボタン
  if nodes.title then
    nodes.title.Text = ShopI18n.t(lang, "title_mvp")
  end
  if nodes.deckBtn then
    nodes.deckBtn.Text = (self._deckOpen and ShopI18n.t(lang, "deck_btn_hide") or ShopI18n.t(lang, "deck_btn_show"))
  end
  if nodes.rerollBtn then
    nodes.rerollBtn.Text = ShopI18n.t(lang, "reroll_btn_fmt", rerollCost)
    local can = true
    if p.canReroll == false then can = false end
    if (not unlimited) and remaining == 0 then can = false end
    if tonumber(mon or 0) < rerollCost then can = false end
    if self._rerollBusy then can = false end
    nodes.rerollBtn.Active = can
    nodes.rerollBtn.TextTransparency = can and 0 or 0.4
    nodes.rerollBtn.BackgroundTransparency = can and 0 or 0.2
  end
  if nodes.infoTitle then
    nodes.infoTitle.Text = ShopI18n.t(lang, "info_title")
  end
  if nodes.closeBtn then
    nodes.closeBtn.Text = ShopI18n.t(lang, "close_btn")
  end

  -- 右：デッキ/情報の排他 + デッキテキスト
  do
    local deckPanel = nodes.deckPanel
    local infoPanel = nodes.infoPanel
    local deckTitle = nodes.deckTitle
    local deckText  = nodes.deckText

    if deckPanel and infoPanel then
      deckPanel.Visible = self._deckOpen
      infoPanel.Visible = not self._deckOpen
    end

    if deckPanel and deckTitle and deckText then
      local n, lst = ShopFormat.deckListFromSnapshot(p.currentDeck)
      deckTitle.Text = ShopI18n.t(lang, "deck_title_fmt", n)
      deckText.Text  = (n > 0) and lst or ShopI18n.t(lang, "deck_empty")
    end
  end

  -- 左グリッド：全消し → 全作り直し
  local scroll = nodes.scroll
  for _, ch in ipairs(scroll:GetChildren()) do
    if ch:IsA("GuiObject") and ch ~= nodes.grid then
      ch:Destroy()
    end
  end

  -- Busy制御＋Remote送信（画面の責務のまま、ここで内包）
  local function onBuy(it: any)
    if self._buyBusy then return end
    if not (self.deps and self.deps.remotes and self.deps.remotes.BuyItem) then return end
    self._buyBusy = true
    print(("[SHOP][UI] BUY click id=%s name=%s"):format(it.id or "?", it.name or "?"))
    self.deps.remotes.BuyItem:FireServer(it.id)
    task.delay(0.25, function() self._buyBusy = false end)
  end

  for _, it in ipairs(items) do
    ShopCells.create(scroll, nodes, it, lang, mon, { onBuy = onBuy })
  end

  -- CanvasSize 調整
  task.defer(function()
    local gridObj = nodes.grid
    if not gridObj then return end
    local frameW = scroll.AbsoluteSize.X
    local cellW = gridObj.CellSize.X.Offset + gridObj.CellPadding.X.Offset
    local perRow = math.max(1, math.floor(frameW / math.max(1, cellW)))
    local rows = math.ceil(#items / perRow)
    local cellH = gridObj.CellSize.Y.Offset + gridObj.CellPadding.Y.Offset
    local needed = rows * cellH + 8
    scroll.CanvasSize = UDim2.new(0, 0, 0, needed)
  end)

  -- サマリ：基本情報（下段固定）
  local s = {}
  if p.seasonSum ~= nil or p.target ~= nil or p.rewardMon ~= nil then
    table.insert(s, ShopI18n.t(lang, "summary_cleared_fmt",
      tonumber(p.seasonSum or 0), tonumber(p.target or 0),
      tonumber(p.rewardMon or 0), tonumber(p.totalMon or mon or 0)))
  end
  table.insert(s, ShopI18n.t(lang, "summary_items_fmt", #items))
  table.insert(s, ShopI18n.t(lang, "summary_money_fmt", mon))
  if unlimited then
    table.insert(s, ShopI18n.t(lang, "summary_unlimited_fmt", rerollCost))
  else
    table.insert(s, ShopI18n.t(lang, "summary_remaining_fmt", remaining or 0, rerollCost))
  end
  nodes.summary.Text = table.concat(s, "\n")
end

return M
