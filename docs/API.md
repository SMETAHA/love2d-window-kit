# API 1.2.0

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
| `trackpad` | table/boolean | Плавная прокрутка precision touchpad (`true` включает её) |
| `touchscreen` | table | Пороги жестов, tap-действия и touch resize |
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
| `trackpad` | — | Вложенные настройки precision touchpad |
| `touchscreen` | — | Вложенные настройки жестов touchscreen |

### Настройки touchpad

`smooth`, `sensitivity`, `invertX`, `invertY`, `friction`, `maxVelocity`, `zoomMode`, `zoomSensitivity`.

`smooth = true` сохраняет дробные wheel delta и добавляет momentum с независимым от FPS затуханием. `zoomMode` принимает `exponential` или `linear`; экспоненциальный zoom применяется только в smooth-режиме. LÖVE сообщает колесо мыши и touchpad ноутбука через один `love.wheelmoved`, поэтому библиотека не может надёжно различить эти устройства и настройка действует на оба. По умолчанию smooth выключен, а поведение 1.1 сохранено.

### Настройки touchscreen

| Параметр | По умолчанию | Назначение |
| --- | --- | --- |
| `pan` / `pinchZoom` | `true` | Pan одним пальцем / zoom двумя пальцами |
| `panThreshold` | `3` | Игнорировать случайное движение в logical px |
| `pinchSensitivity` | `1` | Множитель отношения pinch |
| `pinchMinDistance` | `12` | Минимальная дистанция для начала pinch |
| `twoFingerPan` | `true` | Перемещать viewport за центром pinch |
| `doubleTap` | `false` | Включить zoom двойным tap относительно точки касания |
| `doubleTapInterval` / `doubleTapDistance` | `0.32` / `36` | Временной и пространственный пределы double tap |
| `doubleTapZoom` / `doubleTapResetZoom` | `2` / `1` | Целевые значения zoom |
| `doubleTapDuration` | `0.2` | Длительность zoom-анимации |
| `longPressDelay` | `0.55` | Задержка перед `onLongPress` |
| `resize` / `resizeBorder` | `true` / `24` | Touch-зона изменения размера за углы |

Title bar можно перетаскивать пальцем у любого draggable floating-окна. Touch resize углов требует `resizable = true`; одиночные края намеренно не перехватываются, чтобы сохранить полезную область контента и scrollbar. После отпускания одного пальца из pinch второй продолжает pan без скачка координат.

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
onTap(screenX, screenY, contentX, contentY, viewport, pressure)
onDoubleTap(screenX, screenY, contentX, contentY, viewport, pressure)
onLongPress(screenX, screenY, contentX, contentY, viewport, pressure)
```

`onTap` откладывается до завершения интервала double tap. `onDoubleTap` вызывается сразу после второго касания; верните `false`, чтобы отменить встроенный zoom. Long press включается регистрацией `onLongPress`.

Каждое изменение сообщает координаты после окончательного ограничения. При zoom относительно курсора `onZoom` и `onScroll` видят уже финальное состояние. Анимация сообщает промежуточные изменения и один раз вызывает `onNavigationComplete`. Во время конструктора callbacks не вызываются.

Типичные `reason`: `wheel`, `trackpad`, `wheel-zoom`, `content-drag`, `touch-drag`, `pinch`, `double-tap`, `inertia`, `vertical-drag`, `horizontal-drag`, `window-drag`, `touch-window-drag`, `window-resize`, `touch-window-resize`, `scroll-to`, `zoom-to`, `ensure-visible`, `keyboard`, `resize`, `state`.

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
- `setInputOptions(options)` / `setTrackpadOptions(options)` / `setTouchOptions(options)` / `setInertia(options)`.
- `setCallbacks(callbacks)` и отдельные методы `setOn…`.
- `scrollTo(x, y, options?)` / `scrollBy(dx, dy, options?)`.
- `zoomTo(value, anchorX?, anchorY?, options?)`.
- `centerOn(contentX, contentY, options?)` / `ensureVisible(x, y, w, h, options?)`.
- `isNavigating()` / `cancelNavigation()` / `isTrackpadScrolling()`.
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

Передавайте ему `mousepressed`, `mousereleased`, `mousemoved`, `wheelmoved`, touch callbacks, keyboard callbacks, `textinput` и `textedited`. Mouse-жест принадлежит одному окну до release; каждый touch ID захватывается независимо. Если приложение передаёт native touch callbacks, пропускайте mouse-события с `istouch == true`: LÖVE так помечает mouse-события, созданные касанием, и обработка обоих путей продублирует жест.

Состояние stack содержит только записи со стабильными ID. Если окно реализует `getState` и `setState`, его состояние вкладывается и восстанавливается автоматически. Активация modal-записи отменяет captures ниже modal boundary.

## SystemWindow

`SystemWindow.configure(options)` настраивает настоящее окно через `love.window.setMode`. Поддерживаются `width`, `height`, `title`, `fullscreen`, `fullscreentype`, `vsync`, `resizable`, `borderless`, `centered`, `highdpi`, `usedpiscale`, `msaa`, `minwidth`, `minheight`.

`WindowManager:setSystemWindow` сохранён как совместимый делегат, но в новом коде используйте `SystemWindow` напрямую.

## Координаты и DPI

Scroll хранится в координатах контента. Размер viewport и callbacks ввода находятся в логических координатах LÖVE. При `usedpiscale = true` не умножайте touch/mouse координаты на DPI scale; `getDPIScale()` нужен для информации о плотности, а не для повторной конвертации ввода.
