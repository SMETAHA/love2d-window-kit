# API 1.1.0

## WindowManager

`WindowManager.new(options?)` creates one viewport. Every option is optional.

| Option | Type | Purpose |
| --- | --- | --- |
| `floating` | boolean | Floating viewport or fullscreen area |
| `x`, `y` | number | Floating-window position |
| `width`, `height` | number | Viewport dimensions |
| `contentWidth`, `contentHeight` | number | Virtual content dimensions |
| `title` | string | Title-bar text |
| `titleBarHeight` | number | Title-bar height |
| `draggable` | boolean | Allow title-bar window dragging |
| `resizable` | boolean | Enable edge/corner resizing for floating windows |
| `resize` | table | Resize border and min/max window size |
| `dragToScroll` | boolean | Allow content dragging |
| `zoom`, `minZoom`, `maxZoom` | number | Initial zoom and limits |
| `scrollSpeed` | number | Wheel and keyboard step |
| `alignSmallContent` | boolean | Center content smaller than the viewport |
| `scrollbar` | table | Scrollbar configuration |
| `input` | table | Wheel, keyboard, touch, axes, and zoom-modifier policy |
| `inertia` | table/boolean | Opt-in kinetic scrolling |
| `theme` | table | Frame and title-bar colors |
| `callbacks` | table | Scroll, zoom, layout, and navigation callbacks |

### Scrollbar options

`visible`, `horizontal`, `vertical`, `width`, `minThumbSize`, `pageStep`, `autoHide`, `autoHideDelay`, `fadeDuration`, `color`, `trackColor`, `hoverColor`, and `activeColor`.

A color is `{r, g, b, a}` with components in the `0..1` range. `pageStep` is the fraction of the visible area used when the scrollbar track is clicked.

### Resize options

`border`, `minWidth`, `minHeight`, `maxWidth`, and `maxHeight`. Resizing is opt-in, constrained to the screen, and does not interfere with single-axis scrollbar tracks. Corners remain resize handles.

### Input options

| Option | Default | Purpose |
| --- | --- | --- |
| `wheel`, `keyboard`, `touch` | `true` | Enable each input source |
| `horizontal`, `vertical` | `true` | Axes affected by user input |
| `pinchZoom` | `true` | Two-finger zoom around the gesture midpoint |
| `shiftWheelHorizontal` | `true` | Convert Shift + vertical wheel into horizontal scrolling |
| `zoomModifier` | `"ctrl"` | `ctrl`, `alt`, `shift`, `meta`, or `none` |
| `zoomStep` | `0.1` | Wheel and keyboard zoom increment |

### Inertia options

`enabled`, `friction`, `minVelocity`, and `maxPause`. Inertia is disabled by default to preserve 1.0 behavior. It can be enabled with `inertia = true` or a configuration table. `maxPause` prevents a stale fling after the pointer stopped before release.

### Theme options

`frameColor`, `titleBarColor`, `titleTextColor`, and `borderColor`.

### Callbacks

```lua
onScroll(x, y, oldX, oldY, viewport, reason)
onZoom(oldZoom, zoom, viewport, reason)
onMove(x, y, oldX, oldY, viewport, reason)
onResize(width, height, oldWidth, oldHeight, viewport, reason)
onNavigationComplete(viewport, reason)
```

Each state mutation reports coordinates after they have been clamped. Cursor-anchored zoom therefore reports the final scroll and zoom state. An animation emits changes as the view advances, then calls `onNavigationComplete` once. Construction does not emit callbacks.

Common reasons include `wheel`, `wheel-zoom`, `content-drag`, `touch-drag`, `pinch`, `inertia`, `vertical-drag`, `horizontal-drag`, `window-drag`, `window-resize`, `scroll-to`, `zoom-to`, `ensure-visible`, `keyboard`, `resize`, and `state`.

### Main methods

- `configure(options)` — apply an options table.
- `setFloating(x, y, w, h)` / `setFullscreen()`.
- `setPosition(x, y)` / `setSize(w, h)`.
- `setResizable(enabled, options?)` / `setSizeLimits(minW, minH, maxW?, maxH?)`.
- `setContentSize(w, h)`.
- `setTitle(title)` / `setTitleBar(height, draggable)`.
- `setZoom(value, anchorX?, anchorY?, reason?)`.
- `setZoomLimits(min, max)` / `zoomIn(step?)` / `zoomOut(step?)`.
- `setScrollbarOptions(options)` / `setTheme(theme)`.
- `setInputOptions(options)` / `setInertia(options)`.
- `setCallbacks(callbacks)` and the individual `setOn…` methods.
- `scrollTo(x, y, options?)` / `scrollBy(dx, dy, options?)`.
- `zoomTo(value, anchorX?, anchorY?, options?)`.
- `centerOn(contentX, contentY, options?)` / `ensureVisible(x, y, w, h, options?)`.
- `isNavigating()` / `cancelNavigation()`.
- `screenToContent(x, y)` / `contentToScreen(x, y)`.
- `getViewportSize()` / `getVisibleBounds()` / `getScrollLimits()`.
- `isContentRectVisible(x, y, w, h, fully?)` / `hitTest(x, y)`.
- `getState()` / `setState(state)`.
- `constrainToScreen(w, h, shrink)` — responsive floating layout.
- `draw(fn)` — isolated drawing; the graphics stack is restored if `fn` fails.
- `cancelInput()` — cancel unfinished gestures.

Input methods return `true` when the event belongs to the viewport. Applications normally call them through `WindowStack`.

Navigation options accept `duration`, `easing`, and `reason`. A zero or omitted duration applies the change immediately. Built-in easing values are `linear`, `outQuad`, and `inOutQuad`; a custom function is also accepted. `ensureVisible` additionally accepts content-space `padding`.

`getVisibleBounds()` returns `left, top, right, bottom`; `getScrollLimits()` returns `minX, maxX, minY, maxY`. `hitTest()` returns `content`, `titlebar`, a scrollbar thumb/track name, a `resize-*` direction, or `nil` outside the viewport.

## WindowStack

```lua
local stack = WindowStack.new()
stack:add(window, options)
```

### Add options

| Option | Purpose |
| --- | --- |
| `draw` | Viewport content renderer |
| `id` | Stable non-empty ID used by lookup and stack state persistence |
| `layer` | Persistent z-order group; defaults to `0`, or `100` for floating windows |
| `visible`, `enabled`, `focusable` | Window state |
| `modal` | Block input and focus for every entry below this one |
| `raiseOnFocus` | Raise inside the current layer on input |
| `constrainOnResize` | Keep a floating viewport on-screen |
| `shrinkOnResize` | Temporarily shrink it during orientation changes |
| `onFocus`, `onBlur` | Focus notifications |
| `onCaptureLost` | Forced mouse/touch capture cancellation |

### Management

- `add`, `remove`, `clear`, `contains`, `count`.
- `getEntry`, `getById`, `getWindows`, `getTop`, `getModal`.
- `focus`, `focusTop`, `focusNext(reverse?)`, `getActive`.
- `bringToFront`, `sendToBack`, `setLayer`.
- `setVisible`, `setEnabled`, `setFocusable`, `setModal`, `setDraw`.
- `getState()` / `setState(state)` for entries that have IDs.
- `update`, `draw`, `resize`, `cancelInput`.

Forward mouse, wheel, touch, keyboard, `textinput`, and `textedited` callbacks to the stack. A mouse gesture stays with one window until release; each touch ID is captured independently.

Stack state contains only entries with stable IDs. If a managed window implements `getState` and `setState`, its own state is nested and restored automatically. Activating a modal entry cancels captures held below the modal boundary.

## SystemWindow

`SystemWindow.configure(options)` configures the real OS window through `love.window.setMode`. Supported fields: `width`, `height`, `title`, `fullscreen`, `fullscreentype`, `vsync`, `resizable`, `borderless`, `centered`, `highdpi`, `usedpiscale`, `msaa`, `minwidth`, and `minheight`.

`WindowManager:setSystemWindow` remains as a compatibility delegate. New code should call `SystemWindow` directly.

## Coordinates and DPI

Scroll is stored in content-space units. Viewport bounds and input callbacks use LÖVE logical coordinates. With `usedpiscale = true`, do not multiply mouse or touch coordinates by the DPI scale again; `getDPIScale()` describes density rather than requesting another input conversion.

For the Russian reference, see [`API.md`](API.md).
