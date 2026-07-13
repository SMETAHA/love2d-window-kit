package.path = "./?.lua;" .. package.path

love = {
    graphics = {
        getWidth = function() return 800 end,
        getHeight = function() return 600 end,
        getDimensions = function() return 800, 600 end,
        getDPIScale = function() return 2 end
    },
    mouse = { getPosition = function() return 0, 0 end },
    keyboard = { isDown = function() return false end }
}

local WindowManager = require("WindowManager")
local WindowStack = require("WindowStack")

local window = WindowManager.new({
    floating = true,
    x = 10,
    y = 20,
    width = 600,
    height = 400,
    contentWidth = 2000,
    contentHeight = 1500,
    zoom = 2
})

window.scrollX, window.scrollY = 100, 100
local contentX, contentY = window:screenToContent(210, 144)
assert(contentX == 200 and contentY == 150,
    "high-DPI coordinates must not be multiplied by the DPI scale")

assert(window:touchpressed("finger", 210, 144, 0, 0, 1))
assert(window:touchmoved("finger", 230, 154, 20, 10, 1))
assert(window.scrollX == 90 and window.scrollY == 95,
    "touch delta must be converted only by content zoom")
assert(window:touchreleased("finger", 230, 154, 0, 0, 1))

local stack = WindowStack.new()
stack:add(window, {
    draw = function() end,
    constrainOnResize = true,
    shrinkOnResize = true
})

stack:resize(320, 240)
assert(window.w == 320 and window.h == 240 and window.x == 0 and window.y == 0,
    "portrait resize must keep the floating window on-screen")
stack:resize(800, 600)
assert(window.w == 600 and window.h == 400,
    "preferred floating size must return after orientation recovery")

stack:touchpressed("one", 100, 100, 0, 0, 1)
stack:cancelInput()
assert(not stack:touchmoved("one", 110, 100, 10, 0, 1),
    "focus loss must cancel mobile captures")

print("Mobile/high-DPI tests passed")
