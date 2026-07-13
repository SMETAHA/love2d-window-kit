local SystemWindow = {
    VERSION = "1.0.0"
}

function SystemWindow.configure(options)
    options = options or {}
    assert(type(options) == "table", "options must be a table")

    local width = options.width or love.graphics.getWidth()
    local height = options.height or love.graphics.getHeight()
    assert(type(width) == "number" and width > 0, "width must be greater than zero")
    assert(type(height) == "number" and height > 0, "height must be greater than zero")
    if options.vsync ~= nil then
        assert(options.vsync == -1 or options.vsync == 0 or options.vsync == 1,
            "vsync must be -1, 0 or 1")
    end
    if options.fullscreentype ~= nil then
        assert(options.fullscreentype == "desktop" or options.fullscreentype == "exclusive",
            "fullscreentype must be 'desktop' or 'exclusive'")
    end
    assert(options.msaa == nil or (type(options.msaa) == "number" and options.msaa >= 0),
        "msaa must be non-negative")

    local flags = {
        fullscreen = options.fullscreen == true,
        fullscreentype = options.fullscreentype or "desktop",
        vsync = options.vsync == nil and 1 or options.vsync,
        resizable = options.resizable ~= false,
        borderless = options.borderless == true,
        centered = options.centered ~= false,
        highdpi = options.highdpi ~= false,
        usedpiscale = options.usedpiscale ~= false,
        msaa = options.msaa or 0,
        minwidth = options.minwidth or 1,
        minheight = options.minheight or 1
    }

    local success, message = love.window.setMode(width, height, flags)
    if not success then return false, message end

    if options.title then love.window.setTitle(options.title) end
    return true
end

return SystemWindow
