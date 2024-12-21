local Object = require "lib.classic"

---@class Point
local Point = Object:extend()

function Point:new(x, y, speed)
    self.x = x
    self.y = y
    self.screenWidth = love.graphics.getWidth()
    self.screenHeight = love.graphics.getHeight()
    self.speed = speed
end

return Point