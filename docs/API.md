# API 1.0.0

## WindowManager

`WindowManager.new(options?)` создаёт один viewport. Все параметры необязательны.

| Параметр | Тип | Назначение |
| --- | --- | --- |
| `floating` | boolean | Плавающий viewport или полноэкранная область |
| `x`, `y` | number | Положение плавающего окна |
| `width`, `height` | number | Размер viewport |
| `contentWidth`, `contentHeight` | number | Виртуальный размер контента |
| `title` | string | Заголовок |
| `titleBarHeight` | number | Высота title bar |
| `draggable` | boolean | Перетаскивание окна за title bar |
| `dragToScroll` | boolean | Перетаскивание контента |
| `zoom`, `minZoom`, `maxZoom` | number | Масштаб и границы |
| `scrollSpeed` | number | Шаг колеса и клавиатуры |
| `alignSmallContent` | boolean | Центрирование малого контента |
| `scrollbar` | table | Настройки scrollbar |
| `theme` | table | Цвета рамки и title bar |
| `callbacks` | table | `onScroll` и `onZoom` |

### Scrollbar options

`visible`, `width`, `minThumbSize`, `pageStep`, `autoHide`, `autoHideDelay`, `fadeDuration`, `color`, `trackColor`, `hoverColor`, `activeColor`.

Цвет — таблица `{r, g, b, a}` со значениями `0..1`. `pageStep` задаёт долю видимой области при клике по track.

### Theme

`frameColor`, `titleBarColor`, `titleTextColor`, `borderColor`.

### Callbacks

```lua
onScroll(x, y, oldX, oldY, viewport, reason)
onZoom(oldZoom, zoom, viewport, reason)
```

Уведомления вызываются один раз после окончательного ограничения координат. При zoom относительно курсора `onZoom` и `onScroll` видят уже финальное состояние. Во время конструктора callbacks не вызываются.

Типичные `reason`: `wheel`, `wheel-zoom`, `content-drag`, `touch-drag`, `vertical-drag`, `horizontal-drag`, `vertical-page`, `horizontal-page`, `keyboard`, `resize`, `state`.

### Основные методы

- `configure(options)` — применить таблицу параметров.
- `setFloating(x, y, w, h)` / `setFullscreen()`.
- `setPosition(x, y)` / `setSize(w, h)`.
- `setContentSize(w, h)`.
- `setTitle(title)` / `setTitleBar(height, draggable)`.
- `setZoom(value, anchorX?, anchorY?, reason?)`.
- `setZoomLimits(min, max)` / `zoomIn(step?)` / `zoomOut(step?)`.
- `setScrollbarOptions(options)` / `setTheme(theme)`.
- `setCallbacks(callbacks)` / `setOnScroll(fn?)` / `setOnZoom(fn?)`.
- `screenToContent(x, y)`.
- `getState()` / `setState(state)`.
- `constrainToScreen(w, h, shrink)` — responsive floating layout.
- `draw(fn)` — изолированная отрисовка. Graphics stack восстанавливается даже при ошибке `fn`.
- `cancelInput()` — отменить незавершённые жесты.

Событийные методы возвращают `true`, когда событие принадлежит viewport. Обычно их вызывает `WindowStack`, а не приложение напрямую.

## WindowStack

```lua
local stack = WindowStack.new()
stack:add(window, options)
```

### Add options

| Параметр | Назначение |
| --- | --- |
| `draw` | Callback содержимого viewport |
| `layer` | Постоянная группа z-order; по умолчанию `0` или `100` для floating |
| `visible`, `enabled`, `focusable` | Состояние окна |
| `raiseOnFocus` | Поднимать внутри своего слоя при вводе |
| `constrainOnResize` | Удерживать floating viewport на экране |
| `shrinkOnResize` | Временно уменьшать его при смене ориентации |
| `onFocus`, `onBlur` | События фокуса |
| `onCaptureLost` | Принудительная отмена mouse/touch capture |

### Управление

- `add`, `remove`, `getEntry`, `getWindows`.
- `focus`, `getActive`, `bringToFront`, `setLayer`.
- `setVisible`, `setEnabled`, `setDraw`.
- `update`, `draw`, `resize`, `cancelInput`.

Передавайте ему `mousepressed`, `mousereleased`, `mousemoved`, `wheelmoved`, touch callbacks, keyboard callbacks, `textinput` и `textedited`. Mouse-жест принадлежит одному окну до release; каждый touch ID захватывается независимо.

## SystemWindow

`SystemWindow.configure(options)` настраивает настоящее окно через `love.window.setMode`. Поддерживаются `width`, `height`, `title`, `fullscreen`, `fullscreentype`, `vsync`, `resizable`, `borderless`, `centered`, `highdpi`, `usedpiscale`, `msaa`, `minwidth`, `minheight`.

`WindowManager:setSystemWindow` сохранён как совместимый делегат, но в новом коде используйте `SystemWindow` напрямую.

## Координаты и DPI

Scroll хранится в координатах контента. Размер viewport и callbacks ввода находятся в логических координатах LÖVE. При `usedpiscale = true` не умножайте touch/mouse координаты на DPI scale; `getDPIScale()` нужен для информации о плотности, а не для повторной конвертации ввода.
