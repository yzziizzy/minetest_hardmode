




function get_hopper_formspec()
	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
--		"list[context;src;2.75,0.5;1,1;]"..
		"list[context;main;0,1;8,2;]"..
--		"list[context;dst;4.75,0.96;2,2;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[context;main]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end



minetest.register_node("machines:hopper", {
	description = "Hopper",
	tiles = { "default_tin_block.png" },
	paramtype2 = "facedir",
	groups = {cracky=2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	stack_max = 1,

	can_dig = can_dig,


	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_hopper_formspec())
		local inv = meta:get_inventory()
		inv:set_size('main', 8)
	end,
--[[
	on_metadata_inventory_move = function(pos)
		--minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_put = function(pos)
		-- start timer function, it will sort out whether furnace can burn or not.
		--minetest.get_node_timer(pos):start(1.0)
	end,]]
	on_blast = function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "main", drops)
		drops[#drops+1] = "machines:hopper"
		minetest.remove_node(pos)
		return drops
	end,

-- 	allow_metadata_inventory_put = allow_metadata_inventory_put,
-- 	allow_metadata_inventory_move = allow_metadata_inventory_move,
-- 	allow_metadata_inventory_take = allow_metadata_inventory_take,
})











