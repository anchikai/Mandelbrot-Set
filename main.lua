local main = require("df64.main")

love.conf = main.conf
love.load = main.load
love.update = main.update
love.draw = main.draw
love.wheelmoved = main.wheelmoved
