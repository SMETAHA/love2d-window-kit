-- WindowManager.lua
-- Corrected drag-to-scroll implementation to avoid "jerky" movement.

local WindowManager = {}
WindowManager.__index = WindowManager
WindowManager.VERSION = "1.0.0"

local function copyColor(color)
    return { color[1], color[2], color[3], color[4] == nil and 1 or color[4] }
end

local function validateColor(color, name)
    assert(type(color) == "table", name .. " must be a color table")
    assert(type(color[1]) == "number" and type(color[2]) == "number"
        and type(color[3]) == "number", name .. " must contain r, g and b")
    assert(color[4] == nil or type(color[4]) == "number", name .. " alpha must be a number")
    for i = 1, 4 do
        if color[i] ~= nil then
            assert(color[i] >= 0 and color[i] <= 1, name .. " components must be between 0 and 1")
        end
    end
end

local function changed(a, b)
    return math.abs(a - b) > 1e-9
end

local function setColor(color, alphaMultiplier)
    love.graphics.setColor(color[1], color[2], color[3],
        (color[4] == nil and 1 or color[4]) * (alphaMultiplier or 1))
end

local function tracebackMessage(message)
    if debug and debug.traceback then return debug.traceback(message, 2) end
    return tostring(message)
end

function WindowManager.new(options)
    local self = setmetatable({}, WindowManager)

    -- Floating or fullscreen
    self.isFloating = false
    self.x = 0
    self.y = 0
    self.w = love.graphics.getWidth()
    self.h = love.graphics.getHeight()

    -- Title bar (for floating mode)
    self.title = ""
    self.titleBarHeight = 24
    self.isDraggable = false
    self.isDraggingWindow = false
    self.windowDragOffsetX = 0
    self.windowDragOffsetY = 0

    -- Content (virtual size)
    self.contentWidth = 1000
    self.contentHeight = 1000

    -- Scroll position
    self.scrollX = 0
    self.scrollY = 0

    -- Zoom
    self.zoom = 1
    self.minZoom = 0.5
    self.maxZoom = 3
    self.alignSmallContent = true
    self.dragToScroll = true

    -- Scroll speed for wheel
    self.scrollSpeed = 50

    -- Scrollbars
    self.scrollbarWidth = 10
    self.scrollbarColor = {0.7, 0.7, 0.7, 0.9}
    self.scrollbarTrackColor = {0.15, 0.15, 0.15, 0.35}
    self.scrollbarHoverColor = {0.85, 0.85, 0.85, 1}
    self.scrollbarActiveColor = {1, 1, 1, 1}
    self.showScrollbar = true
    self.scrollbarMinThumbSize = 24
    self.scrollbarPageStep = 0.9
    self.scrollbarAutoHide = false
    self.scrollbarAutoHideDelay = 1
    self.scrollbarFadeDuration = 0.25
    self.scrollbarAlpha = 1
    self.scrollbarIdleTime = 0
    self.hoveredScrollbar = nil

    -- Window chrome theme
    self.frameColor = {0.2, 0.2, 0.2, 0.9}
    self.titleBarColor = {0.3, 0.3, 0.3, 1}
    self.titleTextColor = {1, 1, 1, 1}
    self.borderColor = {1, 1, 1, 1}

    -- Flags for dragging
    self.isDraggingVertical = false
    self.isDraggingHorizontal = false
    self.isDraggingContent = false

    -- For dragging content, we store the initial click in local coords
    self.dragStartLocalX = 0
    self.dragStartLocalY = 0
    self.dragOrigScrollX = 0
    self.dragOrigScrollY = 0

    -- Real window size
    self.windowWidth = self.w
    self.windowHeight = self.h

    -- Scrollbar values
    self.verticalScrollbarHeight = 0
    self.verticalScrollbarY = 0
    self.horizontalScrollbarWidthScaled = 0
    self.horizontalScrollbarX = 0

    -- Callbacks
    self.onScroll = nil
    self.onZoom = nil

    -- Preferred floating size is used to restore layout after orientation changes.
    self.preferredW = self.w
    self.preferredH = self.h

    if options then
        self._suppressCallbacks = true
        self:configure(options)
        self._suppressCallbacks = false
    end

    return self
end

function WindowManager:_snapshot()
    return self.scrollX, self.scrollY, self.zoom
end

function WindowManager:_emitChanges(oldX, oldY, oldZoom, reason)
    if self._suppressCallbacks then return end
    if changed(oldZoom, self.zoom) and self.onZoom then
        self.onZoom(oldZoom, self.zoom, self, reason)
    end
    if (changed(oldX, self.scrollX) or changed(oldY, self.scrollY)) and self.onScroll then
        self.onScroll(self.scrollX, self.scrollY, oldX, oldY, self, reason)
    end
end

function WindowManager:_showScrollbars()
    self.scrollbarIdleTime = 0
    self.scrollbarAlpha = 1
end

------------------------------------------------------------------------------
--                        Checking if point is in window                     --
------------------------------------------------------------------------------

function WindowManager:isPointInsideWindow(mx, my)
    if not self.isFloating then
        return mx >= 0 and mx <= self.w and my >= 0 and my <= self.h
    end
    return (mx >= self.x and mx <= (self.x + self.w)
        and my >= self.y and my <= (self.y + self.h))
end

------------------------------------------------------------------------------
--                               Setup / Modes                                --
------------------------------------------------------------------------------

function WindowManager:setFloating(x, y, w, h)
    local oldX, oldY, oldZoom = self:_snapshot()
    assert(type(x) == "number" and type(y) == "number", "x and y must be numbers")
    assert(type(w) == "number" and w > 0, "w must be greater than zero")
    assert(type(h) == "number" and h > 0, "h must be greater than zero")
    assert(self.titleBarHeight < h, "title bar height must be smaller than the window")
    self.isFloating = true
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.preferredW = w
    self.preferredH = h
    self.windowWidth = w
    self.windowHeight = h
    self:limitScroll(true)
    self:_emitChanges(oldX, oldY, oldZoom, "floating")
    return self
end

function WindowManager:setFullscreen()
    local oldX, oldY, oldZoom = self:_snapshot()
    self.isFloating = false
    self.x = 0
    self.y = 0
    self.w = love.graphics.getWidth()
    self.h = love.graphics.getHeight()
    self.windowWidth = self.w
    self.windowHeight = self.h
    self.preferredW = self.w
    self.preferredH = self.h
    self:limitScroll(true)
    self:_emitChanges(oldX, oldY, oldZoom, "fullscreen")
    return self
end

function WindowManager:setSystemWindow(params)
    local SystemWindow = require("SystemWindow")
    local success, message = SystemWindow.configure(params)
    if success and not self.isFloating then
        self:resize(love.graphics.getDimensions())
    end
    return success, message
end

function WindowManager:load(contentWidth, contentHeight)
    local oldX, oldY, oldZoom = self:_snapshot()
    assert(contentWidth == nil or (type(contentWidth) == "number" and contentWidth >= 0),
        "contentWidth must be a non-negative number")
    assert(contentHeight == nil or (type(contentHeight) == "number" and contentHeight >= 0),
        "contentHeight must be a non-negative number")
    self.contentWidth = contentWidth or self.windowWidth
    self.contentHeight = contentHeight or self.windowHeight
    self:limitScroll(true)
    self:_emitChanges(oldX, oldY, oldZoom, "content-size")
    return self
end

function WindowManager:setContentSize(width, height)
    local oldX, oldY, oldZoom = self:_snapshot()
    assert(type(width) == "number" and width >= 0, "width must be a non-negative number")
    assert(type(height) == "number" and height >= 0, "height must be a non-negative number")
    self.contentWidth, self.contentHeight = width, height
    self:limitScroll()
    self:_emitChanges(oldX, oldY, oldZoom, "content-size")
    return self
end

WindowManager.updateContentSize = WindowManager.setContentSize

function WindowManager:setPosition(x, y)
    assert(type(x) == "number" and type(y) == "number", "x and y must be numbers")
    self.x, self.y = x, y
    return self
end

function WindowManager:setSize(width, height)
    local oldX, oldY, oldZoom = self:_snapshot()
    assert(type(width) == "number" and width > 0, "width must be greater than zero")
    assert(type(height) == "number" and height > 0, "height must be greater than zero")
    if self.isFloating then
        assert(self.titleBarHeight < height, "title bar height must be smaller than the window")
    end
    self.w, self.h = width, height
    self.windowWidth, self.windowHeight = width, height
    self.preferredW, self.preferredH = width, height
    self:limitScroll()
    self:_emitChanges(oldX, oldY, oldZoom, "size")
    return self
end

function WindowManager:setTitle(title)
    assert(type(title) == "string", "title must be a string")
    self.title = title
    return self
end

function WindowManager:setTitleBar(height, draggable)
    local oldX, oldY, oldZoom = self:_snapshot()
    assert(type(height) == "number" and height >= 0, "title bar height must be non-negative")
    assert(height < self.h, "title bar height must be smaller than the window")
    self.titleBarHeight = height
    if draggable ~= nil then self.isDraggable = not not draggable end
    self:limitScroll()
    self:_emitChanges(oldX, oldY, oldZoom, "title-bar")
    return self
end

function WindowManager:setDraggable(enabled)
    self.isDraggable = not not enabled
    return self
end

function WindowManager:setDragToScroll(enabled)
    self.dragToScroll = not not enabled
    return self
end

function WindowManager:setAlignSmallContent(enabled)
    local oldX, oldY, oldZoom = self:_snapshot()
    self.alignSmallContent = not not enabled
    self:limitScroll()
    self:_emitChanges(oldX, oldY, oldZoom, "alignment")
    return self
end

function WindowManager:setScrollSpeed(speed)
    assert(type(speed) == "number" and speed >= 0, "scroll speed must be non-negative")
    self.scrollSpeed = speed
    return self
end

function WindowManager:setZoomLimits(minZoom, maxZoom)
    assert(type(minZoom) == "number" and minZoom > 0, "minZoom must be greater than zero")
    assert(type(maxZoom) == "number" and maxZoom >= minZoom,
        "maxZoom must be greater than or equal to minZoom")
    self.minZoom, self.maxZoom = minZoom, maxZoom
    self:setZoom(self.zoom, nil, nil, "zoom-limits")
    return self
end

function WindowManager:setCallbacks(callbacks)
    callbacks = callbacks or {}
    assert(type(callbacks) == "table", "callbacks must be a table")
    assert(callbacks.onScroll == nil or type(callbacks.onScroll) == "function",
        "onScroll must be a function")
    assert(callbacks.onZoom == nil or type(callbacks.onZoom) == "function",
        "onZoom must be a function")
    if callbacks.onScroll ~= nil then self.onScroll = callbacks.onScroll end
    if callbacks.onZoom ~= nil then self.onZoom = callbacks.onZoom end
    return self
end

function WindowManager:setOnScroll(callback)
    assert(callback == nil or type(callback) == "function", "callback must be a function or nil")
    self.onScroll = callback
    return self
end

function WindowManager:setOnZoom(callback)
    assert(callback == nil or type(callback) == "function", "callback must be a function or nil")
    self.onZoom = callback
    return self
end

function WindowManager:setScrollbarOptions(options)
    options = options or {}
    assert(type(options) == "table", "scrollbar options must be a table")

    if options.visible ~= nil then self.showScrollbar = not not options.visible end
    if options.width ~= nil then
        assert(type(options.width) == "number" and options.width > 0,
            "scrollbar width must be greater than zero")
        self.scrollbarWidth = options.width
    end
    if options.minThumbSize ~= nil then
        assert(type(options.minThumbSize) == "number" and options.minThumbSize >= 0,
            "minThumbSize must be non-negative")
        self.scrollbarMinThumbSize = options.minThumbSize
    end
    if options.pageStep ~= nil then
        assert(type(options.pageStep) == "number" and options.pageStep > 0,
            "pageStep must be greater than zero")
        self.scrollbarPageStep = options.pageStep
    end
    if options.autoHide ~= nil then self.scrollbarAutoHide = not not options.autoHide end
    if options.autoHideDelay ~= nil then
        assert(type(options.autoHideDelay) == "number" and options.autoHideDelay >= 0,
            "autoHideDelay must be non-negative")
        self.scrollbarAutoHideDelay = options.autoHideDelay
    end
    if options.fadeDuration ~= nil then
        assert(type(options.fadeDuration) == "number" and options.fadeDuration >= 0,
            "fadeDuration must be non-negative")
        self.scrollbarFadeDuration = options.fadeDuration
    end

    local colors = {
        color = "scrollbarColor",
        trackColor = "scrollbarTrackColor",
        hoverColor = "scrollbarHoverColor",
        activeColor = "scrollbarActiveColor"
    }
    for optionName, fieldName in pairs(colors) do
        if options[optionName] then
            validateColor(options[optionName], optionName)
            self[fieldName] = copyColor(options[optionName])
        end
    end

    if not self.scrollbarAutoHide then self.scrollbarAlpha = 1 end
    self:updateScrollbars()
    return self
end

function WindowManager:setTheme(theme)
    theme = theme or {}
    assert(type(theme) == "table", "theme must be a table")
    local colors = {
        frameColor = "frameColor",
        titleBarColor = "titleBarColor",
        titleTextColor = "titleTextColor",
        borderColor = "borderColor"
    }
    for optionName, fieldName in pairs(colors) do
        if theme[optionName] then
            validateColor(theme[optionName], optionName)
            self[fieldName] = copyColor(theme[optionName])
        end
    end
    return self
end

function WindowManager:configure(options)
    assert(type(options) == "table", "options must be a table")

    if options.callbacks then self:setCallbacks(options.callbacks) end
    if options.onScroll ~= nil then self:setOnScroll(options.onScroll) end
    if options.onZoom ~= nil then self:setOnZoom(options.onZoom) end

    if options.minZoom ~= nil or options.maxZoom ~= nil then
        self:setZoomLimits(options.minZoom or self.minZoom, options.maxZoom or self.maxZoom)
    end

    if options.floating == true then
        local targetHeight = options.height or options.h or self.h
        local targetTitleHeight = options.titleBarHeight or self.titleBarHeight
        assert(targetTitleHeight < targetHeight,
            "title bar height must be smaller than the floating window")
        if self.titleBarHeight >= targetHeight then
            self.titleBarHeight = targetTitleHeight
        end
        self:setFloating(options.x or self.x, options.y or self.y,
            options.width or options.w or self.w, targetHeight)
    elseif options.floating == false then
        self:setFullscreen()
    elseif options.x ~= nil or options.y ~= nil then
        self:setPosition(options.x or self.x, options.y or self.y)
    end

    if options.floating == nil and (options.width or options.w or options.height or options.h) then
        self:setSize(options.width or options.w or self.w, options.height or options.h or self.h)
    end

    if options.title ~= nil then self:setTitle(options.title) end
    if options.titleBarHeight ~= nil then
        self:setTitleBar(options.titleBarHeight, options.draggable)
    elseif options.draggable ~= nil then
        self:setDraggable(options.draggable)
    end
    if options.dragToScroll ~= nil then self:setDragToScroll(options.dragToScroll) end
    if options.alignSmallContent ~= nil then self:setAlignSmallContent(options.alignSmallContent) end
    if options.scrollSpeed ~= nil then self:setScrollSpeed(options.scrollSpeed) end
    if options.scrollbar then self:setScrollbarOptions(options.scrollbar) end
    if options.theme then self:setTheme(options.theme) end

    if options.contentWidth ~= nil or options.contentHeight ~= nil then
        self:setContentSize(options.contentWidth or self.contentWidth,
            options.contentHeight or self.contentHeight)
    end
    if options.zoom ~= nil then self:setZoom(options.zoom, nil, nil, "configure") end
    return self
end

------------------------------------------------------------------------------
--                               wheelmoved                                  --
------------------------------------------------------------------------------

function WindowManager:wheelmoved(wx, wy)
    -- Check if mouse is inside this window
    local mx, my = love.mouse.getPosition()
    if not self:isPointInsideWindow(mx, my) then
        return false
    end

    local offsetTop = self.isFloating and self.titleBarHeight or 0
    if my - self.y < offsetTop then
        return true
    end

    if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
        self:setZoom(self.zoom + wy * 0.1, mx, my, "wheel-zoom")
    else
        local oldX, oldY, oldZoom = self:_snapshot()
        self.scrollX = self.scrollX - wx * self.scrollSpeed / self.zoom
        self.scrollY = self.scrollY - wy * self.scrollSpeed / self.zoom
        self:limitScroll()
        self:_showScrollbars()
        self:_emitChanges(oldX, oldY, oldZoom, "wheel")
    end
    return true
end

------------------------------------------------------------------------------
--                         mousepressed / mousereleased                      --
------------------------------------------------------------------------------

function WindowManager:mousepressed(mx, my, button)
    if button ~= 1 then
        return false
    end

    -- Check bounding box
    if not self:isPointInsideWindow(mx, my) then
        return false
    end

    -- If floating with title bar
    if self.isFloating and self.isDraggable then
        if my >= self.y and my <= (self.y + self.titleBarHeight)
           and mx >= self.x and mx <= (self.x + self.w) then
            -- Drag the entire window
            self.isDraggingWindow = true
            self.windowDragOffsetX = mx - self.x
            self.windowDragOffsetY = my - self.y
            return true
        end
    end

    -- Check scrollbars
    local localX = mx - self.x
    local localY = my - self.y
    local offsetTop = self.isFloating and self.titleBarHeight or 0

    -- The title bar is chrome, not scrollable content.
    if localY < offsetTop then
        return true
    end

    if self.showScrollbar and self.verticalScrollbarHeight > 0 then
        if localX >= self.w - self.scrollbarWidth
           and localY >= self.verticalScrollbarY
           and localY <= (self.verticalScrollbarY + self.verticalScrollbarHeight) then
            self.isDraggingVertical = true
            self.dragStartY = localY
            self.scrollStartY = self.scrollY
            self:_showScrollbars()
            return true
        end

        if localX >= self.w - self.scrollbarWidth
           and localY >= offsetTop and localY <= self.h then
            local oldX, oldY, oldZoom = self:_snapshot()
            local visibleH = (self.h - offsetTop) / self.zoom
            local direction = localY < self.verticalScrollbarY and -1 or 1
            self.scrollY = self.scrollY + direction * visibleH * self.scrollbarPageStep
            self:limitScroll()
            self:_showScrollbars()
            self:_emitChanges(oldX, oldY, oldZoom, "vertical-page")
            return true
        end
    end

    if self.showScrollbar and self.horizontalScrollbarWidthScaled > 0 then
        if localY >= self.h - self.scrollbarWidth
           and localX >= self.horizontalScrollbarX
           and localX <= (self.horizontalScrollbarX + self.horizontalScrollbarWidthScaled) then
            self.isDraggingHorizontal = true
            self.dragStartX = localX
            self.scrollStartX = self.scrollX
            self:_showScrollbars()
            return true
        end


        if localY >= self.h - self.scrollbarWidth
           and localX >= 0 and localX <= self.w then
            local oldX, oldY, oldZoom = self:_snapshot()
            local visibleW = self.w / self.zoom
            local direction = localX < self.horizontalScrollbarX and -1 or 1
            self.scrollX = self.scrollX + direction * visibleW * self.scrollbarPageStep
            self:limitScroll()
            self:_showScrollbars()
            self:_emitChanges(oldX, oldY, oldZoom, "horizontal-page")
            return true
        end
    end

    -- Otherwise, we drag the content
    self.isDraggingContent = self.dragToScroll
    -- We'll store the local coords where we clicked
    self.dragStartLocalX = localX
    self.dragStartLocalY = localY
    self.dragOrigScrollX = self.scrollX
    self.dragOrigScrollY = self.scrollY

    self:_showScrollbars()

    return true
end

function WindowManager:mousereleased(mx, my, button)
    if button ~= 1 then
        return false
    end

    local wasDragging = (self.isDraggingWindow or self.isDraggingVertical
                         or self.isDraggingHorizontal or self.isDraggingContent)
    if not wasDragging then
        return false
    end

    -- Reset flags
    self.isDraggingWindow = false
    self.isDraggingVertical = false
    self.isDraggingHorizontal = false
    self.isDraggingContent = false
    self:_showScrollbars()

    return true
end

------------------------------------------------------------------------------
--                            mousemoved                                     --
------------------------------------------------------------------------------

function WindowManager:mousemoved(mx, my, dx, dy)
    local inside = self:isPointInsideWindow(mx, my)
    local dragging = (self.isDraggingWindow or self.isDraggingVertical
                      or self.isDraggingHorizontal or self.isDraggingContent)

    if (not inside) and (not dragging) then
        self.hoveredScrollbar = nil
        return false
    end

    if not dragging and self.showScrollbar then
        local localX, localY = mx - self.x, my - self.y
        local offsetTop = self.isFloating and self.titleBarHeight or 0
        if self.verticalScrollbarHeight > 0
           and localX >= self.w - self.scrollbarWidth and localX <= self.w
           and localY >= offsetTop and localY <= self.h then
            self.hoveredScrollbar = "vertical"
            self:_showScrollbars()
        elseif self.horizontalScrollbarWidthScaled > 0
           and localY >= self.h - self.scrollbarWidth and localY <= self.h
           and localX >= 0 and localX <= self.w then
            self.hoveredScrollbar = "horizontal"
            self:_showScrollbars()
        else
            self.hoveredScrollbar = nil
        end
    end

    -- Dragging the window?
    if self.isDraggingWindow then
        self.x = mx - self.windowDragOffsetX
        self.y = my - self.windowDragOffsetY

        -- Prevent the window from going off-screen
        local sw, sh = love.graphics.getDimensions()
        self.x = math.max(0, math.min(self.x, math.max(0, sw - self.w)))
        self.y = math.max(0, math.min(self.y, math.max(0, sh - self.h)))

        return true
    end

    -- Dragging vertical scrollbar
    if self.isDraggingVertical then
        local oldX, oldY, oldZoom = self:_snapshot()
        local localY = my - self.y
        local deltaY = localY - self.dragStartY
        local offsetTop = self.isFloating and self.titleBarHeight or 0
        local visibleH = self.h - offsetTop
        local maxScrollY = self.contentHeight - (visibleH / self.zoom)

        local maxSBY = visibleH - self.verticalScrollbarHeight
        if maxSBY > 0 then
            self.scrollY = self.scrollStartY + (deltaY * (maxScrollY / maxSBY))
        end
        self:limitScroll()
        self:_showScrollbars()
        self:_emitChanges(oldX, oldY, oldZoom, "vertical-drag")
        return true
    end

    -- Dragging horizontal scrollbar
    if self.isDraggingHorizontal then
        local oldX, oldY, oldZoom = self:_snapshot()
        local localX = mx - self.x
        local deltaX = localX - self.dragStartX
        local maxScrollX = self.contentWidth - (self.w / self.zoom)
        local maxSBX = self.w - self.horizontalScrollbarWidthScaled

        if maxSBX > 0 then
            self.scrollX = self.scrollStartX + (deltaX * (maxScrollX / maxSBX))
        end
        self:limitScroll()
        self:_showScrollbars()
        self:_emitChanges(oldX, oldY, oldZoom, "horizontal-drag")
        return true
    end

    -- Dragging the content
    if self.isDraggingContent then
        local oldX, oldY, oldZoom = self:_snapshot()
        local localX = mx - self.x
        local localY = my - self.y

        -- Compute how far the mouse moved from the initial local coords
        local diffX = (localX - self.dragStartLocalX)
        local diffY = (localY - self.dragStartLocalY)

        self.scrollX = self.dragOrigScrollX - (diffX / self.zoom)
        self.scrollY = self.dragOrigScrollY - (diffY / self.zoom)
        self:limitScroll()
        self:_showScrollbars()
        self:_emitChanges(oldX, oldY, oldZoom, "content-drag")
        return true
    end

    return false
end

------------------------------------------------------------------------------
--                          Touch events (for mobile)                        --
------------------------------------------------------------------------------

function WindowManager:touchpressed(id, tx, ty, dx, dy, pressure)
    if not self:isPointInsideWindow(tx, ty) then
        return false
    end
    self.activeTouches = self.activeTouches or {}
    local offsetTop = self.isFloating and self.titleBarHeight or 0
    self.activeTouches[id] = {
        x = tx,
        y = ty,
        content = (ty - self.y) >= offsetTop and self.dragToScroll
    }
    self:_showScrollbars()
    return true
end

function WindowManager:touchmoved(id, tx, ty, dx, dy, pressure)
    if not self.activeTouches or not self.activeTouches[id] then
        return false
    end
    if not self.activeTouches[id].content then
        return true
    end
    local oldX, oldY, oldZoom = self:_snapshot()
    -- Simple approach: move content
    local ddx = dx / self.zoom
    local ddy = dy / self.zoom
    self.scrollX = self.scrollX - ddx
    self.scrollY = self.scrollY - ddy
    self:limitScroll()
    self.activeTouches[id].x, self.activeTouches[id].y = tx, ty
    self:_showScrollbars()
    self:_emitChanges(oldX, oldY, oldZoom, "touch-drag")
    return true
end

function WindowManager:touchreleased(id, tx, ty, dx, dy, pressure)
    if not self.activeTouches or not self.activeTouches[id] then
        return false
    end
    self.activeTouches[id] = nil
    self:_showScrollbars()
    return true
end

------------------------------------------------------------------------------
--                              DRAW                                         --
------------------------------------------------------------------------------

function WindowManager:draw(drawFunction)
    assert(type(drawFunction) == "function", "drawFunction must be a function")
    love.graphics.push("all")

    if self.isFloating then
        self:drawWindowFrame()
    end

    love.graphics.push("all")
    local offsetTop = self.isFloating and self.titleBarHeight or 0
    love.graphics.setScissor(self.x, self.y + offsetTop, self.w, self.h - offsetTop)

    love.graphics.translate(self.x, self.y)
    love.graphics.translate(0, offsetTop)
    love.graphics.translate(-self.scrollX * self.zoom, -self.scrollY * self.zoom)
    love.graphics.scale(self.zoom, self.zoom)

    local visibleW = self.w / self.zoom
    local visibleH = (self.h - offsetTop) / self.zoom
    local success, message = xpcall(function()
        drawFunction(self.scrollX, self.scrollY, visibleW, visibleH)
    end, tracebackMessage)

    love.graphics.pop()

    if not success then
        love.graphics.pop()
        error(message, 0)
    end

    if self.showScrollbar then
        self:drawScrollbars()
    end

    love.graphics.pop()
end

function WindowManager:drawWindowFrame()
    setColor(self.frameColor)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    if self.titleBarHeight > 0 then
        setColor(self.titleBarColor)
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.titleBarHeight)
        setColor(self.titleTextColor)
        if self.title and #self.title > 0 then
            love.graphics.print(self.title, self.x + 5, self.y + 5)
        end
    end

    setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
end

function WindowManager:drawScrollbars()
    local contentWZoomed = self.contentWidth * self.zoom
    local contentHZoomed = self.contentHeight * self.zoom
    local offsetTop = self.isFloating and self.titleBarHeight or 0
    local visibleH = self.h - offsetTop

    if self.scrollbarAlpha <= 0 then return end

    local function thumbColor(axis)
        if (axis == "vertical" and self.isDraggingVertical)
           or (axis == "horizontal" and self.isDraggingHorizontal) then
            return self.scrollbarActiveColor
        elseif self.hoveredScrollbar == axis then
            return self.scrollbarHoverColor
        end
        return self.scrollbarColor
    end

    -- Vertical
    if contentHZoomed > visibleH and self.verticalScrollbarHeight > 0 then
        setColor(self.scrollbarTrackColor, self.scrollbarAlpha)
        love.graphics.rectangle(
            "fill",
            self.x + self.w - self.scrollbarWidth,
            self.y + offsetTop,
            self.scrollbarWidth,
            visibleH
        )
        setColor(thumbColor("vertical"), self.scrollbarAlpha)
        love.graphics.rectangle(
            "fill",
            self.x + self.w - self.scrollbarWidth,
            self.y + self.verticalScrollbarY,
            self.scrollbarWidth,
            self.verticalScrollbarHeight
        )
    end

    -- Horizontal
    if contentWZoomed > self.w and self.horizontalScrollbarWidthScaled > 0 then
        setColor(self.scrollbarTrackColor, self.scrollbarAlpha)
        love.graphics.rectangle(
            "fill",
            self.x,
            self.y + self.h - self.scrollbarWidth,
            self.w,
            self.scrollbarWidth
        )
        setColor(thumbColor("horizontal"), self.scrollbarAlpha)
        love.graphics.rectangle(
            "fill",
            self.x + self.horizontalScrollbarX,
            self.y + self.h - self.scrollbarWidth,
            self.horizontalScrollbarWidthScaled,
            self.scrollbarWidth
        )
    end

    love.graphics.setColor(1, 1, 1, 1)
end

------------------------------------------------------------------------------
--                         LIMIT SCROLL, ZOOM, ETC.                          --
------------------------------------------------------------------------------

function WindowManager:limitScroll(forceAlign)
    local offsetTop = self.isFloating and self.titleBarHeight or 0
    local visibleH = self.h - offsetTop

    local visibleWInContent = self.w / self.zoom
    local visibleHInContent = visibleH / self.zoom
    local maxScrollX = self.contentWidth - visibleWInContent
    local maxScrollY = self.contentHeight - visibleHInContent

    local alignX = (forceAlign or self.alignSmallContent)
    local alignY = (forceAlign or self.alignSmallContent)

    if maxScrollX < 0 and alignX then
        self.scrollX = maxScrollX / 2
    else
        self.scrollX = math.max(0, math.min(self.scrollX, math.max(0, maxScrollX)))
    end

    if maxScrollY < 0 and alignY then
        self.scrollY = maxScrollY / 2
    else
        self.scrollY = math.max(0, math.min(self.scrollY, math.max(0, maxScrollY)))
    end

    self:updateScrollbars()
end

function WindowManager:updateScrollbars()
    local offsetTop = self.isFloating and self.titleBarHeight or 0
    local visibleH = self.h - offsetTop
    local contentWZoomed = self.contentWidth * self.zoom
    local contentHZoomed = self.contentHeight * self.zoom

    -- Vertical
    if contentHZoomed > visibleH then
        local maxScrollY = self.contentHeight - (visibleH / self.zoom)
        local maxThumbHeight = math.max(1, visibleH - 1)
        self.verticalScrollbarHeight = math.min(maxThumbHeight, math.max(
            self.scrollbarMinThumbSize,
            (visibleH / contentHZoomed) * visibleH
        ))
        self.verticalScrollbarY = offsetTop + (self.scrollY / maxScrollY)
            * (visibleH - self.verticalScrollbarHeight)
    else
        self.verticalScrollbarHeight = 0
        self.verticalScrollbarY = offsetTop
    end

    -- Horizontal
    if contentWZoomed > self.w then
        local maxScrollX = self.contentWidth - (self.w / self.zoom)
        local maxThumbWidth = math.max(1, self.w - 1)
        self.horizontalScrollbarWidthScaled = math.min(maxThumbWidth, math.max(
            self.scrollbarMinThumbSize,
            (self.w / contentWZoomed) * self.w
        ))
        self.horizontalScrollbarX = (self.scrollX / maxScrollX)
            * (self.w - self.horizontalScrollbarWidthScaled)
    else
        self.horizontalScrollbarWidthScaled = 0
        self.horizontalScrollbarX = 0
    end
end

function WindowManager:setZoom(z, anchorX, anchorY, reason)
    assert(type(z) == "number", "zoom must be a number")
    assert((anchorX == nil and anchorY == nil)
        or (type(anchorX) == "number" and type(anchorY) == "number"),
        "anchorX and anchorY must both be numbers")

    local oldX, oldY, oldZoom = self:_snapshot()
    local anchorContentX, anchorContentY
    if anchorX ~= nil then
        anchorContentX, anchorContentY = self:screenToContent(anchorX, anchorY)
    end

    if z < self.minZoom then
        z = self.minZoom
    elseif z > self.maxZoom then
        z = self.maxZoom
    end
    self.zoom = z

    if anchorContentX then
        local localX = anchorX - self.x
        local offsetTop = self.isFloating and self.titleBarHeight or 0
        local localY = anchorY - self.y - offsetTop
        self.scrollX = anchorContentX - (localX / self.zoom)
        self.scrollY = anchorContentY - (localY / self.zoom)
    end

    self:limitScroll()
    self:_showScrollbars()
    self:_emitChanges(oldX, oldY, oldZoom, reason or "zoom")
    return self
end

function WindowManager:zoomIn(step)
    step = step or 0.1
    return self:setZoom(self.zoom + step, nil, nil, "zoom-in")
end

function WindowManager:zoomOut(step)
    step = step or 0.1
    return self:setZoom(self.zoom - step, nil, nil, "zoom-out")
end

function WindowManager:screenToContent(mx, my)
    local lx = mx - self.x
    local offsetTop = self.isFloating and self.titleBarHeight or 0
    local ly = my - self.y - offsetTop
    return (lx / self.zoom) + self.scrollX, (ly / self.zoom) + self.scrollY
end

function WindowManager:getState()
    return {
        scrollX = self.scrollX,
        scrollY = self.scrollY,
        zoom = self.zoom,
        x = self.x,
        y = self.y,
        w = self.w,
        h = self.h
    }
end

function WindowManager:setState(st)
    assert(type(st) == "table", "state must be a table")
    local oldX, oldY, oldZoom = self:_snapshot()
    if st.scrollX ~= nil then
        assert(type(st.scrollX) == "number", "scrollX must be a number")
        self.scrollX = st.scrollX
    end
    if st.scrollY ~= nil then
        assert(type(st.scrollY) == "number", "scrollY must be a number")
        self.scrollY = st.scrollY
    end
    if st.zoom ~= nil then
        assert(type(st.zoom) == "number", "zoom must be a number")
        self.zoom = math.max(self.minZoom, math.min(st.zoom, self.maxZoom))
    end
    if st.x ~= nil then
        assert(type(st.x) == "number", "x must be a number")
        self.x = st.x
    end
    if st.y ~= nil then
        assert(type(st.y) == "number", "y must be a number")
        self.y = st.y
    end
    if st.w then
        assert(type(st.w) == "number" and st.w > 0, "w must be greater than zero")
        self.w = st.w
        self.windowWidth = st.w
        self.preferredW = st.w
    end
    if st.h then
        assert(type(st.h) == "number" and st.h > 0, "h must be greater than zero")
        if self.isFloating then
            assert(self.titleBarHeight < st.h, "title bar height must be smaller than the window")
        end
        self.h = st.h
        self.windowHeight = st.h
        self.preferredH = st.h
    end
    self:limitScroll(true)
    self:_showScrollbars()
    self:_emitChanges(oldX, oldY, oldZoom, "state")
    return self
end

function WindowManager:update(dt)
    assert(type(dt) == "number" and dt >= 0, "dt must be a non-negative number")
    if not self.showScrollbar or not self.scrollbarAutoHide then
        self.scrollbarAlpha = 1
        return
    end
    if self.isDraggingVertical or self.isDraggingHorizontal or self.isDraggingContent
       or self.hoveredScrollbar then
        self:_showScrollbars()
        return
    end

    self.scrollbarIdleTime = self.scrollbarIdleTime + dt
    if self.scrollbarIdleTime > self.scrollbarAutoHideDelay then
        if self.scrollbarFadeDuration == 0 then
            self.scrollbarAlpha = 0
        else
            self.scrollbarAlpha = math.max(0,
                self.scrollbarAlpha - (dt / self.scrollbarFadeDuration))
        end
    end
end

function WindowManager:resize(w, h)
    if self.isFloating then
        return false
    end
    assert(type(w) == "number" and w > 0, "w must be greater than zero")
    assert(type(h) == "number" and h > 0, "h must be greater than zero")
    local oldX, oldY, oldZoom = self:_snapshot()
    self.w, self.h = w, h
    self.windowWidth, self.windowHeight = w, h
    self.preferredW, self.preferredH = w, h
    self:limitScroll()
    self:_emitChanges(oldX, oldY, oldZoom, "resize")
    return true
end

function WindowManager:constrainToScreen(screenWidth, screenHeight, shrink)
    assert(type(screenWidth) == "number" and screenWidth > 0,
        "screenWidth must be greater than zero")
    assert(type(screenHeight) == "number" and screenHeight > 0,
        "screenHeight must be greater than zero")
    if not self.isFloating then return false end

    local oldX, oldY, oldZoom = self:_snapshot()
    if shrink then
        self.w = math.min(self.preferredW, screenWidth)
        self.h = math.min(self.preferredH, screenHeight)
        self.windowWidth, self.windowHeight = self.w, self.h
    end
    self.x = math.max(0, math.min(self.x, math.max(0, screenWidth - self.w)))
    self.y = math.max(0, math.min(self.y, math.max(0, screenHeight - self.h)))
    self:limitScroll()
    self:_emitChanges(oldX, oldY, oldZoom, "screen-constraint")
    return true
end

function WindowManager:cancelInput()
    self.isDraggingWindow = false
    self.isDraggingVertical = false
    self.isDraggingHorizontal = false
    self.isDraggingContent = false
    self.activeTouches = {}
    self.hoveredScrollbar = nil
end

function WindowManager:keypressed(key)
    -- Step-based scrolling
    local oldX, oldY, oldZoom = self:_snapshot()
    if key == "up" then
        self.scrollY = self.scrollY - self.scrollSpeed / self.zoom
    elseif key == "down" then
        self.scrollY = self.scrollY + self.scrollSpeed / self.zoom
    elseif key == "left" then
        self.scrollX = self.scrollX - self.scrollSpeed / self.zoom
    elseif key == "right" then
        self.scrollX = self.scrollX + self.scrollSpeed / self.zoom
    elseif key == "=" or key == "+" then
        return self:zoomIn(0.1)
    elseif key == "-" then
        return self:zoomOut(0.1)
    end
    self:limitScroll()
    self:_showScrollbars()
    self:_emitChanges(oldX, oldY, oldZoom, "keyboard")
    return true
end

return WindowManager
