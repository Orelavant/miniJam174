-- Debugger
if arg[2] == "debug" then
	require("lldebugger").start()
end

-- Imports
local Utils = require "utils"

-- Config
--- @enum gameStates
GAME_STATES = {play=0, done=1, menu=2}
local DebugMode = true

local ScreenWidth = love.graphics.getWidth()
local ScreenHeight = love.graphics.getHeight()
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
local FenceX = ScreenWidth / 2
local FenceY = (ScreenHeight / 2) - 150

-- Callbacks
function love.load()
	-- Globals
	GameState = GAME_STATES.play
	PartyHealth = 3
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
	Party = CircleInit(ScreenWidth / 2, ScreenHeight / 2, Utils.randFloat(), Utils.randFloat(), PartyRadius, PartySpeed, PartyColor)
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
	for i=#TableOfEnemies,1,-1 do
		enemy = TableOfEnemies[i]

		enemy:update(dt)

		-- Fence collision
		if Fence:circleCollided(enemy) then
			enemy:setDizzy(true)
			enemy = Fence:handleCircleCollision(enemy)
		end

		-- Party collision
		if Party:checkCircleCollision(enemy) then
			PartyHealth = PartyHealth - 1
			table.remove(TableOfEnemies, i)
		end
	end

	if PartyHealth <= 0 then
		GameState = GAME_STATES.done
		love.load()
	end
end

function love.draw()
	-- Health
	love.graphics.print(PartyHealth, ScreenWidth-20, 0, 0, 2, 2)

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
