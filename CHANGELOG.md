# Changelog

Все заметные изменения проекта документируются здесь. Версии следуют Semantic Versioning.

## Unreleased

### Added

- Двуязычный GitHub Pages-сайт с интерактивными примерами библиотеки.
- Автоматическая compatibility-сборка LÖVE 11.5 через закреплённую ревизию
  `love.js`; WebAssembly-файлы публикуются как Pages artifact.

## 1.0.0 — 2026-07-10

### Added

- `WindowStack` со слоями, z-order, фокусом и mouse/touch capture.
- `SystemWindow` для настройки настоящего окна LÖVE отдельно от viewport.
- Конфигурационный API, темы, callbacks и проверка параметров.
- Minimum scrollbar thumb, page-click, auto-hide, fade и hover/active состояния.
- Responsive resize с восстановлением предпочтительного размера плавающего окна.
- Минимальный пример и mobile/high-DPI диагностический режим.
- Шесть прикладных сценариев: fullscreen canvas, inventory, dashboard, themed
  scrollbars, state callbacks и large-map culling.
- Unit, API, mobile и smoke-тесты; CI с настоящим LÖVE 11.5.
- Двуязычная документация, баннер, contributing/security guides и GitHub templates.

### Fixed

- Смешение экранных и контентных координат при zoom.
- Неверные пределы и drag-математика scrollbar.
- Рывки drag-to-scroll и потеря владельца release.
- Touch-координаты, центрирование малого контента и resize.
- Утечки graphics state из пользовательского draw callback.
- Дублирующиеся или преждевременные `onScroll`/`onZoom` уведомления.

### Compatibility

- Старые `WindowManager.new()`, `load`, `setFloating`, `setFullscreen` и
  `setSystemWindow` сохранены. `setSystemWindow` теперь делегирует в `SystemWindow`.
