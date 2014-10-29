MODNAME = "nspider"

nspider = {
	inherit = monster,
	textures = {"mobs_spider.png"},
	visual = "mesh",
	mesh = "mobs_spider.x",
	visual_size = {x=7, y=7},
	collisionbox = {-0.75, 0, -0.75, 0.75, 1, 0.75},

	animation = {
		speed_normal = 15,
		speed_run = 15,
		stand_start = 1,
		stand_end = 1,
		move_start = 20,
		move_end = 40,
		run_start = 20,
		run_end = 40,
		punch_start = 50,
		punch_end = 90,
	},
	spawnin = {"default:dirt_with_grass",
		"default:dirt",
		"default:sand",
		"default:desert_sand",
		"default:stone",
		"default:desert_stone",
		"default:cobble",
		"default:mossycobble",
		"default:gravel",
		"default:jungletree"},
	peaceful = true,
}

register_mobs(MODNAME .. ":nspider", nspider)
