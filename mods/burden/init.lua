
--[[

the more you carry the slower you go

]]


local base_burden = 1 -- don't mess with this one
local burden_scale = .002 -- this is the one to adjust that you are looking for
local base_speed = 1.5 -- a little faster than normal, when carrying nothing

local function set_burden(player)

	local inv = player:get_inventory()
	local main = inv:get_list("main")

	local burden = 0
	
	
	for i,st in pairs(main)  do
	
		local name = st:get_name()
		if name ~= "" then
			
			local factor = 1
			
			if nil ~= minetest.registered_tools[name] then
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
			
			burden = burden + (prorate * factor * base_burden)
		end
	end
	
	player:set_physics_override({
		speed = base_speed - (burden * burden_scale),
	})
		
	
	
end



local function cyclic_update()
	for _, player in ipairs(minetest.get_connected_players()) do
		set_burden(player)
	end
	minetest.after(5, cyclic_update)
end

minetest.after(5, cyclic_update)
