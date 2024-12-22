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

-- TODO move to seperate config file
White = {1, 1, 1, 0.8}
Red = {1, 0, 0, 0.8}
Green = {0, 1, 0, 0.5}
LightBlue = {0.68, 0.85, 0.9, 1}
Orange = {1, 0.647, 0, 0.8}
local ScreenWidth = love.graphics.getWidth()
local ScreenWidthMid = ScreenWidth / 2
local ScreenHeight = love.graphics.getHeight()
local ScreenHeightMid  = ScreenHeight / 2

local PartyRadius = 25
local PartySpeed = 60
local PartyColor = White

local FenceX = ScreenWidthMid
local FenceY = ScreenHeightMid - 150

local EnemyRadius = 15
local EnemySpawnBuffer = 5
local EnemySpawnLocations = {
	{x=ScreenWidthMid, y=EnemyRadius},
	{x=EnemyRadius + EnemySpawnBuffer, y=ScreenHeightMid},
	{x=ScreenWidth - EnemyRadius - EnemySpawnBuffer, y=ScreenHeightMid},
	{x=ScreenWidthMid, y=ScreenHeight - EnemyRadius - EnemySpawnBuffer}
}
local EnemySpawnRate = 10

local FireballColor = Red
local FireballRadius = 15
local FireballSpeed = 150
local FireballSpawnRate = 7
local FireballDecay = FireballSpawnRate / 3
local HealColor = Green
local HealRadius = 20
local HealSpeed = 150
local HealSpawnRate = 13
local HealDecay = HealSpawnRate / 3

-- Callbacks
function love.load()
	-- Globals
	GameState = GAME_STATES.play
	Score = 0
	PartyHealth = 5
	TableOfProjectiles = {} ---@type Projectile[]
	TableOfEnemies = {} ---@type Enemy[]
	StartOfMove = true
	MousePos = {x=0, y=0}
	MouseDragStart = {x=0, y=0}

	FireballTimer = FireballSpawnRate
	CurrFireballRadius = 0
	HealTimer = HealSpawnRate
	CurrHealRadius = 0

	EnemyTimer = 3

	-- Init classes
	CircleInit = require "entities.circle"
	EnemyInit = require "entities.enemy"
	ProjectileInit = require "entities.projectile"
	local FenceInit = require "entities.fence"

	-- Init objs
    -- Normalize the direction vector (dx, dy) to have a magnitude of 1
    local magnitude = math.sqrt(Utils.randFloat()^2 + Utils.randFloat()^2)
    local dx = Utils.randFloat() / magnitude
    local dy = Utils.randFloat() / magnitude
	Party = CircleInit(ScreenWidthMid, ScreenHeightMid, dx, dy, PartyRadius, PartySpeed, PartyColor, CIRCLE_TYPES.party)

	Fence = FenceInit(FenceX, FenceY)
end

function love.update(dt)
	-- Get position of mouse
	MousePos.x, MousePos.y = love.mouse.getPosition()

	-- Update charge radiuses
	CurrHealRadius = updateChargeRadius(CurrHealRadius, HealRadius, HealSpawnRate, dt)
	CurrFireballRadius = updateChargeRadius(CurrFireballRadius, FireballRadius, FireballSpawnRate, dt)

	-- Spawn timers
	if HealTimer <= 0 then
		spawnHeal()
		HealTimer = HealSpawnRate
	else
		HealTimer = HealTimer - dt
	end
	if FireballTimer <= 0 then
		spawnFireball()
		FireballTimer = FireballSpawnRate
	else
		FireballTimer  = FireballTimer - dt
	end
	if EnemyTimer <= 0 then
		spawnEnemy()
		EnemyTimer = EnemySpawnRate
	else
		EnemyTimer  = EnemyTimer - dt
	end

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
		if projectile.decay <= 0 then
			table.remove(TableOfProjectiles, i)
		end
		
		-- Fence collision
		projectile = Fence:handleCircleCollision(projectile)

		-- Party collision
		--- TODO move circle types to projectiles class
		if Party:checkCircleCollision(projectile) and not projectile.justSpawned then
			-- Resolve effect
			if projectile.type == CIRCLE_TYPES.Fireball then
				PartyHealth = PartyHealth - 1
			elseif projectile.type == CIRCLE_TYPES.heal then
				PartyHealth = PartyHealth + 2
			end

			-- Remove from table
			table.remove(TableOfProjectiles, i)
		end


		-- Enemy collision
		-- TODO fix bug with many projectiles getting removed that were not involved in collision and many enemies spawning (after heal hits them)
		-- TODO fix bug where boost is getting applied multiple times
		for j=#TableOfEnemies,1,-1 do
			local enemy = TableOfEnemies[j]

			if enemy:checkCircleCollision(projectile) then
				-- Remove from table
				table.remove(TableOfProjectiles, j)

				-- Resolve effect
				if projectile.type == CIRCLE_TYPES.Fireball then
					table.remove(TableOfEnemies, j)
				elseif projectile.type == CIRCLE_TYPES.heal then
					enemy:applyBoost()
				end
			end
		end
	end

	-- Update enemies
	for i=#TableOfEnemies,1,-1 do
		local enemy = TableOfEnemies[i]

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
	for _, projectile in ipairs(TableOfProjectiles) do
		projectile:draw()
	end
	for _, enemy in ipairs(TableOfEnemies) do
		enemy:draw()
	end

	-- Draw projectile charge animations
	drawChargeAnimation(CurrHealRadius, HealColor)
	drawChargeAnimation(CurrFireballRadius, FireballColor)

	-- Draw Fence
	Fence:draw()

	-- Debugging fence movement line
	if DebugMode and Fence.state == FENCE_STATES.moving then
		love.graphics.line(MouseDragStart.x, MouseDragStart.y, MousePos.x, MousePos.y)
	end
end

function love.keypressed(key)
	-- Reset game
	if key == "r" then
		love.load()
	end
	
	if key == "d" then
		Fence:rotate()
	end

	-- Debugging spawns
	if DebugMode and key == "space" then
		spawnFireball()
	end

	if DebugMode and key == "f" then
		spawnHeal()
	end

	if DebugMode and key == "e" then
		spawnEnemy()
	end
end

function love.mousereleased()
	-- Fence won't block stuff until it's no longer colliding with anything
	Fence.state = FENCE_STATES.immaterial
end

function spawnFireball()
		local cos, sin = Utils.getSourceTargetAngleComponents(
			Party.x,
			Party.y,
			(Fence.x + (Fence.width / 2)),
			(Fence.y + (Fence.height / 2))
		)
		local fireball = ProjectileInit(
			Party.x,
			Party.y,
			cos,
			sin,
			FireballRadius,
			FireballSpeed,
			FireballColor,
			CIRCLE_TYPES.Fireball,
			FireballDecay
		)
		table.insert(TableOfProjectiles, fireball)
end

function spawnHeal()
	local cos, sin = Utils.getSourceTargetAngleComponents(
		Party.x,
		Party.y,
		(Fence.x + (Fence.width / 2)),
		(Fence.y + (Fence.height / 2))
	)
	local heal = ProjectileInit(
		Party.x,
		Party.y,
		cos,
		sin,
		HealRadius,
		HealSpeed,
		HealColor,
		CIRCLE_TYPES.heal,
		HealDecay
	)
	table.insert(TableOfProjectiles, heal)
end

function spawnEnemy()
	local spawn = EnemySpawnLocations[love.math.random(1, #EnemySpawnLocations)]
	local enemy = EnemyInit(
		spawn.x,
		spawn.y,
		Utils.randFloat(),
		Utils.randFloat(),
		EnemyRadius
	)
	table.insert(TableOfEnemies, enemy)
end

function updateChargeRadius(currRadius, targetRadius, projectileSpawnRate, dt)
    -- Projectile charge radius
    if currRadius < targetRadius then
		local updateRate = targetRadius / projectileSpawnRate
        currRadius = currRadius + updateRate * dt
    else
        currRadius = 0
    end

	return currRadius
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