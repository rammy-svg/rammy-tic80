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

