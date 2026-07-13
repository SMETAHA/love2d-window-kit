local WindowManager = require("WindowManager")
local WindowStack = require("WindowStack")
local Support = require("examples.support")

local stack

function love.load()
    Support.configure("Example: floating inventory")
    stack = WindowStack.new()

    local world = WindowManager.new({
        floating = false,
        contentWidth = 2200,
        contentHeight = 1400,
        scrollbar = { autoHide = true }
    })
    local inventory = WindowManager.new({
        floating = true,
        x = 170,
        y = 100,
        width = 560,
        height = 420,
        title = "Inventory",
        draggable = true,
        contentWidth = 720,
        contentHeight = 900,
        dragToScroll = true,
        scrollbar = {
            width = 12,
            minThumbSize = 34,
            autoHide = true,
            color = {0.35, 0.85, 0.65, 0.95}
        },
        theme = {
            frameColor = {0.08, 0.1, 0.14, 0.98},
            titleBarColor = {0.12, 0.3, 0.24, 1},
            borderColor = {0.35, 0.85, 0.65, 1}
        }
    })

    stack:add(world, {
        layer = 0,
        raiseOnFocus = false,
        draw = function(scrollX, scrollY, visibleWidth, visibleHeight)
            Support.drawGrid(scrollX, scrollY, visibleWidth, visibleHeight,
                2200, 1400, 80, {0.07, 0.09, 0.12, 1}, {0.12, 0.18, 0.22, 1})
        end
    })
    stack:add(inventory, {
        layer = 100,
        shrinkOnResize = true,
        draw = function(scrollX, scrollY, visibleWidth, visibleHeight)
            local left, top, right, bottom = Support.visibleBounds(
                scrollX, scrollY, visibleWidth, visibleHeight, 720, 900)
            love.graphics.setColor(0.04, 0.055, 0.075)
            love.graphics.rectangle("fill", left, top, right - left, bottom - top)
            for index = 1, 48 do
                local column = (index - 1) % 6
                local row = math.floor((index - 1) / 6)
                local x, y = 24 + column * 112, 24 + row * 106
                love.graphics.setColor(0.15, 0.19, 0.24)
                love.graphics.rectangle("fill", x, y, 88, 82)
                love.graphics.setColor(0.35 + (index % 3) * 0.15, 0.72, 0.55)
                love.graphics.rectangle("fill", x + 22, y + 18, 44, 44)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(index, x + 6, y + 5)
            end
        end
    })
    stack:focus(inventory)
end

Support.bind(function() return stack end)
