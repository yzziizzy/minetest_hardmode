minetest.register_node("rot:rotten_wood_1", {
	description = "Rotting Apple Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_wood.png^[colorize:black:90"},
	is_ground_content = false,
	stack_max = 4,
	groups = {choppy = 2, rotten = 1, oddly_breakable_by_hand = 2, flammable = 2, wood = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("rot:rotten_junglewood_1", {
	description = "Rotting Jungle Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_junglewood.png^[colorize:black:80"},
	stack_max = 4,
	is_ground_content = false,
	groups = {choppy = 2, rotten = 1, oddly_breakable_by_hand = 2, flammable = 2, wood = 1},
	sounds = default.node_sound_wood_defaults(),
})
minetest.register_node("rot:rotten_pine_wood_1", {
	description = "Rotting Pine Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_pine_wood.png^[colorize:black:80"},
	is_ground_content = false,
	stack_max = 4,
	groups = {choppy = 3, rotten = 1, oddly_breakable_by_hand = 2, flammable = 3, wood = 1},
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_node("rot:rotten_acacia_wood_1", {
	description = "Rotting Acacia Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_acacia_wood.png^[colorize:black:80"},
	is_ground_content = false,
	stack_max = 4,
	groups = {choppy = 2, rotten = 1, oddly_breakable_by_hand = 2, flammable = 2, wood = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("rot:rotten_aspen_wood_1", {
	description = "Rotting Aspen Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	stack_max = 4,
	tiles = {"default_aspen_wood.png^[colorize:black:80"},
	is_ground_content = false,
	groups = {choppy = 3, rotten = 1, oddly_breakable_by_hand = 2, flammable = 3, wood = 1},
	sounds = default.node_sound_wood_defaults(),
})


--- severe rot 

minetest.register_node("rot:rotten_wood_2", {
	description = "Rotten Apple Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_wood.png^[colorize:black:180"},
	is_ground_content = false,
	stack_max = 4,
	groups = {falling_node = 1, rotten = 2, choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, wood = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("rot:rotten_junglewood_2", {
	description = "Rotten Jungle Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_junglewood.png^[colorize:black:180"},
	stack_max = 4,
	is_ground_content = false,
	groups = {falling_node = 1, rotten = 2, choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, wood = 1},
	sounds = default.node_sound_wood_defaults(),
})
minetest.register_node("rot:rotten_pine_wood_2", {
	description = "Rotten Pine Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_pine_wood.png^[colorize:black:180"},
	is_ground_content = false,
	stack_max = 4,
	groups = {falling_node = 1, rotten = 2, choppy = 3, oddly_breakable_by_hand = 2, flammable = 3, wood = 1},
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_node("rot:rotten_acacia_wood_2", {
	description = "Rotten Acacia Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_acacia_wood.png^[colorize:black:180"},
	is_ground_content = false,
	stack_max = 4,
	groups = {falling_node = 1, rotten = 2, choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, wood = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("rot:rotten_aspen_wood_2", {
	description = "Rotten Aspen Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	stack_max = 4,
	tiles = {"default_aspen_wood.png^[colorize:black:180"},
	is_ground_content = false,
	groups = {falling_node = 1, rotten = 2, choppy = 3, oddly_breakable_by_hand = 2, flammable = 3, wood = 1},
	sounds = default.node_sound_wood_defaults(),
})



local downgrades = {
	["default:wood"] = "rot:rotten_wood_1",
	["default:aspen_wood"] = "rot:rotten_aspen_wood_1",
	["default:acacia_wood"] = "rot:rotten_acacia_wood_1",
	["default:pine_wood"] = "rot:rotten_pine_wood_1",
	["default:junglewood"] = "rot:rotten_junglewood_1",
	
	["rot:rotten_wood_1"] = "rot:rotten_wood_2",
	["rot:rotten_aspen_wood_1"] = "rot:rotten_aspen_wood_2",
	["rot:rotten_acacia_wood_1"] = "rot:rotten_acacia_wood_2",
	["rot:rotten_pine_wood_1"] = "rot:rotten_pine_wood_2",
	["rot:rotten_junglewood_1"] = "rot:rotten_junglewood_2",

	["rot:rotten_wood_2"] = "default:dirt",
	["rot:rotten_aspen_wood_2"] = "default:dirt",
	["rot:rotten_acacia_wood_2"] = "default:dirt",
	["rot:rotten_pine_wood_2"] = "default:dirt",
	["rot:rotten_junglewood_2"] = "default:dirt",
}

minetest.register_abm({
	nodenames = {
		"default:wood",
		"default:aspen_wood",
		"default:acacia_wood",
		"default:pine_wood",
		"default:junglewood",
	},
 	neighbors = {"group:soil", "group:rotten", "group:water"},
	interval = 15,
	chance = 100,
	catch_up = true,
	action = function(pos, node)
		
		minetest.set_node(pos, {name= downgrades[node.name]})
	end,
})


minetest.register_abm({
	nodenames = {
		"rot:rotten_wood_1",
		"rot:rotten_aspen_wood_1",
		"rot:rotten_acacia_wood_1",
		"rot:rotten_pine_wood_1",
		"rot:rotten_junglewood_1",
	},
	neighbors = {"group:soil", "group:rotten", "group:water"},
	interval = 10,
	chance = 80,
	catch_up = true,
	action = function(pos, node)
		
		minetest.set_node(pos, {name= downgrades[node.name]})
	end,
})

minetest.register_abm({
	nodenames = {
		"rot:rotten_wood_2",
		"rot:rotten_aspen_wood_2",
		"rot:rotten_acacia_wood_2",
		"rot:rotten_pine_wood_2",
		"rot:rotten_junglewood_2",
	},
	neighbors = {"group:soil", "group:rotten", "group:water"},
	interval = 10,
	chance = 50,
	catch_up = true,
	action = function(pos, node)
		
		minetest.set_node(pos, {name= downgrades[node.name]})
	end,
})
