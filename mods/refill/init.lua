




minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	
	local inv = placer:get_inventory()
	local main = inv:get_list("main")
	
	local index = placer:get_wield_index() 
	local item = placer:get_wielded_item():get_name() 
	print("index: " .. item .. " size: " .. inv:get_size("main"))
	
	-- find a stack to decrease instead
	
	 
	for i = inv:get_size("main"), 1, -1 do
		if index ~= i then
			local s = inv:get_stack("main", i)
			
			print("pos "..i..": ".. s:get_name() .. " " .. s:get_count())
			if item == s:get_name() then 
				s:take_item(1)
				inv:set_stack("main", i, s)

				return true
			end
		end
	end
	
	if oldnode ~= nil then
		print("Node " .. oldnode.name .. " at " .. 
				minetest.pos_to_string(pos) .. " replaced with " .. 
				newnode.name .. "  by " .. placer:get_player_name())
	else
		print("Node " .. newnode.name .. " at " ..
				minetest.pos_to_string(pos) .. " placed by " .. placer:get_player_name())
	end
end)
