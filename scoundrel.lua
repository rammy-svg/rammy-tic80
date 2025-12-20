function BOOT()

	Cards.buildDeck()
	
	Cards.shuffle(Cards.Deck)
	
	for i=3, 0, -1 do
		Cards.drawOne(Cards.Room)
	end
	
end


function TIC()

		local card = UI.Control.selectCard(Cards.Room)
		
		if card then
			local suit = card.suit
			
			if suit == "Diamonds" then
				
				if Player.lastSlainMonster then
					Player.lastSlainMonster = nil
				end
				
				Player.weapon = card
				
			elseif suit == "Hearts" then
				local restored_health = card.rank
				Player.health = Player.health + restored_health
				
				if Player.health > 20 then
					Player.health = 20
				end

			elseif suit == "Spades" or suit == "Clubs" then
		
				local monster_damage = card.rank
				local weapon_rank = 15
				local weapon_damage = 0
				local total_damage = 0
				
				-- set weapon rank if lastSlainMonster
				if Player.lastSlainMonster then
					weapon_rank = Player.lastSlainMonster.rank
				end
				
				-- check if player has a weapon
				if Player.weapon then
					weapon_damage = Player.weapon.rank
					
					-- then check if the weapon can be used
					if weapon_rank >= monster_damage then
						total_damage = monster_damage - weapon_damage
						
						-- check if damage is negative
						if total_damage <= 0 then
							total_damage = 0
						end
						
					elseif weapon_rank < monster_damage then
						table.insert(Cards.Room, 1, card)
						return
					end
					
				elseif not Player.weapon then
					total_damage = monster_damage
				end
				
				-- subtract total damage from player HP
				Player.health = Player.health - total_damage
				
				-- check if health is negative
				if Player.health <= 0 then
					Player.health = 0
				end
				
				Player.lastSlainMonster = card
				
			end
		end

	-- DRAW
	
	cls(0)
	
	print(Player.health, 128, 10, Draw.COLOR.RED)
	
	for i, card in ipairs(Cards.Room) do
		print(card.ID .. " " 
			.. card.rank_name .. " " 
			.. card.suit,
			0, i*10, Draw.COLOR.WHITE)
	end
	
	if Player.weapon then
		print(Player.weapon.ID .. " "
			.. Player.weapon.rank_name .. " "
			.. Player.weapon.suit, 
			0, 60, Draw.COLOR.YELLOW)
	end
	
	if Player.lastSlainMonster then
		print(Player.lastSlainMonster.ID .. " "
			.. Player.lastSlainMonster.rank_name .. " "
			.. Player.lastSlainMonster.suit, 128, 60, Draw.COLOR.ORANGE)
	end

end





-- UI

UI = { }

	-- CONSTANTS
	
	UI.INPUT = {
		KB_1 = 28,
		KB_2 = 29,
		KB_3 = 30,
		KB_4 = 31
		
		}
		
	
	-- CONTROLS
	
	UI.Control = { }
	
	function UI.Control.selectCard(room)
		local selected_card = nil
	
		for i, card in ipairs(room) do
			local offset = i - 1
			if keyp(UI.INPUT.KB_1 + offset) then
				selected_card = card
				table.remove(room, i)
				break
			end
		end
		
		if selected_card then
			return selected_card
		end
	end
	
	
	

-- DRAW

Draw = { }

	-- CONSTANTS
	
	Draw.COLOR = {
		PURPLE = 1,
		RED = 2,
		ORANGE = 3,
		YELLOW = 4,
		L_GREEN = 5,
		GREEN = 6,
		D_GREEN = 7,
		NAVY = 8,
		D_BLUE = 9,
		L_BLUE = 10,
		CYAN = 11,
		WHITE = 12,
		GRAY_20 = 13,
		GRAY_40 = 14,
		GRAY_60 = 15
		
		}
	


-- PLAYER

Player = { 
	
	health = 15,
	
	weapon = nil,
	lastSlainMonster = nil
	
}




-- CARDS

Cards = { 

	lastCardID = 0,
	
	Deck = { },
	Room = { }

}


	-- CONSTANTS
	
	Cards.SUIT = {
		
		"Hearts",
		"Clubs",
		"Diamonds",
		"Spades"
		
	}

	Cards.RANK = {
		
		{ name = "Ace", value = 14 },
		{ name = 2, value = 2 },
		{ name = 3, value = 3 },
		{ name = 4, value = 4 },
		{ name = 5, value = 5 },
		{ name = 6, value = 6 },
		{ name = 7, value = 7 },
		{ name = 8, value = 8 },
		{ name = 9, value = 9 },
		{ name = 10, value = 10 },
		{ name = "Jack", value = 11 },
		{ name = "Queen", value = 12 },
		{ name = "King", value = 13 }
		
	}
	
	
	
 -- DECK
 
 function Cards.buildDeck()
 	local c = Cards
  local deck = c.Deck
 	local suits = c.SUIT
  local ranks = c.RANK
  
  local card = { }
  
  for i, suit in ipairs(suits) do
  	for j, rank in ipairs(ranks) do
    card = {
    	ID = c.lastCardID,
     suit = suits[i],
     rank = ranks[j].value,
     rank_name = ranks[j].name
    }
     
    table.insert(deck, 1, card)
    c.lastCardID = c.lastCardID + 1
   end
  end
	end
 
 -- shuffle cards
	function Cards.shuffle(cards)
		for i = #cards, 2, -1 do
			local j = math.random(i)
			cards[i], cards[j] = cards[j], cards[i]
		end
	end
	
	-- draw one card to hand
	function Cards.drawOne(room)
		local c = Cards
		local card = table.remove(c.Deck, 1)
		
		table.insert(room, 1, card)
	end
	
    	
 
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

