MODNAME = "nspider"

nspider = {
	inherit = monster,
	textures = {"mobs_spider.png"},
	visual = "mesh",
	mesh = "mobs_spider.x",
	visual_size = {x=7, y=7},
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
}

register_mobs(MODNAME .. ":nspider", nspider)
