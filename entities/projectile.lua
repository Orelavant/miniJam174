local Circle = require "entities.Circle"

---@class Projectile:Circle
local Projectile = Circle:extend()

function Projectile:new(x, y, dx, dy, radius, speed, color, type)
    Projectile.super.new(self, x, y, dx, dy, radius, speed, color, type)
    self.justSpawned = true
end

function Projectile:update(dt)
    Projectile.super.update(self, dt)

    if not self:checkCircleCollision(Party) and self.justSpawned then
        self.justSpawned = false
    end
end

return Projectile