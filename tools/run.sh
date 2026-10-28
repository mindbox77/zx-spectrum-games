#!/bin/bash
# Build everything, then load one game into Fuse.
#   tools/run.sh trick-or-treat
set -euo pipefail
cd "$(dirname "$0")/.."
[ $# = 1 ] || { echo "usage: tools/run.sh <slug>" >&2; exit 1; }
tools/build.sh >/dev/null
tap=build/$1.tap
[ -f "$tap" ] || { echo "no such game: $1" >&2; exit 1; }
rom=${ROM48:-/usr/share/spectrum-roms/48.rom}
exec fuse-sdl --machine 48 --rom-48 "$rom" --tape "$tap" --graphics-filter 2x --no-confirm-actions --fastload
