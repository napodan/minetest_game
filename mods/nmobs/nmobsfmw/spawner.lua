local ABR = minetest.setting_get("active_block_range")
-- Distance max from a player to a node in the active area
local distmax = ( 3 * (ABR * 16)^2 )^0.5
local INTERVAL = 30
spawner_param = {}
spawner_param["hostile"] = { 
	category = "hostile",
	surfaces = {},
	nodes = {"air"},
	interval = INTERVAL,
	chance = 300 / INTERVAL,
	-- entities is a list indexed by node name
	-- each record in that list is a list indexed by an integer or by a string
		-- each record indexed by an integer is a name of a mob
		-- each record indexed by a string is a mob (the name is the index)
	entities = {},
	nbEntities = 0, -- Number of spawned entities in the current block
	current_block = nil, -- We only treat 4 nodes in a block
	nbMax = math.ceil(70 * (ABR)^3 / 4096), -- Max entities in the Active Block Range
	current_entity = "", -- Entity that will be spawn in the current block
}

function spawning_function_hostile(pos, node, active_object_count, active_object_count_wider)
	spawning_function(pos, node, active_object_count, active_object_count_wider, spawner_param["hostile"])
end

function spawning_function(pos, node, active_object_count, active_object_count_wider, param)
	local distplayermin = distmax
	local nearestplayer = {}
	for _,player in pairs(minetest.get_connected_players()) do
		local p = player:getpos()
		local dist = vector.distance(p, pos)
		if dist <= 24 then
			return
		end
		if dist < distplayermin then
			distplayermin = dist
			nearestplayer = p
		end
	end

	if distplayermin == distmax then
		return
	end
	-- calcul nb entities de la categorie
	local nbTotalEntities = 0
	for _,object in pairs(minetest.get_objects_inside_radius(nearestplayer, distmax)) do
		if not object:is_player() then
			local entity = object:get_luaentity()
			if entity then
				if entity.category == param.category then
					nbTotalEntities = nbTotalEntities + 1
					if nbTotalEntities > param.nbMax then
						return
					end
				end
			end
		end
	end
	local block = vector.divide(pos, 16)
	block = vector.subtract(block, 0.5)
	block = vector.round(block)
	if param.current_block == nil or not vector.equals(param.current_block, block) then
		param.current_block = vector.new(block)
		param.nbEntities = 0
		param.current_entity = ""
	end
	if param.nbEntities >= 4 then
		return
	end
	pos.y = pos.y + 1
	if minetest.env:get_node(pos).name ~= "air" then
		return
	end
	pos.y = pos.y - 2
	local surface = minetest.env:get_node(pos).name 
	-- #param.entities[surface] counts only record indexed by number
	if param.entities[surface] == nil or #param.entities[surface] == 0 then
		return
	end
	if param.current_entity == "" then
		-- we must choose a mob
		local rank = math.random(1, #param.entities[surface])
		param.current_entity = param.entities[surface][rank]
	end
	if param.entities[surface][param.current_entity] == nil then
		return
	end
	pos.y = pos.y + 0.5
	if not minetest.env:get_node_light(pos) then
		return
	end
--[[
	if minetest.env:get_node_light(pos) > 7 then
		return
	end
	if minetest.env:get_node_light(pos) < 9 then
		return
	end
	if pos.y > max_height then
		return
	end
--]]
	-- TODO groups are not working
	local mob = minetest.add_entity(pos, param.current_entity)
	if mob then
		param.nbEntities = param.nbEntities + 1
	end
end

-- TODO put action in spawner_param
function register_category(name, action)
	minetest.register_abm({
		nodenames = spawner_param[name].nodes,
		neighbors = spawner_param[name].surfaces,
		interval = spawner_param[name].interval,
		chance = spawner_param[name].chance,
		action = action,
	})
end

function init_spawners(mapgen_params)
	register_category("hostile", spawning_function_hostile)
end

minetest.register_on_mapgen_init(init_spawners(mapgen_params))

minetest.register_chatcommand("debug_nmobs", {
	params = "",
	description = "Display entities around players",
	func = function(name, param)
		local nb = {}
		for _,player in pairs(minetest.get_connected_players()) do
			local p = player:getpos()
			for _,object in pairs(minetest.get_objects_inside_radius(p, 240)) do
				if not object:is_player() then
					local entity = object:get_luaentity()
					if entity then
						local pos = entity.object:getpos()
						print(entity.name .. " " .. minetest.pos_to_string(pos))
						if nb[entity.name] == nil then
							nb[entity.name] = 1
						else
							nb[entity.name] = nb[entity.name] + 1
						end
					end
				end
			end
		end
		for mobs, number in pairs(nb) do
			print("Number of " .. mobs .. " : " .. number)
		end
	end,
})

