bredanimal = {
	breeding = {},
--[[
	on_activate = function(self, staticdata, dtime_s)
		nmobs.on_activate(self, staticdata, dtime_s)
	end,
--]]
}

function bredanimal:register_mobs(name, proto, base)
	proto.spawnin = nil
	proto.category = "bredanimal"
	animal:register_mobs(name, proto, base)
end

function bredanimal:remove_on_activate()
	-- Bred animals are not removed
end

animal:register_mobs(MODNAME .. ":bredanimal", bredanimal, animal)

minetest.register_on_generated(function(minp, maxp, seed)
	--print("register_on_generated : " .. minetest.pos_to_string(minp) .. " " .. minetest.pos_to_string(maxp))
	-- one in 100 MapBlocks will have animals
	local chunksize = minetest.setting_get("chunksize")
	--print("Chunksize : " .. chunksize)
	if PseudoRandom(seed):next(1,100) > (chunksize^3) then
		return
	end
	local list_pos = minetest.find_nodes_in_area(minp, maxp, {"default:dirt_with_grass"})
	if #list_pos == 0 then
		return
	end
	local nbessai = math.min(8, #list_pos)
	for i=1,nbessai,1 do
		local pos = list_pos[i]
		pos.y = pos.y + 0.5
		if minetest.env:get_node(pos).name ~= "air" then
			break
		end
		pos.y = pos.y + 1
		if minetest.env:get_node(pos).name ~= "air" then
			break
		end
		pos.y = pos.y - 1
		local mob = minetest.add_entity(pos, MODNAME .. ":nsheep")
	end
end)

