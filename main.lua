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
-- TODO move to seperate config file
White = {1, 1, 1, 0.8}
Red = {1, 0, 0, 0.8}
Green = {0, 1, 0, 0.8}
LightBlue = {0.68, 0.85, 0.9, 0.8}
Orange = {1, 0.647, 0, 0.8}

local PartyRadius = 25
local PartySpeed = 60
local PartyColor = White

local FireballColor = Red
local FireballRadius = 5
local FireballSpeed = 200
local HealColor = Green
local HealRadius = 5
local HealSpeed = 200

local Fence --- @type Fence
local FenceX = ScreenWidth / 2
local FenceY = (ScreenHeight / 2) - 150

-- Callbacks
function love.load()
	-- Globals
	GameState = GAME_STATES.play
	PartyHealth = 20
	TableOfProjectiles = {} ---@type Projectile[]
	TableOfEnemies = {} ---@type Enemy[]
	StartOfMove = true
	MousePos = {x=0, y=0}
	MouseDragStart = {x=0, y=0}

	-- Init classes
	CircleInit = require "entities.circle"
	EnemyInit = require "entities.enemy"
	ProjectileInit = require "entities.projectile"
	local FenceInit = require "entities.fence"

	-- Init objs
	---@type Circle
	Party = CircleInit(ScreenWidth / 2, ScreenHeight / 2, Utils.randFloat(), Utils.randFloat(), PartyRadius, PartySpeed, PartyColor, CIRCLE_TYPES.party)

	Fence = FenceInit(FenceX, FenceY)
end

function love.update(dt)
	-- Get position of mouse
	MousePos.x, MousePos.y = love.mouse.getPosition()

	-- Update fence
	Fence:update(love.mouse.isDown(1), MousePos.x, MousePos.y, dt)

	-- Update party and fence collision
	Party:update(dt)
	Party = Fence:handleCircleCollision(Party)

	-- Update projectiles
	for i=#TableOfProjectiles,1,-1 do
		local projectile = TableOfProjectiles[i]

		-- Move projectile
		projectile:update(dt)
		
		-- Fence collision
		projectile = Fence:handleCircleCollision(projectile)

		-- Party collision
		--- TODO move circle types to projectiles class
		if Party:checkCircleCollision(projectile) and not projectile.justSpawned then
			-- Resolve effect
			if projectile.type == CIRCLE_TYPES.Fireball then
				PartyHealth = PartyHealth - 1
			elseif projectile.type == CIRCLE_TYPES.heal then
				PartyHealth = PartyHealth + 1
			end

			-- Remove from table
			table.remove(TableOfProjectiles, i)
		end


		-- Enemy collision
		-- TODO fix bug with many projectiles getting removed that were not involved in collision and many enemies spawning (after heal hits them)
		for i=#TableOfEnemies,1,-1 do
			enemy = TableOfEnemies[i]

			if enemy:checkCircleCollision(projectile) then
				-- Resolve effect
				if projectile.type == CIRCLE_TYPES.Fireball then
					table.remove(TableOfEnemies, i)
				elseif projectile.type == CIRCLE_TYPES.heal then
					-- TODO make this speed boost big decaying, so if you bounce them away its rewarding
					enemy.speed = enemy.speed + 10
					table.insert(TableOfEnemies, newEnemy)
				end
	
				-- Remove from table
				table.remove(TableOfProjectiles, i)
			end
		end
	end

	-- Update enemies
	for i=#TableOfEnemies,1,-1 do
		enemy = TableOfEnemies[i]

		enemy:update(dt)

		-- Fence collision
		if Fence:circleCollided(enemy) then
			enemy = Fence:handleCircleCollision(enemy)
			enemy:setDizzy(true)
		end

		-- Party collision
		if Party:checkCircleCollision(enemy) then
			PartyHealth = PartyHealth - 2
			table.remove(TableOfEnemies, i)
		end
	end

	-- Check if game over
	if PartyHealth <= 0 then
		GameState = GAME_STATES.done
		love.load()
	end
end

function love.draw()
	-- Health
	love.graphics.print(PartyHealth, ScreenWidth-40, 0, 0, 2, 2)

	-- Draw Circles
	Party:draw()
	for _, circle in ipairs(TableOfProjectiles) do
		circle:draw()
	end
	for _, circle in ipairs(TableOfEnemies) do
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
		-- TODO track nearest enemy, shoot Fireball at them
		local fireball = ProjectileInit(Party.x, Party.y, Utils.randFloat(), Utils.randFloat(), FireballRadius, FireballSpeed, FireballColor, CIRCLE_TYPES.Fireball)
		table.insert(TableOfProjectiles, fireball)
	end

	if DebugMode and key == "f" then
		local heal = ProjectileInit(Party.x, Party.y, Utils.randFloat(), Utils.randFloat(), HealRadius, HealSpeed, HealColor, CIRCLE_TYPES.heal)
		table.insert(TableOfProjectiles, heal)
	end

	-- Debugging enemy spawn
	if DebugMode and key == "e" then
		local enemy = EnemyInit(love.math.random(EnemyRadius+5, love.graphics.getWidth()), EnemyRadius+5, Utils.randFloat(), Utils.randFloat())
		table.insert(TableOfEnemies, enemy)
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