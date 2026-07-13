package.path = "./?.lua;" .. package.path

local mouseX, mouseY = 200, 200
local time = 0
local keysDown = {}

love = {
    graphics = {
        getWidth = function() return 800 end,
        getHeight = function() return 600 end,
        getDimensions = function() return 800, 600 end
    },
    mouse = {
        getPosition = function() return mouseX, mouseY end
    },
    keyboard = {
        isDown = function(key) return keysDown[key] == true end
    },
    timer = {
        getTime = function() return time end
    }
}

local WindowManager = require("WindowManager")

local function assertApprox(actual, expected, message, tolerance)
    assert(math.abs(actual - expected) <= (tolerance or 1e-6),
        (message or "values differ") .. ": expected " .. expected .. ", got " .. actual)
end

local window = WindowManager.new({
    contentWidth = 2000,
    contentHeight = 1500,
    trackpad = {
        smooth = true,
        friction = 12,
        maxVelocity = 4000
    }
})
window:scrollTo(200, 200)

-- Fractional wheel deltas are accumulated and eased in precision-trackpad mode.
assert(window:wheelmoved(0, -0.5))
assertApprox(window.scrollY, 200, "smooth wheel must defer movement to update")
assert(window.trackpadVelocityY > 0)
local velocityBefore = window.trackpadVelocityY
window:update(0.016)
assert(window.scrollY > 200, "smooth wheel must advance during update")
assert(window.trackpadVelocityY < velocityBefore, "smooth wheel velocity must decay")
window:scrollTo(200, 200)
assert(window.trackpadVelocityX == 0 and window.trackpadVelocityY == 0,
    "explicit navigation must cancel trackpad momentum")

-- Exponential zoom remains stable for fractional wheel deltas and keeps its anchor.
keysDown.lctrl = true
local anchorX, anchorY = window:screenToContent(mouseX, mouseY)
assert(window:wheelmoved(0, 0.5))
assert(window.zoom > 1 and window.zoom < 1.1)
local anchoredX, anchoredY = window:screenToContent(mouseX, mouseY)
assertApprox(anchoredX, anchorX, "trackpad zoom anchor X")
assertApprox(anchoredY, anchorY, "trackpad zoom anchor Y")
keysDown.lctrl = false

window:setZoom(1)
window:scrollTo(200, 200)

-- Small finger jitter is ignored; a deliberate pan starts after the threshold.
assert(window:touchpressed("pan", 100, 100, 0, 0, 1))
time = time + 0.01
assert(window:touchmoved("pan", 102, 101, 2, 1, 1))
assertApprox(window.scrollX, 200, "touch jitter X")
assertApprox(window.scrollY, 200, "touch jitter Y")
time = time + 0.01
assert(window:touchmoved("pan", 112, 101, 10, 0, 1))
assertApprox(window.scrollX, 190, "touch pan after threshold")
assert(window:touchreleased("pan", 112, 101, 0, 0, 1))

local taps, doubleTaps, longPresses = 0, 0, 0
window:setCallbacks({
    onTap = function() taps = taps + 1 end,
    onDoubleTap = function() doubleTaps = doubleTaps + 1 end,
    onLongPress = function() longPresses = longPresses + 1 end
})

-- A single tap waits for the double-tap interval before it is emitted.
window:setTouchOptions({ doubleTap = false })
assert(window:touchpressed("single", 150, 150, 0, 0, 1))
assert(window:touchreleased("single", 150, 150, 0, 0, 1))
assert(taps == 0)
time = time + window.touchDoubleTapInterval + 0.01
window:update(0)
assert(taps == 1)

-- Double tap suppresses the pending single tap and animates anchored zoom.
window:setTouchOptions({ doubleTap = true, doubleTapZoom = 2, doubleTapDuration = 0.2 })
window:setZoom(1)
assert(window:touchpressed("double-a", 180, 160, 0, 0, 1))
assert(window:touchreleased("double-a", 180, 160, 0, 0, 1))
time = time + 0.1
assert(window:touchpressed("double-b", 182, 161, 0, 0, 1))
assert(window:touchreleased("double-b", 182, 161, 0, 0, 1))
assert(doubleTaps == 1 and taps == 1)
window:update(0.2)
assertApprox(window.zoom, 2, "double-tap zoom")

-- Holding a stationary finger emits long press once and never becomes a tap.
assert(window:touchpressed("hold", 220, 180, 0, 0, 0.8))
time = time + window.touchLongPressDelay + 0.01
window:update(0)
window:update(0)
assert(longPresses == 1)
assert(window:touchreleased("hold", 220, 180, 0, 0, 0.8))

-- Pinch and two-finger pan share one stable anchor; releasing one finger
-- transitions directly into one-finger panning without a jump.
window:setZoom(1)
window:scrollTo(200, 200)
assert(window:touchpressed("pinch-a", 100, 220, 0, 0, 1))
assert(window:touchpressed("pinch-b", 200, 220, 0, 0, 1))
assert(window:touchpressed("pinch-c", 300, 220, 0, 0, 1))
assert(window.pinch.first == "pinch-a" and window.pinch.second == "pinch-b",
    "pinch pair must follow touch press order")
time = time + 0.016
window:touchmoved("pinch-a", 120, 220, 20, 0, 1)
window:touchmoved("pinch-b", 220, 220, 20, 0, 1)
assertApprox(window.zoom, 1, "two-finger pan zoom")
assertApprox(window.scrollX, 180, "two-finger pan position")
window:touchreleased("pinch-b", 220, 220, 0, 0, 1)
assert(window.pinch and window.pinch.first == "pinch-a"
    and window.pinch.second == "pinch-c")
window:touchreleased("pinch-c", 300, 220, 0, 0, 1)
local beforeSinglePan = window.scrollX
time = time + 0.016
window:touchmoved("pinch-a", 130, 220, 10, 0, 1)
assert(window.scrollX < beforeSinglePan, "remaining pinch finger must continue panning")
window:touchreleased("pinch-a", 130, 220, 0, 0, 1)

-- Floating chrome has touch-sized title dragging and corner resizing.
local floating = WindowManager.new({
    floating = true,
    x = 50,
    y = 50,
    width = 300,
    height = 220,
    titleBarHeight = 32,
    draggable = true,
    resizable = true,
    resize = { minWidth = 200, minHeight = 140 },
    contentWidth = 800,
    contentHeight = 600
})
assert(floating:touchpressed("title", 120, 65, 0, 0, 1))
floating:touchmoved("title", 170, 95, 50, 30, 1)
floating:touchreleased("title", 170, 95, 0, 0, 1)
assert(floating.x == 100 and floating.y == 80, "touch title drag")

local cornerX, cornerY = floating.x + floating.w - 2, floating.y + floating.h - 2
assert(floating:touchpressed("corner", cornerX, cornerY, 0, 0, 1))
floating:touchmoved("corner", cornerX + 50, cornerY + 40, 50, 40, 1)
floating:touchreleased("corner", cornerX + 50, cornerY + 40, 0, 0, 1)
assert(floating.w == 350 and floating.h == 260, "touch corner resize")

print("Trackpad/touchscreen gesture tests passed")
