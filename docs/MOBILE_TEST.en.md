# Mobile and high-DPI verification

Automated coverage lives in `tests/test_mobile_hidpi.lua`. Run the visual diagnostic view with:

```bash
love . --mobile-test
```

## Device checklist

1. Confirm that the status line reports the expected logical dimensions, DPI scale and orientation.
2. Start a one-finger drag inside the viewport and move outside it. The original viewport must retain the gesture.
3. Pinch and move both fingers together. Zoom and midpoint pan must remain stable.
4. Start dragging, background the application, and return. The old gesture must be cancelled.
5. Rotate portrait → landscape → portrait. The floating viewport must fit on-screen and restore its preferred size when space becomes available again.
6. Verify the 44-pixel mobile scrollbar target, paging, fading and stylus/mouse hover where supported.
7. Verify single tap, double tap and long press; a pending single tap must not fire before a double tap.
8. Release one finger after a pinch and continue panning with the remaining finger without a jump.
9. Drag a floating title bar and resize a corner with one finger.
10. Reach every content edge at zoom levels `0.5`, `1`, `2`, and `3`.

When the application forwards both mouse and touch callbacks, filter mouse events
with `istouch == true` as shown in `examples/support.lua`.

## DPI model

`highdpi` and `usedpiscale` are enabled. Input arrives in LÖVE logical coordinates, so the library does not multiply it by `getDPIScale()`.

Physical testing remains required before shipping a specific Android or iOS build: desktop CI cannot reproduce device touch drivers, background transitions or hardware rotation behavior.

For the Russian checklist, see [`MOBILE_TEST.md`](MOBILE_TEST.md).
