-- name: data.lua
-- desc: Constants and other information for hanafuda solitaire
-- author: Ramona Melfry
-- script: lua



    -- CARDS --


    
function Cards.CONSTANTS()

    local c = Cards


    c.MONTHS = {

        JANUARY = 0,
        FEBRUARY = 1,
        MARCH = 2,
        APRIL = 3,
        MAY = 4,
        JUNE = 5,
        JULY = 6,
        AUGUST = 7,
        SEPTEMBER = 8,
        OCTOBER = 9,
        NOVEMBER = 10,
        DECEMBER = 11

    }

    c.TYPE = {

        CHAFF = 0,
        POETRY = 1,
        ANIMAL = 2,
        BRIGHT = 3

    }

end