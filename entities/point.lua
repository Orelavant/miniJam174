local Object = require "lib.classic"

---@class Point
local Point = Object:extend()

function Point:new(x, y, color)
    self.x = x
    self.y = y
    self.screenWidth = love.graphics.getWidth()
    self.screenHeight = love.graphics.getHeight()
    self.color = color
end

function Point:setTransparancy(alpha)
    self.color[4] = alpha
end

return Point