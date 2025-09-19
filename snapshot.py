# snapshot.py
# Hanahuda プロジェクト直下に置いて実行すると、同ディレクトリ配下を走査して
# フォルダツリーと各ファイルの先頭数百行を PROJECT_SNAPSHOT.md に出力します。
# 依存なし / クロスプラットフォーム（Windows・macOS・Linux）

from __future__ import annotations
import sys
import os
from pathlib import Path
from datetime import datetime

# ===== 設定 =====
MAX_LINES = 300  # 各ファイルから拾う最大行数
OUT_NAME  = "PROJECT_SNAPSHOT.md"

# 除外（部分一致・パスに含まれていたら除外）
EXCLUDES = [
    ".git", ".vscode", "node_modules", "dist", "build", "__pycache__",
    ".DS_Store", ".idea", ".venv",
    # ロック/秘密系
    "package-lock.json", "yarn.lock", "pnpm-lock.yaml",
    ".env", ".env.", ".pem", ".key", ".crt",
]

# バイナリ扱いする拡張子（中身は読まずメタ情報のみ）
BINARY_EXT = {
    "png","jpg","jpeg","gif","webp","bmp","ico","svg",
    "mp3","wav","ogg","flac","mp4","mov","avi","mkv",
    "zip","7z","rar","gz","bz2","xz","jar",
    "rbxl","rbxlx","rbxm","rbxmx",   # Roblox
    "dll","exe","pdb",
}

# コードフェンス言語（拡張子→言語）
FENCE_BY_EXT = {
    "lua": "lua","rbxl":"", "rbxlx":"", "rbxm":"", "rbxmx":"",
    "js":"js","mjs":"js","cjs":"js",
    "ts":"ts","tsx":"tsx","jsx":"jsx",
    "json":"json","yaml":"yaml","yml":"yaml","toml":"toml",
    "py":"py","rb":"rb","go":"go","rs":"rust","java":"java","kt":"kt",
    "cs":"cs","cpp":"cpp","c":"c","h":"c","hpp":"cpp",
    "php":"php","swift":"swift","sql":"sql",
    "sh":"sh","bash":"bash","zsh":"zsh",
    "md":"md","html":"html","css":"css",
    "txt":""
}

ROOT = Path(__file__).resolve().parent

def is_excluded(p: Path) -> bool:
    rp = str(p.relative_to(ROOT)).replace("\\", "/")
    return any(x in rp for x in EXCLUDES)

def ext_of(p: Path) -> str:
    return p.suffix.lower().lstrip(".")

def is_binary(p: Path) -> bool:
    return ext_of(p) in BINARY_EXT

def read_head_lines(p: Path, limit: int) -> list[str]:
    # テキスト判定：まず utf-8 で、ダメなら errors="replace"
    lines: list[str] = []
    try:
        with p.open("r", encoding="utf-8", errors="strict") as f:
            for i, line in enumerate(f):
                if i >= limit: break
                lines.append(line.rstrip("\n"))
        return lines
    except Exception:
        try:
            with p.open("r", encoding="utf-8", errors="replace") as f:
                for i, line in enumerate(f):
                    if i >= limit: break
                    lines.append(line.rstrip("\n"))
            return lines
        except Exception:
            # 最後の砦：バイナリ扱い
            return []

def build_tree() -> str:
    # フォルダ→ファイル、名前順で擬似 tree を作る
    lines: list[str] = []
    def walk(dir: Path, prefix: str = ""):
        try:
            items = sorted(dir.iterdir(), key=lambda p: (not p.is_dir(), p.name.lower()))
        except PermissionError:
            return
        last_idx = len([it for it in items if not is_excluded(it)]) - 1
        idx = -1
        for it in items:
            if is_excluded(it): 
                continue
            idx += 1
            is_last = (idx == last_idx)
            elbow = "└── " if is_last else "├── "
            lines.append(prefix + elbow + it.name)
            if it.is_dir():
                ext_pref = "    " if is_last else "│   "
                walk(it, prefix + ext_pref)
    lines.append(ROOT.name)
    walk(ROOT)
    return "\n".join(lines)

def list_files() -> list[Path]:
    files: list[Path] = []
    for p in ROOT.rglob("*"):
        if p.is_file() and not is_excluded(p):
            files.append(p)
    # 安定ソート（相対パス）
    files.sort(key=lambda x: str(x.relative_to(ROOT)).lower())
    return files

def main():
    out = ROOT / OUT_NAME

    # Header
    header = [
        "# Project Snapshot",
        "",
        f"- Root: `{ROOT}`",
        f"- Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"- Max lines/file: {MAX_LINES}",
        "",
        "## Folder Tree",
        "",
        "```text",
        build_tree(),
        "```",
        "",
        f"## Files (first {MAX_LINES} lines each)",
        ""
    ]
    out.write_text("\n".join(header), encoding="utf-8")

    # Files
    for f in list_files():
        rel = str(f.relative_to(ROOT)).replace("\\", "/")
        with out.open("a", encoding="utf-8") as o:
            o.write(f"\n### {rel}\n")
            if is_binary(f):
                try:
                    size = f.stat().st_size
                except Exception:
                    size = -1
                o.write("```text\n")
                o.write(f"[binary file] size={size} bytes\n")
                o.write("```\n")
                continue

            fence = FENCE_BY_EXT.get(ext_of(f), "")
            o.write(f"```{fence}\n")
            lines = read_head_lines(f, MAX_LINES)
            if lines:
                o.write("\n".join(lines) + "\n")
                # もっと長いかも？を示す
                try:
                    # 速く判定：limit 行読んで still data があれば“…省略”表記
                    with f.open("r", encoding="utf-8", errors="replace") as chk:
                        for _ in range(MAX_LINES):
                            chk.readline()
                        rest = chk.readline()
                        if rest:
                            o.write("... (truncated)\n")
                except Exception:
                    pass
            else:
                o.write("[unreadable or empty]\n")
            o.write("```\n")

    print(f"Done: {out}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
