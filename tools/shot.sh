#!/bin/bash
# Headless screenshot of a game under Fuse, for READMEs and the site.
#   tools/shot.sh <slug> [keys...]
# Loads build/<slug>.tap in a virtual X display, types LOAD "", waits, then
# presses any extra keys given (xdotool names, e.g. space 1 Return), and
# writes <section>/<slug>/screenshot.png. Needs fuse-sdl, Xvfb, xdotool,
# imagemagick and the 48K ROM (spectrum-roms package).
set -euo pipefail
cd "$(dirname "$0")/.."
[ $# -ge 1 ] || { echo "usage: tools/shot.sh <slug> [keys...]" >&2; exit 1; }
slug=$1; shift
tools/build.sh >/dev/null
tap=$PWD/build/$slug.tap
[ -f "$tap" ] || { echo "no such game: $slug" >&2; exit 1; }
dir=""
for s in Basic Fun Assembly; do [ -d "$s/$slug" ] && dir=$s/$slug && break; done
[ -n "$dir" ] || { echo "no folder for $slug" >&2; exit 1; }
rom=${ROM48:-/usr/share/spectrum-roms/48.rom}

export DISPLAY=:99
pkill -x fuse-sdl 2>/dev/null || true; pkill -x Xvfb 2>/dev/null || true; sleep 1
Xvfb :99 -screen 0 1024x768x24 >/dev/null 2>&1 &
sleep 2
fuse-sdl --machine 48 --rom-48 "$rom" --tape "$tap" --no-sound --graphics-filter 2x \
  --no-confirm-actions --no-statusbar --fastload >/dev/null 2>&1 &
sleep 8
W=$(xdotool search --name -- "Fuse" | head -1)
xdotool windowmove "$W" 0 0; xdotool windowfocus "$W"; sleep 1
key() { xdotool keydown "$1"; sleep 0.25; xdotool keyup "$1"; sleep 0.5; }
key j; key ctrl+p; key ctrl+p; key Return         # LOAD ""
sleep 8
for k in "$@"; do key "$k"; sleep 1; done
sleep 2
import -window root -crop 576x448+32+16 +repage "$dir/screenshot.png"
pkill -x fuse-sdl; pkill -x Xvfb
echo "$dir/screenshot.png"
