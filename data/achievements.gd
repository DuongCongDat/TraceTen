class_name AchievementData

const LIST: Array = [
	# ── BEGINNER ──────────────────────────────────────────────
	{
		"id": "first_ten",
		"name": "Hello, Ten!",
		"desc": "Score for the first time.",
		"target": 1,
	},
	{
		"id": "first_powerup",
		"name": "Helping Hand",
		"desc": "Use a power-up for the first time.",
		"target": 1,
	},
	{
		"id": "all_modes",
		"name": "Explorer",
		"desc": "Play all 5 game modes.",
		"target": 5,
	},
	{
		"id": "first_combo",
		"name": "On a Roll",
		"desc": "Reach x2 combo for the first time.",
		"target": 1,
	},
	{
		"id": "first_special",
		"name": "What's This?",
		"desc": "Reveal a Mystery tile for the first time.",
		"target": 1,
	},

	# ── SCORE ─────────────────────────────────────────────────
	{
		"id": "score_100",
		"name": "Century",
		"desc": "Score 100 points in a single game.",
		"target": 100,
	},
	{
		"id": "score_500",
		"name": "High Roller",
		"desc": "Score 500 points in a single game.",
		"target": 500,
	},
	{
		"id": "score_1000",
		"name": "Four Digits",
		"desc": "Score 1000 points in a single game.",
		"target": 1000,
	},

	# ── COMBO ─────────────────────────────────────────────────
	{
		"id": "combo_5",
		"name": "Pentagram",
		"desc": "Reach x5 combo.",
		"target": 5,
	},
	{
		"id": "combo_10",
		"name": "Unstoppable",
		"desc": "Reach x10 combo.",
		"target": 10,
	},
	{
		"id": "combo_classic",
		"name": "Speed Demon",
		"desc": "Reach x5 combo in Classic mode.",
		"target": 5,
	},

	# ── MODE-SPECIFIC ─────────────────────────────────────────
	{
		"id": "classic_survive",
		"name": "Against the Clock",
		"desc": "Finish Classic with 60 seconds or more remaining.",
		"target": 1,
	},
	{
		"id": "gravity_lv4",
		"name": "Gravitational Pull",
		"desc": "Reach Level 4 in Gravity mode.",
		"target": 1,
	},
	{
		"id": "gravity_3lives",
		"name": "Untouchable",
		"desc": "Reach Level 3 in Gravity without losing a life.",
		"target": 1,
	},
	{
		"id": "zen_refill3",
		"name": "Zen Garden",
		"desc": "Trigger the power-up refill milestone 3 times in Zen.",
		"target": 3,
	},
	{
		"id": "challenge_l6",
		"name": "Cube Master",
		"desc": "Unlock Adventure Level 6 (Coral Reef).",
		"target": 1,
	},
	{
		"id": "challenge_l12",
		"name": "Cosmos",
		"desc": "Unlock Adventure Level 12.",
		"target": 1,
	},
	{
		"id": "mutation_alltype",
		"name": "Collector",
		"desc": "Clear all 4 special tile types in a single Mutation game.",
		"target": 4,
	},

	# ── SPECIAL TILES ─────────────────────────────────────────
	{
		"id": "virus_cleared",
		"name": "Defused",
		"desc": "Clear a Virus tile before it explodes.",
		"target": 1,
	},
	{
		"id": "joker_used",
		"name": "Wild Card",
		"desc": "Use a Joker tile in a valid selection.",
		"target": 1,
	},
	{
		"id": "negative_win",
		"name": "Glass Half Empty",
		"desc": "Use a Negative tile to balance a selection to 10.",
		"target": 1,
	},

	# ── QUIRKY / SECRET ───────────────────────────────────────
	{
		"id": "big_selection",
		"name": "Hoarder",
		"desc": "Select 20 or more tiles in a single move.",
		"target": 1,
	},
	{
		"id": "no_hint",
		"name": "I Don't Need Help",
		"desc": "Finish a Classic game without using Hint.",
		"target": 1,
	},
	{
		"id": "cancel_remove",
		"name": "Never Mind",
		"desc": "Cancel Remove mode by pressing Remove again.",
		"target": 1,
	},
	{
		"id": "virus_explode",
		"name": "Oops",
		"desc": "Let a Virus tile explode for the first time.",
		"target": 1,
	},
]

static func get_def(id: String) -> Dictionary:
	for def in LIST:
		if def["id"] == id:
			return def
	return {}
