## ModIcon.gd — Small procedurally drawn icon for a mod card in the shop.
## Category determines the visual: wheel, bet, score, insurance, utility.
class_name ModIcon
extends Control

var category: String = "utility"
var icon_color: Color = Constants.COLOR_GOLD
var _t: float = 0.0

const SIZE := 48.0

func _ready() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var c  := Vector2(SIZE * 0.5, SIZE * 0.5)
	var col := icon_color

	# Backdrop circle
	draw_circle(c, SIZE * 0.46, Color(col.r, col.g, col.b, 0.12))
	draw_arc(c, SIZE * 0.44, 0.0, TAU, 32, Color(col.r, col.g, col.b, 0.35), 1.5)

	match category:
		"wheel":
			_draw_wheel_icon(c, col)
		"bet":
			_draw_chip_icon(c, col)
		"score":
			_draw_score_icon(c, col)
		"insurance":
			_draw_shield_icon(c, col)
		"utility":
			_draw_star_icon(c, col)
		_:
			_draw_star_icon(c, col)

# ─── Icon drawings ────────────────────────────────────────────────────────────

func _draw_wheel_icon(c: Vector2, col: Color) -> void:
	# Spinning roulette wheel silhouette
	var r1 := SIZE * 0.34
	var r2 := SIZE * 0.14
	var rot := _t * 1.5  # slow spin
	draw_arc(c, r1, 0.0, TAU, 32, col, 2.0)
	for i in 8:
		var a := rot + TAU * i / 8.0
		var p1 := c + Vector2(cos(a), sin(a)) * r2
		var p2 := c + Vector2(cos(a), sin(a)) * r1
		draw_line(p1, p2, col, 1.5)
	draw_circle(c, r2, col)
	draw_circle(c, r2 * 0.5, Color(0.05, 0.05, 0.05))
	# Ball dot
	var ball_a := rot * -1.3
	var ball_p := c + Vector2(cos(ball_a), sin(ball_a)) * (r1 + 3.0)
	draw_circle(ball_p, 3.0, Color.WHITE)

func _draw_chip_icon(c: Vector2, col: Color) -> void:
	# Poker chip with stripes
	var r := SIZE * 0.34
	draw_circle(c, r, col.darkened(0.2))
	draw_arc(c, r, 0.0, TAU, 32, col.lightened(0.2), 2.5)
	# Inner ring
	draw_arc(c, r * 0.68, 0.0, TAU, 24, col, 1.5)
	# 4 stripe segments around edge
	for i in 4:
		var a0 := TAU * i / 4.0 + 0.15
		var a1 := a0 + TAU / 4.0 - 0.30
		draw_arc(c, r, a0, a1, 8, col.lightened(0.4), 4.5)
	# Centre dot
	draw_circle(c, 4.0, col.lightened(0.3))

func _draw_score_icon(c: Vector2, col: Color) -> void:
	# Upward arrow with trailing score marks
	var arrow_top  := c + Vector2(0, -SIZE * 0.30)
	var arrow_base := c + Vector2(0,  SIZE * 0.20)
	draw_line(arrow_base, arrow_top, col, 3.0)
	# Arrowhead
	var ah_pts := PackedVector2Array([
		arrow_top + Vector2(-7, 8),
		arrow_top,
		arrow_top + Vector2( 7, 8),
	])
	var ah_col := PackedColorArray([col, col, col])
	draw_polygon(ah_pts, ah_col)
	# Trailing tick marks
	for i in 3:
		var y := arrow_base.y - 6.0 - i * 8.0
		var alpha := 0.3 + i * 0.2
		draw_line(c + Vector2(-8, y - c.y), c + Vector2(8, y - c.y),
				  Color(col.r, col.g, col.b, alpha), 2.0)

func _draw_shield_icon(c: Vector2, col: Color) -> void:
	# Shield silhouette
	var s  := SIZE * 0.36
	var pts := PackedVector2Array([
		c + Vector2(0, -s),
		c + Vector2(-s * 0.75, -s * 0.5),
		c + Vector2(-s * 0.75,  s * 0.1),
		c + Vector2(0,           s),
		c + Vector2( s * 0.75,  s * 0.1),
		c + Vector2( s * 0.75, -s * 0.5),
	])
	var fill_col := PackedColorArray()
	for _i in pts.size():
		fill_col.append(col.darkened(0.25))
	draw_polygon(pts, fill_col)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[4], pts[5], pts[0]]),
				  col.lightened(0.1), 2.0)
	# Centre cross / heart
	draw_line(c + Vector2(0, -s * 0.3), c + Vector2(0, s * 0.2), col.lightened(0.4), 2.5)
	draw_line(c + Vector2(-s * 0.25, 0), c + Vector2(s * 0.25, 0), col.lightened(0.4), 2.5)

func _draw_star_icon(c: Vector2, col: Color) -> void:
	# 5-pointed star
	var outer := SIZE * 0.34
	var inner := SIZE * 0.15
	var rot   := -PI * 0.5
	var pts   := PackedVector2Array()
	for i in 10:
		var a := rot + TAU * i / 10.0
		var r := outer if i % 2 == 0 else inner
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	var colors := PackedColorArray()
	for _i in pts.size():
		colors.append(col)
	draw_polygon(pts, colors)
	draw_polyline(PackedVector2Array(Array(pts) + [pts[0]]), col.lightened(0.2), 1.5)
