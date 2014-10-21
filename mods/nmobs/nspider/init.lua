MODNAME = "nspider"

nspider = {
	textures = {"mobs_spider.png"},
	visual = "mesh",
	mesh = "mobs_spider.x",
	visual_size = {x=7, y=7},
	spawnin = {"default:dirt_with_grass","default:sand","default:desert_sand", "default:stone"},
}

monster:register_mobs(MODNAME .. ":nspider", nspider, monster)
