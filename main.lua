-- Debugger
if arg[2] == "debug" then
	require("lldebugger").start()
end

-- Config
local DebugMode = true

local Party --- @type Circle
local PartyRadius = 25
local PartySpeed = 150

local Fence --- @type Fence
local FenceX = 10
local FenceY = 10

local ProjectileRadius = 10
local ProjectileSpeed = 200

-- Callbacks
function love.load()
	-- Globals
	TableOfCircles = {}
	StartOfMove = true
	MousePos = {x=0, y=0}
	MouseDragStart = {x=0, y=0}

	-- Init classes
	CircleInit = require "entities.circle"
	local FenceInit = require "entities.fence"

	-- Init objs
	Party = CircleInit(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, PartyRadius, PartySpeed)
	table.insert(TableOfCircles, Party)

	Fence = FenceInit(FenceX, FenceY)
end

function love.update(dt)
	-- Get position of mouse
	MousePos.x, MousePos.y = love.mouse.getPosition()

	-- Update fence
	Fence:update(love.mouse.isDown(1), MousePos.x, MousePos.y, dt)

	-- Update circles
	for _, circle in ipairs(TableOfCircles) do
		circle:update(dt)
		circle = Fence:handleCircleCollision(circle)
	end
end

function love.draw()
	-- Draw Circles
	for _, circle in ipairs(TableOfCircles) do
		circle:draw()
	end

	-- Draw Fence
	Fence:draw()

	-- Debugging fence movement line
	if DebugMode and Fence.state == FENCE_STATES.moving then
		love.graphics.line(MouseDragStart.x, MouseDragStart.y, MousePos.x, MousePos.y)
	end
end

function love.keypressed(key)
	-- Debugging spawn projectile
	if DebugMode and key == "space" then
		table.insert(TableOfCircles, CircleInit(Party.x, Party.y, ProjectileRadius, ProjectileSpeed))
	end
end

function love.mousereleased()
	-- Fence won't block stuff until it's no longer colliding with anything
	Fence.state = FENCE_STATES.immaterial
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
