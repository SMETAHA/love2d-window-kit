local WindowManager = require("WindowManager")
local WindowStack = require("WindowStack")
local Support = require("examples.support")

local stack
local viewport
local savedState
local status = "Scroll or zoom to see callback data"

function love.load()
    Support.configure("Example: state and callbacks")
    stack = WindowStack.new()

    viewport = WindowManager.new({
        floating = true,
        x = 160,
        y = 90,
        width = 700,
        height = 480,
        title = "Stateful viewport",
        draggable = true,
        contentWidth = 2400,
        contentHeight = 1600,
        callbacks = {
            onScroll = function(x, y, oldX, oldY, source, reason)
                status = string.format("onScroll: %.1f, %.1f | reason: %s", x, y, reason)
            end,
            onZoom = function(oldZoom, zoom, source, reason)
                status = string.format("onZoom: %.2f -> %.2f | reason: %s",
                    oldZoom, zoom, reason)
            end
        },
        scrollbar = { autoHide = true }
    })

    stack:add(viewport, {
        layer = 100,
        shrinkOnResize = true,
        draw = function(scrollX, scrollY, visibleWidth, visibleHeight)
            local left, top = Support.drawGrid(
                scrollX, scrollY, visibleWidth, visibleHeight,
                2400, 1600, 120,
                {0.06, 0.075, 0.11, 1}, {0.16, 0.22, 0.32, 1})
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("[S] save  [L] load  [R] reset", left + 20, top + 20)
        end
    })
    stack:focus(viewport)
end

Support.bind(function() return stack end, {
    draw = function()
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(status, 16, 16)
    end,
    keypressed = function(key)
        if key == "s" then
            savedState = viewport:getState()
            status = "State saved"
            return true
        elseif key == "l" then
            if savedState then
                viewport:setState(savedState)
                status = "State restored"
            else
                status = "Nothing has been saved yet"
            end
            return true
        elseif key == "r" then
            viewport:setState({scrollX = 0, scrollY = 0, zoom = 1})
            status = "State reset"
            return true
        end
        return false
    end
})
