# Итог аудита app_template_love2d

## Статус

P0, P1 и P2 закрыты. Финальная перепроверка дополнительно закрыла граничные
состояния modal capture, полное отключение источников ввода, FPS-независимый
momentum и минимальную высоту responsive viewport. Совместимые методы сохранены.

## Финальная перепроверка

- Любое активное modal-окно, включая `focusable = false`, освобождает captures и
  focus ниже своей boundary; правило повторно применяется после изменения слоя
  и восстановления stack state.
- Touch, заблокированный modal на press, остаётся поглощённым до release.
- `input.wheel`, `input.keyboard` и `input.touch` отключают источник целиком;
  `touchscreen.pan` независимо управляет только pan одним пальцем.
- Inertia и precision-touchpad momentum используют экспоненциальную интеграцию
  полного `dt`, а нулевой `dt` не сбрасывает скорость.
- `constrainToScreen(..., true)` не создаёт отрицательную content-область даже
  при высоте host-окна меньше title bar.

## Расширение 1.2

- Дробные wheel delta, momentum, friction, inversion и экспоненциальный zoom для
  touchpad с сохранением прежнего wheel-режима по умолчанию.
- Порог pan, pinch + two-finger pan, детерминированный выбор touch-пары и
  бесшовный переход к одному пальцу.
- Delayed tap, double-tap zoom, long press, touch title drag и corner resize.
- Автоматические тесты жестов, обновлённые API, mobile checklist и live example.

## Расширение 1.1

- Плавная и мгновенная навигация: `scrollTo`, `scrollBy`, `zoomTo`, `centerOn`,
  `ensureVisible`, отмена и callback завершения.
- Геометрия viewport: прямое и обратное преобразование координат, visible bounds,
  scroll limits, hit-test и проверка видимости content rect.
- Опциональная инерция, двухпальцевый zoom, input policy и независимое отображение
  горизонтального/вертикального scrollbar.
- Floating resize с восемью направлениями, ограничениями размера и экрана.
- Stable IDs, modal boundary, focus cycling, send-to-back, clear и state round-trip
  в `WindowStack`.
- Новые layout callbacks и runnable-сценарий `navigation-lab`.

## P0 — исправлено

- Единицы scroll/zoom, пределы, scrollbar и центрирование малого контента.
- Drag-to-scroll, владелец release, keyboard isolation и touch coordinates.
- Resize, title bar hit-testing и изоляция graphics state.

## P1 — закрыто

- `WindowStack`: layers, z-order, focus, bring-to-front, mouse capture и независимые touch captures.
- Полный конфигурационный API с проверкой размеров, zoom limits, цветов и callbacks.
- `SystemWindow` отделяет глобальный `love.window.setMode` от viewport.
- `onScroll`/`onZoom` унифицированы и вызываются после финального состояния.
- Draw callback выполняется через защищённую секцию с гарантированным восстановлением graphics stack.

## P2 — закрыто

- CI проверяет Lua 5.1, запускает unit/smoke-набор и настоящий LÖVE 11.5 под Xvfb.
- Добавлены MIT License, Semantic Versioning, changelog, API и отдельный minimal example.
- Добавлены автоматический high-DPI/mobile тест, визуальный стенд и аппаратный checklist.
- Scrollbar получил minimum thumb, track page-click, auto-hide/fade, hover и active состояния.
- Showcase отрисовывает только видимую область сетки.

## Проверки

- `test_window_manager.lua` — геометрия, navigation, inertia, pinch, scrollbar, resize.
- `test_window_stack.lua` — порядок, focus, modal capture, state, visibility, removal.
- `test_api.lua` — API 1.2, validation, callbacks, безопасный draw.
- `test_mobile_hidpi.lua` — DPI 2×, touch delta, orientation и cancel.
- `test_gestures.lua` — touchpad momentum/zoom и touchscreen gestures/chrome.
- Регрессии финальной проверки — non-focusable/reordered modal, полная touch
  ownership-цепочка, source switches, frame-size invariance и tiny host viewport.
- `test_main_smoke.lua` — полный жизненный цикл showcase.
- `test_examples_smoke.lua` — все девять отдельных сценариев.
- `.github/workflows/ci.yml` — реальный LÖVE 11.5 smoke и `.love` artifact.

## Остаточные внешние риски

- Перед мобильным релизом нужен прогон checklist на целевых Android/iOS устройствах.
- `WindowManager` напрямую использует глобальный `love`; unit-тесты изолируют это mock-объектом.
- Публичные поля сохранены ради обратной совместимости. Новый код должен использовать методы и constructor options.

Эти пункты не являются незавершёнными функциями шаблона, но относятся к проверке конкретной платформенной сборки.
