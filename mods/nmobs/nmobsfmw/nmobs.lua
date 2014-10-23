nmobs = {
	-- name is defined later with register_mobs
	category = "hostile",
	hp_max = 10,
	physical = true,
	collisionbox = {-0.4, 0, -0.4, 0.4, 1, 0.4},
	automatic_face_movement_dir = -90.0,

	move_velocity = 1,
	peaceful = false,
	player_last_time_seen =0,
	view_range = 16,
	target = nil,
	on_activate = function (self, staticdata, dtime_s)
		if dtime_s ~= 0 then
			self.remove_on_activate(self)
		end
	end,
}

function nmobs:on_step(dtime)
	self.check_state(self, dtime)
	self.find_target(self, dtime)
	self.goto_target(self, dtime)
	self.target_reach(self, dtime)
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
	if node == "air" then
		self.object:setacceleration({ x=0, y=-10, z=0})
	else
		-- all mobs can swim in water or in lava
		self.object:setacceleration({ x=0, y=0, z=0})
	end
		
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
	self.find_random_target(self, dtime)
end

function nmobs:find_random_target(dtime)
	if self.target == nil then
		local pos = self.object:getpos()
		local minp = vector.subtract(vector.new(pos), self.view_range)
		local maxp = vector.add(vector.new(pos), self.view_range)
		local l_air = minetest.find_nodes_in_area(minp, maxp, {"air"})
		if #l_air == 0 then
			print("Something is wrong")
			return
		end
		local i = math.random(1, #l_air)
		local node = l_air[i]
		local under = vector.new(node)
		under.y = under.y - 1		
		local undername = minetest.get_node(under).name
		if undername ~= "air" and 
				minetest.get_item_group(undername,"water") == 0 and
				minetest.get_item_group(undername,"lava") == 0 then
			local upper = vector.new(node)
			upper.y = upper.y + 1
			if minetest.get_node(upper).name == "air" then
				self.target = node
				self.target.y = self.target.y - 0.5
				self.state = move
			end
		end
	end
end

function nmobs:goto_target(dtime)
	if self.target then
		local object = self.object
		local pos = object:getpos()
		local direction = vector.subtract(self.target, pos)
		direction.y = 0
		direction = vector.normalize(direction)
		local nextnode = vector.add(pos, direction)
		local node = minetest.get_node(nextnode).name
		direction = vector.multiply(direction, self.move_velocity)
		-- We can jump only if we are not falling or not jumping
		if math.abs(object:getvelocity().y) == 0 then
			if node ~= "air" and 
					minetest.get_item_group(node,"water") == 0 and
					minetest.get_item_group(node,"lava") == 0 then
				-- we need to jump
				direction.y = 7
			end
		end
		-- replaced by automatic_face_movement_dir = -90.0
		--local yaw = math.atan(direction.z/direction.x)+math.pi/2
		--object:setyaw(yaw)
		object:setvelocity(direction)
		object:set_animation(
			{x=self.animation.move_start,
			y=self.animation.move_end},
			self.animation.speed_normal, 0)
	end
end

function nmobs:target_reach(dtime)
	if self.target then
		if vector.distance(self.object:getpos(), self.target) <  1 then
			self.target = nil
			self.state = stand
		end
	end	
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
