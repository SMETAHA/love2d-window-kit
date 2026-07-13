#!/usr/bin/env sh
set -eu

LUA_BIN="${LUA_BIN:-lua}"
LUAC_BIN="${LUAC_BIN:-luac}"

find . -name '*.lua' -not -path './.git/*' -exec "$LUAC_BIN" -p {} \;

for test in \
    tests/test_window_manager.lua \
    tests/test_window_stack.lua \
    tests/test_api.lua \
    tests/test_mobile_hidpi.lua \
    tests/test_main_smoke.lua
do
    "$LUA_BIN" "$test"
done

"$LUA_BIN" tests/test_examples_smoke.lua minimal
"$LUA_BIN" tests/test_examples_smoke.lua mobile
"$LUA_BIN" tests/test_examples_smoke.lua fullscreen-canvas
"$LUA_BIN" tests/test_examples_smoke.lua floating-inventory
"$LUA_BIN" tests/test_examples_smoke.lua multi-window-dashboard
"$LUA_BIN" tests/test_examples_smoke.lua themed-scrollbars
"$LUA_BIN" tests/test_examples_smoke.lua state-callbacks
"$LUA_BIN" tests/test_examples_smoke.lua large-map-culling
"$LUA_BIN" tests/test_examples_smoke.lua navigation-lab
