-- Debugger
if arg[2] == "debug" then
	require("lldebugger").start()
end

-- Local vars
local ScreenWidth = love.graphics.getWidth()
local ScreenHeight = love.graphics.getHeight()

-- Party
local PartyRadius = 25
local PartySpeed = 150

-- Fence
---@enum fenceStates
F_STATES = {material=0, moving=1, immaterial=2}

---@param fenceState fenceStates
local function setFenceState(fenceState) end

local FenceWidth = 40
local FenceHeight = 5
local FenceSpeedMod = 1.4

-- Projectiles
local ProjectileRadius = 10
local ProjectileSpeed = 200

-- Callbacks
function love.load()
	-- Globals
	TableOfCircles = {}

	-- Fence Movement vars
	StartOfMove = true
	IsFencePhysical = true
	FenceState = F_STATES.material
	MouseDragStart = {x=0, y=0}

	-- Party
	Party = spawnMovCircle(ScreenWidth / 2, ScreenHeight / 2, randFloat(), randFloat(), PartyRadius, PartySpeed)

	-- Fence
	Fence = {x=10, y=10, width=FenceWidth, height=FenceHeight}

	table.insert(TableOfCircles, Party)
end

function love.update(dt)
	-- Fence movement logic
	mouseX, mouseY = love.mouse.getPosition()
	if love.mouse.isDown(1) then
		FenceState = F_STATES.moving
		-- Initialize the start of the movement
		if StartOfMove then
			MouseDragStart = {x=mouseX, y=mouseY}
		end

		-- Based off the distance and direction of the mouse movement, move the fence
		local angle = math.atan2(mouseY - MouseDragStart.y, mouseX - MouseDragStart.x)
		local cos = math.cos(angle)
		local sin = math.sin(angle)
		local distance = getDistance(MouseDragStart.x, MouseDragStart.y, mouseX, mouseY)

		-- Update fence position
		Fence.x = Fence.x + distance * FenceSpeedMod * cos * dt
		Fence.y = Fence.y + distance * FenceSpeedMod * sin * dt

		-- Keep fence in screen
		Fence = keepRectInScreen(Fence)

		StartOfMove = false
	else
		StartOfMove = true

		-- Make fence material again if not colliding with anything
		if FenceState == F_STATES.immaterial then
			local colliding = false
			local i = 1
			while not colliding and i <= #TableOfCircles do
				local circle = TableOfCircles[i]
				if circleRectangleCollision(circle, Fence) then
					colliding = true
				end

				i = i + 1
			end

			if not colliding then
				FenceState = F_STATES.material
			end
		end
	end


	-- Update all circles
	updateCircles(TableOfCircles, dt)
end

function love.draw()
	-- Draw Circles
	for _, circle in ipairs(TableOfCircles) do
		love.graphics.circle("line", circle.x, circle.y, circle.radius)
	end

	-- Draw Fence
	love.graphics.rectangle("line", Fence.x, Fence.y, Fence.width, Fence.height)
	if FenceState == F_STATES.moving then
		love.graphics.line(MouseDragStart.x, MouseDragStart.y, mouseX, mouseY)
	end
end

function love.keypressed(key)
	if key == "space" then
		dx = randFloat()
		dy = randFloat()

		table.insert(TableOfCircles, spawnMovCircle(Party.x, Party.y, dx, dy, ProjectileRadius, ProjectileSpeed))
	end
end

function love.mousereleased()
	FenceState = F_STATES.immaterial
end

-- Helper Functions
--- Update circles
---@param tableOfCircles any
---@param dt any
function updateCircles(tableOfCircles, dt)
	for _, circle in ipairs(tableOfCircles) do
		-- Normalize the direction vector (dx, dy) to have a magnitude of 1
		local magnitude = math.sqrt(circle.dx^2 + circle.dy^2)
		circle.dx = circle.dx / magnitude
		circle.dy = circle.dy / magnitude

		-- Update circle position
		circle.x = circle.x + circle.speed * circle.dx * dt
		circle.y = circle.y + circle.speed * circle.dy * dt

		-- Bounce circles off fence
		circle, rect = bounceCircleOffRect(circle, Fence)

		-- Bounce circles off screen
		circle = bounceCircleOffScreen(circle)
	end
end

--- Reverse provided direction components of circle upon collision with screen edges
---@param circle movCircle
---@return movCircle
function bounceCircleOffScreen(circle)
	-- Collision on x axis
	if circle.x - circle.radius < 0 or circle.x + circle.radius > ScreenWidth then
		circle.dx = -circle.dx
	end

	-- Colision on y axis
	if circle.y - circle.radius < 0 or circle.y + circle.radius > ScreenHeight then
		circle.dy = -circle.dy
	end

	return circle
end

function keepRectInScreen(rect)
	local rightEdge = rect.x + rect.width

	if rightEdge > ScreenWidth then
		rect.x = ScreenWidth - rect.width
	elseif rect.x < 0 then
		rect.x = 0
	end

	 return rect
end

--- Get distance between two points
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@return number
function getDistance(x1, y1, x2, y2)
    local horizontal_distance = x1 - x2
    local vertical_distance = y1 - y2

    local a = horizontal_distance ^ 2
    local b = vertical_distance ^ 2

    local c = a + b
    local distance = math.sqrt(c)

    return distance
end


-- Chatgpt provided
--- Bounce circle off rect
---@param circle any
---@param rect any
function bounceCircleOffRect(circle, rect)
	if circleRectangleCollision(circle, rect) and FenceState == F_STATES.material then
		-- Determine the side of collision
        local closestX = math.max(rect.x, math.min(circle.x, rect.x + rect.width))
        local closestY = math.max(rect.y, math.min(circle.y, rect.y + rect.height))
        local overlapX = circle.x - closestX
        local overlapY = circle.y - closestY

        if math.abs(overlapX) > math.abs(overlapY) then
            -- Vertical collision (left or right)
            circle.dx = -circle.dx
        else
            -- Horizontal collision (top or bottom)
            circle.dy = -circle.dy
        end
	end

	return circle, rect
end

-- Chatgpt provided
--- Check for circle rectangle collision
---@param circle movCircle
---@param rect any
---@return boolean
function circleRectangleCollision(circle, rect)
    -- Find the closest point on the rectangle to the circle
    local closestX = math.max(rect.x, math.min(circle.x, rect.x + rect.width))
    local closestY = math.max(rect.y, math.min(circle.y, rect.y + rect.height))

    -- Calculate the distance between the circle's center and this closest point
    local distanceX = circle.x - closestX
    local distanceY = circle.y - closestY
    local distanceSquared = distanceX^2 + distanceY^2

    -- Check if the distance is less than or equal to the circle's radius squared
    return distanceSquared <= circle.radius^2
end

-- Moving Circle definition
---@class movCircle
---@field x number
---@field y number
---@field dx number
---@field dy number
---@field radius number
---@field speed number

--- Return table with all components needed for a moving circle
---@param x number
---@param y number
---@param dx number
---@param dy number
---@param radius number
---@param speed number
---@return movCircle
function spawnMovCircle(x, y, dx, dy, radius, speed)
	return {
		x = x,
		y = y,
		dx = dx,
		dy = dy,
		radius = radius,
		speed = speed,
	}
end

--- Return random float between -1 and 1
---@return number
function randFloat()
	return love.math.random() * 2 - 1
end

-- make error handling nice
local love_errorhandler = love.errorhandler

function love.errorhandler(msg)
	if lldebugger then
		error(msg, 2)
	else
		return love_errorhandler(msg)
	end
end
