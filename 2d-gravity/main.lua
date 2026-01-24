-- name: 2d-gravity.lua
-- description: Main file for 2D gravity simulation
-- author: Ramona Melfry
-- script: lua

function BOOT()

    -- set initial palette
    GFX.updatePalette(GFX.PALETTE_INDEX)

    -- create some initial bodies
    Objects.addBody(120, 64, 150, 0, 0, Objects.OBJECT_TYPE.FIXED)  -- large fixed body in center
    Objects.addBody(48, 64, 200, 0, 10, Objects.OBJECT_TYPE.FIXED)      -- smaller body to the left
    Objects.addBody(200, 64, 200, 0, -10, Objects.OBJECT_TYPE.FIXED)    -- smaller body to the right

end


function TIC()

    -- UI --

    UI.getMouse()
    UI.debounceMouse()

     -- add body on left click

    if UI.mouse_left and UI.mouse_clicked then
        if not Objects.getBodyAtPosition(UI.mouse_x, UI.mouse_y) and #Objects.Body < Objects.MAX_OBJECT_COUNT then
            Objects.addBody(UI.mouse_x, UI.mouse_y, 5 + math.random(0, 10), 0, 0, Objects.OBJECT_TYPE.DEFAULT)
        end
    end

    if UI.mouse_right then
        local bodyID = Objects.getBodyAtPosition(UI.mouse_x, UI.mouse_y)
        if bodyID then
            for i, body in pairs(Objects.Body) do
                if body.ID == bodyID and body.type ~= Objects.OBJECT_TYPE.FIXED then
                    Objects.breakBody(body, 3)
                    break
                end
            end
        end
    end

    -- adjust simulation parameters
    UI.changeParameters()

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

    -- print currently controlled parameter and its value
    local param = "G: "
    local parameter_val = Physics.G

    if UI.current_param == UI.SIM_PARAMETERS.C then
        param = "C: "
        parameter_val = Physics.C
    elseif UI.current_param == UI.SIM_PARAMETERS.TIME_SCALE then
        param = "TIME SCALE: "
        parameter_val = Physics.TIME_SCALE
    elseif UI.current_param == UI.SIM_PARAMETERS.SOFTENING then
        param = "SOFTENING: "
        parameter_val = Physics.SOFTENING
    end

    print(param .. parameter_val, 0, 128, GFX.PALETTE.WHITE)

    -- find the first non-fixed body
    local first_free_body = nil
    for _, body in pairs(Objects.Body) do
        if body.type ~= Objects.OBJECT_TYPE.FIXED then
            first_free_body = body
            break
        end
    end

    -- print the effect applied to first free body
    
    if first_free_body then
        local effect_text = "Effect: NONE"
        if first_free_body and first_free_body.fx == GFX.EFFECTS.PULSE then
            effect_text = "Effect: PULSE"
        elseif first_free_body and first_free_body.fx == GFX.EFFECTS.GLOW then
            effect_text = "Effect: GLOW"
        end
        print(effect_text, 100, 128, GFX.PALETTE.WHITE)
    end

    -- print speed and acceleration values of first free body

    if first_free_body then
        local speed = math.sqrt(first_free_body.vx^2 + first_free_body.vy^2)
        local acceleration = math.sqrt(first_free_body.ax^2 + first_free_body.ay^2)
        print("Speed: " .. string.format("%.2f", speed), 100, 118, GFX.PALETTE.WHITE)
        print("Accel: " .. string.format("%.2f", acceleration), 100, 108, GFX.PALETTE.WHITE)
    end

    -- draw speed, acceleration vectors for first free body
    if first_free_body then
        -- speed vector
        local speed_magnitude = math.sqrt(first_free_body.vx^2 + first_free_body.vy^2)
        if speed_magnitude > 0 then
            local speed_scale = speed_magnitude * 5
            line(first_free_body.x, first_free_body.y,
                 first_free_body.x + first_free_body.vx * speed_scale,
                 first_free_body.y + first_free_body.vy * speed_scale,
                 GFX.PALETTE.WHITE)
        end

        -- acceleration vector
        local accel_magnitude = math.sqrt(first_free_body.ax^2 + first_free_body.ay^2)
        if accel_magnitude > 0 then
            local accel_scale = accel_magnitude * 500
            line(first_free_body.x, first_free_body.y,
                 first_free_body.x + first_free_body.ax * accel_scale,
                 first_free_body.y + first_free_body.ay * accel_scale,
                 GFX.PALETTE.RED)
        end
    end

end

