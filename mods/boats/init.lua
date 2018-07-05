--
-- Helper functions
--

local function is_water(pos)
	local nn = minetest.get_node(pos).name
	return minetest.get_item_group(nn, "water") ~= 0
end


local function get_sign(i)
	if i == 0 then
		return 0
	else
		return i / math.abs(i)
	end
end


local function get_velocity(v, yaw, y)
	local x = -math.sin(yaw) * v
	local z =  math.cos(yaw) * v
	return {x = x, y = y, z = z}
end


local function get_v(v)
	return math.sqrt(v.x ^ 2 + v.z ^ 2)
end

--
-- Boat entity
--

local boat = {
	physical = true,
	-- Warning: Do not change the position of the collisionbox top surface,
	-- lowering it causes the boat to fall through the world if underwater
	collisionbox = {-0.5, -0.35, -0.5, 0.5, 0.3, 0.5},
	visual = "mesh",
	mesh = "boats_boat.obj",
	textures = {"default_wood.png"},

	driver = nil,
	v = 0,
	last_v = 0,
	removed = false
}


function boat.on_rightclick(self, clicker)
	if not clicker or not clicker:is_player() then
		return
	end
	local name = clicker:get_player_name()
	if self.driver and clicker == self.driver then
		self.driver = nil
		clicker:set_detach()
		player_api.player_attached[name] = false
		player_api.set_animation(clicker, "stand" , 30)
		local pos = clicker:getpos()
		pos = {x = pos.x, y = pos.y + 0.2, z = pos.z}
		minetest.after(0.1, function()
			clicker:setpos(pos)
		end)
	elseif not self.driver then
		local attach = clicker:get_attach()
		if attach and attach:get_luaentity() then
			local luaentity = attach:get_luaentity()
			if luaentity.driver then
				luaentity.driver = nil
			end
			clicker:set_detach()
		end
		self.driver = clicker
		clicker:set_attach(self.object, "",
			{x = 0.5, y = 1, z = -3}, {x = 0, y = 0, z = 0})
		player_api.player_attached[name] = true
		minetest.after(0.2, function()
			player_api.set_animation(clicker, "sit" , 30)
		end)
		clicker:set_look_horizontal(self.object:getyaw())
	end
end


function boat.on_activate(self, staticdata, dtime_s)
	self.object:set_armor_groups({immortal = 1})
	if staticdata then
		self.v = tonumber(staticdata)
	end
	self.last_v = self.v
end


function boat.get_staticdata(self)
	return tostring(self.v)
end


function boat.on_punch(self, puncher)
	if not puncher or not puncher:is_player() or self.removed then
		return
	end
	if self.driver and puncher == self.driver then
		self.driver = nil
		puncher:set_detach()
		player_api.player_attached[puncher:get_player_name()] = false
	end
	if not self.driver then
		self.removed = true
		local inv = puncher:get_inventory()
		if not (creative and creative.is_enabled_for
				and creative.is_enabled_for(puncher:get_player_name()))
				or not inv:contains_item("main", "boats:boat") then
			local leftover = inv:add_item("main", "boats:boat")
			-- if no room in inventory add a replacement boat to the world
			if not leftover:is_empty() then
				minetest.add_item(self.object:getpos(), leftover)
			end
		end
		-- delay remove to ensure player is detached
		minetest.after(0.1, function()
			self.object:remove()
		end)
	end
end


function boat.on_step(self, dtime)
	self.v = get_v(self.object:getvelocity()) * get_sign(self.v)
	if self.driver then
		local ctrl = self.driver:get_player_control()
		local yaw = self.object:getyaw()
		if ctrl.up then
			self.v = self.v + 0.1
		elseif ctrl.down then
			self.v = self.v - 0.1
		end
		if ctrl.left then
			if self.v < 0 then
				self.object:setyaw(yaw - (1 + dtime) * 0.03)
			else
				self.object:setyaw(yaw + (1 + dtime) * 0.03)
			end
		elseif ctrl.right then
			if self.v < 0 then
				self.object:setyaw(yaw + (1 + dtime) * 0.03)
			else
				self.object:setyaw(yaw - (1 + dtime) * 0.03)
			end
		end
	end
	local velo = self.object:getvelocity()
	if self.v == 0 and velo.x == 0 and velo.y == 0 and velo.z == 0 then
		self.object:setpos(self.object:getpos())
		return
	end
	local s = get_sign(self.v)
	self.v = self.v - 0.02 * s
	if s ~= get_sign(self.v) then
		self.object:setvelocity({x = 0, y = 0, z = 0})
		self.v = 0
		return
	end
	if math.abs(self.v) > 5 then
		self.v = 5 * get_sign(self.v)
	end

	local p = self.object:getpos()
	p.y = p.y - 0.5
	local new_velo
	local new_acce = {x = 0, y = 0, z = 0}
	if not is_water(p) then
		local nodedef = minetest.registered_nodes[minetest.get_node(p).name]
		if (not nodedef) or nodedef.walkable then
			self.v = 0
			new_acce = {x = 0, y = 1, z = 0}
		else
			new_acce = {x = 0, y = -9.8, z = 0}
		end
		new_velo = get_velocity(self.v, self.object:getyaw(),
			self.object:getvelocity().y)
		self.object:setpos(self.object:getpos())
	else
		p.y = p.y + 1
		if is_water(p) then
			local y = self.object:getvelocity().y
			if y >= 5 then
				y = 5
			elseif y < 0 then
				new_acce = {x = 0, y = 20, z = 0}
			else
				new_acce = {x = 0, y = 5, z = 0}
			end
			new_velo = get_velocity(self.v, self.object:getyaw(), y)
			self.object:setpos(self.object:getpos())
		else
			new_acce = {x = 0, y = 0, z = 0}
			if math.abs(self.object:getvelocity().y) < 1 then
				local pos = self.object:getpos()
				pos.y = math.floor(pos.y) + 0.5
				self.object:setpos(pos)
				new_velo = get_velocity(self.v, self.object:getyaw(), 0)
			else
				new_velo = get_velocity(self.v, self.object:getyaw(),
					self.object:getvelocity().y)
				self.object:setpos(self.object:getpos())
			end
		end
	end
	self.object:setvelocity(new_velo)
	self.object:setacceleration(new_acce)
end


minetest.register_entity("boats:boat", boat)




minetest.register_craftitem("boats:boat", {
	description = "Boat",
	inventory_image = "boats_inventory.png",
	wield_image = "boats_wield.png",
	wield_scale = {x = 2, y = 2, z = 1},
	liquids_pointable = true,
	groups = {flammable = 2},
	stack_max = 1,

	on_place = function(itemstack, placer, pointed_thing)
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		local udef = minetest.registered_nodes[node.name]
		if udef and udef.on_rightclick and
				not (placer and placer:is_player() and
				placer:get_player_control().sneak) then
			return udef.on_rightclick(under, node, placer, itemstack,
				pointed_thing) or itemstack
		end

		if pointed_thing.type ~= "node" then
			return itemstack
		end
		if not is_water(pointed_thing.under) then
			return itemstack
		end
		pointed_thing.under.y = pointed_thing.under.y + 0.5
		boat = minetest.add_entity(pointed_thing.under, "boats:boat")
		if boat then
			if placer then
				boat:setyaw(placer:get_look_horizontal())
			end
			local player_name = placer and placer:get_player_name() or ""
			if not (creative and creative.is_enabled_for and
					creative.is_enabled_for(player_name)) then
				itemstack:take_item()
			end
		end
		return itemstack
	end,
})


minetest.register_craft({
	output = "boats:boat",
	recipe = {
		{"",           "",           ""          },
		{"group:wood", "",           "group:wood"},
		{"group:wood", "group:wood", "group:wood"},
	},
})

minetest.register_craft({
	type = "fuel",
	recipe = "boats:boat",
	burntime = 20,
})





-- ---------------------------------------------------
-- Tin boat




local boat_tin = {
	physical = true,
	-- Warning: Do not change the position of the collisionbox top surface,
	-- lowering it causes the boat to fall through the world if underwater
	collisionbox = {-0.35, -0.35, -0.35, 0.35, 0.3, 0.35},
	visual = "mesh",
	mesh = "boats_canoe.obj",
	textures = {"default_tin_block.png"},

	driver = nil,
	v = 0,
	last_v = 0,
	removed = false
}


function boat_tin.on_rightclick(self, clicker)
	if not clicker or not clicker:is_player() then
		return
	end
	local name = clicker:get_player_name()
	if self.driver and clicker == self.driver then
		self.driver = nil
		clicker:set_detach()
		player_api.player_attached[name] = false
		player_api.set_animation(clicker, "stand" , 30)
		local pos = clicker:getpos()
		pos = {x = pos.x, y = pos.y + 0.2, z = pos.z}
		minetest.after(0.1, function()
			clicker:setpos(pos)
		end)
	elseif not self.driver then
		local attach = clicker:get_attach()
		if attach and attach:get_luaentity() then
			local luaentity = attach:get_luaentity()
			if luaentity.driver then
				luaentity.driver = nil
			end
			clicker:set_detach()
		end
		self.driver = clicker
		clicker:set_attach(self.object, "",
			{x = 0.5, y = 1, z = -3}, {x = 0, y = 0, z = 0})
		player_api.player_attached[name] = true
		minetest.after(0.2, function()
			player_api.set_animation(clicker, "sit" , 30)
		end)
		clicker:set_look_horizontal(self.object:getyaw())
	end
end


function boat_tin.on_activate(self, staticdata, dtime_s)
	self.object:set_armor_groups({immortal = 1})
	if staticdata then
		self.v = tonumber(staticdata)
	end
	self.last_v = self.v
end


function boat_tin.get_staticdata(self)
	return tostring(self.v)
end


function boat_tin.on_punch(self, puncher)
	if not puncher or not puncher:is_player() or self.removed then
		return
	end
	if self.driver and puncher == self.driver then
		self.driver = nil
		puncher:set_detach()
		player_api.player_attached[puncher:get_player_name()] = false
	end
	if not self.driver then
		self.removed = true
		local inv = puncher:get_inventory()
		if not (creative and creative.is_enabled_for
				and creative.is_enabled_for(puncher:get_player_name()))
				or not inv:contains_item("main", "boats:boat_tin") then
			local leftover = inv:add_item("main", "boats:boat_tin")
			-- if no room in inventory add a replacement boat to the world
			if not leftover:is_empty() then
				minetest.add_item(self.object:getpos(), leftover)
			end
		end
		-- delay remove to ensure player is detached
		minetest.after(0.1, function()
			self.object:remove()
		end)
	end
end


function boat_tin.on_step(self, dtime)
	self.v = get_v(self.object:getvelocity()) * get_sign(self.v)
	if self.driver then
		local ctrl = self.driver:get_player_control()
		local yaw = self.object:getyaw()
		if ctrl.up then
			self.v = self.v + 0.2
		elseif ctrl.down then
			self.v = self.v - 0.2
		end
		if ctrl.left then
			if self.v < 0 then
				self.object:setyaw(yaw - (1 + dtime) * 0.04)
			else
				self.object:setyaw(yaw + (1 + dtime) * 0.04)
			end
		elseif ctrl.right then
			if self.v < 0 then
				self.object:setyaw(yaw + (1 + dtime) * 0.04)
			else
				self.object:setyaw(yaw - (1 + dtime) * 0.04)
			end
		end
	end
	local velo = self.object:getvelocity()
	if self.v == 0 and velo.x == 0 and velo.y == 0 and velo.z == 0 then
		self.object:setpos(self.object:getpos())
		return
	end
	local s = get_sign(self.v)
	self.v = self.v - 0.002 * s
	if s ~= get_sign(self.v) then
		self.object:setvelocity({x = 0, y = 0, z = 0})
		self.v = 0
		return
	end
	if math.abs(self.v) > 15 then
		self.v = 15 * get_sign(self.v)
	end

	local p = self.object:getpos()
	p.y = p.y - 0.5
	local new_velo
	local new_acce = {x = 0, y = 0, z = 0}
	if not is_water(p) then
		local nodedef = minetest.registered_nodes[minetest.get_node(p).name]
		if (not nodedef) or nodedef.walkable then
			self.v = 0
			new_acce = {x = 0, y = 1, z = 0}
		else
			new_acce = {x = 0, y = -9.8, z = 0}
		end
		new_velo = get_velocity(self.v, self.object:getyaw(),
			self.object:getvelocity().y)
		self.object:setpos(self.object:getpos())
	else
		p.y = p.y + 1
		if is_water(p) then
			local y = self.object:getvelocity().y
			if y >= 5 then
				y = 5
			elseif y < 0 then
				new_acce = {x = 0, y = 3, z = 0} -- float parameters. bigger = bouncier
			else
				new_acce = {x = 0, y = 1, z = 0}
			end
			new_velo = get_velocity(self.v, self.object:getyaw(), y)
			self.object:setpos(self.object:getpos())
		else
			new_acce = {x = 0, y = 0, z = 0}
			if math.abs(self.object:getvelocity().y) < 1 then
				local pos = self.object:getpos()
				pos.y = math.floor(pos.y) + 0.5
				self.object:setpos(pos)
				new_velo = get_velocity(self.v, self.object:getyaw(), 0)
			else
				new_velo = get_velocity(self.v, self.object:getyaw(),
					self.object:getvelocity().y)
				self.object:setpos(self.object:getpos())
			end
		end
	end
	self.object:setvelocity(new_velo)
	self.object:setacceleration(new_acce)
end



minetest.register_entity("boats:boat_tin", boat_tin)


minetest.register_craftitem("boats:boat_tin", {
	description = "Metal Boat",
	inventory_image = "boats_tin_inventory.png",
	wield_image = "boats_tin_wield.png",
	wield_scale = {x = 2, y = 2, z = 1},
	liquids_pointable = true,
	groups = {flammable = 2},
	stack_max = 1,

	on_place = function(itemstack, placer, pointed_thing)
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		local udef = minetest.registered_nodes[node.name]
		if udef and udef.on_rightclick and
				not (placer and placer:is_player() and
				placer:get_player_control().sneak) then
			return udef.on_rightclick(under, node, placer, itemstack,
				pointed_thing) or itemstack
		end

		if pointed_thing.type ~= "node" then
			return itemstack
		end
		if not is_water(pointed_thing.under) then
			return itemstack
		end
		pointed_thing.under.y = pointed_thing.under.y + 0.5
		boat = minetest.add_entity(pointed_thing.under, "boats:boat_tin")
		if boat then
			if placer then
				boat:setyaw(placer:get_look_horizontal())
			end
			local player_name = placer and placer:get_player_name() or ""
			if not (creative and creative.is_enabled_for and
					creative.is_enabled_for(player_name)) then
				itemstack:take_item()
			end
		end
		return itemstack
	end,
})




minetest.register_craft({
	output = "boats:boat_tin",
	recipe = {
		{"",           "",           ""          },
		{"default:tin_ingot", "",           "default:tin_ingot"},
		{"default:tin_ingot", "default:tin_ingot", "default:tin_ingot"},
	},
})


























-- ---------------------------------------------------
-- Steel boat




local boat_steel = {
	physical = true,
	-- Warning: Do not change the position of the collisionbox top surface,
	-- lowering it causes the boat to fall through the world if underwater
	collisionbox = {-2.35, -01.35, -2.35, 02.35, 0.3, 02.35},
	visual = "mesh",
	visual_size = {x=8,y=8,z=8},
	mesh = "cargo_ship.obj",
	textures = {"default_bronze_block.png"},

	driver = nil,
	v = 0,
	last_v = 0,
	removed = false,
	
	-- box = nil,
}


-- minetest.register_entity("boats:boat_cargo_box", boat_cargo_box)





local modpath = minetest.get_modpath("boats")
local mod_storage = minetest.get_mod_storage()

local boat_data = {}

boat_data.objects = {}

boat_data.next_entity = mod_storage:get_int("next_entity") or 1
boat_data.entities = minetest.deserialize(mod_storage:get_string("entities")) or {}

if type(boat_data.entities) ~= "table" then
	boat_data.entities = {}
end

local function save_data() 
	--print("saving")
	mod_storage:set_int("next_entity", boat_data.next_entity);
	mod_storage:set_string("entities", minetest.serialize(boat_data.entities))
end


local function deploy_boat(boat)
	local id = boat_data.next_entity
	boat_data.next_entity = boat_data.next_entity + 1
	
	boat.data = boat.data or {}
	boat.data.id = id
	boat.data.driver = nil
	
	boat_data.objects[id] = boat
	
	boat_data.entities[id] = {
		id = id,
		inventories = {
			
		
		},
	}

	save_data()
end




local function enter_boat(self, clicker) 
	local name = clicker:get_player_name()
	if not self.driver then
		local attach = clicker:get_attach()
		if attach and attach:get_luaentity() then
			local luaentity = attach:get_luaentity()
			if luaentity.driver then
				luaentity.driver = nil
			end
			clicker:set_detach()
		end
		self.driver = clicker
		clicker:set_attach(self.object, "",
			{x = 0.5, y = 1, z = -3}, {x = 0, y = 0, z = 0})
		player_api.player_attached[name] = true
		minetest.after(0.2, function()
			player_api.set_animation(clicker, "sit" , 30)
		end)
		clicker:set_look_horizontal(self.object:getyaw())
	end

end


local function get_steel_boat_formspec()
	local state_str = "Sailing"
	
	return "" ..
		"size[10,8;]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"label[1,1;"..state_str.."]" ..
		"button[5,1;5,1;board;Board]" ..
		""
end


function boat_steel.on_rightclick(self, clicker)
	if not clicker or not clicker:is_player() then
		return
	end
	local name = clicker:get_player_name()
	if self.driver and clicker == self.driver then
	
		-- exit boat
		self.driver = nil
		clicker:set_detach()
		player_api.player_attached[name] = false
		player_api.set_animation(clicker, "stand" , 30)
		local pos = clicker:getpos()
		pos = {x = pos.x, y = pos.y + 0.2, z = pos.z}
		minetest.after(0.1, function()
			clicker:setpos(pos)
		end)
	else
		-- show formspec
		minetest.show_formspec(clicker:get_player_name(), "boats:steel_boat_formQ"..self.data.id, get_steel_boat_formspec(self))
		

		
	end
end

local function splitname(name)
	local c = string.find(name, "Q")
	print("c " ..c)
	return string.sub(name, 1,  c - 1), string.sub(name, c + 1, string.len(name))
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	
	
	local formprefix, id = splitname(formname)
	
	if formprefix ~= "boats:steel_boat_form" then
		print("wrong prefix: " .. formname .. " - " .. formprefix)
		return
	end
	
	
	
	if fields.board then
		id = id + 0
		local boat = boat_data.objects[id]
		print("id ".. id)
		if not boat then
			print("no boat " .. dump(boat) .. " " .. dump(id))
			print(dump(boat_data))
			--enter_boat(boat, player)
		else
			enter_boat(boat, player)
		end
		return
	end
	
end)


minetest.register_node("boats:bollard", {
	paramtype = "light",
	description = "Mooring Bollard",
	tiles = {"default_bronze_block.png",  "default_bronze_block.png", "default_bronze_block.png",
	         "default_bronze_block.png", "default_bronze_block.png",   "default_bronze_block.png"},
	node_box = {
		type = "fixed",
		fixed = {
			--11.25
			{-0.49, -0.5, -0.10, 0.49, 0.5, 0.10},
			{-0.10, -0.5, -0.49, 0.10, 0.5, 0.49},
			--22.5
			{-0.46, -0.5, -0.19, 0.46, 0.5, 0.19},
			{-0.19, -0.5, -0.46, 0.19, 0.5, 0.46},
			-- 33.75
			{-0.416, -0.5, -0.28, 0.416, 0.5, 0.28},
			{-0.28, -0.5, -0.416, 0.28, 0.5, 0.416},
			--45
			{-0.35, -0.5, -0.35, 0.35, 0.5, 0.35},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
	},
	drawtype = "nodebox",
	groups = {cracky=3,oddly_breakable_by_hand=3 },
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		
	end,
})




function boat_steel.on_activate(self, staticdata, dtime_s)
	self.object:set_armor_groups({immortal = 1})
	if staticdata then
		self.data = minetest.deserialize(staticdata)
		
		if not self.data or not self.data.id then 
			deploy_boat(self)
		end
		print("self.data.id = "..self.data.id)
		print(dump(self))
		boat_data.objects[self.data.id] = self
	else 
		self.data = {}
		print("steel boat with no staticdata")
	end	
	
	
	 
end


function boat_steel.get_staticdata(self)
	return minetest.serialize(self.data)
end


function boat_steel.on_punch(self, puncher)
	if not puncher or not puncher:is_player() or self.removed then
		return
	end
	if self.driver and puncher == self.driver then
		self.driver = nil
		puncher:set_detach()
		player_api.player_attached[puncher:get_player_name()] = false
	end
	if not self.driver then
		self.removed = true
		local inv = puncher:get_inventory()
		if not (creative and creative.is_enabled_for
				and creative.is_enabled_for(puncher:get_player_name()))
				or not inv:contains_item("main", "boats:boat_steel") then
			local leftover = inv:add_item("main", "boats:boat_steel")
			-- if no room in inventory add a replacement boat to the world
			if not leftover:is_empty() then
				minetest.add_item(self.object:getpos(), leftover)
			end
		end
		-- delay remove to ensure player is detached
		minetest.after(0.1, function()
			self.object:remove()
		end)
	end
end


function boat_steel.on_step(self, dtime)
	self.v = get_v(self.object:getvelocity()) * get_sign(self.v)
	local yaw = self.object:getyaw()
	local bp = self.object:getpos()
	local velo = self.object:getvelocity()
	bp.y = bp.y + 4

	local speed = vector.length(velo)
	
	if self.driver then
		local ctrl = self.driver:get_player_control()
		local yaw = self.object:getyaw()
		if ctrl.up then
			self.v = self.v + 0.02
		elseif ctrl.down then
			self.v = self.v - 0.02
		end
		if ctrl.left then
			if self.v < 0 then
				self.object:setyaw(yaw - (1 + dtime) * 0.0005 * speed)
			else
				self.object:setyaw(yaw + (1 + dtime) * 0.0005 * speed)
			end
		elseif ctrl.right then
			if self.v < 0 then
				self.object:setyaw(yaw + (1 + dtime) * 0.0005 * speed)
			else
				self.object:setyaw(yaw - (1 + dtime) * 0.0005 * speed)
			end
		end
	end
	
	local drift = {x=0,y=0,z=0}
	if speed < .1 then
		print("drifting")
		-- float away randomly
		drift = {
			x = math.random(5.1, 10.9),
			y = 0,
			z = math.random(5.1, 10.9),
		}
	end
	
	
	
	if self.v == 0 and velo.x == 0 and velo.y == 0 and velo.z == 0 then
		self.object:setpos(self.object:getpos())
		return
	end
	local s = get_sign(self.v)
	-- self.v = self.v - 0.002 * s
	if s ~= get_sign(self.v) then
		self.object:setvelocity({x = 0, y = 0, z = 0})
		self.v = 0
		return
	end
	if math.abs(self.v) > 4 then
		self.v = 4 * get_sign(self.v)
	end

	local p = self.object:getpos()
	p.y = p.y - 0.5
	local new_velo
	local new_acce = {x = 0, y = 0, z = 0}
	if not is_water(p) then
		local nodedef = minetest.registered_nodes[minetest.get_node(p).name]
		if (not nodedef) or nodedef.walkable then
			self.v = 0
			new_acce = {x = 0, y = 1, z = 0}
		else
			new_acce = {x = 0, y = -9.8, z = 0}
		end
		new_velo = get_velocity(self.v, self.object:getyaw(),
			self.object:getvelocity().y)
		self.object:setpos(self.object:getpos())
	else
		p.y = p.y + 1
		if is_water(p) then
			local y = self.object:getvelocity().y
			if y >= 5 then
				y = 5
			elseif y < 0 then
				new_acce = {x = 0, y = 3, z = 0} -- float parameters. bigger = bouncier
			else
				new_acce = {x = 0, y = 1, z = 0}
			end
			new_velo = get_velocity(self.v, self.object:getyaw(), y)
			self.object:setpos(self.object:getpos())
		else
			new_acce = {x = 0, y = 0, z = 0}
			if math.abs(self.object:getvelocity().y) < 1 then
				local pos = self.object:getpos()
				pos.y = math.floor(pos.y) + 0.5
				self.object:setpos(pos)
				new_velo = get_velocity(self.v, self.object:getyaw(), 0)
			else
				new_velo = get_velocity(self.v, self.object:getyaw(),
					self.object:getvelocity().y)
				self.object:setpos(self.object:getpos())
			end
		end
	end
	self.object:setvelocity(vector.add(new_velo, drift))
	self.object:setacceleration(new_acce)
	

end



minetest.register_entity("boats:boat_steel", boat_steel)


minetest.register_craftitem("boats:boat_steel", {
	description = "Steel Boat",
	inventory_image = "boats_tin_inventory.png^[colorize:#600:80",
	wield_image = "boats_tin_wield.png",
	wield_scale = {x = 2, y = 2, z = 1},
	liquids_pointable = true,
	groups = {flammable = 2},
	stack_max = 1,

	on_place = function(itemstack, placer, pointed_thing)
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		local udef = minetest.registered_nodes[node.name]
		if udef and udef.on_rightclick and
				not (placer and placer:is_player() and
				placer:get_player_control().sneak) then
			return udef.on_rightclick(under, node, placer, itemstack,
				pointed_thing) or itemstack
		end

		if pointed_thing.type ~= "node" then
			return itemstack
		end
		if not is_water(pointed_thing.under) then
			return itemstack
		end
		pointed_thing.under.y = pointed_thing.under.y + 0.5
		boat = minetest.add_entity(pointed_thing.under, "boats:boat_steel")
		--deploy_boat(boat)
		if boat then
			if placer then
				boat:setyaw(placer:get_look_horizontal())
			end
			local player_name = placer and placer:get_player_name() or ""
			if not (creative and creative.is_enabled_for and
					creative.is_enabled_for(player_name)) then
				itemstack:take_item()
			end
			

		end
		return itemstack
	end,
})




minetest.register_craft({
	output = "boats:boat_steel",
	recipe = {
		{"",           "",           ""          },
		{"default:steel_ingot", "",           "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	},
})
