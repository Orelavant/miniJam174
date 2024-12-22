-- Debugger
if arg[2] == "debug" then
	require("lldebugger").start()
end

-- Imports
local Utils = require "utils"

-- Config
local DebugMode = true

local ScreenWidthMid = love.graphics.getWidth() / 2
local ScreenHeightMid = love.graphics.getHeight() / 2
White = {1, 1, 1, 1}
Red = {1, 0, 0, 1}
Green = {0, 1, 0, 0.5}

local PartyRadius = 25
local PartySpeed = 60
local PartyColor = Green

local ProjectileRadius = 5
local ProjectileSpeed = 200
local ProjectileColor = Red

local Fence --- @type Fence
local FenceX = ScreenWidthMid
local FenceY = ScreenHeightMid - 150

-- Callbacks
function love.load()
	-- Globals
	TableOfCircles = {} ---@type Circle[]
	TableOfEnemies = {} ---@type Enemy[]
	StartOfMove = true
	MousePos = {x=0, y=0}
	MouseDragStart = {x=0, y=0}

	-- Init classes
	CircleInit = require "entities.circle"
	EnemyInit = require "entities.enemy"
	local FenceInit = require "entities.fence"

	-- Init objs
	Party = CircleInit(ScreenWidthMid, ScreenHeightMid, Utils.randFloat(), Utils.randFloat(), PartyRadius, PartySpeed, PartyColor)
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

	-- Update enemies
	for _, enemy in ipairs(TableOfEnemies) do
		enemy:update(dt)
		if Fence:circleCollided(enemy) then
			enemy:setDizzy(true)
			enemy = Fence:handleCircleCollision(enemy)
		end
	end
end

function love.draw()
	-- Draw Circles
	for _, circle in ipairs(TableOfCircles) do
		circle:draw()
	end

	-- Draw Enemies
	for _, enemy in ipairs(TableOfEnemies) do
		enemy:draw()
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
		table.insert(TableOfCircles, CircleInit(Party.x, Party.y, Utils.randFloat(), Utils.randFloat(), ProjectileRadius, ProjectileSpeed, ProjectileColor))
	end

	-- Debugging enemy spawn
	if DebugMode and key == "e" then
		table.insert(TableOfEnemies, EnemyInit(love.math.random(EnemyRadius+5, love.graphics.getWidth()), EnemyRadius+5, Utils.randFloat(), Utils.randFloat()))
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
