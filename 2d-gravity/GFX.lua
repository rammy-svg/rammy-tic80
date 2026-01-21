-- name: GFX.lua
-- description: Handles graphics rendering for 2D gravity simulation
-- author: Ramona Melfry, Nesbox
-- script: lua
-- notes: palette scripts and data from TIC-80 demos


GFX = { 

    Effects = { },

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
        RED = 2,
        YELLOW = 4,
        WHITE = 15
    }

}


-- draws the trail of a body
function GFX.drawTrail(body)
    for i, point in ipairs(body.trail) do
        -- shrink size of trail points over time
        local scale = (i / #body.trail)
        -- shift color starting with body color
        local color = (body.mass % 16) * scale
        circ(point.x, point.y, scale, color)
    end
end


-- draws a larger circle around a body that pulses
function GFX.drawPulse(body)
    local t = time()
    local pulseSize = 2 + math.sin(t * 10)
    circ(body.x, body.y, body.mass * GFX.OBJECT_SCALE_FACTOR + pulseSize, GFX.PALETTE.WHITE)
end


-- draws a pulse at the given position
function GFX.drawExplosion(x, y, color, maxSize, duration)
    local t = time()
    local elapsed = (t % duration)
    local size = (elapsed / duration) * maxSize
    local offset_x = math.random(-2, 2)
    local offset_y = math.random(-2, 2)
    circ(x + offset_x, y + offset_y, size, color)
end

-- draws all free bodies in the simulation
function GFX.drawFreeBodies()
    for _, body in pairs(Objects.Body) do
        if body.type ~= "fixed" then
            circ(body.x, body.y, body.mass * GFX.OBJECT_SCALE_FACTOR, body.mass % 16)
            GFX.drawTrail(body)
        end
    end
end


-- draws all fixed bodies in the simulation
function GFX.drawFixedBodies()
    for _, body in pairs(Objects.Body) do
        if body.type == "fixed" then
            circ(body.x, body.y, body.mass * GFX.OBJECT_SCALE_FACTOR, body.mass % 16)
        end
    end
end

-- update bodies with effects
function GFX.drawAllFX()

    -- handle "aerodynamic heating" effect
    for _, body in pairs(Objects.Body) do
        if body.fx == "pulse" and body.type ~= "fixed" then
            GFX.drawPulse(body)
        end
    end

    -- handle explosions
    for i = #GFX.Effects, 1, -1 do
        local effect = GFX.Effects[i]
        GFX.drawExplosion(effect.x, effect.y, effect.color, effect.magnitude, effect.duration)
        effect.duration = effect.duration - 0.1
        if effect.duration <= 0 then
            table.remove(GFX.Effects, i)
        end
    end
    
end


-- updates the palette to the selected one
function GFX.updatePalette(index)
	local palette=GFX.PALETTES[index].data
	for i=1,#palette,2 do
		poke(GFX.PALETTE_ADDRESS+i//6*3+i//2%3,tonumber(palette:sub(i,i+1),16))
	end	
end

