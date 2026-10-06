--title: DIGIDRIVE
--author: Ramona Melfry
--script: lua
--desc: A clone of the bit generations game, "DIGIDRIVE" for TIC-80




	-- INIT --
	

--define namespaces

Player = {}
Field = {}
Traffic = {}

Input = {}
GFX = {}
Debug = {}



	-- CONSTANTS --
	
	
-- Traffic

Traffic.TYPE = {
	CONE = 1,
	ROUND = 2,
	SQUARE = 3,
	SPECIAL = 4
}

-- Input

Input.DIRECTION = {
	UP = 1,
	RIGHT = 2,
	DOWN = 3,
	LEFT = 4
}

-- GFX

GFX.ANIM_FRAMERATE_MOD = 2

GFX.SPRITE = {
	
	--cars
	CONE = 1,
	ROUND = 2,
	SQUARE = 3,
	SPECIAL = 4,
	
	--UI
	SELECTOR_ORIGIN = 0
}

GFX.PALETTE = {
	FG = 12,
	BG = 0,
	OUTLINE = 13,
	ACCENT1 = 2,
	ACCENT2 = 15
}

GFX.LANE_WIDTH = 17

	-- OTHER LOOKUPS --



-- Field

Field.SPAWN = {
	{ x=64-8, y=136 },
	{ x=0, y=64-8 },
	{ x=64, y=0 },
	{ x=136, y=64 }
}


-- Traffic

Traffic.DIRECTION = {
	{ x=0, y=-1 },
	{ x=1, y=0 },
	{ x=0, y=1 },
	{ x=-1, y=0 }
}
 
 
-- GFX

GFX.SELECTOR = {
	{ 
		x_step=0, y_step=-1,
		x_offset=0, y_offset=0,
		flip=0,
		accent_x=-1, accent_y=0
	},
	{ 
		x_step=1, y_step=0,
		x_offset=1, y_offset=0,
		flip=0,
		accent_x=0, accent_y=-1
	},
	{   x_step=0, y_step=1,
		x_offset=0, y_offset=1,
		flip=1,
		accent_x=1, accent_y=0
	},
	{
		x_step=-1, y_step=0,
		x_offset=0, y_offset=0,
		flip=2,
		accent_x=0, accent_y=1
	}
}

		-- TRAFFIC --
	
--define list of active traffic
Traffic.Active = { }
	
	
--function to build a new car
function Traffic.create(color, dir)
	
	local car = {
		color = color,
		dir = dir
	}
	
	return car
end


--function for spawning a new car
function Traffic.spawnNew(car)

	local color = car.color
	local dir = car.dir
	local spawn_x = Field.SPAWN[car.dir].x
	local spawn_y = Field.SPAWN[car.dir].y

	--put everything into a list to put into 
	--the list of active traffic
	local item = {
		color = color,
		x = spawn_x,
		y = spawn_y,
		dir = dir
	}
	
	--then put it into the list of active traffic
	table.insert(Traffic.Active, 1, item)
end


--function for updating the position of cars on the map
function Traffic.updatePositions()

	for i, item in ipairs(Traffic.Active) do
		local x_pos = item.x
		local y_pos = item.y
		local dir = item.dir
		local move_x = Traffic.DIRECTION[dir].x
		local move_y = Traffic.DIRECTION[dir].y
		
		item.x = x_pos + move_x
		item.y = y_pos + move_y
	end
end


--clean up traffic that is not on-screen
function Traffic.cleanup()
	
	for i, item in ipairs(Traffic.Active) do
		local x_pos = item.x
		local y_pos = item.y
		
		if x_pos < 0 
			or x_pos > 136 
			or y_pos < 0 
			or y_pos > 136 then
			
			table.remove(Traffic.Active, i)			
		end
	end
end

	-- FIELD --
	
--define variables
Field.gameSpeed = 32


--define the queue of actions
Field.Queue = { }


--define the game field lanes

Field.Lanes = {
	{ 
		type = nil,
		stacked = 0,
		fuel = 0,
		decay_rate = 0.5,
		
		queue = { }
	},
	{
		type = nil,
		stacked = 0,
		fuel = 0,
		decay_rate = 0.5,
		
		queue = { }
	},
		{
		type = nil,
		stacked = 0,
		fuel = 0,
		decay_rate = 0.5,
		
		queue = { }
	},
		{
		type = nil,
		stacked = 0,
		fuel = 0,
		decay_rate = 0.5,
		
		queue = { }
	}
}
	
	
--adds a new car to the play queue
function Field.addCar(color, dir)

	local car = Traffic.create(color, dir)
	
	table.insert(Field.Queue, car)
end


--get the next queue item
function Field.getNextQueue()

	local item = table.remove(Field.Queue, 1)
	
	return item
end



--advance the queue one step
function Field.advanceQueue(speed)

	local t = math.floor(time())
	
	if t % speed == 0 and #Field.Queue >= 1 then
		local car = Field.getNextQueue()
		
		Traffic.spawnNew(car)
	end
end

	


	-- INPUT --
	
	
--handles player inputs in game
function Input.inGame()

end



	-- DRAW --
	
--declare variables
GFX.selector_length = 0
	

--draw the gameplay field

function GFX.drawField(x,y)

	local color = GFX.PALETTE
	local offset = 4
	
	--draw the drop shadow
	rect(x+offset, y+56+offset, 136, GFX.LANE_WIDTH, color.ACCENT2)
	rect(x+56+offset, y+offset, GFX.LANE_WIDTH, 136, color.ACCENT2)
	
	--draw the main game field
	rect(x, y+56, 136, GFX.LANE_WIDTH, color.FG)
	rect(x+56, y, GFX.LANE_WIDTH, 136, color.FG)    
	
end 
	
	
-- draw traffic
function GFX.drawTraffic()

	for i, item in pairs(Traffic.Active) do
		local color = item.color
		local x_pos = item.x
		local y_pos = item.y
		--TIC 80 expects rotation val from 0-3, 
		--we have 1-4:
		local rot = item.dir - 1 
		spr(color, x_pos, y_pos, 0, 1, 0, rot, 1, 1)
	end
end



--draw a line along the lane the player has selected
function GFX.drawSelectedLane(dir, origin_x, origin_y, total_length)

	local length = GFX.selector_length
	local t = math.floor(time())
	local scale = 16
		 
	--check to see if we can increase length
	if GFX.selector_length < total_length then
		GFX.selector_length = length + scale
	elseif GFX.selector_length >= total_length then
		length = total_length
	end
	
	--get the endpoint
	local len_x = GFX.SELECTOR[dir].x_step
	local len_y = GFX.SELECTOR[dir].y_step
	
	len_x = len_x * length
	len_y = len_y * length
	
	local endpoint_x = origin_x + len_x
	local endpoint_y = origin_y + len_y
	
	--draw ornaments
	local ornament1_offset_x = GFX.SELECTOR[dir].accent_x
	local ornament1_offset_y = GFX.SELECTOR[dir].accent_y
	local ornament2_offset_x = - (GFX.SELECTOR[dir].accent_x)
	local ornament2_offset_y = - (GFX.SELECTOR[dir].accent_y)

	local ornament3_offset_x = 3*ornament1_offset_x
	local ornament3_offset_y = 3*ornament1_offset_y
	local ornament4_offset_x = 3*ornament2_offset_x
	local ornament4_offset_y = 3*ornament2_offset_y

	line(origin_x - ornament1_offset_x, origin_y - ornament1_offset_y, endpoint_x - ornament1_offset_x, endpoint_y - ornament1_offset_y, GFX.PALETTE.OUTLINE)
 	line(origin_x - ornament2_offset_x, origin_y - ornament2_offset_y, endpoint_x - ornament2_offset_x, endpoint_y - ornament2_offset_y, GFX.PALETTE.OUTLINE)
	
	line(origin_x - ornament3_offset_x, origin_y - ornament3_offset_y, endpoint_x - ornament3_offset_x, endpoint_y - ornament3_offset_y, GFX.PALETTE.ACCENT1)
 	line(origin_x - ornament4_offset_x, origin_y - ornament4_offset_y, endpoint_x - ornament4_offset_x, endpoint_y - ornament4_offset_y, GFX.PALETTE.ACCENT1)
	
	
	--draw the starting point of the line
	local offset = 3
	local flip = GFX.SELECTOR[dir].flip
	local x_pos = origin_x - offset
	local y_pos = origin_y - offset
	local rot = dir - 1 --again need to shift indices down
	spr(GFX.SPRITE.SELECTOR_ORIGIN, x_pos, y_pos, 0, 1, flip, rot, 1, 1)
	
	
	
	--actually draw the line
	origin_x = origin_x + GFX.SELECTOR[dir].x_offset
	origin_y = origin_y + GFX.SELECTOR[dir].y_offset
	line(origin_x, origin_y, endpoint_x, endpoint_y, GFX.PALETTE.ACCENT1)
			
end



	-- DEBUG --
	
	

-- utility for getting screen coords

function Debug.printCoords()

	local mouse_x, mouse_y = mouse()
	
	print(mouse_x .. ", " .. mouse_y, GFX.PALETTE.FG)
end


-- print the currently active cars
function Debug.printActive()

	if #Traffic.Active > 0 then
		for i, car in ipairs(Traffic.Active) do
			print(car.color .. " " .. car.x .. " " .. car.y .. " " .. car.dir, 140, 64+(8*i), GFX.PALETTE.FG)
		end
	else
	
		print("no active traffic", 140, 64, GFX.PALETTE.ACCENT2)
	end
end

-- print the current play queue

function Debug.printQueue()

	if #Field.Queue > 0 then
		for i, car in ipairs(Field.Queue) do
			print(car.color .. " " .. car.dir, 140, 0+(8*i), GFX.PALETTE.FG)
		end
	else
	
		print("nothing in queue", 140, 0, GFX.PALETTE.ACCENT2)
	end
end



	-- MAIN --
	
	

function TIC()

	cls(GFX.PALETTE.BG)
	
	Field.advanceQueue(Field.gameSpeed)
	
	if #Traffic.Active > 0 then
		Traffic.cleanup()
		Traffic.updatePositions()
	end

	Debug.printCoords()
	Debug.printActive()
	Debug.printQueue()
	

	GFX.drawField(4,4)
	
	if #Traffic.Active > 0 then
		GFX.drawTraffic()
	end
	
	local button_pressed = false
	
	if btn(0) then
		--Field.addCar(Traffic.TYPE.CONE, Input.DIRECTION.UP)
		GFX.drawSelectedLane(Input.DIRECTION.UP, 64, 64, 64)
	elseif btn(1) then
		--Field.addCar(Traffic.TYPE.ROUND, Input.DIRECTION.DOWN)
		GFX.drawSelectedLane(Input.DIRECTION.DOWN, 64, 64, 64)	
	elseif btn(2) then
		--Field.addCar(Traffic.TYPE.SQUARE, Input.DIRECTION.RIGHT)
		GFX.drawSelectedLane(Input.DIRECTION.LEFT, 64, 64, 64)
	elseif btn(3) then
		--Field.addCar(Traffic.TYPE.CONE, Input.DIRECTION.LEFT)
		GFX.drawSelectedLane(Input.DIRECTION.RIGHT, 64, 64, 64)
	else
		GFX.selector_length = 0
	end
	
end
-- <TILES>
-- 000:20000020c20002c0cc202cc0ccc2ccc0ccccccc0000000000000000000000000
-- 001:0000d0000000d000000dfd00000dfd0000dfffd000dfdfd000dd0dd000000000
-- 002:000ddd0000d222d000d222d000d222d000d222d000ddddd000d000d000000000
-- 003:000fff00000fdf0000fdddf000fdddf000fdddf000fdfdf000fffff000000000
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
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f4d0d0d0566c86333c57
-- </PALETTE>

