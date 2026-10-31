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
Field.CAR_SIZE = 8

Field.LANE_LEFT_EDGE = Field.CENTER - Field.HALF_WIDTH
Field.LANE_TOP_EDGE = Field.CENTER - Field.HALF_WIDTH

Field.GAME_SPEED_SCALE = 32

Field.FUEL_TANK_CAPS = {
	RESERVED_1 = nil,
	RESERVED_2 = nil,
	RESERVED_3 = nil,

	TRIANGLE = 3,
	SQUARE = 4,
	PENTAGON = 5,
	HEXAGON = 6,
	CIRCLE = 8
}

Field.FUEL_THRESHOLDS = {
	Field.FUEL_TANK_CAPS.TRIANGLE,
	Field.FUEL_TANK_CAPS.TRIANGLE + Field.FUEL_TANK_CAPS.SQUARE,
	Field.FUEL_TANK_CAPS.TRIANGLE + Field.FUEL_TANK_CAPS.SQUARE +
		Field.FUEL_TANK_CAPS.PENTAGON,
	Field.FUEL_TANK_CAPS.TRIANGLE + Field.FUEL_TANK_CAPS.SQUARE +
		Field.FUEL_TANK_CAPS.PENTAGON + Field.FUEL_TANK_CAPS.HEXAGON,
	Field.FUEL_TANK_CAPS.TRIANGLE + Field.FUEL_TANK_CAPS.SQUARE +
		Field.FUEL_TANK_CAPS.PENTAGON + Field.FUEL_TANK_CAPS.HEXAGON +
		Field.FUEL_TANK_CAPS.CIRCLE
}

-- Traffic

Traffic.SNAP_SPEED = 1	--px/frame

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
		ACCENT = 90,
		SHADOW = 186
	},
	TANK_SQUARE = {
		BG = 48,
		FG = 144,
		ACCENT = 56,
		SHADOW = 188
	},
	TANK_PENTAGON = {
		BG = 80,
		FG = 176,
		ACCENT = 22,
		SHADOW = 190
	},
	TANK_HEXAGON = {
		BG = 208,
		FG = 210,
		ACCENT = 212,
		SHADOW = 190
	},
	TANK_CIRCLE = {
		BG = 214,
		FG = 216,
		ACCENT = 218,
		SHADOW = 190
	}
}


GFX.PALETTE = {
	TRANSPARENT = 0,
	TRUE_BLACK = 1,
	TRUE_WHITE = 2,

	ACCENT_1 = 7,
	ACCENT_2 = 6,
	ACCENT_3 = 5,
	ACCENT_4 = 4,

	FG_1 = 11,
	FG_2 = 10,
	FG_3 = 9,
	FG_4 = 8,

	BG_1 = 15,
	BG_2 = 14,
	BG_3 = 13,
	BG_4 = 12
}

GFX.COLOR = {
	--values that the game actually uses (try to use these instead of referencing colors directly)
	FG = GFX.PALETTE.FG_4,
	BG = GFX.PALETTE.BG_2,
	OUTLINE = GFX.PALETTE.FG_1,
	ACCENT1 = GFX.PALETTE.ACCENT_1,
	ACCENT2 = GFX.PALETTE.FG_2
}





	-- OTHER LOOKUPS --



-- Field

Field.SPAWN = {
	{ x = Field.LANE_LEFT_EDGE, y = Field.SIZE }, -- UP
	{ x = 0 - Field.HALF_WIDTH, y = Field.LANE_TOP_EDGE }, -- RIGHT
	{ x = Field.CENTER + 1, y = 0 - Field.HALF_WIDTH }, -- DOWN
	{ x = Field.SIZE, y = Field.CENTER + 1 } -- LEFT
}


Field.INTERSECTION = {
	x_min = Field.CENTER - Field.HALF_WIDTH,
	x_max = Field.CENTER + Field.HALF_WIDTH,
	y_min = Field.CENTER - Field.HALF_WIDTH,
	y_max = Field.CENTER + Field.HALF_WIDTH
}


Field.TURN_ZONE = {
    x_min = Field.LANE_LEFT_EDGE,
    x_max = Field.LANE_LEFT_EDGE + Field.LANE_WIDTH - Field.CAR_SIZE,
    y_min = Field.LANE_TOP_EDGE,
    y_max = Field.LANE_TOP_EDGE + Field.LANE_WIDTH - Field.CAR_SIZE,
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
	{ x = Field.LANE_LEFT_EDGE - 2.25 * Field.LANE_WIDTH, y = Field.LANE_WIDTH, },
	{ x = Field.CENTER + 1.25 * Field.LANE_WIDTH, y = Field.LANE_TOP_EDGE - 2.25 * Field.LANE_WIDTH },
	{ x = Field.LANE_LEFT_EDGE + 1.25 * Field.LANE_WIDTH, y = Field.SIZE - 3 * Field.LANE_WIDTH },
	{ x = Field.LANE_WIDTH, y = Field.LANE_TOP_EDGE + 1.25 * Field.LANE_WIDTH } 
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
	},
	{
		GFX.SPRITE.TANK_HEXAGON.BG,
		GFX.SPRITE.TANK_HEXAGON.ACCENT,
		GFX.SPRITE.TANK_HEXAGON.FG
	},
	{
		GFX.SPRITE.TANK_CIRCLE.BG,
		GFX.SPRITE.TANK_CIRCLE.ACCENT,
		GFX.SPRITE.TANK_CIRCLE.FG
	}
}


		-- GLOBAL HELPERS --

-- Move `current` toward `target` by at most `max_step`, snapping on arrival.
function stepToward(current, target, max_step)
    local delta = target - current
    if math.abs(delta) <= max_step then
        return target
    end
    return current + (delta > 0 and max_step or -max_step)
end

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
		new_dir = nil,

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
function Traffic.inTurnZone(item)
    local z = Field.TURN_ZONE
    return item.x >= z.x_min and item.x <= z.x_max
       and item.y >= z.y_min and item.y <= z.y_max
end

function Traffic.canTurn(item, new_dir)
    if item.changed then return false end
    if item.dir == new_dir then return false end
    if (item.dir + 1) % 4 + 1 == new_dir then return false end -- no U-turns
    return Traffic.inTurnZone(item)
end

function Traffic.applyTurns(new_dir)
    if not new_dir then return end
    for _, item in ipairs(Traffic.Active) do
        if Traffic.canTurn(item, new_dir) then
            item.dir = new_dir
            item.changed = true
            local lane = Field.LANE[new_dir]
            item.snap = { axis = lane.axis, value = lane.value }
        end
    end
end


--function for updating the position of cars on the map
function Traffic.updatePositions()
    for _, item in ipairs(Traffic.Active) do
        --ease toward the lane
        if item.snap then
            local axis, target = item.snap.axis, item.snap.value
            if item[axis] < target then
                item[axis] = math.min(item[axis] + Traffic.SNAP_SPEED, target)
            else
                item[axis] = math.max(item[axis] - Traffic.SNAP_SPEED, target)
            end
            if item[axis] == target then item.snap = nil end
        end

        --advance in the current direction
        local move = Traffic.DIRECTION[item.dir]
        item.x = item.x + move.x
        item.y = item.y + move.y
    end
end




--clean up traffic that is not on-screen
function Traffic.cleanup()

	for i = #Traffic.Active, 1, -1 do
		local item = Traffic.Active[i]

		--first check to see if the car has moved through the intersection
		--and flag it if it has
		if not item.thru and Traffic.inIntersection(item) then
			item.thru = true
		end

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
				if lane.type and lane.stored then
					Field.pushToGFX(lane.stored, lane.type, lane.dir)
				end

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
				Field.pushToGFX(lane.stored, lane.type, lane.dir)

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
            local anim = GFX.Sprites.Traffic[lane.dir]
            if #anim.cars == 0 then
                Field.pushToGFX(lane.stored, lane.type, lane.dir, "fuel")
            end

            lane.fuel = lane.fuel + 1
            lane.stored = 0
            lane.last_car_pos = Field.getCoords(Field.ENDPOINTS[lane.dir])

            if lane.level <= 0 then
                lane.level = 1
            end
        end
    end
end


function Field.checkLevels()

	for i, lane in ipairs(Field.Lanes) do
		if lane.level >= 1 then
			local max_capacity = Field.FUEL_THRESHOLDS[lane.level]
			if lane.fuel > max_capacity then
				lane.level = lane.level + 1
			end
		end
	end
end


--push info from the lane to GFX for animations
function Field.pushToGFX(count, color, dir, mode)
    mode = mode or "clear"

    local anim = GFX.Sprites.Traffic[dir]
    anim.type  = color
    anim.count = count
    anim.mode  = mode

    if mode == "fuel" then
        -- Fuel tanks are drawn at 2x scale (16x16), cars are 8x8.
        -- Offset by (4, 4) to center the car on the tank.
        local tank = GFX.FUEL_TANKS[dir]
		local offset = 4
        anim.fuel_target = { x = tank.x + offset, y = tank.y + offset }
    else
        anim.fuel_target = nil
    end

    for i = count, 1, -1 do
        local car = {
            x_pos = Field.ENDPOINTS[dir].x - (Traffic.DIRECTION[dir].x * (i-1) * 4),
            y_pos = Field.ENDPOINTS[dir].y - (Traffic.DIRECTION[dir].y * (i-1) * 4),
            rotation = dir,
            target_x = Field.ENDPOINTS[dir].x,
            target_y = Field.ENDPOINTS[dir].y,
            done = false
        }
        table.insert(anim.cars, car)
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
		local color = math.random(1, 2)
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


--declare a table to keep track of sprites for animated effects
GFX.Sprites = {
	Traffic = {
		{ 
			dir = Input.DIRECTION.UP, type = nil, count = nil,
			cars = { }
		},
		{ 
			dir = Input.DIRECTION.RIGHT, type = nil, count = nil,
			cars = { }
		},
		{ 
			dir = Input.DIRECTION.DOWN, type = nil, count = nil,
			cars = { }
		},
		{ 
			dir = Input.DIRECTION.LEFT, type = nil, count = nil,
			cars = { }
		}
	}
}


--animate the special cars
function GFX.drawSpecial(x_pos, y_pos, rotation)
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


--animate the cars being removed from the lane
function GFX.animateClearedLanesNew()
    local speed = 1  -- pixels per frame; tune to taste

    for _, anim in ipairs(GFX.Sprites.Traffic) do
        local dir      = anim.dir
        local step     = Traffic.DIRECTION[dir]
        local rotation = dir - 1
        local type     = anim.type
        local mode     = anim.mode or "clear"

        if #anim.cars > 0 then

            -- PHASE 1: collapse every car onto the lane endpoint
            local all_collapsed = true
            for _, car in ipairs(anim.cars) do
                if not car.done then
                    if car.x_pos ~= car.target_x or car.y_pos ~= car.target_y then
                        all_collapsed = false
                        car.x_pos = stepToward(car.x_pos, car.target_x, speed)
                        car.y_pos = stepToward(car.y_pos, car.target_y, speed)
                    end
                end
            end

            -- PHASE 2: move as a group
            if all_collapsed then
                if mode == "fuel" then
                    -- Move the collapsed stack toward the fuel tank.
                    local t      = anim.fuel_target
                    local sample = anim.cars[1]
                    local dx     = t.x - sample.x_pos
                    local dy     = t.y - sample.y_pos
                    local dist   = math.sqrt(dx * dx + dy * dy)

					speed = 2

                    if dist <= speed then
                        -- Arrived: release the sprites; the tank sprite is already drawn
                        anim.cars = {}
                    else
                        local nx = (dx / dist) * speed
                        local ny = (dy / dist) * speed
                        for _, car in ipairs(anim.cars) do
							car.done = true
                            car.x_pos = car.x_pos + nx
                            car.y_pos = car.y_pos + ny
                        end
                    end
                else
                    -- "clear": scroll off the field as before
                    for _, car in ipairs(anim.cars) do
                        car.done = true
                        car.x_pos = car.x_pos + step.x * speed
                        car.y_pos = car.y_pos + step.y * speed
                    end

                    for k = #anim.cars, 1, -1 do
                        local car = anim.cars[k]
                        if car.x_pos < Field.ORIGIN_X - Field.HALF_WIDTH or
                           car.x_pos > Field.ORIGIN_X + Field.SIZE or
                           car.y_pos < Field.ORIGIN_Y - Field.HALF_WIDTH or
                           car.y_pos > Field.ORIGIN_Y + Field.SIZE then
                            table.remove(anim.cars, k)
                        end
                    end
                end
            end

            -- DRAW
            for _, car in ipairs(anim.cars) do
                spr(type, car.x_pos, car.y_pos, 0, 1, 0, rotation, 1, 1)
            end
        end
    end
end



function GFX.animateClearedLanes()
    local speed = 1  -- pixels per frame; increase for a faster animation

    for i, lane in ipairs(GFX.Sprites.Traffic) do
        local dir = lane.dir
        local step = Traffic.DIRECTION[dir]
        local rotation = dir - 1
        local type = lane.type

        if #lane.cars > 0 then
            -- Phase 1: move all cars toward the endpoint (collapse)
            for _, car in ipairs(lane.cars) do
                if not car.done then
                    local dx = car.target_x - car.x_pos
                    local dy = car.target_y - car.y_pos
                    if dx ~= 0 or dy ~= 0 then
                        car.x_pos = car.x_pos + step.x * speed
                        car.y_pos = car.y_pos + step.y * speed

                        -- clamp so we don't overshoot the target
                        if step.x > 0 and car.x_pos > car.target_x then car.x_pos = car.target_x end
                        if step.x < 0 and car.x_pos < car.target_x then car.x_pos = car.target_x end
                        if step.y > 0 and car.y_pos > car.target_y then car.y_pos = car.target_y end
                        if step.y < 0 and car.y_pos < car.target_y then car.y_pos = car.target_y end
                    end
                end
            end

            -- Check if every car has reached the endpoint
            local all_at_target = true
            for _, car in ipairs(lane.cars) do
                if not car.done and (car.x_pos ~= car.target_x or car.y_pos ~= car.target_y) then
                    all_at_target = false
                    break
                end
            end

            -- Once they are all together, start moving them off-screen
            if all_at_target then
                for _, car in ipairs(lane.cars) do
                    car.done = true
                end
            end

            -- Phase 2: move done cars off the field
            for _, car in ipairs(lane.cars) do
                if car.done then
                    car.x_pos = car.x_pos + step.x * speed
                    car.y_pos = car.y_pos + step.y * speed
                end
            end

            -- Draw the cars
            for _, car in ipairs(lane.cars) do
                spr(type, car.x_pos, car.y_pos, 0, 1, 0, rotation, 1, 1)
            end

            -- Remove cars that are completely off-screen (iterate backwards)
            for k = #lane.cars, 1, -1 do
                local car = lane.cars[k]
                if car.done and (
                    car.x_pos < Field.ORIGIN_X - Field.HALF_WIDTH or
                    car.x_pos > Field.ORIGIN_X + Field.SIZE or
                    car.y_pos < Field.ORIGIN_Y - Field.HALF_WIDTH or
                    car.y_pos > Field.ORIGIN_Y + Field.SIZE
                ) then
                    table.remove(lane.cars, k)
                end
            end
        end
    end
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
			GFX.drawSpecial(x_pos, y_pos, rotation)
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
		
		--print the actual names of the color/lane direction as strings
		print(lane.type or ("none" ))
		

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
		spr(GFX.SPRITE.TANK_TRIANGLE.SHADOW, x_pos + 4, y_pos + 2, 0, 2, 0, 0, 2, 2)
		spr(GFX.SPRITE.TANK_TRIANGLE.BG, x_pos, y_pos, 0, 2, 0, 0, 2, 2)
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
		Field.checkLevels()
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
	end

	GFX.drawStored()
	GFX.animateClearedLanesNew()
	GFX.drawFuelTanks()
	GFX.maskEdge()
	
	--Debug.printCoords()
	Debug.printActive()
	--Debug.printQueue()
	Debug.showLaneStats()
	--Debug.showFuelTanks()
	--Debug.showEndpoints()

end
-- <TILES>
-- 000:7000007087000780887078808887888088888880000000000000000000000000
-- 001:000000000000b0000000b000000bfb00000bfb0000bfffb000bfbfb000bb0bb0
-- 002:00000000000bbb0000bb7bb000b777b000b777b000b7b7b000bbbbb000b000b0
-- 003:00000000000eee00000e9e0000e999e000e999e000e9e9e000eeeee000000000
-- 004:0000b000000b7b0000b7e7b000be2eb000b2d2b000bb0bb000b000b000000000
-- 005:0000b000000beb0000be2eb000b272b000b7b7b000bb0bb000b000b000000000
-- 006:0000b000000b2b0000b272b000b7e7b000bebeb000bb0bb000b000b000000000
-- 007:0000f000000f7f0000f7e7f000fe2ef000f2f2f000ff0ff000f000f000000000
-- 008:0000f000000fef0000fe2ef000f272f000f7f7f000ff0ff000f000f000000000
-- 009:0000f000000f2f0000f27cf000f7e7f000fefef000ff0ff000f000f000000000
-- 016:000000000000000b0000000b000000be000000be00000bee00000bee0000beee
-- 017:000000000000000000000000b0000000b0000000eb000000eb000000eeb00000
-- 018:000000000000000000bbbbbb00beeeee00beeeee00beeeee00beeeee00beeeee
-- 019:0000000000000000bbbbbb00eeeeeb00eeeeeb00eeeeeb00eeeeeb00eeeeeb00
-- 020:000000000000000b000000be00000bee0000beee000beeee00beeeee0beeeeee
-- 021:00000000b0000000eb000000eeb00000eeeb0000eeeeb000eeeeeb00eeeeeeb0
-- 022:000000000000bbbb0000beee000beeee000beeee00beeeee00beeeee0beeeeee
-- 023:00000000bbbb0000eeeb0000eeeeb000eeeeb000eeeeeb00eeeeeb00eeeeedb0
-- 024:00000000000000bb0000bbee000beebb00bebbbb00bebbbb0bebbbbb0bebbbbb
-- 025:00000000bb000000eebb0000bbeeb000bbbbeb00bbbbeb00bbbbbeb0bbbbbeb0
-- 032:0000beee000beeee000beeee00beeeee00bebbbb0beeeeee0bbbbbbb00000000
-- 033:eeb00000eeeb0000eeeb0000eeeeb000bbbeb000eeeeeb00bbbbbb0000000000
-- 034:00beeeee00beeeee00beeeee00bebbbb00beeeee00bbbbbb0000000000000000
-- 035:eeeeeb00eeeeeb00eeeeeb00bbbbeb00eeeeeb00bbbbbb000000000000000000
-- 036:0beeeeee00beeeee00beeeee000beeee000bebbb0000beee0000bbbb00000000
-- 037:eeeeeeb0eeeeeb00eeeeeb00eeeeb000bbbeb000eeeb0000bbbb000000000000
-- 038:0beeeeee00beeeee00beeeee000beeee000be9990000beee0000bbbb00000000
-- 039:eeeeedb0eeeeeb00eeeeeb00eeeeb000999eb000eeeb0000bbbb000000000000
-- 040:0bebbbbb0bebbbbb00bebbbb00bebbbb000beebb0000bbee000000bb00000000
-- 041:bbbbbeb0bbbbbeb0bbbbeb00bbbbeb00bbeeb000eebb0000bb00000000000000
-- 052:0000000000000000000000000000000000000000000000000000000b0000000b
-- 064:000000000000000000000bbb00000bbb0000bbbb000000000000000000000000
-- 065:0000000000000000bb000000bb000000bbb00000000000000000000000000000
-- 066:000000bb000000bb00000bbb00000bbb0000bbbb000000000000000000000000
-- 067:b0000000b0000000bb000000bb000000bbb00000000000000000000000000000
-- 068:000000bb000000bb00000bbb00000bbb0000bbbb000000000000000000000000
-- 069:b0000000b0000000bb000000bb000000bbb00000000000000000000000000000
-- 086:000000000000000000000000000000000000000000000000000000000000bbbb
-- 087:00000000000000000000000000000000000000000000000000000000bbbb0000
-- 088:0000000000000000000000000000000000000000000000000000bbbb0000bbbb
-- 089:000000000000000000000000000000000000000000000000bbbb0000bbbb0000
-- 090:00000000000000000000000000000000000000000000bbbb0000bbbb0000bbbb
-- 091:0000000000000000000000000000000000000000bbbb0000bbbb0000bbbb0000
-- 092:000000000000000000000000000000000000bbbb0000bbbb0000bbbb0000bbbb
-- 093:00000000000000000000000000000000bbbb0000bbbb0000bbbb0000bbbb0000
-- 096:00000000000000000000bbbb0000bbbb00000000000000000000000000000000
-- 097:0000000000000000bbbb0000bbbb000000000000000000000000000000000000
-- 098:000000000000bbbb0000bbbb0000bbbb00000000000000000000000000000000
-- 099:00000000bbbb0000bbbb0000bbbb000000000000000000000000000000000000
-- 100:0000bbbb0000bbbb0000bbbb0000bbbb00000000000000000000000000000000
-- 101:bbbb0000bbbb0000bbbb0000bbbb000000000000000000000000000000000000
-- 102:0000bbbb0000bbbb0000bbbb0000bbbb00000000000000000000000000000000
-- 103:bbbb0000bbbb0000bbbb0000bbbb000000000000000000000000000000000000
-- 104:0000bbbb0000bbbb0000bbbb0000bbbb00000000000000000000000000000000
-- 105:bbbb0000bbbb0000bbbb0000bbbb000000000000000000000000000000000000
-- 106:0000bbbb0000bbbb0000bbbb0000bbbb00000000000000000000000000000000
-- 107:bbbb0000bbbb0000bbbb0000bbbb000000000000000000000000000000000000
-- 108:0000bbbb0000bbbb0000bbbb0000bbbb00000000000000000000000000000000
-- 109:bbbb0000bbbb0000bbbb0000bbbb000000000000000000000000000000000000
-- 124:00000000000000000000000000000000000000000000000000000000000bbbbb
-- 125:00000000000000000000000000000000000000000000000000000000bbbbb000
-- 126:00000000000000000000000000000000000000000000000000009999000bbbbb
-- 127:00000000000000000000000000000000000000000000000099990000bbbbb000
-- 128:00000000000000000000000000000bbb00000bbb000000000000000000000000
-- 129:000000000000000000000000bbb00000bbb00000000000000000000000000000
-- 130:00000000000000000000999900000bbb00000bbb000000000000000000000000
-- 131:000000000000000099990000bbb00000bbb00000000000000000000000000000
-- 132:00000000000000000000bbbb00000bbb00000bbb000000000000000000000000
-- 133:0000000000000000bbbb0000bbb00000bbb00000000000000000000000000000
-- 134:000000000000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 135:00000000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
-- 136:000999990000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 137:99999000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
-- 138:000bbbbb0000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 139:bbbbb000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
-- 140:000bbbbb0000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 141:bbbbb000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
-- 142:000bbbbb0000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 143:bbbbb000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
-- 144:0000000000000000000000000000000000000000000000000000bbbb000bbbbb
-- 145:000000000000000000000000000000000000000000000000bbbb0000bbbbb000
-- 146:000000000000000000000000000000000000000000000bbb0000bbbb000bbbbb
-- 147:0000000000000000000000000000000000000000bbb00000bbbb0000bbbbb000
-- 148:0000000000000000000000000000000b000000bb00000bbb0000bbbb000bbbbb
-- 149:000000000000000000000000b0000000bb000000bbb00000bbbb0000bbbbb000
-- 160:000bbbbb0000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 161:bbbbb000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
-- 162:000bbbbb0000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 163:bbbbb000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
-- 164:000bbbbb0000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 165:bbbbb000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
-- 192:0000000000000000000000000000000000000bbb000000000000000000000000
-- 193:00000000000000000000000000000000bbb00000000000000000000000000000
-- 194:0000000000000000000000000000099900000bbb000000000000000000000000
-- 195:00000000000000000000000099900000bbb00000000000000000000000000000
-- 196:00000000000000000000000000000bbb00000bbb000000000000000000000000
-- 197:000000000000000000000000bbb00000bbb00000000000000000000000000000
-- 198:00000000000000000000999900000bbb00000bbb000000000000000000000000
-- 199:000000000000000099990000bbb00000bbb00000000000000000000000000000
-- 200:00000000000000000000bbbb00000bbb00000bbb000000000000000000000000
-- 201:0000000000000000bbbb0000bbb00000bbb00000000000000000000000000000
-- 202:00000000000099990000bbbb00000bbb00000bbb000000000000000000000000
-- 203:0000000099990000bbbb0000bbb00000bbb00000000000000000000000000000
-- 204:000000000000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 205:00000000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
-- 206:000999990000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 207:99999000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
-- 210:0000000000000000000000000000000000000000000000000000000000099999
-- 211:0000000000000000000000000000000000000000000000000000000099999000
-- 212:00000000000000000000000000000000000000000000000000000000000bbbbb
-- 213:00000000000000000000000000000000000000000000000000000000bbbbb000
-- 214:00000000000000000000000000000000000000000000000000009999000bbbbb
-- 215:00000000000000000000000000000000000000000000000099990000bbbbb000
-- 216:0000000000000000000000000000000000000000000000000000bbbb000bbbbb
-- 217:000000000000000000000000000000000000000000000000bbbb0000bbbbb000
-- 218:0000000000000000000000000000099900000999000099990000bbbb000bbbbb
-- 219:000000000000000000000000999000009990000099990000bbbb0000bbbbb000
-- 220:00000000000000000000000000000bbb00000bbb0000bbbb0000bbbb000bbbbb
-- 221:000000000000000000000000bbb00000bbb00000bbbb0000bbbb0000bbbbb000
-- 224:000bbbbb0000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 225:bbbbb000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
-- 226:000bbbbb0000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 227:bbbbb000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
-- 228:000bbbbb0000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 229:bbbbb000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
-- 230:000bbbbb0000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 231:bbbbb000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
-- 232:000bbbbb0000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 233:bbbbb000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
-- 234:000bbbbb0000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 235:bbbbb000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
-- 236:000bbbbb0000bbbb0000bbbb00000bbb00000bbb000000000000000000000000
-- 237:bbbbb000bbbb0000bbbb0000bbb00000bbb00000000000000000000000000000
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
-- 000:1a1c2c00000dffffff0000009c5461b13e53c52a46d7183bf4f4f4e9eaedd4d8e2b6bed83b404f333c572937601f326a
-- </PALETTE>

