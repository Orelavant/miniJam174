-- Debugger
if arg[2] == "debug" then
	require("lldebugger").start()
end

-- Local vars
local ScreenWidth = love.graphics.getWidth()
local ScreenHeight = love.graphics.getHeight()

local PartyRadius = 25
local PartySpeed = 150

local FenceWidth = 40
local FenceHeight = 5

local ProjectileRadius = 10
local ProjectileSpeed = 200

-- Callbacks
function love.load()
	-- Settings
	love.mouse.setVisible(false)

	-- Globals
	TableOfCircles = {}

	-- Party
	Party = spawnMovCircle(ScreenWidth / 2, ScreenHeight / 2, randFloat(), randFloat(), PartyRadius, PartySpeed)

	-- Fence
	Fence = {x=10, y=10, width=FenceWidth, height=FenceHeight}

	table.insert(TableOfCircles, Party)
end

function love.update(dt)
	-- Fence follows mouse
	mouse_x, mouse_y = love.mouse.getPosition()
	Fence.x = mouse_x - (Fence.width / 2)
	Fence.y = mouse_y - (Fence.height / 2)

	-- Update all circles
	updateCircles(TableOfCircles, dt)
end

function love.draw()
	-- Draw Fence
	love.graphics.rectangle("line", Fence.x, Fence.y, Fence.width, Fence.height)

	-- Draw Circles
	for _, circle in ipairs(TableOfCircles) do
		love.graphics.circle("line", circle.x, circle.y, circle.radius)
	end
end

function love.keypressed(key)
	if key == "space" then
		dx = randFloat()
		dy = randFloat()

		table.insert(TableOfCircles, spawnMovCircle(Party.x, Party.y, dx, dy, ProjectileRadius, ProjectileSpeed))
	end
end

-- Helper Functions
--- Update circles
---@param tableOfCircles any
---@param dt any
function updateCircles(tableOfCircles, dt)
	for _, circle in ipairs(tableOfCircles) do
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

-- Chatgpt provided
--- Bounce circle off rect
---@param circle any
---@param rect any
function bounceCircleOffRect(circle, rect)
	if circleRectangleCollision(circle, rect) then
		-- Find the closest point on the rectangle
        local closestX = math.max(rect.x, math.min(circle.x, rect.x + rect.width))
        local closestY = math.max(rect.y, math.min(circle.y, rect.y + rect.height))

        -- Calculate the collision normal (direction from the closest point to the circle center)
        local normalX = circle.x - closestX
        local normalY = circle.y - closestY
        local normalLength = math.sqrt(normalX^2 + normalY^2)

        -- Normalize the collision normal
        normalX = normalX / normalLength
        normalY = normalY / normalLength

        -- Calculate dot product of velocity and normal to check if moving towards the rectangle
        local dotProduct = circle.dx * normalX + circle.dy * normalY
        
        -- If dot product is negative, the circle is moving towards the rectangle
        if dotProduct < 0 then
            -- Reflect the velocity vector
            circle.dx = circle.dx - 2 * dotProduct * normalX
            circle.dy = circle.dy - 2 * dotProduct * normalY

            -- Resolve the overlap for the circle: move the circle out of the rectangle
            local overlap = circle.radius - normalLength
            circle.x = circle.x + normalX * overlap
            circle.y = circle.y + normalY * overlap

            -- Resolve the overlap for the rectangle: move it out of the circle
            -- Move the rectangle away from the circle along the collision normal
            local rectOverlap = overlap
            if math.abs(normalX) > math.abs(normalY) then
                -- Move rectangle horizontally if the collision is mostly horizontal
                rect.x = rect.x - normalX * rectOverlap
            else
                -- Move rectangle vertically if the collision is mostly vertical
                rect.y = rect.y - normalY * rectOverlap
            end
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
