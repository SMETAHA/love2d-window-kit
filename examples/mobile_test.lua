local WindowManager = require("WindowManager")
local WindowStack = require("WindowStack")

local windows
local viewport
local touches = {}

local function orientation(width, height)
    return width >= height and "landscape" or "portrait"
end

function love.load()
    windows = WindowStack.new()
    local width, height = love.graphics.getDimensions()
    viewport = WindowManager.new({
        floating = true,
        x = 24,
        y = 64,
        width = math.min(640, width - 48),
        height = math.min(420, height - 88),
        title = "Touch viewport",
        draggable = true,
        contentWidth = 1800,
        contentHeight = 1400,
        scrollbar = {
            width = 16,
            minThumbSize = 44,
            autoHide = true
        }
    })

    windows:add(viewport, {
        layer = 100,
        shrinkOnResize = true,
        draw = function(scrollX, scrollY, visibleWidth, visibleHeight)
            love.graphics.setColor(0.1, 0.12, 0.18)
            love.graphics.rectangle("fill", scrollX, scrollY, visibleWidth, visibleHeight)
            love.graphics.setColor(0.25, 0.9, 0.65)
            for x = 0, 1800, 180 do
                for y = 0, 1400, 140 do
                    love.graphics.rectangle("line", x + 10, y + 10, 150, 110)
                end
            end
        end
    })
    windows:focus(viewport)
end

function love.update(dt) windows:update(dt) end

function love.draw()
    windows:draw()
    local width, height = love.graphics.getDimensions()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format(
        "%s | logical: %dx%d | DPI: %.2f | touches: %d",
        orientation(width, height), width, height,
        love.graphics.getDPIScale(), #love.touch.getTouches()), 12, 12)
    for _, touch in pairs(touches) do
        love.graphics.setColor(1, 0.35, 0.25, 0.75)
        love.graphics.circle("fill", touch.x, touch.y, 24)
    end
end

function love.resize(w, h) windows:resize(w, h) end
function love.mousepressed(...) windows:mousepressed(...) end
function love.mousereleased(...) windows:mousereleased(...) end
function love.mousemoved(...) windows:mousemoved(...) end
function love.wheelmoved(...) windows:wheelmoved(...) end

function love.touchpressed(id, x, y, dx, dy, pressure)
    touches[id] = {x = x, y = y, pressure = pressure}
    windows:touchpressed(id, x, y, dx, dy, pressure)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    touches[id] = {x = x, y = y, pressure = pressure}
    windows:touchmoved(id, x, y, dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    touches[id] = nil
    windows:touchreleased(id, x, y, dx, dy, pressure)
end

function love.focus(focused)
    if not focused then
        touches = {}
        windows:cancelInput()
    end
end
