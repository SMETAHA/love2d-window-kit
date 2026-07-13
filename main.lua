-- main.lua
local WindowManager = require("WindowManager")
local WindowStack = require("WindowStack")
local SystemWindow = require("SystemWindow")

local exampleModules = {
    ["fullscreen-canvas"] = "examples.fullscreen_canvas",
    ["floating-inventory"] = "examples.floating_inventory",
    ["multi-window-dashboard"] = "examples.multi_window_dashboard",
    ["themed-scrollbars"] = "examples.themed_scrollbars",
    ["state-callbacks"] = "examples.state_callbacks",
    ["large-map-culling"] = "examples.large_map_culling",
    ["navigation-lab"] = "examples.navigation_lab"
}

for _, value in ipairs(arg or {}) do
    if value == "--minimal" then
        require("examples.minimal")
        return
    elseif value == "--mobile-test" then
        require("examples.mobile_test")
        return
    else
        local exampleName = value:match("^%-%-example=(.+)$")
        if exampleName and exampleModules[exampleName] then
            require(exampleModules[exampleName])
            return
        end
    end
end

local systemWindow
local floatingWindow
local windowStack

local CONTENT_W, CONTENT_H = 2000, 1500
local savedFloatingState
local smokeMode = false
local smokeFrames = 0

for _, value in ipairs(arg or {}) do
    if value == "--smoke" then smokeMode = true end
end

local function visibleBounds(scrollX, scrollY, visibleWidth, visibleHeight)
    local left = math.max(0, scrollX)
    local top = math.max(0, scrollY)
    local right = math.min(CONTENT_W, scrollX + visibleWidth)
    local bottom = math.min(CONTENT_H, scrollY + visibleHeight)
    return left, top, math.max(left, right), math.max(top, bottom)
end

local function drawSystemContent(scrollX, scrollY, visibleWidth, visibleHeight)
    local left, top, right, bottom = visibleBounds(
        scrollX, scrollY, visibleWidth, visibleHeight)
    love.graphics.setColor(0.8, 0.9, 1.0)
    love.graphics.rectangle("fill", left, top, right - left, bottom - top)

    love.graphics.setColor(0, 0, 0, 0.2)
    for x = math.floor(left / 100) * 100, right, 100 do
        love.graphics.line(x, top, x, bottom)
    end
    for y = math.floor(top / 100) * 100, bottom, 100 do
        love.graphics.line(left, y, right, y)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("System Window (arrows, +/-) - active: "
        .. tostring(windowStack:getActive() == systemWindow), left + 10, top + 10)
end

local function drawFloatingContent(scrollX, scrollY, visibleWidth, visibleHeight)
    local left, top, right, bottom = visibleBounds(
        scrollX, scrollY, visibleWidth, visibleHeight)
    love.graphics.setColor(1, 1, 0.8)
    love.graphics.rectangle("fill", left, top, right - left, bottom - top)

    love.graphics.setColor(0, 0, 0, 0.2)
    for x = math.floor(left / 100) * 100, right, 100 do
        love.graphics.line(x, top, x, bottom)
    end
    for y = math.floor(top / 100) * 100, bottom, 100 do
        love.graphics.line(left, y, right, y)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Floating Window - active: "
        .. tostring(windowStack:getActive() == floatingWindow), left + 10, top + 10)
end

function love.load()
    windowStack = WindowStack.new()

    local configured, message = SystemWindow.configure({
        width = 1024,
        height = 768,
        title = "WindowManager Showcase",
        resizable = true,
        highdpi = true,
        usedpiscale = true
    })
    assert(configured, message or "Could not configure the system window")

    -- 1) Системное окно (во весь экран внутри библиотеки)
    systemWindow = WindowManager.new({
        floating = false,
        contentWidth = CONTENT_W,
        contentHeight = CONTENT_H,
        scrollbar = {
            minThumbSize = 28,
            autoHide = true,
            autoHideDelay = 1.2,
            fadeDuration = 0.3
        }
    })

    -- 2) Плавающее окно
    floatingWindow = WindowManager.new({
        floating = true,
        x = 100,
        y = 80,
        width = 600,
        height = 400,
        title = "Floating Window",
        draggable = true,
        contentWidth = CONTENT_W,
        contentHeight = CONTENT_H,
        scrollbar = {
            width = 12,
            minThumbSize = 32,
            color = {0.8, 0.3, 0.3, 0.9},
            hoverColor = {1, 0.45, 0.45, 1},
            activeColor = {1, 0.7, 0.35, 1},
            autoHide = true
        }
    })

    windowStack:add(systemWindow, {
        draw = drawSystemContent,
        layer = 0,
        raiseOnFocus = false
    })
    windowStack:add(floatingWindow, {
        draw = drawFloatingContent,
        layer = 100,
        raiseOnFocus = true,
        constrainOnResize = true,
        shrinkOnResize = true
    })
    windowStack:focus(systemWindow)
end

function love.update(dt)
    windowStack:update(dt)
    if smokeMode then
        smokeFrames = smokeFrames + 1
        if smokeFrames >= 3 then love.event.quit() end
    end
end

function love.draw()
    windowStack:draw()

    love.graphics.setColor(1,1,1)
    local _, height = love.graphics.getDimensions()
    love.graphics.print("[S] Save floatingWindow | [L] Load floatingWindow | [ESC] quit", 10, height - 20)
end

function love.resize(w, h)
    windowStack:resize(w, h)
end

------------------------------------------------------------------------------
--                          EVENT FORWARDING                                --
------------------------------------------------------------------------------

function love.mousepressed(x, y, button, istouch, presses)
    if not istouch then windowStack:mousepressed(x, y, button, false, presses) end
end

function love.mousereleased(x, y, button, istouch, presses)
    if not istouch then windowStack:mousereleased(x, y, button, false, presses) end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if not istouch then windowStack:mousemoved(x, y, dx, dy, false) end
end

function love.wheelmoved(wx, wy)
    windowStack:wheelmoved(wx, wy)
end

-- touch (mobile)
function love.touchpressed(id, x, y, dx, dy, pressure)
    windowStack:touchpressed(id, x, y, dx, dy, pressure)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    windowStack:touchmoved(id, x, y, dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    windowStack:touchreleased(id, x, y, dx, dy, pressure)
end

function love.focus(focused)
    if not focused then windowStack:cancelInput() end
end

-- Клавиши отдаем только активному окну
function love.keypressed(key, scancode, isrepeat)
    windowStack:keypressed(key, scancode, isrepeat)

    if key == "s" then
        savedFloatingState = floatingWindow:getState()
        print("FloatingWindow state saved!")
    elseif key == "l" then
        if savedFloatingState then
            floatingWindow:setState(savedFloatingState)
            print("FloatingWindow state loaded!")
        else
            print("No saved state!")
        end
    elseif key == "escape" then
        love.event.quit()
    end
end

function love.keyreleased(key, scancode)
    windowStack:keyreleased(key, scancode)
end

function love.textinput(text)
    windowStack:textinput(text)
end

function love.textedited(text, start, length)
    windowStack:textedited(text, start, length)
end
