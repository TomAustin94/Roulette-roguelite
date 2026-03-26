## GameOver.gd — Shown on both game-over and win states.
## Adapts its content based on GameManager.state.
extends Control

func _ready() -> void:
	var won := GameManager.state == GameManager.GameState.WIN
	_build_ui(won)

func _build_ui(won: bool) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.02)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Subtle colour tint overlay
	var tint := ColorRect.new()
	tint.color = (Color(0.1, 0.5, 0.1, 0.12) if won else Color(0.5, 0.05, 0.05, 0.18))
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tint)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",  50)
	margin.add_theme_constant_override("margin_right", 50)
	add_child(margin)
	margin.add_child(vbox)

	# Icon / large symbol
	var icon_lbl := Label.new()
	icon_lbl.text  = "★" if won else "✦"
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 80)
	icon_lbl.add_theme_color_override("font_color", Constants.COLOR_GOLD if won else Color(0.6, 0.1, 0.1))
	vbox.add_child(icon_lbl)

	# Headline
	var headline := Label.new()
	headline.text = ("YOU'RE FREE." if won else "THE HOUSE WINS.")
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline.add_theme_font_size_override("font_size", 44)
	headline.add_theme_color_override("font_color", Constants.COLOR_GOLD if won else Constants.COLOR_RED.lightened(0.2))
	headline.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	headline.add_theme_constant_override("shadow_offset_x", 3)
	headline.add_theme_constant_override("shadow_offset_y", 3)
	vbox.add_child(headline)

	# Flavour text
	var flavor_texts_win := [
		"Five floors. Five bosses. One soul recovered.",
		"The Devil tips his hat. Grudgingly.",
		"You beat the house. This time.",
	]
	var flavor_texts_lose := [
		"The wheel stops. Your chips do not.",
		"The house always wins. Tonight, it did.",
		"Try again. The Devil is patient.",
	]
	var flavors := flavor_texts_win if won else flavor_texts_lose
	var flavor_lbl := Label.new()
	flavor_lbl.text = flavors[randi() % flavors.size()]
	flavor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor_lbl.add_theme_font_size_override("font_size", 16)
	flavor_lbl.add_theme_color_override("font_color", Color(0.70, 0.65, 0.55))
	flavor_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(flavor_lbl)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.3, 0.25, 0.1, 0.4))
	vbox.add_child(sep)

	# Stats
	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	vbox.add_child(stats_vbox)

	_add_stat(stats_vbox, "Floors Cleared", str(GameManager.run_stats.get("floors_cleared", 0)))
	_add_stat(stats_vbox, "Total Spins",    str(GameManager.run_stats.get("total_spins", 0)))
	_add_stat(stats_vbox, "Biggest Win",    "♦ %d" % GameManager.run_stats.get("biggest_win", 0))
	_add_stat(stats_vbox, "Chips Left",     "♦ %d" % GameManager.chips)
	_add_stat(stats_vbox, "Mods Held",      str(ModManager.active_mods.size()))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer)

	# Try again button
	var retry_btn := _make_button("TRY AGAIN", Constants.COLOR_GOLD, Color.BLACK)
	retry_btn.pressed.connect(_on_retry)
	vbox.add_child(retry_btn)

	# Main menu button
	var menu_btn := _make_button("MAIN MENU", Color(0.2, 0.2, 0.2), Color.WHITE)
	menu_btn.pressed.connect(_on_main_menu)
	vbox.add_child(menu_btn)

func _add_stat(parent: VBoxContainer, label: String, value: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	parent.add_child(hbox)

	var k := Label.new()
	k.text = label
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k.add_theme_font_size_override("font_size", 16)
	k.add_theme_color_override("font_color", Color(0.65, 0.60, 0.50))
	hbox.add_child(k)

	var v := Label.new()
	v.text = value
	v.size_flags_horizontal = Control.SIZE_SHRINK_END
	v.add_theme_font_size_override("font_size", 16)
	v.add_theme_color_override("font_color", Constants.COLOR_TEXT)
	hbox.add_child(v)

func _on_retry() -> void:
	AudioManager.play_sfx("button_click")
	GameManager.start_new_run()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_main_menu() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _make_button(label: String, bg: Color, text_color: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(360, 62)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", text_color)

	var style := StyleBoxFlat.new()
	style.bg_color = bg.darkened(0.1)
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color = bg.lightened(0.2)
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = bg
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", style)
	return btn
