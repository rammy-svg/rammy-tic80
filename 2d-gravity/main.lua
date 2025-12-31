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

