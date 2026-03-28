## BettingTable.gd — Touch-friendly roulette betting grid.
## Draws the European roulette layout as a procedural Control node.
## Portrait layout: 0 row → 12×3 number grid → outside bets.
class_name BettingTable
extends Control

# ─── Signals ─────────────────────────────────────────────────────────────────
signal bet_placed(bet_type: int, bet_data: Dictionary, amount: int)
signal bet_removed(bet_type: int, bet_data: Dictionary)

# ─── Layout constants ─────────────────────────────────────────────────────────
# The standard roulette table (portrait-adapted):
#   Column A (left)  = numbers ≡ 1 mod 3: 1,4,7,…,34
#   Column B (mid)   = numbers ≡ 2 mod 3: 2,5,8,…,35
#   Column C (right) = numbers ≡ 0 mod 3: 3,6,9,…,36
# Rows go top-to-bottom, 1–12 in row 1 … 34–36 in row 12.

const COLS   := 3
const ROWS   := 12   # 36 numbers / 3 columns

var _cell_w: float = 0.0
var _cell_h: float = 0.0
var _pad:    float = 4.0
var _zero_h: float = 0.0
var _out_h:  float = 0.0
var _col_h:  float = 0.0   # column-bets row height

# Hit regions: Array of { rect: Rect2, bet_type, bet_data }
var _hit_regions: Array[Dictionary] = []

# Active bets: key = "type_data" → { type, data, amount }
var _active_bets: Dictionary = {}

# Which chip is selected (mirrors Game.gd selection)
var selected_chip: int = 5

# Disabled bet types (from boss rules)
var disabled_bet_types: Array[int] = []

func _ready() -> void:
	resized.connect(_on_resized)
	_recalculate_layout()

func _on_resized() -> void:
	_recalculate_layout()

func _recalculate_layout() -> void:
	_cell_w = (size.x - _pad * (COLS + 1)) / (COLS + 0.5)  # +0.5 for outside col
	_cell_h = 0.0
	_zero_h = 60.0
	_out_h  = 60.0
	_col_h  = 60.0

	# Fill available height
	var remaining := size.y - _zero_h - _out_h - _col_h - _pad * (ROWS + 4)
	_cell_h = max(40.0, remaining / ROWS)

	_rebuild_hit_regions()
	queue_redraw()

# ─── Public API ───────────────────────────────────────────────────────────────

func refresh_bets(bets: Array[Dictionary]) -> void:
	_active_bets.clear()
	for bet in bets:
		var key := _bet_key(bet.type, bet.data)
		_active_bets[key] = bet.duplicate(true)
	queue_redraw()

func clear_display() -> void:
	_active_bets.clear()
	queue_redraw()

# ─── Input ────────────────────────────────────────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventMouseButton):
		return

	var pressed := false
	var pos     := Vector2.ZERO

	if event is InputEventScreenTouch:
		pressed = event.pressed
		pos     = event.position
	elif event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		pos     = event.position

	if not pressed:
		return

	for region in _hit_regions:
		if region.rect.has_point(pos):
			var btype: int = region.bet_type
			if btype in disabled_bet_types:
				return
			var bdata: Dictionary = region.bet_data
			AudioManager.play_sfx("chip_place")
			bet_placed.emit(btype, bdata, selected_chip)
			return

# ─── Layout Builder ───────────────────────────────────────────────────────────

func _rebuild_hit_regions() -> void:
	_hit_regions.clear()

	var y := _pad

	# ── Zero ──
	var zero_rect := Rect2(_pad, y, size.x - _pad * 2.0, _zero_h)
	_hit_regions.append({ "rect": zero_rect, "bet_type": Constants.BetType.STRAIGHT, "bet_data": { "number": 0 } })
	y += _zero_h + _pad

	# ── Number grid (ROWS × COLS) ──
	for row in ROWS:            # row 0 = numbers 1-3, row 11 = numbers 34-36
		for col in COLS:        # col 0 = ≡1, col 1 = ≡2, col 2 = ≡3
			var num   := row * 3 + col + 1
			var rect  := Rect2(_pad + col * (_cell_w + _pad), y, _cell_w, _cell_h)
			_hit_regions.append({ "rect": rect, "bet_type": Constants.BetType.STRAIGHT, "bet_data": { "number": num } })
		y += _cell_h + _pad

	# ── Dozen bets (3 side-by-side) ──
	var third := (size.x - _pad * 4.0) / 3.0
	var dozens := [Constants.BetType.DOZEN_1, Constants.BetType.DOZEN_2, Constants.BetType.DOZEN_3]
	for i in 3:
		var rect := Rect2(_pad + i * (third + _pad), y, third, _out_h)
		_hit_regions.append({ "rect": rect, "bet_type": dozens[i], "bet_data": {} })
	y += _out_h + _pad

	# ── Column bets (3 side-by-side) ──
	var cols := [Constants.BetType.COLUMN_1, Constants.BetType.COLUMN_2, Constants.BetType.COLUMN_3]
	for i in 3:
		var rect := Rect2(_pad + i * (third + _pad), y, third, _col_h)
		_hit_regions.append({ "rect": rect, "bet_type": cols[i], "bet_data": {} })
	y += _col_h + _pad

	# ── Even-chance bets (6 side-by-side) ──
	var sixth := (size.x - _pad * 7.0) / 6.0
	var evens := [
		Constants.BetType.LOW,
		Constants.BetType.EVEN,
		Constants.BetType.RED,
		Constants.BetType.BLACK,
		Constants.BetType.ODD,
		Constants.BetType.HIGH,
	]
	for i in 6:
		var rect := Rect2(_pad + i * (sixth + _pad), y, sixth, _out_h)
		_hit_regions.append({ "rect": rect, "bet_type": evens[i], "bet_data": {} })

# ─── Drawing ──────────────────────────────────────────────────────────────────

func _draw() -> void:
	# Background felt
	draw_rect(Rect2(Vector2.ZERO, size), Constants.COLOR_FELT)

	var y := _pad

	# ── Zero ──
	var zero_rect := Rect2(_pad, y, size.x - _pad * 2.0, _zero_h)
	_draw_cell(zero_rect, "0", Constants.COLOR_GREEN, Constants.BetType.STRAIGHT, { "number": 0 })
	y += _zero_h + _pad

	# ── Number grid ──
	for row in ROWS:
		for col in COLS:
			var num    := row * 3 + col + 1
			var rect   := Rect2(_pad + col * (_cell_w + _pad), y, _cell_w, _cell_h)
			var ncolor: Color
			match Constants.get_number_color(num):
				"red":   ncolor = Constants.COLOR_RED
				"black": ncolor = Constants.COLOR_BLACK
				_:       ncolor = Constants.COLOR_GREEN
			_draw_cell(rect, str(num), ncolor, Constants.BetType.STRAIGHT, { "number": num })
		y += _cell_h + _pad

	# ── Dozen bets ──
	var third := (size.x - _pad * 4.0) / 3.0
	var dozen_labels := ["1st 12", "2nd 12", "3rd 12"]
	var dozens := [Constants.BetType.DOZEN_1, Constants.BetType.DOZEN_2, Constants.BetType.DOZEN_3]
	for i in 3:
		var rect := Rect2(_pad + i * (third + _pad), y, third, _out_h)
		_draw_cell(rect, dozen_labels[i], Constants.COLOR_FELT_DARK, dozens[i], {})
	y += _out_h + _pad

	# ── Column bets ──
	var col_labels := ["Col 1", "Col 2", "Col 3"]
	var cols := [Constants.BetType.COLUMN_1, Constants.BetType.COLUMN_2, Constants.BetType.COLUMN_3]
	for i in 3:
		var rect := Rect2(_pad + i * (third + _pad), y, third, _col_h)
		_draw_cell(rect, col_labels[i], Constants.COLOR_FELT_DARK, cols[i], {})
	y += _col_h + _pad

	# ── Even-chance bets ──
	var sixth := (size.x - _pad * 7.0) / 6.0
	var even_labels := ["1–18", "EVEN", "RED", "BLK", "ODD", "19–36"]
	var even_colors := [
		Constants.COLOR_FELT_DARK, Constants.COLOR_FELT_DARK,
		Constants.COLOR_RED,       Constants.COLOR_BLACK,
		Constants.COLOR_FELT_DARK, Constants.COLOR_FELT_DARK,
	]
	var evens := [
		Constants.BetType.LOW,   Constants.BetType.EVEN,
		Constants.BetType.RED,   Constants.BetType.BLACK,
		Constants.BetType.ODD,   Constants.BetType.HIGH,
	]
	for i in 6:
		var rect := Rect2(_pad + i * (sixth + _pad), y, sixth, _out_h)
		_draw_cell(rect, even_labels[i], even_colors[i], evens[i], {})

func _draw_cell(
	rect:     Rect2,
	label:    String,
	bg_color: Color,
	bet_type: int,
	bet_data: Dictionary
) -> void:
	var key      := _bet_key(bet_type, bet_data)
	var has_bet  := _active_bets.has(key)
	var disabled := bet_type in disabled_bet_types

	# Background
	var fill := bg_color
	if disabled:
		fill = fill.darkened(0.5)
	draw_rect(rect, fill, true, -1)

	# Highlight border when hovered / has bet
	if has_bet:
		draw_rect(rect, Constants.COLOR_GOLD, false, 2.0)
	else:
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.4), false, 1.0)

	# Label
	var font := ThemeDB.fallback_font
	var fsize := 20
	var tsize := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var tpos  := rect.get_center() - tsize * 0.5 + Vector2(0, tsize.y * 0.3)
	draw_string(font, tpos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize,
				Color(1.0, 1.0, 1.0, 0.9 if not disabled else 0.3))

	# Chip stack indicator
	if has_bet:
		var bet: Dictionary = _active_bets[key]
		var amount : int = bet.get("amount", 0)
		var chip_col := Constants.get_chip_color(selected_chip)
		var chip_pos := rect.get_center()
		draw_circle(chip_pos, 16.0, chip_col)
		draw_arc(chip_pos, 16.0, 0.0, TAU, 16, Color(0.0,0.0,0.0,0.4), 1.5)
		var amt_str  := str(amount)
		var asize    := font.get_string_size(amt_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
		draw_string(font, chip_pos - asize * 0.5 + Vector2(0, asize.y * 0.3),
					amt_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.BLACK)

# ─── Helpers ──────────────────────────────────────────────────────────────────

func _bet_key(bet_type: int, bet_data: Dictionary) -> String:
	if bet_type == Constants.BetType.STRAIGHT:
		return "straight_%d" % bet_data.get("number", -1)
	return str(bet_type)
