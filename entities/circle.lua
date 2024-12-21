
local Point = require "entities.point"

---@class Circle:Point
local Circle = Point:extend()

---Constructor
---@param x number
---@param y number
---@param radius number
---@param speed number
function Circle:new(x, y, dx, dy, radius, speed)
    Circle.super.new(self, x, y, speed)
    self.dx = dx
    self.dy = dy
    self.radius = radius
end

--- Update circle position
---@param dt number
function Circle:update(dt)
    -- Normalize the direction vector (dx, dy) to have a magnitude of 1
    local magnitude = math.sqrt(self.dx^2 + self.dy^2)
    self.dx = self.dx / magnitude
    self.dy = self.dy / magnitude

    -- Update circle position
    self.x = self.x + self.speed * self.dx * dt
    self.y = self.y + self.speed * self.dy * dt

    -- Handle screen collision
    self:handleScreenCollision()
end

function Circle:draw()
	love.graphics.circle("line", self.x, self.y, self.radius)
end

--- Reverse provided direction components of circle upon collision with screen edges
function Circle:handleScreenCollision()
	-- Collision on x axis
	if self.x - self.radius < 0 or self.x + self.radius > self.screenWidth then
		self.dx = -self.dx
	end

	-- Colision on y axis
	if self.y - self.radius < 0 or self.y + self.radius > self.screenHeight then
		self.dy = -self.dy
	end
end

return Circle