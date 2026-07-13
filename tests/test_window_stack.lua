package.path = "./?.lua;" .. package.path

local WindowStack = require("WindowStack")

local function newWindow(name, left, right, floating)
    local window = {
        name = name,
        left = left,
        right = right,
        isFloating = floating,
        events = {},
        cancelled = false
    }

    local function record(event)
        window.events[#window.events + 1] = event
    end

    function window:inside(x)
        return x >= self.left and x <= self.right
    end

    function window:mousepressed(x, y, button)
        if button == 1 and self:inside(x) then
            record("press")
            return true
        end
        return false
    end

    function window:mousereleased()
        record("release")
        return true
    end

    function window:mousemoved()
        record("move")
        return false
    end

    function window:touchpressed(id, x)
        if self:inside(x) then
            record("touch-press-" .. id)
            return true
        end
        return false
    end

    function window:touchmoved(id)
        record("touch-move-" .. id)
        return true
    end

    function window:touchreleased(id)
        record("touch-release-" .. id)
        return true
    end

    function window:keypressed(key)
        record("key-" .. key)
    end

    function window:keyreleased(key)
        record("key-release-" .. key)
    end

    function window:textinput(text)
        record("text-" .. text)
    end

    function window:update()
        record("update")
    end

    function window:draw(renderer)
        renderer()
    end

    function window:resize(w, h)
        self.resizeWidth, self.resizeHeight = w, h
    end

    function window:cancelInput()
        self.cancelled = true
    end

    return window
end

local function count(window, expected)
    local total = 0
    for _, event in ipairs(window.events) do
        if event == expected then total = total + 1 end
    end
    return total
end

local stack = WindowStack.new()
local base = newWindow("base", 0, 200, false)
local first = newWindow("first", 0, 70, true)
local second = newWindow("second", 40, 110, true)
local drawOrder = {}
local captureLost = 0

stack:add(base, { layer = 0, raiseOnFocus = false, draw = function()
    drawOrder[#drawOrder + 1] = "base"
end })
stack:add(first, { layer = 100, onCaptureLost = function()
    captureLost = captureLost + 1
end, draw = function()
    drawOrder[#drawOrder + 1] = "first"
end })
stack:add(second, { layer = 100, draw = function()
    drawOrder[#drawOrder + 1] = "second"
end })

-- The topmost overlapping window owns the whole mouse gesture.
assert(stack:mousepressed(50, 10, 1))
assert(stack:getActive() == second)
assert(stack:mousemoved(500, 500, 450, 490))
assert(stack:mousereleased(500, 500, 1))
assert(count(second, "press") == 1 and count(second, "move") == 1
    and count(second, "release") == 1)
assert(count(base, "press") == 0 and count(first, "press") == 0)

-- Clicking the exposed part raises the first floating window within layer 100.
assert(stack:mousepressed(20, 10, 1))
stack:mousereleased(20, 10, 1)
assert(stack:getActive() == first)
assert(stack:mousepressed(50, 10, 1))
stack:mousereleased(50, 10, 1)
assert(count(first, "press") == 2, "raised window must win the overlap")

-- Keyboard input goes only to the focused window.
assert(stack:keypressed("right"))
assert(count(first, "key-right") == 1)
assert(count(second, "key-right") == 0)
assert(stack:keyreleased("right"))
assert(stack:textinput("A"))
assert(count(first, "key-release-right") == 1 and count(first, "text-A") == 1)

-- Independent touch IDs retain their original owners even after z-order changes.
assert(stack:touchpressed("a", 20, 10, 0, 0, 1))
assert(stack:touchpressed("b", 90, 10, 0, 0, 1))
assert(stack:touchmoved("a", 500, 10, 10, 0, 1))
assert(stack:touchmoved("b", 0, 10, -10, 0, 1))
assert(count(first, "touch-move-a") == 1)
assert(count(second, "touch-move-b") == 1)
assert(stack:touchreleased("a", 500, 10, 0, 0, 1))
assert(stack:touchreleased("b", 0, 10, 0, 0, 1))

-- Hiding a captured window cancels its state and prevents further delivery.
assert(stack:mousepressed(20, 10, 1))
assert(stack:setVisible(first, false))
assert(first.cancelled)
assert(captureLost == 1)
assert(not stack:mousemoved(20, 10, 0, 0))
assert(stack:getActive() == nil)
assert(stack:setVisible(first, true))

assert(stack:mousepressed(90, 10, 1))
stack:cancelInput()
assert(not stack:mousemoved(90, 10, 0, 0), "focus loss must clear mouse capture")

-- Layer 0 remains below floating windows regardless of focus.
assert(stack:focus(base))
assert(stack:bringToFront(base))
stack:draw()
assert(drawOrder[1] == "base")

stack:resize(1280, 720)
assert(base.resizeWidth == 1280 and second.resizeHeight == 720)
stack:update(0.016)
assert(count(base, "update") == 1)

assert(stack:remove(second))
assert(not stack:getEntry(second))
assert(not stack:remove(second))

-- Stable IDs, focus cycling, and within-layer back ordering.
local ordered = WindowStack.new()
local alpha = newWindow("alpha", 0, 100, true)
local beta = newWindow("beta", 0, 100, true)
ordered:add(alpha, { id = "alpha", layer = 100 })
ordered:add(beta, { id = "beta", layer = 100 })
assert(not pcall(function()
    ordered:add(newWindow("duplicate", 0, 10, true), { id = "alpha" })
end), "stack IDs must be unique")
assert(ordered:count() == 2 and ordered:contains(alpha))
assert(ordered:getById("alpha") == alpha and ordered:getTop() == beta)
assert(ordered:focusNext() == alpha)
assert(ordered:focusNext() == beta)
assert(ordered:focusNext(true) == alpha)
assert(ordered:sendToBack(beta) and ordered:getTop() == alpha)
local savedOrder = ordered:getState()
ordered:setVisible(alpha, false)
ordered:setLayer(beta, 0)
ordered:setState(savedOrder)
assert(ordered:getEntry(alpha).visible and ordered:getEntry(beta).layer == 100)
assert(ordered:getTop() == alpha and ordered:getActive() == alpha)

-- A modal entry blocks pointer and keyboard routing to all entries below it.
local modalStack = WindowStack.new()
local background = newWindow("background", 0, 200, false)
local dialog = newWindow("dialog", 50, 100, true)
modalStack:add(background, { id = "background", layer = 0 })
modalStack:add(dialog, { id = "dialog", layer = 200, modal = true })
assert(modalStack:getModal() == dialog and modalStack:getActive() == dialog)
assert(modalStack:mousepressed(20, 10, 1), "outside modal input must be consumed")
assert(count(background, "press") == 0)
assert(not modalStack:focus(background), "focus cannot move below a modal entry")
assert(modalStack:mousepressed(70, 10, 1))
modalStack:mousereleased(70, 10, 1)
assert(count(dialog, "press") == 1)
assert(modalStack:setModal(dialog, false))
assert(modalStack:mousepressed(20, 10, 1))
modalStack:mousereleased(20, 10, 1)
assert(count(background, "press") == 1)
modalStack:clear()
assert(modalStack:count() == 0 and modalStack:getActive() == nil)

-- Opening a modal also cancels gestures already captured below its boundary.
local captureStack = WindowStack.new()
local capturedBackground = newWindow("captured-background", 0, 200, false)
local lateDialog = newWindow("late-dialog", 50, 100, true)
captureStack:add(capturedBackground, { layer = 0 })
captureStack:add(lateDialog, { layer = 200, modal = true, visible = false })
assert(captureStack:mousepressed(20, 10, 1))
assert(captureStack:setVisible(lateDialog, true))
assert(capturedBackground.cancelled, "modal activation must cancel lower capture")
assert(captureStack:mousemoved(20, 10, 0, 0))
assert(count(capturedBackground, "move") == 0)

print("WindowStack tests passed")
