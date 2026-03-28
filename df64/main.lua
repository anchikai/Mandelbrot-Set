local dragger = require("dragger")
local reset = require("reset")

local shaderFile = assert(io.open("df64/mandelbrot.glsl"))
local shaderCode = shaderFile:read("*a")
shaderFile:close()

local main = {}

---@type love.conf
function main.conf(conf)
	conf.console = true
end

---@type love.load
function main.load()
	love.window.setMode(320, 320)
	love.window.setTitle("Mandelbrot Set")
	maxIterations = 64
	inverseMaxIterations = 1 / maxIterations
	offset = {}
	offset.X = 0
	offset.Y = 0
	size = 2.25
	realMin = -size + offset.X
	realDiff = 2 * size / love.graphics.getWidth()

	imaginaryMin = -size + offset.Y
	imaginaryDiff = 2 * size / love.graphics.getHeight()

	velx, vely = 0, 0

	font = love.graphics.newFont("Renogare.ttf", 18)

	juliaR, juliaI = 0, 0

	mandelbrotShader = love.graphics.newShader(shaderCode)
	mandelbrotShader:send("max_iterations", maxIterations)
	mandelbrotShader:send("inverse_max_iter", inverseMaxIterations)
end

function clamp(min, val, max)
	return math.max(min, math.min(val, max))
end

local SPLITTER = bit.lshift(1, 29) + 1

---@param val number
---@return number hi, number lo
local function split_df64(val)
	local t = val * SPLITTER
	local hi = t - (t - val)
	local lo = val - hi

	return hi, lo
end

local pauseCooldown = 0
---@type love.update
function main.update(dt)
	time = love.timer.getTime()

	local width, height = love.graphics.getDimensions()

	-- Camera Movement
	dragger.update(love.mouse.isDown(3))
	dragger.deltaMult = size
	offset.X = -dragger.X / (width / 2)
	offset.Y = -dragger.Y / (height / 2)

	-- Reset
	if love.keyboard.isDown("r") then
		reset()
	end

	local wi, hi = love.window.getMode()
	if love.keyboard.isDown("1") and wi ~= 320 then
		love.window.setMode(320, 320)
	elseif love.keyboard.isDown("2") and wi ~= 512 then
		love.window.setMode(512, 512)
	elseif love.keyboard.isDown("3") and wi ~= 640 then
		love.window.setMode(640, 640)
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
			mandelbrotShader:send("max_iterations", maxIterations)
			mandelbrotShader:send("inverse_max_iter", inverseMaxIterations)
		end
		pauseCooldown = 1
	else
		pauseCooldown = 0
	end

	if love.keyboard.isDown("space") then
		juliaR = (love.mouse.getX() - love.graphics.getWidth() / 2) / 100
		juliaI = (love.mouse.getY() - love.graphics.getHeight() / 2) / 100
	end

	-- Camera Zoom
	size = math.abs(size / (1 + vely * 0.0075))
	vely = vely - vely * math.min(dt * 10, 1)

	realMin = offset.X - size
	realDiff = 2 * size / width

	imaginaryMin = offset.Y - size
	imaginaryDiff = 2 * size / height

	local juliaRHi, juliaRLo = split_df64(juliaR)
	mandelbrotShader:send("julia_r_hi", juliaRHi)
	mandelbrotShader:send("julia_r_lo", juliaRLo)
	local juliaIHi, juliaILo = split_df64(juliaI)
	mandelbrotShader:send("julia_i_hi", juliaIHi)
	mandelbrotShader:send("julia_i_lo", juliaILo)
	local realMinHi, realMinLo = split_df64(realMin)
	mandelbrotShader:send("real_min_hi", realMinHi)
	mandelbrotShader:send("real_min_lo", realMinLo)
	local imagMinHi, imagMinLo = split_df64(imaginaryMin)
	mandelbrotShader:send("imag_min_hi", imagMinHi)
	mandelbrotShader:send("imag_min_lo", imagMinLo)
	local realDiffHi, realDiffLo = split_df64(realDiff)
	mandelbrotShader:send("real_diff_hi", realDiffHi)
	mandelbrotShader:send("real_diff_lo", realDiffLo)
	local imagDiffHi, imagDiffLo = split_df64(imaginaryDiff)
	mandelbrotShader:send("imag_diff_hi", imagDiffHi)
	mandelbrotShader:send("imag_diff_lo", imagDiffLo)
end

function main.draw()
	local width, height = love.graphics.getDimensions()
	love.graphics.setShader(mandelbrotShader)
	love.graphics.rectangle("fill", 0, 0, width, height)
	love.graphics.setShader()

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
		love.graphics.rectangle("fill", 0, height - 32, 72, 32)
	end
	love.graphics.setColor(0, 0, 0)
	love.graphics.print(string.format("Size: %.3g", size), 2, 20)
	love.graphics.print("Iterations: " .. maxIterations, 2)

	-- Controls Help
	if love.keyboard.isDown("tab") then
		love.graphics.setColor(1, 1, 1, 0.5)
		love.graphics.rectangle("fill", 0, height - 115, love.graphics.getWidth(), 115)
		love.graphics.setColor(0, 0, 0)
		love.graphics.print("Pan Camera: Middle Click", 2, height - 115)
		love.graphics.print("Zoom In/Out: Scroll Up/Down", 2, height - 92)
		love.graphics.print("+/- Iterations: LMB/RMB", 2, height - 69)
		love.graphics.print("Reset: R  Adjust Z: Spacebar", 2, height - 46)
		love.graphics.print("Window Size: 1-3", 2, height - 23)
		love.graphics.print(love.timer.getFPS() .. " FPS", width - 80, height - 23)
	else
		love.graphics.print(love.timer.getFPS() .. " FPS", 2, height - 23)
	end
end

---@type love.wheelmoved
function main.wheelmoved(dx, dy)
	vely = vely + dy * 20
end

return main
