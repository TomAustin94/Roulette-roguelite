## HUD.gd — In-game heads-up display.
## Compact single-bar layout using proper VBox containers — no absolute positioning.
class_name HUD
extends Control

signal pause_pressed

var _floor_label:  Label
var _target_label: Label
var _score_bar:    ProgressBar
var _chips_label:  Label
var _spins_label:  Label
var _mod_notif:    Label
var _boss_banner:  Panel

var _notif_tween:  Tween = null
var _score_tween:  Tween = null
var _glow_overlay: ColorRect
var _bar_glow:     Panel

func _ready() -> void:
	_build_ui()
	_connect_signals()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	# ── Row 1: Floor / Chips ──────────────────────────────────────────────────
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left",  14)
	top_margin.add_theme_constant_override("margin_right", 14)
	top_margin.add_theme_constant_override("margin_top",   8)
	top_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(top_margin)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 0)
	top_margin.add_child(top_row)

	_floor_label = _make_label("Floor 1 · Round 1", 17, true)
	_floor_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_floor_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_LEFT
	_floor_label.clip_text = true
	top_row.add_child(_floor_label)

	_chips_label = _make_label("♦ 150", 20, true)
	_chips_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	_chips_label.add_theme_color_override("font_color", Constants.COLOR_GOLD)
	top_row.add_child(_chips_label)

	# Pause button (small, right of chips)
	var pause_btn := Button.new()
	pause_btn.text = "❙❙"
	pause_btn.custom_minimum_size = Vector2(52, 36)
	pause_btn.add_theme_font_size_override("font_size", 14)
	pause_btn.add_theme_color_override("font_color", Color(0.62, 0.57, 0.44))
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.10, 0.06, 0.80)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		ps.set("corner_radius_" + c, 6)
	for s in ["left","right","top","bottom"]:
		ps.set("border_width_" + s, 1)
	ps.border_color = Color(0.35, 0.30, 0.15, 0.45)
	pause_btn.add_theme_stylebox_override("normal", ps)
	var ph := ps.duplicate() as StyleBoxFlat
	ph.bg_color = Color(0.12, 0.18, 0.12)
	pause_btn.add_theme_stylebox_override("hover", ph)
	pause_btn.add_theme_stylebox_override("pressed", ps)
	pause_btn.pressed.connect(func(): pause_pressed.emit())
	top_row.add_child(pause_btn)

	# ── Row 2: Score bar ──────────────────────────────────────────────────────
	var bar_margin := MarginContainer.new()
	bar_margin.add_theme_constant_override("margin_left",   14)
	bar_margin.add_theme_constant_override("margin_right",  14)
	bar_margin.add_theme_constant_override("margin_top",    4)
	bar_margin.add_theme_constant_override("margin_bottom", 2)
	bar_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(bar_margin)

	var bar_vbox := VBoxContainer.new()
	bar_vbox.add_theme_constant_override("separation", 2)
	bar_margin.add_child(bar_vbox)

	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 8)
	bar_vbox.add_child(bar_row)

	_target_label = _make_label("0 / 400", 13)
	_target_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_target_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_LEFT
	bar_row.add_child(_target_label)

	_spins_label = _make_label("⟳ 5 spins", 13)
	_spins_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	_spins_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
	bar_row.add_child(_spins_label)

	_score_bar = ProgressBar.new()
	_score_bar.custom_minimum_size = Vector2(0, 16)
	_score_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_score_bar.min_value = 0
	_score_bar.max_value = 400
	_score_bar.value     = 0
	_score_bar.show_percentage = false
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Constants.COLOR_GOLD
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		fill_style.set("corner_radius_" + c, 4)
	_score_bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.0, 0.0, 0.0, 0.45)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		bg_style.set("corner_radius_" + c, 4)
	_score_bar.add_theme_stylebox_override("background", bg_style)
	bar_vbox.add_child(_score_bar)

	# Glow layer behind bar
	_bar_glow = Panel.new()
	_bar_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bar_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_style := StyleBoxFlat.new()
	glow_style.bg_color = Color(0, 0, 0, 0)
	glow_style.shadow_color  = Constants.COLOR_GOLD
	glow_style.shadow_size   = 0
	glow_style.shadow_offset = Vector2.ZERO
	_bar_glow.add_theme_stylebox_override("panel", glow_style)
	_bar_glow.modulate.a = 0.0
	bar_vbox.add_child(_bar_glow)
	bar_vbox.move_child(_bar_glow, 0)

	# ── Row 3: Boss banner (hidden by default) ────────────────────────────────
	_boss_banner = Panel.new()
	_boss_banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_banner.custom_minimum_size.y = 0
	_boss_banner.visible = false
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color(0.55, 0.05, 0.05, 0.95)
	_boss_banner.add_theme_stylebox_override("panel", banner_style)
	root.add_child(_boss_banner)

	var boss_label := _make_label("", 13)
	boss_label.name = "BossLabel"
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	boss_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_boss_banner.add_child(boss_label)

	# ── Mod notification (floats at centre, alpha-fades) ─────────────────────
	_mod_notif = _make_label("", 15, true)
	_mod_notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mod_notif.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mod_notif.add_theme_color_override("font_color", Constants.COLOR_HIGHLIGHT)
	_mod_notif.modulate.a = 0.0
	_mod_notif.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mod_notif)  # direct child, floats above layout

	# ── Full-screen flash for round win ──────────────────────────────────────
	_glow_overlay = ColorRect.new()
	_glow_overlay.color        = Color(0.9, 0.78, 0.2, 0.0)
	_glow_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_glow_overlay)

func _connect_signals() -> void:
	GameManager.chips_changed.connect(_on_chips_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.round_started.connect(_on_round_started)
	GameManager.round_won.connect(_on_round_won)
	ModManager.mod_triggered.connect(_on_mod_triggered)

# ─── Signal handlers ─────────────────────────────────────────────────────────

func _on_chips_changed(amount: int) -> void:
	_chips_label.text = "♦ %d" % amount

func _on_score_changed(score: int, tgt: int) -> void:
	_target_label.text = "%d / %d" % [score, tgt]
	if _score_tween:
		_score_tween.kill()
	_score_tween = create_tween()
	_score_tween.set_ease(Tween.EASE_OUT)
	_score_tween.set_trans(Tween.TRANS_QUAD)
	_score_tween.tween_property(_score_bar, "value", float(score), 0.4)
	_pulse_bar_glow(score >= tgt)

func _on_round_started(info: Dictionary) -> void:
	_floor_label.text = "%s · Round %d" % [
		info.get("floor_name", "Floor %d" % info.get("floor", 1)),
		info.get("round", 1)
	]
	_chips_label.text  = "♦ %d" % GameManager.chips
	_spins_label.text  = "⟳ %d spins" % info.get("spins", 5)
	_score_bar.max_value = info.get("target", 400)
	_score_bar.value     = 0
	_target_label.text   = "0 / %d" % info.get("target", 400)

	var boss_rule: Dictionary = info.get("boss_rule", {})
	if boss_rule.is_empty():
		_boss_banner.visible = false
		_boss_banner.custom_minimum_size.y = 0
	else:
		_boss_banner.visible = true
		_boss_banner.custom_minimum_size.y = 36
		var lbl := _boss_banner.get_node_or_null("BossLabel") as Label
		if lbl:
			lbl.text = "☠ %s: %s" % [boss_rule.get("name", ""), boss_rule.get("description", "")]

func update_spins(spins: int) -> void:
	_spins_label.text = "⟳ %d spin%s" % [spins, "" if spins == 1 else "s"]

func _on_mod_triggered(_id: String, description: String) -> void:
	_mod_notif.text = description
	if _notif_tween:
		_notif_tween.kill()
	_mod_notif.modulate.a = 1.0
	_notif_tween = create_tween()
	_notif_tween.tween_interval(1.5)
	_notif_tween.tween_property(_mod_notif, "modulate:a", 0.0, 0.5)

func _on_round_won() -> void:
	_glow_overlay.color.a = 0.0
	var t := create_tween()
	t.tween_property(_glow_overlay, "color:a", 0.45, 0.12)
	t.tween_property(_glow_overlay, "color:a", 0.0,  0.55)
	var fill_style := _score_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style:
		var t2 := create_tween()
		t2.tween_property(fill_style, "bg_color", Color.WHITE, 0.15)
		t2.tween_property(fill_style, "bg_color", Constants.COLOR_GOLD, 0.35)

func _pulse_bar_glow(is_complete: bool) -> void:
	var color := Color(1.0, 1.0, 0.6, 0.0) if is_complete else Color(0.7, 0.9, 0.7, 0.0)
	_bar_glow.modulate.a = 1.0
	_glow_overlay.color  = Color(color.r, color.g, color.b, 0.0)
	var t := create_tween()
	t.tween_property(_bar_glow, "modulate:a", 0.0, 0.5)

func _make_label(text: String, fsize: int, bold: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", fsize)
	if bold:
		lbl.add_theme_color_override("font_color", Constants.COLOR_TEXT)
	else:
		lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75))
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	return lbl
