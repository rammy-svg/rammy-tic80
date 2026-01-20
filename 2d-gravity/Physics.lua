-- name: Physics.lua
-- description: Handles physics calculations for 2D gravity simulation
-- author: Ramona Melfry
-- script: lua


Physics = {

    -- CONSTANTS --

    G = 6.67430e-11,
    TIME_SCALE = 100,
    C = 100
 }


-- function to calculate the gravitational force between two bodies
function Physics.calculateGravitationalForce(body1, body2)
    -- calculate distance components
    local dx = body2.x - body1.x
    local dy = body2.y - body1.y
    local distance = math.sqrt(dx * dx + dy * dy) / Physics.TIME_SCALE

    -- avoid division by zero
    if distance == 0 then
        return 0, 0
    end

    -- calculate gravitational force magnitude
    local force = Physics.G * (body1.mass * body2.mass) / (distance * distance)
    local angle = math.atan2(dy, dx)

    -- convert force magnitude to X and Y components
    local forceX = force * math.cos(angle)
    local forceY = force * math.sin(angle)

    return forceX, forceY
end


-- update all bodies' positions
function Physics.updateBodies()

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

    -- finally update trails
    for _, body in pairs(Objects.Body) do
        Objects.updateTrail(body)
    end
    
end


-- check for speed limit violations
function Physics.limitSpeeds()
    for _, body in pairs(Objects.Body) do
        local speed = math.sqrt(body.vx * body.vx + body.vy * body.vy)
        local maxSpeed = Physics.C * body.mass

        if speed > maxSpeed then
            local scale = maxSpeed / speed
            body.vx = body.vx * scale
            body.vy = body.vy * scale
        end
    end
end



-- resolve collisions between bodies (currently combines masses and is not implemented)
function Physics.resolveCollisions()
    local bodiesToCombine = { }

    for i = 1, #Objects.Body do
        for j = i + 1, #Objects.Body do
            local body1 = Objects.Body[i]
            local body2 = Objects.Body[j]

            local dx = body2.x - body1.x
            local dy = body2.y - body1.y
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance < (body1.mass + body2.mass) / 10 then
                table.insert(bodiesToCombine, {body1, body2})
            end
        end
    end

    for _, pair in pairs(bodiesToCombine) do
        Objects.combineMass(pair[1], pair[2])
    end

end

