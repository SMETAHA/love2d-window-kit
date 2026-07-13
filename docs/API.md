# API 1.1.0

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
| `resizable` | boolean | Изменение размера floating-окна за края и углы |
| `resize` | table | Толщина resize-зоны и min/max размеры окна |
| `dragToScroll` | boolean | Перетаскивание контента |
| `zoom`, `minZoom`, `maxZoom` | number | Масштаб и границы |
| `scrollSpeed` | number | Шаг колеса и клавиатуры |
| `alignSmallContent` | boolean | Центрирование малого контента |
| `scrollbar` | table | Настройки scrollbar |
| `input` | table | Политика wheel, keyboard, touch, осей и zoom-модификатора |
| `inertia` | table/boolean | Опциональная кинетическая прокрутка |
| `theme` | table | Цвета рамки и title bar |
| `callbacks` | table | Scroll, zoom, layout и navigation callbacks |

### Scrollbar options

`visible`, `horizontal`, `vertical`, `width`, `minThumbSize`, `pageStep`, `autoHide`, `autoHideDelay`, `fadeDuration`, `color`, `trackColor`, `hoverColor`, `activeColor`.

Цвет — таблица `{r, g, b, a}` со значениями `0..1`. `pageStep` задаёт долю видимой области при клике по track.

### Resize options

`border`, `minWidth`, `minHeight`, `maxWidth`, `maxHeight`. Resize включается явно, ограничивается экраном и не перекрывает односоставные scrollbar tracks. Углы остаются resize-зонами.

### Input options

| Параметр | По умолчанию | Назначение |
| --- | --- | --- |
| `wheel`, `keyboard`, `touch` | `true` | Включить соответствующий источник ввода |
| `horizontal`, `vertical` | `true` | Оси, меняемые пользовательским вводом |
| `pinchZoom` | `true` | Zoom двумя пальцами относительно центра жеста |
| `shiftWheelHorizontal` | `true` | Shift + вертикальное колесо прокручивает по горизонтали |
| `zoomModifier` | `"ctrl"` | `ctrl`, `alt`, `shift`, `meta` или `none` |
| `zoomStep` | `0.1` | Шаг zoom для колеса и клавиатуры |

### Inertia options

`enabled`, `friction`, `minVelocity`, `maxPause`. Инерция выключена по умолчанию ради поведения 1.0. Включить её можно через `inertia = true` или таблицу параметров. `maxPause` исключает устаревший рывок, если указатель остановился до release.

### Theme

`frameColor`, `titleBarColor`, `titleTextColor`, `borderColor`.

### Callbacks

```lua
onScroll(x, y, oldX, oldY, viewport, reason)
onZoom(oldZoom, zoom, viewport, reason)
onMove(x, y, oldX, oldY, viewport, reason)
onResize(width, height, oldWidth, oldHeight, viewport, reason)
onNavigationComplete(viewport, reason)
```

Каждое изменение сообщает координаты после окончательного ограничения. При zoom относительно курсора `onZoom` и `onScroll` видят уже финальное состояние. Анимация сообщает промежуточные изменения и один раз вызывает `onNavigationComplete`. Во время конструктора callbacks не вызываются.

Типичные `reason`: `wheel`, `wheel-zoom`, `content-drag`, `touch-drag`, `pinch`, `inertia`, `vertical-drag`, `horizontal-drag`, `window-drag`, `window-resize`, `scroll-to`, `zoom-to`, `ensure-visible`, `keyboard`, `resize`, `state`.

### Основные методы

- `configure(options)` — применить таблицу параметров.
- `setFloating(x, y, w, h)` / `setFullscreen()`.
- `setPosition(x, y)` / `setSize(w, h)`.
- `setResizable(enabled, options?)` / `setSizeLimits(minW, minH, maxW?, maxH?)`.
- `setContentSize(w, h)`.
- `setTitle(title)` / `setTitleBar(height, draggable)`.
- `setZoom(value, anchorX?, anchorY?, reason?)`.
- `setZoomLimits(min, max)` / `zoomIn(step?)` / `zoomOut(step?)`.
- `setScrollbarOptions(options)` / `setTheme(theme)`.
- `setInputOptions(options)` / `setInertia(options)`.
- `setCallbacks(callbacks)` и отдельные методы `setOn…`.
- `scrollTo(x, y, options?)` / `scrollBy(dx, dy, options?)`.
- `zoomTo(value, anchorX?, anchorY?, options?)`.
- `centerOn(contentX, contentY, options?)` / `ensureVisible(x, y, w, h, options?)`.
- `isNavigating()` / `cancelNavigation()`.
- `screenToContent(x, y)` / `contentToScreen(x, y)`.
- `getViewportSize()` / `getVisibleBounds()` / `getScrollLimits()`.
- `isContentRectVisible(x, y, w, h, fully?)` / `hitTest(x, y)`.
- `getState()` / `setState(state)`.
- `constrainToScreen(w, h, shrink)` — responsive floating layout.
- `draw(fn)` — изолированная отрисовка. Graphics stack восстанавливается даже при ошибке `fn`.
- `cancelInput()` — отменить незавершённые жесты.

Событийные методы возвращают `true`, когда событие принадлежит viewport. Обычно их вызывает `WindowStack`, а не приложение напрямую.

Navigation options принимают `duration`, `easing` и `reason`. Нулевая или пропущенная длительность применяет состояние сразу. Встроенные easing: `linear`, `outQuad`, `inOutQuad`; также допустима функция. `ensureVisible` дополнительно принимает `padding` в координатах контента.

`getVisibleBounds()` возвращает `left, top, right, bottom`, а `getScrollLimits()` — `minX, maxX, minY, maxY`. `hitTest()` возвращает `content`, `titlebar`, имя thumb/track scrollbar, направление `resize-*` или `nil` вне viewport.

## WindowStack

```lua
local stack = WindowStack.new()
stack:add(window, options)
```

### Add options

| Параметр | Назначение |
| --- | --- |
| `draw` | Callback содержимого viewport |
| `id` | Стабильный непустой ID для поиска и сохранения состояния stack |
| `layer` | Постоянная группа z-order; по умолчанию `0` или `100` для floating |
| `visible`, `enabled`, `focusable` | Состояние окна |
| `modal` | Блокировать ввод и focus всех записей ниже |
| `raiseOnFocus` | Поднимать внутри своего слоя при вводе |
| `constrainOnResize` | Удерживать floating viewport на экране |
| `shrinkOnResize` | Временно уменьшать его при смене ориентации |
| `onFocus`, `onBlur` | События фокуса |
| `onCaptureLost` | Принудительная отмена mouse/touch capture |

### Управление

- `add`, `remove`, `clear`, `contains`, `count`.
- `getEntry`, `getById`, `getWindows`, `getTop`, `getModal`.
- `focus`, `focusTop`, `focusNext(reverse?)`, `getActive`.
- `bringToFront`, `sendToBack`, `setLayer`.
- `setVisible`, `setEnabled`, `setFocusable`, `setModal`, `setDraw`.
- `getState()` / `setState(state)` для записей со стабильными ID.
- `update`, `draw`, `resize`, `cancelInput`.

Передавайте ему `mousepressed`, `mousereleased`, `mousemoved`, `wheelmoved`, touch callbacks, keyboard callbacks, `textinput` и `textedited`. Mouse-жест принадлежит одному окну до release; каждый touch ID захватывается независимо.

Состояние stack содержит только записи со стабильными ID. Если окно реализует `getState` и `setState`, его состояние вкладывается и восстанавливается автоматически. Активация modal-записи отменяет captures ниже modal boundary.

## SystemWindow

`SystemWindow.configure(options)` настраивает настоящее окно через `love.window.setMode`. Поддерживаются `width`, `height`, `title`, `fullscreen`, `fullscreentype`, `vsync`, `resizable`, `borderless`, `centered`, `highdpi`, `usedpiscale`, `msaa`, `minwidth`, `minheight`.

`WindowManager:setSystemWindow` сохранён как совместимый делегат, но в новом коде используйте `SystemWindow` напрямую.

## Координаты и DPI

Scroll хранится в координатах контента. Размер viewport и callbacks ввода находятся в логических координатах LÖVE. При `usedpiscale = true` не умножайте touch/mouse координаты на DPI scale; `getDPIScale()` нужен для информации о плотности, а не для повторной конвертации ввода.
