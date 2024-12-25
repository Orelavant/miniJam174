local Circle = require "entities.circle"
local Utils = require "utils"

---@class Enemy:Circle
local Enemy = Circle:extend()

-- Local config
local speed = 65
local boostValue = 65
local dizzyTimer = 3
local boostDecayTime = 3
local boostDecayPerSecond = boostValue / boostDecayTime
local color = Orange

function Enemy:new(x, y, dx, dy, radius)
    Enemy.super.new(self, x, y, dx, dy, radius, speed, color, CIRCLE_TYPES.enemy)
    self.dizzy = false
    self.dizzyTimer = dizzyTimer
    self.boostDecayTimer = 0
    self.boostApplied = false
end

function Enemy:update(dt)
    if not self.dizzy then
        self.dizzyTimer = dizzyTimer

        -- Target the party by getting the angle toward them
        self.dx, self.dy = Utils.getSourceTargetAngleComponents(self.x, self.y, Party.x, Party.y)
    else
        -- Only dizzy till dizzyTimer is up
        self.dizzyTimer = self.dizzyTimer - dt

        if self.dizzyTimer <= 0 then
            self.dizzy = false
        end
    end

    self:decayBoost(dt)

    self:update(dt)
end

function Enemy:setDizzy(boolean)
    self.dizzy = boolean
end

function Enemy:applyBoost()
    self.speed = self.speed + boostValue
    self.boostDecayTimer = boostDecayTime
    self.boostApplied = true
end

-- investigate why this is being called when it shouldn't be
function Enemy:decayBoost(dt)
    if self.boostDecayTimer > 0 then
        local sub = boostDecayPerSecond * dt
        self.speed = self.speed - sub
        self.boostDecayTimer = self.boostDecayTimer - dt
    else
        self.boostApplied = false
    end
end

return Enemy