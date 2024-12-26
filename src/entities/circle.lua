
-- Imports
local Point = require "entities.point"
local Utils = require "utils"

---@class Circle:Point
local Circle = Point:extend()

CIRCLE_TYPES = {party=0, enemy=1, fireball=2, heal=3}

---Constructor
function Circle:new(x, y, dx, dy, radius, speed, color, type)
    Circle.super.new(self, x, y, color)
    self.dx, self.dy = Utils.normalizeVectors(dx, dy)
	print(self.dx, self.dy)
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
    -- Debug to see where circles are traveling
    if DebugMode then
        love.graphics.line(self.x, self.y, self.x + (self.dx * self.speed * 0.25), self.y + (self.dy * self.speed * 0.25))
    end

    love.graphics.setColor(self.color)
	love.graphics.circle("line", self.x, self.y, self.radius)
    love.graphics.setColor(White)
end

--- Reverse provided direction components of circle upon collision with screen edges
function Circle:handleScreenCollision()
    if self.x - self.radius <= CameraScreenXZero then
        self.x = self.radius
        self.dx = -self.dx
        WallBounceSfx:play()
    elseif self.x + self.radius >= CameraScreenWidth then
        self.x = CameraScreenWidth - self.radius
        self.dx = -self.dx
        WallBounceSfx:play()
    end

    if self.y - self.radius <= CameraScreenYZero then
        self.y = self.radius
        self.dy = -self.dy
        WallBounceSfx:play()
    elseif self.y + self.radius >= CameraScreenHeight then
        self.y = CameraScreenHeight - self.radius
        self.dy = -self.dy
        WallBounceSfx:play()
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