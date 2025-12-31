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
        local alpha = i / #body.trail
        local color = body.mass % 16
        circ(point.x, point.y, alpha, color)  -- adjust size as needed
    end
end

function GFX.drawAllBodies()
    for _, body in pairs(Objects.Body) do
        circ(body.x, body.y, body.mass * GFX.OBJECT_SCALE_FACTOR, body.mass % 16)
        GFX.drawTrail(body)
    end
end

