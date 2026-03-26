## WinPopup.gd — Animated overlay shown after each spin result.
## Scales in, briefly holds, then floats upward and fades out.
## Called by Game.gd; replaces the plain result panel.
class_name WinPopup
extends Control

signal dismissed

# ─── Config ───────────────────────────────────────────────────────────────────
const HOLD_TIME   := 1.8
const RISE_PIXELS := 80.0

var _number:    int  = 0
var _winnings:  int  = 0
var _score_gain: int = 0
var _is_win:    bool = false

# Child nodes
var _panel:       Panel
var _num_label:   Label
var _chips_label: Label
var _score_label: Label
var _mult_label:  Label   # shown for big wins / mod triggers

func _ready() -> void:
	_build()

func _build() -> void:
	modulate.a = 0.0

	# Outer glow panel
	_panel = Panel.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(360, 110)
	_panel.position            = Vector2(-180, -55)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.04, 0.90)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		style.set("corner_radius_" + c, 14)
	for s in ["left","right","top","bottom"]:
		style.set("border_width_" + s, 2)
	style.border_color = Constants.COLOR_GOLD
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	# Inner VBox
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(vbox)

	_num_label = _make_label("", 34, true)
	_num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_num_label)

	_chips_label = _make_label("", 20)
	_chips_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_chips_label)

	_score_label = _make_label("", 15)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_color_override("font_color", Color(0.75, 0.72, 0.62))
	vbox.add_child(_score_label)

	# Multiplier pop (hidden by default, shown for big wins)
	_mult_label = _make_label("", 18, true)
	_mult_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mult_label.add_theme_color_override("font_color", Constants.COLOR_HIGHLIGHT)
	_mult_label.visible = false
	vbox.add_child(_mult_label)

# ─── Public API ───────────────────────────────────────────────────────────────

func show_result(number: int, winnings: int, score_gain: int) -> void:
	_number     = number
	_winnings   = winnings
	_score_gain = score_gain
	_is_win     = winnings > 0

	_populate_labels()
	_style_for_result()
	_animate_in()

func show_mod_bonus(description: String) -> void:
	_mult_label.text    = description
	_mult_label.visible = true
	var t := create_tween()
	t.tween_interval(0.5)
	t.tween_property(_mult_label, "modulate:a", 0.0, 0.6)
	t.tween_callback(func(): _mult_label.visible = false; _mult_label.modulate.a = 1.0)

# ─── Internals ────────────────────────────────────────────────────────────────

func _populate_labels() -> void:
	var col_name := Constants.get_number_color(_number).to_upper()
	_num_label.text = "%s  %d" % [col_name, _number]

	if _is_win:
		_chips_label.text = "+%d chips" % _winnings
		_score_label.text = "+%d toward target" % _score_gain
	else:
		_chips_label.text = "No win"
		_score_label.text = "+%d toward target" % _score_gain if _score_gain > 0 else ""

func _style_for_result() -> void:
	var style := _panel.get_theme_stylebox("panel") as StyleBoxFlat
	if not style:
		return

	var num_color: Color
	match Constants.get_number_color(_number):
		"red":   num_color = Constants.COLOR_RED.lightened(0.15)
		"black": num_color = Color(0.85, 0.82, 0.78)
		_:       num_color = Constants.COLOR_GREEN.lightened(0.2)

	_num_label.add_theme_color_override("font_color", num_color)

	if _is_win:
		if _winnings >= 300:
			style.border_color = Constants.COLOR_GOLD
			_chips_label.add_theme_color_override("font_color", Constants.COLOR_GOLD)
			_chips_label.add_theme_font_size_override("font_size", 26)
		else:
			style.border_color = Color(0.5, 0.7, 0.5, 0.9)
			_chips_label.add_theme_color_override("font_color", Color(0.65, 0.92, 0.65))
			_chips_label.add_theme_font_size_override("font_size", 20)
	else:
		style.border_color = Color(0.45, 0.35, 0.35, 0.8)
		_chips_label.add_theme_color_override("font_color", Color(0.70, 0.55, 0.55))
		_chips_label.add_theme_font_size_override("font_size", 20)

func _animate_in() -> void:
	visible = true
	modulate.a = 0.0
	_panel.scale = Vector2(0.7, 0.7)
	_panel.pivot_offset = _panel.custom_minimum_size * 0.5

	# Scale + fade in
	var t_in := create_tween()
	t_in.set_parallel(true)
	t_in.tween_property(self, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_in.tween_property(_panel, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t_in.chain().tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.08)
	t_in.chain().tween_interval(HOLD_TIME)
	t_in.chain().tween_callback(_animate_out)

	# Particle burst for big wins
	if _winnings >= 200:
		_spawn_particles()

func _animate_out() -> void:
	var start_y := position.y
	var t_out := create_tween()
	t_out.set_parallel(true)
	t_out.tween_property(self, "position:y", start_y - RISE_PIXELS, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t_out.tween_property(self, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t_out.chain().tween_callback(func():
		visible = false
		position.y = start_y
		modulate.a = 1.0
		dismissed.emit()
	)

func _spawn_particles() -> void:
	# Spawn simple rising dots as a win celebration
	var color := Constants.COLOR_GOLD if _winnings >= 500 else Color(0.65, 0.90, 0.65)
	for i in 12:
		var dot := ColorRect.new()
		dot.color = color
		dot.size  = Vector2(6, 6)
		var start_pos := _panel.position + Vector2(randf_range(20, 340), randf_range(20, 90))
		dot.position  = start_pos
		add_child(dot)

		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(dot, "position:y", start_pos.y - randf_range(40, 120), randf_range(0.5, 1.0)) \
		 .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT) \
		 .set_delay(randf_range(0.0, 0.25))
		t.tween_property(dot, "modulate:a", 0.0, randf_range(0.4, 0.9)) \
		 .set_delay(randf_range(0.1, 0.4))
		t.chain().tween_callback(dot.queue_free)

# ─── Helpers ─────────────────────────────────────────────────────────────────

func _make_label(text: String, fsize: int, bold: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", fsize)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	if bold:
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
		lbl.add_theme_constant_override("shadow_offset_x", 2)
		lbl.add_theme_constant_override("shadow_offset_y", 2)
	return lbl
