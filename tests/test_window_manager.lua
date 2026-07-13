package.path = "./?.lua;" .. package.path

local mouseX, mouseY = 0, 0
local ctrlDown = false
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
        isDown = function() return ctrlDown end
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

print("WindowManager tests passed")
