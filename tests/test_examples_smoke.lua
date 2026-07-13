local mode = arg[1] or "minimal"
local flags = {
    minimal = "--minimal",
    mobile = "--mobile-test",
    ["fullscreen-canvas"] = "--example=fullscreen-canvas",
    ["floating-inventory"] = "--example=floating-inventory",
    ["multi-window-dashboard"] = "--example=multi-window-dashboard",
    ["themed-scrollbars"] = "--example=themed-scrollbars",
    ["state-callbacks"] = "--example=state-callbacks",
    ["large-map-culling"] = "--example=large-map-culling"
}
assert(flags[mode], "unknown example mode")

package.path = "./?.lua;" .. package.path

local width, height = 1024, 768
local stackDepth = 0
local activeTouches = {}

love = {
    graphics = {
        getWidth = function() return width end,
        getHeight = function() return height end,
        getDimensions = function() return width, height end,
        getDPIScale = function() return 2 end,
        push = function() stackDepth = stackDepth + 1 end,
        pop = function() stackDepth = stackDepth - 1 end,
        setScissor = function() end,
        translate = function() end,
        scale = function() end,
        setColor = function() end,
        rectangle = function() end,
        print = function() end,
        line = function() end,
        circle = function() end
    },
    window = {
        setMode = function(w, h)
            width, height = w, h
            return true
        end,
        setTitle = function() end
    },
    mouse = { getPosition = function() return 100, 100 end },
    keyboard = { isDown = function() return false end },
    touch = {
        getTouches = function() return activeTouches end
    },
    event = { quit = function() end }
}

arg = {flags[mode]}
dofile("main.lua")
love.load()
love.update(0.016)
love.draw()

love.mousepressed(100, 100, 1, false, 1)
love.mousemoved(120, 110, 20, 10, false)
love.mousereleased(120, 110, 1, false, 1)

if mode == "mobile" then
    activeTouches[1] = "touch"
    love.touchpressed("touch", 100, 100, 0, 0, 1)
    love.touchmoved("touch", 110, 105, 10, 5, 1)
    love.touchreleased("touch", 110, 105, 0, 0, 1)
    activeTouches = {}
end

love.resize(600, 900)
love.draw()
assert(stackDepth == 0, "example must leave the graphics stack balanced")

print(mode .. " example smoke test passed")
