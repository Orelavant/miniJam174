local Point = require "entities.point"

---@class Rectangle:Point
local Rectangle = Point:extend()

---Constructor
function Rectangle:new(x, y, width, height, color)
    Rectangle.super.new(self, x, y, color)
    self.width = width
    self.height = height
end

--- Draw rectangle
function Rectangle:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.setColor(White)
end

function Rectangle:handleScreenCollision()
	local rightEdge = self.x + self.width
	local bottomEdge = self.y + self.height

	if rightEdge > self.screenWidth then
		self.x = self.screenWidth - self.width
	elseif self.x < 0 then
		self.x = 0
	end

	if bottomEdge > self.screenHeight then
		self.y = self.screenHeight - self.height
	elseif self.y < 1 then
		self.y = 1
	end

	return self
end

function Rectangle:checkCircleCollision(circle)
    -- Find the closest point on the rectangle to the circle
    local closestX = math.max(self.x, math.min(circle.x, self.x + self.width))
    local closestY = math.max(self.y, math.min(circle.y, self.y + self.height))

    -- Calculate the distance between the circle's center and this closest point
    local distanceX = circle.x - closestX
    local distanceY = circle.y - closestY
    local distanceSquared = distanceX^2 + distanceY^2

    -- Check if the distance is less than or equal to the circle's radius squared
    return distanceSquared <= circle.radius^2
end

return Rectangle