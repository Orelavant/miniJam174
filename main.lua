-- debugger
if arg[2] == "debug" then
	require("lldebugger").start()
end

-- declare local vars
local screenWidth = love.graphics.getWidth()
local screenHeight = love.graphics.getHeight()

local partyRadius = 25
local partySpeed = 400

local projectileRadius = 10
local projectileSpeed = 200

-- code
function love.load()
	-- Globals
    tableOfCircles = {}

	-- Party
	party = spawnMovCircle(
		screenWidth / 2,
		screenHeight / 2,
		randFloat(),
		randFloat(),
        partyRadius,
        partySpeed
	)

    table.insert(tableOfCircles, party)
end

function love.update(dt)
    for _,circle in ipairs(tableOfCircles) do
        -- Update circle position
        circle.x = circle.x + circle.speed * circle.dx * dt
        circle.y = circle.y + circle.speed * circle.dy * dt

        -- Reverse circle angle component upon screen collision
        circle = bounceCircleOffScreen(circle, screenWidth, screenHeight)
    end

end

function love.draw()
    for _,circle in ipairs(tableOfCircles) do
        love.graphics.circle("line", circle.x, circle.y, circle.radius)
    end
end

function love.keypressed(key)
	-- For debugging
	if key == "space" then
        dx = randFloat()
        dy = randFloat()
        print(dx, dy)
		table.insert(
			tableOfCircles,
			spawnMovCircle(
				party.x,
				party.y,
				dx,
                dy,	
				projectileRadius,
				projectileSpeed
			)
		)
	end
end

--- Reverse provided direction components of circle
---@param movCircle movCircle
---@return movCircle
function bounceCircleOffScreen(movCircle)
	-- Collision on x axis
	if movCircle.x - movCircle.radius < 0 or movCircle.x + movCircle.radius > screenWidth then
		movCircle.dx = -movCircle.dx
	end

	-- Colision on y axis
	if movCircle.y - movCircle.radius < 0 or movCircle.y + movCircle.radius > screenHeight then
		movCircle.dy = -movCircle.dy
	end

    return movCircle
end


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

--- random float between -1 and 1
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
