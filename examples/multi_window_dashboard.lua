local WindowManager = require("WindowManager")
local WindowStack = require("WindowStack")
local Support = require("examples.support")

local stack

local function addPanel(title, x, y, width, height, accent, phase)
    local panel = WindowManager.new({
        floating = true,
        x = x,
        y = y,
        width = width,
        height = height,
        title = title,
        draggable = true,
        contentWidth = 900,
        contentHeight = 620,
        scrollbar = { autoHide = true, color = accent },
        theme = {
            frameColor = {0.055, 0.065, 0.09, 0.98},
            titleBarColor = {accent[1] * 0.45, accent[2] * 0.45, accent[3] * 0.45, 1},
            borderColor = accent
        }
    })

    stack:add(panel, {
        layer = 100,
        shrinkOnResize = true,
        draw = function(scrollX, scrollY, visibleWidth, visibleHeight)
            local left, top, right, bottom = Support.visibleBounds(
                scrollX, scrollY, visibleWidth, visibleHeight, 900, 620)
            love.graphics.setColor(0.035, 0.045, 0.065)
            love.graphics.rectangle("fill", left, top, right - left, bottom - top)
            love.graphics.setColor(accent[1], accent[2], accent[3], 0.9)
            local previousX, previousY
            for i = 0, 80 do
                local px = i * 11
                local py = 300 + math.sin(i * 0.25 + phase) * 120
                if previousX then love.graphics.line(previousX, previousY, px, py) end
                previousX, previousY = px, py
            end
        end
    })
end

function love.load()
    Support.configure("Example: multi-window dashboard", 1180, 760)
    stack = WindowStack.new()

    local background = WindowManager.new({floating = false, contentWidth = 1180, contentHeight = 760})
    stack:add(background, {
        layer = 0,
        focusable = false,
        raiseOnFocus = false,
        draw = function(scrollX, scrollY, visibleWidth, visibleHeight)
            love.graphics.setColor(0.025, 0.03, 0.045)
            love.graphics.rectangle("fill", scrollX, scrollY, visibleWidth, visibleHeight)
            love.graphics.setColor(0.65, 0.72, 0.85)
            love.graphics.print("Click a panel to focus and raise it inside layer 100", 24, 24)
        end
    })

    addPanel("Network", 70, 90, 520, 340, {0.25, 0.75, 1, 1}, 0)
    addPanel("Simulation", 390, 180, 560, 360, {0.65, 0.45, 1, 1}, 1.8)
    addPanel("Telemetry", 180, 390, 610, 300, {0.25, 0.95, 0.6, 1}, 3.2)
end

Support.bind(function() return stack end)
