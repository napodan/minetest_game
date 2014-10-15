mobs:register_mob("mobs:dog", {
	type = "pet",
	hp_max = 5,
	owner = "",
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1, 0.4},
	textures = {"mobs_dog.png"},
	visual = "mesh",
	mesh = "mobs_dog.x",
	makes_footstep_sound = true,
	view_range = 1000,
	walk_velocity = 4,
	run_velocity = 4,
	damage = 2,
	armor = 200,
	attack_type = "dogfight",
	drops = {
		{name = "mobs:meat_raw",
		chance = 1,
		min = 2,
		max = 3,},
	},
	drawtype = "front",
	water_damage = 0,
	lava_damage = 5,
	light_damage = 0,
	on_rightclick = function(self, clicker)
		tool = clicker:get_wielded_item()
		minetest.add_entity(self.object:getpos(), "mobs:wardog")
		self.object:remove()
	end,
	animation = {
		speed_normal = 20,
		speed_run = 30,
		stand_start = 10,
		stand_end = 20,
		walk_start = 75,
		walk_end = 100,
		run_start = 100,
		run_end = 130,
		punch_start = 135,
		punch_end = 155,
	},
	jump = true,
	step = 1,
	blood_texture = "mobs_blood.png",
})
 
