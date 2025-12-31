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

