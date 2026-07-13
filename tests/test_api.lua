package.path = "./?.lua;" .. package.path

local width, height = 1024, 768
local mouseX, mouseY = 0, 0
local stackDepth = 0
local lastFlags

love = {
    graphics = {
        getWidth = function() return width end,
        getHeight = function() return height end,
        getDimensions = function() return width, height end,
        push = function() stackDepth = stackDepth + 1 end,
        pop = function() stackDepth = stackDepth - 1 end,
        setScissor = function() end,
        translate = function() end,
        scale = function() end,
        setColor = function() end,
        rectangle = function() end,
        print = function() end
    },
    window = {
        setMode = function(w, h, flags)
            width, height, lastFlags = w, h, flags
            return true
        end,
        setTitle = function() end
    },
    mouse = {
        getPosition = function() return mouseX, mouseY end
    },
    keyboard = {
        isDown = function() return false end
    }
}

local WindowManager = require("WindowManager")
local WindowStack = require("WindowStack")
local SystemWindow = require("SystemWindow")

assert(WindowManager.VERSION == "1.0.0")
assert(WindowStack.VERSION == "1.0.0")
assert(SystemWindow.VERSION == "1.0.0")

assert(SystemWindow.configure({
    width = 800,
    height = 600,
    highdpi = true,
    usedpiscale = true
}))
assert(lastFlags.highdpi and lastFlags.usedpiscale)

local legacy = WindowManager.new()
assert(legacy:setSystemWindow({width = 640, height = 480, title = "Legacy"}))
assert(legacy.w == 640 and legacy.h == 480,
    "legacy setSystemWindow must delegate and resize the fullscreen viewport")

local scrollEvents, zoomEvents = {}, {}
local window = WindowManager.new({
    floating = true,
    x = 10,
    y = 20,
    width = 500,
    height = 300,
    title = "Configured",
    draggable = true,
    contentWidth = 2000,
    contentHeight = 1500,
    minZoom = 0.5,
    maxZoom = 4,
    scrollbar = {
        minThumbSize = 50,
        pageStep = 0.5,
        autoHide = true,
        autoHideDelay = 0,
        fadeDuration = 0.1
    },
    callbacks = {
        onScroll = function(x, y, oldX, oldY, source, reason)
            scrollEvents[#scrollEvents + 1] = {x, y, oldX, oldY, source, reason}
        end,
        onZoom = function(oldZoom, zoom, source, reason)
            zoomEvents[#zoomEvents + 1] = {oldZoom, zoom, source, reason}
        end
    }
})

assert(#scrollEvents == 0 and #zoomEvents == 0,
    "construction must not emit change callbacks")
assert(window.title == "Configured" and window.isDraggable)
assert(window.verticalScrollbarHeight >= 50 and window.horizontalScrollbarWidthScaled >= 50)

window.scrollX, window.scrollY = 100, 100
window:setZoom(2, 260, 144, "anchor-test")
assert(math.abs(window.scrollX - 225) < 1e-6)
assert(math.abs(window.scrollY - 150) < 1e-6)
assert(#zoomEvents == 1 and zoomEvents[1][4] == "anchor-test")
assert(#scrollEvents == 1 and scrollEvents[1][6] == "anchor-test")

window:update(0.2)
assert(window.scrollbarAlpha == 0, "auto-hide must fade the scrollbars")
window:_showScrollbars()
assert(window.scrollbarAlpha == 1)

window.scrollY = 0
window:limitScroll()
local oldY = window.scrollY
local clickY = window.verticalScrollbarY + window.verticalScrollbarHeight + 10
assert(window:mousepressed(window.x + window.w - 1, window.y + clickY, 1))
assert(window.scrollY > oldY, "clicking the track must page-scroll")

window:setDragToScroll(false)
local beforeX, beforeY = window.scrollX, window.scrollY
assert(window:mousepressed(window.x + 100, window.y + 100, 1))
assert(not window:mousemoved(window.x + 130, window.y + 130, 30, 30))
assert(window.scrollX == beforeX and window.scrollY == beforeY)

local ok, message = pcall(function()
    window:draw(function() error("draw failure") end)
end)
assert(not ok and tostring(message):find("draw failure", 1, true))
assert(stackDepth == 0, "draw errors must restore the graphics stack")

assert(not pcall(function() window:setZoomLimits(2, 1) end))
assert(not pcall(function() window:setScrollbarOptions({ color = {2, 0, 0} }) end))

print("Public API tests passed")
