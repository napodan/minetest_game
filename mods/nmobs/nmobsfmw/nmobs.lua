nmobs = {
	-- name is defined later with register_mobs
	category = "hostile",
	hp_max = 10,
	physical = true,
	collisionbox = {-0.4, 0, -0.4, 0.4, 1, 0.4},
	automatic_face_movement_dir = -90.0,
	stepheight = 1.1,

	move_velocity = 1,
	move_timer = 1,
	inblocktimer = 0,
	maxdrop = 4,
	peaceful = false,
	player_last_time_seen =0,
	view_range = 16,
	target = nil,
	on_activate = function (self, staticdata, dtime_s)
		if dtime_s ~= 0 then
			self.remove_on_activate(self)
		end
		self.move_timer = 1
		self.state = stand
		self.object:set_animation({
			x = self.animation.stand_start,
			y = self.animation.stand_end},
			self.animation.speed_normal,
			0)
	end,
}

function nmobs:on_step(dtime)
	self.check_state(self, dtime)
	if self.sounds and self.sounds.random and math.random(1, 100) <= 1 then
		minetest.sound_play(self.sounds.random, {object = self.object})
	end
	if self.move_timer < 0 then
		self.find_target(self, dtime)
		self.goto_target(self, dtime)
		self.target_reach(self, dtime)
		self.move_timer = 1
	else
		self.move_timer = self.move_timer - dtime
	end
end

function nmobs:check_state(dtime)
	local pos = self.object:getpos()
	--print(minetest.pos_to_string(pos))
	-- Be careful
	-- entity at y = 1.5 belong to the node at y = 2
	-- entity at y = -1.5 belong to the node at y = -1 but get_node give us
	-- the node at y = -2
	-- every time we need to get a node from an entity we need to add 0.5 to
	-- get the node where the entity is or substract 0.5 to get the node
	-- under the entity
	local nodepos = vector.new(pos)
	nodepos.y = nodepos.y + 0.5
	local node = minetest.get_node(nodepos).name
	local nodedef = minetest.registered_nodes[node]
	if node ~= "air" and 
			( nodedef.walkable == nil or
				nodedef.walkable ) then
		-- Where am I ? I feel lost
		-- That may happen during the map generation : some mobs may appear
		-- before some node in the same place
		-- But sometimes, it's happening during movement so we will use a timer
		if self.inblocktimer > 1 then 
			--print("mob removed : " .. minetest.pos_to_string(pos))
			self.object:remove()
		else
			--print("mob will be removed : " .. minetest.pos_to_string(pos))
			--print("Node : " .. node)
			self.inblocktimer = self.inblocktimer + dtime
		end
	else
		self.inblocktimer = 0
	end
	self.check_players_pos(self,dtime, pos)
	if minetest.get_item_group(node, "water") == 0 and
		minetest.get_item_group(node, "lava") == 0 then
		self.object:setacceleration({ x=0, y=-10, z=0})
	else
		-- all mobs can swim in water or in lava
		self.object:setacceleration({ x=0, y=0, z=0})
	end
	-- We check if target is unreachable
	if self.target then
		if self.target ~= self.savetarget then
			self.savetarget = self.target
			self.targettimer = 20
		else
			if self.targettimer < 0 then
				--print("Target unreachable")
				-- target unreachable
				self.target = nil
				self.object:setvelocity({x = 0, y = 0, z = 0})
				self.state = stand
				self.object:set_animation(
					{x=self.animation.stand_start,
					y=self.animation.stand_end},
					self.animation.speed_normal, 0)
			else
				self.targettimer = self.targettimer - dtime
			end
		end
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
	self.find_player(self, dtime)
	self.find_random_target(self, dtime)
end

function nmobs:find_player(dtime)
	if not self.peaceful then
		local pos = self.object:getpos()
		for _,player in pairs(minetest.get_connected_players()) do
			local p = player:getpos()
			local dist = vector.distance(p, pos)
			if dist > 1 and dist <= self.view_range then
				self.target = p
				-- TODO select a random player if there are more than one
				break
			end
		end
	end
end
	
function nmobs:find_random_target(dtime)
	if self.target == nil then
		local pos = self.object:getpos()
		local nodepos = vector.new(pos)
		nodepos.y = nodepos.y + 0.5
		local minp = vector.subtract(vector.new(nodepos), self.view_range / 4)
		local maxp = vector.add(vector.new(nodepos), self.view_range / 4)
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
		local underdef = minetest.registered_nodes[undername]
		if undername ~= "air" and 
				( underdef.walkable == nil or
				underdef.walkable ) then
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
		local path = minetest.find_path(
			pos,
			self.target,
			self.view_range,
			self.stepheight,
			self.maxdrop,
			nil)
		if path ~= nil and #path >= 2 then
			local direction = vector.subtract(path[2], pos)
			direction.y = 0
			direction = vector.normalize(direction)
			direction = vector.multiply(direction, self.move_velocity)
			
			object:setvelocity(direction)
			object:set_animation(
				{x=self.animation.move_start,
				y=self.animation.move_end},
				self.animation.speed_normal, 0)
		else
			--print("Path not found between " .. minetest.pos_to_string(pos) .. " and " .. minetest.pos_to_string(self.target) )
			if vector.length(object:getvelocity()) == 0 then
				local direction = vector.subtract(self.target, pos)
				direction.y = 0
				direction = vector.normalize(direction)
				direction = vector.multiply(direction, self.move_velocity)
			
				object:setvelocity(direction)
				object:set_animation(
					{x=self.animation.move_start,
					y=self.animation.move_end},
					self.animation.speed_normal, 0)
			end
			--else we keep the same direction

		end
	end
end

function nmobs:target_reach(dtime)
	if self.target then
		local pos = self.object:getpos()
		--print("Target : " .. minetest.pos_to_string(self.target))
		if math.abs(pos.x - self.target.x) < 1 and  math.abs(pos.y - self.target.y) < 1.5 and math.abs(pos.z - self.target.z) < 1 then
			self.object:setvelocity({x = 0, y = 0, z = 0})
			self.state = stand
			self.object:set_animation(
				{x=self.animation.stand_start,
				y=self.animation.stand_end},
				self.animation.speed_normal, 0)
			self.target = nil
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

