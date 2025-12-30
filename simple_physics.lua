Objects = { 

    Body = { },
    last_object_ID = 0,

    -- CONSTANTS --

    MAX_OBJECT_COUNT = 50,
    MAX_OBJECT_SIZE = 1000

}


function Objects.createBody(x, y, mass, vx, vy, type)
    local object = {
        ID = Objects.last_object_ID,
        x = x,
        y = y,
        mass = mass,
        vx = vx or 0,
        vy = vy or 0,
        type = type or "default",
        trail = { }

    }

    Objects.last_object_ID = Objects.last_object_ID + 1
    return object
end

function Objects.addBody(x, y, mass, type)
    local body = Objects.createBody(x, y, mass, type)
    table.insert(Objects.Body, body)
end

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

function Objects.destroyBody(object_ID)
    for i, body in ipairs(Objects.Body) do
        if body.ID == object_ID then
            table.remove(Objects.Body, i)
            return
        end
    end
end

function Objects.destroyBodyAtPosition(x, y)
    local object_ID = Objects.getBodyAtPosition(x, y)
    if object_ID then
        Objects.destroyBody(object_ID)
    end
end

function Objects.combineMass(body1, body2)
    local combinedMass = body1.mass + body2.mass
    local combinedX = (body1.x * body1.mass + body2.x * body2.mass) / combinedMass
    local combinedY = (body1.y * body1.mass + body2.y * body2.mass) / combinedMass

    local newBody = Objects.createBody(combinedX, combinedY, combinedMass)

    Objects.destroyBody(body1.ID)
    Objects.destroyBody(body2.ID)

    table.insert(Objects.Body, newBody)
end

function Objects.updateTrail(body)
    table.insert(body.trail, {x=body.x, y=body.y})
    if #body.trail > GFX.MAX_TRAIL_LENGTH then
        table.remove(body.trail, 1)
    end
end

function Objects.removeOutOfBounds()
    for i = #Objects.Body, 1, -1 do
        local body = Objects.Body[i]
        if body.x < 0 or body.x > 240 or body.y < 0 or body.y > 136 then
            table.remove(Objects.Body, i)
        end
    end
end

function Objects.removeLargeBodies()
    for i = #Objects.Body, 1, -1 do
        local body = Objects.Body[i]
        if body.mass > Objects.MAX_OBJECT_SIZE then
            table.remove(Objects.Body, i)
        end
    end
end

function Objects.checkMaxObjects()
    while #Objects.Body > Objects.MAX_OBJECT_COUNT do
        table.remove(Objects.Body, 1)
    end
end

function Objects.cleanup()
    Objects.removeOutOfBounds()
    Objects.removeLargeBodies()
    Objects.checkMaxObjects()
end



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


GFX = { 

    -- CONSTANTS --

    OBJECT_SCALE_FACTOR = 0.1,

    MAX_TRAIL_LENGTH = 20,

    PALETTE = {
        WHITE = 12
    }

}

function GFX.drawTrail(body)
    for i, point in ipairs(body.trail) do
        -- Draw a fading circle or point
        local alpha = i / #body.trail  -- from 0 to 1
        local color = body.mass % 16  -- or use a color based on mass
        circ(point.x, point.y, alpha, color)  -- adjust size as needed
    end
end

function GFX.drawAllBodies()
    for _, body in pairs(Objects.Body) do
        circ(body.x, body.y, body.mass * GFX.OBJECT_SCALE_FACTOR, body.mass % 16)
        GFX.drawTrail(body)
    end
end


UI = { 

    mouse_x = 0,
    mouse_y = 0,
    mouse_left = false,
    mouse_right = false,
    mouse_middle = false

}

function UI.getMouse()
    UI.mouse_x, UI.mouse_y, UI.mouse_left, UI.mouse_middle, UI.mouse_right = mouse()
end


function TIC()

    -- UI --

    UI.getMouse()

    if UI.mouse_left then
        if not Objects.getBodyAtPosition(UI.mouse_x, UI.mouse_y) and #Objects.Body < Objects.MAX_OBJECT_COUNT then
            Objects.addBody(UI.mouse_x, UI.mouse_y, 5 + math.random(0, 10))
        end
    end

    if UI.mouse_right then
        if Objects.getBodyAtPosition(UI.mouse_x, UI.mouse_y) then
            Objects.destroyBodyAtPosition(UI.mouse_x, UI.mouse_y)
        end
    end

    -- UPDATE --

    Physics.updateBodies()
    
    Objects.cleanup()

    -- DRAW --

    cls(0)

    GFX.drawAllBodies()

    -- print total number of objects on screen
    print("Objects: " .. #Objects.Body, 1, 1, GFX.PALETTE.WHITE)


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

