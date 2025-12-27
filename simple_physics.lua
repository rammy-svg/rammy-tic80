Objects = { 

    Body = { },
    last_object_ID = 0,
    max_object_count = 50

}


function Objects.createBody(x, y, mass)
    local object = {
        ID = Objects.last_object_ID,
        x = x,
        y = y,
        mass = mass,
        accel = 0
    }

    Objects.last_object_ID = Objects.last_object_ID + 1
    return object
end

function Objects.addBody(x, y, mass)
    local body = Objects.createBody(x, y, mass)
    table.insert(Objects.Body, body)
end

function Objects.getBodyAtPosition(x, y)
    for _, body in pairs(Objects.Body) do
        if body.x == x and body.y == y then
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

function Objects.combineBodies(body1, body2)
    local combinedMass = body1.mass + body2.mass
    local combinedX = (body1.x * body1.mass + body2.x * body2.mass) / combinedMass
    local combinedY = (body1.y * body1.mass + body2.y * body2.mass) / combinedMass

    local newBody = Objects.createBody(combinedX, combinedY, combinedMass)

    Objects.destroyBody(body1.ID)
    Objects.destroyBody(body2.ID)

    table.insert(Objects.Body, newBody)
end


Physics = {

    G = 6.67430e-2

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
    for i, body1 in pairs(Objects.Body) do
        local totalForceX = 0
        local totalForceY = 0

        for j, body2 in pairs(Objects.Body) do
            if i ~= j then
                local forceX, forceY = Physics.calculateGravitationalForce(body1, body2)
                totalForceX = totalForceX + forceX
                totalForceY = totalForceY + forceY
            end
        end

        local accelX = totalForceX / body1.mass
        local accelY = totalForceY / body1.mass

        body1.x = body1.x + accelX
        body1.y = body1.y + accelY
    end

    Physics.resolveCollisions()
    Physics.removeOutOfBounds()
    Physics.removeLargeBodies()
    Physics.checkMaxObjects()

end

function Physics.removeLargeBodies()
    for i = #Objects.Body, 1, -1 do
        local body = Objects.Body[i]
        if body.mass > 100 then
            table.remove(Objects.Body, i)
        end
    end
end

function Physics.removeOutOfBounds()
    for i = #Objects.Body, 1, -1 do
        local body = Objects.Body[i]
        if body.x < 0 or body.x > 240 or body.y < 0 or body.y > 136 then
            table.remove(Objects.Body, i)
        end
    end
end

function Physics.checkMaxObjects()
    while #Objects.Body > Objects.max_object_count do
        table.remove(Objects.Body, 1)
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
        Objects.combineBodies(pair[1], pair[2])
    end

end


GFX = { 

    PALETTE = {
        WHITE = 12
    }

}

function GFX.drawAllBodies()
    for _, body in pairs(Objects.Body) do
        circ(body.x, body.y, body.mass / 10, body.mass % 16)
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

    UI.getMouse()


    if UI.mouse_left then
        if not Objects.getBodyAtPosition(UI.mouse_x, UI.mouse_y) and #Objects.Body < Objects.max_object_count then
            Objects.addBody(UI.mouse_x, UI.mouse_y, 5 + math.random(0, 10))
        end
    end

    if UI.mouse_right then
        if Objects.getBodyAtPosition(UI.mouse_x, UI.mouse_y) then
            Objects.destroyBodyAtPosition(UI.mouse_x, UI.mouse_y)
        end
    end

    Physics.updateBodies()

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

