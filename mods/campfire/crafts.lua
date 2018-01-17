

minetest.register_craft({
	output = 'campfire:embers 1',
	recipe = {
		{'', 'default:flint', ''},
		{'group:stone', 'group:stick', 'group:stone'},
	}
})





minetest.register_craft({
	type = 'cooking',
	recipe = 'default:grass_1',
	output = 'campfire:dried_grass',
	cooktime = 1,
})

