#!/usr/bin/env bash
# sync-local.sh — seat Kitsune in the local RyoStore catalogue tree and
# reinstall it, for the development loop.
#
#   repo (this folder's parent tree, as lockscreens/kitsune)
#     -> ~/Documents/GitHub/ryostore-local (the stable local catalogue)
#     -> ryostore install lockscreens kitsune
#
# The local tree is the durable seat: the file:// override in
# ~/.config/ryoku/ryostore-base points there, and the tree is never
# branch-switched, so a store refresh cannot unseat the theme.
set -eu

REPO="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="$HOME/Documents/GitHub/ryostore-local"
PRODUCT="$STAGE/lockscreens/kitsune"

if [ ! -f "$HOME/.config/ryoku/ryostore-base" ]; then
    echo "sync-local: no ryostore-base override — the store is serving the published catalogue; refusing" >&2
    exit 1
fi

mkdir -p "$PRODUCT/content" "$PRODUCT/assets"
cp -r "$REPO/content/." "$PRODUCT/content/"
cp "$REPO/assets/preview.webp" "$PRODUCT/assets/preview.webp"
cp "$REPO/LICENSE" "$REPO/PROVENANCE.txt" "$PRODUCT/"

DIGEST="$(python3 "$REPO/tools/build-manifest.py" "$PRODUCT")"
python3 - "$STAGE/lockscreens/registry.json" "$DIGEST" <<'PY'
import json, sys
path, digest = sys.argv[1], sys.argv[2]
doc = json.load(open(path))
for row in doc["lockscreens"]:
    if row["id"] == "kitsune":
        row["manifestSha256"] = digest
json.dump(doc, open(path, "w"), indent=2, ensure_ascii=False)
open(path, "a").write("\n")
print("registry digest:", digest)
PY

git -C "$STAGE" add -A
git -C "$STAGE" -c user.email=local@jurai -c user.name=jurai-local \
    commit -qm "kitsune: sync from repo" || true

"$HOME/.local/bin/jurai-storecheck" lockscreens kitsune

ryostore remove lockscreens kitsune >/dev/null 2>&1 || true
rm -rf "$HOME/.local/share/qylock/themes/kitsune"
ryostore install lockscreens kitsune

# Her ground on this machine: the theme-local Backgrounds seat, linked
# to the current wallpaper — the lock shows it blurred (his word).
WP="$(python3 -c "import json; print(json.load(open('$HOME/.config/jurai/wallpaper.json'))['path'])" 2>/dev/null || true)"
if [ -n "$WP" ] && [ -f "$WP" ]; then
    mkdir -p "$HOME/.local/share/qylock/themes/kitsune/Backgrounds"
    ln -sf "$WP" "$HOME/.local/share/qylock/themes/kitsune/Backgrounds/wallpaper.jpg"
    echo "sync-local: ground linked -> $WP"
fi
echo "sync-local: kitsune seated from $REPO"
