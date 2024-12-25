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

	if rightEdge >= CameraScreenWidth then
		self.x = CameraScreenWidth - self.width
	elseif self.x <= CameraScreenXZero then
		self.x = CameraScreenXZero
	end

	if bottomEdge >= CameraScreenHeight then
		self.y = CameraScreenHeight - self.height
	elseif self.y <= CameraScreenYZero + 1 then
		self.y = CameraScreenYZero + 1
	end

	return self
end

-- Chat Gpt Generated
function Rectangle:handleCircleCollision(circle)
    if self:checkCircleCollision(circle) then
		-- Fence:bounceSfx()

        -- Find the closest point on the rectangle to the circle
        local closestX = math.max(self.x, math.min(circle.x, self.x + self.width))
        local closestY = math.max(self.y, math.min(circle.y, self.y + self.height))

        -- Calculate the vector from the circle's center to the closest point
        local overlapX = circle.x - closestX
        local overlapY = circle.y - closestY
        local distance = math.sqrt(overlapX^2 + overlapY^2)

        -- If the circle is actually overlapping (distance < circle radius)
        if distance < circle.radius then
            -- Normalize the overlap vector
            local normX = overlapX / distance
            local normY = overlapY / distance

            -- Push the circle out along the normalized vector
            circle.x = closestX + normX * circle.radius
            circle.y = closestY + normY * circle.radius

            -- Reflect the circle's velocity along the normal
            local dot = circle.dx * normX + circle.dy * normY
            circle.dx = circle.dx - 2 * dot * normX
            circle.dy = circle.dy - 2 * dot * normY
        end
    end

    return circle
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