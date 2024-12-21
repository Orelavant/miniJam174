-- Debugger
if arg[2] == "debug" then
	require("lldebugger").start()
end

-- Global variables for physics world and objects
local world
local circle
local rectangle
local circleShape, rectangleShape
local circleFixture, rectangleFixture

function love.load()
    -- Initialize the physics world with no gravity (top-down)
    world = love.physics.newWorld(0, 0, true) -- No gravity (0, 0)

    -- Create a circle body and shape (dynamic, so it can move)
    circle = love.physics.newBody(world, 400, 300, "dynamic") -- Position (400, 300), "dynamic" means it can move
    circleShape = love.physics.newCircleShape(30) -- Radius 30
    circleFixture = love.physics.newFixture(circle, circleShape)

    -- Set initial constant velocity for the circle (move right at 100 pixels per second)
    circle:setLinearVelocity(100, 0)  -- 100 pixels per second to the right

    -- Create a rectangle body and shape (kinematic, so we move it manually with the mouse)
    rectangle = love.physics.newBody(world, 400, 500, "kinematic") -- Position (400, 500), "kinematic" means it can be moved manually
    rectangleShape = love.physics.newRectangleShape(100, 20) -- Width 100, Height 20
    rectangleFixture = love.physics.newFixture(rectangle, rectangleShape)

    -- Set restitution (bounciness) of the circle
    circleFixture:setRestitution(0.8) -- 0.8 means a pretty bouncy circle

    -- Disable collision between circle and rectangle by setting collision groups
    -- Both the circle and the rectangle will belong to different collision groups
    rectangleFixture:setCategory(2)  -- Assign to group 2
    circleFixture:setCategory(1)     -- Assign to group 1
    circleFixture:setMask(2)         -- Only collide with group 2 (rectangle)
end

function love.update(dt)
    -- Update the physics world (circle maintains its velocity)
    world:update(dt)

    -- Move the rectangle with the mouse position
    local mouseX, mouseY = love.mouse.getPosition()
    rectangle:setPosition(mouseX, mouseY)

    -- Manually handle the collision between circle and rectangle
    local cx, cy = circle:getPosition()
    local rx, ry = rectangle:getPosition()

    -- Get the rectangle's points (the four corners of the rectangle)
    local points = {rectangleShape:getPoints()}
    local rw = points[4] - points[2]  -- Calculate width from x points (point 2 and 4)
    local rh = points[5] - points[1]  -- Calculate height from y points (point 1 and 5)

    -- Simple bounding box collision check between the circle and rectangle
    if cx + circleShape:getRadius() > rx - rw / 2 and cx - circleShape:getRadius() < rx + rw / 2 and
       cy + circleShape:getRadius() > ry - rh / 2 and cy - circleShape:getRadius() < ry + rh / 2 then
        -- If there's a collision, calculate bounce direction based on normal
        local dx, dy = circle:getLinearVelocity()

        -- Check the direction of impact (on the x-axis or y-axis)
        if cx + circleShape:getRadius() > rx - rw / 2 and cx - circleShape:getRadius() < rx + rw / 2 then
            -- Circle is colliding with the vertical side of the rectangle
            dx = -dx  -- Reverse horizontal velocity
        end
        if cy + circleShape:getRadius() > ry - rh / 2 and cy - circleShape:getRadius() < ry + rh / 2 then
            -- Circle is colliding with the horizontal side of the rectangle
            dy = -dy  -- Reverse vertical velocity
        end

        -- Apply the updated velocity to simulate bouncing
        circle:setLinearVelocity(dx, dy)
        
        -- Avoid circle overlap after bounce by adjusting its position
        if cx + circleShape:getRadius() > rx - rw / 2 and cx - circleShape:getRadius() < rx + rw / 2 then
            circle:setPosition(cx + circleShape:getRadius(), cy)
        end
        if cy + circleShape:getRadius() > ry - rh / 2 and cy - circleShape:getRadius() < ry + rh / 2 then
            circle:setPosition(cx, cy + circleShape:getRadius())
        end
    end
end

function love.draw()
    -- Draw the circle
    love.graphics.setColor(0, 1, 0) -- Green color
    love.graphics.circle("fill", circle:getX(), circle:getY(), circleShape:getRadius())

    -- Draw the rectangle
    love.graphics.setColor(1, 0, 0) -- Red color
    love.graphics.polygon("fill", rectangle:getWorldPoints(rectangleShape:getPoints()))
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
