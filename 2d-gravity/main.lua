-- name: 2d-gravity.lua
-- description: Main file for 2D gravity simulation
-- author: Ramona Melfry
-- script: lua

function BOOT()

    -- set initial palette
    GFX.updatePalette(GFX.PALETTE_INDEX)

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

