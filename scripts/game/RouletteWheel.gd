## RouletteWheel.gd — Draws and animates the roulette wheel.
## All graphics are procedural — no external image assets required.
class_name RouletteWheel
extends Control

# ─── Signals ─────────────────────────────────────────────────────────────────
signal spin_finished(winning_number: int)

# ─── Layout ───────────────────────────────────────────────────────────────────
const SECTOR_COUNT  := 37
const SECTOR_ANGLE  := TAU / SECTOR_COUNT   # radians per sector (~9.73°)

var _radius:       float  = 0.0   # Set in _ready from control size
var _inner_radius: float  = 0.0
var _num_radius:   float  = 0.0
var _ball_radius:  float  = 0.0
var _center:       Vector2 = Vector2.ZERO

# ─── Animation State ──────────────────────────────────────────────────────────
var _wheel_angle:      float = 0.0   # current rotation of the wheel (radians)
var _ball_angle:       float = 0.0   # ball position on the track
var _ball_speed:       float = 0.0   # rad/sec (decreases to 0)
var _ball_visible:     bool  = false
var _is_spinning:      bool  = false
var _spin_tween:       Tween = null
var _result_number:    int   = -1

# Highlight state after landing
var _landed_sector:    int   = -1
var _flash_timer:      float = 0.0
var _flash_visible:    bool  = true

func _ready() -> void:
	_recalculate_layout()
	resized.connect(_recalculate_layout)

func _recalculate_layout() -> void:
	var side   := min(size.x, size.y)
	_radius       = side * 0.46
	_inner_radius = side * 0.10
	_num_radius   = side * 0.36
	_ball_radius  = side * 0.43
	_center       = size * 0.5
	queue_redraw()

func _process(delta: float) -> void:
	if _is_spinning or _ball_visible:
		if _ball_speed != 0.0:
			_ball_angle += _ball_speed * delta
		if _flash_timer > 0.0:
			_flash_timer -= delta
			_flash_visible = fmod(_flash_timer, 0.2) < 0.1
		queue_redraw()

# ─── Public API ───────────────────────────────────────────────────────────────

## Animate a spin that lands on `target_number`.
func spin_to(target_number: int) -> void:
	if _is_spinning:
		return

	_result_number = target_number
	_is_spinning   = true
	_ball_visible  = true
	_landed_sector = -1
	_flash_timer   = 0.0

	var sector_idx := Constants.WHEEL_NUMBERS.find(target_number)

	# Target angle: pointer is at top (−π/2). We want sector_idx to sit there.
	var sector_offset := sector_idx * SECTOR_ANGLE
	var pointer_angle := -PI * 0.5
	var full_spins    := randf_range(5.0, 8.0) * TAU
	var delta_needed  := fposmod(pointer_angle - sector_offset - _wheel_angle, TAU)
	var final_angle   := _wheel_angle + full_spins + delta_needed

	# Wheel spin tween — slow deceleration
	if _spin_tween:
		_spin_tween.kill()
	_spin_tween = create_tween()
	_spin_tween.set_ease(Tween.EASE_OUT)
	_spin_tween.set_trans(Tween.TRANS_CUBIC)
	_spin_tween.tween_property(self, "_wheel_angle", final_angle, 4.5)
	_spin_tween.tween_callback(_on_wheel_stopped)

	# Ball starts fast in opposite direction, decelerates
	_ball_angle = _wheel_angle + randf_range(0.0, TAU)
	_ball_speed = -18.0
	var ball_tween := create_tween()
	ball_tween.set_ease(Tween.EASE_OUT)
	ball_tween.set_trans(Tween.TRANS_EXPO)
	ball_tween.tween_property(self, "_ball_speed", 0.0, 4.2)

func reset() -> void:
	_is_spinning   = false
	_ball_visible  = false
	_ball_speed    = 0.0
	_result_number = -1
	_landed_sector = -1
	_flash_timer   = 0.0
	if _spin_tween:
		_spin_tween.kill()
	queue_redraw()

# ─── Drawing ──────────────────────────────────────────────────────────────────

func _draw() -> void:
	_draw_outer_rim()
	_draw_sectors()
	_draw_inner_hub()
	_draw_pointer()
	if _ball_visible:
		_draw_ball()

func _draw_outer_rim() -> void:
	# Wood/brass outer ring
	draw_circle(_center, _radius + 10.0, Color(0.22, 0.14, 0.06))
	draw_arc(_center, _radius + 6.0, 0.0, TAU, 64, Color(0.55, 0.40, 0.18), 5.0)
	draw_arc(_center, _radius + 2.0, 0.0, TAU, 64, Color(0.35, 0.25, 0.10), 2.0)

func _draw_sectors() -> void:
	for i in SECTOR_COUNT:
		var num := Constants.WHEEL_NUMBERS[i]

		# Determine sector colour
		var sector_color: Color
		match Constants.get_number_color(num):
			"red":   sector_color = Constants.COLOR_RED
			"black": sector_color = Constants.COLOR_BLACK
			_:       sector_color = Constants.COLOR_GREEN

		# Flash highlight when ball has landed on this sector
		if _landed_sector == i and _flash_timer > 0.0 and _flash_visible:
			sector_color = sector_color.lightened(0.5)

		var a_center := _wheel_angle + (i + 0.5) * SECTOR_ANGLE
		var a_start  := _wheel_angle + i * SECTOR_ANGLE - 0.01
		var a_end    := a_start + SECTOR_ANGLE + 0.01

		_draw_arc_sector(_center, _inner_radius, _radius, a_start, a_end, sector_color)

		# Divider line
		var p1 := _center + Vector2(cos(a_start + 0.01), sin(a_start + 0.01)) * _inner_radius
		var p2 := _center + Vector2(cos(a_start + 0.01), sin(a_start + 0.01)) * _radius
		draw_line(p1, p2, Color(0.30, 0.22, 0.10, 0.7), 1.0)

		# Number label
		var text_pos := _center + Vector2(cos(a_center), sin(a_center)) * _num_radius
		_draw_centered_text(str(num), text_pos, 13)

func _draw_inner_hub() -> void:
	draw_circle(_center, _inner_radius, Color(0.18, 0.12, 0.06))
	draw_arc(_center, _inner_radius, 0.0, TAU, 32, Color(0.55, 0.40, 0.18), 2.5)
	# Cross spokes
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var p1 := _center + Vector2(cos(angle), sin(angle)) * (_inner_radius * 0.3)
		var p2 := _center + Vector2(cos(angle), sin(angle)) * (_inner_radius * 0.85)
		draw_line(p1, p2, Color(0.45, 0.33, 0.14), 2.0)
	draw_circle(_center, _inner_radius * 0.3, Color(0.55, 0.40, 0.18))

func _draw_pointer() -> void:
	# Gold triangle pointing down at top of wheel
	var tip  := _center + Vector2(0.0, -(_radius + 14.0))
	var left := tip + Vector2(-7.0,  14.0)
	var rght := tip + Vector2( 7.0,  14.0)
	draw_polygon(PackedVector2Array([tip, left, rght]), PackedColorArray([Constants.COLOR_GOLD]))
	draw_polyline(PackedVector2Array([tip, left, rght, tip]), Color(0.6, 0.5, 0.1), 1.0)

func _draw_ball() -> void:
	var ball_pos := _center + Vector2(cos(_ball_angle), sin(_ball_angle)) * _ball_radius
	# Shadow
	draw_circle(ball_pos + Vector2(2.0, 2.0), 7.0, Color(0.0, 0.0, 0.0, 0.3))
	# Ball body
	draw_circle(ball_pos, 7.0, Color.WHITE)
	# Highlight
	draw_circle(ball_pos + Vector2(-2.0, -2.0), 2.5, Color(1.0, 1.0, 1.0, 0.8))

# ─── Helpers ──────────────────────────────────────────────────────────────────

## Draws a filled arc-sector (donut slice) as a polygon.
func _draw_arc_sector(
	center: Vector2,
	r_inner: float,
	r_outer: float,
	a_start: float,
	a_end:   float,
	color:   Color,
	steps:   int = 8
) -> void:
	var pts := PackedVector2Array()
	for s in range(steps + 1):
		var a := a_start + (a_end - a_start) * s / steps
		pts.append(center + Vector2(cos(a), sin(a)) * r_outer)
	for s in range(steps, -1, -1):
		var a := a_start + (a_end - a_start) * s / steps
		pts.append(center + Vector2(cos(a), sin(a)) * r_inner)
	draw_polygon(pts, PackedColorArray([color]))

func _draw_centered_text(text: String, pos: Vector2, size: int) -> void:
	var font      := ThemeDB.fallback_font
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, text_size.y * 0.25),
				text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.WHITE)

# ─── Callbacks ────────────────────────────────────────────────────────────────

func _on_wheel_stopped() -> void:
	_is_spinning = false
	_ball_speed  = 0.0

	# Snap ball to winning sector center
	var sector_idx := Constants.WHEEL_NUMBERS.find(_result_number)
	_ball_angle    = _wheel_angle + (sector_idx + 0.5) * SECTOR_ANGLE
	_landed_sector = sector_idx
	_flash_timer   = 1.5  # flash for 1.5 seconds

	queue_redraw()
	AudioManager.play_sfx("win" if _result_number != 0 else "big_win")
	spin_finished.emit(_result_number)
