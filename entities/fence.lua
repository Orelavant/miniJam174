local Rectangle = require "entities.rectangle"
local Utils = require "utils"

---@class Fence:Rectangle
local Fence = Rectangle:extend()

-- Global config
---@enum fenceStates
FENCE_STATES = {material=0, moving=1, immaterial=2}

-- Local config
local width = 40
local height = 5
local speedMod = 1.4

-- Constructor
function Fence:new(x, y)
    Fence.super.new(self, x, y, width, height)
    self.speedMod = speedMod
    self.state = FENCE_STATES.material
end

--- Handle fence movement
---@param mouseDown boolean
---@param dt number
function Fence:update(mouseDown, mouseX, mouseY, dt)
	if mouseDown then
		-- Initialize the start of the movement
		if StartOfMove then
			self.state = FENCE_STATES.moving
			MouseDragStart = {x=mouseX, y=mouseY}
		end

		-- TODO make getting angle a util function
		-- Based off the distance and direction of the mouse movement, move the fence
		local angle = math.atan2(mouseY - MouseDragStart.y, mouseX - MouseDragStart.x)
		local cos = math.cos(angle)
		local sin = math.sin(angle)
		local distance = Utils.getDistance(MouseDragStart.x, MouseDragStart.y, mouseX, mouseY)

		-- Update fence position
		self.x = self.x + distance * self.speedMod * cos * dt
		self.y = self.y + distance * self.speedMod * sin * dt

		-- Keep fence in screen
		self = self:handleScreenCollision()

		-- No longer start of move
		StartOfMove = false
	else
		-- Move has ended by now
		StartOfMove = true

		-- Make fence material again if not colliding with anything
		if self.state == FENCE_STATES.immaterial then
			local colliding = false
			local i = 1
			while not colliding and i <= #TableOfCircles do
				local circle = TableOfCircles[i]
				if self:checkCircleCollision(circle) then
					colliding = true
				end

				i = i + 1
			end

			if not colliding then
				self.state = FENCE_STATES.material
			end
		end
	end
end

function Fence:handleCircleCollision(circle)
	if self:circleCollided(circle) then
		-- Determine the side of collision
        local closestX = math.max(self.x, math.min(circle.x, self.x + self.width))
        local closestY = math.max(self.y, math.min(circle.y, self.y + self.height))
        local overlapX = circle.x - closestX
        local overlapY = circle.y - closestY

        if math.abs(overlapX) > math.abs(overlapY) then
            -- Vertical collision
            circle.dx = -circle.dx
        else
            -- Horizontal collision
            circle.dy = -circle.dy
        end
	end

	return circle
end

function Fence:circleCollided(circle)
	return self:checkCircleCollision(circle) and self.state == FENCE_STATES.material
end

return Fence