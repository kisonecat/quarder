pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- in2the4
-- by kisonecat

sfx_move = 0
sfx_beat = 1
sfx_note_c = 2
sfx_note_e = 3
sfx_note_g = 4
sfx_note_low_g = 5
sfx_note_low_e = 6
sfx_error_1 = 7
sfx_error_2 = 8

spr_mark_long = 30
spr_mark_short = 31

beats_per_second = 2
last_beat = 0

beats = {}
beat_depth = 5
direction = 0

labels = {}
bolded = {}
cards = {}
card_x = {}
card_y = {}

timeline = {}

selected = {}

color_order = {8, 3, 12}

function _init()
   reset_selection()
   
   for i=1, 10 do
      labels[i] = 48 + i - 1
      bolded[i] = 48 - 16 + i - 1
      card_x[i] = 64 - 4
      card_y[i] = 64 - 4      
   end

   shuffle()

   
   px = 1
   py = cards[px]
end

function shuffle()
   for i=1, 10 do
      cards[i] = i
   end

   for i=10, 2, -1 do
      local j = flr(rnd(i))+1
      local s = cards[j]
      cards[j] = cards[i]
      cards[i] = s
   end
end

tile_width = 10
tile_height = 9

margin_x = (128 - tile_width * 10) / 2
margin_y = (128 - tile_height * 10) / 2

function board_x(x)
   return (x-1)*tile_width + margin_x
end

function board_y(y)
   return 128 - 8 - ((y-1)*tile_height + margin_y)
end

function reset_selection()
   for i=1, 10 do
      selected[i] = 0
   end
   selected_count = 0
end

function selection_error()
   sfx(sfx_error_1)
   sfx(sfx_error_2)
   reset_selection()
end

function next_puzzle()
   resorted = {}
   resorted_x = {}
   resorted_y = {}   
   
   for i = 1,10 do
      if selected[i] == 0 then
	 add( resorted, cards[i] )
	 add( resorted_x, card_x[i] )
	 add( resorted_y, card_y[i] )	 
      end
   end
   
   for i = 1,10 do
      if selected[i] != 0 then
	 add( resorted, cards[i] )
	 add( resorted_x, card_x[i] )
	 add( resorted_y, card_y[i] )	 	 
      end
   end

   cards = resorted
   card_x = resorted_x
   card_y = resorted_y

   function swap(i,j)
      local s = cards[i]
      cards[i] = cards[j]
      cards[j] = s

      local s = card_x[i]
      card_x[i] = card_x[j]
      card_x[j] = s

      local s = card_y[i]
      card_y[i] = card_y[j]
      card_y[j] = s
   end

   local transpositions = { {7, 8}, {7, 9}, {7, 10}, {8, 9}, {8, 10}, {9, 10} }

   for i=1, 9 do
      local r = flr(rnd(transpositions)) + 1
      swap( transpositions[r][1], transpositions[r][2] )
   end
   
   -- shuffle the last four
   --for i=10, 2, -1 do
   --local j = flr(rnd(i))+1
   --local s = cards[j]
   --cards[j] = cards[i]
   --cards[i] = s
   --end
   
   reset_selection()
end

function update_selection()
   if (selected_count == 0) then
      return
   end
      
   if (selected_count == 1) then
      direction = 0
      sfx(sfx_note_c)
   end

   local s1, s2, s3, s4
   
   for i=1, 10 do
      if selected[i] == 1 then
	 s1 = i
      end
      if selected[i] == 2 then
	 s2 = i
      end
      if selected[i] == 3 then
	 s3 = i
      end
      if selected[i] == 4 then
	 s4 = i
      end
   end
   
   if (selected_count == 2) then
      direction = 1
      if (cards[s1] < cards[s2]) then
	 direction = 1
      end
      if (cards[s1] > cards[s2]) then      
	 direction = -1
      end
      
      if (direction == 1) then
	 sfx(sfx_note_e)
      end
      if (direction == -1) then
	 sfx(sfx_note_low_g)
      end
   end

   if (selected_count == 3) then
      local good = false

      if ((s1 > s2) and (s2 > s3)) or
	 ((s3 > s2) and (s2 > s1)) then
	 if direction == 1 then
	    if (cards[s2] < cards[s3]) then
	       good = true
	    end
	 end
	 if direction == -1 then
	    if (cards[s2] > cards[s3]) then
	       good = true
	    end
	 end
      end

      if (good and direction == 1) then
	 sfx(sfx_note_g)
      end
      
      if (good and direction == -1) then
	 sfx(sfx_note_low_e)
      end

      if not good then
	 selection_error()
      end
   end

   if (selected_count == 4) then
      local good = false
      
      if ((s1 > s2) and (s3 > s4)) or
	 ((s2 > s1) and (s4 > s3)) then
	 if direction == 1 then
	    if (cards[s3] < cards[s4]) then
	       good = true
	    end
	 end
	 if direction == -1 then
	    if (cards[s3] > cards[s4]) then
	       good = true
	    end
	 end
      end

      if (good and direction == 1) then
	 sfx(sfx_note_c, 1)
	 sfx(sfx_note_e, 2)
	 sfx(sfx_note_g, 3)
      end
      
      if (good and direction == -1) then
	 sfx(sfx_note_c, 1)
	 sfx(sfx_note_low_g, 2)
	 sfx(sfx_note_low_e, 3)
      end

      if not good then
	 selection_error()
      else
	 next_puzzle()
      end
   end
end

function _update60()
   local move_x = false
   local move_y = false
   local move_select = false

   for i = 1,10 do
      local factor = 5
      card_x[i] = (factor*card_x[i] + board_x(i))/(factor + 1)
      card_y[i] = (factor*card_y[i] + board_y(cards[i]))/(factor + 1)  
   end
   
   if (btnp(4) or btnp(5)) then
      if selected[px] != 0 then
	 reset_selection()
	 selection_error()
      else
	 selected_count = selected_count + 1
	 selected[px] = selected_count
      end
      
      move_select = true
      add( timeline, { kind = 15, time = time() } )
      update_selection()
   end
   
   if (btnp(1)) then
      px = px + 1
      move_x = true
      add( timeline, { kind = 12, time = time() } )
   end
    
   if (btnp(0)) then
      px = px - 1
      move_x = true
      add( timeline, { kind = 11, time = time() } )      
   end

   if move_x then
      if (px < 1) px = 1
      if (px > 10) px = 10
      py = cards[px]
   end

   -- FIXME do not do both
   
   if (btnp(2)) then
      py = py + 1
      move_y = true
      add( timeline, { kind = 13, time = time() } )      
   end
    
   if (btnp(3)) then
      py = py - 1
      move_y = true
      add( timeline, { kind = 14, time = time() } )            
   end

   if move_y then
      if (py < 1) py = 1
      if (py > 10) py = 10
      for i=1,10 do
	 if cards[i] == py then
	    px = i
	 end
      end
   end

   if move_x or move_y then
      sfx(sfx_move)
   end

   local t = time()

   if flr(t * beats_per_second) > flr(last_beat * beats_per_second) then
      last_beat = t
      sfx(sfx_beat)
   end
   
   if move_x or move_y or move_select then
      add( beats, t * beats_per_second)
      if #beats > beat_depth then
	 del( beats, beats[1] )
      end
   end
end


function draw_edges(sense, color)
   for i=1, 10 do
      local ci = cards[i]
      local xi = card_x[i] + 4
      local yi = card_y[i] + 4
      for j=i+1, 10 do
	 local cj = cards[j]
	 local xj = card_x[j] + 4
	 local yj = card_y[j] + 4

	 if ci * sense < cj * sense then
	    local inbetween = false
	    for k = i+1, j-1 do
	       local ck = cards[k]

	       if ci * sense < ck * sense and ck * sense < cj * sense then
		  inbetween = true
	       end
	    end

	    if inbetween == false then
	       line( xi, yi, xj, yj, color )
	    end
	 end
      end
   end   
end

function draw_timeline()
   local height = 6
   local width = 4
   local t = time() * beats_per_second * 4 - 128/width
   
   for i = flr(t), flr(t) + 4*8 do
      local x = width*(i - t)
      if i % 4 == 0 then
	 spr( spr_mark_long, x, 128 - 8 )
      else
	 spr( spr_mark_short, x, 128 - 8 )	 
      end
   end

   for e in all(timeline) do
      local i = e.time * beats_per_second * 4
      local x = width*(flr(i) - t) - 5
      spr( e.kind, x, 128 - height - 8 )

      -- delete items that are invisible
      if x + 8 < 0 then
	 del( timeline, e )
      end
   end
end

function _draw()
   cls()

   draw_edges( 1, 2 )
   draw_edges( -1, 1 )   
   
   for i=1, 10 do
      local c = cards[i]
      if selected[i] == 0 then
	 pal()
	 pal(15, 0)
	 spr( labels[c], card_x[i], card_y[i] )
	 spr( labels[c], card_x[i], 4 )
      else
	 pal()
	 pal(7, 0)
	 spr( bolded[c], card_x[i]+1, card_y[i] )
	 spr( bolded[c], card_x[i]-1, card_y[i] )
	 spr( bolded[c], card_x[i], card_y[i]+1 )
	 spr( bolded[c], card_x[i], card_y[i]-1 )

	 spr( bolded[c], card_x[i]+1, card_y[i]+1)
	 spr( bolded[c], card_x[i]-1, card_y[i]-1 )
	 spr( bolded[c], card_x[i]-1, card_y[i]+1 )
	 spr( bolded[c], card_x[i]+1, card_y[i]-1 )

	 pal(7, color_order[ selected[i] ] )
	 spr( bolded[c], card_x[i], card_y[i] )
	 spr( bolded[c], card_x[i], 4 )	 
      end
   end

   pal()
   
   if (time() - last_beat < 0.1) then
      spr( 2, card_x[px] - 4, card_y[px] - 4, 2, 2 )
      spr( 2, card_x[px] - 4, 0, 2, 2 )      
   else
      spr( 0, card_x[px] - 4, card_y[px] - 4, 2, 2 )
      spr( 0, card_x[px] - 4, 0, 2, 2 )      
   end

   draw_timeline()
end

__gfx__
02000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00820000000028000022200000022200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00288820028882000028802002088200000000000000000000000000000000000000000000000000000000000007000000070000000700000007000000070000
00080000000080000028888008888200000000000000000000000000000000000000000000000000000000000070000000007000000700000077700000707000
00080000000080000000800000080000000000000000000000000000000000000000000000000000000000000777770007777700070707000707070007000700
00020000000020000002800000082000000000000000000000000000000000000000000000000000000000000070000000007000007770000007000000707000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000070000000700000007000000070000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000
00020000000020000002800000082000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000
00080000000080000000800000080000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000050000000
00080000000080000028888008888200000000000000000000000000000000000000000000000000000000000000000000000000000000006000000050000000
00288820028882000028802002088200000000000000000000000000000000000000000000000000000000000000000000000000000000006000000050000000
00820000000028000022200000022200000000000000000000000000000000000000000000000000000000000000000000000000000000006000000050000000
02000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000050000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000050000000
07777770007770000777777007777770077007700777777007777770077777700777777007777770000000000000000000000000000000000000000000000000
07777770007770000777777007777770077007700777777007777770077777700777777007777770000000000000000000000000000000000000000000000000
07700770000770000000077000000770077007700770000007700000077007700770077007700770000000000000000000000000000000000000000000000000
07700770000770000777777000777770077777700777777007777770000007700777777007777770000000000000000000000000000000000000000000000000
07700770000770000770000000000770000007700000077007700770000007700770077000000770000000000000000000000000000000000000000000000000
07777770000770000777777007777770000007700777777007777770000007700777777000000770000000000000000000000000000000000000000000000000
07777770000770000777777007777770000007700777777007777770000007700777777000000770000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ffffff000ffff000ffff0000ffffff00ffffff00ffffff00fffff000ffffff00ffffff00ffffff0000000000000000000000000000000000000000000000000
0f7777f000f77f000f777f000f7777f00f7ff7f00f7777f00f777f000f7777f00f7777f00f7777f0000000000000000000000000000000000000000000000000
0f7ff7f000ff7f000ffff7f00ffff7f00f7ff7f00f7ffff00f7fff000f7ff7f00f7ff7f00f7ff7f0000000000000000000000000000000000000000000000000
0f7ff7f0000f7f000f7777f000f777f00f7777f00f7777f00f7777f00ffff7f00f7777f00f7777f0000000000000000000000000000000000000000000000000
0f7ff7f0000f7f000f7ffff00ffff7f00ffff7f00ffff7f00f7ff7f00000f7f00f7ff7f00ffff7f0000000000000000000000000000000000000000000000000
0f7777f0000f7f000f7777f00f7777f00000f7f00f7777f00f7777f00000f7f00f7777f00000f7f0000000000000000000000000000000000000000000000000
0ffffff0000fff000ffffff00ffffff00000fff00ffffff00ffffff00000fff00ffffff00000fff0000000000000000000000000000000000000000000000000
__sfx__
000100003052024510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000942001400003000020000600026000460000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000c57000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001057000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001357000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000757000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000457000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000525000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000b25000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 02030444
00 02050644
00 07084344

