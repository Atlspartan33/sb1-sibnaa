#!/usr/bin/env bash
# Plays the game in a fake Roblox engine (server + 2 players) and checks that everything works,
# then lets 4 "monkey" players tap and rub randomly for an hour of game time.
#   ./run.sh            run the play-through test
#   ./run.sh --screens  also take screenshots of every screen and 3D renders of the runway
# Needs: python3, curl, unzip. Screenshots also need node + Playwright with Chromium.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
GAME="$(cd "$HERE/../.." && pwd)"
CACHE="$HERE/.cache"
OUT="$HERE/out"
mkdir -p "$CACHE" "$OUT"

# Works on Linux, macOS and Windows (Git Bash)
case "$(uname -s)" in
	MINGW* | MSYS* | CYGWIN*) ZIP=luau-windows.zip; LUAU="$CACHE/luau.exe"; export PYTHONUTF8=1 ;;
	Darwin*) ZIP=luau-macos.zip; LUAU="$CACHE/luau" ;;
	*) ZIP=luau-ubuntu.zip; LUAU="$CACHE/luau" ;;
esac
command -v python3 >/dev/null 2>&1 || python3() { python "$@"; }
if [ ! -x "$LUAU" ]; then
	curl -sSL -o "$CACHE/luau.zip" "https://github.com/luau-lang/luau/releases/download/0.650/$ZIP"
	unzip -o -q "$CACHE/luau.zip" -d "$CACHE"
fi
if [ ! -f "$CACHE/API-Dump.json" ]; then
	curl -sSL -o "$CACHE/API-Dump.json" https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json
fi

cd "$HERE"
python3 gen_api.py "$CACHE/API-Dump.json"
python3 bundle.py "$GAME"
python3 check_props.py "$CACHE/API-Dump.json" "$GAME/src"

"$LUAU" themes_check.luau | tee "$OUT/themes.out" | tail -1
grep -q "gaps	0" "$OUT/themes.out" || { echo "A theme can't be matched with free items"; exit 1; }
"$LUAU" events.luau > "$OUT/events.out"
grep -v '^@@' "$OUT/events.out"
grep -q "errors	0	fails	0" "$OUT/events.out" || { echo "HOLIDAY EVENTS TEST FAILED"; exit 1; }
"$LUAU" play.luau > "$OUT/play.out"
grep -v '^@@' "$OUT/play.out"
"$LUAU" monkey.luau > "$OUT/monkey.out"
cat "$OUT/monkey.out"
grep -q "errors	0	warnings	0" "$OUT/monkey.out" || { echo "MONKEY TEST FAILED"; exit 1; }

if [ "${1:-}" = "--screens" ]; then
	if [ ! -d "$CACHE/three/node_modules/three" ]; then
		mkdir -p "$CACHE/three" && (cd "$CACHE/three" && npm init -y >/dev/null && npm install three@0.160.0 >/dev/null)
	fi
	python3 render.py "$OUT/play.out" "$OUT/screens"
	"$LUAU" gallery.luau > "$OUT/gallery.out" && python3 render.py "$OUT/gallery.out" "$OUT/screens"
	"$LUAU" dolls.luau > "$OUT/dolls.out" && python3 render.py "$OUT/dolls.out" "$OUT/screens"
	"$LUAU" world3d.luau > "$OUT/world.out" && python3 render3d.py "$OUT/world.out" "$OUT/3d"
	python3 render.py "$OUT/events.out" "$OUT/screens" && python3 render3d.py "$OUT/events.out" "$OUT/3d"
fi

grep -q "errors	0	warnings	0	fails	0" "$OUT/play.out" || { echo "PLAYTEST FAILED"; exit 1; }
echo "PLAYTEST PASSED"
