#!/usr/bin/env bash
# Plays the game in a fake Roblox engine (server + 2 players) and checks that everything works.
#   ./run.sh            run the play-through test
#   ./run.sh --screens  also take screenshots of every screen and 3D renders of the runway
# Needs: python3, curl, unzip. Screenshots also need node + Playwright with Chromium.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
GAME="$(cd "$HERE/../.." && pwd)"
CACHE="$HERE/.cache"
OUT="$HERE/out"
mkdir -p "$CACHE" "$OUT"

if [ ! -x "$CACHE/luau" ]; then
	curl -sSL -o "$CACHE/luau.zip" https://github.com/luau-lang/luau/releases/download/0.650/luau-ubuntu.zip
	unzip -o -q "$CACHE/luau.zip" -d "$CACHE"
fi
if [ ! -f "$CACHE/API-Dump.json" ]; then
	curl -sSL -o "$CACHE/API-Dump.json" https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json
fi

cd "$HERE"
python3 gen_api.py "$CACHE/API-Dump.json"
python3 bundle.py "$GAME"
python3 check_props.py "$CACHE/API-Dump.json" "$GAME/src"

"$CACHE/luau" themes_check.luau | tee "$OUT/themes.out" | tail -1
grep -q "gaps	0" "$OUT/themes.out" || { echo "A theme can't be matched with free items"; exit 1; }
"$CACHE/luau" events.luau > "$OUT/events.out"
grep -v '^@@' "$OUT/events.out"
grep -q "errors	0	fails	0" "$OUT/events.out" || { echo "HOLIDAY EVENTS TEST FAILED"; exit 1; }
"$CACHE/luau" play.luau > "$OUT/play.out"
grep -v '^@@' "$OUT/play.out"

if [ "${1:-}" = "--screens" ]; then
	if [ ! -d "$CACHE/three/node_modules/three" ]; then
		mkdir -p "$CACHE/three" && (cd "$CACHE/three" && npm init -y >/dev/null && npm install three@0.160.0 >/dev/null)
	fi
	python3 render.py "$OUT/play.out" "$OUT/screens"
	"$CACHE/luau" gallery.luau > "$OUT/gallery.out" && python3 render.py "$OUT/gallery.out" "$OUT/screens"
	"$CACHE/luau" dolls.luau > "$OUT/dolls.out" && python3 render.py "$OUT/dolls.out" "$OUT/screens"
	"$CACHE/luau" world3d.luau > "$OUT/world.out" && python3 render3d.py "$OUT/world.out" "$OUT/3d"
	python3 render.py "$OUT/events.out" "$OUT/screens" && python3 render3d.py "$OUT/events.out" "$OUT/3d"
fi

grep -q "errors	0	warnings	0	fails	0" "$OUT/play.out" || { echo "PLAYTEST FAILED"; exit 1; }
echo "PLAYTEST PASSED"
