-- ServerScriptService/RemotesInit.server.lua
-- v0.9.9-fix:
--  - 「この手で勝負」用の Confirm を常設
--  - 画面遷移系（HomeOpen/DecideNext/StageResult）もここで ensure
--  - 既存の KITO / Talisman / PlaceOnSlot は従来どおり

local RS = game:GetService("ReplicatedStorage")

local function ensureFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local function ensureRE(parent, name)
	local ev = parent:FindFirstChild(name)
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = parent
	end
	return ev
end

local remotes = ensureFolder(RS, "Remotes")

--==================================================
-- 既存（従来どおり）
--==================================================
ensureRE(remotes, "PlaceOnSlot")     -- C→S
ensureRE(remotes, "TalismanPlaced")  -- S→C (ACK)

-- ★ KITO ピック用（起動時に必ず用意）
ensureRE(remotes, "KitoPickStart")   -- S→C: 候補提示
ensureRE(remotes, "KitoPickDecide")  -- C→S: 決定（uid を返す）
ensureRE(remotes, "KitoPickResult")  -- S→C: 結果トースト等

--==================================================
-- ★ 追加：Run 進行・遷移系
--==================================================
ensureRE(remotes, "Confirm")     -- C→S: 「この手で勝負」
ensureRE(remotes, "DecideNext")  -- C→S: リザルトからの遷移（"home"/"koikoi"/"abandon" 等）
ensureRE(remotes, "HomeOpen")    -- S→C: ホーム画面オープン
ensureRE(remotes, "StageResult") -- S→C: ステージ結果モーダルの表示/クローズ

print("[RemotesInit] Remotes ready →", remotes:GetFullName())
