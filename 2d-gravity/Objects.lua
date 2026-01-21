-- name: Objects.lua
-- description: Handles object creation and management for 2D gravity simulation
-- author: Ramona Melfry
-- script: lua


Objects = { 

    Body = { },
    last_object_ID = 0,

    -- CONSTANTS --

    MAX_OBJECT_COUNT = 50,
    MAX_OBJECT_SIZE = 1000

}


-- creates a new body object
function Objects.createBody(x, y, mass, vx, vy, type)
    local object = {
        ID = Objects.last_object_ID,
        
        x = x,
        y = y,
        
        mass = mass,
        vx = vx or 0,
        vy = vy or 0,
        ax = 0,
        ay = 0,
        
        type = type or "default",

        trail = { },
        fx = nil

    }

    Objects.last_object_ID = Objects.last_object_ID + 1
    return object
end


-- adds a new body to the current simulation
function Objects.addBody(x, y, mass, vx, vy, type)
    local body = Objects.createBody(x, y, mass, vx, vy, type)
    table.insert(Objects.Body, body)
end


-- destroys the body with the given ID
function Objects.destroyBody(object_ID)
    for i, body in ipairs(Objects.Body) do
        if body.ID == object_ID then
            table.remove(Objects.Body, i)
            return
        end
    end
end




-- returns the ID of the body at the given position, or nil if none
function Objects.getBodyAtPosition(x, y)
    for _, body in pairs(Objects.Body) do
        local min_x = body.x - (body.mass * GFX.OBJECT_SCALE_FACTOR)
        local max_x = body.x + (body.mass * GFX.OBJECT_SCALE_FACTOR)
        local min_y = body.y - (body.mass * GFX.OBJECT_SCALE_FACTOR)
        local max_y = body.y + (body.mass * GFX.OBJECT_SCALE_FACTOR)

        if x >= min_x and x <= max_x and y >= min_y and y <= max_y then
            return body.ID
        end
    end
    return nil
end


-- destroys the body at the given position
function Objects.destroyBodyAtPosition(x, y)
    local object_ID = Objects.getBodyAtPosition(x, y)
    if object_ID then
        Objects.destroyBody(object_ID)
    end
end




-- updates the trail of a body
function Objects.updateTrail(body)
    table.insert(body.trail, {x=body.x, y=body.y})
    if #body.trail > GFX.MAX_TRAIL_LENGTH then
        table.remove(body.trail, 1)
    end
end


-- applies an effect to a body when it is accelerating rapidly
function Objects.applyEffects()
    for _, body in pairs(Objects.Body) do
        local acceleration = math.sqrt(body.ax * body.ax + body.ay * body.ay)
        if acceleration > 0.0000002 then
            body.fx = "pulse"
        else
            body.fx = nil
        end
    end
end



-- check for collision between two bodies
function Objects.checkCollision(body1, body2)
    local dx = body1.x - body2.x
    local dy = body1.y - body2.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local minDistance = (body1.mass + body2.mass) * GFX.OBJECT_SCALE_FACTOR
    return distance < minDistance
end


-- resolve collision between two bodies (1 in 3 chance to destroy both)
function Objects.resolveCollisions(body1, body2)
    if Objects.checkCollision(body1, body2) then
        if math.random(3) == 1 and body1.type ~= "fixed" and body2.type ~= "fixed" then
            last_x = (body1.x + body2.x) / 2
            last_y = (body1.y + body2.y) / 2
            table.insert(GFX.Effects, {x=last_x, y=last_y, color=GFX.PALETTE.YELLOW, magnitude=5, duration=1})

            Objects.destroyBody(body1.ID)
            Objects.destroyBody(body2.ID)
        end
    end
end

-- removes bodies that are out of bounds
function Objects.removeOutOfBounds()
    for i = #Objects.Body, 1, -1 do
        local body = Objects.Body[i]
        if body.x < 0 or body.x > 240 or body.y < 0 or body.y > 136 then
            table.remove(Objects.Body, i)
        end
    end
end


-- function for screen wrap
function Objects.screenWrap(body)
    for _, body in pairs(Objects.Body) do
        if body.x < 0 then
            body.x = 240
        elseif body.x > 240 then
            body.x = 0
        end

        if body.y < 0 then
            body.y = 136
        elseif body.y > 136 then
            body.y = 0
        end
    end
end


-- removes bodies that exceed the maximum size
function Objects.removeLargeBodies()
    for i = #Objects.Body, 1, -1 do
        local body = Objects.Body[i]
        if body.mass > Objects.MAX_OBJECT_SIZE then
            table.remove(Objects.Body, i)
        end
    end
end


-- ensures the number of bodies does not exceed the maximum count (for performace reasons)
function Objects.checkMaxObjects()
    while #Objects.Body > Objects.MAX_OBJECT_COUNT do
        table.remove(Objects.Body, 1)
    end
end


-- objects moving at high speeds have a chance to break apart
function Objects.checkMaxSpeeds()
    for i = #Objects.Body, 1, -1 do
        local body = Objects.Body[i]
        local speed = math.sqrt(body.vx * body.vx + body.vy * body.vy)
        local maxSpeed = Physics.C * (1 + math.log(1+body.mass/100))

        if speed > maxSpeed * 1.5 and body.type ~= "fixed" then
            table.insert(GFX.Effects, {x=body.x, y=body.y, color=GFX.PALETTE.RED, magnitude=5, duration=1})
            table.remove(Objects.Body, i)
        end
    end
end

-- performs cleanup operations on the bodies
function Objects.cleanup()
    -- Objects.removeOutOfBounds()
    Objects.screenWrap()
    Objects.removeLargeBodies()
    Objects.checkMaxObjects()
end



-- update all bodies' positions
function Objects.updateBodies()

    -- reset accelerations
    for _, body in pairs(Objects.Body) do
        body.ax = 0
        body.ay = 0
    end

    -- calculate forces between all pairs of bodies
    for _, body1 in pairs(Objects.Body) do
        for _, body2 in pairs(Objects.Body) do
            if body1.ID ~= body2.ID then
                local forceX, forceY = Physics.calculateGravitationalForce(body1, body2)
                body1.ax = body1.ax + forceX / body1.mass
                body1.ay = body1.ay + forceY / body1.mass
            end
        end
    end

    -- update velocity and position
    for _, body in pairs(Objects.Body) do
        if body.type ~= "fixed" then
            body.vx = body.vx + (body.ax * Physics.TIME_SCALE)
            body.vy = body.vy + (body.ay * Physics.TIME_SCALE)
            body.x = body.x + (body.vx * Physics.TIME_SCALE)
            body.y = body.y + (body.vy * Physics.TIME_SCALE)
        end
    end

    -- update trails
    for _, body in pairs(Objects.Body) do
        Objects.updateTrail(body)
    end


    -- resolve collisions
    for _, body1 in pairs(Objects.Body) do
        for _, body2 in pairs(Objects.Body) do
            if body1.ID ~= body2.ID then
                Objects.resolveCollisions(body1, body2)
            end
        end
    end


    -- limit speeds
    Physics.limitSpeeds()

    
end

