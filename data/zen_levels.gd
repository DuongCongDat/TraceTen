class_name ZenLevels

const LEVELS = [
	{
		"id": 1, "name": "Meadow",
		"unlock_score": 0,
		"constraints": {"min_tiles": 3},
		"constraint_text": "Select >= 3 tiles",
	},
	{
		"id": 2, "name": "Forest",
		"unlock_score": 50,
		"constraints": {"min_tiles": 3, "min_bbox_area": 4},
		"constraint_text": "Select >= 3 tiles, area >= 4",
	},
	{
		"id": 3, "name": "Riverside",
		"unlock_score": 150,
		"constraints": {"must_be_square": true, "min_square_size": 2, "min_tiles": 3},
		"constraint_text": "Square region (>= 2x2), >= 3 tiles",
	},
	{
		"id": 4, "name": "Ocean Shore",
		"unlock_score": 300,
		"constraints": {"min_tiles": 4, "min_bbox_area": 6},
		"constraint_text": "Select >= 4 tiles, area >= 6",
	},
	{
		"id": 5, "name": "Deep Sea",
		"unlock_score": 500,
		"constraints": {"min_bbox_size": {"x": 2, "y": 3}, "min_tiles": 4},
		"constraint_text": "Region >= 2x3 (or 3x2), >= 4 tiles",
	},
	{
		"id": 6, "name": "Coral Reef",
		"unlock_score": 750,
		"constraints": {"must_be_square": true, "min_square_size": 3, "min_tiles": 5},
		"constraint_text": "Square region (>= 3x3), >= 5 tiles",
	},
	{
		"id": 7, "name": "Desert",
		"unlock_score": 1000,
		"constraints": {"min_tiles": 5, "min_bbox_area": 8},
		"constraint_text": "Select >= 5 tiles, area >= 8",
	},
	{
		"id": 8, "name": "Canyon",
		"unlock_score": 1300,
		"constraints": {"min_bbox_size": {"x": 3, "y": 3}, "min_tiles": 5},
		"constraint_text": "Region >= 3 wide and 3 tall, >= 5 tiles",
	},
	{
		"id": 9, "name": "Mountain",
		"unlock_score": 1700,
		"constraints": {"min_tiles": 6, "min_bbox_area": 9},
		"constraint_text": "Select >= 6 tiles, area >= 9",
	},
	{
		"id": 10, "name": "Snow Peak",
		"unlock_score": 2200,
		"constraints": {"min_bbox_area": 12, "min_tiles": 6},
		"constraint_text": "Area >= 12, >= 6 tiles",
	},
	{
		"id": 11, "name": "Aurora",
		"unlock_score": 2800,
		"constraints": {"min_tiles": 7, "min_bbox_area": 12},
		"constraint_text": "Select >= 7 tiles, area >= 12",
	},
	{
		"id": 12, "name": "Cosmos",
		"unlock_score": 3500,
		"constraints": {"min_bbox_area": 16, "min_tiles": 8},
		"constraint_text": "Area >= 16, >= 8 tiles",
	},
]
