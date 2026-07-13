local WindowManager = require("WindowManager")
local WindowStack = require("WindowStack")
local SystemWindow = require("SystemWindow")

local windows
local viewport

function love.load()
    assert(SystemWindow.configure({
        width = 800,
        height = 600,
        title = "WindowManager minimal example",
        resizable = true
    }))

    windows = WindowStack.new()
    viewport = WindowManager.new({
        floating = false,
        contentWidth = 1600,
        contentHeight = 1200,
        scrollbar = { autoHide = true }
    })

    windows:add(viewport, {
        layer = 0,
        raiseOnFocus = false,
        draw = function(scrollX, scrollY, visibleWidth, visibleHeight)
            love.graphics.setColor(0.08, 0.1, 0.14)
            love.graphics.rectangle("fill", scrollX, scrollY, visibleWidth, visibleHeight)
            love.graphics.setColor(0.35, 0.8, 1)
            love.graphics.rectangle("fill", 200, 180, 240, 160)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Drag, use the wheel, or Ctrl + wheel", scrollX + 20, scrollY + 20)
        end
    })
    windows:focus(viewport)
end

function love.update(dt) windows:update(dt) end
function love.draw() windows:draw() end
function love.resize(w, h) windows:resize(w, h) end
function love.mousepressed(x, y, button, istouch, presses)
    if not istouch then windows:mousepressed(x, y, button, false, presses) end
end
function love.mousereleased(x, y, button, istouch, presses)
    if not istouch then windows:mousereleased(x, y, button, false, presses) end
end
function love.mousemoved(x, y, dx, dy, istouch)
    if not istouch then windows:mousemoved(x, y, dx, dy, false) end
end
function love.wheelmoved(...) windows:wheelmoved(...) end
function love.touchpressed(...) windows:touchpressed(...) end
function love.touchmoved(...) windows:touchmoved(...) end
function love.touchreleased(...) windows:touchreleased(...) end
function love.keypressed(...) windows:keypressed(...) end
function love.keyreleased(...) windows:keyreleased(...) end
function love.textinput(...) windows:textinput(...) end
function love.textedited(...) windows:textedited(...) end
function love.focus(focused) if not focused then windows:cancelInput() end end
