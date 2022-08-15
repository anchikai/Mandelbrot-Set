local dragger = require("dragger")
local complex = require("complex")
require("reset")

local pointsTable = {}
function love.load()
    love.window.setMode(320, 320)
    love.window.setTitle("Mandelbrot Set")
    maxIterations = 64
    inverseMaxIterations = 1 / maxIterations
    offset = {}
    offset.X = 0
    offset.Y = 0
    size = 2.25
    realMin = -size + offset.X
    realMax = size + offset.X

    imaginaryMin = -size + offset.Y
    imaginaryMax = size + offset.Y

    velx, vely = 0, 0

    font = love.graphics.newFont("Renogare.ttf", 18)

    local counter = 1
    for x = 0, love.graphics.getWidth() do
        for y = 0, love.graphics.getHeight() do
            pointsTable[counter] = {x, y, 0, 0, 0, 1}
            counter = counter + 1
        end
    end
end

local juliaX = 0
local juliaY = 0
local function mandelbrot(cr, ci)
    local zr, zi = juliaX, juliaY
    local n = 0
    while zr * zr + zi * zi <= 4 and n < maxIterations do
        zr, zi = zr * zr - zi * zi, zr * zi + zi * zr -- square z
        zr, zi = zr + cr, zi + ci -- add c to z
        n = n + 1
    end
    return n
end

-- local c = complex.new(0.274, 0.008)
-- local R = 4

-- -- where z is x, y coordinates
-- local function julia(z)
--   local n = 0
--   while complex.abs(z) < R and n < maxIterations do
--     z = complex.add(complex.mul(z, z), c)
--     n = n + 1
--   end

--   return n
-- end

function clamp(min, val, max)
    return math.max(min, math.min(val, max));
end

local pauseCooldown = 0
function love.update(dt)
    time = love.timer.getTime()

    -- Camera Movement
    dragger.update(love.mouse.isDown(3))
    dragger.deltaMult = size
    offset.X = -dragger.X/160
    offset.Y = -dragger.Y/160

    -- Reset
    if love.keyboard.isDown("r") then
        reset()
    end

    local wi, hi = love.window.getMode()
    local windowChanged
    if love.keyboard.isDown("1") and wi ~= 320 then
        windowChanged = true
        love.window.setMode(320, 320)
    elseif love.keyboard.isDown("2") and wi ~= 512 then
        windowChanged = true
        love.window.setMode(512, 512)
    elseif love.keyboard.isDown("3") and wi ~= 640 then
        windowChanged = true
        love.window.setMode(640, 640)
    end

    if windowChanged then
        pointsTable = {}
        local counter = 1
        for x = 0, love.graphics.getWidth() do
            for y = 0, love.graphics.getHeight() do
                pointsTable[counter] = {x, y, 0, 0, 0, 1}
                counter = counter + 1
            end
        end
    end

    -- Max Iterations
    if love.mouse.isDown(1) or love.mouse.isDown(2) then
        if pauseCooldown ~= 1 then
            if love.mouse.isDown(1) then
                maxIterations = maxIterations * 2
            elseif love.mouse.isDown(2) then
                maxIterations = maxIterations / 2
            end
            maxIterations = clamp(2, maxIterations, 8192)
            inverseMaxIterations = 1 / maxIterations
        end
        pauseCooldown = 1
    else
        pauseCooldown = 0
    end

    if love.keyboard.isDown("space") then
        juliaX = (love.mouse.getX()-love.graphics.getWidth()/2)/100
        juliaY = (love.mouse.getY()-love.graphics.getHeight()/2)/100
    end

    -- Camera Zoom
    size = math.abs(size / (1 + vely * 0.0075))
    velx = velx - velx * math.min( dt * 10, 1 )
    vely = vely - vely * math.min( dt * 10, 1 )

    realMin = offset.X - size
    realMax = offset.X + size

    imaginaryMin = offset.Y - size
    imaginaryMax = offset.Y + size
end

function love.draw()
    local counter = 1
    for x = 0, love.graphics.getWidth() do
        for y = 0, love.graphics.getHeight() do
            local cr, ci = realMin + (x / love.graphics.getWidth()) * (realMax - realMin), imaginaryMin + (y /love.graphics.getHeight()) * (imaginaryMax - imaginaryMin)
            local m = mandelbrot(cr, ci)
            R = 1 - m * inverseMaxIterations
            G = 0.8 - m * inverseMaxIterations
            B = 1 - m * inverseMaxIterations
            local point = pointsTable[counter]
            point[3], point[4], point[5] = R, G, B
            counter = counter + 1
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.points(pointsTable)
    
    -- Set Info
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, 0.5)
    if time >= 10 then
        love.graphics.rectangle("fill", 0, 0, 160, 46)
    elseif time < 10 then
        love.graphics.rectangle("fill", 0, 0, 200, 69)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print("Hold TAB for Help", 2, 40)
    end
    if not love.keyboard.isDown("tab") then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("fill", 0, love.graphics.getHeight()-32, 72, 32)
    end
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(string.format("Size: %.3g", size), 2, 20)
    love.graphics.print("Iterations: "..maxIterations, 2)

    -- Controls Help
    if love.keyboard.isDown("tab") then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 115, love.graphics.getWidth(), 115)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print("Pan Camera: Middle Click", 2, love.graphics.getHeight() - 115)
        love.graphics.print("Zoom In/Out: Scroll Up/Down", 2, love.graphics.getHeight() - 92)
        love.graphics.print("+/- Iterations: LMB/RMB", 2, love.graphics.getHeight() - 69)
        love.graphics.print("Reset: R  Adjust Z: Spacebar", 2, love.graphics.getHeight() - 46)
        love.graphics.print("Window Size: 1-3", 2, love.graphics.getHeight() - 23)
        love.graphics.print(love.timer.getFPS().." FPS", love.graphics.getWidth() - 80, love.graphics.getHeight() - 23)
    else
        love.graphics.print(love.timer.getFPS().." FPS", 2, love.graphics.getHeight() - 23)
    end
end

function love.wheelmoved( dx, dy )
    velx = velx + dx * 20
    vely = vely + dy * 20
end