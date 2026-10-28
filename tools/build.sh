#!/bin/bash
# Build every game into build/ and stage the Pages site into build/site/.
#
#   Basic/<slug>/<NAME>.bas   -> build/<slug>.tap   (zmakebas, autostart 10)
#   Fun/<slug>/<NAME>.bas     -> build/<slug>.tap
#   Assembly/<slug>/<name>.asm -> build/<slug>.tap  (pasmo --tapbas)
#
# Needs: zmakebas, pasmo (both in Debian/Ubuntu), python3.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD
OUT=$ROOT/build
SITE=$OUT/site
rm -rf "$OUT"
mkdir -p "$OUT" "$SITE/tapes"

have() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1" >&2; exit 1; }; }
have zmakebas
have python3

# title = first markdown heading of the game's README, else the folder name
title_of() {
  local d=$1
  if [ -f "$d/README.md" ]; then
    sed -n 's/^# *//p' "$d/README.md" | head -1
  else
    basename "$d"
  fi
}

blurb_of() {
  # first non-empty paragraph line after the heading
  [ -f "$1/README.md" ] || { echo ""; return; }
  awk 'NR>1 && NF && !/^#/ && !/^!\[/ {print; exit}' "$1/README.md"
}

JSON="["
first=1
n=0

for section in Basic Fun Assembly; do
  [ -d "$section" ] || continue
  for d in "$section"/*/; do
    [ -d "$d" ] || continue
    d=${d%/}
    slug=$(basename "$d")
    machine=48
    tap=""
    case $section in
      Basic|Fun)
        src=$(ls "$d"/*.bas 2>/dev/null | head -1)
        [ -n "$src" ] || { echo "skip $d (no .bas)"; continue; }
        name=$(basename "${src%.bas}")
        tap=$OUT/$slug.tap
        zmakebas -a 10 -n "${name:0:10}" -o "$tap" "$src"
        ;;
      Assembly)
        have pasmo
        src=$(ls "$d"/*.asm 2>/dev/null | head -1)
        [ -n "$src" ] || { echo "skip $d (no .asm)"; continue; }
        name=$(basename "${src%.asm}")
        tap=$OUT/$slug.tap
        [ -f "$d/machine" ] && machine=$(cat "$d/machine")
        pasmo --tapbas --name "${name:0:10}" "$src" "$tap"
        ;;
    esac
    cp "$tap" "$SITE/tapes/$slug.tap"
    [ -f "$d/screenshot.png" ] && cp "$d/screenshot.png" "$SITE/tapes/$slug.png"
    t=$(title_of "$d"); b=$(blurb_of "$d")
    [ $first = 1 ] || JSON+=","
    first=0
    JSON+=$(python3 -c 'import json,sys; print(json.dumps({"slug":sys.argv[1],"title":sys.argv[2],"section":sys.argv[3],"blurb":sys.argv[4],"machine":int(sys.argv[5]),"shot":sys.argv[6]=="1"}))' \
      "$slug" "$t" "$section" "$b" "$machine" "$([ -f "$d/screenshot.png" ] && echo 1 || echo 0)")
    n=$((n+1))
    printf '  %-9s %-28s -> %s (%s bytes)\n' "$section" "$slug" "$(basename "$tap")" "$(stat -c %s "$tap")"
  done
done
JSON+="]"
echo "$JSON" > "$SITE/games.json"

cp docs/*.html docs/*.css "$SITE/" 2>/dev/null || true
cp docs/*.js "$SITE/" 2>/dev/null || true
cp LICENSE "$SITE/LICENSE.txt"

# JSSpeccy is fetched, not vendored: it is GPL and this repo is CC BY-NC-SA.
JSS=${JSSPECCY_ZIP:-}
if [ -z "$JSS" ]; then
  JSS=$OUT/jsspeccy.zip
  curl -sSL -o "$JSS" https://github.com/gasman/jsspeccy3/releases/download/v3.2/jsspeccy-3.2.zip
fi
python3 - "$JSS" "$SITE" <<'EOF'
import zipfile, sys, os
z = zipfile.ZipFile(sys.argv[1]); site = sys.argv[2]
for m in z.namelist():
    if m.startswith("jsspeccy/") and not m.endswith("/") and "__MACOSX" not in m and ".DS_Store" not in m:
        z.extract(m, site)
for n in ("COPYING",):
    if n in z.namelist():
        z.extract(n, os.path.join(site, "jsspeccy"))
EOF

echo "built $n game(s); site staged in build/site"
