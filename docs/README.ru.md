# LÖVE Window Kit 1.1.0

Лёгкий набор для создания прокручиваемых и масштабируемых viewport в LÖVE2D: анимированная навигация, инерция, pinch zoom, изменяемые размеры окон, модальный фокус и независимый multi-touch.

[← Главная страница](../README.md) · [API](API.md) · [Mobile checklist](MOBILE_TEST.md)

## Возможности

- колесо, клавиатура, drag-to-scroll, touch и опциональная инерция;
- масштабирование относительно точки под курсором;
- pinch zoom и плавные `scrollTo`, `zoomTo`, `centerOn`, `ensureVisible`;
- плавающие перетаскиваемые и resizable-окна;
- z-order, слои, стабильные ID, active и modal-окна;
- mouse capture до release и отдельный capture каждого touch ID;
- настраиваемые scrollbar с page-click, hover, active и auto-hide;
- high-DPI, resize и смена ориентации;
- сохранение состояния и унифицированные callbacks;
- тесты и CI с LÖVE 11.5.

## Быстрый старт

```bash
git clone https://github.com/SMETAHA/love2d-window-kit.git
cd love2d-window-kit
love .
```

Минимальная интеграция:

```bash
love . --minimal
```

## Сценарии

| Команда | Назначение |
| --- | --- |
| `love . --example=fullscreen-canvas` | Большой canvas с pan и zoom |
| `love . --example=floating-inventory` | Плавающий игровой инвентарь |
| `love . --example=multi-window-dashboard` | Несколько перекрывающихся окон |
| `love . --example=themed-scrollbars` | Подробная настройка оформления |
| `love . --example=state-callbacks` | Состояние и callbacks |
| `love . --example=large-map-culling` | Оптимизированная большая карта |
| `love . --example=navigation-lab` | Инерция, pinch, плавные цели и resize |
| `love . --mobile-test` | Touch, DPI и ориентация |

Исходники всех сценариев находятся в [`examples/`](../examples/). Полный конфигурационный контракт описан в [`docs/API.md`](API.md).

## Проверка

```bash
sh scripts/run_tests.sh
```

Перед мобильным релизом также пройдите [`MOBILE_TEST.md`](MOBILE_TEST.md) на реальном устройстве.
