cold = {}
cold.items = {}


local mod_path = minetest.get_modpath("cold")

dofile(mod_path.."/items.lua")

COLD_MAX = 20
COLD_FACTOR = .07
COLD_SHIVER = .5
COLD_FREEZE = 1.5
COLD_SHIVER_LVL = 15
COLD_FREEZE_LVL = 19
COLD_SHIVER_CHANCE = 5
COLD_SUN_FACTOR = 1.5
COLD_LAT_FACTOR = 10
COLD_LAT_OFFSET = 0 -- -0.4 -- .5 for even. lower is warmer.
COLD_UNDERGROUND_TEMP = 12 -- target temp to approach 
COLD_UNDERGROUND_Y = -12 -- height before underground temp takes over  
COLD_ELV_OFFSET = -55 -- lower makes higher elevations warmer 
COLD_ELV_RATE = .035 -- .01 for 1 degree every 100 nodes 
COLD_DEEP_Y = -512 -- height where the earth starts to get warm on its own
COLD_DEEP_RATE = .01 -- higher makes deeper levels get warmer, per node
COLD_SEASON_FACTOR = 2

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
	if not name or not cold[name] then
		return false
	end
	
	local env
	local ppos = player:getpos()
	
	local lvl = cold[name].lvl
	
	if ppos.y < COLD_DEEP_Y then
		
		env = (ppos.y + COLD_DEEP_Y) * COLD_DEEP_RATE
		print("deep: ".. env)
	elseif ppos.y < COLD_UNDERGROUND_Y then
		
		-- approach the underground temp
		env = (COLD_UNDERGROUND_TEMP - lvl) * .5
		print("und: ".. env)
	else -- normal surface calculations
		local season, season_time = seasons.get_season()
		local seas = 0
		if season == "winter" then
			seas = 1
		elseif season == "spring" then
			seas = 1 - season_time
		elseif season == "fall" then
			seas = season_time
		end
		
		local sun = (math.sin(minetest.get_timeofday() * math.pi) * -2) + .5
		print("tod: " .. sun);
		local lat = math.sin(ppos.z / (16000)) + COLD_LAT_OFFSET
		
		local elv = math.max(ppos.y + COLD_ELV_OFFSET, 0)
		print("elv: " .. elv * COLD_ELV_RATE)
		env = sun * COLD_SUN_FACTOR + 
					lat * COLD_LAT_FACTOR +
					elv * COLD_ELV_RATE + 
					seas * COLD_SEASON_FACTOR
				
	
		print("cold sun: " .. (sun * COLD_SUN_FACTOR))
		print("cold lat: " .. (lat * COLD_LAT_FACTOR))
	end
	
	-- TODO need to check if the player is swimming
	print("cold env: " .. env)
	
	local pos
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
		coldfactor = -20
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
	
	-- bonuses from items like clothes
	local clothes = 0
	local cslots = {}
	if burden.players[name] then
		for i,c in ipairs(burden.players[name].hotbar) do
			local ins = minetest.get_item_group(c, "insulation")
			if ins > 0 then
				local slot
				if minetest.get_item_group(c, "hat") then
					slot = "hat"
				elseif minetest.get_item_group(c, "gloves") then
					slot = "gloves"
				elseif minetest.get_item_group(c, "boots") then
					slot = "boots"
				elseif minetest.get_item_group(c, "coat") then
					slot = "coat"
				else 
					slot = "none"
				end
				
				-- note that bonues must be subtracted to get warmth
				if cslots[slot] < ins then
					clothes = clothes + cslots[slot]
				end
				
				cslots[slot] = ins
				clothes = clothes - ins
			end
		end
	end
	
	if new_lvl > 0 then
		 lvl = new_lvl
	else 
		lvl = lvl + (coldfactor * COLD_FACTOR) + env + clothes
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
		
		player:set_hp(hp)
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










