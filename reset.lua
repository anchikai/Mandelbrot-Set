local dragger = require("dragger")
local function reset()
	size = 2.25
	juliaR = 0
	juliaI = 0
	offset.X = 0
	offset.Y = 0
	dragger.X = 0
	dragger.Y = 0
	dragger.savedX = 0
	dragger.savedY = 0
end

return reset
