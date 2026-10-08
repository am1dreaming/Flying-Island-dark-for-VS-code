#!/usr/bin/env bash
# Installs Flying Island into VS Code on macOS. Windows: install.ps1
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CODE="${CODE:-$(command -v code || echo "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code")}"
[ -x "$CODE" ] || CODE="$HOME/Downloads/Visual Studio Code.app/Contents/Resources/app/bin/code"
[ -x "$CODE" ] || { echo "VS Code CLI not found; set CODE=/path/to/code"; exit 1; }
SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
EXT_ID_VER="$(python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); print("%s.%s-%s" % (p["publisher"], p["name"], p["version"]))' "$HERE/package.json")"
EXT_DIR="$HOME/.vscode/extensions/$EXT_ID_VER"
# The extension used to be published as "Islands Dark (CLion)".
LEGACY_EXT_ID="yaroslav.islands-dark-clion"

echo "==> Fonts (JetBrains Mono, Inter — SIL OFL 1.1, see fonts/*-OFL.txt)"
mkdir -p "$HOME/Library/Fonts"
cp -n "$HERE"/fonts/*.ttf "$HERE"/fonts/*.otf "$HOME/Library/Fonts/" 2>/dev/null || true

echo "==> Flying Island extension"
VSIX="$HERE/$(python3 "$HERE/tools/pack_vsix.py" | cut -d' ' -f1)"
# Register via the CLI (fails harmlessly while VS Code is running and the
# extension is already registered), then always sync files in place.
USER_DIR="$(dirname "$SETTINGS")"
# Every VS Code profile has its own extensions + settings: install into all.
PROFILES=("")
while IFS= read -r name; do [ -n "$name" ] && PROFILES+=("$name"); done < <(python3 - "$USER_DIR" <<'PY'
import json, sys, os
p = os.path.join(sys.argv[1], "globalStorage", "storage.json")
try:
    for pr in json.load(open(p)).get("userDataProfiles", []): print(pr["name"])
except Exception: pass
PY
)
for prof in "${PROFILES[@]}"; do
  args=(); [ -n "$prof" ] && args=(--profile "$prof")
  echo "   profile: ${prof:-Default}"
  "$CODE" ${args[@]+"${args[@]}"} --uninstall-extension "$LEGACY_EXT_ID" >/dev/null 2>&1 || true   # fine if never installed
  for ext in "$VSIX" llvm-vs-code-extensions.vscode-clangd chadalen.vscode-jetbrains-icon-theme ; do
    "$CODE" ${args[@]+"${args[@]}"} --install-extension "$ext" --force >/dev/null 2>&1 || echo "     ! $ext (restart VS Code and re-run)"
  done
done
mkdir -p "$EXT_DIR"
mkdir -p "$EXT_DIR/css"
cp -R "$HERE/package.json" "$HERE/extension.js" "$HERE/themes" "$EXT_DIR/"
cp "$HERE/css/islands.css" "$HERE/css/vibrancy.css" "$EXT_DIR/css/"
mkdir -p "$EXT_DIR/licenses"
cp "$HERE/LICENSE" "$EXT_DIR/LICENSE.txt"; cp "$HERE/NOTICE" "$EXT_DIR/NOTICE.txt"
cp "$HERE/licenses/Apache-2.0.txt" "$EXT_DIR/licenses/"

# Island geometry: the extension injects css/islands.css into workbench.html
# from inside VS Code on startup (macOS blocks external writes to the bundle).

echo "==> Merging settings into every profile (backup: settings.json.bak-islands)"
SETTING_FILES=("$SETTINGS")
for d in "$USER_DIR"/profiles/*/; do [ -f "${d}settings.json" ] && SETTING_FILES+=("${d}settings.json"); done
for f in "${SETTING_FILES[@]}"; do
  [ -f "$f" ] && [ ! -f "$f.bak-islands" ] && cp "$f" "$f.bak-islands"
  python3 - "$HERE/settings/settings.jsonc" "$f" "$HERE/css/islands.css" <<'PY'
import json, re, sys, os
src, dst, css = sys.argv[1:4]

def strip_jsonc(t):
    out, i, n, s = [], 0, len(t), False
    while i < n:
        c = t[i]
        if s:
            out.append(c)
            if c == "\\": out.append(t[i + 1]); i += 1
            elif c == '"': s = False
        elif c == '"': s = True; out.append(c)
        elif t.startswith("//", i):
            while i < n and t[i] != "\n": i += 1
            continue
        elif t.startswith("/*", i):
            i = t.index("*/", i) + 2; continue
        else: out.append(c)
        i += 1
    return re.sub(r",(\s*[}\]])", r"\1", "".join(out))

new = json.loads(strip_jsonc(open(src).read()))
cur = json.loads(strip_jsonc(open(dst).read())) if os.path.exists(dst) and open(dst).read().strip() else {}

# drop keys from the old Apc-based setup
imports = [i for i in cur.get("apc.imports", []) if not i.endswith("/islands.css")]
if imports: cur["apc.imports"] = imports
else: cur.pop("apc.imports", None)
for k in ("apc.font.family", "apc.monospace.font.family"): cur.pop(k, None)
# drop keys of the pre-rename extension ("islandsDark.*")
for k in [k for k in cur if k.startswith("islandsDark.")]: cur.pop(k)
cur.update(new)
open(dst, "w").write(json.dumps(cur, indent=4, ensure_ascii=False) + "\n")
print("   merged", len(new), "keys ->", dst.split("/User/")[-1])
PY
done

echo
echo "Done. Restart VS Code (Cmd+Q), reopen, click \"Reload Window\" in the Flying Island popup."
echo "Undo: run \"Flying Island: Remove All Patches\" in VS Code; restore each settings.json from its settings.json.bak-islands, then"
echo "      \"$CODE\" --uninstall-extension $(echo "$EXT_ID_VER" | sed 's/-[0-9.]*$//')"
