


minetest.register_craftitem("cold:fur_coat", {
	description = "Fur Coat",
	stack_max = 1,
	inventory_image = "cold_fur_coat.png",
	groups = {insulation = 7, coat = 1},
})

minetest.register_craftitem("cold:fur_gloves", {
	description = "Fur Gloves",
	stack_max = 1,
	inventory_image = "cold_fur_gloves.png",
	groups = {insulation = 1, gloves = 1},
})

minetest.register_craftitem("cold:fur_boots", {
	description = "Fur Boots",
	stack_max = 1,
	inventory_image = "cold_fur_boots.png",
	groups = {insulation = 3, shoes = 1},
})

minetest.register_craftitem("cold:fur_hat", {
	description = "Fur Hat",
	stack_max = 1,
	inventory_image = "cold_fur_hat.png",
	groups = {insulation = 1, hat = 1},
})


minetest.register_craft({
	output = 'cold:fur_coat 1',
	recipe = {
		{'fur:small_pelt', 'fur:small_pelt', 'fur:small_pelt'},
		{'fur:small_pelt', 'fur:small_pelt', 'fur:small_pelt'},
		{'fur:small_pelt', 'fur:small_pelt', 'fur:small_pelt'},
	}
})

minetest.register_craft({
	output = 'cold:fur_gloves 1',
	recipe = {
		{'', '', ''},
		{'fur:small_pelt', '', 'fur:small_pelt'},
		{'', '', ''},
	}
})

minetest.register_craft({
	output = 'cold:fur_boots 1',
	recipe = {
		{'', '', ''},
		{'fur:small_pelt', '', 'fur:small_pelt'},
		{'fur:small_pelt', '', 'fur:small_pelt'},
	}
})

minetest.register_craft({
	output = 'cold:fur_hat 1',
	recipe = {
		{'fur:small_pelt', 'fur:small_pelt', 'fur:small_pelt'},
		{'', '', ''},
		{'', '', ''},
	}
})
