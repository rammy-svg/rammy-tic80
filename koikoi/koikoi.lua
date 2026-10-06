-- name: data.lua
-- desc: Constants and other information for hanafuda solitaire
-- author: Ramona Melfry
-- script: lua



Cards = { }



-- initializes globals and constants
function Cards.INIT()

    local c = Cards

    c.CONSTANTS()

    c.Deck = { }
    c.buildDeck()

end

-- builds hanafuda deck

function Cards.buildDeck()

    local c = Cards
    local deck = c.Deck

    -- first build all possible card combinations
    for i=0, #c.MONTH, 1 do
        local month = c.MONTH[i]
        for j=0, #c.VALUE, 1 do
            local value = c.VALUE[j]
            local card = { 
                month = month,
                value = value }

            table.insert(deck, card)
        end
    end

    -- then remove the cards that don't exist in the deck

    for _, card in pairs(deck) do
        if card.value == c.VALUE.POETRY and (
                card.month == c.MONTH.AUGUST 
                or card.month == c.MONTH.DECEMBER
            ) then
            table.remove(deck, card)
            elseif card.value == c.VALUE.ANIMAL and (
                card.month == c.MONTH.JANUARY 
                or card.month == c.MONTH.MARCH 
                or card.month == c.MONTH.DECEMBER 
            ) then
            table.remove(deck, card)
            elseif card.value == c.VALUE.BRIGHT and not (
                card.month == c.MONTH.JANUARY 
                or card.month == c.MONTH.MARCH
                or card.month == c.MONTH.AUGUST
                or card.month == c.MONTH.DECEMBER
            ) then
            table.remove(deck, card)
        end
    end

    -- move one card from November to December
    for i, card in pairs(deck) do
        if card.month == c.MONTH.NOVEMBER and card.value == c.VALUE.CHAFF then
            card.month = c.MONTH.DECEMBER
            break
        end
    end

    -- add IDs to cards
    for i, card in pairs(deck) do
        card.id = i
    end

end


-- name: data.lua
-- desc: Constants and other information for hanafuda solitaire
-- author: Ramona Melfry
-- script: lua



    -- CARDS --
    
function Cards.CONSTANTS()

    local c = Cards


    c.MONTH = {

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

    c.VALUE = {

        CHAFF = 0,
        POETRY = 1,
        ANIMAL = 2,
        BRIGHT = 3

    }

end

-- name: Hanafuda Solitaire
-- desc: A single player version of the hanafuda game "koi-koi"
-- author: Ramona Melfry
-- script: lua


function BOOT()

    Cards.INIT()
    firstrun = true

end


function TIC()

    -- print the deck to the console for testing purposes
    if firstrun then
        for _, card in pairs(Cards.Deck) do
            trace(card.id .. " " .. card.month .. ", " ..  card.value)
        end
        firstrun = false
    end
end

-- <TILES>

-- </TILES>

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

