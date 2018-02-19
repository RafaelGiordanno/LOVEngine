local Terebi = require("terebi")
local lume = require("lume")
local Camera = require("camera")
local screen = nil

local GAME_WIDTH = 16 * 20
local GAME_HEIGHT = 9 * 20

local GRAVITY = 9.8
local player = {
    pos = { x = 80, y = 24 },
    vel = { x = 0, y = 0 },
    w = 16, 
    h = 16
}

local buttons = {
    right = false,
    left = false,
    up = false,
    down = false,
    hold = false
}

local stateTime = 0
local spectralRealm = false

-- map is a linked list of points
-- map = { next = map, x = 16, y = 0, xb = 0, yb = 0, xe = 16, ye = 0 }
map = { next = map, x = 16, y = 140, xb = 0, yb = 140, xe = 16, ye = 80 }
map = { next = map, x = 80, y = 140, xb = 0, yb = 140, xe = 80, ye = 80 }
map = { next = map, x = 96, y = 156, xb = 80, yb = 156, xe = 96, ye = 96 }
map = { next = map, x = 140, y = 156, xb = 188, yb = 156, xe = 140, ye = 96 }
map = { next = map, x = 156, y = 160, xb = 188, yb = 160, xe = 156, ye = 100 }
map = { next = map, x = 188, y = 160, xb = 224, yb = 160, xe = 188, ye = 100 }
map = { next = map, x = 200, y = 140, xb = 256, yb = 140, xe = 240, ye = 40 }
map = { next = map, x = 240, y = 140, xb = 296, yb = 140, xe = 280, ye = 40 }

bgRectangles = {
    { x = 110, y = 30, w = 80, h = 80, r = 0.54, rs = 1, xs = 30 },
    { x = 200, y = 110, w = 60, h = 60, r = 0.54, rs = 1, xs = 15 },
    { x = 30, y = 50, w = 30, h = 30, r = 0.54, rs = 1, xs = 50 },
    { x = 160, y = 80, w = 40, h = 40, r = 0.54, rs = 1, xs = 34 },
}

function love.load(arg)
    for k, v in ipairs(arg) do
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
    camera = Camera(player.pos.x, player.pos.y)
    bgCamera = Camera(player.pos.x, player.pos.y)
end

function love.update(dt)
    stateTime = stateTime + dt

    if DEBUG then
        local node = map
        while node do
            if spectralRealm then
                node.x = lume.lerp(node.x, node.xe, 0.4)
                node.y = lume.lerp(node.y, node.ye, 0.4)
            else
                node.x = lume.lerp(node.x, node.xb, 0.4)
                node.y = lume.lerp(node.y, node.yb, 0.4)
            end
            -- switching nodes
            node = node.next
        end
    else
        -- moving walls around...
        local node = map
        while node do
            if spectralRealm then
                node.x = lume.lerp(node.x, node.xe, 0.01)
                node.y = lume.lerp(node.y, node.ye, 0.01)
                if node.y < node.ye + 0.2 and node.y > node.ye - 0.2 then
                    spectralRealm = false
                end
            else
                node.x = lume.lerp(node.x, node.xb, 0.01)
                node.y = lume.lerp(node.y, node.yb, 0.01)
                if node.y < node.yb + 0.2 and node.y > node.yb - 0.2 then
                    spectralRealm = true
                end
            end
            -- switching nodes
            node = node.next
        end
    end
    
    -- input handling
    if buttons.right then
        player.vel.x = player.vel.x + 16 * dt
    elseif buttons.left then
        player.vel.x = player.vel.x - 16 * dt
    else
        player.vel.x = lume.lerp(player.vel.x, 0, 0.2)
    end

    if DEBUG and buttons.hold then
        if buttons.up then
            player.vel.y = player.vel.y - 16 * dt
        elseif buttons.down then
            player.vel.y = player.vel.y + 16 * dt
        else
            player.vel.y = lume.lerp(player.vel.y, 0, 0.2)
        end
    else
        player.vel.y = player.vel.y + GRAVITY * dt

        -- checking collisions...
        checkCollisions()
    end

    if DEBUG and buttons.hold then
        player.vel.x = lume.clamp(player.vel.x, -5, 5)
        player.vel.y = lume.clamp(player.vel.y, -5, 5)
    else
        player.vel.x = lume.clamp(player.vel.x, -1, 1)
        player.vel.y = lume.clamp(player.vel.y, -3, 3)
    end

    -- updating player's position
    player.pos.x = player.pos.x + player.vel.x
    player.pos.y = player.pos.y + player.vel.y

    -- camera updating
    local scl = (screen:getScale() - 1) * 0.5
    local dx,dy = player.pos.x - camera.x + scl * GAME_WIDTH, player.pos.y - camera.y + scl * GAME_HEIGHT
    camera:move(dx, dy)
    if not DEBUG then
        camera.scale = lume.lerp(camera.scale, (1.2 - math.abs(player.vel.x * 0.15)), .02)
        bgCamera.scale = lume.lerp(camera.scale, (1.2 - math.abs(player.vel.x * 0.01)), .02)
    end
    bgCamera:lookAt(player.pos.x * 0.5 + scl * GAME_WIDTH, player.pos.y * 0.5 + scl * GAME_HEIGHT)
end

local selectedNode = nil

function love.mousepressed(x, y, button, istouch)
    if button == 1 then -- Versions prior to 0.10.0 use the MouseConstant 'l'
        local bx, by = camera:worldCoords(x, y)
        local node = map
        local scl = (screen:getScale() - 1) * 0.5
        local bx = x * 0.5 + player.pos.x
        local by = y * 0.5 + player.pos.y
        print("searching at..." .. bx .. " " .. by)
        print('static position: ' .. x .. ' ' .. y)
        print('player position: ' .. player.pos.x .. ' ' .. player.pos.y)
        print("--")
        while node do
            local nx = node.x + scl * GAME_WIDTH
            local ny = node.y + scl * GAME_HEIGHT
            if bx > nx - 4 and bx < nx + 4 and by > ny - 4 and by < ny + 4 then
                print("got it!")
                selectedNode = node
                break
            end

            -- switching nodes
            node = node.next
        end
    end
 end

 function love.mousereleased(x, y, button, istouch)
    selectedNode = nil
 end

 function love.mousemoved(x, y, dx, dy, istouch)
    if selectedNode ~= nil then
        bx = x * 0.5 + player.pos.x
        by = y * 0.5 + player.pos.y
        selectedNode.x = x
        selectedNode.y = y
    end
 end

function checkCollisions()
    local node = map
    local nextNode = map.next
    while nextNode do
        local bx = node.x
        local by = node.y
        local ex = nextNode.x
        local ey = nextNode.y

        local px1 = player.pos.x + player.w * 0.5
        local py1 = player.pos.y + player.h + player.vel.y + 0.5
        local px2 = player.pos.x + player.w * 0.5
        local py2 = player.pos.y + player.vel.y

        -- checking vertical collision
        local intersect = intersectSegments(px1, py1, px2, py2, bx, by, ex, ey)
        if intersect ~= nil then
            player.vel.y = 0
            if intersect.y > player.pos.y then
                player.pos.y = intersect.y - player.h + 1.5
            end
        end

        -- checking horizontal collisions
        local px1 = player.pos.x - player.w * 0.5 + player.vel.x
        local py1 = player.pos.y + player.h * 0.5
        local px2 = player.pos.x + player.w * 0.5 + player.vel.x
        local py2 = player.pos.y + player.h * 0.5
        local intersect = intersectSegments(px1, py1, px2, py2, bx, by, ex, ey)
        if intersect ~= nil then
            player.vel.x = 0
            if intersect.x > player.pos.x + player.w * 0.5 then
                player.pos.x = intersect.x - player.w * 0.5 - 0.1
            else
                player.pos.x = intersect.x + player.w * 0.5 + 0.1
            end
        end

        -- switching nodes
        node = nextNode
        nextNode = nextNode.next
    end
end

function render()
    -- love.graphics.clear(12, 23, 77, 255)
    love.graphics.clear(7, 4, 7, 255)
    bgCamera:attach()
    love.graphics.setColor(love.math.random(255), love.math.random(255), love.math.random(255), 180)
    -- updating bgRectangles
    drawRects()
    bgCamera:detach()

    camera:attach()
    love.graphics.setColor(love.math.random(255), love.math.random(255), love.math.random(255), 255)
    -- the player
    love.graphics.line(player.pos.x, player.pos.y, player.pos.x, player.pos.y + player.h)
    love.graphics.line(player.pos.x - player.w * 0.5, player.pos.y + player.h * 0.5, player.pos.x + player.w * 0.5, player.pos.y + player.h * 0.5)

    -- the map
    local node = map
    local nextNode = map.next
    while nextNode do
        -- love.graphics.line(node.x, node.y, nextNode.x, nextNode.y)
        love.graphics.line(nextNode.x, nextNode.y, node.x, node.y)
        if DEBUG then
            love.graphics.rectangle('line', nextNode.x - 4, nextNode.y - 4, 8, 8)
        end
        node = nextNode
        nextNode = nextNode.next
    end
    camera:detach()
    love.graphics.print(love.timer.getFPS(), GAME_WIDTH - 32, GAME_HEIGHT - 32)
end

function drawRects()
    -- Check to see if you want the rectangle to be rounded or not:
    -- Set defaults for rotation, offset x and y
    love.graphics.push()
    for i, v in ipairs(bgRectangles) do
        -- rotatedRectangle( 'line', 100, 100, 50, 50, math.pi / 4 )
        v.r = v.r + v.rs * 0.017
        v.x = v.x - v.xs * 0.017
        love.graphics.translate(v.x + v.w/2, v.y + v.h/2)
        love.graphics.push()
        if v.x < bgCamera.x - GAME_WIDTH then
            v.x = bgCamera.x + GAME_WIDTH
            v.w = love.math.random(30, 100)
            v.h = v.w
            -- v.y = bgCamera.y - GAME_HEIGHT + love.math.random(GAME_HEIGHT)
        end
        love.graphics.rotate(-v.r)
        love.graphics.rectangle('line', -v.w/2, -v.h/2, v.w, v.h)
        love.graphics.rotate(v.r)
        love.graphics.pop()
    end
    love.graphics.pop()
end

function drawRect(mode, x, y, w, h, a)
    -- Check to see if you want the rectangle to be rounded or not:
    -- Set defaults for rotation, offset x and y
    a = a or 0
    ox = w / 2
    oy = h / 2
    -- You don't need to indent these; I do for clarity
    love.graphics.push()
        love.graphics.translate(x + ox, y + oy)
        love.graphics.push()
            love.graphics.rotate(-a)
            love.graphics.rectangle(mode, -ox, -oy, w, h)
        love.graphics.pop()
    love.graphics.pop()
end

function rotatedRectangle( mode, x, y, w, h, rx, ry, segments, r, ox, oy )
    -- Check to see if you want the rectangle to be rounded or not:
    if not oy and rx then r, ox, oy = rx, ry, segments end
    -- Set defaults for rotation, offset x and y
    r = r or 0
    ox = ox or w / 2
    oy = oy or h / 2
    -- You don't need to indent these; I do for clarity
    love.graphics.push()
        love.graphics.translate( x + ox, y + oy )
        love.graphics.push()
            love.graphics.rotate( -r )
            love.graphics.rectangle( mode, -ox, -oy, w, h, rx, ry, segments )
        love.graphics.pop()
    love.graphics.pop()
end

function love.draw()
    screen:draw(render)
end

function love.keypressed(key)
    if key == "right" or key == "d" then
        buttons.right = true
    elseif key == "left" or key == "a" then
        buttons.left = true
    elseif key == "up" or key == "w" then
        buttons.up = true
    elseif key == "down" or key == "s" then
        buttons.down = true
    elseif key == "h" then
        buttons.hold = true
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
    if DEBUG then
        if key == 'q' then
            spectralRealm = false
        end
        if key == 'e' then
            spectralRealm = true
        end
    end

    -- player buttons
    if key == "right" or key == "d" then
        buttons.right = false
    elseif key == "left" or key == "a" then
        buttons.left = false
    elseif key == "up" or key == "w" then
        buttons.up = false
    elseif key == "down" or key == "s" then
        buttons.down = false
    elseif key == "h" then
        buttons.hold = false
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