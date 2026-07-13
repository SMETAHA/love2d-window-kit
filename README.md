<p align="center">
  <img src="assets/banner.svg" alt="LÖVE Window Kit" width="100%">
</p>

<p align="center">
  <a href="https://github.com/SMETAHA/love2d-window-kit/releases/latest"><img src="https://img.shields.io/github/v/release/SMETAHA/love2d-window-kit?color=ec4899" alt="Latest release"></a>
  <a href="https://github.com/SMETAHA/love2d-window-kit/actions/workflows/ci.yml"><img src="https://github.com/SMETAHA/love2d-window-kit/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/SMETAHA/love2d-window-kit/actions/workflows/pages.yml"><img src="https://github.com/SMETAHA/love2d-window-kit/actions/workflows/pages.yml/badge.svg" alt="GitHub Pages"></a>
  <img src="https://img.shields.io/badge/LÖVE-11.5-EA316E?logo=love&logoColor=white" alt="LÖVE 11.5">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-22C55E" alt="MIT License"></a>
</p>

<p align="center">
  Small Lua modules for scrollable and zoomable viewports, floating windows,
  input routing, precision trackpads and touchscreen gestures in LÖVE2D.
</p>

<p align="center">
  <a href="https://smetaha.github.io/love2d-window-kit/"><strong>Live examples</strong></a> ·
  <a href="docs/API.en.md">API</a> ·
  <a href="docs/RECIPES.md">Recipes</a> ·
  <a href="docs/README.ru.md">Русская версия</a>
</p>

## What it includes

- Scroll, drag, keyboard and kinetic navigation.
- Cursor-anchored zoom and animated camera helpers.
- Smooth fractional input for precision touchpads.
- One-finger pan, pinch + two-finger pan, double tap and long press.
- Draggable and resizable floating windows with focus and capture.
- Layered stacks, modal routing, styled scrollbars and saved state.

The runtime has no third-party dependencies and remains compatible with the Lua
5.1 / LuaJIT semantics used by LÖVE.

## Quick start

Copy `WindowManager.lua`, `WindowStack.lua` and `SystemWindow.lua` into your
project. Create a viewport and add it to a stack:

```lua
local WindowManager = require("WindowManager")
local WindowStack = require("WindowStack")

local windows = WindowStack.new()
local map = WindowManager.new({
    contentWidth = 4200,
    contentHeight = 2800,
    minZoom = 0.35,
    maxZoom = 3,
    inertia = true,
    input = {
        trackpad = { smooth = true },
        touchscreen = { doubleTap = true, twoFingerPan = true }
    }
})

windows:add(map, {
    id = "map",
    draw = function(scrollX, scrollY, visibleWidth, visibleHeight)
        -- Draw in content-space coordinates here.
    end
})

function love.update(dt) windows:update(dt) end
function love.draw() windows:draw() end
function love.wheelmoved(...) windows:wheelmoved(...) end
function love.touchpressed(...) windows:touchpressed(...) end
function love.touchmoved(...) windows:touchmoved(...) end
function love.touchreleased(...) windows:touchreleased(...) end
```

Use [`examples/minimal.lua`](examples/minimal.lua) for the complete mouse,
keyboard, touch, resize and focus callback bridge. When native touch callbacks
are forwarded, ignore mouse events with `istouch == true` so a touch is not
processed twice.

## Modules

| Module | Responsibility |
| --- | --- |
| `WindowManager` | One viewport: content coordinates, scroll, zoom, gestures and chrome |
| `WindowStack` | Multiple viewports: layers, focus, capture, modal routing and state |
| `SystemWindow` | The real LÖVE window: size, fullscreen, DPI and platform flags |

## Live examples

The [demo site](https://smetaha.github.io/love2d-window-kit/) runs the real Lua
project through `love.js`. The same scenarios can be launched locally:

| Scenario | Command | Shows |
| --- | --- | --- |
| Minimal | `love . --minimal` | Smallest complete integration |
| Navigation lab | `love . --example=navigation-lab` | Touchpad, pinch + pan, tap/hold and touch resize |
| Fullscreen canvas | `love . --example=fullscreen-canvas` | Large pan-and-zoom canvas |
| Floating inventory | `love . --example=floating-inventory` | Game UI above a world viewport |
| Window dashboard | `love . --example=multi-window-dashboard` | Layers, focus and overlapping windows |
| Themed scrollbars | `love . --example=themed-scrollbars` | Paging, hover, fade and colors |
| State and callbacks | `love . --example=state-callbacks` | Save/restore and event reasons |
| Large map | `love . --example=large-map-culling` | Visible-range drawing on a 20k × 20k map |
| Mobile diagnostics | `love . --mobile-test` | Touch IDs, logical DPI and orientation |
| Full showcase | `love .` | Combined desktop demonstration |

## Navigation helpers

```lua
map:centerOn(player.x, player.y, {
    duration = 0.35,
    easing = "inOutQuad"
})

map:ensureVisible(item.x, item.y, item.w, item.h, {
    padding = 48,
    duration = 0.25
})
```

See the [API reference](docs/API.en.md) for configuration, callbacks and exact
method signatures. Mobile projects should also use the
[device checklist](docs/MOBILE_TEST.en.md).

## Testing

```bash
sh scripts/run_tests.sh
```

The suite covers geometry, input ownership, touchpad momentum, touchscreen
gestures, high-DPI coordinates, stack behavior and every runnable example. CI
also runs the project with LÖVE 11.5 and builds the browser demo.

## License

[MIT](LICENSE). Contributions and focused bug reports are welcome; see
[CONTRIBUTING.md](CONTRIBUTING.md).
