-- name: Physics.lua
-- description: Handles physics calculations for 2D gravity simulation
-- author: Ramona Melfry
-- script: lua


Physics = {

    -- CONSTANTS --

    G = 6.67430e-11,
    TIME_SCALE = 100,
    C = 1e+3
 }


-- function to calculate the gravitational force between two bodies
function Physics.calculateGravitationalForce(body1, body2)
    -- calculate distance components
    local dx = body2.x - body1.x
    local dy = body2.y - body1.y
    local distance_sq = dx * dx + dy * dy

    local min_distance_sq = 256  -- minimum distance squared to avoid extreme forces
    distance_sq = math.max(distance_sq, min_distance_sq)
    local distance = math.sqrt(distance_sq) / Physics.TIME_SCALE

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


-- check for speed limit violations
function Physics.limitSpeeds()
    for _, body in pairs(Objects.Body) do
        local speed = math.sqrt(body.vx * body.vx + body.vy * body.vy)
        local maxSpeed = Physics.C * (1 + math.log(1+body.mass/100))

        if speed > maxSpeed then
            local scale = maxSpeed / speed
            body.vx = body.vx * scale
            body.vy = body.vy * scale
        end
    end
end


