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


