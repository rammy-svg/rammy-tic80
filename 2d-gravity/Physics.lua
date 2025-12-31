Physics = {

    G = 6.67430e-8,

    TIME_SCALE = 100

 }


function Physics.calculateGravitationalForce(body1, body2)
    local dx = body2.x - body1.x
    local dy = body2.y - body1.y
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance == 0 then
        return 0, 0
    end

    local force = Physics.G * (body1.mass * body2.mass) / (distance * distance)
    local angle = math.atan2(dy, dx)

    local forceX = force * math.cos(angle)
    local forceY = force * math.sin(angle)

    return forceX, forceY
end


function Physics.updateBodies()

    for _, body in pairs(Objects.Body) do
        body.ax = 0
        body.ay = 0
    end

    for _, body1 in pairs(Objects.Body) do
        for _, body2 in pairs(Objects.Body) do
            if body1.ID ~= body2.ID then
                local forceX, forceY = Physics.calculateGravitationalForce(body1, body2)
                body1.ax = body1.ax + forceX / body1.mass
                body1.ay = body1.ay + forceY / body1.mass
            end
        end
    end

    -- Then, update velocity and position
    for _, body in pairs(Objects.Body) do
        body.vx = body.vx + (body.ax * Physics.TIME_SCALE)
        body.vy = body.vy + (body.ay * Physics.TIME_SCALE)
        body.x = body.x + (body.vx * Physics.TIME_SCALE)
        body.y = body.y + (body.vy * Physics.TIME_SCALE)
    end

    -- finally update trails
    for _, body in pairs(Objects.Body) do
        Objects.updateTrail(body)
    end
    
end

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

