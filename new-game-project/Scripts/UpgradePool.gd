# UpgradePool.gd (regular script, not a node — just static data + logic)
extends Node

# time_cost = how much MORE negative shot_timer_reduction becomes
# e.g. 0.05 means shots drain 0.05 more time each

static func get_pool() -> Array:
	return [
		{
			"name": "Swift Feet",
			"desc": "+15% move speed",
			"time_cost": 0.05,
			"apply": func(p): p.speed *= 1.15
		},
		{
			"name": "Quick Trigger",
			"desc": "-20% shot cooldown",
			"time_cost": 0.08,
			"apply": func(p): p.shot_cooldown *= 0.8  # see note below
		},
		{
			"name": "Reach",
			"desc": "+25% melee range",
			"time_cost": 0.05,
			"apply": func(p): p.melee_range *= 1.25
		},
		{
			"name": "Steel Nerves",
			"desc": "+0.3s invincibility on hit",
			"time_cost": 0.1,
			"apply": func(p): p.iframe_duration += 0.3
		},
		{
			"name": "Heavy Rounds",
			"desc": "+10 bullet damage",
			"time_cost": 0.1,
			"apply": func(p): p.bullet_damage += 10
		},
	]
