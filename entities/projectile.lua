local Circle = require "entities.Circle"

---@class Projectile:Circle
local Projectile = Circle:extend()

function Projectile:new(x, y, dx, dy, radius, speed, color, type, decay)
    Projectile.super.new(self, x, y, dx, dy, radius, speed, color, type)
    self.justSpawned = true
    self.currChargeRadius = 0
    self.decay = decay
end

function Projectile:update(dt)

    Projectile.super.update(self, dt)

    -- Spawn collision check
    if not self:checkCircleCollision(Party) and self.justSpawned then
        self.justSpawned = false
    end

    self:updateDecay(dt)
end

function Projectile:updateDecay(dt)
    if self.decay > 0 then
        self.decay = self.decay - dt
    end
end


-- static util
function drawChargeAnimation(radius, color)
    love.graphics.setColor(color)
	love.graphics.circle("line", Party.x, Party.y, radius)
    love.graphics.setColor(White)
end

return Projectile