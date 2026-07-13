package.path = "./?.lua;" .. package.path

local mouseX, mouseY = 0, 0
local time = 0
local keysDown = {}
local graphicsStack = 0

love = {
    graphics = {
        getWidth = function() return 1024 end,
        getHeight = function() return 768 end,
        getDimensions = function() return 1024, 768 end,
        push = function() graphicsStack = graphicsStack + 1 end,
        pop = function() graphicsStack = graphicsStack - 1 end,
        setScissor = function() end,
        translate = function() end,
        scale = function() end,
        setColor = function() end,
        rectangle = function() end,
        print = function() end
    },
    window = {
        setMode = function() return true end,
        setTitle = function() end
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

local function assertApprox(actual, expected, message)
    assert(math.abs(actual - expected) < 1e-6,
        (message or "values differ") .. ": expected " .. expected .. ", got " .. actual)
end

local function newFloating()
    local window = WindowManager.new()
    window:setFloating(0, 0, 500, 300)
    window:load(1000, 800)
    return window
end

local window = newFloating()
window:setZoom(2)
window.scrollX, window.scrollY = math.huge, math.huge
window:limitScroll()
assertApprox(window.scrollX, 750, "horizontal zoom limit")
assertApprox(window.scrollY, 662, "vertical zoom limit")

window.scrollX, window.scrollY = 400, 400
assert(window:mousepressed(100, 100, 1))
assert(window:mousemoved(150, 120, 50, 20))
assertApprox(window.scrollX, 375, "drag-to-scroll X")
assertApprox(window.scrollY, 390, "drag-to-scroll Y")
assert(window:mousereleased(150, 120, 1))
assert(not window:mousereleased(150, 120, 1), "release without capture must not be consumed")

window.scrollY = 0
window:limitScroll()
local track = (window.h - window.titleBarHeight) - window.verticalScrollbarHeight
assert(window:mousepressed(window.w - 1,
    window.verticalScrollbarY + window.verticalScrollbarHeight / 2, 1))
window:mousemoved(window.w - 1,
    window.dragStartY + track, 0, track)
assertApprox(window.scrollY, 662, "vertical scrollbar end")
window:mousereleased(window.w - 1, window.h, 1)

local beforeTitleWheel = window.scrollY
mouseX, mouseY = 100, 10
assert(window:wheelmoved(0, -1), "title bar wheel must be consumed")
assertApprox(window.scrollY, beforeTitleWheel, "title bar must not scroll content")

local small = WindowManager.new()
small:setFloating(0, 0, 500, 300)
small:load(100, 50)
assertApprox(small.scrollX, -200, "small content horizontal centering")
assertApprox(small.scrollY, -113, "small content vertical centering")

local fullscreen = WindowManager.new()
assert(fullscreen:resize(800, 600))
assert(fullscreen.w == 800 and fullscreen.h == 600)

window:draw(function() end)
assert(graphicsStack == 0, "draw must restore the graphics stack")

window:touchpressed("touch", 100, 100, 0, 0, 1)
window:cancelInput()
assert(not window:touchmoved("touch", 110, 100, 10, 0, 1),
    "cancelInput must release touches")

-- Geometry helpers are exact inverses and expose content-space bounds.
window:setZoom(2)
window:scrollTo(100, 150)
local screenX, screenY = window:contentToScreen(180, 230)
local contentX, contentY = window:screenToContent(screenX, screenY)
assertApprox(contentX, 180, "contentToScreen inverse X")
assertApprox(contentY, 230, "contentToScreen inverse Y")
local visibleW, visibleH = window:getViewportSize()
assertApprox(visibleW, 250, "viewport width")
assertApprox(visibleH, 138, "viewport height")
local left, top, right, bottom = window:getVisibleBounds()
assertApprox(right - left, visibleW, "visible bounds width")
assertApprox(bottom - top, visibleH, "visible bounds height")
assert(window:isContentRectVisible(120, 170, 10, 10, true))
assert(not window:isContentRectVisible(900, 700, 10, 10))

-- Programmatic navigation supports immediate helpers and deterministic animation.
window:centerOn(500, 400)
assertApprox(window.scrollX, 375, "centerOn X")
assertApprox(window.scrollY, 331, "centerOn Y")
window:ensureVisible(950, 750, 20, 20, { padding = 10 })
assert(window:isContentRectVisible(950, 750, 20, 20, true))

local navigationComplete = 0
window:setOnNavigationComplete(function(source, reason)
    assert(source == window and reason == "animated-test")
    navigationComplete = navigationComplete + 1
end)
window:scrollTo(100, 120, {
    duration = 1,
    easing = "linear",
    reason = "animated-test"
})
assert(window:isNavigating())
window:update(0.5)
assert(window:isNavigating())
window:update(0.5)
assert(not window:isNavigating() and navigationComplete == 1)
assertApprox(window.scrollX, 100, "animated scroll X")
assertApprox(window.scrollY, 120, "animated scroll Y")

-- Inertia is opt-in and remains clamped to the content limits.
window:setInertia({ enabled = true, friction = 6, minVelocity = 0 })
window.velocityX, window.velocityY = 200, 100
window:update(0.1)
assert(window.scrollX > 100 and window.scrollY > 120, "inertia must advance scroll")
window:scrollTo(100, 120)
assert(window.velocityX == 0 and window.velocityY == 0,
    "explicit navigation must cancel inertia")

-- Two captured touches pinch around their midpoint.
window:setZoom(1)
window:scrollTo(100, 100)
assert(window:touchpressed("pinch-a", 100, 100, 0, 0, 1))
assert(window:touchpressed("pinch-b", 200, 100, 0, 0, 1))
time = time + 0.016
assert(window:touchmoved("pinch-b", 300, 100, 100, 0, 1))
assertApprox(window.zoom, 2, "pinch zoom")
window:touchreleased("pinch-a", 100, 100, 0, 0, 1)
window:touchreleased("pinch-b", 300, 100, 0, 0, 1)

-- Floating windows can opt into bounded edge/corner resizing.
local moved, resized = 0, 0
local resizable = newFloating()
resizable:setCallbacks({
    onMove = function() moved = moved + 1 end,
    onResize = function() resized = resized + 1 end
})
resizable:setResizable(true, {
    border = 10,
    minWidth = 240,
    minHeight = 180,
    maxWidth = 700,
    maxHeight = 600
})
assert(resizable:hitTest(499, 299) == "resize-se")
assert(resizable:mousepressed(499, 299, 1))
assert(resizable:mousemoved(650, 450, 151, 151))
assert(resizable.w > 500 and resizable.h > 300 and resized > 0)
assert(resizable:mousereleased(650, 450, 1))
resizable:setPosition(20, 30)
assert(moved > 0)

-- Input policy prevents disabled axes and unknown keys from being consumed.
resizable:setInputOptions({ horizontal = false })
assert(not resizable:keypressed("left"))
assert(not resizable:keypressed("unmapped"))
resizable:setInputOptions({ horizontal = true })
assert(resizable:keypressed("right"))

-- Source switches disable the entire wheel/touch source, not only panning.
mouseX, mouseY = 100, 100
keysDown.lctrl = true
local zoomBeforeDisabledWheel = resizable.zoom
resizable.trackpadVelocityX, resizable.trackpadVelocityY = 10, 20
resizable:setInputOptions({ wheel = false })
assert(not resizable:wheelmoved(0, 1))
assertApprox(resizable.zoom, zoomBeforeDisabledWheel, "disabled wheel zoom")
assert(resizable.trackpadVelocityX == 0 and resizable.trackpadVelocityY == 0)
resizable:setInputOptions({ wheel = true, touch = false })
assert(not resizable:touchpressed("disabled-touch", 100, 100, 0, 0, 1))
assert(not resizable.activeTouches or not resizable.activeTouches["disabled-touch"])
keysDown.lctrl = false

-- Disabling touchscreen pan alone still permits an explicitly enabled pinch.
resizable:setInputOptions({ touch = true })
resizable:setTouchOptions({ pan = false, pinchZoom = true })
resizable:setZoom(1)
resizable:scrollTo(100, 100)
assert(resizable:touchpressed("no-pan-a", 100, 100, 0, 0, 1))
assert(resizable:touchmoved("no-pan-a", 130, 100, 30, 0, 1))
assertApprox(resizable.scrollX, 100, "disabled one-finger pan")
assert(resizable:touchpressed("no-pan-b", 200, 100, 0, 0, 1))
assert(resizable:touchmoved("no-pan-b", 300, 100, 100, 0, 1))
assert(resizable.zoom > 1, "pinch must remain independent from one-finger pan")
resizable:touchreleased("no-pan-a", 130, 100, 0, 0, 1)
resizable:touchreleased("no-pan-b", 300, 100, 0, 0, 1)

-- Exponential integration produces the same momentum across frame sizes.
local inertiaCoarse, inertiaFine = newFloating(), newFloating()
for _, candidate in ipairs({ inertiaCoarse, inertiaFine }) do
    candidate:setInertia({ enabled = true, friction = 6, minVelocity = 0 })
    candidate:scrollTo(100, 100)
    candidate.velocityX, candidate.velocityY = 200, 100
end
inertiaCoarse:update(0.1)
inertiaFine:update(0.05)
inertiaFine:update(0.05)
assertApprox(inertiaCoarse.scrollX, inertiaFine.scrollX, "frame-independent inertia X")
assertApprox(inertiaCoarse.scrollY, inertiaFine.scrollY, "frame-independent inertia Y")
assertApprox(inertiaCoarse.velocityX, inertiaFine.velocityX,
    "frame-independent inertia velocity")
local retainedVelocity = inertiaCoarse.velocityX
inertiaCoarse:update(0)
assertApprox(inertiaCoarse.velocityX, retainedVelocity, "zero dt must preserve inertia")

local trackpadCoarse, trackpadFine = newFloating(), newFloating()
for _, candidate in ipairs({ trackpadCoarse, trackpadFine }) do
    candidate:setTrackpadOptions({ smooth = true, friction = 12 })
    candidate:scrollTo(100, 100)
    candidate.trackpadVelocityX, candidate.trackpadVelocityY = 300, 150
end
trackpadCoarse:update(0.1)
trackpadFine:update(0.05)
trackpadFine:update(0.05)
assertApprox(trackpadCoarse.scrollX, trackpadFine.scrollX,
    "frame-independent trackpad X")
assertApprox(trackpadCoarse.trackpadVelocityX, trackpadFine.trackpadVelocityX,
    "frame-independent trackpad velocity")

-- An impossibly short host keeps a non-negative content viewport.
local tiny = newFloating()
assert(tiny:constrainToScreen(20, 10, true))
local tinyViewportWidth, tinyViewportHeight = tiny:getViewportSize()
assert(tiny.w == 20 and tiny.h == tiny.titleBarHeight + 1)
assert(tinyViewportWidth == 20 and tinyViewportHeight == 1)

print("WindowManager tests passed")
