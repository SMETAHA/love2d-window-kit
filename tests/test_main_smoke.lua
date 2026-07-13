package.path = "./?.lua;" .. package.path

local width, height = 1024, 768
local mouseX, mouseY = 0, 0
local stackDepth = 0

love = {
    graphics = {
        getWidth = function() return width end,
        getHeight = function() return height end,
        getDimensions = function() return width, height end,
        push = function() stackDepth = stackDepth + 1 end,
        pop = function() stackDepth = stackDepth - 1 end,
        setScissor = function() end,
        translate = function() end,
        scale = function() end,
        setColor = function() end,
        rectangle = function() end,
        print = function() end,
        line = function() end
    },
    window = {
        setMode = function(w, h)
            width, height = w, h
            return true
        end,
        setTitle = function() end
    },
    mouse = {
        getPosition = function() return mouseX, mouseY end
    },
    keyboard = {
        isDown = function() return false end
    },
    event = {
        quit = function() end
    }
}

dofile("main.lua")

love.load()
love.update(0.016)
love.draw()
assert(stackDepth == 0, "main draw must leave the graphics stack balanced")

love.mousepressed(150, 150, 1, false, 1)
love.mousemoved(900, 700, 750, 550, false)
love.mousereleased(900, 700, 1, false, 1)

mouseX, mouseY = 200, 200
love.wheelmoved(0, -1)
love.touchpressed("one", 200, 200, 0, 0, 1)
love.touchmoved("one", 210, 205, 10, 5, 1)
love.touchreleased("one", 210, 205, 0, 0, 1)

love.keypressed("right", "right", false)
love.keypressed("s", "s", false)
love.keypressed("l", "l", false)
love.keyreleased("l", "l")
love.textinput("A")
love.textedited("A", 0, 1)
love.focus(false)
love.resize(1280, 720)
love.draw()
assert(stackDepth == 0, "resized draw must leave the graphics stack balanced")

print("main.lua smoke test passed")
