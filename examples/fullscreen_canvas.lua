local WindowManager = require("WindowManager")
local WindowStack = require("WindowStack")
local Support = require("examples.support")

local CONTENT_W, CONTENT_H = 3200, 2200
local stack

function love.load()
    Support.configure("Example: fullscreen canvas")
    stack = WindowStack.new()

    local canvas = WindowManager.new({
        floating = false,
        contentWidth = CONTENT_W,
        contentHeight = CONTENT_H,
        minZoom = 0.35,
        maxZoom = 4,
        scrollbar = { autoHide = true, minThumbSize = 28 }
    })

    stack:add(canvas, {
        layer = 0,
        raiseOnFocus = false,
        draw = function(scrollX, scrollY, visibleWidth, visibleHeight)
            local left, top = Support.drawGrid(
                scrollX, scrollY, visibleWidth, visibleHeight,
                CONTENT_W, CONTENT_H, 100,
                {0.055, 0.07, 0.105, 1}, {0.15, 0.21, 0.3, 1})

            love.graphics.setColor(0.32, 0.75, 1, 0.85)
            love.graphics.rectangle("fill", 420, 300, 520, 300)
            love.graphics.setColor(1, 0.48, 0.35, 0.9)
            love.graphics.circle("fill", 1600, 920, 180)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Fullscreen canvas: drag / wheel / Ctrl + wheel", left + 20, top + 20)
        end
    })
    stack:focus(canvas)
end

Support.bind(function() return stack end)
