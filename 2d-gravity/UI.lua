-- name: UI.lua
-- description: Handles all UI interactions and components for 2D gravity simulation
-- author: Ramona Melfry
-- script: lua


UI = { 


    -- KEYBOARD --

    INPUT = {
        KB_1 = 28,
        KB_2 = 29,
        KB_3 = 30,
        KB_4 = 31
    },

    -- MOUSE STATE --

    mouse_x = 0,
    mouse_y = 0,
    mouse_left = false,
    mouse_right = false,
    mouse_middle = false,
    mouse_scroll_x = 0,
    mouse_scroll_y = 0,

    mouse_clicked = false,
    mouse_released = false,
    mouse_pressed = false,


    -- SIMULATION CONTROL --

        
    SIM_PARAMETERS = {
        G = 0,
        C = 1,
        TIME_SCALE = 2,
        SOFTENING = 3
    },

    current_param = 0

}


-- updates the current mouse state
function UI.getMouse()
    UI.mouse_x, UI.mouse_y, UI.mouse_left, UI.mouse_middle, UI.mouse_right, UI.mouse_scroll_x, UI.mouse_scroll_y = mouse()
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


-- functions for detecting mouse scroll
function UI.checkScrollWheel()
    local up = false
    local down = false
    local left = false
    local right = false
    
    if UI.mouse_scroll_y > 0 then
        up = true
    elseif UI.mouse_scroll_y < 0 then
        down = true
    elseif UI.mouse_scroll_x < 0 then
        left = true
    elseif UI.mouse_scroll_x > 0 then
        right = true
    end

    return up, down, left, right
end



    -- MODULE SPECIFIC FUNCTIONS --

-- function for changing simulation parameters with the scroll wheel
function UI.changeParameters()
    local units = 1
    local operation = "add"
    local target = "G"


    -- change current parameter
    if keyp(UI.INPUT.KB_1) then
        UI.current_param = UI.SIM_PARAMETERS.G
    elseif keyp(UI.INPUT.KB_2) then
        UI.current_param = UI.SIM_PARAMETERS.C
    elseif keyp(UI.INPUT.KB_3) then
        UI.current_param = UI.SIM_PARAMETERS.TIME_SCALE
    elseif keyp(UI.INPUT.KB_4) then
        UI.current_param = UI.SIM_PARAMETERS.SOFTENING
    end

    if UI.current_param == UI.SIM_PARAMETERS.G then
        target = "G"
    elseif UI.current_param == UI.SIM_PARAMETERS.C then
        target = "C"
    elseif UI.current_param == UI.SIM_PARAMETERS.TIME_SCALE then
        target = "time_scale"
    elseif UI.current_param == UI.SIM_PARAMETERS.SOFTENING then
        target = "soft"
    end

    if UI.mouse_scroll_y > 0 then
        if target == "G" then
            Physics.G = Physics.G + 0.01
        elseif target == "C" then
            Physics.C = Physics.C + 1
        elseif target == "time_scale" then
            Physics.TIME_SCALE = Physics.TIME_SCALE * 2
        elseif target == "soft" then
            Physics.SOFTENING = Physics.SOFTENING + 10
        end
    elseif UI.mouse_scroll_y < 0 then
        if target == "G" then
            Physics.G = Physics.G - 0.01
        elseif target == "C" and Physics.C > 0 then
            Physics.C = Physics.C - 1
        elseif target == "time_scale" then
            Physics.TIME_SCALE = Physics.TIME_SCALE / 2
        elseif target == "soft" and Physics.SOFTENING > 0 then
            Physics.SOFTENING = Physics.SOFTENING - 10
        end
    end

end


