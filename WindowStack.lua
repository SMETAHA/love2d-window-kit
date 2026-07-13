local WindowStack = {}
WindowStack.__index = WindowStack
WindowStack.VERSION = "1.1.0"

local function option(value, default)
    if value == nil then return default end
    return value
end

function WindowStack.new()
    return setmetatable({
        entries = {},
        byWindow = {},
        byId = {},
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
    assert(options.id == nil or (type(options.id) == "string" and #options.id > 0),
        "id must be a non-empty string")
    assert(options.id == nil or not self.byId[options.id], "id is already in this stack")
    local booleanOptions = {
        "visible", "enabled", "focusable", "modal", "raiseOnFocus",
        "constrainOnResize", "shrinkOnResize"
    }
    for _, name in ipairs(booleanOptions) do
        assert(options[name] == nil or type(options[name]) == "boolean",
            name .. " must be a boolean")
    end

    local entry = {
        window = window,
        id = options.id,
        draw = options.draw,
        visible = option(options.visible, true),
        enabled = option(options.enabled, true),
        focusable = option(options.focusable, true),
        modal = option(options.modal, false),
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
    if entry.id then self.byId[entry.id] = entry end
    if entry.modal and entry.visible and entry.enabled and entry.focusable then
        self:_releaseBlockedCaptures()
        self:_setActiveEntry(entry)
    end
    return window
end

function WindowStack:getEntry(window)
    return self.byWindow[window]
end

function WindowStack:getById(id)
    local entry = self.byId[id]
    return entry and entry.window or nil
end

function WindowStack:contains(window)
    return self.byWindow[window] ~= nil
end

function WindowStack:count()
    return #self.entries
end

function WindowStack:getState()
    local state = {
        version = WindowStack.VERSION,
        active = self.activeEntry and self.activeEntry.id or nil,
        entries = {}
    }
    for _, entry in ipairs(self.entries) do
        if entry.id then
            local item = {
                id = entry.id,
                layer = entry.layer,
                visible = entry.visible,
                enabled = entry.enabled,
                focusable = entry.focusable,
                modal = entry.modal
            }
            if type(entry.window.getState) == "function" then
                item.state = entry.window:getState()
            end
            state.entries[#state.entries + 1] = item
        end
    end
    return state
end

function WindowStack:setState(state)
    assert(type(state) == "table", "state must be a table")
    assert(type(state.entries) == "table", "state.entries must be a table")

    local originalOrder, savedOrder = {}, {}
    for index, entry in ipairs(self.entries) do originalOrder[entry] = index end
    for index, item in ipairs(state.entries) do
        assert(type(item) == "table" and type(item.id) == "string",
            "each saved entry must have a string id")
        local entry = self.byId[item.id]
        if entry then
            savedOrder[entry] = index
            if item.layer ~= nil then
                assert(type(item.layer) == "number", "saved layer must be a number")
                entry.layer = item.layer
            end
            if item.focusable ~= nil then entry.focusable = not not item.focusable end
            if item.modal ~= nil then entry.modal = not not item.modal end
            if item.state ~= nil and type(entry.window.setState) == "function" then
                entry.window:setState(item.state)
            end
            if item.visible ~= nil then self:setVisible(entry.window, item.visible) end
            if item.enabled ~= nil then self:setEnabled(entry.window, item.enabled) end
        end
    end

    local fallbackOffset = #state.entries + 1
    table.sort(self.entries, function(a, b)
        if a.layer ~= b.layer then return a.layer < b.layer end
        local orderA = savedOrder[a] or fallbackOffset + originalOrder[a]
        local orderB = savedOrder[b] or fallbackOffset + originalOrder[b]
        return orderA < orderB
    end)

    if state.active ~= nil then
        assert(type(state.active) == "string", "state.active must be a string or nil")
        local active = self.byId[state.active]
        if not active or not self:focus(active.window) then self:focusTop() end
    elseif self:getModal() then
        self:focusTop()
    else
        self:_setActiveEntry(nil)
    end
    return self
end

function WindowStack:getActive()
    return self.activeEntry and self.activeEntry.window or nil
end

function WindowStack:getWindows()
    local windows = {}
    for i, entry in ipairs(self.entries) do windows[i] = entry.window end
    return windows
end

function WindowStack:getTop()
    for i = #self.entries, 1, -1 do
        local entry = self.entries[i]
        if entry.visible then return entry.window end
    end
    return nil
end

function WindowStack:_modalBoundary()
    for i = #self.entries, 1, -1 do
        local entry = self.entries[i]
        if entry.modal and entry.visible and entry.enabled then return i, entry end
    end
    return 1, nil
end

function WindowStack:getModal()
    local _, entry = self:_modalBoundary()
    return entry and entry.window or nil
end

function WindowStack:_entryAllowedByModal(entry)
    local boundary = self:_modalBoundary()
    for i = boundary, #self.entries do
        if self.entries[i] == entry then return true end
    end
    return false
end

function WindowStack:_releaseBlockedCaptures()
    local blocked = {}
    if self.mouseCaptureEntry
       and not self:_entryAllowedByModal(self.mouseCaptureEntry) then
        blocked[self.mouseCaptureEntry] = true
    end
    for _, entry in pairs(self.touchCaptures) do
        if not self:_entryAllowedByModal(entry) then blocked[entry] = true end
    end
    for entry in pairs(blocked) do self:_releaseEntry(entry) end
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
    if not entry or not entry.visible or not entry.enabled or not entry.focusable
       or not self:_entryAllowedByModal(entry) then
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

function WindowStack:sendToBack(window)
    local entry = self.byWindow[window]
    if not entry then return false end
    local oldIndex
    for i, current in ipairs(self.entries) do
        if current == entry then oldIndex = i break end
    end
    if not oldIndex then return false end

    table.remove(self.entries, oldIndex)
    local insertAt = #self.entries + 1
    for i, current in ipairs(self.entries) do
        if current.layer >= entry.layer then
            insertAt = i
            break
        end
    end
    table.insert(self.entries, insertAt, entry)
    return true
end

function WindowStack:focusTop()
    local boundary = self:_modalBoundary()
    for i = #self.entries, boundary, -1 do
        local entry = self.entries[i]
        if entry.visible and entry.enabled and entry.focusable then
            self:_setActiveEntry(entry)
            return entry.window
        end
    end
    self:_setActiveEntry(nil)
    return nil
end

function WindowStack:focusNext(reverse)
    local boundary = self:_modalBoundary()
    local candidates = {}
    for i = boundary, #self.entries do
        local entry = self.entries[i]
        if entry.visible and entry.enabled and entry.focusable then
            candidates[#candidates + 1] = entry
        end
    end
    if #candidates == 0 then
        self:_setActiveEntry(nil)
        return nil
    end

    local current = 0
    for i, entry in ipairs(candidates) do
        if entry == self.activeEntry then current = i break end
    end
    local nextIndex
    if reverse then
        nextIndex = current <= 1 and #candidates or current - 1
    else
        nextIndex = (current == 0 or current >= #candidates) and 1 or current + 1
    end
    self:_setActiveEntry(candidates[nextIndex])
    return candidates[nextIndex].window
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

function WindowStack:setFocusable(window, focusable)
    local entry = self.byWindow[window]
    if not entry then return false end
    entry.focusable = not not focusable
    if not entry.focusable and self.activeEntry == entry then self:_setActiveEntry(nil) end
    return true
end

function WindowStack:setModal(window, modal)
    local entry = self.byWindow[window]
    if not entry then return false end
    entry.modal = not not modal
    if entry.modal and entry.visible and entry.enabled and entry.focusable then
        self:_releaseBlockedCaptures()
        self:_setActiveEntry(entry)
    elseif not entry.modal and self.activeEntry == nil then
        self:focusTop()
    end
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
    local boundary, modalEntry = self:_modalBoundary()
    for i = #self.entries, boundary, -1 do
        local entry = self.entries[i]
        local handler = entry.window[method]
        if entry.visible and entry.enabled and type(handler) == "function"
           and handler(entry.window, ...) then
            return entry
        end
    end
    return nil, modalEntry ~= nil, modalEntry
end

function WindowStack:mousepressed(x, y, button, istouch, presses)
    if self.mouseCaptureEntry then
        return true
    end

    local entry, blocked, modalEntry = self:_dispatchTop(
        "mousepressed", x, y, button, istouch, presses)
    if not entry then
        if blocked then
            if modalEntry and modalEntry.focusable then self:_setActiveEntry(modalEntry) end
            return true
        end
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
        local handled, blocked = self:_dispatchTop(
            "mousereleased", x, y, button, istouch, presses)
        return handled ~= nil or blocked
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
    local entry, blocked = self:_dispatchTop("mousemoved", x, y, dx, dy, istouch)
    return entry ~= nil or blocked
end

function WindowStack:wheelmoved(x, y)
    local entry, blocked = self:_dispatchTop("wheelmoved", x, y)
    return entry ~= nil or blocked
end

function WindowStack:touchpressed(id, x, y, dx, dy, pressure)
    if self.touchCaptures[id] then return true end

    local entry, blocked, modalEntry = self:_dispatchTop(
        "touchpressed", id, x, y, dx, dy, pressure)
    if not entry then
        if blocked and modalEntry and modalEntry.focusable then self:_setActiveEntry(modalEntry) end
        return blocked
    end

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
    if not entry or not entry.visible or not entry.enabled
       or not self:_entryAllowedByModal(entry) then return false end

    local handler = entry.window[method]
    if type(handler) ~= "function" then return false end
    return handler(entry.window, ...) ~= false
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
    if entry.visible and entry.modal and entry.enabled and entry.focusable then
        self:_releaseBlockedCaptures()
        self:_setActiveEntry(entry)
    end
    return true
end

function WindowStack:setEnabled(window, enabled)
    local entry = self.byWindow[window]
    if not entry then return false end
    entry.enabled = not not enabled
    if not entry.enabled then self:_releaseEntry(entry) end
    if entry.enabled and entry.modal and entry.visible and entry.focusable then
        self:_releaseBlockedCaptures()
        self:_setActiveEntry(entry)
    end
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
    if entry.id then self.byId[entry.id] = nil end
    for i, current in ipairs(self.entries) do
        if current == entry then
            table.remove(self.entries, i)
            break
        end
    end
    return true
end

function WindowStack:clear()
    while #self.entries > 0 do
        self:remove(self.entries[#self.entries].window)
    end
    return self
end

return WindowStack
