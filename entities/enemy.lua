local Circle = require "entities.Circle"

---@class Enemy:Circle
local Enemy = Circle:extend()

-- Local config
EnemyRadius = 10
local speed = 80
local dizzyTimer = 2
local color = {1, 0.647, 0, 0.5}

function Enemy:new(x, y, dx, dy)
    Enemy.super.new(self, x, y, dx, dy, EnemyRadius, speed, color)
    self.dizzy = false
    self.dizzyTimer = dizzyTimer
end

function Enemy:update(dt)
    if not self.dizzy then
        self.dizzyTimer = dizzyTimer

        -- Target the party by getting the angle toward them
        local angle = math.atan2(Party.y - self.y, Party.x - self.x)
        self.dx = math.cos(angle)
        self.dy = math.sin(angle)
    else
        -- Only dizzy till dizzyTimer is up
        self.dizzyTimer = self.dizzyTimer - dt
        if self.dizzyTimer < 0 then
            self.dizzy = false
        end
    end

    Enemy.super.update(self, dt)
end

function Enemy:setDizzy(boolean)
    self.dizzy = boolean
end

return Enemy