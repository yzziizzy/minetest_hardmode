




local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end




local function get_af_active_formspec(fuel_percent, item_percent)
	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
-- 		"list[context;src;2.75,0.5;1,1;]"..
		"list[context;fuel;.75,.5;2,4;]"..
		"image[2.75,1.5;1,1;default_furnace_fire_bg.png^[lowpart:"..
		(100-fuel_percent)..":default_furnace_fire_fg.png]"..
		"image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[lowpart:"..
		(item_percent)..":gui_furnace_arrow_fg.png^[transformR270]"..
-- 		"list[context;dst;4.75,0.96;2,2;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
-- 		"listring[context;dst]"..
-- 		"listring[current_player;main]"..
-- 		"listring[context;src]"..
-- 		"listring[current_player;main]"..
-- 		"listring[context;fuel]"..
-- 		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
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

-- gets a new item to cook
local function grab_raw_item(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	
	local list = inv:get_list("main")
	for i,st in ipairs(list) do
	
		local cooked 
		cooked, remains = minetest.get_craft_result({method = "cooking", width = 1, items = {ItemStack(st:get_name())}})
		
		if cooked.time ~= 0 then
			st:take_item()
			inv:set_stack("main", i, st)
			
			return cooked
		end
	end
	
	return nil -- no cookable items found
end

-- returns false if the container overflowed
local function put_item(pos, item) 
	local meta = minetest.get_meta(pos)
	if meta == nil then
		print("af: wasting item for lack of output")
		return
	end
	
	local inv = meta:get_inventory()
	if inv == nil then
		print("af: wasting item for lack of output inventory")
		return
	end
	
	local rem = inv:add_item("main", item)
	if rem ~= nil and rem:get_count() > 0 then
		return false
	end
	
	return true
end



local function af_on_timer(pos, elapsed)

	local meta = minetest.get_meta(pos)
	local fuel_time = meta:get_float("fuel_time") or 0
	local fuel_burned = meta:get_float("fuel_burned") or 0
	local cook_time_remaining = meta:get_float("cook_time_remaining") or 0
	local cook_item = meta:get_string("cook_item") or ""
	
	local inv = meta:get_inventory()
	
	local can_cook = false
	
	local burned = elapsed
	local turn_off = false
	
	print("\n\naf timer")
	print("fuel_burned: " .. fuel_burned)
	print("fuel_time: " .. fuel_time)
	
-- 	if fuel_burned <= fuel_time or fuel_time == 0 then
-- 		-- use fuel
-- 		print("af fuel")
		
		if fuel_time > 0 and fuel_burned + elapsed < fuel_time then

			fuel_burned = fuel_burned + elapsed
			meta:set_float("fuel_burned", fuel_burned + elapsed)
		else
			local t = grab_fuel(inv)
			if t <= 0 then -- out of fuel
				print("out of fuel")
				meta:set_float("fuel_time", 0)
				meta:set_float("fuel_burned", 0)
				
				burned = fuel_time - fuel_burned
				
				turn_off = true
			else
				-- roll into the next period
				fuel_burned =  elapsed - (fuel_time - fuel_burned)
				fuel_time = t
				
				print("fuel remaining: " .. (fuel_time - fuel_burned))
			
				meta:set_float("fuel_time", fuel_time)
				meta:set_float("fuel_burned", fuel_burned)
			end
		end
		
-- 	end
	
	
		
	if cook_item == "" then
		
		
		local cooked = grab_raw_item({x=pos.x, y=pos.y+1, z=pos.z})
		if cooked ~= nil then
			cook_item = cooked.item:to_table()
			cook_time_remaining = cooked.time
			print(cook_item)
			meta:set_string("cook_item", minetest.serialize(cook_item))
			meta:set_float("cook_time_remaining", cooked.time)
		else
			-- nothing to cook, carry on
			print("nothing to cook")
			cook_item = nil
			meta:set_string("cook_item", "")
		end
		
		
	else
		print(cook_item)
		cook_item = minetest.deserialize(cook_item)
	end
	
	
	if cook_item ~= nil and burned > 0 then
		
		local remain = cook_time_remaining - burned
		print("remain: ".. remain);
		if remain > 0 then
			meta:set_float("cook_time_remaining", remain)
		else
			print("finished")
			-- cooking is finished
			put_item({x=pos.x, y=pos.y - 1, z=pos.z}, cook_item.name .. " " .. (cook_item.count or 1))
			
			meta:set_string("cook_item", "")
			meta:set_float("cook_time_remaining", 0)
		end
		
		
	end
	
	
	
	if turn_off then
		swap_node(pos, "machines:autofurnace_off")
		return
	end
	
	fuel_pct = math.floor((fuel_burned * 100) / fuel_time)
--	item_pct = math.floor((fuel_burned * 100) / fuel_time)
	meta:set_string("formspec", get_af_active_formspec(fuel_pct, 0))
	meta:set_string("infotext", "Fuel: " ..  fuel_pct)
	
	minetest.get_node_timer(pos):start(1.0)
	
	
	
	--[[
	
	local cookable, cooked
	local fuel

	local update = true
	while elapsed > 0 and update do
		update = false

		--srclist = inv:get_list("src")
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


	return result ]]
end



function get_af_inactive_formspec()
	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
--		"list[context;src;2.75,0.5;1,1;]"..
		"list[context;fuel;2.75,2.5;2,2;]"..
		"image[2.75,1.5;1,1;default_furnace_fire_bg.png]"..
-- 		"image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
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







minetest.register_node("machines:autofurnace", {
	description = "Autofurnace",
	tiles = {
		"default_bronze_block.png", "default_bronze_block.png",
		"default_bronze_block.png", "default_bronze_block.png",
		"default_bronze_block.png",
		{
			image = "default_furnace_front_active.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1.5
			},
		}
	},
	paramtype2 = "facedir",
	groups = {cracky=2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	stack_max = 1,

	can_dig = can_dig,

	on_timer = af_on_timer,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_af_inactive_formspec())
		local inv = meta:get_inventory()
		inv:set_size('fuel', 4)
		
		minetest.get_node_timer(pos):start(1.0)
		
	end,

	on_metadata_inventory_move = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_put = function(pos)
		-- start timer function, it will sort out whether furnace can burn or not.
		minetest.get_node_timer(pos):start(1.0)
	end,
	
	
	on_punch = function(pos)
		swap_node(pos, "machines:autofurnace_off")
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






minetest.register_node("machines:autofurnace_off", {
	description = "Autofurnace (off)",
	tiles = {
		"default_bronze_block.png", "default_bronze_block.png",
		"default_bronze_block.png", "default_bronze_block.png",
		"default_bronze_block.png", "default_furnace_front.png"
	},
	paramtype2 = "facedir",
	groups = {cracky=2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	stack_max = 1,

	can_dig = can_dig,

	--on_timer = af_node_timer,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_af_inactive_formspec())
		local inv = meta:get_inventory()
		inv:set_size('fuel', 4)
		
		--minetest.get_node_timer(pos):start(1.0)
		
	end,

	on_metadata_inventory_move = function(pos)
		--minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_put = function(pos)
		-- start timer function, it will sort out whether furnace can burn or not.
		--minetest.get_node_timer(pos):start(1.0)
	end,
	
	on_punch = function(pos)
		swap_node(pos, "machines:autofurnace")
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








minetest.register_craft({
	output = 'machines:autofurnace_off',
	recipe = {
		{'default:bronze_ingot', 'default:bronze_ingot', 'default:bronze_ingot'},
		{'default:bronze_ingot', 'default:flint',        'default:bronze_ingot'},
		{'default:bronze_ingot', 'default:bronze_ingot', 'default:bronze_ingot'},
	}
})















