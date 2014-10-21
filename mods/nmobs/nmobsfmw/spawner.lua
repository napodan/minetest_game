ABR = minetest.setting_get("active_block_range")
spawner_param = {}
spawner_param["hostile"] = { 
	category = "hostile",
	nodenames = {},
	neighbors = {"air"},
	interval = 30,
	chance = 2000,
	entities = {},
	nbEntities = 0, -- Number of spawned entities in the current block
	current_block = nil, -- We only treat 4 nodes in a block
	nbMax = math.ceil(70 * ABR^3 / 512), -- Max entities in the Active Block Range
	current_entity = 0, -- Entity that will be spawn in the current block
}

function spawning_function_hostile(pos, node, active_object_count, active_object_count_wider)
	spawning_function(pos, node, active_object_count, active_object_count_wider, spawner_param["hostile"])
end

function spawning_function(pos, node, active_object_count, active_object_count_wider, param)
	for _,player in pairs(minetest.get_connected_players()) do
		local p = player:getpos()
		-- calcul nb entities de la categorie
		local nbTotalEntities = 0
		for _,object in pairs(minetest.get_objects_inside_radius(p,128.0)) do
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
		local dist = vector.distance(p, pos)
		if dist <= 24 then
			return
		end
	end
	local block = vector.divide(pos, 16)
	block = vector.subtract(block, 0.5)
	block = vector.round(block)
	if param.current_block == nil or not vector.equals(param.current_block, block) then
		param.current_block = vector.new(block)
		param.nbEntities = 0
		-- Select the species to spawn in category hostile
		param.current_entity = math.random(1, #param.entities[node.name])
	end
	if param.nbEntities >= 4 then
		return
	end
	pos.y = pos.y + 0.5
--[[
	if not minetest.env:get_node_light(pos) then
		return
	end
	if minetest.env:get_node_light(pos) > max_light then
		return
	end
	if minetest.env:get_node_light(pos) < 9 then
		return
	end
	if pos.y > max_height then
		return
	end
--]]
	if minetest.env:get_node(pos).name ~= "air" then
		return
	end
	pos.y = pos.y + 1
	if minetest.env:get_node(pos).name ~= "air" then
		return
	end
	pos.y = pos.y - 1
	-- TODO groups are not working
	local mob = minetest.add_entity(pos, param.entities[node.name][param.current_entity])
	if mob then
		param.nbEntities = param.nbEntities + 1
	end
end

-- TODO put action in spawner_param
function register_category(name, action)
	minetest.register_abm({
		nodenames = spawner_param[name].nodenames,
		neighbors = spawner_param[name].neighbors,
		interval = spawner_param[name].interval,
		chance = spawner_param[name].chance,
		action = action,
	})
end

function init_spawners(mapgen_params)
	register_category("hostile", spawning_function_hostile)
end

minetest.register_on_mapgen_init(init_spawners(mapgen_params))


