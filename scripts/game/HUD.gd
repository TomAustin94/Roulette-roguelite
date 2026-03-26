## HUD.gd — In-game heads-up display.
## Shows floor/round info, score progress, chips, spins, and mod notifications.
class_name HUD
extends Control

# ─── References (set by Game.gd after add_child) ─────────────────────────────
var _floor_label:    Label
var _target_label:   Label
var _score_bar:      ProgressBar
var _chips_label:    Label
var _spins_label:    Label
var _mod_notif:      Label  # transient mod trigger notification
var _boss_banner:    Panel  # shown on boss rounds

var _notif_tween:    Tween  = null
var _score_tween:    Tween  = null

func _ready() -> void:
	_build_ui()
	_connect_signals()

func _build_ui() -> void:
	# ── Top bar: floor / round info ──────────────────────────────────────────
	var top_bar := HBoxContainer.new()
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size.y = 70
	top_bar.add_theme_constant_override("separation", 0)
	add_child(top_bar)

	_floor_label = _make_label("Floor 1 · Round 1", 18, true)
	_floor_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_floor_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_LEFT
	top_bar.add_child(_floor_label)

	_chips_label = _make_label("♦ 150", 20, true)
	_chips_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	_chips_label.add_theme_color_override("font_color", Constants.COLOR_GOLD)
	top_bar.add_child(_chips_label)

	# ── Score progress bar ───────────────────────────────────────────────────
	var bar_container := VBoxContainer.new()
	bar_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar_container.position.y = 75
	bar_container.custom_minimum_size.y = 50
	add_child(bar_container)

	_target_label = _make_label("0 / 400", 14)
	_target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar_container.add_child(_target_label)

	_score_bar = ProgressBar.new()
	_score_bar.custom_minimum_size = Vector2(0, 18)
	_score_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_score_bar.min_value = 0
	_score_bar.max_value = 400
	_score_bar.value     = 0
	_score_bar.show_percentage = false
	var style := StyleBoxFlat.new()
	style.bg_color = Constants.COLOR_GOLD
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	_score_bar.add_theme_stylebox_override("fill", style)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.0, 0.0, 0.0, 0.4)
	bg_style.corner_radius_top_left     = 4
	bg_style.corner_radius_top_right    = 4
	bg_style.corner_radius_bottom_left  = 4
	bg_style.corner_radius_bottom_right = 4
	_score_bar.add_theme_stylebox_override("background", bg_style)
	bar_container.add_child(_score_bar)

	# ── Spins remaining ──────────────────────────────────────────────────────
	_spins_label = _make_label("⟳ 5 spins", 16)
	_spins_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_spins_label.position = Vector2(-200, 130)
	_spins_label.custom_minimum_size.x = 190
	_spins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_spins_label)

	# ── Boss rule banner ─────────────────────────────────────────────────────
	_boss_banner = Panel.new()
	_boss_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_boss_banner.position.y = 130
	_boss_banner.custom_minimum_size.y = 0
	_boss_banner.visible = false
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color(0.55, 0.05, 0.05, 0.92)
	_boss_banner.add_theme_stylebox_override("panel", banner_style)
	add_child(_boss_banner)

	var boss_label := _make_label("", 13)
	boss_label.name = "BossLabel"
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	boss_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_boss_banner.add_child(boss_label)

	# ── Mod notification ─────────────────────────────────────────────────────
	_mod_notif = _make_label("", 15, true)
	_mod_notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mod_notif.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_mod_notif.position.y = 185
	_mod_notif.custom_minimum_size = Vector2(600, 30)
	_mod_notif.position.x = -300
	_mod_notif.add_theme_color_override("font_color", Constants.COLOR_HIGHLIGHT)
	_mod_notif.modulate.a = 0.0
	add_child(_mod_notif)

func _connect_signals() -> void:
	GameManager.chips_changed.connect(_on_chips_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.round_started.connect(_on_round_started)
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

func _on_round_started(info: Dictionary) -> void:
	_floor_label.text = "%s · Round %d" % [info.get("floor_name", "Floor %d" % info.get("floor", 1)), info.get("round", 1)]
	_chips_label.text = "♦ %d" % GameManager.chips
	_spins_label.text = "⟳ %d spins" % info.get("spins", 5)
	_score_bar.max_value = info.get("target", 400)
	_score_bar.value     = 0
	_target_label.text   = "0 / %d" % info.get("target", 400)

	# Boss rule banner
	var boss_rule: Dictionary = info.get("boss_rule", {})
	if boss_rule.is_empty():
		_boss_banner.visible = false
		_boss_banner.custom_minimum_size.y = 0
	else:
		_boss_banner.visible = true
		_boss_banner.custom_minimum_size.y = 44
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

# ─── Helpers ─────────────────────────────────────────────────────────────────

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
