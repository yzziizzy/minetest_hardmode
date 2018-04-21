

minetest.register_node('campfire:embers', {
	description = 'Campfire',
	drawtype = 'mesh',
	mesh = 'campfire_kindling.obj',
	tiles = {'campfire_campfire_logs.png'},
	inventory_image = 'campfire_campfire.png',
	wield_image = 'campfire_campfire.png',
	walkable = false,
	is_ground_content = true,
	groups = {dig_immediate=3, flammable=1,},
	paramtype = 'light',
	light_source = 5,
	drop = 'campfire:embers',
	selection_box = {
		type = 'fixed',
		fixed = { -0.48, -0.5, -0.48, 0.48, 0.0, 0.48 },
		},
	on_construct = function(pos)
			local meta = minetest.env:get_meta(pos)
			local timer = minetest.get_node_timer(pos)
			meta:set_string('formspec', campfire.embers_formspec)
			meta:set_string('infotext', 'Campfire');
			local inv = meta:get_inventory()
			inv:set_size('fuel', 8)
-- 			inv:set_size("src", 1)
-- 			inv:set_size("dst", 2)
			timer:start(180)
		end,
	can_dig = function(pos, player)
			local meta = minetest.get_meta(pos);
			local inv = meta:get_inventory()
			if not inv:is_empty("fuel") then
				return false
-- 			elseif not inv:is_empty("dst") then
-- 				return false
-- 			elseif not inv:is_empty("src") then
-- 				return false
			end
			return true
		end,
	on_timer = function(pos, elapsed)
		local timer = minetest.get_node_timer(pos)
		timer:stop()
		minetest.set_node(pos, {name = 'campfire:embers'})
		end,
	after_place_node = function(pos)
		local timer = minetest.get_node_timer(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local fuel = nil
			local fuellist = inv:get_list('fuel')
			if fuellist then
				fuel = minetest.get_craft_result({method = 'fuel', width = 1, items = fuellist})
			end
		if fuel.time <= 0 then
			if inv:is_empty('fuel') then
				timer:start(180)
				end
			end
		end,
})

minetest.register_node('campfire:campfire', {
	description = 'Burning Campfire',
	drawtype = 'mesh',
	mesh = 'campfire_campfire.obj',
	tiles = {
		{name='fire_basic_flame_animated.png', animation={type='vertical_frames', aspect_w=16, aspect_h=16, length=1}}, {name='campfire_campfire_logs.png'}},
	inventory_image = 'campfire_campfire.png',
	wield_image = 'campfire_campfire.png',
	paramtype = 'light',
	walkable = false,
	damage_per_second = 1,
	light_source = 14,
	is_ground_content = true,
	drop = 'campfire:campfire',
	groups = {cracky=2,hot=2,attached_node=1,igniter=1,not_in_creative_inventory=1},
	selection_box = {
		type = 'fixed',
		fixed = { -0.48, -0.5, -0.48, 0.48, 0.0, 0.48 },
		},
	can_dig = function(pos, player)
			local meta = minetest.get_meta(pos);
			local inv = meta:get_inventory()
			if not inv:is_empty("fuel") then
				return false
-- 			elseif not inv:is_empty("dst") then
-- 				return false
-- 			elseif not inv:is_empty("src") then
-- 				return false
			end
			return true
		end,
			get_staticdata = function(self)
end,
})

