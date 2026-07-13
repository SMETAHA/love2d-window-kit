# Usage recipes

These recipes correspond to runnable modules in [`examples/`](../examples/).

## 1. Scrollable fullscreen canvas

Use a layer-0, non-raising viewport for an editor, skill tree or world map. Set a large virtual content size and draw only the visible bounds passed to the renderer.

```bash
love . --example=fullscreen-canvas
```

Source: [`fullscreen_canvas.lua`](../examples/fullscreen_canvas.lua).

## 2. Inventory above a game world

Put the world at layer `0` and interactive UI at layer `100`. The stack sends wheel and drag events to the topmost matching window, preventing the world from scrolling behind the inventory.

```bash
love . --example=floating-inventory
```

Source: [`floating_inventory.lua`](../examples/floating_inventory.lua).

## 3. Multiple overlapping tools

Add several floating windows to the same layer. Clicking one focuses it and moves it to the front inside that layer; the background never jumps above them.

```bash
love . --example=multi-window-dashboard
```

Source: [`multi_window_dashboard.lua`](../examples/multi_window_dashboard.lua).

## 4. Custom application theme

Configure frame, title bar, border, track, thumb, hover and active colors. Auto-hide can remain enabled without changing hit-testing or page-click behavior.

```bash
love . --example=themed-scrollbars
```

Source: [`themed_scrollbars.lua`](../examples/themed_scrollbars.lua).

## 5. Persist viewport state

Save the result of `getState()` in your settings data and pass it back to `setState()`. Callbacks include a `reason` string so analytics or UI labels can distinguish wheel, touch, keyboard and restore operations.

```bash
love . --example=state-callbacks
```

Source: [`state_callbacks.lua`](../examples/state_callbacks.lua).

## 6. Cull a very large map

Convert the visible content bounds into tile indices and iterate only that range. The example uses a 20,000 × 20,000 virtual map without visiting every tile each frame.

```bash
love . --example=large-map-culling
```

Source: [`large_map_culling.lua`](../examples/large_map_culling.lua).

## 7. Touch and orientation diagnostics

Use larger scrollbar hit targets on mobile and enable `shrinkOnResize` for floating windows. The diagnostic view shows logical dimensions, DPI scale and active touches.

```bash
love . --mobile-test
```

Source: [`mobile_test.lua`](../examples/mobile_test.lua).

## 8. Trackpad and touchscreen navigation

Enable smooth fractional wheel deltas for precision touchpads, use pinch + midpoint pan on touchscreens, and move to known content targets with easing. The same example also demonstrates delayed tap, double-tap zoom, long press, and touch-sized floating-window controls.

```bash
love . --example=navigation-lab
```

Source: [`navigation_lab.lua`](../examples/navigation_lab.lua).

```lua
viewport:setTrackpadOptions({
    smooth = true,
    friction = 14,
    zoomMode = "exponential"
})

viewport:setTouchOptions({
    panThreshold = 4,
    twoFingerPan = true,
    doubleTap = true,
    doubleTapZoom = 2
})

viewport:centerOn(target.x, target.y, {
    duration = 0.4,
    easing = "inOutQuad"
})

viewport:ensureVisible(target.x, target.y, target.w, target.h, {
    padding = 48,
    duration = 0.25
})
```

LÖVE sends both mouse wheels and laptop touchpads through `love.wheelmoved`, so smooth trackpad policy also affects a connected mouse wheel. Keep it disabled when strict wheel steps are preferable.

## 9. Resizable editor panel

Resize is opt-in, so existing floating windows keep their 1.0 behavior. Define sensible limits and let `WindowStack:resize` keep the panel on-screen after an orientation or system-window change.

```lua
local inspector = WindowManager.new({
    floating = true,
    x = 80, y = 60,
    width = 620, height = 440,
    title = "Inspector",
    draggable = true,
    resizable = true,
    resize = {
        border = 10,
        minWidth = 360,
        minHeight = 260,
        maxWidth = 1000
    }
})
```

## 10. Modal confirmation window

Give stack entries stable IDs when they must be found or restored later. A visible, enabled modal entry blocks pointer and keyboard routing to every entry below it.

```lua
stack:add(confirmWindow, {
    id = "delete-confirmation",
    layer = 1000,
    modal = true,
    draw = drawConfirmation
})

-- Close and unblock the stack.
stack:setModal(confirmWindow, false)
stack:setVisible(confirmWindow, false)
stack:focusTop()
```
