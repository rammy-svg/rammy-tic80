-- name: 2d-gravity.lua
-- description: Main file for 2D gravity simulation
-- author: Ramona Melfry
-- script: lua

function BOOT()

    -- set initial palette
    GFX.updatePalette(GFX.PALETTE_INDEX)

    -- create some initial bodies
    Objects.addBody(120, 64, 150, 0, 0, Objects.OBJECT_TYPE.FIXED)  -- large fixed body in center
    Objects.addBody(48, 64, 200, 0, 10, Objects.OBJECT_TYPE.FIXED)      -- smaller body to the left
    Objects.addBody(200, 64, 200, 0, -10, Objects.OBJECT_TYPE.FIXED)    -- smaller body to the right

end


function TIC()

    -- UI --

    UI.getMouse()
    UI.debounceMouse()

     -- add body on left click

    if UI.mouse_left and UI.mouse_clicked then
        if not Objects.getBodyAtPosition(UI.mouse_x, UI.mouse_y) and #Objects.Body < Objects.MAX_OBJECT_COUNT then
            Objects.addBody(UI.mouse_x, UI.mouse_y, 5 + math.random(0, 10), 0, 0, Objects.OBJECT_TYPE.DEFAULT)
        end
    end

    if UI.mouse_right then
        local bodyID = Objects.getBodyAtPosition(UI.mouse_x, UI.mouse_y)
        if bodyID then
            for i, body in pairs(Objects.Body) do
                if body.ID == bodyID and body.type ~= Objects.OBJECT_TYPE.FIXED then
                    Objects.breakBody(body, 3)
                    break
                end
            end
        end
    end

    -- adjust simulation parameters
    UI.changeParameters()

    -- use arrow keys to select palette
    if btnp(0,20,5) and GFX.PALETTE_INDEX>1 then 
		GFX.PALETTE_INDEX=GFX.PALETTE_INDEX-1 
		GFX.updatePalette(GFX.PALETTE_INDEX)
	end

	if btnp(1,20,5) and GFX.PALETTE_INDEX<#GFX.PALETTES then 
		GFX.PALETTE_INDEX=GFX.PALETTE_INDEX+1 
		GFX.updatePalette(GFX.PALETTE_INDEX)
	end

    -- UPDATE --

    Objects.updateBodies()
    Objects.applyEffects()
    Objects.cleanup()

    -- DRAW --

    cls(0)

    GFX.drawFixedBodies()
    GFX.drawAllFX()
    GFX.drawFreeBodies()


    -- DEBUG INFO --

    -- print total number of objects on screen
    print("Objects: " .. #Objects.Body, 1, 1, GFX.PALETTE.WHITE)


    -- print current palette name
    print("Palette: " .. GFX.PALETTES[GFX.PALETTE_INDEX].name, 1, 10, GFX.PALETTE.WHITE)

    -- draw swatches for current palette
    for i=0,15 do
        rect(180 + i * 4, 1, 4, 4, i)
    end

    -- print currently controlled parameter and its value
    local param = "G: "
    local parameter_val = Physics.G

    if UI.current_param == UI.SIM_PARAMETERS.C then
        param = "C: "
        parameter_val = Physics.C
    elseif UI.current_param == UI.SIM_PARAMETERS.TIME_SCALE then
        param = "TIME SCALE: "
        parameter_val = Physics.TIME_SCALE
    elseif UI.current_param == UI.SIM_PARAMETERS.SOFTENING then
        param = "SOFTENING: "
        parameter_val = Physics.SOFTENING
    end

    print(param .. parameter_val, 0, 128, GFX.PALETTE.WHITE)

    -- find the first non-fixed body
    local first_free_body = nil
    for _, body in pairs(Objects.Body) do
        if body.type ~= Objects.OBJECT_TYPE.FIXED then
            first_free_body = body
            break
        end
    end

    -- print the mass of the first free body

    if first_free_body then
        print("Mass: " .. string.format("%.2f", first_free_body.mass), 100, 128, GFX.PALETTE.WHITE)
    end

    -- print speed and acceleration values of first free body

    if first_free_body then
        local speed = math.sqrt(first_free_body.vx^2 + first_free_body.vy^2)
        local acceleration = math.sqrt(first_free_body.ax^2 + first_free_body.ay^2)
        print("Speed: " .. string.format("%.2f", speed), 100, 118, GFX.PALETTE.WHITE)
        print("Accel: " .. string.format("%.2f", acceleration), 100, 108, GFX.PALETTE.WHITE)
    end

    -- draw speed, acceleration vectors for first free body
    if first_free_body then
        -- speed vector
        local speed_magnitude = math.sqrt(first_free_body.vx^2 + first_free_body.vy^2)
        if speed_magnitude > 0 then
            local speed_scale = speed_magnitude * 5
            line(first_free_body.x, first_free_body.y,
                 first_free_body.x + first_free_body.vx * speed_scale,
                 first_free_body.y + first_free_body.vy * speed_scale,
                 GFX.PALETTE.WHITE)
        end

        -- acceleration vector
        local accel_magnitude = math.sqrt(first_free_body.ax^2 + first_free_body.ay^2)
        if accel_magnitude > 0 then
            local accel_scale = accel_magnitude * 500
            line(first_free_body.x, first_free_body.y,
                 first_free_body.x + first_free_body.ax * accel_scale,
                 first_free_body.y + first_free_body.ay * accel_scale,
                 GFX.PALETTE.RED)
        end
    end

end

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
function Objects.resolveCollisionsNew(body1, body2)
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
            Objects.combineBodies(body1, body2)
        elseif collision_type == Objects.COLLISION_TYPE.BOUNCE then
            Physics.calculateElasticCollision(body1, body2)
        elseif collision_type == Objects.COLLISION_TYPE.BREAK then
            local larger_body = body1.mass > body2.mass and body1 or body2
            table.insert(GFX.Effects, {x=larger_body.x, y=larger_body.y, color=GFX.PALETTE.YELLOW, magnitude=8, duration=1.5})
            Objects.breakBody(larger_body, 3)
        elseif collision_type == Objects.COLLISION_TYPE.EXPLODE then
            table.insert(GFX.Effects, {x=(body1.x + body2.x)/2, y=(body1.y + body2.y)/2, color=GFX.PALETTE.YELLOW, magnitude=10, duration=1.5})
            Objects.breakBody(body1, 3)
            Objects.breakBody(body2, 3)
        elseif collision_type == Objects.COLLISION_TYPE.ABSORB then
            local larger_body = body1.mass > body2.mass and body1 or body2
            local smaller_body = body1.mass > body2.mass and body2 or body1
            table.insert(GFX.Effects, {x=smaller_body.x, y=smaller_body.y, color=GFX.PALETTE.YELLOW, magnitude=5, duration=1})
            Objects.destroyBody(smaller_body.ID)
        end

    end
end





-- new function for resolving collisions, taking into account mass and velocities
function Objects.resolveCollisions(body1, body2)
    if math.random(Objects.REACTIVITY) == 1 and Objects.checkCollision(body1, body2) then
        -- check for fixed bodies
        if body1.type == Objects.OBJECT_TYPE.FIXED or body2.type == Objects.OBJECT_TYPE.FIXED then
            return
        end
        
        -- two small bodies combine at low speeds, destroy each other at high speeds
        if body1.mass < 20 and body2.mass < 20 then
            local relative_speed = math.sqrt((body1.vx - body2.vx)^2 + (body1.vy - body2.vy)^2)

            if relative_speed < 1 then
                Objects.combineBodies(body1, body2)
            else
                last_x = (body1.x + body2.x) / 2
                last_y = (body1.y + body2.y) / 2
                table.insert(GFX.Effects, {x=last_x, y=last_y, color=GFX.PALETTE.YELLOW, magnitude=5, duration=1})
                Objects.destroyBody(body1.ID)
                Objects.destroyBody(body2.ID)
            end


        -- smaller bodies are absorbed by larger bodies
        elseif body1.mass ~= body2.mass then
            local larger_body = body1.mass > body2.mass and body1 or body2
            local smaller_body = body1.mass > body2.mass and body2 or body1

        -- large bodies have a chance to break apart when colliding with a smaller body at high speeds
            if (body1.mass >= 20 or body2.mass >= 20) and math.random(3) == 1 then
                local smaller_body = body1.mass > body2.mass and body2 or body1
                local smaller_body_speed = math.sqrt(smaller_body.vx * smaller_body.vx + smaller_body.vy * smaller_body.vy)
                if smaller_body_speed > 0.5 then
                    table.insert(GFX.Effects, {x=smaller_body.x, y=smaller_body.y, color=GFX.PALETTE.YELLOW, magnitude=10, duration=1.5})
                    Objects.breakBody(smaller_body, 3)
                end
            else
                table.insert(GFX.Effects, {x=smaller_body.x, y=smaller_body.y, color=GFX.PALETTE.YELLOW, magnitude=5, duration=1})
                Objects.combineBodies(larger_body, smaller_body)
            end

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

    -- update trails
    for _, body in pairs(Objects.Body) do
        Objects.updateTrail(body)
    end


    -- resolve collisions
    for _, body1 in pairs(Objects.Body) do
        for _, body2 in pairs(Objects.Body) do
            if body1.ID ~= body2.ID then
                Objects.resolveCollisionsNew(body1, body2)
            end
        end
    end


    -- limit speeds
    Physics.limitSpeeds()

    
end

-- name: Physics.lua
-- description: Handles physics calculations for 2D gravity simulation
-- author: Ramona Melfry
-- script: lua


Physics = {

    G = 0.1,           -- scaled gravitational constant
    C = 4.5,           -- "speed of light" (in pixels per frame)

    TIME_SCALE = 0.5,

    SOFTENING = 40
}

function Physics.calculateGravitationalForce(body1, body2)
    local dx = body2.x - body1.x
    local dy = body2.y - body1.y
    local distance_sq = dx * dx + dy * dy
    
    -- Apply softening to prevent extreme forces at close range
    local softened_distance_sq = distance_sq + Physics.SOFTENING
    
    -- Force calculation with adjusted G
    local force = Physics.G * (body1.mass * body2.mass) / softened_distance_sq
    
    -- Normalize direction vector
    local inv_distance = 1 / math.sqrt(softened_distance_sq)
    local forceX = force * dx * inv_distance
    local forceY = force * dy * inv_distance
    
    return forceX, forceY
end

function Physics.calculateElasticCollision(body1, body2)
    -- Calculate collision normal
    local dx = body2.x - body1.x
    local dy = body2.y - body1.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    if distance == 0 then return end
    
    local nx = dx / distance
    local ny = dy / distance
    
    -- Separate bodies to prevent sticking
    local overlap = (body1.mass + body2.mass) * GFX.OBJECT_SCALE_FACTOR - distance
    if overlap > 0 then
        local separation = overlap * 0.5
        if body1.type ~= Objects.OBJECT_TYPE.FIXED then
            body1.x = body1.x - nx * separation
            body1.y = body1.y - ny * separation
        end
        if body2.type ~= Objects.OBJECT_TYPE.FIXED then
            body2.x = body2.x + nx * separation
            body2.y = body2.y + ny * separation
        end
    end
    
    -- Relative velocity
    local dvx = body2.vx - body1.vx
    local dvy = body2.vy - body1.vy
    
    -- Velocity along collision normal
    local velocity_along_normal = dvx * nx + dvy * ny
    
    -- Do not resolve if velocities are separating
    if velocity_along_normal > 0 then return end
    
    -- Calculate impulse scalar (with restitution coefficient)
    local restitution = 0.8  -- Bounciness (0-1)
    local impulse = -(1 + restitution) * velocity_along_normal
    impulse = impulse / (1/body1.mass + 1/body2.mass)
    
    -- Apply impulse
    local impulse_x = impulse * nx
    local impulse_y = impulse * ny
    
    if body1.type ~= Objects.OBJECT_TYPE.FIXED then
        body1.vx = body1.vx - impulse_x / body1.mass
        body1.vy = body1.vy - impulse_y / body1.mass
    end
    

    if body2.type ~= Objects.OBJECT_TYPE.FIXED then
        body2.vx = body2.vx + impulse_x / body2.mass
        body2.vy = body2.vy + impulse_y / body2.mass
    end
end



function Physics.limitSpeeds()
    for _, body in pairs(Objects.Body) do
        local speed = math.sqrt(body.vx * body.vx + body.vy * body.vy)

        if speed > Physics.C then
            -- scale down velocity to the speed of light
            local scale = Physics.C / speed
            body.vx = body.vx * scale
            body.vy = body.vy * scale
        end
    end
end


-- name: GFX.lua
-- description: Handles graphics rendering for 2D gravity simulation
-- author: Ramona Melfry, Nesbox
-- script: lua
-- notes: palette scripts and data from TIC-80 demos


GFX = { 

    Effects = { },

        -- CONSTANTS --

    EFFECTS = {
        PULSE = 1,
        GLOW = 2
    },

    PALETTE_INDEX = 1,
    
    PALETTE_ADDRESS=0x3FC0,
    
    PALETTE = {
        RED = 2,
        YELLOW = 4,
        WHITE = 15
    },

    PALETTES = {
        {name="SWEETIE-16", data="1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7333c57566c8694b0c2f4f4f4"},
        {name="DB16",		data="140c1c44243430346d4e4a4e854c30346524d04648757161597dced27d2c8595a16daa2cd2aa996dc2cadad45edeeed6"},
        {name="PICO-8",     data="0000007e25531d2b535f574fab5236008751ff004d83769cff77a8ffa300c2c3c700e756ffccaa29adfffff024fff1e8"},
        {name="ARNE16",     data="0000001b2632005784493c2ba4642244891abe26332f484e31a2f2eb89319d9d9da3ce27e06f8bb2dceff7e26bffffff"},
        {name="EDG16",	    data="193d3f3f2832743f399e2835b86f50327345e53b444f67810484d1fb922bafbfd263c64de4a6722ce8f4ffe762ffffff"},
        {name="A64",	    data="0000004c3435313a9148545492562b509450b148638080787655a28385cf9cabb19ccc47cd93738fbfd5bbc840ede6c8"},
        {name="C64",		data="00000057420040318d5050508b542955a0498839327878788b3f967869c49f9f9f94e089b8696267b6bdbfce72ffffff"},
        {name="VIC20",      data="000000772d2642348ba85fb4b668627e70caa8734a559e4ae99df5e9b287bdcc7185d4dc92df87c5ffffffffb0ffffff"},
        {name="CGA",        data="000000aa00000000aa555555aa550000aa00ff5555aaaaaa5555ffaa00aa00aaaa55ff55ff55ff55ffffffff55ffffff"},
        {name="SLIFE",      data="0000001226153f28117a2222513155d13b27286fb85d853acc8218e07f8a9b8bff68c127c7b581b3e868a8e4d4ffffff"},
        {name="JMP",        data="000000191028833129453e78216c4bdc534b7664fed365c846af45e18d79afaab9d6b97b9ec2e8a1d685e9d8a1f5f4eb"},
        {name="CGARNE",     data="0000002234d15c2e788a36225e606e0c7e45e23d69aa5c3d4c81fb44aacceb8a60b5b5b56cd9477be2f9ffd93fffffff"},
        {name="PSYG",       data="0000001b1e29003308362747084a3c443f41a2324e52524c546a0073615064647c516cbf77785be08b799ea4a7cbe8f7"},
        {name="EROGE",      data="0d080d2a23494f2b247d384032535f825b314180a0c16c5bc591547bb24e74adbbe89973bebbb2f0bd77fbdf9bfff9e4"},
        {name="EISLAND",    data="051625794765686086567864ca657e8686918184abcc8d867ea78839d4b98dbcd29dc085edc38de6d1d1f5e17af6f6bf"},
    },

    OBJECT_SCALE_FACTOR = 0.1,

    MAX_TRAIL_LENGTH = 20,

}


-- draws the trail of a body
function GFX.drawTrail(body)
    for i, point in ipairs(body.trail) do
        local color = (body.mass % 16)
        pix(point.x, point.y, color)
    end
end


-- draws a larger circle around a body that pulses
function GFX.drawPulse(body, speed, color)
    local t = time()
    local pulseSize = 2 + math.sin(t * speed) 
    circ(body.x, body.y, body.mass * GFX.OBJECT_SCALE_FACTOR + pulseSize, color)
end


-- draws a pulse at the given position
function GFX.drawExplosion(x, y, color, maxSize, duration)
    local t = time()
    local elapsed = (t % duration)
    local size = (elapsed / duration) * maxSize
    local offset_x = math.random(-2, 2)
    local offset_y = math.random(-2, 2)
    circ(x + offset_x, y + offset_y, size, color)
end

-- draws all free bodies in the simulation
function GFX.drawFreeBodies()
    for _, body in pairs(Objects.Body) do
        if body.type ~= Objects.OBJECT_TYPE.FIXED then
            local color = body.mass % 16
            -- check if same as background color
            if color < 1 then
                color = GFX.PALETTE.WHITE
            end

            GFX.drawTrail(body)
            circ(body.x, body.y, body.mass * GFX.OBJECT_SCALE_FACTOR, color)
        end
    end
end


-- draws all fixed bodies in the simulation
function GFX.drawFixedBodies()
    for _, body in pairs(Objects.Body) do
        if body.type == Objects.OBJECT_TYPE.FIXED then
            circ(body.x, body.y, body.mass * GFX.OBJECT_SCALE_FACTOR, body.mass % 16)
        end
    end
end

-- update bodies with effects
function GFX.drawAllFX()

    -- handle "aerodynamic heating" effect
    for _, body in pairs(Objects.Body) do
        if body.fx == GFX.EFFECTS.PULSE and body.type ~= Objects.OBJECT_TYPE.FIXED then
            GFX.drawPulse(body, 10, GFX.PALETTE.YELLOW)
        elseif body.fx == GFX.EFFECTS.GLOW and body.type ~= Objects.OBJECT_TYPE.FIXED then
            GFX.drawPulse(body, 5, GFX.PALETTE.WHITE)
        end
    end

    -- handle explosions
    for i = #GFX.Effects, 1, -1 do
        local effect = GFX.Effects[i]
        GFX.drawExplosion(effect.x, effect.y, effect.color, effect.magnitude, effect.duration)
        effect.duration = effect.duration - 0.1
        if effect.duration <= 0 then
            table.remove(GFX.Effects, i)
        end
    end
    
end


-- updates the palette to the selected one
function GFX.updatePalette(index)
	local palette=GFX.PALETTES[index].data
	for i=1,#palette,2 do
		poke(GFX.PALETTE_ADDRESS+i//6*3+i//2%3,tonumber(palette:sub(i,i+1),16))
	end	
end

-- name: UI.lua
-- description: Handles all UI interactions and components for 2D gravity simulation
-- author: Ramona Melfry
-- script: lua


UI = { 


    -- KEYBOARD --

    INPUT = {
        KB_1 = 28,
        KB_2 = 29,
        KB_3 = 30,
        KB_4 = 31
    },

    -- MOUSE STATE --

    mouse_x = 0,
    mouse_y = 0,
    mouse_left = false,
    mouse_right = false,
    mouse_middle = false,
    mouse_scroll_x = 0,
    mouse_scroll_y = 0,

    mouse_clicked = false,
    mouse_released = false,
    mouse_pressed = false,


    -- SIMULATION CONTROL --

        
    SIM_PARAMETERS = {
        G = 0,
        C = 1,
        TIME_SCALE = 2,
        SOFTENING = 3
    },

    current_param = 0

}


-- updates the current mouse state
function UI.getMouse()
    UI.mouse_x, UI.mouse_y, UI.mouse_left, UI.mouse_middle, UI.mouse_right, UI.mouse_scroll_x, UI.mouse_scroll_y = mouse()
end


-- debounce single mouseclicks/releases
function UI.debounceMouse()
    if UI.mouse_left or UI.mouse_right or UI.mouse_middle then
        if not UI.mouse_pressed then
            UI.mouse_clicked = true
            UI.mouse_released = false
            UI.mouse_pressed = true
        else
            UI.mouse_clicked = false
            UI.mouse_released = false
        end
    else
        if UI.mouse_pressed then
            UI.mouse_released = true
            UI.mouse_clicked = false
            UI.mouse_pressed = false
        else
            UI.mouse_released = false
            UI.mouse_clicked = false
        end
    end
end


-- functions for detecting mouse scroll
function UI.checkScrollWheel()
    local up = false
    local down = false
    local left = false
    local right = false
    
    if UI.mouse_scroll_y > 0 then
        up = true
    elseif UI.mouse_scroll_y < 0 then
        down = true
    elseif UI.mouse_scroll_x < 0 then
        left = true
    elseif UI.mouse_scroll_x > 0 then
        right = true
    end

    return up, down, left, right
end



    -- MODULE SPECIFIC FUNCTIONS --

-- function for changing simulation parameters with the scroll wheel
function UI.changeParameters()
    local units = 1
    local operation = "add"
    local target = "G"


    -- change current parameter
    if keyp(UI.INPUT.KB_1) then
        UI.current_param = UI.SIM_PARAMETERS.G
    elseif keyp(UI.INPUT.KB_2) then
        UI.current_param = UI.SIM_PARAMETERS.C
    elseif keyp(UI.INPUT.KB_3) then
        UI.current_param = UI.SIM_PARAMETERS.TIME_SCALE
    elseif keyp(UI.INPUT.KB_4) then
        UI.current_param = UI.SIM_PARAMETERS.SOFTENING
    end

    if UI.current_param == UI.SIM_PARAMETERS.G then
        target = "G"
    elseif UI.current_param == UI.SIM_PARAMETERS.C then
        target = "C"
    elseif UI.current_param == UI.SIM_PARAMETERS.TIME_SCALE then
        target = "time_scale"
    elseif UI.current_param == UI.SIM_PARAMETERS.SOFTENING then
        target = "soft"
    end

    if UI.mouse_scroll_y > 0 then
        if target == "G" then
            Physics.G = Physics.G + 0.01
        elseif target == "C" then
            Physics.C = Physics.C + 1
        elseif target == "time_scale" then
            Physics.TIME_SCALE = Physics.TIME_SCALE * 2
        elseif target == "soft" then
            Physics.SOFTENING = Physics.SOFTENING + 10
        end
    elseif UI.mouse_scroll_y < 0 then
        if target == "G" then
            Physics.G = Physics.G - 0.01
        elseif target == "C" and Physics.C > 0 then
            Physics.C = Physics.C - 1
        elseif target == "time_scale" then
            Physics.TIME_SCALE = Physics.TIME_SCALE / 2
        elseif target == "soft" and Physics.SOFTENING > 0 then
            Physics.SOFTENING = Physics.SOFTENING - 10
        end
    end

end


-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

