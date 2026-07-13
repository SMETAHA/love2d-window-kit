# Contributing

Thanks for helping improve LÖVE Window Kit.

## Before opening a pull request

1. Keep changes focused and avoid unrelated formatting rewrites.
2. Preserve compatibility with Lua 5.1 / LuaJIT and LÖVE 11.5.
3. Add or update a test for every behavioral change.
4. Update `docs/API.en.md`, `docs/API.md`, and `CHANGELOG.md` when the public API changes.
5. Run:

```bash
sh scripts/run_tests.sh
```

## Code style

- Four spaces, no tabs.
- English identifiers, comments and user-facing strings in source code.
- Methods that mutate configuration should validate input and return `self` when chaining is useful.
- Input handlers return `true` only when the event belongs to that viewport.
- Store scrolling in content-space units; convert to screen-space only while drawing.

## New examples

Add runnable scenarios to `examples/`, register them in the whitelist near the top of `main.lua`, document the command in `README.md`, and extend `tests/test_examples_smoke.lua`.

## Reporting bugs

Include your OS, LÖVE version, a minimal reproduction and the exact input sequence. For touch or DPI bugs, also include logical window dimensions and `love.graphics.getDPIScale()`.
