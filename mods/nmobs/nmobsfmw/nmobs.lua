nmobs = {
	-- name is defined later with register_mobs
	category = "hostile",
	hp_max = 10,
	physical = true,
	collisionbox = {-0.4, 0, -0.4, 0.4, 1, 0.4},
	peaceful = false,
	player_last_time_seen =0,
	view_range = 16,
	on_activate = function (self, staticdata, dtime_s)
		if dtime_s ~= 0 then
			self.remove_on_activate(self)
		end
	end,
}

function nmobs:on_step(dtime)
	self.check_state(self, dtime)
	self.find_target(self, dtime)
end

function nmobs:check_state(dtime)
	local pos = self.object:getpos()
	local node = minetest.get_node(pos).name
	if node ~= "air" and 
			minetest.get_item_group(node,"water") == 0 and
			minetest.get_item_group(node,"lava") == 0 then
		-- Where am I ? I feel lost
		-- That may happen during the map generation : some mobs may appear
		-- before some node in the same place
		self.object:remove()
	end
	self.check_players_pos(self,dtime, pos)
end

function nmobs:check_players_pos(dtime,pos)
	for _,player in pairs(minetest.get_connected_players()) do
		local p = player:getpos()
		local dist = vector.distance(p, pos)
		if dist > 128 then
			-- Where have you been ? Maybe too far
			self.object:remove()
		elseif dist > 30 then
			if self.player_last_time_seen > 30 then
				if math.random(1, 800) == 1 then
					-- bad luck
					self.object:remove()
				end
			else
				self.player_last_time_seen = self.player_last_time_seen + dtime
			end
		else
			self.player_last_time_seen = 0
		end	
	end
end

function nmobs:find_target(dtime)
	local pos = self.object:getpos()
	local node = minetest.get_node(pos).name
	
	--minetest.find_node_near(pos, self.view_range, node)
end

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
				table.insert(spawner_param["hostile"].surfaces, spawnin)
			end
			table.insert(spawner_param["hostile"].entities[spawnin], proto.name)
			spawner_param["hostile"].entities[spawnin][proto.name] = proto
		end
	end
end

function nmobs:remove_on_activate()
	-- Where have you been ? Maybe too far
	self.object:remove()
end

nmobs:register_mobs(MODNAME .. ":nmobs", nmobs)

function register_mobs(name, proto)
	if proto.inherit then
		proto.inherit:register_mobs(name, proto, proto.inherit)
	else
		print(name .. "must have an inherit record")
	end
end
