
--[[

the more you carry the slower you go

]]

burden = {}
burden.players = {}


local base_burden = 1 -- don't mess with this one
local burden_scale = .002 -- this is the one to adjust that you are looking for
local base_speed = 1.5 -- a little faster than normal, when carrying nothing

local function set_burden(player)

	local pname = player:get_player_name()
	local inv = player:get_inventory()
	local main = inv:get_list("main")

	local b = 0
	
	local hot = player:hud_get_hotbar_itemcount()
	
	for i,st in ipairs(main)  do
	
		local name = st:get_name()
		
		if i <= hot then
			burden.players[pname].hotbar[i] = name
		end
		
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
			
			b = b + (prorate * factor * base_burden)
		end
	end
	
	player:set_physics_override({
		speed = base_speed - (b * burden_scale),
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
function minetest.node_dig(pos, node, digger)

	if digger:is_player() then
		
		local inv = digger:get_inventory()
		local drops = minetest.get_node_drops(node.name)
		
		local took_item = false
		
		for i,st in ipairs(drops)  do
			if inv:room_for_item("main", st) then
				took_item = true
				
				local leftovers = inv:add_item("main", st)
				
				if leftovers ~= nil then
					break
				end
			else
				break
			end
		end
		
		if took_item then
			minetest.set_node(pos, {name="air"})
		end
		
		return
	end
		
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


