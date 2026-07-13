local SystemWindow = require("SystemWindow")

local Support = {}

function Support.setColor(color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
end

function Support.configure(title, width, height)
    local success, message = SystemWindow.configure({
        width = width or 1024,
        height = height or 720,
        title = title,
        resizable = true,
        highdpi = true,
        usedpiscale = true
    })
    assert(success, message or "Could not configure the system window")
end

function Support.visibleBounds(scrollX, scrollY, visibleWidth, visibleHeight,
        contentWidth, contentHeight)
    local left = math.max(0, scrollX)
    local top = math.max(0, scrollY)
    local right = math.min(contentWidth, scrollX + visibleWidth)
    local bottom = math.min(contentHeight, scrollY + visibleHeight)
    return left, top, math.max(left, right), math.max(top, bottom)
end

function Support.drawGrid(scrollX, scrollY, visibleWidth, visibleHeight,
        contentWidth, contentHeight, spacing, background, gridColor)
    local left, top, right, bottom = Support.visibleBounds(
        scrollX, scrollY, visibleWidth, visibleHeight, contentWidth, contentHeight)
    Support.setColor(background)
    love.graphics.rectangle("fill", left, top, right - left, bottom - top)
    Support.setColor(gridColor)
    for x = math.floor(left / spacing) * spacing, right, spacing do
        love.graphics.line(x, top, x, bottom)
    end
    for y = math.floor(top / spacing) * spacing, bottom, spacing do
        love.graphics.line(left, y, right, y)
    end
    return left, top, right, bottom
end

function Support.bind(getStack, hooks)
    hooks = hooks or {}

    function love.update(dt)
        getStack():update(dt)
        if hooks.update then hooks.update(dt) end
    end

    function love.draw()
        getStack():draw()
        if hooks.draw then hooks.draw() end
    end

    function love.resize(w, h)
        getStack():resize(w, h)
        if hooks.resize then hooks.resize(w, h) end
    end

    function love.mousepressed(x, y, button, istouch, presses)
        if not istouch then getStack():mousepressed(x, y, button, false, presses) end
    end
    function love.mousereleased(x, y, button, istouch, presses)
        if not istouch then getStack():mousereleased(x, y, button, false, presses) end
    end
    function love.mousemoved(x, y, dx, dy, istouch)
        if not istouch then getStack():mousemoved(x, y, dx, dy, false) end
    end
    function love.wheelmoved(...) getStack():wheelmoved(...) end
    function love.touchpressed(...) getStack():touchpressed(...) end
    function love.touchmoved(...) getStack():touchmoved(...) end
    function love.touchreleased(...) getStack():touchreleased(...) end

    function love.keypressed(key, scancode, isrepeat)
        if hooks.keypressed and hooks.keypressed(key, scancode, isrepeat) then return end
        getStack():keypressed(key, scancode, isrepeat)
    end
    function love.keyreleased(...) getStack():keyreleased(...) end
    function love.textinput(...) getStack():textinput(...) end
    function love.textedited(...) getStack():textedited(...) end

    function love.focus(focused)
        if not focused then getStack():cancelInput() end
    end
end

return Support
