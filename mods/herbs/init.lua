

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
	on_use = function(itemstack, user, pointed_thing)
		
	end,
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
	drops = {"herbs:aloe_vera 2"},
	selection_box = {
		type = "fixed",
		fixed = {-4 / 16, -0.5, -4 / 16, 4 / 16, 7 / 16, 4 / 16}
	},
	groups = {snappy = 2, flammable = 2, attached_node = 1},
	sounds = default.node_sound_leaves_defaults(),
})

-- TODO: register decoration







minetest.register_abm({
	label = "Aloe Propagation",
	nodenames = "herbs:aloe_vera_plant",
	interval = 30,
	chance = 100,
	catch_up = true,
	action = function(pos, node)
	
		pos.y = pos.y - 1
		local under = minetest.get_node(pos)
		pos.y = pos.y + 1
			
		-- must grow in desert sand
		if under.name ~= "default:desert_sand" then
			return
		end

		local pos0 = vector.subtract(pos, 1)
		local pos1 = vector.add(pos, 1)
		
		local soils = minetest.find_nodes_in_area_under_air(pos0, pos1, "default:desert_sand")
		if #soils > 0 then
			local seedling = soils[math.random(#soils)]
			local seedling_above = {x = seedling.x, y = seedling.y + 1, z = seedling.z}
			light = minetest.get_node_light(seedling_above)
			if not light or light < 10 then
				return
			end

			minetest.set_node(seedling_above, {name = node.name})
		end
	end,
})


local mg_name = minetest.get_mapgen_setting("mg_name")
if mg_name == "v6" then -- does anybody still create new worlds on v6?
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"default:desert_sand"},
		sidelen = 16,
		noise_params = {
			offset = 0,
			scale = 0.006,
			spread = {x = 100, y = 100, z = 100},
			seed = 436,
			octaves = 3,
			persist = 0.6
		},
		y_min = 1,
		y_max = 30,
		decoration = "herbs:aloe_vera_plant",
	})
else
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"default:desert_sand"},
		sidelen = 16,
		noise_params = {
			offset = -0.02,
			scale = 0.04,
			spread = {x = 200, y = 200, z = 200},
			seed = seed,
			octaves = 3,
			persist = 0.6
		},
		biomes = {"desert"},
		y_min = 1,
		y_max = 31000,
		decoration = "herbs:aloe_vera_plant",
	})
end




minetest.register_node("herbs:still", {
	description = "Infusion Still",
	tiles = {"default_copper_block.png"},
-- 	inventory_image = "default_snowball.png",
-- 	wield_image = "default_copper_block.png",
	paramtype = "light",
	stack_max = 1,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.48, -0.5, -0.48, 0.48, .6, 0.48},
			{-0.05, .5, -0.05, 0.05, 1.0, 0.05},
			{-0.05, -0.05+1, -0.05, 0.05+1, 0.05+1, 0.05},
			{-0.05+1, .4, -0.05, 0.05+1, 1.0, 0.05},
		},
	},
	groups = {cracky = 2},
	sounds = default.node_sound_snow_defaults(),

	on_construct = function(pos)
		
	end,
})


