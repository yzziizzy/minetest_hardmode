

--[[
tea
coffee
thistle
nettle
horsetail
wolfbane

-- distill alcohol for tinctures

foxglove
lupine


]]

minetest.register_craftitem("herbs:aloe_vera", {
	description = "Aloe Vera",
	stack_max = 12,
	inventory_image = "herbs_aloe_vera_plant.png",
	groups = {},
})

minetest.register_node("herbs:aloe_vera_plant", {
	description = "Aloe Vera",
	drawtype = "plantlike",
	tiles = {"herbs_aloe_vera_plant.png"},
	inventory_image = "herbs_aloe_vera_plant.png",
	wield_image = "herbs_aloe_vera_plant.png",
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 4,
	sunlight_propagates = true,
	walkable = false,
	stack_max = 1,
	drops = {"herbs:aloe_vera 2"}
	selection_box = {
		type = "fixed",
		fixed = {-4 / 16, -0.5, -4 / 16, 4 / 16, 7 / 16, 4 / 16}
	},
	groups = {snappy = 2, flammable = 2, attached_node = 1},
	sounds = default.node_sound_leaves_defaults(),
})












