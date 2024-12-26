-- Debugger
if arg[2] == "debug" then
	DebugMode = true
	print(arg[2])
	require("lldebugger").start()
else
	DebugMode = false
end

-- Imports
local Utils = require "utils"

-- Config
--- @enum gameStates
GAME_STATES = {play=0, done=1, menu=2}

local Song = love.audio.newSource("audio/spaceJazz.mp3", "stream")
Song:setVolume(0.5)
local PartyDamageSfx = love.audio.newSource("audio/partyDamage.wav", "static")
local ProjectileShotSfx = love.audio.newSource("audio/fireball.wav", "static")
local EnemyDeathSfx = love.audio.newSource("audio/enemyDeath2.wav", "static")
WallBounceSfx = love.audio.newSource("audio/wallBounce.wav", "static")
BounceSfxTable = {
	love.audio.newSource("audio/bounce1.wav", "static"),
	love.audio.newSource("audio/bounce2.wav", "static")
}

-- TODO move to seperate config file
White = {1, 1, 1, 0.8}
Red = {1, 0, 0, 0.8}
Green = {0, 1, 0, 0.5}
LightBlue = {0.68, 0.85, 0.9, 1}
SemiTransparentLightBlue = {0.68, 0.85, 0.9, 0.5}
TransparentLightBlue = {0.68, 0.85, 0.9, 0.2}
Orange = {1, 0.647, 0, 0.8}

local ScreenWidth = love.graphics.getWidth()
local ScreenHeight = love.graphics.getHeight()
local InitCameraMoveTimer = 5

local BushImg = love.graphics.newImage("visual/bush.png")
local BushScale = 0.025
local BushOffset = 10
local MaxBushCount = 30

local PartyRadius = 25
local PartyColor = White
local GlobalSpeedMod = 10
local GlobalSpeed = 0
local DebugGlobalSpeed = 100
local InitGlobalSpeedModRate = 21
local InitPartyHealth = 5
local DebugPartyHealth = 9999
local GlobalSpeedModRate = 25

local FenceX = ScreenWidth / 2
local FenceY = ScreenHeight / 2 - 150

local EnemyRadius = 15
local EnemySpawnBuffer = 5
local EnemySpawnLocations = {
	{x=ScreenWidth / 2, y=EnemyRadius},
	{x=EnemyRadius + EnemySpawnBuffer, y=ScreenHeight / 2},
	{x=ScreenWidth - EnemyRadius - EnemySpawnBuffer, y=ScreenHeight / 2},
	{x=ScreenWidth / 2, y=ScreenHeight - EnemyRadius - EnemySpawnBuffer}
}
local EnemySpawnRate = 10

local FireballColor = Red
local FireballRadius = 10
local FireballSpeed = 150
local FireballSpawnRate = 7
local FireballDecay = FireballSpawnRate * 1.5
local HealColor = Green
local HealRadius = 20
local HealSpeed = 150
local HealSpawnRate = 13
local HealDecay = HealSpawnRate * 2


-- Callbacks
function love.load()
	-- Audio
	Song:setLooping(true)
	Song:play()

	-- Globals
	GameState = GAME_STATES.play
	CameraScreenWidth = ScreenWidth
	CameraScreenHeight = ScreenHeight
	CameraScreenXZero = 0
	CameraScreenYZero = 0
	PartyXPositionAtStartOfCamMove = 0
	PartyYPositionAtStartOfCamMove = 0
	PartyXPositionAtEndOfCamMove = 0
	PartyYPositionAtEndOfCamMove = 0
	CameraMove = false
	CameraMoveStart = true
	CameraMoveTimer = InitCameraMoveTimer
	CameraMoveZone = CameraScreenWidth - CameraScreenWidth / 4

	Score = 0
	-- TODO have a func that sets all vars relavant to debug modes or not
	if DebugMode then
		PartyHealth = DebugPartyHealth
		PartySpeed = DebugGlobalSpeed
	else
		PartyHealth = InitPartyHealth
		PartySpeed = GlobalSpeed
	end
	PartyTimer = InitGlobalSpeedModRate
	TableOfProjectiles = {} ---@type Projectile[]
	TableOfEnemies = {} ---@type Enemy[]
	TableOfBushes = {}
	StartOfMove = true
	MousePos = {x=0, y=0}
	MouseDragStart = {x=0, y=0}
	ShakeDuration = 0
	ShakeWait = 0
	ShakeOffset = {x = 0, y = 0}

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
	Party = CircleInit(ScreenWidth / 2, ScreenHeight / 2, 1, 0, PartyRadius, PartySpeed, PartyColor, CIRCLE_TYPES.party)
	initBushSpawn()

	Fence = FenceInit(FenceX, FenceY)
end

function love.update(dt)
	-- Get position of mouse
	MousePos.x, MousePos.y = love.mouse.getPosition()

	-- Screenshake
	if ShakeDuration > 0 then
		ShakeDuration = ShakeDuration - dt
		if ShakeWait > 0 then
			ShakeWait = ShakeWait - dt
		else
			ShakeOffset.x = love.math.random(-5,5)
			ShakeOffset.y = love.math.random(-5,5)
			ShakeWait = 0.05
		end
	end

	-- Update charge radiuses
	CurrHealRadius = updateChargeRadius(CurrHealRadius, PartyRadius, HealSpawnRate, dt)
	CurrFireballRadius = updateChargeRadius(CurrFireballRadius, PartyRadius, FireballSpawnRate, dt)

	-- TODO Update speed of everything on timer
	if PartyTimer > 0 then
		PartyTimer = PartyTimer - dt
	else
		Party.speed = PartySpeed + GlobalSpeedMod

		-- Reset timer
		PartyTimer = GlobalSpeedModRate
	end

	-- Spawn timers
	if HealTimer <= 0 and not DebugMode then
		spawnHeal()
		HealTimer = HealSpawnRate
	else
		HealTimer = HealTimer - dt
	end
	if FireballTimer <= 0 and not DebugMode then
		spawnFireball()
		FireballTimer = FireballSpawnRate
	else
		FireballTimer  = FireballTimer - dt
	end
	if EnemyTimer <= 0 and not DebugMode then
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

	-- Move camera if party is on the right quarter of the screen
	if Party.x > CameraMoveZone then
		CameraMove = true
		if CameraMoveStart then
			PartyXPositionAtStartOfCamMove = Party.x
			PartyYPositionAtStartOfCamMove = Party.y
			CameraMoveStart = false
		end
	end
	
	-- Temp, stop camera move after a certain amount of time
	if not CameraMoveStart then
		CameraMoveTimer = CameraMoveTimer - dt
		if CameraMoveTimer <= 0 then
			CameraMove = false
			CameraMoveStart = true
			CameraMoveTimer = InitCameraMoveTimer
			CameraMoveZone = CameraScreenWidth - CameraScreenWidth / 4
			PartyXPositionAtEndOfCamMove = Party.x
			PartyYPositionAtEndOfCamMove = Party.y
		end
	end

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
				PartyDamageSfx:play()
				ShakeDuration = 0.15
			elseif projectile.type == CIRCLE_TYPES.heal then
				PartyHealth = PartyHealth + 2
			end

			-- Remove from table
			table.remove(TableOfProjectiles, i)
		end


		-- Enemy collision
		-- TODO fix bug with many projectiles getting removed that were not involved in collision and many enemies spawning (after heal hits them)
		for j=#TableOfEnemies,1,-1 do
			local enemy = TableOfEnemies[j]

			if enemy:checkCircleCollision(projectile) then
				-- Remove from table
				table.remove(TableOfProjectiles, j)

				-- Resolve effect
				if projectile.type == CIRCLE_TYPES.Fireball then
					table.remove(TableOfEnemies, j)
					EnemyDeathSfx:play()
					Score = Score + 10
				elseif projectile.type == CIRCLE_TYPES.heal then
					if enemy.boostApplied == false then
						enemy:applyBoost()
					end
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


	-- Update values based off player's direction of travel
	if CameraMove then
		CameraScreenWidth = CameraScreenWidth + Party.speed * Party.dx * dt
		CameraScreenXZero = CameraScreenXZero + Party.speed * Party.dx * dt
		CameraScreenHeight = CameraScreenHeight + Party.speed * Party.dy * dt
		CameraScreenYZero = CameraScreenYZero + Party.speed * Party.dy * dt
		Fence.x = Fence.x + Party.speed * Party.dx * dt
		Fence.y = Fence.y + Party.speed * Party.dy * dt

		-- Spawn and move bushes
		bushManager()
		moveBushes(dt)
	end

	-- Check if game over
	if PartyHealth <= 0 then
		resetGame()
	end
end

function love.draw()
	if CameraMove then
		-- TODO HOW TO TRANSLATE ONLY IN THE X DIRECTION
		print(-Party.x + PartyXPositionAtStartOfCamMove)
		love.graphics.translate(-Party.x + PartyXPositionAtStartOfCamMove, -Party.y + PartyYPositionAtStartOfCamMove)
	else
		love.graphics.translate(PartyXPositionAtEndOfCamMove, PartyYPositionAtEndOfCamMove)
	end

	-- Screenshake
	-- From sheepolution
	if ShakeDuration > 0 then
		-- Translate with a random number between -5 an 5.
		-- This second translate will be done based on the previous translate.
		-- So it will not reset the previous translate.
		love.graphics.translate(love.math.random(-5,5), love.math.random(-5,5))
	end

	-- Draw Bushes
	for _, bush in ipairs(TableOfBushes) do
		drawBush(bush)
	end

	-- Draw party spawnCone
	

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

	-- Everything that should not be affected by translation should be drawn below
	love.graphics.origin()

	-- Fence movement line
	if Fence.state == FENCE_STATES.moving then
		love.graphics.setColor(TransparentLightBlue)
		love.graphics.line(MouseDragStart.x, MouseDragStart.y, MousePos.x, MousePos.y)
		love.graphics.setColor(White)
	end

	-- Score and Health
	local healthString = "Health: " .. PartyHealth
	love.graphics.print(healthString, ScreenWidth-string.len(healthString) * 7, 0, 0, 1, 1)
	love.graphics.print("Score: " .. Score, 0, 0, 0, 1, 1)
end

function love.keypressed(key)
	-- Reset game
	if key == "r" then
		resetGame()
	end
	
	if key == "space" then
		Fence:rotate()
	end

	-- Debugging spawns
	if DebugMode and key == "f" then
		spawnFireball()
	end

	if DebugMode and key == "d" then
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

		ProjectileShotSfx:play()
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

	ProjectileShotSfx:play()
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

function initBushSpawn()
	for i=0,MaxBushCount do
		local randomX = love.math.random(0, ScreenWidth)
		local randomY = love.math.random(0, ScreenHeight)

		spawnBush(randomX, randomY, BushScale)
	end
end

function bushManager()
	-- Remove bushes when they go off screen
	for i=#TableOfBushes,1,-1 do
		local bush = TableOfBushes[i]

		if bush.x <= CameraScreenXZero or bush.x >= CameraScreenWidth or bush.y <= CameraScreenYZero or bush.y >= CameraScreenHeight then
			table.remove(TableOfBushes, i)
		end
	end

	-- TODO calculate this instead of using table?
	-- X edge of screen table, then Y edge of screen table
	-- Starting from right edge of screen, to right edge and bottom edge, then bottom edge, etc.
	local cameraScreenXZeroBushOffset = CameraScreenXZero + BushOffset
	local cameraScreenYZeroBushOffset = CameraScreenYZero + BushOffset
	local cameraScreenWidthBushOffset = CameraScreenWidth - BushOffset
	local cameraScreenHeightBushOffset = CameraScreenHeight - BushOffset
	local BushSpawnTable = {
		{
			{cameraScreenWidthBushOffset, love.math.random(cameraScreenYZeroBushOffset, cameraScreenHeightBushOffset)},
			{love.math.random(cameraScreenXZeroBushOffset, cameraScreenWidthBushOffset), cameraScreenHeightBushOffset},
		},
		{
			{cameraScreenWidthBushOffset, love.math.random(cameraScreenYZeroBushOffset, cameraScreenHeightBushOffset)},
			{cameraScreenWidthBushOffset, love.math.random(cameraScreenYZeroBushOffset, cameraScreenHeightBushOffset)},
		}
	}

	-- Spawning based off of party direction of travel
	-- We only want to spawn on edges of screen, so this var decides that
	local xOrYEdgeSpawn = love.math.random(2)
	if #TableOfBushes <= MaxBushCount then
		-- Right edge of screen
		if Party.dx >= 0.8 then
			spawnBush(BushSpawnTable[xOrYEdgeSpawn][1][1], BushSpawnTable[xOrYEdgeSpawn][1][2], BushScale)
		-- Right and bottom edge of screen
		elseif Party.dx < 0.8 and Party.dy > 0 then
			spawnBush(BushSpawnTable[xOrYEdgeSpawn][2][1], BushSpawnTable[xOrYEdgeSpawn][2][2], BushScale)
		end
	end
end

function spawnBush(x, y, scale)
	table.insert(TableOfBushes, {x=x, y=y, r=love.math.random(0, 2 * math.pi), scale=scale})
end

function drawBush(bush)
	love.graphics.draw(BushImg, bush.x, bush.y, bush.r, bush.scale, bush.scale, BushImg:getWidth() / 2, BushImg:getHeight() / 2)
end

function moveBushes(dt)
	for _, bush in ipairs(TableOfBushes) do
		bush.x = bush.x + Party.speed * -Party.dx * dt
		bush.y = bush.y + Party.speed * -Party.dy * dt
	end
end

function resetGame()
	GameState = GAME_STATES.done
	Song:stop()
	love.load()
end

-- -- make error handling nice
local love_errorhandler = love.errorhandler
function love.errorhandler(msg)
	if lldebugger then
		error(msg, 2)
	else
		return love_errorhandler(msg)
	end
end