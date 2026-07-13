function love.conf(t)
    -- Keep the original identity so existing save directories remain compatible.
    t.identity = "window_manager_template"
    t.version = "11.5"
    t.console = false
    t.window.title = "LÖVE Window Kit"
    t.window.width = 1024
    t.window.height = 768
    t.window.resizable = true
    t.window.vsync = 1
    t.window.highdpi = true
    t.window.usedpiscale = true
end
