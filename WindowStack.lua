local WindowStack = {}
WindowStack.__index = WindowStack
WindowStack.VERSION = "1.0.0"

local function option(value, default)
    if value == nil then return default end
    return value
end

function WindowStack.new()
    return setmetatable({
        entries = {},
        byWindow = {},
        activeEntry = nil,
        mouseCaptureEntry = nil,
        mouseCaptureButton = nil,
        touchCaptures = {}
    }, WindowStack)
end

function WindowStack:add(window, options)
    assert(type(window) == "table", "window must be a table")
    assert(not self.byWindow[window], "window is already in this stack")
    options = options or {}
    assert(options.draw == nil or type(options.draw) == "function", "draw must be a function")
    assert(options.layer == nil or type(options.layer) == "number", "layer must be a number")
    assert(options.onFocus == nil or type(options.onFocus) == "function", "onFocus must be a function")
    assert(options.onBlur == nil or type(options.onBlur) == "function", "onBlur must be a function")
    assert(options.onCaptureLost == nil or type(options.onCaptureLost) == "function",
        "onCaptureLost must be a function")

    local entry = {
        window = window,
        draw = options.draw,
        visible = option(options.visible, true),
        enabled = option(options.enabled, true),
        focusable = option(options.focusable, true),
        raiseOnFocus = options.raiseOnFocus,
        layer = options.layer or (window.isFloating and 100 or 0),
        onFocus = options.onFocus,
        onBlur = options.onBlur,
        onCaptureLost = options.onCaptureLost,
        constrainOnResize = option(options.constrainOnResize, window.isFloating == true),
        shrinkOnResize = option(options.shrinkOnResize, false)
    }

    local insertAt = #self.entries + 1
    for i, current in ipairs(self.entries) do
        if current.layer > entry.layer then
            insertAt = i
            break
        end
    end
    table.insert(self.entries, insertAt, entry)
    self.byWindow[window] = entry
    return window
end

function WindowStack:getEntry(window)
    return self.byWindow[window]
end

function WindowStack:getActive()
    return self.activeEntry and self.activeEntry.window or nil
end

function WindowStack:getWindows()
    local windows = {}
    for i, entry in ipairs(self.entries) do windows[i] = entry.window end
    return windows
end

function WindowStack:_setActiveEntry(entry)
    if entry == self.activeEntry then return end

    local previous = self.activeEntry
    self.activeEntry = entry

    if previous and previous.onBlur then
        previous.onBlur(previous.window, entry and entry.window or nil)
    end
    if entry and entry.onFocus then
        entry.onFocus(entry.window, previous and previous.window or nil)
    end
end

function WindowStack:focus(window)
    if window == nil then
        self:_setActiveEntry(nil)
        return true
    end

    local entry = self.byWindow[window]
    if not entry or not entry.visible or not entry.enabled or not entry.focusable then
        return false
    end
    self:_setActiveEntry(entry)
    return true
end

function WindowStack:bringToFront(window)
    local entry = self.byWindow[window]
    if not entry then return false end

    local oldIndex
    for i, current in ipairs(self.entries) do
        if current == entry then
            oldIndex = i
            break
        end
    end
    if not oldIndex then return false end

    table.remove(self.entries, oldIndex)
    local insertAt = #self.entries + 1
    for i, current in ipairs(self.entries) do
        if current.layer > entry.layer then
            insertAt = i
            break
        end
    end
    table.insert(self.entries, insertAt, entry)
    return true
end

function WindowStack:setLayer(window, layer)
    assert(type(layer) == "number", "layer must be a number")
    local entry = self.byWindow[window]
    if not entry then return false end
    entry.layer = layer
    return self:bringToFront(window)
end

function WindowStack:setDraw(window, draw)
    assert(draw == nil or type(draw) == "function", "draw must be a function or nil")
    local entry = self.byWindow[window]
    if not entry then return false end
    entry.draw = draw
    return true
end

function WindowStack:_activateFromInput(entry)
    if entry.focusable then
        self:_setActiveEntry(entry)
    end
    local shouldRaise = entry.raiseOnFocus
    if shouldRaise == nil then
        shouldRaise = entry.window.isFloating == true
    end
    if shouldRaise then
        self:bringToFront(entry.window)
    end
end

function WindowStack:_dispatchTop(method, ...)
    for i = #self.entries, 1, -1 do
        local entry = self.entries[i]
        local handler = entry.window[method]
        if entry.visible and entry.enabled and type(handler) == "function"
           and handler(entry.window, ...) then
            return entry
        end
    end
    return nil
end

function WindowStack:mousepressed(x, y, button, istouch, presses)
    if self.mouseCaptureEntry then
        return true
    end

    local entry = self:_dispatchTop("mousepressed", x, y, button, istouch, presses)
    if not entry then
        if button == 1 then self:_setActiveEntry(nil) end
        return false
    end

    self.mouseCaptureEntry = entry
    self.mouseCaptureButton = button
    self:_activateFromInput(entry)
    return true
end

function WindowStack:mousereleased(x, y, button, istouch, presses)
    local entry = self.mouseCaptureEntry
    if not entry then
        return self:_dispatchTop("mousereleased", x, y, button, istouch, presses) ~= nil
    end
    if button ~= self.mouseCaptureButton then return true end

    self.mouseCaptureEntry = nil
    self.mouseCaptureButton = nil
    local handler = entry.window.mousereleased
    if type(handler) == "function" then
        handler(entry.window, x, y, button, istouch, presses)
    end
    return true
end

function WindowStack:mousemoved(x, y, dx, dy, istouch)
    local captured = self.mouseCaptureEntry
    if captured then
        local handler = captured.window.mousemoved
        if type(handler) == "function" then
            handler(captured.window, x, y, dx, dy, istouch)
        end
        return true
    end
    return self:_dispatchTop("mousemoved", x, y, dx, dy, istouch) ~= nil
end

function WindowStack:wheelmoved(x, y)
    return self:_dispatchTop("wheelmoved", x, y) ~= nil
end

function WindowStack:touchpressed(id, x, y, dx, dy, pressure)
    if self.touchCaptures[id] then return true end

    local entry = self:_dispatchTop("touchpressed", id, x, y, dx, dy, pressure)
    if not entry then return false end

    self.touchCaptures[id] = entry
    self:_activateFromInput(entry)
    return true
end

function WindowStack:touchmoved(id, x, y, dx, dy, pressure)
    local entry = self.touchCaptures[id]
    if not entry then return false end

    local handler = entry.window.touchmoved
    if type(handler) == "function" then
        handler(entry.window, id, x, y, dx, dy, pressure)
    end
    return true
end

function WindowStack:touchreleased(id, x, y, dx, dy, pressure)
    local entry = self.touchCaptures[id]
    if not entry then return false end

    self.touchCaptures[id] = nil
    local handler = entry.window.touchreleased
    if type(handler) == "function" then
        handler(entry.window, id, x, y, dx, dy, pressure)
    end
    return true
end

function WindowStack:_dispatchActive(method, ...)
    local entry = self.activeEntry
    if not entry or not entry.visible or not entry.enabled then return false end

    local handler = entry.window[method]
    if type(handler) ~= "function" then return false end
    handler(entry.window, ...)
    return true
end

function WindowStack:keypressed(key, scancode, isrepeat)
    return self:_dispatchActive("keypressed", key, scancode, isrepeat)
end

function WindowStack:keyreleased(key, scancode)
    return self:_dispatchActive("keyreleased", key, scancode)
end

function WindowStack:textinput(text)
    return self:_dispatchActive("textinput", text)
end

function WindowStack:textedited(text, start, length)
    return self:_dispatchActive("textedited", text, start, length)
end

function WindowStack:update(dt)
    for _, entry in ipairs(self.entries) do
        local handler = entry.window.update
        if entry.enabled and type(handler) == "function" then
            handler(entry.window, dt)
        end
    end
end

function WindowStack:draw()
    for _, entry in ipairs(self.entries) do
        if entry.visible and type(entry.draw) == "function" then
            entry.window:draw(entry.draw)
        end
    end
end

function WindowStack:resize(w, h)
    for _, entry in ipairs(self.entries) do
        local handler = entry.window.resize
        local resized = false
        if type(handler) == "function" then
            resized = handler(entry.window, w, h) == true
        end
        if not resized and entry.constrainOnResize
           and type(entry.window.constrainToScreen) == "function" then
            entry.window:constrainToScreen(w, h, entry.shrinkOnResize)
        end
    end
end

function WindowStack:setVisible(window, visible)
    local entry = self.byWindow[window]
    if not entry then return false end
    entry.visible = not not visible
    if not entry.visible then self:_releaseEntry(entry) end
    return true
end

function WindowStack:setEnabled(window, enabled)
    local entry = self.byWindow[window]
    if not entry then return false end
    entry.enabled = not not enabled
    if not entry.enabled then self:_releaseEntry(entry) end
    return true
end

function WindowStack:_releaseEntry(entry)
    local hadCapture = self.mouseCaptureEntry == entry
    if self.mouseCaptureEntry == entry then
        self.mouseCaptureEntry = nil
        self.mouseCaptureButton = nil
    end
    for id, captured in pairs(self.touchCaptures) do
        if captured == entry then
            self.touchCaptures[id] = nil
            hadCapture = true
        end
    end
    if type(entry.window.cancelInput) == "function" then
        entry.window:cancelInput()
    end
    if hadCapture and entry.onCaptureLost then
        entry.onCaptureLost(entry.window)
    end
    if self.activeEntry == entry then
        self:_setActiveEntry(nil)
    end
end

function WindowStack:cancelInput()
    local captured = {}
    if self.mouseCaptureEntry then captured[self.mouseCaptureEntry] = true end
    for _, entry in pairs(self.touchCaptures) do captured[entry] = true end
    self.mouseCaptureEntry = nil
    self.mouseCaptureButton = nil
    self.touchCaptures = {}
    for _, entry in ipairs(self.entries) do
        if type(entry.window.cancelInput) == "function" then
            entry.window:cancelInput()
        end
        if captured[entry] and entry.onCaptureLost then
            entry.onCaptureLost(entry.window)
        end
    end
end

function WindowStack:remove(window)
    local entry = self.byWindow[window]
    if not entry then return false end

    self:_releaseEntry(entry)
    self.byWindow[window] = nil
    for i, current in ipairs(self.entries) do
        if current == entry then
            table.remove(self.entries, i)
            break
        end
    end
    return true
end

return WindowStack
