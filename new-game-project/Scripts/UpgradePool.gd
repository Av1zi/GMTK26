# UpgradePool.gd (regular script, not a node — just static data + logic)
extends Node

# time_cost = how much MORE negative shot_timer_reduction becomes
# e.g. 0.05 means shots drain 0.05 more time each

static func get_pool() -> Array:
	return [
		{
			"name": "Wheeeeeeeee",
			"desc": "+20% move speed",
			"time_cost": 0.05,
			"apply": func(p): p.speed *= 1.15
		},
		{
			"name": "So Anyway I Started Blasting",
			"desc": "-15% shot cooldown",
			"time_cost": 0.08,
			"apply": func(p): p.shot_cooldown *= 0.85  # see note below
		},
		{
			"name": "long stick",
			"desc": "+50% melee range",
			"time_cost": 0.05,
			"apply": func(p): p.melee_range *= 1.50
		},
		{
			"name": "Light Work No Reaction",
			"desc": "+0.3s invincibility on hit",
			"time_cost": 0.03,
			"apply": func(p): p.iframe_duration += 0.3
		},
		{
			"name": "Big Boy Bullets",
			"desc": "+10 bullet damage",
			"time_cost": 0.1,
			"apply": func(p): p.bullet_damage += 10
		},
				{
			"name": "Smort",
			"desc": "+20% xp gain",
			"time_cost": 0.05,
			"apply": func(p): p.xp_gain_mult *= 1.2
		},
		{
			"name": "Chip Chop",
			"desc": "+25% slash damage",
			"time_cost": 0.065,
			"apply": func(p): p.slash_dmg *= 1.25
		},
		{
			"name": "Shlik Shlak",
			"desc": "-20% slash cooldown",
			"time_cost": 0.075,
			"apply": func(p): p.melee_cooldown *= 0.8
		},
	]
