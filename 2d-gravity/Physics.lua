-- name: Physics.lua
-- description: Handles physics calculations for 2D gravity simulation
-- author: Ramona Melfry
-- script: lua


Physics = {

    G = 0.07,           -- scaled gravitational constant
    C = 2.5,           -- "speed of light" (in pixels per frame)

    TIME_SCALE = 1.0,

    SOFTENING = 150
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


