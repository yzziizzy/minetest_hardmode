-- A couple variables used throughout.
percent = 100
-- GUI related stuff
default.gui_bg = 'bgcolor[#080808BB;true]'
default.gui_bg_img = 'background[5,5;1,1;gui_formbg.png;true]'
default.gui_slots = 'listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]'

campfire = {}


dofile(minetest.get_modpath('campfire')..'/functions.lua')
dofile(minetest.get_modpath('campfire')..'/abms.lua')
dofile(minetest.get_modpath('campfire')..'/nodes.lua')
dofile(minetest.get_modpath('campfire')..'/crafts.lua')
