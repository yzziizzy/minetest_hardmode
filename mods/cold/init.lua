cold = {}


COLD_MAX = 20
COLD_FACTOR = .07
COLD_SHIVER = .5
COLD_FREEZE = 1.5
COLD_SHIVER_LVL = 15
COLD_FREEZE_LVL = 19
COLD_SHIVER_CHANCE = 5
COLD_SUN_FACTOR = 1.5
COLD_LAT_DIVISOR = 16000 -- number of nodes north or south (z) to equal 1 point lost

-- read/write
function cold.read(player)
	local inv = player:get_inventory()
	if not inv then
		return nil
	end
	local hgp = inv:get_stack("cold", 1):get_count()
	if hgp == 0 then
		hgp = 21
		inv:set_stack("cold", 1, ItemStack({name = ":", count = hgp}))
	else
		hgp = hgp
	end
	if tonumber(hgp) > COLD_MAX + 1 then
		hgp = COLD_MAX + 1
	end
	return hgp - 1
end


function cold.save(player)
	local inv = player:get_inventory()
	local name = player:get_player_name()
	local value = cold[name].lvl
	if not inv or not value then
		return nil
	end
	if value > COLD_MAX then
		value = COLD_MAX
	end
	
	if value < 0 then
		value = 0
	end
	inv:set_stack("cold", 1, ItemStack({name = ":", count = value + 1}))
	return true
end

function cold.update_cold(player, new_lvl)
	local name = player:get_player_name() or nil
	if not name then
		return false
	end
	
	local sun = (math.sin(minetest.get_timeofday() * math.pi) * -2) + .5
	print("tod: " .. sun);
	local pos
	
	local ppos = player:getpos()
	
	-- TODO trig this too
	local lat = math.abs(ppos.z) / COLD_LAT_DIVISOR
	
	local env = sun * COLD_SUN_FACTOR + lat
	
	print("cold sun: " .. (sun * COLD_SUN_FACTOR))
	print("cold lat: " .. lat)
	-- TODO need to check if the player is swimming
	print("cold env: " .. env)
	
	local coldfactor = -2
	
	-- look for hot things nearby
	pos = minetest.find_node_near(ppos, 10, {
		"campfire:campfire",
		"default:furnace_active",
		"fire:basic_flame",
		"fire:permanent_flame",
		"default:lava_souce",
		"default:lava_flowing",
	})
	
	if pos ~= nil then
		coldfactor = -5
	else
		-- look for really cold things
		pos = minetest.find_node_near(ppos, 20, {
			"default:snow",
			"default:snowblock",
			"default:ice",
			"default:dirt_with_snow",
		})
		
		if pos ~= nil then
			coldfactor = 10
		else -- look for chilly things
			local pos = minetest.find_node_near(ppos, 20, {
				"default:dirt_with_coniferous_litter",
				"default:silver_sand", -- cold desert
			})
			
			if pos ~= nil then
				coldfactor = 3
			end
		end
	end
	
	if minetest.setting_getbool("enable_damage") == false then
		cold[name] = 0
		return
	end
	
	local lvl = cold[name].lvl
	if new_lvl > 0 then
		 lvl = new_lvl
	else 
		lvl = lvl + (coldfactor * COLD_FACTOR) + env
	end
	if lvl > COLD_MAX then
		lvl = COLD_MAX
	elseif lvl < 0 then
		lvl = 0
	end
	cold[name].lvl = lvl
	
	print("coldfactor: " .. (coldfactor * COLD_FACTOR))
	print("coldness: " ..lvl)
	
	if lvl >= COLD_SHIVER_LVL then 
		local hp = player:get_hp()
		
		if lvl >= COLD_FREEZE_LVL then
			hp = hp - COLD_FREEZE
		else
			if 0 == math.random(0, COLD_SHIVER_CHANCE) then
				hp = hp - COLD_SHIVER
			end
		end
		
		--player:set_hp(hp)
	end
	
	hud.change_item(player, "cold", {number = lvl})
	cold.save(player)
end
local update_cold = cold.update_cold


if minetest.setting_getbool("enable_damage") then
    minetest.register_on_joinplayer(function(player)
		local inv = player:get_inventory()
		inv:set_size("cold", 1)

		local name = player:get_player_name()
		cold[name] = {}
		cold[name].lvl = cold.read(player)
		cold[name].exhaus = 0
		local lvl = cold[name].lvl
		if lvl > 20 then
			lvl = 20
		end
		
		minetest.after(0.8, function()
			hud.swap_statbar(player, "cold", "armor")
			hud.change_item(player, "cold", {number = lvl, max = 20})
		end)
    end)

    -- for exhaustion

    minetest.register_on_respawnplayer(function(player)
		cold.update_cold(player, 0)
    end)
end



hud.register("cold", {
	hud_elem_type = "statbar",
	position = {x = 0,y = 2},
	size = {x = 24, y = 24},
	text = "cold_hud_snowflake.png",
	number = 20,
	alignment = {x = -1, y = -1},
	offset = {x = 10, y = -30},
	background = "",
	--autohide_bg = true,
	max = 20,
})




local function update(player)
	
	
	update_cold(player, -1)
	
end





local function cyclic_update()
	for _, player in ipairs(minetest.get_connected_players()) do
		update(player)
	end
	minetest.after(5, cyclic_update)
end

minetest.after(5, cyclic_update)
