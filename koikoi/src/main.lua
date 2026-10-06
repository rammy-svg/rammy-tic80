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

