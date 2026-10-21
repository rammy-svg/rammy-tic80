-- title:   palette-swap
-- author:  Ramona Melfry
-- desc:    little palette swap function test
-- script:  lua

t=0
x=96
y=24
n_palette=nil

SPRITES = {
	['ticboy'] = {
		ID = 1,
		H = 2, W = 2,
		FRAMES = 2,
		KEY = 14,
		PALETTES = {
				DEFAULT = 1,
				YELLOW = 2,
				RED = 3,
				GREEN = 4
		}
	}
}

PALETTES = {
	ticboy = {  
		DEFAULT = { 10, 08 },
		YELLOW = { 04, 02 }, 
		RED = { 02, 01 },
		GREEN = { 06, 07 }
	}
}

--helper function to remap colors in a palette
--call with no arguments to reset palette
function pal(old_color, new_color)
    if old_color == nil and new_color == nil then
        -- reset the palette map to default mappings
        for i = 0, 15 do 
            poke4(0x3FF0 * 2 + i, i) 
        end
    else
        -- map old color to new color
        poke4(0x3FF0 * 2 + old_color, new_color)
    end
end

function frameTileOffset(sprite, frame_id)
	local w = sprite.W
	local h = sprite.H

	local frames = sprite.FRAMES_PER_ROW or (16//w)
	local frame_x = frame_id % frames
	local frame_y = frame_id // frames

	return frame_x * w + frame_y * h * 16
end

--draw a sprite with a specified palette
--leave "new_palette" as nil for default palette
--use "t" and "speed" to control animation
--pass "frame" directly to "t" for manual control
function spr2(name, x, y, scale, flip, rotate, t, speed, palette)
	local sprite = SPRITES[name]
	local speed = speed or 2
	local current_frame = (t * speed // 60) % sprite.FRAMES
	local frame_tile = sprite.ID + frameTileOffset(sprite, current_frame)

	local pal_table = PALETTES[name] or nil
	local pal_changed = nil

    if palette and pal_table and pal_table[palette] then
        local old_pal = pal_table.DEFAULT
        local new_pal = pal_table[palette]
        pal_changed = {}
        for i = 1, math.min(#old_pal, #new_pal) do
            pal(old_pal[i], new_pal[i])
            pal_changed[#pal_changed+1] = old_pal[i]
        end
    end

    spr(frame_tile, x, y, sprite.KEY, scale, flip, rotate, sprite.W, sprite.H)

    if pal_changed then
        for i = 1, #pal_changed do
            pal(pal_changed[i], pal_changed[i])
        end
    end

end


function TIC()

	if btn(0) then y=y-1 end
	if btn(1) then y=y+1 end
	if btn(2) then x=x-1 end
	if btn(3) then x=x+1 end
	
	if keyp(28) then n_palette = 'DEFAULT' end 
	if keyp(29) then n_palette = 'YELLOW' end
	if keyp(30) then n_palette = 'RED' end
	if keyp(31) then n_palette = 'GREEN' end

	cls(13)
	
	spr2('ticboy',x,y,3,0,0,t,2,n_palette)
	print("HELLO WORLD!",84,84)
	t=t+1
end

-- <TILES>
-- 001:eccccccccc888888caaaaaaaca888888cacccccccacc0ccccacc0ccccacc0ccc
-- 002:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
-- 003:eccccccccc888888caaaaaaaca888888cacccccccacccccccacc0ccccacc0ccc
-- 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
-- 017:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 020:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- 033:eccccccccc222222c4444444c4222222c4ccccccc4cc0cccc4cc0cccc4cc0ccc
-- 034:ccccceee2222ccee44440cee22240ceeccc40ccc0cc40c0c0cc40c0c0cc40c0c
-- 035:eccccccccc222222c4444444c4222222c4ccccccc4ccccccc4cc0cccc4cc0ccc
-- 036:ccccceee2222ccee44440cee22240ceeccc40cccccc40c0c0cc40c0c0cc40c0c
-- 049:c4ccccccc4444444c444c444c4444cccc4444444c2222222cc000cccecccccec
-- 050:ccc400cc44440ccec4440cee44440cee44440cee2222ccee000cceeecccceeee
-- 051:c4ccccccc4444444c444c444c4444cccc4444444c2222222cc000cccecccccec
-- 052:ccc400cc44440ccec4440cee44440cee44440cee2222ccee000cceeecccceeee
-- 065:eccccccccc111111c2222222c2111111c2ccccccc2cc0cccc2cc0cccc2cc0ccc
-- 066:ccccceee1111ccee22220cee11120ceeccc20ccc0cc20c0c0cc20c0c0cc20c0c
-- 067:eccccccccc111111c2222222c2111111c2ccccccc2ccccccc2cc0cccc2cc0ccc
-- 068:ccccceee1111ccee22220cee11120ceeccc20cccccc20c0c0cc20c0c0cc20c0c
-- 081:c2ccccccc2222222c222c222c2222cccc2222222c1111111cc000cccecccccec
-- 082:ccc200cc22220ccec2220cee22220cee22220cee1111ccee000cceeecccceeee
-- 083:c2ccccccc2222222c222c222c2222cccc2222222c1111111cc000cccecccccec
-- 084:ccc200cc22220ccec2220cee22220cee22220cee1111ccee000cceeecccceeee
-- 097:eccccccccc777777c6666666c6777777c6ccccccc6cc0cccc6cc0cccc6cc0ccc
-- 098:ccccceee7777ccee66660cee77760ceeccc60ccc0cc60c0c0cc60c0c0cc60c0c
-- 099:eccccccccc777777c6666666c6777777c6ccccccc6ccccccc6cc0cccc6cc0ccc
-- 100:ccccceee7777ccee66660cee77760ceeccc60cccccc60c0c0cc60c0c0cc60c0c
-- 113:c6ccccccc6666666c666c666c6666cccc6666666c7777777cc000cccecccccec
-- 114:ccc600cc66660ccec6660cee66660cee66660cee7777ccee000cceeecccceeee
-- 115:c6ccccccc6666666c666c666c6666cccc6666666c7777777cc000cccecccccec
-- 116:ccc600cc66660ccec6660cee66660cee66660cee7777ccee000cceeecccceeee
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

