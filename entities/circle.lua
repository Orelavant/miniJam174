
local Point = require "entities.point"

---@class Circle:Point
local Circle = Point:extend()

CIRCLE_TYPES = {party=0, enemy=1, fireball=2, heal=3}

---Constructor
function Circle:new(x, y, dx, dy, radius, speed, color, type)
    Circle.super.new(self, x, y, color)
    -- Normalize the direction vector (dx, dy) to have a magnitude of 1
    local magnitude = math.sqrt(dx^2 + dy^2)
    self.dx = dx / magnitude
    self.dy = dy / magnitude
    self.radius = radius
    self.speed = speed
    self.type = type
end

--- Update circle position
---@param dt number
function Circle:update(dt)
    -- Update circle position
    self.x = self.x + self.speed * self.dx * dt
    self.y = self.y + self.speed * self.dy * dt

    -- Handle screen collision
    self:handleScreenCollision()
end

function Circle:draw()
    love.graphics.setColor(self.color)
	love.graphics.circle("line", self.x, self.y, self.radius)
    love.graphics.setColor(White)
end

--- Reverse provided direction components of circle upon collision with screen edges
function Circle:handleScreenCollision()
    -- Collision on x axis
    if self.x - self.radius < 0 then
        self.x = self.radius -- Push circle out of the left wall
        self.dx = -self.dx
    elseif self.x + self.radius > self.screenWidth then
        self.x = self.screenWidth - self.radius -- Push circle out of the right wall
        self.dx = -self.dx
    end

    -- Collision on y axis
    if self.y - self.radius < 0 then
        self.y = self.radius -- Push circle out of the top wall
        self.dy = -self.dy
    elseif self.y + self.radius > self.screenHeight then
        self.y = self.screenHeight - self.radius -- Push circle out of the bottom wall
        self.dy = -self.dy
    end
end

function Circle:checkCircleCollision(circle)
    -- Calculate the distance between the two circles
    local dx = circle.x - self.x
    local dy = circle.y - self.y
    local distance = math.sqrt(dx^2 + dy^2)

    -- Check if the circles are colliding
    return distance < (self.radius + circle.radius)
end

return Circle