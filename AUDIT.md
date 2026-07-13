# Итог аудита app_template_love2d

## Статус

P0, P1 и P2 закрыты в версии `1.0.0`. Исходный двухфайловый прототип преобразован в шаблон с разделёнными viewport, стеком окон, публичным API, тестами, CI и документацией без удаления совместимых методов.

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

- `test_window_manager.lua` — геометрия, zoom, drag, scrollbar, resize.
- `test_window_stack.lua` — порядок, focus, capture, visibility, removal.
- `test_api.lua` — API 1.0, validation, callbacks, безопасный draw.
- `test_mobile_hidpi.lua` — DPI 2×, touch delta, orientation и cancel.
- `test_main_smoke.lua` — полный жизненный цикл showcase.
- `test_examples_smoke.lua` — все восемь отдельных сценариев.
- `.github/workflows/ci.yml` — реальный LÖVE 11.5 smoke и `.love` artifact.

## Остаточные внешние риски

- Перед мобильным релизом нужен прогон checklist на целевых Android/iOS устройствах.
- `WindowManager` напрямую использует глобальный `love`; unit-тесты изолируют это mock-объектом.
- Публичные поля сохранены ради обратной совместимости. Новый код должен использовать методы и constructor options.

Эти пункты не являются незавершёнными функциями шаблона, но относятся к проверке конкретной платформенной сборки.
