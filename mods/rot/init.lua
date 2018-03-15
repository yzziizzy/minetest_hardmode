

rot = {}


function deepclone(t)
	if type(t) ~= "table" then 
		return t 
	end
	
	local meta = getmetatable(t)
	local target = {}
	
	for k, v in pairs(t) do
		if type(v) == "table" then
			target[k] = deepclone(v)
		else
			target[k] = v
		end
	end
	
	setmetatable(target, meta)
	
	return target
end

local function splitname(name)
	local c = string.find(name, ":", 1)
	return string.sub(name, 1, c - 1), string.sub(name, c + 1, string.len(name))
end


-- change table
local downgrades = {}

-- for abm node list
local abm_list_1 = {}
local abm_list_2 = {}
local abm_list_final = {}




rot.register_node = function(old, tiles) 
	
	-- level 1
	local def = deepclone(minetest.registered_nodes[old])
	def.groups.not_in_creative_inventory = 1
	def.groups.rotten = 1
	def.description = "Rotting " .. def.description
	
	local oldmod, oldname = splitname(old)
	local name1 = "rot:"..oldmod.."_"..oldname.."_1"
	table.insert(abm_list_1, old)
	downgrades[old] = name1
	
	if tiles then
		def.tiles = tiles
	else
		for k, v in pairs(def.tiles) do
			def.tiles[k] = def.tiles[k].."^[colorize:black:80"
		end
	end
	
	if drops then 
		def.drops = drops
	else
		def.drops = name1
	end
	
	minetest.register_node(name1, def)
	
	-- level 2
	def = deepclone(minetest.registered_nodes[old])
	def.groups.not_in_creative_inventory = 1
	def.groups.rotten = 2
	def.description = "Rotten " .. def.description
	
	local oldmod, oldname = splitname(old)
	local name2 = "rot:"..oldmod.."_"..oldname.."_2"
	table.insert(abm_list_2, name1)
	downgrades[name1] = name2
	
	if tiles then
		def.tiles = tiles
	else
		for k, v in pairs(def.tiles) do
			def.tiles[k] = def.tiles[k].."^[colorize:black:180"
		end
	end
	
	if drops then 
		def.drops = drops
	else
		def.drops = name2
	end
	
	minetest.register_node(name2, def)
	
	-- for the final transition to dirt
	table.insert(abm_list_final, name2)
	downgrades[name2] = "default:dirt"
	
	
end



rot.register_node("default:wood")
rot.register_node("default:aspen_wood")
rot.register_node("default:acacia_wood")
rot.register_node("default:pine_wood")
rot.register_node("default:junglewood")

rot.register_node("default:fence_wood")
rot.register_node("default:fence_acacia_wood")
rot.register_node("default:fence_junglewood")
rot.register_node("default:fence_pine_wood")
rot.register_node("default:fence_aspen_wood")

rot.register_node("farming:straw")


local stairlist = {
	"wood",
	"aspen_wood",
	"pine_wood",
	"acacia_wood",
	"junglewood",
	"straw"
}

-- BUG: stairs has complicated images
-- for _,v in ipairs(stairlist) do
-- 	rot.register_node("stairs:stair_"..v)
-- 	rot.register_node("stairs:stair_outer_"..v)
-- 	rot.register_node("stairs:stair_inner_"..v)
-- 	rot.register_node("stairs:slab_"..v)
-- end

-- todo: stairs/slabs, chests, doors, beds


minetest.register_abm({
	nodenames = abm_list_1,
 	neighbors = {"group:soil", "group:rotten", "group:water"},
	interval = 1,--15,
	chance = 100,
	catch_up = true,
	action = function(pos, node)
		local n = downgrades[node.name]
		if n then
			minetest.set_node(pos, {name = n})
		end
	end,
})


minetest.register_abm({
	nodenames = abm_list_2,
	neighbors = {"group:soil", "group:rotten", "group:water"},
	interval = 10,
	chance = 80,
	catch_up = true,
	action = function(pos, node)
		
		minetest.set_node(pos, {name= downgrades[node.name]})
	end,
})

minetest.register_abm({
	nodenames = abm_list_final,
	neighbors = {"group:soil", "group:rotten", "group:water"},
	interval = 10,
	chance = 50,
	catch_up = true,
	action = function(pos, node)
		
		minetest.set_node(pos, {name= downgrades[node.name]})
	end,
})
