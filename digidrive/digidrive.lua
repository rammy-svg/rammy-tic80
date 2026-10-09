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
	

-- Field
Field.ORIGIN_X = 0
Field.ORIGIN_Y = 0
Field.SIZE = 136

Field.CENTER = Field.SIZE / 2
Field.LANE_WIDTH = 17
Field.HALF_WIDTH = 8

Field.LANE_LEFT_EDGE = Field.CENTER - Field.HALF_WIDTH
Field.LANE_TOP_EDGE = Field.CENTER - Field.HALF_WIDTH

Field.GAME_SPEED_SCALE = 32

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

GFX.ANIM_FRAMERATE_MOD = 180

GFX.SPRITE = {
	
	--cars
	CONE = 1,
	ROUND = 2,
	SQUARE = 3,
	SPECIAL = 4,
	
	--UI
	SELECTOR_ORIGIN = 0,

	--fuel tanks
	TANK_TRIANGLE = {
		BG = 16,
		FG = 112,
		ACCENT = 90
	},
	TANK_SQUARE = {
		BG = 48,
		FG = 144,
		ACCENT = 56
	},
	TANK_PENTAGON = {
		BG = 80,
		FG = 176,
		ACCENT = 22
	}
}


GFX.PALETTE = {
	TRANSPARENT = 0,
	TRUE_BLACK = 1,
	TRUE_WHITE = 2,

	BLACK = 15,
	GRAY = 14,
	LT_GRAY = 13,
	WHITE = 12,
	
	ACCENT_1 = 7,
	ACCENT_2 = 6,
	ACCENT_3 = 5,
	ACCENT_4 = 4
}


GFX.COLOR = {
	--values that the game actually uses (try to use these instead of referencing colors directly)
	FG = GFX.PALETTE.WHITE,
	BG = GFX.PALETTE.BLACK,
	OUTLINE = GFX.PALETTE.LT_GRAY,
	ACCENT1 = GFX.PALETTE.ACCENT_1,
	ACCENT2 = GFX.PALETTE.GRAY
}





	-- OTHER LOOKUPS --



-- Field

Field.SPAWN = {
	{ x = Field.LANE_LEFT_EDGE, y = Field.SIZE }, -- UP
	{ x = 0 - Field.HALF_WIDTH, y = Field.LANE_TOP_EDGE }, -- RIGHT
	{ x = Field.CENTER + 1, y = 0 - Field.HALF_WIDTH }, -- DOWN
	{ x = Field.SIZE, y = Field.CENTER + 1 } -- LEFT
}


--this is the zone where cars can change direction
Field.INTERSECTION = {
	x_min = Field.CENTER - Field.HALF_WIDTH,
	x_max = Field.CENTER + Field.HALF_WIDTH,
	y_min = Field.CENTER - Field.HALF_WIDTH,
	y_max = Field.CENTER + Field.HALF_WIDTH
}


Field.ENDPOINTS = {
	{ x = Field.LANE_LEFT_EDGE, y = 0 }, -- UP
	{ x = Field.SIZE - Field.HALF_WIDTH, y = Field.LANE_TOP_EDGE }, -- RIGHT
	{ x = Field.CENTER + 1, y = Field.SIZE - Field.HALF_WIDTH }, -- DOWN
	{ x = 0, y = Field.CENTER + 1 } -- LEFT
}


Field.LANE = {
	{ axis = "x", value = Field.LANE_LEFT_EDGE },
	{ axis = "y", value = Field.LANE_LEFT_EDGE },
	{ axis = "x", value = Field.LANE_LEFT_EDGE + ( Field.LANE_WIDTH - 8 ) }, 
	{ axis = "y", value = Field.LANE_LEFT_EDGE + ( Field.LANE_WIDTH - 8 ) }
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


GFX.FUEL_TANKS = {
	{ x = Field.LANE_LEFT_EDGE - 1.25 * Field.LANE_WIDTH, y = Field.LANE_WIDTH, },
	{ x = Field.SIZE - 2 * Field.LANE_WIDTH, y = Field.LANE_TOP_EDGE - 1.25 * Field.LANE_WIDTH },
	{ x = Field.LANE_LEFT_EDGE + 1.5 * Field.LANE_WIDTH, y = Field.SIZE - 2 * Field.LANE_WIDTH },
	{ x = 1.25 * Field.LANE_WIDTH, y = Field.LANE_TOP_EDGE + 1.5 * Field.LANE_WIDTH } 
}

GFX.TANK_SPRITE = {
	{
		GFX.SPRITE.TANK_TRIANGLE.BG,
		GFX.SPRITE.TANK_TRIANGLE.ACCENT,
		GFX.SPRITE.TANK_TRIANGLE.FG
	},
	{
		GFX.SPRITE.TANK_SQUARE.BG,
		GFX.SPRITE.TANK_SQUARE.ACCENT,
		GFX.SPRITE.TANK_SQUARE.FG
	},
	{
		GFX.SPRITE.TANK_PENTAGON.BG,
		GFX.SPRITE.TANK_PENTAGON.ACCENT,
		GFX.SPRITE.TANK_PENTAGON.FG
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
	local spawn = Field.SPAWN[car.dir]
	
	local spawn_x = Field.ORIGIN_X + spawn.x
	local spawn_y = Field.ORIGIN_Y + spawn.y

	--put everything into a list to put into 
	--the list of active traffic
	local item = {
		color = color,
		x = spawn_x,
		y = spawn_y,
		dir = dir,
		changed = false,
		thru = false,
		active = true
	}
	
	--then put it into the list of active traffic
	table.insert(Traffic.Active, 1, item)
end


--check to see if the car is in the intersection
function Traffic.inIntersection(item)

    return item.x >= Field.INTERSECTION.x_min and item.x <= Field.INTERSECTION.x_max
       and item.y >= Field.INTERSECTION.y_min and item.y <= Field.INTERSECTION.y_max
end

-- check if the car can turn on this frame
function Traffic.canTurn(item, new_dir)

    if item.changed then 
		return false 
	end
    
	--ignore direction change if car is already moving in that direction
	if item.dir == new_dir then 
		return false
	end
    
	--no U-turns allowed
	if (item.dir + 1) % 4 + 1 == new_dir then 
		return false 
	end
    
	--can't turn unless in intersection
	if not Traffic.inIntersection(item) then 
		return false 
	end

    --car must already be in the destination lane before it can turn
    local lane = Field.LANE[new_dir]
    return item[lane.axis] == lane.value
end

-- new_dir is the direction the player is holding (or nil)
function Traffic.applyTurns(new_dir)
    if not new_dir then 
		return
	end
    
	for _, item in ipairs(Traffic.Active) do
    
		if Traffic.canTurn(item, new_dir) then
    		item.dir = new_dir
            item.changed = true
        end
    end
end


--function for updating the position of cars on the map
function Traffic.updatePositions()

	for i, item in ipairs(Traffic.Active) do
		local x_pos = item.x
		local y_pos = item.y
		local dir = item.dir
		local move_x = Traffic.DIRECTION[dir].x
		local move_y = Traffic.DIRECTION[dir].y
		
		--update positions
		item.x = x_pos + move_x
		item.y = y_pos + move_y

		--check to see if the car has passed through the intersection yet
		if Traffic.inIntersection(item) then
			item.thru = true
		end

	end
end




--clean up traffic that is not on-screen
function Traffic.cleanup()

	for i = #Traffic.Active, 1, -1 do
		local item = Traffic.Active[i]

		--use field size to determine if the car is off-screen
		if item.x < Field.ORIGIN_X - Field.HALF_WIDTH or 
			item.x > Field.ORIGIN_X + Field.SIZE or 
			item.y < Field.ORIGIN_Y - Field.HALF_WIDTH or 
			item.y > Field.ORIGIN_Y + Field.SIZE then
			
			--check to see if the car has passed through the intersection before removing it
			if item.thru then
				table.remove(Traffic.Active, i)
			end
		end
	end
end




	-- FIELD --

	
--define variables
Field.game_speed = 0.25
Field.queue_timer_max = 100
Field.queue_timer = 0


--define tables
Field.Queue = { }
Field.Lanes = { }


--helper functions
function Field.getCoords(point)
	return { x = point.x, y = point.y }
end

--define the game field lanes
function Field.buildLanes()
	
	Field.Lanes = { }

	for i=1, 4, 1 do
		local lane = { 
			dir = i,
			type = nil,
			stored = 0,
			level = 0,
			fuel = 0,
			decay_rate = 0.5,
			
			queue = { },
		
			--keep track of the position of the last car in the stack, for more graceful animations
			last_car_pos = Field.getCoords(Field.ENDPOINTS[i])
		}

		table.insert(Field.Lanes, lane)
	end
end



--handle cars that are at the end of the lane
function Field.updateLanes()

	for i, item in ipairs(Traffic.Active) do

		local lane = Field.Lanes[item.dir]

		local gap = 4
		local endpoint = lane.last_car_pos

		if item.x == endpoint.x and item.y == endpoint.y and item.active then
			
			--special cars always clear the lane
			if item.color == Traffic.TYPE.SPECIAL then
				lane.type = nil
				lane.stored = 0
				lane.level = 0
				lane.fuel = 0
				 
				--reset the last car positions
				lane.last_car_pos = Field.getCoords(Field.ENDPOINTS[lane.dir])
			
			--check to see if the lane is already defined
			--and assign it if not
			elseif lane.type == nil then
				lane.type = item.color
				lane.stored = lane.stored + 1

				--update the position of the last car (by adding the opposite of the direction of travel)
				lane.last_car_pos.x = lane.last_car_pos.x - (Traffic.DIRECTION[lane.dir].x * gap)
				lane.last_car_pos.y = lane.last_car_pos.y - (Traffic.DIRECTION[lane.dir].y * gap)

				table.remove(Traffic.Active, i)
			elseif lane.type == item.color then
				lane.stored = lane.stored + 1
				
				lane.last_car_pos.x = lane.last_car_pos.x - (Traffic.DIRECTION[lane.dir].x * gap)
				lane.last_car_pos.y = lane.last_car_pos.y - (Traffic.DIRECTION[lane.dir].y * gap)

				table.remove(Traffic.Active, i)
			else
				--wrong color resets the lane
				lane.type = nil
				lane.stored = 0
				lane.level = 0
				lane.fuel = 0

				lane.last_car_pos = Field.getCoords(Field.ENDPOINTS[lane.dir])

				--make sure the car passing through does not get stored
				item.active = false
			end

		end
	end
end


--check for lanes that have 5 cars in them
function Field.checkGroups()

	for i, lane in ipairs(Field.Lanes) do
		if lane.stored == 5 then
			--add 1 unit of fuel
			lane.fuel = lane.fuel + 1
			--then clear the lane
			lane.stored = 0
			lane.last_car_pos = Field.getCoords(Field.ENDPOINTS[lane.dir])

			--check if the lane is already locked to a color (level 1 or higher)
			if lane.level <= 0 then
				lane.level = 1
			end
		end
	end
end
	
	
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
function Field.advanceQueue()
		local car = Field.getNextQueue()
		
		Traffic.spawnNew(car)
end



--new queue manager (using timer instead of modulo)
function Field.queueMan()

	--check to see if the queue is full
	if #Field.Queue < 5 then
		--get a random color and direction (implement difficulty scaled weighting later)
		local color = math.random(1, 4)
		local dir = math.random(1, 4)
		Field.addCar(color, dir)
	end

	--check if we should advance the queue this step
	if Field.queue_timer < Field.queue_timer_max then
		Field.queue_timer = Field.queue_timer + 1
	elseif Field.queue_timer >= Field.queue_timer_max then
		--run the next step
		Field.advanceQueue()
		Field.queue_timer = 0
	end

end


	-- INPUT --


-- initialize variables
Input.held = nil



--handle player inputs in-game
function Input.handleInputs()

	if btn(0) then
		Input.held = Input.DIRECTION.UP
	elseif btn(1) then
		Input.held = Input.DIRECTION.DOWN
	elseif btn(2) then
		Input.held = Input.DIRECTION.LEFT
	elseif btn(3) then
		Input.held = Input.DIRECTION.RIGHT
	else
		Input.held = nil
	end
end




	-- DRAW --
	
--declare and initialize variables
GFX.selector_length = 0



--animate the special cars
function GFX.drawSpecial(x_pos, y_pos, rotation, thru)
	local t = time()
	local frame_count = 6
	--modulate the frame rate to slow down the animation
	t = math.floor(t / GFX.ANIM_FRAMERATE_MOD)
	local frame = t % frame_count

	spr(GFX.SPRITE.SPECIAL + frame, x_pos, y_pos, 0, 1, 0, rotation, 1, 1)
end

--mask the right edge of the playfield
function GFX.maskEdge()
	local offset = 4
	rect(Field.SIZE, Field.LANE_TOP_EDGE, Field.HALF_WIDTH, Field.LANE_WIDTH + offset, GFX.COLOR.BG)
	--fix the drop shadow
	rect(Field.SIZE, Field.LANE_TOP_EDGE + offset, offset, Field.LANE_WIDTH, GFX.COLOR.ACCENT2)
end

--draw the gameplay field

function GFX.drawField()
	local origin_x = Field.ORIGIN_X
	local origin_y = Field.ORIGIN_Y
	local color = GFX.COLOR
	local offset = 4

	-- shadow
	rect(origin_x + offset, origin_y + Field.LANE_TOP_EDGE + offset, Field.SIZE, Field.LANE_WIDTH, color.ACCENT2)
	rect(origin_x + Field.LANE_LEFT_EDGE + offset, origin_y + offset, Field.LANE_WIDTH, Field.SIZE, color.ACCENT2)

	-- main playfield
	rect(origin_x, origin_y + Field.LANE_TOP_EDGE, Field.SIZE, Field.LANE_WIDTH, color.FG)
	rect(origin_x + Field.LANE_LEFT_EDGE, origin_y, Field.LANE_WIDTH, Field.SIZE, color.FG)

end


--draw stored cars in the lanes
function GFX.drawStored()
	for i, lane in ipairs(Field.Lanes) do
		--check to see if there are any cars stored in this lane
		if lane.stored > 0 then
			--draw stored cars at the endpoint with offset
			for j=lane.stored, 1, -1 do
				--draw the stored cars in a stack
				local endpoint = Field.ENDPOINTS[lane.dir]
				local type = lane.type
				--shift the sprite using Traffic.DIRECTION
				local x_pos = endpoint.x - (Traffic.DIRECTION[i].x * (j-1) * 4)
				local y_pos = endpoint.y - (Traffic.DIRECTION[i].y * (j-1) * 4)
				--TIC 80 expects rotation val from 0-3, 
				--we have 1-4:
				local rotation = i - 1
				spr(type, x_pos, y_pos, 0, 1, 0, rotation, 1, 1)
			end
		end
	end
end


--draw fuel tanks next to lanes
function GFX.drawFuelTanks()
	for i, lane in ipairs(Field.Lanes) do
		if lane.type and lane.level >= 1 then
			local x_pos = GFX.FUEL_TANKS[i].x
			local y_pos = GFX.FUEL_TANKS[i].y
			local shape = GFX.TANK_SPRITE[lane.level]
			local sprite = shape[lane.type]
			
			spr(sprite, x_pos, y_pos, 0, 1, 0, 0, 2, 2)
		end
	end
end



	
	
-- draw traffic
function GFX.drawTraffic()

	for i, item in pairs(Traffic.Active) do
		local color = item.color
		local x_pos = item.x
		local y_pos = item.y
		--TIC 80 expects rotation val from 0-3, 
		--we have 1-4:
		local rotation = item.dir - 1

		--handle special cars first
		if item.color == Traffic.TYPE.SPECIAL then
			GFX.drawSpecial(x_pos, y_pos, rotation, item.thru)
		else
			spr(color, x_pos, y_pos, 0, 1, 0, rotation, 1, 1)
		end
	end
end



--draw a line along the lane the player has selected
function GFX.drawSelectedLane(dir, origin_x, origin_y, total_length)

	local t = math.floor(time())
	local scale = 8
	
	GFX.selector_length = math.min(GFX.selector_length + scale, total_length)
	local length = GFX.selector_length
		 
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

	--inner line outline
	local ornament1_offset_x = GFX.SELECTOR[dir].accent_x
	local ornament1_offset_y = GFX.SELECTOR[dir].accent_y
	local ornament2_offset_x = - (GFX.SELECTOR[dir].accent_x)
	local ornament2_offset_y = - (GFX.SELECTOR[dir].accent_y)

	--outer lines
	local selector_width = 3

	local ornament3_offset_x = selector_width * ornament1_offset_x
	local ornament3_offset_y = selector_width * ornament1_offset_y
	local ornament4_offset_x = selector_width * ornament2_offset_x
	local ornament4_offset_y = selector_width * ornament2_offset_y

	line(origin_x - ornament1_offset_x, origin_y - ornament1_offset_y, endpoint_x - ornament1_offset_x, endpoint_y - ornament1_offset_y, GFX.COLOR.OUTLINE)
 	line(origin_x - ornament2_offset_x, origin_y - ornament2_offset_y, endpoint_x - ornament2_offset_x, endpoint_y - ornament2_offset_y, GFX.COLOR.OUTLINE)
	
	line(origin_x - ornament3_offset_x, origin_y - ornament3_offset_y, endpoint_x - ornament3_offset_x, endpoint_y - ornament3_offset_y, GFX.COLOR.ACCENT1)
 	line(origin_x - ornament4_offset_x, origin_y - ornament4_offset_y, endpoint_x - ornament4_offset_x, endpoint_y - ornament4_offset_y, GFX.COLOR.ACCENT1)
	
	--starting point of the line
	local offset = 3
	local flip = GFX.SELECTOR[dir].flip
	local x_pos = origin_x - offset
	local y_pos = origin_y - offset
	local rot = dir - 1 --again need to shift indices down
	spr(GFX.SPRITE.SELECTOR_ORIGIN, x_pos, y_pos, 0, 1, flip, rot, 1, 1)
	
	
	
	--actually draw the line
	origin_x = origin_x + GFX.SELECTOR[dir].x_offset
	origin_y = origin_y + GFX.SELECTOR[dir].y_offset
	line(origin_x, origin_y, endpoint_x, endpoint_y, GFX.COLOR.ACCENT1)
			
end




	-- DEBUG --
	
	

-- utility for getting screen coords

function Debug.printCoords()

	local mouse_x, mouse_y = mouse()
	
	print(mouse_x .. ", " .. mouse_y, 0, 0, GFX.COLOR.FG)
end


-- print the currently active cars
function Debug.printActive()

	if #Traffic.Active > 0 then
		for i, car in ipairs(Traffic.Active) do
			print(car.color .. " " .. car.dir .. " ( " .. car.x .. ", " .. car.y .. " )" .. " " .. (car.changed and "1" or "0") .. " " .. (car.thru and "1" or "0"), 140, 64+(8*i), GFX.COLOR.FG)
		end
	else
	
		print("no active traffic", 140, 64, GFX.COLOR.ACCENT2)
	end
end

-- print the current play queue

function Debug.printQueue()

	if #Field.Queue > 0 then
		for i, car in ipairs(Field.Queue) do
			print(car.color .. " " .. car.dir, 140, 0+(8*i), GFX.COLOR.FG)
		end
	else
	
		print("nothing in queue", 140, 0, GFX.COLOR.ACCENT2)
	end
end


-- print the lane stats next to the lanes
function Debug.showLaneStats()

	for i, lane in ipairs(Field.Lanes) do
		
		local endpoint = Field.ENDPOINTS[i]
		local x_pos = GFX.FUEL_TANKS[i].x
		local y_pos = GFX.FUEL_TANKS[i].y
		
		print(lane.type or "nil", x_pos, y_pos - 8, GFX.COLOR.ACCENT2)
		print(lane.dir, x_pos, y_pos, GFX.COLOR.ACCENT1)
		print(lane.level, x_pos, y_pos + 8, GFX.COLOR.ACCENT2)
		print(lane.fuel, x_pos, y_pos + 16, GFX.COLOR.ACCENT2)
	end
end


-- show where the fuel tanks are on the field
function Debug.showFuelTanks()
	for i, tank in ipairs(GFX.FUEL_TANKS) do
		local x_pos = tank.x
		local y_pos = tank.y
		spr(GFX.SPRITE.TANK_TRIANGLE.BG, x_pos, y_pos, 0, 1, 0, 0, 2, 2)
	end
end


--show where the endpoints currently are
function Debug.showEndpoints()
	for i, lane in ipairs(Field.Lanes) do
		local x_pos = lane.last_car_pos.x
		local y_pos = lane.last_car_pos.y

		spr(255, x_pos, y_pos, 0, 1, 0, 0, 1, 1)
	end
end

	-- MAIN --

function BOOT()

	Field.buildLanes()

end
	
	

function TIC()

	cls(GFX.COLOR.BG)

	Input.handleInputs()
	
	Field.queueMan()
	
	if #Traffic.Active > 0 then
		if Input.held then
			Traffic.applyTurns(Input.held)
		end

		Traffic.updatePositions()
		Field.updateLanes()
		Field.checkGroups()
		Traffic.cleanup()
	end



	GFX.drawField()
	
	local cx = Field.ORIGIN_X + Field.CENTER
	local cy = Field.ORIGIN_Y + Field.CENTER
	local len = Field.CENTER  -- distance from center to edge, 68

    if Input.held then
        GFX.drawSelectedLane(Input.held, cx, cy, len)
    else
        GFX.selector_length = 0
    end

	if #Traffic.Active > 0 then
		GFX.drawTraffic()
		GFX.maskEdge()
	end

	GFX.drawStored()
	GFX.drawFuelTanks()
	
	Debug.printCoords()
	Debug.printActive()
	Debug.printQueue()
	--Debug.showLaneStats()
	--Debug.showFuelTanks()
	--Debug.showEndpoints()

end
-- <TILES>
-- 000:70000070c70007c0cc707cc0ccc7ccc0ccccccc0000000000000000000000000
-- 001:000000000000d0000000d000000dfd00000dfd0000dfffd000dfdfd000dd0dd0
-- 002:00000000000ddd0000dd7dd000d777d000d777d000d7d7d000ddddd000d000d0
-- 003:00000000000fff00000fcf0000fcccf000fcccf000fcfcf000fffff000000000
-- 004:0000d000000d7d0000d7e7d000de2ed000d2d2d000dd0dd000d000d000000000
-- 005:0000d000000ded0000de2ed000d272d000d7d7d000dd0dd000d000d000000000
-- 006:0000d000000d2d0000d272d000d7e7d000deded000dd0dd000d000d000000000
-- 007:0000f000000f7f0000f7e7f000fe2ef000f2f2f000ff0ff000f000f000000000
-- 008:0000f000000fef0000fe2ef000f272f000f7f7f000ff0ff000f000f000000000
-- 009:0000f000000f2f0000f27cf000f7e7f000fefef000ff0ff000f000f000000000
-- 016:000000000000000f0000000f000000fd000000fd00000fdd00000fdd0000fddd
-- 017:000000000000000000000000f0000000f0000000df000000df000000ddf00000
-- 018:000000000000000f0000000f000000fd000000fd00000fdd00000fdd0000fddd
-- 019:000000000000000000000000f0000000f0000000df000000df000000ddf00000
-- 020:000000000000000f0000000f000000fd000000fd00000fdd00000fdf0000fddf
-- 021:000000000000000000000000f0000000f0000000df000000df000000ddf00000
-- 022:00000000000000060000006d000006dd00006ddd0006dddd006ddddd06dddddd
-- 023:0000000060000000d6000000dd600000ddd60000dddd6000ddddd600dddddd60
-- 024:00000000000000060000006d000006dd00006ddd0006dddd006ddddd06dddddd
-- 025:0000000060000000d6000000dd600000ddd60000dddd6000ddddd600dddddd60
-- 026:00000000000000060000006d000006dd00006ddd0006dddd006ddddd06d66666
-- 027:0000000060000000d6000000dd600000ddd60000dddd6000ddddd60066666d60
-- 028:00000000000000060000006d000006dd00006ddd0006d666006d666606d66666
-- 029:0000000060000000d6000000dd600000ddd60000666d60006666d60066666d60
-- 030:00000000000000060000006d000006d600006d660006d666006d666606d66666
-- 031:0000000060000000d60000006d60000066d60000666d60006666d60066666d60
-- 032:0000fddd000fdddd000fdddd00fddfff00fdffff0fdddddd0fffffff00000000
-- 033:ddf00000dddf0000dddf0000ffddf000fffdf000dddddf00ffffff0000000000
-- 034:0000fddd000fddff000fdfff00fddfff00fdffff0fdddddd0fffffff00000000
-- 035:ddf00000fddf0000ffdf0000ffddf000fffdf000dddddf00ffffff0000000000
-- 036:0000fdff000fddff000fdfff00fddfff00fdffff0fdddddd0fffffff00000000
-- 037:fdf00000fddf0000ffdf0000ffddf000fffdf000dddddf00ffffff0000000000
-- 038:06dddddd006ddddd006ddddd0006d6660006dd6600006ddd0000666600000000
-- 039:dddddd60ddddd600ddddd600666d600066dd6000ddd600006666000000000000
-- 040:06dddddd006d6666006d66660006d6660006d66600006ddd0000666600000000
-- 041:dddddd606666d6006666d600666d6000666d6000ddd600006666000000000000
-- 042:06d66666006d6666006d66660006d6660006d66600006ddd0000666600000000
-- 043:66666d606666d6006666d600666d6000666d6000ddd600006666000000000000
-- 044:06d66666006d6666006d66660006d6660006d66600006ddd0000666600000000
-- 045:66666d606666d6006666d600666d6000666d6000ddd600006666000000000000
-- 046:06d66666006d6666006d66660006d6660006d66600006ddd0000666600000000
-- 047:66666d606666d6006666d600666d6000666d6000ddd600006666000000000000
-- 048:000000000000000000ffffff00fddddd00fddddd00fddddd00fddddd00fddddd
-- 049:0000000000000000ffffff00dddddf00dddddf00dddddf00dddddf00dddddf00
-- 050:000000000000000000ffffff00fddddd00fddddd00fddddd00fddddd00fddddd
-- 051:0000000000000000ffffff00dddddf00dddddf00dddddf00dddddf00dddddf00
-- 052:000000000000000000ffffff00fddddd00fddddd00fddddd00fdffff00fdffff
-- 053:0000000000000000ffffff00dddddf00dddddf00dddddf00ffffdf00ffffdf00
-- 054:000000000000000000ffffff00fddddd00fdffff00fdffff00fdffff00fdffff
-- 055:0000000000000000ffffff00dddddf00ffffdf00ffffdf00ffffdf00ffffdf00
-- 056:000000000000000000666666006ddddd006ddddd006ddddd006ddddd006ddddd
-- 057:000000000000000066666600ddddd600ddddd600ddddd600ddddd600ddddd600
-- 058:000000000000000000666666006ddddd006ddddd006ddddd006ddddd006ddddd
-- 059:000000000000000066666600ddddd600ddddd600ddddd600ddddd600ddddd600
-- 060:000000000000000000666666006ddddd006ddddd006ddddd006d6666006d6666
-- 061:000000000000000066666600ddddd600ddddd600ddddd6006666d6006666d600
-- 062:000000000000000000666666006ddddd006d6666006d6666006d6666006d6666
-- 063:000000000000000066666600ddddd6006666d6006666d6006666d6006666d600
-- 064:00fddddd00fddddd00fdffff00fdffff00fddddd00ffffff0000000000000000
-- 065:dddddf00dddddf00ffffdf00ffffdf00dddddf00ffffff000000000000000000
-- 066:00fdffff00fdffff00fdffff00fdffff00fddddd00ffffff0000000000000000
-- 067:ffffdf00ffffdf00ffffdf00ffffdf00dddddf00ffffff000000000000000000
-- 068:00fdffff00fdffff00fdffff00fdffff00fddddd00ffffff0000000000000000
-- 069:ffffdf00ffffdf00ffffdf00ffffdf00dddddf00ffffff000000000000000000
-- 070:00fdffff00fdffff00fdffff00fdffff00fddddd00ffffff0000000000000000
-- 071:ffffdf00ffffdf00ffffdf00ffffdf00dddddf00ffffff000000000000000000
-- 072:006ddddd006ddddd006d6666006d6666006ddddd006666660000000000000000
-- 073:ddddd600ddddd6006666d6006666d600ddddd600666666000000000000000000
-- 074:006d6666006d6666006d6666006d6666006ddddd006666660000000000000000
-- 075:6666d6006666d6006666d6006666d600ddddd600666666000000000000000000
-- 076:006d6666006d6666006d6666006d6666006ddddd006666660000000000000000
-- 077:6666d6006666d6006666d6006666d600ddddd600666666000000000000000000
-- 078:006d6666006d6666006d6666006d6666006ddddd006666660000000000000000
-- 079:6666d6006666d6006666d6006666d600ddddd600666666000000000000000000
-- 080:000000000000000f000000fd00000fdd0000fddd000fdddd00fddddd0fdddddd
-- 081:00000000f0000000df000000ddf00000dddf0000ddddf000dddddf00ddddddf0
-- 082:000000000000000f000000fd00000fdd0000fddd000fdddd00fddddd0fdddddd
-- 083:00000000f0000000df000000ddf00000dddf0000ddddf000dddddf00ddddddf0
-- 084:000000000000000f000000fd00000fdd0000fddd000fdddd00fddddd0fdfffff
-- 085:00000000f0000000df000000ddf00000dddf0000ddddf000dddddf00fffffdf0
-- 086:000000000000000f000000fd00000fdd0000fddd000fdfff00fdffff0fdfffff
-- 087:00000000f0000000df000000ddf00000dddf0000fffdf000ffffdf00fffffdf0
-- 088:000000000000000f000000fd00000fdf0000fdff000fdfff00fdffff0fdfffff
-- 089:00000000f0000000df000000fdf00000ffdf0000fffdf000ffffdf00fffffdf0
-- 090:0000000000000006000000060000006d0000006d000006dd000006dd00006ddd
-- 091:0000000000000000000000006000000060000000d6000000d6000000dd600000
-- 092:0000000000000006000000060000006d0000006d000006dd000006dd00006ddd
-- 093:0000000000000000000000006000000060000000d6000000d6000000dd600000
-- 094:0000000000000006000000060000006d0000006d000006dd000006d600006dd6
-- 095:0000000000000000000000006000000060000000d6000000d6000000dd600000
-- 096:0fdddddd00fddddd00fddddd000fdfff000fddff0000fddd0000ffff00000000
-- 097:ddddddf0dddddf00dddddf00fffdf000ffddf000dddf0000ffff000000000000
-- 098:0fdddddd00fdffff00fdffff000fdfff000fdfff0000fddd0000ffff00000000
-- 099:ddddddf0ffffdf00ffffdf00fffdf000fffdf000dddf0000ffff000000000000
-- 100:0fdfffff00fdffff00fdffff000fdfff000fdfff0000fddd0000ffff00000000
-- 101:fffffdf0ffffdf00ffffdf00fffdf000fffdf000dddf0000ffff000000000000
-- 102:0fdfffff00fdffff00fdffff000fdfff000fdfff0000fddd0000ffff00000000
-- 103:fffffdf0ffffdf00ffffdf00fffdf000fffdf000dddf0000ffff000000000000
-- 104:0fdfffff00fdffff00fdffff000fdfff000fdfff0000fddd0000ffff00000000
-- 105:fffffdf0ffffdf00ffffdf00fffdf000fffdf000dddf0000ffff000000000000
-- 106:00006ddd0006dddd0006dddd006dd666006d666606dddddd0666666600000000
-- 107:dd600000ddd60000ddd6000066dd6000666d6000ddddd6006666660000000000
-- 108:00006ddd0006dd660006d666006dd666006d666606dddddd0666666600000000
-- 109:dd6000006dd6000066d6000066dd6000666d6000ddddd6006666660000000000
-- 110:00006d660006dd660006d666006dd666006d666606dddddd0666666600000000
-- 111:6d6000006dd6000066d6000066dd6000666d6000ddddd6006666660000000000
-- 112:000000000000000d0000000d000000df000000df00000dff00000dff0000dfff
-- 113:000000000000000000000000d0000000d0000000fd000000fd000000ffd00000
-- 114:000000000000000d0000000d000000df000000df00000dff00000dff0000dfff
-- 115:000000000000000000000000d0000000d0000000fd000000fd000000ffd00000
-- 116:000000000000000d0000000d000000df000000df00000dff00000dfd0000dffd
-- 117:000000000000000000000000d0000000d0000000fd000000fd000000ffd00000
-- 128:0000dfff000dffff000dffff00dffddd00dfdddd0dffffff0ddddddd00000000
-- 129:ffd00000fffd0000fffd0000ddffd000dddfd000fffffd00dddddd0000000000
-- 130:0000dfff000dffdd000dfddd00dffddd00dfdddd0dffffff0ddddddd00000000
-- 131:ffd00000dffd0000ddfd0000ddffd000dddfd000fffffd00dddddd0000000000
-- 132:0000dfdd000dffdd000dfddd00dffddd00dfdddd0dffffff0ddddddd00000000
-- 133:dfd00000dffd0000ddfd0000ddffd000dddfd000fffffd00dddddd0000000000
-- 144:000000000000000000dddddd00dfffff00dfffff00dfffff00dfffff00dfffff
-- 145:0000000000000000dddddd00fffffd00fffffd00fffffd00fffffd00fffffd00
-- 146:000000000000000000dddddd00dfffff00dfffff00dfffff00dfffff00dfffff
-- 147:0000000000000000dddddd00fffffd00fffffd00fffffd00fffffd00fffffd00
-- 148:000000000000000000dddddd00dfffff00dfffff00dfffff00dfdddd00dfdddd
-- 149:0000000000000000dddddd00fffffd00fffffd00fffffd00ddddfd00ddddfd00
-- 150:000000000000000000dddddd00dfffff00dfdddd00dfdddd00dfdddd00dfdddd
-- 151:0000000000000000dddddd00fffffd00ddddfd00ddddfd00ddddfd00ddddfd00
-- 160:00dfffff00dfffff00dfdddd00dfdddd00dfffff00dddddd0000000000000000
-- 161:fffffd00fffffd00ddddfd00ddddfd00fffffd00dddddd000000000000000000
-- 162:00dfdddd00dfdddd00dfdddd00dfdddd00dfffff00dddddd0000000000000000
-- 163:ddddfd00ddddfd00ddddfd00ddddfd00fffffd00dddddd000000000000000000
-- 164:00dfdddd00dfdddd00dfdddd00dfdddd00dfffff00dddddd0000000000000000
-- 165:ddddfd00ddddfd00ddddfd00ddddfd00fffffd00dddddd000000000000000000
-- 166:00dfdddd00dfdddd00dfdddd00dfdddd00dfffff00dddddd0000000000000000
-- 167:ddddfd00ddddfd00ddddfd00ddddfd00fffffd00dddddd000000000000000000
-- 176:000000000000000d000000df00000dff0000dfff000dffff00dfffff0dffffff
-- 177:00000000d0000000fd000000ffd00000fffd0000ffffd000fffffd00ffffffd0
-- 178:000000000000000d000000df00000dff0000dfff000dffff00dfffff0dffffff
-- 179:00000000d0000000fd000000ffd00000fffd0000ffffd000fffffd00ffffffd0
-- 180:000000000000000d000000df00000dff0000dfff000dffff00dfffff0dfddddd
-- 181:00000000d0000000fd000000ffd00000fffd0000ffffd000fffffd00dddddfd0
-- 182:000000000000000d000000df00000dff0000dfff000dfddd00dfdddd0dfddddd
-- 183:00000000d0000000fd000000ffd00000fffd0000dddfd000ddddfd00dddddfd0
-- 184:000000000000000d000000df00000dfd0000dfdd000dfddd00dfdddd0dfddddd
-- 185:00000000d0000000fd000000dfd00000ddfd0000dddfd000ddddfd00dddddfd0
-- 192:0dffffff00dfffff00dfffff000dfddd000dffdd0000dfff0000dddd00000000
-- 193:ffffffd0fffffd00fffffd00dddfd000ddffd000fffd0000dddd000000000000
-- 194:0dffffff00dfdddd00dfdddd000dfddd000dffdd0000dfff0000dddd00000000
-- 195:ffffffd0ddddfd00ddddfd00dddfd000ddffd000fffd0000dddd000000000000
-- 196:0dfddddd00dfdddd00dfdddd000dfddd000dffdd0000dfff0000dddd00000000
-- 197:dddddfd0ddddfd00ddddfd00dddfd000ddffd000fffd0000dddd000000000000
-- 198:0dfddddd00dfdddd00dfdddd000dfddd000dffdd0000dfff0000dddd00000000
-- 199:dddddfd0ddddfd00ddddfd00dddfd000ddffd000fffd0000dddd000000000000
-- 200:0dfddddd00dfdddd00dfdddd000dfddd000dffdd0000dfff0000dddd00000000
-- 201:dddddfd0ddddfd00ddddfd00dddfd000ddffd000fffd0000dddd000000000000
-- 255:7000000707000070007007000007700000077000007007000700007070000007
-- </TILES>

-- <SPRITES>
-- 000:0000000d000000df00000dff0000dfff000dffff00dffffd0dffffd0dffffd00
-- 001:d0000000fd000000ffd00000fffd0000ffffd000dffffd000dffffd000dffffd
-- 002:000000000000000000000000000000dd0000dd6600dd66660d666666d66666dd
-- 003:000000000000000000000000dd00000066dd00006666dd00666666d0dd66666d
-- 004:000000000000000000000000fffffffff2222222f2222222f2222222f22fffff
-- 005:000000000000000000000000ffffffff2222222f2222222f2222222ffffff22f
-- 016:dfffd000dffd0000dfd00000dd00000000000000000000000000000000000000
-- 017:000dfffd0000dffd00000dfd000000dd00000000000000000000000000000000
-- 018:d666dd00d66d0000d6d00000ddd0000000000000000000000000000000000000
-- 019:00dd666d0000d66d00000d6d00000ddd00000000000000000000000000000000
-- 020:f22f0000f22f0000f22f0000ffff000000000000000000000000000000000000
-- 021:0000f22f0000f22f0000f22f0000ffff00000000000000000000000000000000
-- 032:0000000d000000de00000dee0000deee000deeee00deeeed0deeeed0deeeed00
-- 033:d0000000ed000000eed00000eeed0000eeeed000deeeed000deeeed000deeeed
-- 034:000000000000000000000000000000dd0000dd5500dd55550d555555d55555dd
-- 035:000000000000000000000000dd00000055dd00005555dd00555555d0dd55555d
-- 036:000000000000000000000000eeeeeeeee2222222e2222222e2222222e22eeeee
-- 037:000000000000000000000000eeeeeeee2222222e2222222e2222222eeeeee22e
-- 048:deeed000deed0000ded00000dd00000000000000000000000000000000000000
-- 049:000deeed0000deed00000ded000000dd00000000000000000000000000000000
-- 050:d555dd00d55d0000d5d00000ddd0000000000000000000000000000000000000
-- 051:00dd555d0000d55d00000d5d00000ddd00000000000000000000000000000000
-- 052:e22e0000e22e0000e22e0000eeee000000000000000000000000000000000000
-- 053:0000e22e0000e22e0000e22e0000eeee00000000000000000000000000000000
-- 064:0000000d000000dd00000ddd0000dddd000ddddd00dddddd0dddddd0dddddd00
-- 065:d0000000dd000000ddd00000dddd0000ddddd000dddddd000dddddd000dddddd
-- 066:000000000000000000000000000000dd0000dd4400dd44440d444444d44444dd
-- 067:000000000000000000000000dd00000044dd00004444dd00444444d0dd44444d
-- 068:000000000000000000000000ddddddddd2222222d2222222d2222222d22ddddd
-- 069:000000000000000000000000dddddddd2222222d2222222d2222222dddddd22d
-- 080:ddddd000dddd0000ddd00000dd00000000000000000000000000000000000000
-- 081:000ddddd0000dddd00000ddd000000dd00000000000000000000000000000000
-- 082:d444dd00d44d0000d4d00000ddd0000000000000000000000000000000000000
-- 083:00dd444d0000d44d00000d4d00000ddd00000000000000000000000000000000
-- 084:d22d0000d22d0000d22d0000dddd000000000000000000000000000000000000
-- 085:0000d22d0000d22d0000d22d0000dddd00000000000000000000000000000000
-- </SPRITES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c00000dffffff0000009c5461b13e53c52a46d7183b000000000000000000000000f4f4f4d0d0d0566c86333c57
-- </PALETTE>

