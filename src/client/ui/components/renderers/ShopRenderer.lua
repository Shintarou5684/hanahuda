-- src/client/ui/components/renderers/ShopRenderer.lua
-- v0.9.SIMPLE-2 ShopRenderer：Shop画面の描画処理（_render 相当）
-- ポリシー: リロール可否は「所持金 >= 費用」のみで判定。_rerollBusy は renderer では参照しない。

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
  local mon = tonumber(p.mon or p.totalMon or 0) or 0
  local rerollCost = tonumber(p.rerollCost or 1) or 1

  print(("[SHOP][UI] render lang=%s items=%d mon=%d rerollCost=%d")
    :format(lang, #items, mon, rerollCost))

  -- タイトル・ボタン
  if nodes.title then
    nodes.title.Text = ShopI18n.t(lang, "title_mvp")
  end
  if nodes.deckBtn then
    nodes.deckBtn.Text = (self._deckOpen and ShopI18n.t(lang, "deck_btn_hide") or ShopI18n.t(lang, "deck_btn_show"))
  end
  if nodes.rerollBtn then
    nodes.rerollBtn.Text = ShopI18n.t(lang, "reroll_btn_fmt", rerollCost)

    -- 可否は「所持金>=費用」だけで決定（_rerollBusy は wire 側で抑止）
    local can = (p.canReroll ~= false) and (mon >= rerollCost)
    nodes.rerollBtn.Active = can
    nodes.rerollBtn.AutoButtonColor = can

    -- 見た目は固定（無効時も色は薄くしない）
    nodes.rerollBtn.TextTransparency = 0
    nodes.rerollBtn.BackgroundTransparency = 0
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
  if not scroll then return end
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

  -- サマリ：基本情報のみ（残回数表示は撤去）
  local s = {}
  if p.seasonSum ~= nil or p.target ~= nil or p.rewardMon ~= nil then
    table.insert(s, ShopI18n.t(lang, "summary_cleared_fmt",
      tonumber(p.seasonSum or 0), tonumber(p.target or 0),
      tonumber(p.rewardMon or 0), tonumber(p.totalMon or mon or 0)))
  end
  table.insert(s, ShopI18n.t(lang, "summary_items_fmt", #items))
  table.insert(s, ShopI18n.t(lang, "summary_money_fmt", mon))
  nodes.summary.Text = table.concat(s, "\n")
end

return M
