## GameOver.gd — Shown on both game-over and win states.
## Submits score to HighScoreManager and adapts UI accordingly.
extends Control

func _ready() -> void:
	var won := GameManager.state == GameManager.GameState.WIN
	HighScoreManager.submit_score(won)
	_build_ui(won)

func _build_ui(won: bool) -> void:
	# ── Background ────────────────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.02)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var tint := ColorRect.new()
	tint.color = Color(0.06, 0.40, 0.06, 0.10) if won else Color(0.45, 0.04, 0.04, 0.16)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tint)

	# ── Gold top border ───────────────────────────────────────────────────────
	var top_line := ColorRect.new()
	top_line.color = Constants.COLOR_GOLD if won else Constants.COLOR_RED.lightened(0.1)
	top_line.anchor_right = 1.0
	top_line.custom_minimum_size = Vector2(0, 3)
	add_child(top_line)

	# ── Content ───────────────────────────────────────────────────────────────
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",  55)
	margin.add_theme_constant_override("margin_right", 55)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 22)
	margin.add_child(vbox)

	# ── Icon ─────────────────────────────────────────────────────────────────
	var icon := Label.new()
	icon.text = "★" if won else "✦"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 72)
	icon.add_theme_color_override("font_color", Constants.COLOR_GOLD if won else Color(0.65, 0.10, 0.10))
	vbox.add_child(icon)

	# ── Headline ──────────────────────────────────────────────────────────────
	var headline := Label.new()
	headline.text = "YOU'RE FREE." if won else "THE HOUSE WINS."
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline.add_theme_font_size_override("font_size", 44)
	headline.add_theme_color_override("font_color", Constants.COLOR_GOLD if won else Constants.COLOR_RED.lightened(0.2))
	headline.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	headline.add_theme_constant_override("shadow_offset_x", 3)
	headline.add_theme_constant_override("shadow_offset_y", 3)
	vbox.add_child(headline)

	# ── New best badge ────────────────────────────────────────────────────────
	if HighScoreManager.is_new_best(GameManager.total_score):
		var badge := Label.new()
		badge.text = "★  NEW BEST SCORE!"
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 18)
		badge.add_theme_color_override("font_color", Constants.COLOR_HIGHLIGHT)
		vbox.add_child(badge)

	# ── Flavour quote ─────────────────────────────────────────────────────────
	var win_quotes := [
		"Five floors. Five bosses. One soul recovered.",
		"The Devil tips his hat. Grudgingly.",
		"You beat the house. This time.",
	]
	var loss_quotes := [
		"The wheel stops. Your chips do not.",
		"The house always wins. Tonight it did.",
		"Try again. The Devil is patient.",
	]
	var quotes := win_quotes if won else loss_quotes
	var flavor := Label.new()
	flavor.text = quotes[randi() % quotes.size()]
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.add_theme_font_size_override("font_size", 16)
	flavor.add_theme_color_override("font_color", Color(0.68, 0.63, 0.52))
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(flavor)

	# ── Floor progress dots ───────────────────────────────────────────────────
	var dots_row := _make_floor_dots()
	vbox.add_child(dots_row)

	# ── Stats ─────────────────────────────────────────────────────────────────
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.30, 0.25, 0.10, 0.35))
	vbox.add_child(sep)

	var stats_vb := VBoxContainer.new()
	stats_vb.add_theme_constant_override("separation", 10)
	vbox.add_child(stats_vb)

	_add_stat(stats_vb, "Total Score",     str(GameManager.total_score))
	_add_stat(stats_vb, "Floors Cleared",  str(GameManager.run_stats.get("floors_cleared", 0)))
	_add_stat(stats_vb, "Total Spins",     str(GameManager.run_stats.get("total_spins", 0)))
	_add_stat(stats_vb, "Biggest Win",     "♦ %d" % GameManager.run_stats.get("biggest_win", 0))
	_add_stat(stats_vb, "Chips Remaining", "♦ %d" % GameManager.chips)

	# ── Buttons ───────────────────────────────────────────────────────────────
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(gap)

	var retry_btn := _make_button("TRY AGAIN", Constants.COLOR_GOLD, Color.BLACK)
	retry_btn.pressed.connect(_on_retry)
	vbox.add_child(retry_btn)

	var hs_btn := _make_button("HIGH SCORES", Color(0.08, 0.12, 0.08), Constants.COLOR_TEXT)
	hs_btn.pressed.connect(_on_high_scores)
	vbox.add_child(hs_btn)

	var menu_btn := _make_button("MAIN MENU", Color(0.14, 0.14, 0.14), Constants.COLOR_TEXT)
	menu_btn.pressed.connect(_on_main_menu)
	vbox.add_child(menu_btn)

# ─── Floor dots ───────────────────────────────────────────────────────────────

func _make_floor_dots() -> Control:
	var container := HBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 14)
	container.custom_minimum_size = Vector2(0, 28)

	var floors_cleared := GameManager.run_stats.get("floors_cleared", 0)
	for i in 5:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(14, 14)
		dot.color = Constants.COLOR_GOLD if i < floors_cleared else Color(0.22, 0.18, 0.12)
		container.add_child(dot)

	return container

# ─── Stat row ─────────────────────────────────────────────────────────────────

func _add_stat(parent: VBoxContainer, label: String, value: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	parent.add_child(hbox)

	var k := Label.new()
	k.text = label
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k.add_theme_font_size_override("font_size", 16)
	k.add_theme_color_override("font_color", Color(0.62, 0.57, 0.46))
	hbox.add_child(k)

	var v := Label.new()
	v.text = value
	v.size_flags_horizontal = Control.SIZE_SHRINK_END
	v.add_theme_font_size_override("font_size", 16)
	v.add_theme_color_override("font_color", Constants.COLOR_TEXT)
	hbox.add_child(v)

# ─── Navigation ───────────────────────────────────────────────────────────────

func _on_retry() -> void:
	AudioManager.play_sfx("button_click")
	SaveManager.delete_save()
	GameManager.start_new_run()
	GameManager.begin_run()  # skip lore intro for retries
	get_tree().change_scene_to_file("res://scenes/FloorTransition.tscn")

func _on_high_scores() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().change_scene_to_file("res://scenes/HighScores.tscn")

func _on_main_menu() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# ─── Button factory ───────────────────────────────────────────────────────────

func _make_button(label: String, bg: Color, text_color: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 68)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", text_color)

	var style := StyleBoxFlat.new()
	style.bg_color = bg.darkened(0.1)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		style.set("corner_radius_" + c, 10)
	for s in ["left","right","top","bottom"]:
		style.set("border_width_" + s, 2)
	style.border_color = bg.lightened(0.2)
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = bg
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", style)
	return btn
