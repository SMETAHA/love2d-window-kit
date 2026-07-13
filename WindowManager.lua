-- WindowManager.lua
-- Corrected drag-to-scroll implementation to avoid "jerky" movement.

local WindowManager = {}
WindowManager.__index = WindowManager
WindowManager.VERSION = "1.1.0"

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

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(value, maximum))
end

local function inputTime()
    if love.timer and love.timer.getTime then return love.timer.getTime() end
    return os.clock()
end

local easingFunctions = {
    linear = function(t) return t end,
    outQuad = function(t) return 1 - (1 - t) * (1 - t) end,
    inOutQuad = function(t)
        if t < 0.5 then return 2 * t * t end
        return 1 - ((-2 * t + 2) ^ 2) / 2
    end
}

local function resolveEasing(easing)
    if easing == nil then return easingFunctions.outQuad end
    if type(easing) == "function" then return easing end
    assert(type(easing) == "string" and easingFunctions[easing],
        "easing must be 'linear', 'outQuad', 'inOutQuad' or a function")
    return easingFunctions[easing]
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

    -- Optional resizing for floating windows
    self.isResizable = false
    self.resizeBorder = 8
    self.minWindowWidth = 96
    self.minWindowHeight = 64
    self.maxWindowWidth = nil
    self.maxWindowHeight = nil
    self.sizeLimitsEnabled = false
    self.isResizingWindow = false
    self.resizeEdges = nil

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

    -- Input policy
    self.wheelScroll = true
    self.keyboardScroll = true
    self.touchScroll = true
    self.pinchToZoom = true
    self.horizontalScroll = true
    self.verticalScroll = true
    self.shiftWheelHorizontal = true
    self.zoomModifier = "ctrl"
    self.zoomStep = 0.1

    -- Optional kinetic scrolling. Disabled by default for 1.0 compatibility.
    self.inertiaEnabled = false
    self.inertiaFriction = 8
    self.inertiaMinVelocity = 15
    self.inertiaMaxPause = 0.12
    self.velocityX = 0
    self.velocityY = 0
    self.lastDragTime = nil
    self.navigation = nil

    -- Scroll speed for wheel
    self.scrollSpeed = 50

    -- Scrollbars
    self.scrollbarWidth = 10
    self.scrollbarColor = {0.7, 0.7, 0.7, 0.9}
    self.scrollbarTrackColor = {0.15, 0.15, 0.15, 0.35}
    self.scrollbarHoverColor = {0.85, 0.85, 0.85, 1}
    self.scrollbarActiveColor = {1, 1, 1, 1}
    self.showScrollbar = true
    self.showHorizontalScrollbar = true
    self.showVerticalScrollbar = true
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
    self.onMove = nil
    self.onResize = nil
    self.onNavigationComplete = nil

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

function WindowManager:_layoutSnapshot()
    return self.x, self.y, self.w, self.h
end

function WindowManager:_emitLayoutChanges(oldX, oldY, oldW, oldH, reason)
    if self._suppressCallbacks then return end
    if (changed(oldX, self.x) or changed(oldY, self.y)) and self.onMove then
        self.onMove(self.x, self.y, oldX, oldY, self, reason)
    end
    if (changed(oldW, self.w) or changed(oldH, self.h)) and self.onResize then
        self.onResize(self.w, self.h, oldW, oldH, self, reason)
    end
end

function WindowManager:_stopMotion()
    self.navigation = nil
    self.velocityX = 0
    self.velocityY = 0
end

function WindowManager:_windowSizeLimits()
    local minHeight = math.max(self.minWindowHeight,
        self.isFloating and (self.titleBarHeight + 1) or 1)
    return self.minWindowWidth, minHeight,
        self.maxWindowWidth or math.huge, self.maxWindowHeight or math.huge
end

function WindowManager:_clampWindowSize(width, height)
    if not self.sizeLimitsEnabled and not self.isResizable then return width, height end
    local minW, minH, maxW, maxH = self:_windowSizeLimits()
    return clamp(width, minW, maxW), clamp(height, minH, maxH)
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

function WindowManager:_getResizeEdges(mx, my)
    if not self.isFloating or not self.isResizable or not self:isPointInsideWindow(mx, my) then
        return nil
    end
    local localX, localY = mx - self.x, my - self.y
    local border = math.min(self.resizeBorder, self.w / 2, self.h / 2)
    local horizontal = localX <= border and "w" or (localX >= self.w - border and "e" or "")
    local vertical = localY <= border and "n" or (localY >= self.h - border and "s" or "")
    -- Keep single-axis scrollbar tracks usable. Corners remain resize handles.
    if horizontal == "e" and vertical == "" and self.verticalScroll and self.showScrollbar
       and self.showVerticalScrollbar and self.verticalScrollbarHeight > 0 then
        horizontal = ""
    end
    if vertical == "s" and horizontal == "" and self.horizontalScroll and self.showScrollbar
       and self.showHorizontalScrollbar and self.horizontalScrollbarWidthScaled > 0 then
        vertical = ""
    end
    local edges = vertical .. horizontal
    return #edges > 0 and edges or nil
end

function WindowManager:hitTest(mx, my)
    if not self:isPointInsideWindow(mx, my) then return nil end
    local resizeEdges = self:_getResizeEdges(mx, my)
    if resizeEdges then return "resize-" .. resizeEdges end

    local localX, localY = mx - self.x, my - self.y
    local offsetTop = self.isFloating and self.titleBarHeight or 0
    if localY < offsetTop then return "titlebar" end

    if self.verticalScroll and self.showScrollbar and self.showVerticalScrollbar
       and self.verticalScrollbarHeight > 0
       and localX >= self.w - self.scrollbarWidth then
        if localY >= self.verticalScrollbarY
           and localY <= self.verticalScrollbarY + self.verticalScrollbarHeight then
            return "vertical-thumb"
        end
        return "vertical-track"
    end
    if self.horizontalScroll and self.showScrollbar and self.showHorizontalScrollbar
       and self.horizontalScrollbarWidthScaled > 0
       and localY >= self.h - self.scrollbarWidth then
        if localX >= self.horizontalScrollbarX
           and localX <= self.horizontalScrollbarX + self.horizontalScrollbarWidthScaled then
            return "horizontal-thumb"
        end
        return "horizontal-track"
    end
    return "content"
end

------------------------------------------------------------------------------
--                               Setup / Modes                                --
------------------------------------------------------------------------------

function WindowManager:setFloating(x, y, w, h)
    local oldX, oldY, oldZoom = self:_snapshot()
    local oldLayoutX, oldLayoutY, oldW, oldH = self:_layoutSnapshot()
    assert(type(x) == "number" and type(y) == "number", "x and y must be numbers")
    assert(type(w) == "number" and w > 0, "w must be greater than zero")
    assert(type(h) == "number" and h > 0, "h must be greater than zero")
    assert(self.titleBarHeight < h, "title bar height must be smaller than the window")
    self.isFloating = true
    w, h = self:_clampWindowSize(w, h)
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
    self:_emitLayoutChanges(oldLayoutX, oldLayoutY, oldW, oldH, "floating")
    return self
end

function WindowManager:setFullscreen()
    local oldX, oldY, oldZoom = self:_snapshot()
    local oldLayoutX, oldLayoutY, oldW, oldH = self:_layoutSnapshot()
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
    self:_emitLayoutChanges(oldLayoutX, oldLayoutY, oldW, oldH, "fullscreen")
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
    local oldX, oldY, oldW, oldH = self:_layoutSnapshot()
    self.x, self.y = x, y
    self:_emitLayoutChanges(oldX, oldY, oldW, oldH, "position")
    return self
end

function WindowManager:setSize(width, height)
    local oldX, oldY, oldZoom = self:_snapshot()
    local oldLayoutX, oldLayoutY, oldW, oldH = self:_layoutSnapshot()
    assert(type(width) == "number" and width > 0, "width must be greater than zero")
    assert(type(height) == "number" and height > 0, "height must be greater than zero")
    if self.isFloating then
        assert(self.titleBarHeight < height, "title bar height must be smaller than the window")
    end
    width, height = self:_clampWindowSize(width, height)
    self.w, self.h = width, height
    self.windowWidth, self.windowHeight = width, height
    self.preferredW, self.preferredH = width, height
    self:limitScroll()
    self:_emitChanges(oldX, oldY, oldZoom, "size")
    self:_emitLayoutChanges(oldLayoutX, oldLayoutY, oldW, oldH, "size")
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
    assert(self.maxWindowHeight == nil or height < self.maxWindowHeight,
        "title bar height must be smaller than maxHeight")
    self.titleBarHeight = height
    if self.minWindowHeight <= height then self.minWindowHeight = height + 1 end
    if draggable ~= nil then self.isDraggable = not not draggable end
    self:limitScroll()
    self:_emitChanges(oldX, oldY, oldZoom, "title-bar")
    return self
end

function WindowManager:setDraggable(enabled)
    self.isDraggable = not not enabled
    return self
end

function WindowManager:setSizeLimits(minWidth, minHeight, maxWidth, maxHeight)
    assert(type(minWidth) == "number" and minWidth > 0,
        "minWidth must be greater than zero")
    assert(type(minHeight) == "number" and minHeight > 0,
        "minHeight must be greater than zero")
    assert(maxWidth == nil or (type(maxWidth) == "number" and maxWidth >= minWidth),
        "maxWidth must be nil or greater than or equal to minWidth")
    assert(maxHeight == nil or (type(maxHeight) == "number" and maxHeight >= minHeight),
        "maxHeight must be nil or greater than or equal to minHeight")
    assert(maxHeight == nil or maxHeight > self.titleBarHeight,
        "maxHeight must be greater than the title bar height")

    self.minWindowWidth, self.minWindowHeight = minWidth, minHeight
    self.maxWindowWidth, self.maxWindowHeight = maxWidth, maxHeight
    self.sizeLimitsEnabled = true
    if self.isFloating then self:setSize(self.w, self.h) end
    return self
end

function WindowManager:setResizable(enabled, options)
    options = options or {}
    assert(type(options) == "table", "resize options must be a table")
    if options.border ~= nil then
        assert(type(options.border) == "number" and options.border > 0,
            "resize border must be greater than zero")
        self.resizeBorder = options.border
    end

    if enabled or next(options) ~= nil then
        local minWidth = options.minWidth or self.minWindowWidth
        local minHeight = options.minHeight or self.minWindowHeight
        local maxWidth = options.maxWidth
        local maxHeight = options.maxHeight
        if options.maxWidth == nil then maxWidth = self.maxWindowWidth end
        if options.maxHeight == nil then maxHeight = self.maxWindowHeight end
        self:setSizeLimits(minWidth, minHeight, maxWidth, maxHeight)
    end
    self.isResizable = not not enabled
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

function WindowManager:setInputOptions(options)
    options = options or {}
    assert(type(options) == "table", "input options must be a table")

    local booleans = {
        wheel = "wheelScroll",
        keyboard = "keyboardScroll",
        touch = "touchScroll",
        pinchZoom = "pinchToZoom",
        horizontal = "horizontalScroll",
        vertical = "verticalScroll",
        shiftWheelHorizontal = "shiftWheelHorizontal"
    }
    for optionName, fieldName in pairs(booleans) do
        if options[optionName] ~= nil then self[fieldName] = not not options[optionName] end
    end

    if options.zoomModifier ~= nil then
        assert(options.zoomModifier == "ctrl" or options.zoomModifier == "alt"
            or options.zoomModifier == "shift" or options.zoomModifier == "meta"
            or options.zoomModifier == "none",
            "zoomModifier must be 'ctrl', 'alt', 'shift', 'meta' or 'none'")
        self.zoomModifier = options.zoomModifier
    end
    if options.zoomStep ~= nil then
        assert(type(options.zoomStep) == "number" and options.zoomStep > 0,
            "zoomStep must be greater than zero")
        self.zoomStep = options.zoomStep
    end
    return self
end

function WindowManager:setInertia(options)
    if type(options) == "boolean" then options = { enabled = options } end
    options = options or {}
    assert(type(options) == "table", "inertia options must be a table or boolean")
    if options.enabled ~= nil then self.inertiaEnabled = not not options.enabled end
    if options.friction ~= nil then
        assert(type(options.friction) == "number" and options.friction > 0,
            "inertia friction must be greater than zero")
        self.inertiaFriction = options.friction
    end
    if options.minVelocity ~= nil then
        assert(type(options.minVelocity) == "number" and options.minVelocity >= 0,
            "inertia minVelocity must be non-negative")
        self.inertiaMinVelocity = options.minVelocity
    end
    if options.maxPause ~= nil then
        assert(type(options.maxPause) == "number" and options.maxPause >= 0,
            "inertia maxPause must be non-negative")
        self.inertiaMaxPause = options.maxPause
    end
    if not self.inertiaEnabled then
        self.velocityX, self.velocityY = 0, 0
    end
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
    assert(callbacks.onMove == nil or type(callbacks.onMove) == "function",
        "onMove must be a function")
    assert(callbacks.onResize == nil or type(callbacks.onResize) == "function",
        "onResize must be a function")
    assert(callbacks.onNavigationComplete == nil
        or type(callbacks.onNavigationComplete) == "function",
        "onNavigationComplete must be a function")
    if callbacks.onScroll ~= nil then self.onScroll = callbacks.onScroll end
    if callbacks.onZoom ~= nil then self.onZoom = callbacks.onZoom end
    if callbacks.onMove ~= nil then self.onMove = callbacks.onMove end
    if callbacks.onResize ~= nil then self.onResize = callbacks.onResize end
    if callbacks.onNavigationComplete ~= nil then
        self.onNavigationComplete = callbacks.onNavigationComplete
    end
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

function WindowManager:setOnMove(callback)
    assert(callback == nil or type(callback) == "function", "callback must be a function or nil")
    self.onMove = callback
    return self
end

function WindowManager:setOnResize(callback)
    assert(callback == nil or type(callback) == "function", "callback must be a function or nil")
    self.onResize = callback
    return self
end

function WindowManager:setOnNavigationComplete(callback)
    assert(callback == nil or type(callback) == "function", "callback must be a function or nil")
    self.onNavigationComplete = callback
    return self
end

function WindowManager:setScrollbarOptions(options)
    options = options or {}
    assert(type(options) == "table", "scrollbar options must be a table")

    if options.visible ~= nil then self.showScrollbar = not not options.visible end
    if options.horizontal ~= nil then
        self.showHorizontalScrollbar = not not options.horizontal
    end
    if options.vertical ~= nil then self.showVerticalScrollbar = not not options.vertical end
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
    if options.onMove ~= nil then self:setOnMove(options.onMove) end
    if options.onResize ~= nil then self:setOnResize(options.onResize) end
    if options.onNavigationComplete ~= nil then
        self:setOnNavigationComplete(options.onNavigationComplete)
    end

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
    if options.minWidth ~= nil or options.minHeight ~= nil
       or options.maxWidth ~= nil or options.maxHeight ~= nil then
        self:setSizeLimits(options.minWidth or self.minWindowWidth,
            options.minHeight or self.minWindowHeight,
            options.maxWidth or self.maxWindowWidth,
            options.maxHeight or self.maxWindowHeight)
    end
    if options.dragToScroll ~= nil then self:setDragToScroll(options.dragToScroll) end
    if options.alignSmallContent ~= nil then self:setAlignSmallContent(options.alignSmallContent) end
    if options.scrollSpeed ~= nil then self:setScrollSpeed(options.scrollSpeed) end
    if options.input then self:setInputOptions(options.input) end
    if options.inertia ~= nil then self:setInertia(options.inertia) end
    if options.resizable ~= nil or options.resize then
        self:setResizable(options.resizable ~= false, options.resize)
    end
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

function WindowManager:_modifierDown(modifier)
    if modifier == "none" then return true end
    local keys = {
        ctrl = {"lctrl", "rctrl"},
        alt = {"lalt", "ralt"},
        shift = {"lshift", "rshift"},
        meta = {"lgui", "rgui"}
    }
    local pair = keys[modifier]
    return pair and (love.keyboard.isDown(pair[1]) or love.keyboard.isDown(pair[2])) or false
end

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

    if self:_modifierDown(self.zoomModifier) then
        self:setZoom(self.zoom + wy * self.zoomStep, mx, my, "wheel-zoom")
    else
        if not self.wheelScroll then return false end
        self:_stopMotion()
        if self.shiftWheelHorizontal and self.zoomModifier ~= "shift"
           and self:_modifierDown("shift") and wx == 0 then
            wx, wy = wy, 0
        end
        local oldX, oldY, oldZoom = self:_snapshot()
        if self.horizontalScroll then
            self.scrollX = self.scrollX - wx * self.scrollSpeed / self.zoom
        end
        if self.verticalScroll then
            self.scrollY = self.scrollY - wy * self.scrollSpeed / self.zoom
        end
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

    self:_stopMotion()
    local resizeEdges = self:_getResizeEdges(mx, my)
    if resizeEdges then
        self.isResizingWindow = true
        self.resizeEdges = resizeEdges
        self.resizeStartMouseX, self.resizeStartMouseY = mx, my
        self.resizeStartX, self.resizeStartY = self.x, self.y
        self.resizeStartW, self.resizeStartH = self.w, self.h
        return true
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

    if self.verticalScroll and self.showScrollbar and self.showVerticalScrollbar
       and self.verticalScrollbarHeight > 0 then
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

    if self.horizontalScroll and self.showScrollbar and self.showHorizontalScrollbar
       and self.horizontalScrollbarWidthScaled > 0 then
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
    self.lastDragTime = inputTime()

    self:_showScrollbars()

    return true
end

function WindowManager:mousereleased(mx, my, button)
    if button ~= 1 then
        return false
    end

    local wasDraggingContent = self.isDraggingContent
    local wasDragging = (self.isDraggingWindow or self.isResizingWindow
                         or self.isDraggingVertical or self.isDraggingHorizontal
                         or self.isDraggingContent)
    if not wasDragging then
        return false
    end

    -- Reset flags
    self.isDraggingWindow = false
    self.isResizingWindow = false
    self.resizeEdges = nil
    self.isDraggingVertical = false
    self.isDraggingHorizontal = false
    self.isDraggingContent = false
    if wasDraggingContent and self.lastDragTime
       and inputTime() - self.lastDragTime > self.inertiaMaxPause then
        self.velocityX, self.velocityY = 0, 0
    end
    self.lastDragTime = nil
    if not self.inertiaEnabled then self.velocityX, self.velocityY = 0, 0 end
    self:_showScrollbars()

    return true
end

------------------------------------------------------------------------------
--                            mousemoved                                     --
------------------------------------------------------------------------------

function WindowManager:mousemoved(mx, my, dx, dy)
    local inside = self:isPointInsideWindow(mx, my)
    local dragging = (self.isDraggingWindow or self.isResizingWindow
                      or self.isDraggingVertical or self.isDraggingHorizontal
                      or self.isDraggingContent)

    if (not inside) and (not dragging) then
        self.hoveredScrollbar = nil
        return false
    end

    if not dragging and self.showScrollbar then
        local localX, localY = mx - self.x, my - self.y
        local offsetTop = self.isFloating and self.titleBarHeight or 0
        if self.showVerticalScrollbar and self.verticalScrollbarHeight > 0
           and localX >= self.w - self.scrollbarWidth and localX <= self.w
           and localY >= offsetTop and localY <= self.h then
            self.hoveredScrollbar = "vertical"
            self:_showScrollbars()
        elseif self.showHorizontalScrollbar and self.horizontalScrollbarWidthScaled > 0
           and localY >= self.h - self.scrollbarWidth and localY <= self.h
           and localX >= 0 and localX <= self.w then
            self.hoveredScrollbar = "horizontal"
            self:_showScrollbars()
        else
            self.hoveredScrollbar = nil
        end
    end

    if self.isResizingWindow then
        local oldX, oldY, oldW, oldH = self:_layoutSnapshot()
        local deltaX = mx - self.resizeStartMouseX
        local deltaY = my - self.resizeStartMouseY
        local left, top = self.resizeStartX, self.resizeStartY
        local right = self.resizeStartX + self.resizeStartW
        local bottom = self.resizeStartY + self.resizeStartH
        local minW, minH, maxW, maxH = self:_windowSizeLimits()
        local screenW, screenH = love.graphics.getDimensions()

        if self.resizeEdges:find("w", 1, true) then
            left = clamp(self.resizeStartX + deltaX,
                math.max(0, right - maxW), right - minW)
        elseif self.resizeEdges:find("e", 1, true) then
            right = clamp(right + deltaX, left + minW,
                math.min(screenW, left + maxW))
        end
        if self.resizeEdges:find("n", 1, true) then
            top = clamp(self.resizeStartY + deltaY,
                math.max(0, bottom - maxH), bottom - minH)
        elseif self.resizeEdges:find("s", 1, true) then
            bottom = clamp(bottom + deltaY, top + minH,
                math.min(screenH, top + maxH))
        end

        self.x, self.y, self.w, self.h = left, top, right - left, bottom - top
        self.windowWidth, self.windowHeight = self.w, self.h
        self.preferredW, self.preferredH = self.w, self.h
        local oldScrollX, oldScrollY, oldZoom = self:_snapshot()
        self:limitScroll()
        self:_showScrollbars()
        self:_emitChanges(oldScrollX, oldScrollY, oldZoom, "window-resize")
        self:_emitLayoutChanges(oldX, oldY, oldW, oldH, "window-resize")
        return true
    end

    -- Dragging the window?
    if self.isDraggingWindow then
        local oldX, oldY, oldW, oldH = self:_layoutSnapshot()
        self.x = mx - self.windowDragOffsetX
        self.y = my - self.windowDragOffsetY

        -- Prevent the window from going off-screen
        local sw, sh = love.graphics.getDimensions()
        self.x = math.max(0, math.min(self.x, math.max(0, sw - self.w)))
        self.y = math.max(0, math.min(self.y, math.max(0, sh - self.h)))

        self:_emitLayoutChanges(oldX, oldY, oldW, oldH, "window-drag")
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

        if self.horizontalScroll then
            self.scrollX = self.dragOrigScrollX - (diffX / self.zoom)
        end
        if self.verticalScroll then
            self.scrollY = self.dragOrigScrollY - (diffY / self.zoom)
        end
        local now = inputTime()
        local elapsed = now - (self.lastDragTime or now)
        if self.inertiaEnabled and elapsed > 1e-4 then
            local factor = math.min(1, elapsed * 18)
            if self.horizontalScroll then
                local sampleX = -dx / self.zoom / elapsed
                self.velocityX = self.velocityX + (sampleX - self.velocityX) * factor
            end
            if self.verticalScroll then
                local sampleY = -dy / self.zoom / elapsed
                self.velocityY = self.velocityY + (sampleY - self.velocityY) * factor
            end
        end
        self.lastDragTime = now
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

function WindowManager:_contentTouches()
    local result = {}
    for id, touch in pairs(self.activeTouches or {}) do
        if touch.content then result[#result + 1] = { id = id, touch = touch } end
    end
    return result
end

function WindowManager:_startPinchIfPossible()
    if not self.pinchToZoom then return end
    local touches = self:_contentTouches()
    if #touches < 2 then return end
    local first, second = touches[1], touches[2]
    local dx = second.touch.x - first.touch.x
    local dy = second.touch.y - first.touch.y
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance <= 0 then return end
    local middleX = (first.touch.x + second.touch.x) / 2
    local middleY = (first.touch.y + second.touch.y) / 2
    local contentX, contentY = self:screenToContent(middleX, middleY)
    self.pinch = {
        first = first.id,
        second = second.id,
        distance = distance,
        zoom = self.zoom,
        contentX = contentX,
        contentY = contentY
    }
    self.velocityX, self.velocityY = 0, 0
end

function WindowManager:touchpressed(id, tx, ty, dx, dy, pressure)
    if not self:isPointInsideWindow(tx, ty) then
        return false
    end
    self.activeTouches = self.activeTouches or {}
    local offsetTop = self.isFloating and self.titleBarHeight or 0
    self.activeTouches[id] = {
        x = tx,
        y = ty,
        content = (ty - self.y) >= offsetTop and self.touchScroll and self.dragToScroll
    }
    self:_stopMotion()
    self.lastDragTime = inputTime()
    self:_startPinchIfPossible()
    self:_showScrollbars()
    return true
end

function WindowManager:touchmoved(id, tx, ty, dx, dy, pressure)
    if not self.activeTouches or not self.activeTouches[id] then
        return false
    end
    local touch = self.activeTouches[id]
    touch.x, touch.y = tx, ty
    if not touch.content then
        return true
    end


    if self.pinch and (id == self.pinch.first or id == self.pinch.second) then
        local first = self.activeTouches[self.pinch.first]
        local second = self.activeTouches[self.pinch.second]
        if first and second then
            local oldX, oldY, oldZoom = self:_snapshot()
            local distanceX, distanceY = second.x - first.x, second.y - first.y
            local distance = math.sqrt(distanceX * distanceX + distanceY * distanceY)
            local middleX, middleY = (first.x + second.x) / 2, (first.y + second.y) / 2
            local targetZoom = clamp(self.pinch.zoom * distance / self.pinch.distance,
                self.minZoom, self.maxZoom)
            local offsetTop = self.isFloating and self.titleBarHeight or 0
            self.zoom = targetZoom
            if self.horizontalScroll then
                self.scrollX = self.pinch.contentX - ((middleX - self.x) / targetZoom)
            end
            if self.verticalScroll then
                self.scrollY = self.pinch.contentY
                    - ((middleY - self.y - offsetTop) / targetZoom)
            end
            self:limitScroll()
            self:_showScrollbars()
            self:_emitChanges(oldX, oldY, oldZoom, "pinch")
        end
        return true
    end

    local oldX, oldY, oldZoom = self:_snapshot()
    local ddx = dx / self.zoom
    local ddy = dy / self.zoom
    if self.horizontalScroll then self.scrollX = self.scrollX - ddx end
    if self.verticalScroll then self.scrollY = self.scrollY - ddy end

    local now = inputTime()
    local elapsed = now - (self.lastDragTime or now)
    if self.inertiaEnabled and elapsed > 1e-4 then
        local factor = math.min(1, elapsed * 18)
        if self.horizontalScroll then
            local sampleX = -dx / self.zoom / elapsed
            self.velocityX = self.velocityX + (sampleX - self.velocityX) * factor
        end
        if self.verticalScroll then
            local sampleY = -dy / self.zoom / elapsed
            self.velocityY = self.velocityY + (sampleY - self.velocityY) * factor
        end
    end
    self.lastDragTime = now
    self:limitScroll()
    self:_showScrollbars()
    self:_emitChanges(oldX, oldY, oldZoom, "touch-drag")
    return true
end

function WindowManager:touchreleased(id, tx, ty, dx, dy, pressure)
    if not self.activeTouches or not self.activeTouches[id] then
        return false
    end
    self.activeTouches[id] = nil
    if self.pinch and (id == self.pinch.first or id == self.pinch.second) then
        self.pinch = nil
        self:_startPinchIfPossible()
    end
    if not next(self.activeTouches) then
        if self.lastDragTime and inputTime() - self.lastDragTime > self.inertiaMaxPause then
            self.velocityX, self.velocityY = 0, 0
        end
        self.lastDragTime = nil
    end
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
    if self.showVerticalScrollbar and contentHZoomed > visibleH
       and self.verticalScrollbarHeight > 0 then
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
    if self.showHorizontalScrollbar and contentWZoomed > self.w
       and self.horizontalScrollbarWidthScaled > 0 then
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

function WindowManager:_scrollLimitsFor(zoom, forceAlign)
    zoom = zoom or self.zoom
    local offsetTop = self.isFloating and self.titleBarHeight or 0
    local visibleH = self.h - offsetTop

    local visibleWInContent = self.w / zoom
    local visibleHInContent = visibleH / zoom
    local maxScrollX = self.contentWidth - visibleWInContent
    local maxScrollY = self.contentHeight - visibleHInContent
    local alignX = (forceAlign or self.alignSmallContent)
    local alignY = (forceAlign or self.alignSmallContent)

    local minX, minY = 0, 0
    if maxScrollX < 0 then
        minX, maxScrollX = alignX and maxScrollX / 2 or 0,
            alignX and maxScrollX / 2 or 0
    end
    if maxScrollY < 0 then
        minY, maxScrollY = alignY and maxScrollY / 2 or 0,
            alignY and maxScrollY / 2 or 0
    end
    return minX, maxScrollX, minY, maxScrollY
end

function WindowManager:getScrollLimits()
    return self:_scrollLimitsFor(self.zoom, false)
end

function WindowManager:_clampScrollValues(x, y, zoom, forceAlign)
    local minX, maxX, minY, maxY = self:_scrollLimitsFor(zoom, forceAlign)
    return clamp(x, minX, maxX), clamp(y, minY, maxY)
end

function WindowManager:limitScroll(forceAlign)
    self.scrollX, self.scrollY = self:_clampScrollValues(
        self.scrollX, self.scrollY, self.zoom, forceAlign)

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

function WindowManager:getViewportSize(zoom)
    zoom = zoom or self.zoom
    assert(type(zoom) == "number" and zoom > 0, "zoom must be greater than zero")
    local offsetTop = self.isFloating and self.titleBarHeight or 0
    return self.w / zoom, (self.h - offsetTop) / zoom
end

function WindowManager:getVisibleBounds()
    local visibleW, visibleH = self:getViewportSize()
    return self.scrollX, self.scrollY,
        self.scrollX + visibleW, self.scrollY + visibleH
end

function WindowManager:contentToScreen(contentX, contentY)
    assert(type(contentX) == "number" and type(contentY) == "number",
        "contentX and contentY must be numbers")
    local offsetTop = self.isFloating and self.titleBarHeight or 0
    return self.x + (contentX - self.scrollX) * self.zoom,
        self.y + offsetTop + (contentY - self.scrollY) * self.zoom
end

function WindowManager:isContentRectVisible(x, y, width, height, fully)
    assert(type(x) == "number" and type(y) == "number", "x and y must be numbers")
    assert(type(width) == "number" and width >= 0,
        "width must be a non-negative number")
    assert(type(height) == "number" and height >= 0,
        "height must be a non-negative number")
    local left, top, right, bottom = self:getVisibleBounds()
    if fully then
        return x >= left and y >= top and x + width <= right and y + height <= bottom
    end
    return x + width >= left and y + height >= top and x <= right and y <= bottom
end

function WindowManager:_navigate(targetX, targetY, targetZoom, options, defaultReason)
    options = options or {}
    if type(options) == "number" then options = { duration = options } end
    assert(type(options) == "table", "navigation options must be a table or duration")
    local duration = options.duration or 0
    assert(type(duration) == "number" and duration >= 0,
        "navigation duration must be non-negative")
    targetZoom = clamp(targetZoom or self.zoom, self.minZoom, self.maxZoom)
    targetX, targetY = self:_clampScrollValues(
        targetX or self.scrollX, targetY or self.scrollY, targetZoom, false)
    local reason = options.reason or defaultReason or "navigation"

    self.velocityX, self.velocityY = 0, 0
    if duration == 0 then
        local oldX, oldY, oldZoom = self:_snapshot()
        self.navigation = nil
        self.scrollX, self.scrollY, self.zoom = targetX, targetY, targetZoom
        self:updateScrollbars()
        self:_showScrollbars()
        self:_emitChanges(oldX, oldY, oldZoom, reason)
        return self
    end

    self.navigation = {
        elapsed = 0,
        duration = duration,
        easing = resolveEasing(options.easing),
        startX = self.scrollX,
        startY = self.scrollY,
        startZoom = self.zoom,
        targetX = targetX,
        targetY = targetY,
        targetZoom = targetZoom,
        reason = reason
    }
    self:_showScrollbars()
    return self
end

function WindowManager:scrollTo(x, y, options)
    assert(type(x) == "number" and type(y) == "number", "x and y must be numbers")
    return self:_navigate(x, y, self.zoom, options, "scroll-to")
end

function WindowManager:scrollBy(dx, dy, options)
    assert(type(dx) == "number" and type(dy) == "number", "dx and dy must be numbers")
    return self:scrollTo(self.scrollX + dx, self.scrollY + dy, options)
end

function WindowManager:zoomTo(zoom, anchorX, anchorY, options)
    assert(type(zoom) == "number", "zoom must be a number")
    if type(anchorX) == "table" then
        options, anchorX, anchorY = anchorX, nil, nil
    end
    assert((anchorX == nil and anchorY == nil)
        or (type(anchorX) == "number" and type(anchorY) == "number"),
        "anchorX and anchorY must both be numbers")

    local targetZoom = clamp(zoom, self.minZoom, self.maxZoom)
    local targetX, targetY = self.scrollX, self.scrollY
    if anchorX ~= nil then
        local contentX, contentY = self:screenToContent(anchorX, anchorY)
        local offsetTop = self.isFloating and self.titleBarHeight or 0
        targetX = contentX - (anchorX - self.x) / targetZoom
        targetY = contentY - (anchorY - self.y - offsetTop) / targetZoom
    end
    return self:_navigate(targetX, targetY, targetZoom, options, "zoom-to")
end

function WindowManager:centerOn(contentX, contentY, options)
    assert(type(contentX) == "number" and type(contentY) == "number",
        "contentX and contentY must be numbers")
    local visibleW, visibleH = self:getViewportSize()
    return self:scrollTo(contentX - visibleW / 2, contentY - visibleH / 2, options)
end

function WindowManager:ensureVisible(x, y, width, height, options)
    assert(type(x) == "number" and type(y) == "number", "x and y must be numbers")
    assert(type(width) == "number" and width >= 0,
        "width must be a non-negative number")
    assert(type(height) == "number" and height >= 0,
        "height must be a non-negative number")
    options = options or {}
    if type(options) == "number" then options = { padding = options } end
    assert(type(options) == "table", "ensureVisible options must be a table or padding")
    local padding = options.padding or 0
    assert(type(padding) == "number" and padding >= 0, "padding must be non-negative")

    local visibleW, visibleH = self:getViewportSize()
    local availableW, availableH = math.max(0, visibleW - padding * 2),
        math.max(0, visibleH - padding * 2)
    local targetX, targetY = self.scrollX, self.scrollY
    if width > availableW then
        targetX = x + width / 2 - visibleW / 2
    elseif x < targetX + padding then
        targetX = x - padding
    elseif x + width > targetX + visibleW - padding then
        targetX = x + width - visibleW + padding
    end
    if height > availableH then
        targetY = y + height / 2 - visibleH / 2
    elseif y < targetY + padding then
        targetY = y - padding
    elseif y + height > targetY + visibleH - padding then
        targetY = y + height - visibleH + padding
    end

    local navigationOptions = {
        duration = options.duration,
        easing = options.easing,
        reason = options.reason or "ensure-visible"
    }
    return self:scrollTo(targetX, targetY, navigationOptions)
end

function WindowManager:isNavigating()
    return self.navigation ~= nil
end

function WindowManager:cancelNavigation()
    local wasNavigating = self.navigation ~= nil
    self.navigation = nil
    return wasNavigating
end

function WindowManager:setZoom(z, anchorX, anchorY, reason)
    assert(type(z) == "number", "zoom must be a number")
    assert((anchorX == nil and anchorY == nil)
        or (type(anchorX) == "number" and type(anchorY) == "number"),
        "anchorX and anchorY must both be numbers")

    self:_stopMotion()
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
        version = WindowManager.VERSION,
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
    self:_stopMotion()
    local oldX, oldY, oldZoom = self:_snapshot()
    local oldLayoutX, oldLayoutY, oldW, oldH = self:_layoutSnapshot()
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
    self.w, self.h = self:_clampWindowSize(self.w, self.h)
    self.windowWidth, self.windowHeight = self.w, self.h
    self.preferredW, self.preferredH = self.w, self.h
    self:limitScroll(true)
    self:_showScrollbars()
    self:_emitChanges(oldX, oldY, oldZoom, "state")
    self:_emitLayoutChanges(oldLayoutX, oldLayoutY, oldW, oldH, "state")
    return self
end

function WindowManager:_updateNavigation(dt)
    local navigation = self.navigation
    if not navigation then return false end
    local oldX, oldY, oldZoom = self:_snapshot()
    navigation.elapsed = math.min(navigation.duration, navigation.elapsed + dt)
    local progress = navigation.duration == 0 and 1
        or navigation.elapsed / navigation.duration
    local eased = clamp(navigation.easing(progress), 0, 1)
    self.zoom = navigation.startZoom
        + (navigation.targetZoom - navigation.startZoom) * eased
    self.scrollX = navigation.startX + (navigation.targetX - navigation.startX) * eased
    self.scrollY = navigation.startY + (navigation.targetY - navigation.startY) * eased
    self:limitScroll()
    self:_showScrollbars()
    self:_emitChanges(oldX, oldY, oldZoom, navigation.reason)

    if progress >= 1 then
        self.scrollX, self.scrollY, self.zoom = navigation.targetX,
            navigation.targetY, navigation.targetZoom
        self:limitScroll()
        self.navigation = nil
        if self.onNavigationComplete and not self._suppressCallbacks then
            self.onNavigationComplete(self, navigation.reason)
        end
    end
    return true
end

function WindowManager:_updateInertia(dt)
    if not self.inertiaEnabled or self.navigation or self.isDraggingContent
       or self.isDraggingVertical or self.isDraggingHorizontal
       or self.pinch or next(self.activeTouches or {}) then
        return false
    end
    if math.abs(self.velocityX) < self.inertiaMinVelocity then self.velocityX = 0 end
    if math.abs(self.velocityY) < self.inertiaMinVelocity then self.velocityY = 0 end
    if self.velocityX == 0 and self.velocityY == 0 then return false end

    local oldX, oldY, oldZoom = self:_snapshot()
    local step = math.min(dt, 0.05)
    self.scrollX = self.scrollX + self.velocityX * step
    self.scrollY = self.scrollY + self.velocityY * step
    self:limitScroll()
    if changed(oldX, self.scrollX) == false then self.velocityX = 0 end
    if changed(oldY, self.scrollY) == false then self.velocityY = 0 end
    local damping = math.exp(-self.inertiaFriction * step)
    self.velocityX, self.velocityY = self.velocityX * damping, self.velocityY * damping
    self:_showScrollbars()
    self:_emitChanges(oldX, oldY, oldZoom, "inertia")
    return true
end

function WindowManager:update(dt)
    assert(type(dt) == "number" and dt >= 0, "dt must be a non-negative number")
    self:_updateNavigation(dt)
    self:_updateInertia(dt)

    if not self.showScrollbar or not self.scrollbarAutoHide then
        self.scrollbarAlpha = 1
        return
    end
    if self.isDraggingVertical or self.isDraggingHorizontal or self.isDraggingContent
       or self.isResizingWindow or self.hoveredScrollbar or self.navigation
       or self.velocityX ~= 0 or self.velocityY ~= 0 then
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
    local oldLayoutX, oldLayoutY, oldW, oldH = self:_layoutSnapshot()
    self.w, self.h = w, h
    self.windowWidth, self.windowHeight = w, h
    self.preferredW, self.preferredH = w, h
    self:limitScroll()
    self:_emitChanges(oldX, oldY, oldZoom, "resize")
    self:_emitLayoutChanges(oldLayoutX, oldLayoutY, oldW, oldH, "resize")
    return true
end

function WindowManager:constrainToScreen(screenWidth, screenHeight, shrink)
    assert(type(screenWidth) == "number" and screenWidth > 0,
        "screenWidth must be greater than zero")
    assert(type(screenHeight) == "number" and screenHeight > 0,
        "screenHeight must be greater than zero")
    if not self.isFloating then return false end

    local oldX, oldY, oldZoom = self:_snapshot()
    local oldLayoutX, oldLayoutY, oldW, oldH = self:_layoutSnapshot()
    if shrink then
        self.w = math.min(self.preferredW, screenWidth)
        self.h = math.min(self.preferredH, screenHeight)
        self.w, self.h = self:_clampWindowSize(self.w, self.h)
        self.w, self.h = math.min(self.w, screenWidth), math.min(self.h, screenHeight)
        self.windowWidth, self.windowHeight = self.w, self.h
    end
    self.x = math.max(0, math.min(self.x, math.max(0, screenWidth - self.w)))
    self.y = math.max(0, math.min(self.y, math.max(0, screenHeight - self.h)))
    self:limitScroll()
    self:_emitChanges(oldX, oldY, oldZoom, "screen-constraint")
    self:_emitLayoutChanges(oldLayoutX, oldLayoutY, oldW, oldH, "screen-constraint")
    return true
end

function WindowManager:cancelInput()
    self.isDraggingWindow = false
    self.isResizingWindow = false
    self.resizeEdges = nil
    self.isDraggingVertical = false
    self.isDraggingHorizontal = false
    self.isDraggingContent = false
    self.activeTouches = {}
    self.pinch = nil
    self.lastDragTime = nil
    self.velocityX, self.velocityY = 0, 0
    self.hoveredScrollbar = nil
end

function WindowManager:keypressed(key)
    -- Step-based scrolling
    if not self.keyboardScroll then return false end
    local oldX, oldY, oldZoom = self:_snapshot()
    if key == "up" then
        if not self.verticalScroll then return false end
        self.scrollY = self.scrollY - self.scrollSpeed / self.zoom
    elseif key == "down" then
        if not self.verticalScroll then return false end
        self.scrollY = self.scrollY + self.scrollSpeed / self.zoom
    elseif key == "left" then
        if not self.horizontalScroll then return false end
        self.scrollX = self.scrollX - self.scrollSpeed / self.zoom
    elseif key == "right" then
        if not self.horizontalScroll then return false end
        self.scrollX = self.scrollX + self.scrollSpeed / self.zoom
    elseif key == "=" or key == "+" then
        self:zoomIn(self.zoomStep)
        return true
    elseif key == "-" then
        self:zoomOut(self.zoomStep)
        return true
    else
        return false
    end
    self:_stopMotion()
    self:limitScroll()
    self:_showScrollbars()
    self:_emitChanges(oldX, oldY, oldZoom, "keyboard")
    return true
end

return WindowManager
