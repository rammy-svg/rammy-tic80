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
    mouse_middle = false,
    mouse_clicked = false,
    mouse_released = false,
    mouse_pressed = false

}


-- updates the current mouse state
function UI.getMouse()
    UI.mouse_x, UI.mouse_y, UI.mouse_left, UI.mouse_middle, UI.mouse_right = mouse()
end


-- debounce single mouseclicks/releases
function UI.debounceMouse()
    if UI.mouse_left or UI.mouse_right or UI.mouse_middle then
        if not UI.mouse_pressed then
            UI.mouse_clicked = true
            UI.mouse_released = false
            UI.mouse_pressed = true
        else
            UI.mouse_clicked = false
            UI.mouse_released = false
        end
    else
        if UI.mouse_pressed then
            UI.mouse_released = true
            UI.mouse_clicked = false
            UI.mouse_pressed = false
        else
            UI.mouse_released = false
            UI.mouse_clicked = false
        end
    end
end

