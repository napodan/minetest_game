nmobs = {
	-- name is defined later with register_mobs
	category = "hostile",
	hp_max = 10,
	physical = true,
	collisionbox = {-0.4, 0, -0.4, 0.4, 1, 0.4},
	peaceful = false,
	on_activate = function (self, staticdata, dtime_s)
		if dtime_s ~= 0 then
			self.remove_on_activate(self)
		end
	end,
	on_step = function (self, dtime)
		local pos = self.object:getpos()
		local node = minetest.get_node(pos).name
		if node ~= "air" and 
				minetest.get_item_group(node,"water") == 0 and
				minetest.get_item_group(node,"lava") == 0 then
			-- Where am I ? I feel lost
			self.object:remove()
		end
	end,
	
}

function nmobs:register_mobs(name, proto, base)
	if name == nil then
		return
	end
	proto.name = name
	if base ~= nil then
		proto.__index = base
		setmetatable(proto, base)
	end
	minetest.register_entity(name, proto)
	if proto.spawnin ~= nil then
		for _,spawnin in pairs(proto.spawnin) do
			if spawner_param["hostile"].entities[spawnin] == nil then
				print("new spawner " .. spawnin)
				spawner_param["hostile"].entities[spawnin] = {}
				table.insert(spawner_param["hostile"].nodenames, spawnin)
			end
			table.insert(spawner_param["hostile"].entities[spawnin], proto.name)
		end
	end
end

function nmobs:remove_on_activate()
	-- Where have you been ? Maybe to far
	self.object:remove()
end

nmobs:register_mobs(MODNAME .. ":nmobs", nmobs)

