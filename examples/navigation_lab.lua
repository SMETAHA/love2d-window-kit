local WindowManager = require("WindowManager")
local WindowStack = require("WindowStack")
local Support = require("examples.support")

local CONTENT_W, CONTENT_H = 4200, 2800
local stack
local viewport
local selected = 1
local status = "Ready"

local landmarks = {
    { x = 420, y = 360, label = "Spawn", color = {0.25, 0.9, 0.65} },
    { x = 2100, y = 740, label = "Station", color = {0.35, 0.75, 1} },
    { x = 3450, y = 2260, label = "Vault", color = {1, 0.55, 0.3} }
}

local function focusLandmark(index)
    selected = index
    local landmark = landmarks[index]
    viewport:centerOn(landmark.x, landmark.y, {
        duration = 0.45,
        easing = "inOutQuad",
        reason = "landmark"
    })
    status = "Moving to " .. landmark.label
end

local function drawContent(scrollX, scrollY, visibleWidth, visibleHeight)
    local left, top = Support.drawGrid(
        scrollX, scrollY, visibleWidth, visibleHeight,
        CONTENT_W, CONTENT_H, 100,
        {0.035, 0.045, 0.065, 1}, {0.11, 0.16, 0.23, 1})

    for index, landmark in ipairs(landmarks) do
        love.graphics.setColor(landmark.color[1], landmark.color[2], landmark.color[3],
            index == selected and 1 or 0.7)
        love.graphics.circle("fill", landmark.x, landmark.y, index == selected and 38 or 28)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(index .. "  " .. landmark.label, landmark.x + 48, landmark.y - 8)
    end

    love.graphics.setColor(0.7, 0.78, 0.9)
    love.graphics.print("Drag and release for inertia. Pinch on touch devices.", left + 18, top + 18)
end

function love.load()
    Support.configure("Example: navigation lab", 1180, 760)
    stack = WindowStack.new()

    local background = WindowManager.new({
        floating = false,
        contentWidth = 1180,
        contentHeight = 760,
        dragToScroll = false,
        scrollbar = { visible = false }
    })
    stack:add(background, {
        id = "background",
        layer = 0,
        focusable = false,
        draw = function(scrollX, scrollY, visibleWidth, visibleHeight)
            love.graphics.setColor(0.018, 0.022, 0.032)
            love.graphics.rectangle("fill", scrollX, scrollY, visibleWidth, visibleHeight)
        end
    })

    viewport = WindowManager.new({
        floating = true,
        x = 70,
        y = 70,
        width = 900,
        height = 560,
        title = "Navigation lab — resize from a corner",
        draggable = true,
        resizable = true,
        resize = {
            border = 10,
            minWidth = 420,
            minHeight = 300
        },
        contentWidth = CONTENT_W,
        contentHeight = CONTENT_H,
        minZoom = 0.35,
        maxZoom = 3,
        inertia = {
            enabled = true,
            friction = 7,
            minVelocity = 18
        },
        input = {
            pinchZoom = true,
            shiftWheelHorizontal = true
        },
        scrollbar = {
            autoHide = true,
            minThumbSize = 30,
            color = {0.3, 0.75, 1, 0.9}
        },
        theme = {
            frameColor = {0.03, 0.04, 0.06, 0.98},
            titleBarColor = {0.08, 0.18, 0.28, 1},
            borderColor = {0.3, 0.75, 1, 1}
        },
        callbacks = {
            onNavigationComplete = function(_, reason)
                status = reason == "landmark" and "Landmark centered" or "Navigation complete"
            end
        }
    })

    stack:add(viewport, {
        id = "map",
        layer = 100,
        shrinkOnResize = true,
        draw = drawContent
    })
    stack:focus(viewport)
    focusLandmark(1)
end

Support.bind(function() return stack end, {
    keypressed = function(key)
        local index = tonumber(key)
        if index and landmarks[index] then
            focusLandmark(index)
            return true
        elseif key == "home" then
            viewport:zoomTo(1, {
                duration = 0.35,
                easing = "outQuad",
                reason = "reset-zoom"
            })
            return true
        elseif key == "f" then
            local landmark = landmarks[selected]
            viewport:ensureVisible(landmark.x - 40, landmark.y - 40, 80, 80, {
                padding = 60,
                duration = 0.3
            })
            return true
        end
        return false
    end,
    draw = function()
        local width, height = love.graphics.getDimensions()
        love.graphics.setColor(0.72, 0.78, 0.9)
        love.graphics.print("[1–3] landmarks   [Home] reset zoom   [F] ensure visible   " .. status,
            18, height - 26)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("zoom %.2f", viewport.zoom), width - 110, 18)
    end
})
