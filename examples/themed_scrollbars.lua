local WindowManager = require("WindowManager")
local WindowStack = require("WindowStack")
local Support = require("examples.support")

local stack

function love.load()
    Support.configure("Example: themed scrollbars")
    stack = WindowStack.new()

    local viewport = WindowManager.new({
        floating = true,
        x = 120,
        y = 80,
        width = 760,
        height = 520,
        title = "Neon document",
        draggable = true,
        contentWidth = 1400,
        contentHeight = 1800,
        scrollbar = {
            width = 16,
            minThumbSize = 48,
            pageStep = 0.8,
            autoHide = true,
            autoHideDelay = 0.7,
            fadeDuration = 0.35,
            color = {0.15, 0.85, 1, 0.85},
            trackColor = {0.02, 0.15, 0.2, 0.7},
            hoverColor = {0.55, 0.95, 1, 1},
            activeColor = {1, 0.35, 0.75, 1}
        },
        theme = {
            frameColor = {0.025, 0.035, 0.07, 0.98},
            titleBarColor = {0.08, 0.12, 0.28, 1},
            titleTextColor = {0.6, 0.95, 1, 1},
            borderColor = {0.15, 0.85, 1, 1}
        }
    })

    stack:add(viewport, {
        layer = 100,
        shrinkOnResize = true,
        draw = function(scrollX, scrollY, visibleWidth, visibleHeight)
            local left, top, right, bottom = Support.visibleBounds(
                scrollX, scrollY, visibleWidth, visibleHeight, 1400, 1800)
            love.graphics.setColor(0.018, 0.025, 0.055)
            love.graphics.rectangle("fill", left, top, right - left, bottom - top)
            for row = 0, 26 do
                local y = 50 + row * 64
                love.graphics.setColor(0.12, 0.18, 0.32)
                love.graphics.rectangle("fill", 70, y, 1180, 36)
                love.graphics.setColor(0.25, 0.85, 1, 0.8)
                love.graphics.rectangle("fill", 70, y, 160 + (row % 7) * 110, 4)
            end
        end
    })
    stack:focus(viewport)
end

Support.bind(function() return stack end)
