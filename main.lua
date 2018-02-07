local Terebi = require("terebi")
local lume = require("lume")
local screen = nil

local GAME_WIDTH = 16 * 20
local GAME_HEIGHT = 9 * 20

local GRAVITY = 9.8
local player = {
    pos = { x = 190, y = 24 },
    vel = { x = 0, y = 0 },
    w = 16, 
    h = 16
}

local buttons = {
    right = false,
    left = false
}

-- map is a linked list of points
map = { next = map, x = 16, y = 140 }
map = { next = map, x = 80, y = 140 }
map = { next = map, x = 96, y = 156 }
map = { next = map, x = 140, y = 156 }
map = { next = map, x = 156, y = 160 }
map = { next = map, x = 188, y = 160 }
map = { next = map, x = 200, y = 140 }
map = { next = map, x = 240, y = 140 }

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
    -- apply the default filter
    Terebi.initializeLoveDefaults()
    screen = Terebi.newScreen(GAME_WIDTH, GAME_HEIGHT, 2):setBackgroundColor(64, 64, 64)
end

function love.update(dt)
    -- input handling
    if buttons.right then
        player.vel.x = player.vel.x + 16 * dt
    elseif buttons.left then
        player.vel.x = player.vel.x - 16 * dt
    else
        player.vel.x = lume.lerp(player.vel.x, 0, 0.2)
    end

    player.vel.y = player.vel.y + GRAVITY * dt

    -- checking collisions...
    local node = map
    local nextNode = map.next
    while nextNode do
        local bx = node.x
        local by = node.y
        local ex = nextNode.x
        local ey = nextNode.y

        local px1 = player.pos.x
        local py1 = player.pos.y + player.h + player.vel.y + 0.5
        local px2 = player.pos.x
        local py2 = player.pos.y

        -- checking vertical collision
        local intersect = intersectSegments(px1, py1, px2, py2, bx, by, ex, ey)
        if intersect ~= nil then
            player.vel.y = 0
            if intersect.y > player.pos.y then
                player.pos.y = intersect.y - player.h + 1.5
            end
        end
        -- switching nodes
        node = nextNode
        nextNode = nextNode.next
    end

    player.vel.x = lume.clamp(player.vel.x, -1, 1)
    player.vel.y = lume.clamp(player.vel.y, -4, 4)

    -- updating player's position
    player.pos.x = player.pos.x + player.vel.x
    player.pos.y = player.pos.y + player.vel.y
end

function render()
    love.graphics.clear(12, 23, 77, 255)
    -- the player
    love.graphics.line(player.pos.x, player.pos.y, player.pos.x, player.pos.y + player.h)

    -- the map
    local node = map
    local nextNode = map.next
    while nextNode do
        love.graphics.line(node.x, node.y, nextNode.x, nextNode.y)
        node = nextNode
        nextNode = nextNode.next
    end
    love.graphics.print(love.timer.getFPS(), GAME_WIDTH - 32, GAME_HEIGHT - 32)
end

function love.draw()
    screen:draw(render)
end

function love.keypressed(key)
    if key == "right" or key == "d" then
        buttons.right = true
    elseif key == "left" or key == "a" then
        buttons.left = true
    end
end

function love.keyreleased(key)
    -- support buttons
    if key == '=' or key == '+' then
        screen:increaseScale()
    end
    if key == '-' then
        screen:decreaseScale()
    end
    if key == 'f11' then
        screen:toggleFullscreen()
    end

    -- player buttons
    if key == "right" or key == "d" then
        buttons.right = false
    elseif key == "left" or key == "a" then
        buttons.left = false
    end
    
end

-- math stuff goes here
function intersectSegments (x1, y1, x2, y2, x3, y3, x4, y4)
    local d = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
    if (d == 0) then
        return nil
    end

    local yd = y1 - y3
    local xd = x1 - x3
    local ua = ((x4 - x3) * yd - (y4 - y3) * xd) / d
    if (ua < 0 or ua > 1) then
         return nil
    end

    local ub = ((x2 - x1) * yd - (y2 - y1) * xd) / d
    if (ub < 0 or ub > 1) then
        return nil
    end

    return { x = x1 + (x2 - x1) * ua, y = y1 + (y2 - y1) * ua }
end