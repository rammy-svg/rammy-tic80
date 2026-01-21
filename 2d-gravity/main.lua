-- name: 2d-gravity.lua
-- description: Main file for 2D gravity simulation
-- author: Ramona Melfry
-- script: lua

function BOOT()

    -- set initial palette
    GFX.updatePalette(GFX.PALETTE_INDEX)

    -- create some initial bodies
    Objects.addBody(120, 64, 100, 0, 0, "fixed")  -- large fixed body in center
    Objects.addBody(48, 64, 150, 0, 10, "fixed")      -- smaller body to the left
    Objects.addBody(200, 64, 150, 0, -10, "fixed")    -- smaller body to the right

end


function TIC()

    -- UI --

    UI.getMouse()
    UI.debounceMouse()

     -- add body on left click

    if UI.mouse_left and UI.mouse_clicked then
        if not Objects.getBodyAtPosition(UI.mouse_x, UI.mouse_y) and #Objects.Body < Objects.MAX_OBJECT_COUNT then
            Objects.addBody(UI.mouse_x, UI.mouse_y, 5 + math.random(0, 10), 0, 0, "default")
        end
    end

    if UI.mouse_right then
        local bodyID = Objects.getBodyAtPosition(UI.mouse_x, UI.mouse_y)
        if bodyID then
            for i, body in pairs(Objects.Body) do
                if body.ID == bodyID and body.type ~= "fixed" then
                    Objects.destroyBody(bodyID)
                    break
                end
            end
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

    Objects.updateBodies()
    Objects.applyEffects()
    Objects.cleanup()

    -- DRAW --

    cls(0)

    GFX.drawFixedBodies()
    GFX.drawAllFX()
    GFX.drawFreeBodies()


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

