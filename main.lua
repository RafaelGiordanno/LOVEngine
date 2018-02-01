local Terebi = require("terebi")
local screen = nil

local GAME_WIDTH = 16 * 20
local GAME_HEIGHT = 9 * 20

function love.load(arg)
    for k, v in ipairs(arg) do
		-- mute music
		if (v == '-debug') then
            DEBUG = true
        elseif (v == '-editor') then
            -- initialize editor
		end
    end
    love.graphics.setDefaultFilter('nearest', 'nearest')

    screen = Terebi.newScreen(GAME_WIDTH, GAME_HEIGHT, 1):setBackgroundColor(64, 64, 64)
end

function love.update(dt)

end

function love.draw()

end

function love.keypressed(key)

end

function love.keyreleased(key)
    if key == '=' or key == '+' then
        screen:increaseScale()
    end
    if key == '-' then
        screen:decreaseScale()
    end
    if key == 'f11' then
        screen:toggleFullscreen()
    end
end