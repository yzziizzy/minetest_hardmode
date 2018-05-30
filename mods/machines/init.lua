



local modpath = minetest.get_modpath("machines")
dofile(modpath.."/hopper.lua")
dofile(modpath.."/autofurnace.lua")



local function splitname(name)
	local c = string.find(name, ":", 1)
	return string.sub(name, 1, c - 1), string.sub(name, c + 1, string.len(name))
end



local function grab_fuel(inv)
	
	local list = inv:get_list("fuel")
	for i,st in ipairs(list) do
	print(st:get_name())
		local fuel, remains
		fuel, remains = minetest.get_craft_result({
			method = "fuel", 
			width = 1, 
			items = {
				ItemStack(st:get_name())
			},
		})

		if fuel.time > 0 then
			-- Take fuel from fuel list
			st:take_item()
			inv:set_stack("fuel", i, st)
			
			return fuel.time
		end
	end
	
	return 0 -- no fuel found
end







local function can_dig(pos, player)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("fuel")
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
-- 	if minetest.is_protected(pos, player:get_player_name()) then
-- 		return 0
-- 	end
-- 	local meta = minetest.get_meta(pos)
-- 	local inv = meta:get_inventory()
-- 	if listname == "fuel" then
-- 		if minetest.get_craft_result({method="fuel", width=1, items={stack}}).time ~= 0 then
-- 			if inv:is_empty("src") then
-- 				meta:set_string("infotext", "Furnace is empty")
-- 			end
-- 			return stack:get_count()
-- 		else
-- 			return 0
-- 		end
-- 	elseif listname == "src" then
-- 		return stack:get_count()
-- 	elseif listname == "dst" then
-- 		return 0
-- 	end
	
	
	
	return stack:get_count()
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end




-- local prominent_items = {
-- 	["default:cobble"] = 1
-- 	["default:wood"] = 1
-- 	["default:stick"] = 1
-- 	["tnt:gunpowder"] = 1
-- 	["tnt:tnt"] = 1
-- 
-- }
local standard_recipies = {}

-- find all the default items and cache their node names
local default_items = {}
for n,item in pairs(minetest.registered_items) do
	--print("name[ " .. n)
	if string.find(n, ":", 1) then
		m,p = splitname(n)
		if m == "default" then
			default_items[n] = p
		end
	end
end


local function get_canonical_item_for_group(group)
	
	for name,_ in pairs(default_items) do
		local item = minetest.registered_items[name]
		if item.groups[group] ~= nil then
			return name
		end
		
	end
	
	-- nothing in default, search further
	for name,item in pairs(minetest.registered_items) do
		if item.groups[group] ~= nil then
			return name
		end
	end
	
	return ""
end



local function set_craft_recipe(pos, index)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local protolist = inv:get_stack("proto", 1)
	
	if protolist == nil then
		-- no prototype
		return
	end
	--print(protolist:get_name())
	
	local recipes_all = minetest.get_all_craft_recipes(protolist:get_name())
	
	local recipes = {}
	for _,r in ipairs(recipes_all) do
		if r.type ~= "cooking" then
			table.insert(recipes, r)
		end
	end
	
	if #recipes == 0 then
		-- nothing to do
		return
	end
	
	local n = meta:get_float("n") or 1
	
	if n > #recipes or n <= 0 then
		n = (n % #recipes) + 1
		meta:set_float("n", n)
	end
	
	local recip = recipes[n]
	
	
-- 	if 1 == 1 then return end
	
	local needed = {} -- specific items needed
	local needed_show = {} -- representative items to displat to the user
	local needed_groups = {} -- group items needed
	--print("---")
	for i,item in ipairs(recip.items) do
		--print("item - "..item)
		
		local name = item
		if item:sub(1, 6) == "group:" then
			local group = item:sub(7)
			needed_groups[group] = (needed_groups[group] or 0) + 1
			
			name = get_canonical_item_for_group(group)
		else 
			needed[item] = (needed[item] or 0) + 1 
		end
		
		
		needed_show[name] = (needed_show[name] or 0) + 1 
	end
	
	--print("^^^")
	-- show needed item to the user
	local i = 1
	for name,qty in pairs(needed_show) do
		--print("needed name: " .. name)
		inv:set_stack("needs", i, name .. " " .. qty)
		
		i = i + 1
	end
	
	-- clear out the unused slots
	while i <= 9 do
		inv:set_stack("needs", i, "")
		
		i = i + 1
	end
	
	
	meta:set_string("work", minetest.serialize({
		needed = needed,
		needed_groups = needed_groups,
		recipe = recip,
		result = protolist:get_name(),
	}))
end



local function fancy_machine_node_timer(pos, elapsed)


	local meta = minetest.get_meta(pos)
	local fuel_time = meta:get_float("fuel_time") or 0
	local make_time = meta:get_float("make_time") or 0
	local fuel_totaltime = meta:get_float("fuel_totaltime") or 0

	
	local inv = meta:get_inventory()

	local protolist = inv:get_stack("proto", 1)
	
	-- check fuel

	
	
	
	proto = protolist:get_name()
	if proto == nil then
		return
	end

	
	local tmp = meta:get_string("work")
	if not tmp then
		-- no prototype or recipe selected
		return
	end
	
	local work = minetest.deserialize(tmp)
	if not work or not work.needed then
		-- missing or bad data
		return
	end
	
	local needed = work.needed
	local needed_groups = work.needed_groups
	
	-- collect all the ingredients
	
	-- todo: cache hopper locations
	-- look for hoppers
	local hoppers = minetest.find_nodes_in_area(
		{x=pos.x - 1, y=pos.y + 1, z = pos.z - 1},
		{x=pos.x + 1, y=pos.y + 1, z = pos.z + 1},
		"machines:hopper"
	)
	
	local has_cnt = 0
	local has = {}
	print("hoppers found: "..#hoppers)
	for _,hop in ipairs(hoppers) do
		local hmeta = minetest.get_meta(hop)
		local hinv = hmeta:get_inventory()
		
		local hlist = hinv:get_list("main")
		if #hlist > 0 then
			
			local hitem = hlist[1]
			if hitem then
				local hitem_name = hitem:get_name()
			
				print("hopper item: ".. hitem_name)
				
				if needed[hitem_name] then
					print("needed item")
					has[hitem_name] = (has[hitem_name] or 0) + hitem:get_count()
				else
					for _,g in pairs(needed_groups) do 
						if minetest.registered_items[hitem_name].groups[g] ~= nil then
							print("found needed group item")
							has[hitem] = (has[hitem] or 0) + hlist:get_count()
						end
					end
				end
				
			end
		else
			print("hopper empty")
		end
		
	end
	
	local some_missing = 0 
	for name,qty in pairs(needed) do
		if not has[name] or has[name] < qty then
			print("item: "..name.. " has: " .. (has[name] or "none") .. " need: " ..qty)
			some_missing = 1
			break
		end
	end
	
	
	if some_missing == 1 then
		print("not enough supply for machine at "..pos.x..","..pos.y..","..pos.z)
		return false
	end
	
	-- take the inputs to craft an item 
	for _,hop in ipairs(hoppers) do
		local hmeta = minetest.get_meta(hop)
		local hinv = hmeta:get_inventory()
		
		--local hlist = hinv:get_list("main")
		
		for name,qty in pairs(needed) do
			local taken = hinv:remove_item("main", name .. " " .. qty) 
			print("took ".. taken:get_count() .. " of " .. taken:get_name())
			
			needed[name] = qty - taken:get_count()
			if needed[name] == 0 then
				needed[name] = nil
			end
		end
	end
	
	-- recheck needed to make sure enough was taken
	
	
	-- output the item
	local outmeta = minetest.get_meta({x=pos.x, y=pos.y - 1, z=pos.z})
	local outinv = outmeta:get_inventory()
	
	outinv:add_item("main", proto)
	
	return true
end




local function machine_node_timer(pos, elapsed)
	
	print("machine timer " .. elapsed)
	return fancy_machine_node_timer(pos, elapsed)
end







function get_machine_inactive_formspec(j)
	local i = j or 0
	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
--		"list[context;src;2.75,0.5;1,1;]"..
		"list[context;needs;0,0;8,2;]"..
		"list[context;proto;1.5,1;1,1;]"..
		"list[context;fuel;4,2;3,2;]"..
		"image[2,2.5;1,1;default_furnace_fire_bg.png]"..
-- 		"image[3.5,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
		"image_button[0.5,1.25;0.8,0.8;creative_prev_icon.png;recipe_prev;]"..
		"image_button[2.5,1.25;0.8,0.8;creative_next_icon.png;recipe_next;]"..
		--		"list[context;dst;4.75,0.96;2,2;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[context;dst]"..
		"listring[current_player;main]"..
		"listring[context;src]"..
		"listring[current_player;main]"..
		"listring[context;fuel]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

function get_machine_active_formspec(fuel_pct)
	
	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
--		"list[context;src;2.75,0.5;1,1;]"..
		"list[context;needs;0,0;8,2;]"..
		"list[context;proto;1.5,1;1,1;]"..
		"list[context;fuel;4,2;3,2;]"..
		"image[2,2.5;1,1;default_furnace_fire_bg.png]^[lowpart:"..
		(100-fuel_pct)..":default_furnace_fire_fg.png]"..
-- 		"image[3.5,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
		"image_button[0.5,1.25;0.8,0.8;creative_prev_icon.png;recipe_prev;]"..
		"image_button[2.5,1.25;0.8,0.8;creative_next_icon.png;recipe_next;]"..
		--		"list[context;dst;4.75,0.96;2,2;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[context;dst]"..
		"listring[current_player;main]"..
		"listring[context;src]"..
		"listring[current_player;main]"..
		"listring[context;fuel]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end



minetest.register_node("machines:machine_on", {
	description = "Machine",
	tiles = {
		"default_furnace_top.png", "default_furnace_bottom.png",
		"default_bronze_block.png", "default_furnace_side.png",
		"default_furnace_side.png", "default_furnace_front.png"
	},
	paramtype2 = "facedir",
	groups = {cracky=2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	stack_max = 1,

	can_dig = can_dig,

	on_timer = machine_node_timer,
	
	on_punch = function(pos) 
		swap_node(pos, "machines:machine") -- regular is the off version
	end,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_machine_active_formspec())
		local inv = meta:get_inventory()
		inv:set_size('needs', 8)
		inv:set_size('fuel', 6)
		inv:set_size('proto', 1)
		
		print("constructed")
		minetest.get_node_timer(pos):start(1.0)
		
	end,

	on_metadata_inventory_move = function(pos)
		--	on_metadata_inventory_put = function(pos, listname)
		--if listname == "proto" then
		--	set_craft_recipe(pos, 1)
		--end
	end,
	
	on_metadata_inventory_put = function(pos, listname)
		if listname == "proto" then
			set_craft_recipe(pos, 1)
		end
	end,
-- 	on_blast = function(pos)
-- 		local drops = {}
-- 		default.get_inventory_drops(pos, "src", drops)
-- 		default.get_inventory_drops(pos, "fuel", drops)
-- 		default.get_inventory_drops(pos, "dst", drops)
-- 		drops[#drops+1] = "machines:machine"
-- 		minetest.remove_node(pos)
-- 		return drops
-- 	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	
	

	on_receive_fields = function(pos, form, fields, sender)
		
		local meta = minetest.get_meta(pos)
		local i = meta:get_float("n") or 1
		
		
		if fields.recipe_next then
			i = i + 1
		elseif fields.recipe_prev then
			i = i - 1
		end
		meta:set_float("n", i)
		
		
		set_craft_recipe(pos, i)
		
		meta:set_string("formspec", get_machine_inactive_formspec(i))
		
	end


	
	
})



minetest.register_node("machines:machine", {
	description = "Machine",
	tiles = {
		"default_furnace_top.png", "default_furnace_bottom.png",
		"default_bronze_block.png", "default_furnace_side.png",
		"default_furnace_side.png", "default_furnace_front.png"
	},
	paramtype2 = "facedir",
	groups = {cracky=2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	stack_max = 1,

	can_dig = can_dig,
	
	on_punch = function(pos) 
		swap_node(pos, "machines:machine_on")
		minetest.get_node_timer(pos):start(1.0)
	end,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_machine_inactive_formspec())
		local inv = meta:get_inventory()
		inv:set_size('needs', 8)
		inv:set_size('fuel', 6)
		inv:set_size('proto', 1)
		
-- 		minetest.get_node_timer(pos):start(1.0)
		
	end,

	on_metadata_inventory_move = function(pos)
-- 		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_put = function(pos, listname)
		if listname == "proto" then
			set_craft_recipe(pos, 1)
		end
	end,
-- 	on_blast = function(pos)
-- 		local drops = {}
-- 		default.get_inventory_drops(pos, "src", drops)
-- 		default.get_inventory_drops(pos, "fuel", drops)
-- 		default.get_inventory_drops(pos, "dst", drops)
-- 		drops[#drops+1] = "machines:machine"
-- 		minetest.remove_node(pos)
-- 		return drops
-- 	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	
	

	on_receive_fields = function(pos, form, fields, sender)
		
		local meta = minetest.get_meta(pos)
		local i = meta:get_float("n") or 1
		
		
		if fields.recipe_next then
			i = i + 1
		elseif fields.recipe_prev then
			i = i - 1
		end
		meta:set_float("n", i)
		
		set_craft_recipe(pos, i)
		
		meta:set_string("formspec", get_machine_inactive_formspec(i))
		
	end


	
	
})



