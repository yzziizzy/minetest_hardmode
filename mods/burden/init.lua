
--[[

the more you carry the slower you go

]]

burden = {}
burden.players = {}

local mod_path = minetest.get_modpath("burden")

dofile(mod_path.."/weights.lua")


local base_burden = 1 -- don't mess with this one
local burden_scale = .006 -- this is the one to adjust that you are looking for
local base_speed = 1.5 -- a little faster than normal, when carrying nothing


local speed_bonuses = {}
local wear_rates = {}


local function set_burden(player)

	local pname = player:get_player_name()
	local inv = player:get_inventory()
	local main = inv:get_list("main")

	local b = 0
	local total_bonus = 0
	local active_bonus = {}
	
	local hot = player:hud_get_hotbar_itemcount()
	
	for i,st in ipairs(main)  do
	
		local name = st:get_name()
		
		if i <= hot then
			burden.players[pname].hotbar[i] = name
		
			local bonus = speed_bonuses[name] 
			if bonus and active_bonus[name] == nil then
				total_bonus = total_bonus + bonus
				active_bonus[name] = true
				
				st:add_wear(wear_rates[name])
				--if st:get_count() == 0 and wdef.sound and wdef.sound.breaks then
				--	core.sound_play(wdef.sound.breaks, {pos = pos, gain = 0.5})
				--end
				-- TODO: wear the sandals
			end
		end
		
		
		if name ~= "" then
			
			local factor = 1
			
			if nil ~= burden.weights[name] then
				factor = burden.weights[name]
			elseif nil ~= minetest.registered_tools[name] then
				factor = 1.5
			elseif nil ~= minetest.registered_craftitems[name] then 
				factor = 2
			elseif nil ~= minetest.registered_nodes[name] then 
				factor = 4
			elseif nil ~= minetest.registered_items[name] then 
				factor = 1
			else 
				factor = 0
			end
			
			local prorate = st:get_count() / st:get_stack_max()
			
			b = b + (prorate * factor * base_burden)
		end
	end
	
	inv:set_list("main", main)
	
	---print("total_bonus: ".. total_bonus)
	player:set_physics_override({
		speed = base_speed - (b * burden_scale) + total_bonus,
	})
		
	
	
end



local function cyclic_update()
	for _, player in ipairs(minetest.get_connected_players()) do
		set_burden(player)
	end
	minetest.after(5, cyclic_update)
end

minetest.after(5, cyclic_update)


-- init player data structures
minetest.register_on_joinplayer(function(player)
	burden.players[player:get_player_name()] = {
		hotbar = {}
	}
end)

-- prevent digging when inventory is full

local old_node_dig = minetest.node_dig

minetest.node_dig = function(pos, node, digger)
	local def = minetest.registered_nodes[node.name]
	if def and (not def.diggable or
			(def.can_dig and not def.can_dig(pos, digger))) then
		return
	end

	if digger:is_player() then
		
		local inv = digger:get_inventory()
		local wielded = digger and digger:get_wielded_item()
		
		if wielded then
		--print("wielded " .. wielded:get_name())
		else 
		--print("wielded - nil")
		end
		local drops = minetest.get_node_drops(node, wielded and wielded:get_name())
		
		local took_item = false
		
		for _,st in pairs(drops)  do
			--print(st)
			if inv:room_for_item("main", st) then
				took_item = true
				--print("st ".. st)
				local leftovers = inv:add_item("main", st)
				
				if leftovers ~= nil then
					--print("breaking 2\n")
					--break
				end
			else
				--print("breaking 1\n")
				break
			end
		end
		--minetest.handle_node_drops(pos, drops, digger)

		
		
		
		if took_item then
			minetest.remove_node(pos)
			
			if wielded and wielded:get_name() ~= "" then
				local wdef = wielded:get_definition()
				local tp = wielded:get_tool_capabilities()
				local dp = core.get_dig_params(def and def.groups, tp)
				if wdef and wdef.after_use then
					wielded = wdef.after_use(wielded, digger, node, dp) or wielded
				else
					-- Wear out tool
					if not core.settings:get_bool("creative_mode") then
						wielded:add_wear(dp.wear)
						if wielded:get_count() == 0 and wdef.sound and wdef.sound.breaks then
							core.sound_play(wdef.sound.breaks, {pos = pos, gain = 0.5})
						end
					end
				end
				digger:set_wielded_item(wielded)
			end
			
			-- Run callback
			if def and def.after_dig_node then
				-- Copy pos and node because callback can modify them
				local pos_copy = {x=pos.x, y=pos.y, z=pos.z}
				local node_copy = {name=node.name, param1=node.param1, param2=node.param2}
				def.after_dig_node(pos_copy, node_copy, oldmetadata, digger)
			end
			
			-- Run script hook
			local _, callback
			for _, callback in ipairs(core.registered_on_dignodes) do
				local origin = core.callback_origins[callback]
				if origin then
					core.set_last_run_mod(origin.mod)
					--print("Running " .. tostring(callback) ..
					--	" (a " .. origin.name .. " callback in " .. origin.mod .. ")")
				else
					--print("No data associated with callback")
				end

				-- Copy pos and node because callback can modify them
				local pos_copy = {x=pos.x, y=pos.y, z=pos.z}
				local node_copy = {name=node.name, param1=node.param1, param2=node.param2}
				callback(pos_copy, node_copy, digger)
			end
			
		end
		
		return
	end
	printf("burden: shouldn't be here")
	-- non-players
	old_node_dig(pos, node, digger)
end


-- can't just drop items

local old_item_drop = minetest.item_drop
minetest.item_drop = function(itemstack, dropper, pos)
	if not dropper:is_player() then
		old_item_drop(itemstack, dropper, pos)
	end
end



-- bonus items


minetest.register_tool("burden:sandals", {
	description = "Sandals",
	stack_max = 1,
	inventory_image = "burden_sandals.png",
	groups = {},
})

minetest.register_craft({
	output = 'burden:sandals 1',
	recipe = {
		{'', '', ''},
		{'default:papyrus', 'farming:string', 'default:papyrus'},
		{'default:papyrus', '', 'default:papyrus'},
	}
})


speed_bonuses["burden:sandals"] = .2
wear_rates["burden:sandals"] = 50
