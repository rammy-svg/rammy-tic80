-- name: 2d-gravity.lua
-- description: Main file for 2D gravity simulation
-- author: Ramona Melfry
-- script: lua

function BOOT()

    -- set initial palette
    GFX.updatePalette(GFX.PALETTE_INDEX)

    -- create some initial bodies
    Objects.addBody(96, 64, 100, 0, 0, "fixed")  -- large fixed body in center
    Objects.addBody(50, 64, 10, 0, 10, "default")      -- smaller body to the left
    Objects.addBody(150, 64, 10, 0, -10, "default")    -- smaller body to the right

end


function TIC()

    -- UI --

    UI.getMouse()

    if UI.mouse_left then
        if not Objects.getBodyAtPosition(UI.mouse_x, UI.mouse_y) and #Objects.Body < Objects.MAX_OBJECT_COUNT then
            Objects.addBody(UI.mouse_x, UI.mouse_y, 5 + math.random(0, 10), 0, 0, "default")
        end
    end

    if UI.mouse_right then
        if Objects.getBodyAtPosition(UI.mouse_x, UI.mouse_y) then
            Objects.destroyBodyAtPosition(UI.mouse_x, UI.mouse_y)
        end
    end

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

    Physics.updateBodies()
    
    Objects.cleanup()

    -- DRAW --

    cls(0)

    GFX.drawAllBodies()


    -- DEBUG INFO --

    -- print total number of objects on screen
    print("Objects: " .. #Objects.Body, 1, 1, GFX.PALETTE.WHITE)


    -- print current palette name
    print("Palette: " .. GFX.PALETTES[GFX.PALETTE_INDEX].name, 1, 10, GFX.PALETTE.WHITE)

    -- draw swatches for current palette
    for i=0,15 do
        rect(180 + i * 4, 1, 4, 4, i)
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

    MAX_OBJECT_COUNT = 50,
    MAX_OBJECT_SIZE = 1000

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
        type = type or "default",
        trail = { }

    }

    Objects.last_object_ID = Objects.last_object_ID + 1
    return object
end


-- adds a new body to the current simulation
function Objects.addBody(x, y, mass, vx, vy, type)
    local body = Objects.createBody(x, y, mass, vx, vy, type)
    table.insert(Objects.Body, body)
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


-- destroys the body with the given ID
function Objects.destroyBody(object_ID)
    for i, body in ipairs(Objects.Body) do
        if body.ID == object_ID then
            table.remove(Objects.Body, i)
            return
        end
    end
end


-- destroys the body at the given position
function Objects.destroyBodyAtPosition(x, y)
    local object_ID = Objects.getBodyAtPosition(x, y)
    if object_ID then
        Objects.destroyBody(object_ID)
    end
end


-- combines two bodies into one with combined mass
function Objects.combineMass(body1, body2)
    local combinedMass = body1.mass + body2.mass
    local combinedX = (body1.x * body1.mass + body2.x * body2.mass) / combinedMass
    local combinedY = (body1.y * body1.mass + body2.y * body2.mass) / combinedMass

    local newBody = Objects.createBody(combinedX, combinedY, combinedMass)

    Objects.destroyBody(body1.ID)
    Objects.destroyBody(body2.ID)

    table.insert(Objects.Body, newBody)
end


-- updates the trail of a body
function Objects.updateTrail(body)
    table.insert(body.trail, {x=body.x, y=body.y})
    if #body.trail > GFX.MAX_TRAIL_LENGTH then
        table.remove(body.trail, 1)
    end
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


-- removes bodies that exceed the maximum size
function Objects.removeLargeBodies()
    for i = #Objects.Body, 1, -1 do
        local body = Objects.Body[i]
        if body.mass > Objects.MAX_OBJECT_SIZE then
            table.remove(Objects.Body, i)
        end
    end
end


-- ensures the number of bodies does not exceed the maximum count (for performace reasons)
function Objects.checkMaxObjects()
    while #Objects.Body > Objects.MAX_OBJECT_COUNT do
        table.remove(Objects.Body, 1)
    end
end


-- performs cleanup operations on the bodies
function Objects.cleanup()
    Objects.removeOutOfBounds()
    Objects.removeLargeBodies()
    Objects.checkMaxObjects()
end

-- name: Physics.lua
-- description: Handles physics calculations for 2D gravity simulation
-- author: Ramona Melfry
-- script: lua


Physics = {

    -- CONSTANTS --

    G = 6.67430e-8,
    TIME_SCALE = 100

 }


-- function to calculate the gravitational force between two bodies
function Physics.calculateGravitationalForce(body1, body2)
    -- calculate distance components
    local dx = body2.x - body1.x
    local dy = body2.y - body1.y
    local distance = math.sqrt(dx * dx + dy * dy)

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

-- name: GFX.lua
-- description: Handles graphics rendering for 2D gravity simulation
-- author: Ramona Melfry, Nesbox
-- script: lua
-- notes: palette scripts and data from TIC-80 demos


GFX = { 

    PALETTE_INDEX = 1,

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

    -- CONSTANTS --

    OBJECT_SCALE_FACTOR = 0.1,

    MAX_TRAIL_LENGTH = 20,

    PALETTE_ADDRESS=0x3FC0,
    
    PALETTE = {
        WHITE = 12
    }

}


-- draws the trail of a body
function GFX.drawTrail(body)
    for i, point in ipairs(body.trail) do
        -- shrink size of trail points over time
        local scale = i / #body.trail
        -- shift color starting with body color
        local color = (body.mass % 16) * scale
        circ(point.x, point.y, scale, color)
    end
end


-- draws all bodies in the simulation
function GFX.drawAllBodies()
    for _, body in pairs(Objects.Body) do
        circ(body.x, body.y, body.mass * GFX.OBJECT_SCALE_FACTOR, body.mass % 16)
        GFX.drawTrail(body)
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

    -- MOUSE STATE --

    mouse_x = 0,
    mouse_y = 0,
    mouse_left = false,
    mouse_right = false,
    mouse_middle = false

}


-- updates the current mouse state
function UI.getMouse()
    UI.mouse_x, UI.mouse_y, UI.mouse_left, UI.mouse_middle, UI.mouse_right = mouse()
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

