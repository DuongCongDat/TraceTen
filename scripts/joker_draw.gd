class_name JokerDraw
extends Control

const PIXELS := [
	".X...X...X.",
	".X...X...X.",
	".XXXXXXXXX.",
	"XXXXXXXXXXX",
	"..XXXXXXX..",
	"..X.XXX.X..",
	"..XXXXXXX..",
	"..XX...XX..",
	"..XXXXXXX..",
	"...XXXXX...",
]

const INK := Color(0.353, 0.216, 0.071)  # #5a3712

func _draw():
	var cols := PIXELS[0].length()
	var rows := PIXELS.size()
	# Scale pixel grid to fit control, centered
	var cell_w := size.x / float(cols)
	var cell_h := size.y / float(rows)
	var cell   := minf(cell_w, cell_h)
	var ox := (size.x - cell * cols) * 0.5
	var oy := (size.y - cell * rows) * 0.5
	for r in rows:
		for c in cols:
			if PIXELS[r][c] == "X":
				draw_rect(Rect2(ox + c * cell, oy + r * cell, cell, cell), INK)
