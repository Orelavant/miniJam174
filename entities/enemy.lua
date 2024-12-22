local Circle = require "entities.Circle"

---@class Enemy:Circle
local Enemy = Circle:extend()

-- Local config
local speed = 65
local boostValue = 40
local dizzyTimer = 3
local boostDecayTime = 2
local boostDecayPerSecond = boostValue / boostDecayTime
local color = Orange

function Enemy:new(x, y, dx, dy, radius)
    Enemy.super.new(self, x, y, dx, dy, radius, speed, color, CIRCLE_TYPES.enemy)
    self.dizzy = false
    self.dizzyTimer = dizzyTimer
    self.boostDecayTimer = 0
    --- TODO temp fix since boost is being applied multiple times for some reason
    self.boostApplied = false
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

    self:decayBoost(dt)
    Enemy.super.update(self, dt)
end

function Enemy:setDizzy(boolean)
    self.dizzy = boolean
end

function Enemy:applyBoost()
    self.speed = self.speed + boostValue
    self.boostDecayTimer = boostDecayTime
    self.boostApplied = true
end

function Enemy:decayBoost(dt)
    if self.boostDecayTimer > 0 then
        local sub = boostDecayPerSecond * dt
        self.speed = self.speed - sub
    else
        self.boostApplied = false
    end
end

return Enemy