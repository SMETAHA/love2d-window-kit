# Changelog

Все заметные изменения проекта документируются здесь. Версии следуют Semantic Versioning.

## 1.1.0 — 2026-07-13

### Added

- GitHub Pages-сайт с интерактивными примерами библиотеки.
- Автоматическая compatibility-сборка LÖVE 11.5 через закреплённую ревизию
  `love.js`; WebAssembly-файлы публикуются как Pages artifact.
- Плавные `scrollTo`, `scrollBy`, `zoomTo`, `centerOn` и `ensureVisible` с easing.
- Геометрический API: видимые границы, пределы scroll, преобразование координат,
  проверка видимости прямоугольника и hit-test.
- Опциональная инерция, pinch zoom, Shift + wheel и настройка источников/осей ввода.
- Изменение размера floating-окон за края и углы с min/max ограничениями.
- `WindowStack` получил стабильные ID, modal routing, focus cycling, send-to-back,
  clear и сохранение полного состояния stack.
- Сценарий `navigation-lab` для новых возможностей.

### Changed

- Callbacks расширены событиями move, resize и завершения навигации.
- Scrollbar можно независимо скрывать по горизонтали и вертикали.
- README, двуязычный API и recipes обновлены под API 1.1; GitHub Pages упрощён
  до каталога сценариев с единой live-панелью.

### Fixed

- Неизвестные клавиши больше не помечаются как обработанные viewport.
- Resize-зоны не перекрывают односоставные scrollbar tracks.
- Усилена проверка параметров `SystemWindow`.

### Compatibility

- Инерция и resize выключены по умолчанию; API 1.0 и старые сценарии сохранены.

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
