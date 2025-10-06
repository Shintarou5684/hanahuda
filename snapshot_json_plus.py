
from __future__ import annotations
import sys, os, json, re
from pathlib import Path
from datetime import datetime, timezone

# ===== Settings =====
MAX_LINES  = int(os.environ.get("SNAPSHOT_MAX_LINES", "300"))
OUT_NAME   = os.environ.get("SNAPSHOT_OUT", "PROJECT_SNAPSHOT.json")
SCAN_BYTES = int(os.environ.get("SNAPSHOT_SCAN_BYTES", "200000"))  # per file scan budget (bytes)

EXCLUDES = [
    ".git", ".vscode", "node_modules", "dist", "build", "__pycache__",
    ".DS_Store", ".idea", ".venv",
    "package-lock.json", "yarn.lock", "pnpm-lock.yaml",
    ".env", ".env.", ".pem", ".key", ".crt",
]

BINARY_EXT = {
    "png","jpg","jpeg","gif","webp","bmp","ico","svg",
    "mp3","wav","ogg","flac","mp4","mov","avi","mkv",
    "zip","7z","rar","gz","bz2","xz","jar",
    "rbxl","rbxlx","rbxm","rbxmx",
    "dll","exe","pdb",
}

FENCE_BY_EXT = {
    "lua":"lua","rbxl":"", "rbxlx":"", "rbxm":"", "rbxmx":"",
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

def relpath(p: Path) -> str:
    return str(p.relative_to(ROOT)).replace("\\", "/")

def is_excluded(p: Path) -> bool:
    rp = relpath(p)
    return any(x in rp for x in EXCLUDES)

def ext_of(p: Path) -> str:
    return p.suffix.lower().lstrip(".")

def is_binary(p: Path) -> bool:
    return ext_of(p) in BINARY_EXT

def read_head_lines(p: Path, limit: int) -> tuple[list[str], bool]:
    lines: list[str] = []
    truncated = False
    for enc, err in (("utf-8","strict"), ("utf-8","replace")):
        try:
            with p.open("r", encoding=enc, errors=err) as f:
                for i, line in enumerate(f):
                    if i >= limit:
                        truncated = True
                        break
                    lines.append(line.rstrip("\n"))
            break
        except Exception:
            lines, truncated = [], False
            continue
    return lines, truncated

def slurp_for_scan(p: Path, budget: int) -> str:
    try:
        with p.open("rb") as f:
            data = f.read(budget)
        try:
            return data.decode("utf-8", "replace")
        except Exception:
            return data.decode("utf-8", "replace")
    except Exception:
        return ""

def build_tree() -> str:
    lines: list[str] = []
    def walk(dir: Path, prefix: str = ""):
        try:
            items = sorted(dir.iterdir(), key=lambda p: (not p.is_dir(), p.name.lower()))
        except PermissionError:
            return
        keep = [it for it in items if not is_excluded(it)]
        last_idx = len(keep) - 1
        for idx, it in enumerate(keep):
            is_last = (idx == last_idx)
            elbow = "└── " if is_last else "├── "
            lines.append(prefix + elbow + it.name)
            if it.is_dir():
                ext_pref = "    " if is_last else "│   "
                walk(it, prefix + ext_pref)
    lines.append(ROOT.name)
    walk(ROOT)
    return "\n".join(lines)

def list_dirs_files() -> tuple[list[str], list[Path]]:
    dirs_set = set()
    files: list[Path] = []
    for p in ROOT.rglob("*"):
        if is_excluded(p):
            continue
        if p.is_dir():
            dirs_set.add(relpath(p))
        elif p.is_file():
            files.append(p)
    dirs = sorted(dirs_set, key=lambda s: s.lower())
    files.sort(key=lambda x: relpath(x).lower())
    return dirs, files

def meta_for(p: Path) -> dict:
    try:
        st = p.stat()
        size = int(st.st_size)
        mtime = datetime.fromtimestamp(st.st_mtime, tz=timezone.utc).isoformat()
    except Exception:
        size = -1
        mtime = None
    return {"size": size, "mtime": mtime}

# -------- Heuristic analyzers (Lua/text) --------
RE_WAIT = re.compile(r"WaitForChild\s*\(\s*['\"]([^'\"\)]+)['\"]\s*\)")
RE_ROUTER = re.compile(r"ScreenRouter\.register\s*\(\s*['\"]([^'\"\)]+)['\"]")
RE_FIRE_ARG = re.compile(r":FireServer\s*\(\s*['\"]([^'\"\)]*)['\"]?")
RE_FROM_SCALE = re.compile(r"\bUDim2\.fromScale\b")
RE_FROM_OFFSET = re.compile(r"\bUDim2\.fromOffset\b")
RE_UDIM2_NEW = re.compile(r"\bUDim2\.new\s*\(")
RE_LOCALE_JP = re.compile(r"['\"]jp['\"]", re.IGNORECASE)
RE_LOCALE_JA = re.compile(r"['\"]ja['\"]", re.IGNORECASE)
RE_KITO = re.compile(r"\bKito(?:Pick|Assets|Defs|Wires|PickView)\b")
RE_ONCLIENT = re.compile(r"\.OnClientEvent\b")

def analyze_text(text: str) -> dict:
    waits = RE_WAIT.findall(text)
    screens = RE_ROUTER.findall(text)
    fire_args = RE_FIRE_ARG.findall(text)
    from_scale = len(RE_FROM_SCALE.findall(text))
    from_offset = len(RE_FROM_OFFSET.findall(text))
    udim2_new = len(RE_UDIM2_NEW.findall(text))
    onclient = len(RE_ONCLIENT.findall(text))
    return {
        "waitForChild": waits,
        "routerScreens": screens,
        "fireServerArgs": [s for s in fire_args if s],
        "udim": {"fromScale": from_scale, "fromOffset": from_offset, "new": udim2_new},
        "locale": {
            "jp_literals": len(RE_LOCALE_JP.findall(text)),
            "ja_literals": len(RE_LOCALE_JA.findall(text)),
        },
        "kitoMention": bool(RE_KITO.search(text)),
        "onClientEventCount": onclient,
    }

def main():
    ROOT = Path(__file__).resolve().parent
    out_path = ROOT / OUT_NAME
    dirs, files = list_dirs_files()

    manifest = {
        "meta": {
            "tool": "snapshot_json_plus",
            "version": "0.3.0",
            "root": str(ROOT),
            "generated": datetime.now(timezone.utc).isoformat(),
            "maxLinesPerFile": MAX_LINES,
            "scanBytes": SCAN_BYTES,
            "excludes": EXCLUDES,
            "binaryExt": sorted(BINARY_EXT),
            "counts": {"dirs": len(dirs), "files": len(files)}
        },
        "tree": build_tree(),
        "dirs": dirs,
        "files": [],
        "analysis": {
            "summary": {
                "relativeLayoutRisk": [],    # files where fromOffset >> fromScale
                "routerScreens": {},         # screenName -> [paths]
                "remotes": {
                    "fireServerArgs": {},    # arg -> [paths]
                    "waitForChild": {},      # name -> [paths]
                },
                "localeJpUsage": [],         # files containing 'jp' literals
                "kitoFiles": [],             # files mentioning Kito*
            }
        }
    }

    # Per-file loop
    for f in files:
        entry = {
            "path": relpath(f),
            "ext": ext_of(f),
            "binary": is_binary(f),
            **meta_for(f)
        }
        text = ""
        if not entry["binary"]:
            head, truncated = read_head_lines(f, MAX_LINES)
            entry["head"] = head
            entry["truncated"] = truncated
            text = slurp_for_scan(f, SCAN_BYTES)

            # Lightweight analysis
            a = analyze_text(text)
            entry["analysis"] = a

            # Aggregate: relative layout risk
            ud = a["udim"]
            if ud["fromOffset"] > max(ud["fromScale"] * 2, 0) and (ud["fromOffset"] + ud["fromScale"] + ud["new"]) > 0:
                manifest["analysis"]["summary"]["relativeLayoutRisk"].append(entry["path"])

            # Aggregate: router screens
            for s in a["routerScreens"]:
                manifest["analysis"]["summary"]["routerScreens"].setdefault(s, []).append(entry["path"])

            # Aggregate: remotes
            for arg in a["fireServerArgs"]:
                manifest["analysis"]["summary"]["remotes"]["fireServerArgs"].setdefault(arg, []).append(entry["path"])
            for w in a["waitForChild"]:
                manifest["analysis"]["summary"]["remotes"]["waitForChild"].setdefault(w, []).append(entry["path"])

            # Aggregate: locale jp usage
            if a["locale"]["jp_literals"] > 0:
                manifest["analysis"]["summary"]["localeJpUsage"].append(entry["path"])

            # Aggregate: Kito
            if a["kitoMention"]:
                manifest["analysis"]["summary"]["kitoFiles"].append(entry["path"])

        manifest["files"].append(entry)

    # Write JSON
    with out_path.open("w", encoding="utf-8") as o:
        json.dump(manifest, o, ensure_ascii=False, indent=2)

    print(f"Done: {out_path}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
