-- name: Objects.lua
-- description: Handles object creation and management for 2D gravity simulation
-- author: Ramona Melfry
-- script: lua


Objects = { 

    Body = { },
    last_object_ID = 0,

    -- CONSTANTS --

    OBJECT_TYPE = { 
        DEFAULT = 1,
        FIXED = 2
    },

    COLLISION_TYPE = {
        DESTROY = 1,
        COMBINE = 2,
        BOUNCE = 3,
        BREAK = 4,
        EXPLODE = 5,
        ABSORB = 6
    },

    REACTIVITY = 10,  -- 1 in x chance to interact with other body on collision

    MAX_OBJECT_COUNT = 50,
    MAX_OBJECT_SIZE = 50

}


-- creates a new body object
function Objects.createBody(x, y, mass, vx, vy, type)
    local object = {
        ID = Objects.last_object_ID,
        
        x = x,
        y = y,
        
        mass = mass,
        temp = 0,
        vx = vx or 0,
        vy = vy or 0,
        ax = 0,
        ay = 0,
        
        type = type or Objects.OBJECT_TYPE.DEFAULT,

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
function Objects.effectHeat()
    for _, body in pairs(Objects.Body) do
        local acceleration = math.sqrt(body.ax * body.ax + body.ay * body.ay)
        if acceleration > 0.025 then
            body.fx = GFX.EFFECTS.PULSE
        else
            body.fx = nil
        end
    end
end


-- objects glow when traveling at high speeds
function Objects.effectGlow()
    for _, body in pairs(Objects.Body) do
        local speed = math.sqrt(body.vx * body.vx + body.vy * body.vy)
        if speed > 0.75 and body.fx ~= GFX.EFFECTS.PULSE then  -- pulse effect has priority
            body.fx = GFX.EFFECTS.GLOW
        elseif body.fx == GFX.EFFECTS.PULSE then
            body.fx = GFX.EFFECTS.PULSE
        else
            body.fx = nil
        end
    end
end


-- applies all effects to free bodies
function Objects.applyEffects()
    Objects.effectHeat()
    Objects.effectGlow()
end


-- check for collision between two bodies
function Objects.checkCollision(body1, body2)
    local dx = body1.x - body2.x
    local dy = body1.y - body2.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local minDistance = (body1.mass + body2.mass) * GFX.OBJECT_SCALE_FACTOR
    return distance < minDistance
end


-- determine the type of collision between two bodies
function Objects.getCollisionType(body1, body2)
    local relative_speed = math.sqrt((body1.vx - body2.vx)^2 + (body1.vy - body2.vy)^2)
    local mass_ratio = math.max(body1.mass, body2.mass) / math.min(body1.mass, body2.mass)
    local mass_threshold = 15

    local larger = body1.mass > body2.mass and body1 or body2
    local smaller = body1.mass > body2.mass and body2 or body1

    -- If the mass ratio is larger than 10:
        -- 1. The smaller body is always destroyed.

    -- If the mass ratio is larger than 3: 
        -- 1. If both bodies have a mass larger than the threshold:
            -- a. At low speeds, bounce off of each other.
            -- b. At high speeds, break the larger body.
        -- 2. If one body has a mass larger than the threshold:
            -- a. Combine both bodies. 
        -- 3. If neither body has a mass larger than the threshold:
            -- a. At low speeds, combine both bodies.
            -- b. At high speeds, destroy both bodies.

    -- Otherwise, if both masses are similar:
        -- 1. If both bodies have a mass larger than the threshold:
            -- a. At low speeds, bounce off of each other.
            -- b. At high speeds, break both bodies (explode).
        -- 2. If both bodies have a mass smaller than the threshold:
            -- a. At low speeds, combine both bodies.
            -- b. At high speeds, destroy both bodies.

    if mass_ratio >= 4 then
        return Objects.COLLISION_TYPE.ABSORB
    elseif mass_ratio >= 1.5 then
        if larger.mass >= mass_threshold and smaller.mass >= mass_threshold then
            if relative_speed < 1.5 then
                return Objects.COLLISION_TYPE.BOUNCE
            else
                return Objects.COLLISION_TYPE.BREAK
            end
        elseif larger.mass >= mass_threshold or smaller.mass >= mass_threshold then
            return Objects.COLLISION_TYPE.COMBINE
        else
            if relative_speed < 1.5 then
                return Objects.COLLISION_TYPE.COMBINE
            else
                return Objects.COLLISION_TYPE.DESTROY
            end
        end
    else
        if body1.mass >= mass_threshold and body2.mass >= mass_threshold then
            if relative_speed < 1.5 then
                return Objects.COLLISION_TYPE.BOUNCE
            else
                return Objects.COLLISION_TYPE.EXPLODE
            end
        else
            if relative_speed < 1.5 then
                return Objects.COLLISION_TYPE.COMBINE
            else
                return Objects.COLLISION_TYPE.DESTROY
            end
        end

    end
   
end


-- newer function for resolving collisions with new flags
function Objects.resolveCollisions(body1, body2)
    if math.random(Objects.REACTIVITY) == 1 and Objects.checkCollision(body1, body2) then
        -- check for fixed bodies
        if body1.type == Objects.OBJECT_TYPE.FIXED or body2.type == Objects.OBJECT_TYPE.FIXED then
            return
        end

        -- get the collision type
        local collision_type = Objects.getCollisionType(body1, body2)

        if collision_type == Objects.COLLISION_TYPE.DESTROY then
            table.insert(GFX.Effects, {x=(body1.x + body2.x)/2, y=(body1.y + body2.y)/2, color=GFX.PALETTE.YELLOW, magnitude=5, duration=1})
            Objects.destroyBody(body1.ID)
            Objects.destroyBody(body2.ID)
        elseif collision_type == Objects.COLLISION_TYPE.COMBINE then
            Physics.calculateElasticCollision(body1, body2)
            Objects.combineBodies(body1, body2)
        elseif collision_type == Objects.COLLISION_TYPE.BOUNCE then
            Physics.calculateElasticCollision(body1, body2)
        elseif collision_type == Objects.COLLISION_TYPE.BREAK then
            local larger_body = body1.mass > body2.mass and body1 or body2
            table.insert(GFX.Effects, {x=larger_body.x, y=larger_body.y, color=GFX.PALETTE.YELLOW, magnitude=8, duration=1.5})
            Physics.calculateElasticCollision(body1, body2)
            Objects.breakBody(larger_body, 3)
        elseif collision_type == Objects.COLLISION_TYPE.EXPLODE then
            table.insert(GFX.Effects, {x=(body1.x + body2.x)/2, y=(body1.y + body2.y)/2, color=GFX.PALETTE.YELLOW, magnitude=10, duration=1.5})
            Objects.breakBody(body1, 3)
            Objects.breakBody(body2, 3)
        elseif collision_type == Objects.COLLISION_TYPE.ABSORB then
            local larger_body = body1.mass > body2.mass and body1 or body2
            local smaller_body = body1.mass > body2.mass and body2 or body1
            table.insert(GFX.Effects, {x=smaller_body.x, y=smaller_body.y, color=GFX.PALETTE.YELLOW, magnitude=5, duration=1})
            Physics.calculateElasticCollision(body1, body2)
            Objects.destroyBody(smaller_body.ID)
        end

    end
end




-- combines the mass of two bodies and averages their velocities
function Objects.combineBodies(body1, body2)
    local total_mass = body1.mass + body2.mass
    local new_vx = (body1.vx * body1.mass + body2.vx * body2.mass) / total_mass
    local new_vy = (body1.vy * body1.mass + body2.vy * body2.mass) / total_mass

    body1.mass = total_mass
    body1.vx = new_vx
    body1.vy = new_vy

    table.insert(GFX.Effects, {x=body2.x, y=body2.y, color=GFX.PALETTE.YELLOW, magnitude=5, duration=1})

    Objects.destroyBody(body2.ID)
end


-- breaks a large body into a specified number of smaller bodies
function Objects.breakBody(body, fragments)
    local fragment_mass = body.mass / fragments
    for i = 1, fragments do
        local angle = math.random() * 2 * math.pi
        local speed = 1 / Physics.TIME_SCALE
        local vx = body.vx + math.cos(angle) * speed
        local vy = body.vy + math.sin(angle) * speed
        Objects.addBody(body.x, body.y, fragment_mass, vx, vy, Objects.OBJECT_TYPE.DEFAULT)
    end
    table.insert(GFX.Effects, {x=body.x, y=body.y, color=GFX.PALETTE.YELLOW, magnitude=8, duration=1.5})
    Objects.destroyBody(body.ID)

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
        if body.mass > Objects.MAX_OBJECT_SIZE and body.type ~= Objects.OBJECT_TYPE.FIXED then
            table.insert(GFX.Effects, {x=body.x, y=body.y, color=GFX.PALETTE.YELLOW, magnitude=10, duration=1.5})
            Objects.breakBody(body, 5)
        end
    end
end


-- ensures the number of bodies does not exceed the maximum count (for performace reasons)
function Objects.checkMaxObjects()
    while #Objects.Body > Objects.MAX_OBJECT_COUNT do
        table.remove(Objects.Body, 1)
    end
end


-- quantizes the size of bodies to discrete steps
function Objects.quantizeBodySizes()
    for _, body in pairs(Objects.Body) do
        body.mass = math.floor(body.mass / 10) * 10
        if body.mass < 10 then
            body.mass = 10
        end
    end
end


-- performs cleanup operations on the bodies
function Objects.cleanup()
    -- Objects.removeOutOfBounds()
    Objects.screenWrap()
    Objects.removeLargeBodies()
    Objects.quantizeBodySizes()
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
        if body.type ~= Objects.OBJECT_TYPE.FIXED then
            body.vx = body.vx + (body.ax * Physics.TIME_SCALE)
            body.vy = body.vy + (body.ay * Physics.TIME_SCALE)
            body.x = body.x + (body.vx * Physics.TIME_SCALE)
            body.y = body.y + (body.vy * Physics.TIME_SCALE)
        end
    end


    -- handle heat effects
    for _, body in pairs(Objects.Body) do
        local speed = math.sqrt(body.vx^2 + body.vy^2)
        if speed > 1.5 then
            body.temp = body.temp + Physics.TIME_SCALE * 5
        elseif body.temp > 0 then
            body.temp = body.temp - Physics.TIME_SCALE * 2
        end

        if body.type ~= Objects.OBJECT_TYPE.FIXED and body.temp > 300 then
            table.insert(GFX.Effects, {x=body.x, y=body.y, color=GFX.PALETTE.WHITE, magnitude=3, duration=1})
            Objects.destroyBody(body.ID)
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

