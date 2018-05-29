



local modpath = minetest.get_modpath("machines")
dofile(modpath.."/hopper.lua")
dofile(modpath.."/autofurnace.lua")



local function splitname(name)
	local c = string.find(name, ":", 1)
	return string.sub(name, 1, c - 1), string.sub(name, c + 1, string.len(name))
end


local function can_dig(pos, player)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("fuel") and inv:is_empty("dst") and inv:is_empty("src")
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
for _,n in ipairs(minetest.registered_items) do
	m,p = splitname(n)
	if m == "default" then
		default_items[n] = p
	end
end


local function get_canonical_item_for_group(group)
	
	for _,name in ipairs(default_items) do
		local item = minetest.registered_items[name]
		
		if item.groups[group] ~= nil then
			
			
			return name
		end
		
	end
	
end


local function get_best_craft_recipe(out_item)
	
	local in_count = 1000
	local out_count = 1000
	
	function sortfn(a, b)
		if #a.items == #b.items then
			return a.width < b.width
		else
			return #a.items < #b.items
		end
		
	end
	
	
	local recipes = minetest.get_all_craft_recipes(proto)
	local normal_list = {}
	for _,r in ipairs(recipes) do
		if r.type == "normal" then
			table.insert(normal_list, r)
		end
	end
	
	table.sort(normal_list, sortfn)
	
	
	return normal_list[1]
end



local function fancy_machine_node_timer(pos, elapsed)

	local meta = minetest.get_meta(pos)
	local fuel_time = meta:get_float("fuel_time") or 0
	local make_time = meta:get_float("make_time") or 0
	local fuel_totaltime = meta:get_float("fuel_totaltime") or 0

	
	local inv = meta:get_inventory()

	local protolist = inv:get_stack("proto", 1)
	
	
	fuel_time = fuel_time + elapsed
	if fuel_time > fuel_totaltime then
		
		-- try to burn more fuel
		local fuellist = inv:get_stack("fuel", 1)
		fuel, out = minetest.get_craft_result({method = "fuel", width = 1, items = fuellist})
		if fuel.time == 0 then
			-- out of fuel
			print("machine out of fuel")
			
			
		else
			local rem = fuel_time - fuel_totaltime
			fuel_time = fuel.time + rem
			
			meta:set_float("fuel_time", fuel.time)
			
			inv:set_stack("fuel", 1, out.items[1])
		end
		
		
		
		meta:set_float("fuel_time", 0)
		meta:set_float("fuel_totaltime", 0)
		
		
		
		
	end

	
	-- clear needs list
	inv:set_list("needs", {})

	
	
	
	proto = protolist:get_name()
	if proto == nil then
		return
	end
	
-- 	local recip = minetest.get_all_craft_recipes(proto)
-- 	if nil == recip or recip.items == nil then
-- 		return
-- 	end
	local recip = get_best_craft_recipe(proto)
	
	
	local needed = {}
	local needed_groups = {}
	
	for i,item in ipairs(recip.items) do
		print("item - "..item)
		
		local name = item
		if item:sub(1, 6) == "group:" then
			local group = item:sub(7)
			needed_groups[group] = (needed_groups[group] or 0) + 1
			
			
			local name = get_canonical_item_for_group(group)
			--[[
			for iname, idef in pairs(minetest.registered_items) do
				if idef.groups[group] ~= nil then
					name = iname
					break
				end
			end]]
		end
		
		needed[item] = (needed[item] or 0) + 1 
		
		inv:set_stack("needs", i, name)
	end
	
	
	-- show needed item to the user
	local i = 1
	for name,qty in pairs(needed) do
		
		inv:set_stack("needs", i, name .. " " .. qty)
		
		i = i + 1
	end
	
	
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
				
				if needed[hitem] then
					print("needed item")
					has[hitem] = (has[hitem] or 0) + hlist:get_count()
				else
					for _,g in ipairs(needed_groups) do 
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
		if not has[name] or has[name] >= qty then 
			some_missing = 1
			break
		end
	end
	
	
	if some_missing then
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
	
	if 1 == 1 then
		return true
	end
	
	local cookable, cooked
	local fuel

	local update = true
	while elapsed > 0 and update do
		update = false

		srclist = inv:get_list("src")
		fuellist = inv:get_list("fuel")

		--
		-- Cooking
		--

		-- Check if we have cookable content
		local aftercooked
		cooked, aftercooked = minetest.get_craft_result({method = "cooking", width = 1, items = srclist})
		cookable = cooked.time ~= 0

		local el = math.min(elapsed, fuel_totaltime - fuel_time)
		if cookable then -- fuel lasts long enough, adjust el to cooking duration
			el = math.min(el, cooked.time - src_time)
		end

		-- Check if we have enough fuel to burn
		if fuel_time < fuel_totaltime then
			-- The furnace is currently active and has enough fuel
			fuel_time = fuel_time + el
			-- If there is a cookable item then check if it is ready yet
			if cookable then
				src_time = src_time + el
				if src_time >= cooked.time then
					-- Place result in dst list if possible
					if inv:room_for_item("dst", cooked.item) then
						inv:add_item("dst", cooked.item)
						inv:set_stack("src", 1, aftercooked.items[1])
						src_time = src_time - cooked.time
						update = true
					end
				else
					-- Item could not be cooked: probably missing fuel
					update = true
				end
			end
		else
			-- Furnace ran out of fuel
			if cookable then
				-- We need to get new fuel
				local afterfuel
				fuel, afterfuel = minetest.get_craft_result({method = "fuel", width = 1, items = fuellist})

				if fuel.time == 0 then
					-- No valid fuel in fuel list
					fuel_totaltime = 0
					src_time = 0
				else
					-- Take fuel from fuel list
					inv:set_stack("fuel", 1, afterfuel.items[1])
					update = true
					fuel_totaltime = fuel.time + (fuel_totaltime - fuel_time)
				end
			else
				-- We don't need to get new fuel since there is no cookable item
				fuel_totaltime = 0
				src_time = 0
			end
			fuel_time = 0
		end

		elapsed = elapsed - el
	end

	if fuel and fuel_totaltime > fuel.time then
		fuel_totaltime = fuel.time
	end
	if srclist[1]:is_empty() then
		src_time = 0
	end

	--
	-- Update formspec, infotext and node
	--
	local formspec
	local item_state
	local item_percent = 0
	if cookable then
		item_percent = math.floor(src_time / cooked.time * 100)
		if item_percent > 100 then
			item_state = "100% (output full)"
		else
			item_state = item_percent .. "%"
		end
	else
		if srclist[1]:is_empty() then
			item_state = "Empty"
		else
			item_state = "Not cookable"
		end
	end

	local fuel_state = "Empty"
	local active = "inactive"
	local result = false

	if fuel_totaltime ~= 0 then
		active = "active"
		local fuel_percent = math.floor(fuel_time / fuel_totaltime * 100)
		fuel_state = fuel_percent .. "%"
		formspec = default.get_furnace_active_formspec(fuel_percent, item_percent)
		swap_node(pos, "default:furnace_active")
		-- make sure timer restarts automatically
		result = true
	else
		if not fuellist[1]:is_empty() then
			fuel_state = "0%"
		end
		formspec = default.get_furnace_inactive_formspec()
		swap_node(pos, "default:furnace")
		-- stop timer on the inactive furnace
		minetest.get_node_timer(pos):stop()
	end

	local infotext = "Furnace " .. active .. "\n(Item: " .. item_state ..
		"; Fuel: " .. fuel_state .. ")"

	--
	-- Set meta values
	--
	meta:set_float("fuel_totaltime", fuel_totaltime)
	meta:set_float("fuel_time", fuel_time)
	meta:set_float("src_time", src_time)
	meta:set_string("formspec", formspec)
	meta:set_string("infotext", infotext)

	return result
end




local function machine_node_timer(pos, elapsed)
	
	print("machine timer " .. elapsed)
	return fancy_machine_node_timer(pos, elapsed)
end







function get_machine_inactive_formspec()
	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
--		"list[context;src;2.75,0.5;1,1;]"..
		"list[context;needs;0,1;8,2;]"..
		"list[context;fuel;2.75,2.5;1,1;]"..
		"image[2.75,1.5;1,1;default_furnace_fire_bg.png]"..
		"image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
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

	on_timer = machine_node_timer,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_machine_inactive_formspec())
		local inv = meta:get_inventory()
		inv:set_size('src', 1)
		inv:set_size('needs', 8)
		inv:set_size('fuel', 1)
		inv:set_size('dst', 4)
		
		minetest.get_node_timer(pos):start(1.0)
		
	end,

	on_metadata_inventory_move = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_put = function(pos)
		-- start timer function, it will sort out whether furnace can burn or not.
		minetest.get_node_timer(pos):start(1.0)
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
})





