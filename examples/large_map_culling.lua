local WindowManager = require("WindowManager")
local WindowStack = require("WindowStack")
local Support = require("examples.support")

local MAP_W, MAP_H = 20000, 20000
local TILE = 64
local stack
local visibleTiles = 0

local function tileColor(x, y)
    local value = (x * 17 + y * 31) % 11
    if value < 3 then return 0.12, 0.34, 0.22 end
    if value < 6 then return 0.18, 0.28, 0.42 end
    if value < 9 then return 0.38, 0.3, 0.18 end
    return 0.42, 0.18, 0.2
end

function love.load()
    Support.configure("Example: large map culling", 1200, 760)
    stack = WindowStack.new()

    local map = WindowManager.new({
        floating = false,
        contentWidth = MAP_W,
        contentHeight = MAP_H,
        minZoom = 0.2,
        maxZoom = 3,
        scrollbar = { autoHide = true, minThumbSize = 30 }
    })

    stack:add(map, {
        layer = 0,
        raiseOnFocus = false,
        draw = function(scrollX, scrollY, visibleWidth, visibleHeight)
            local left, top, right, bottom = Support.visibleBounds(
                scrollX, scrollY, visibleWidth, visibleHeight, MAP_W, MAP_H)
            local firstColumn = math.max(0, math.floor(left / TILE))
            local lastColumn = math.min(math.ceil(MAP_W / TILE) - 1, math.ceil(right / TILE))
            local firstRow = math.max(0, math.floor(top / TILE))
            local lastRow = math.min(math.ceil(MAP_H / TILE) - 1, math.ceil(bottom / TILE))

            visibleTiles = 0
            for row = firstRow, lastRow do
                for column = firstColumn, lastColumn do
                    local r, g, b = tileColor(column, row)
                    love.graphics.setColor(r, g, b)
                    love.graphics.rectangle("fill",
                        column * TILE, row * TILE, TILE - 1, TILE - 1)
                    visibleTiles = visibleTiles + 1
                end
            end
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("20,000 x 20,000 procedural tile map", left + 20, top + 20)
        end
    })
    stack:focus(map)
end

Support.bind(function() return stack end, {
    draw = function()
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", 12, 12, 230, 32)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Visible tiles drawn: " .. visibleTiles, 22, 21)
    end
})
