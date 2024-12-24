local Rectangle = require "entities.rectangle"
local Utils = require "utils"

---@class Fence:Rectangle
local Fence = Rectangle:extend()

-- Global config
---@enum fenceStates
FENCE_STATES = {material=0, moving=1, immaterial=2}

-- Local config
local width = 60
local height = 5
local speedMod = 1.65
local color = LightBlue

-- Constructor
function Fence:new(x, y)
    Fence.super.new(self, x, y, width, height, color)
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
		-- TODO add util for adding all the circles into one table
		if self.state == FENCE_STATES.immaterial then
			-- Create table of all circles to check collisions against
			local tableOfCircles = {Party}
			for _, circle in ipairs(TableOfProjectiles) do
				table.insert(tableOfCircles, circle)
			end
			for _, circle in ipairs(TableOfEnemies) do
				table.insert(tableOfCircles, circle)
			end

			-- Check if colliding with any circles. If not, immaterial, if so, still immaterial
			local colliding = false
			local i = 1
			while not colliding and i <= #tableOfCircles do
				local circle = tableOfCircles[i]
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

	if self.state == FENCE_STATES.moving or self.state == FENCE_STATES.immaterial then
		self.color = SemiTransparentLightBlue
	else
		self.color = LightBlue
	end
end

-- Chat Gpt Generated
function Fence:handleCircleCollision(circle)
    if self:circleCollided(circle) then
		Fence:bounceSfx()

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

function Fence:circleCollided(circle)
	return self:checkCircleCollision(circle) and self.state == FENCE_STATES.material
end

function Fence:rotate()
	self.state = FENCE_STATES.immaterial

	self.x = self.x + ((self.width / 2) - (self.height / 2))
	self.y = self.y - ((self.width - self.height) / 2)

	local temp = self.width
	self.width = self.height
	self.height = temp

end

function Fence:bounceSfx()
	local n = love.math.random(1, #BounceSfxTable)
	BounceSfxTable[n]:play()
end

return Fence