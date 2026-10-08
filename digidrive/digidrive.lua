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
	SELECTOR_ORIGIN = 0
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
		thru = false
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


--define the queue of actions
Field.Queue = { }


--define the game field lanes

Field.Lanes = {
	{ 
		type = nil,
		stored = 0,
		fuel = 0,
		decay_rate = 0.5,
		
		queue = { }
	},
	{
		type = nil,
		stored = 0,
		fuel = 0,
		decay_rate = 0.5,
		
		queue = { }
	},
		{
		type = nil,
		stored = 0,
		fuel = 0,
		decay_rate = 0.5,
		
		queue = { }
	},
		{
		type = nil,
		stored = 0,
		fuel = 0,
		decay_rate = 0.5,
		
		queue = { }
	}
}


--handle cars that are at the end of the lane
function Field.updateLanes()

	for i, item in ipairs(Traffic.Active) do
		local endpoint = Field.ENDPOINTS[item.dir]
		if item.x == endpoint.x and item.y == endpoint.y then
			--update the lane stats
			local lane = Field.Lanes[item.dir]
			
			--special cars always clear the lane
			if item.color == Traffic.TYPE.SPECIAL then
				lane.type = nil
				lane.stored = 0
			--then check to see if the lane is already defined
			--and assign it if not
			elseif Field.Lanes[item.dir].type == nil then
				Field.Lanes[item.dir].type = item.color
				lane.stored = lane.stored + 1
				table.remove(Traffic.Active, i)
			elseif Field.Lanes[item.dir].type == item.color then
				lane.stored = lane.stored + 1
				table.remove(Traffic.Active, i)
			else
				--wrong color resets the lane
				lane.type = nil
				lane.stored = 0
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
	
--declare variables
GFX.selector_length = 0


--animate the special cars
function GFX.drawSpecial(x_pos, y_pos, rotation, thru)
	local t = time()
	local frame_count = 6
	--modulate the frame rate to slow down the animation
	t = math.floor(t / GFX.ANIM_FRAMERATE_MOD)
	local frame = t % frame_count

	spr(GFX.SPRITE.SPECIAL + frame, x_pos, y_pos, 0, 1, 0, rotation, 1, 1)


			if frame <= 2 then
				sfx(00, "A-6", 2, 0, 7, 0)
			elseif frame > 2 then
				sfx(00, "E-6", 2, 0, 7, 0)
			end
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
				local endpoint = Field.ENDPOINTS[i]
				local type = lane.type
				--shift the sprite using Traffic.DIRECTION
				local x_pos = endpoint.x - (Traffic.DIRECTION[i].x * (j-1) * 3)
				local y_pos = endpoint.y - (Traffic.DIRECTION[i].y * (j-1) * 3)
				--TIC 80 expects rotation val from 0-3, 
				--we have 1-4:
				local rotation = i - 1
				spr(type, x_pos, y_pos, 0, 1, 0, rotation, 1, 1)
			end
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
	
	print(mouse_x .. ", " .. mouse_y, GFX.COLOR.FG)
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



	-- MAIN --
	
	

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
	
	--Debug.printCoords()
	Debug.printActive()
	Debug.printQueue()

end
-- <TILES>
-- 000:70000070c70007c0cc707cc0ccc7ccc0ccccccc0000000000000000000000000
-- 001:0000d0000000d000000dfd00000dfd0000dfffd000dfdfd000dd0dd000000000
-- 002:000ddd0000dd7dd000d777d000d777d000d7d7d000ddddd000d000d000000000
-- 003:000fff00000fcf0000fcccf000fcccf000fcfcf000fffff00000000000000000
-- 004:0000d000000d7d0000d7e7d000de2ed000d2d2d000dd0dd000d000d000000000
-- 005:0000d000000ded0000de2ed000d272d000d7d7d000dd0dd000d000d000000000
-- 006:0000d000000d2d0000d272d000d7e7d000deded000dd0dd000d000d000000000
-- 007:0000f000000f7f0000f7e7f000fe2ef000f2f2f000ff0ff000f000f000000000
-- 008:0000f000000fef0000fe2ef000f272f000f7f7f000ff0ff000f000f000000000
-- 009:0000f000000f2f0000f27cf000f7e7f000fefef000ff0ff000f000f000000000
-- 128:0000000f000000ff00000fff0000ffff000fffff00ffffff0ffffff0ffffff00
-- 129:f0000000ff000000fff00000ffff0000fffff000ffffff000ffffff000ffffff
-- 130:0000000000000000000000070000777700077777007777770777777777777777
-- 131:0000000000000000700000007777000077777000777777007777777077777777
-- 132:0000000000000777000007770000077777777777777777777777777777777777
-- 133:0000000077700000777000007770000077777777777777777777777777777777
-- 134:000000000000000000000000dddddddddddddddddddddddddddddddddddddddd
-- 135:000000000000000000000000dddddddddddddddddddddddddddddddddddddddd
-- 144:fffff000ffff0000fff00000ff00000000000000000000000000000000000000
-- 145:000fffff0000ffff00000fff000000ff00000000000000000000000000000000
-- 146:7777770077770000777000007770000000000000000000000000000000000000
-- 147:0077777700007777000007770000077700000000000000000000000000000000
-- 148:7777000077770000777700007777000000000000000000000000000000000000
-- 149:0000777700007777000077770000777700000000000000000000000000000000
-- 150:dddd0000dddd0000dddd0000dddd000000000000000000000000000000000000
-- 151:0000dddd0000dddd0000dddd0000dddd00000000000000000000000000000000
-- 160:0000000e000000ee00000eee0000eeee000eeeee00eeeeee0eeeeee0eeeeee00
-- 161:e0000000ee000000eee00000eeee0000eeeee000eeeeee000eeeeee000eeeeee
-- 162:0000000000000000000000050000555500055555005555550555555555555555
-- 163:0000000000000000500000005555000055555000555555005555555055555555
-- 164:0000000000000555000005550000055555555555555555555555555555555555
-- 165:0000000055500000555000005550000055555555555555555555555555555555
-- 166:000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 167:000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 176:eeeee000eeee0000eee00000ee00000000000000000000000000000000000000
-- 177:000eeeee0000eeee00000eee000000ee00000000000000000000000000000000
-- 178:5555550055550000555000005550000000000000000000000000000000000000
-- 179:0055555500005555000005550000055500000000000000000000000000000000
-- 180:5555000055550000555500005555000000000000000000000000000000000000
-- 181:0000555500005555000055550000555500000000000000000000000000000000
-- 182:eeee0000eeee0000eeee0000eeee000000000000000000000000000000000000
-- 183:0000eeee0000eeee0000eeee0000eeee00000000000000000000000000000000
-- 192:0000000d000000dd00000ddd0000dddd000ddddd00dddddd0dddddd0dddddd00
-- 193:d0000000dd000000ddd00000dddd0000ddddd000dddddd000dddddd000dddddd
-- 194:0000000000000000000000040000444400044444004444440444444444444444
-- 195:0000000000000000400000004444000044444000444444004444444044444444
-- 196:0000000000000444000004440000044444444444444444444444444444444444
-- 197:0000000044400000444000004440000044444444444444444444444444444444
-- 198:000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
-- 199:000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
-- 208:ddddd000dddd0000ddd00000dd00000000000000000000000000000000000000
-- 209:000ddddd0000dddd00000ddd000000dd00000000000000000000000000000000
-- 210:4444440044440000444000004440000000000000000000000000000000000000
-- 211:0044444400004444000004440000044400000000000000000000000000000000
-- 212:4444000044440000444400004444000000000000000000000000000000000000
-- 213:0000444400004444000044440000444400000000000000000000000000000000
-- 214:ffff0000ffff0000ffff0000ffff000000000000000000000000000000000000
-- 215:0000ffff0000ffff0000ffff0000ffff00000000000000000000000000000000
-- 255:2000000202000020002002000002200000022000002002000200002020000002
-- </TILES>

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

