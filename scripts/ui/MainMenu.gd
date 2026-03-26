## MainMenu.gd — Title screen with lore flavour and new-run entry.
extends Control

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Constants.COLOR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Decorative wheel silhouette (simple arcs)
	var deco := _make_deco()
	deco.set_anchors_preset(Control.PRESET_TOP_WIDE)
	deco.custom_minimum_size = Vector2(0, 420)
	add_child(deco)

	# Content VBox
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)

	# Spacer (wheel deco area)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 360)
	vbox.add_child(spacer)

	# Title
	var title := Label.new()
	title.text = "ROULETTE\nROGUELITE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Constants.COLOR_GOLD)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	vbox.add_child(title)

	# Subtitle / lore
	var sub := Label.new()
	sub.text = "You made a deal. The Devil dealt.\nWin back your soul — one spin at a time."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.75, 0.70, 0.60))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD
	sub.custom_minimum_size.x = 700
	vbox.add_child(sub)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(sep)

	# New Run button
	var play_btn := _make_button("NEW RUN", Constants.COLOR_GOLD, Color.BLACK)
	play_btn.pressed.connect(_on_new_run)
	vbox.add_child(play_btn)

	# Footer flavour
	var footer := Label.new()
	footer.text = "Five floors. One wheel. No mercy."
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 13)
	footer.add_theme_color_override("font_color", Color(0.45, 0.40, 0.35))
	vbox.add_child(footer)

func _make_deco() -> Control:
	# Node2D drawn as part of a Control using a proxy
	var node := Control.new()
	node.draw.connect(func():
		var cx := node.size.x * 0.5
		var cy := node.size.y * 0.5 + 20
		var center := Vector2(cx, cy)
		# Outer glow rings
		for i in 3:
			var r := 170.0 + i * 12.0
			node.draw_arc(center, r, 0.0, TAU, 64,
						  Color(Constants.COLOR_GOLD.r, Constants.COLOR_GOLD.g, Constants.COLOR_GOLD.b, 0.08 + i * 0.04),
						  2.0 + i * 0.5)
		# Simple sector outlines
		for s in 18:
			var a := TAU * s / 18.0
			var p1 := center + Vector2(cos(a), sin(a)) * 55.0
			var p2 := center + Vector2(cos(a), sin(a)) * 165.0
			node.draw_line(p1, p2, Color(Constants.COLOR_GOLD.r, Constants.COLOR_GOLD.g, Constants.COLOR_GOLD.b, 0.15), 1.0)
		# Alternating red/black arc segments
		for s in 18:
			var a0 := TAU * s / 18.0
			var a1 := TAU * (s + 0.9) / 18.0
			var col := Constants.COLOR_RED if s % 2 == 0 else Constants.COLOR_BLACK
			col.a = 0.55
			node.draw_arc(center, 140.0, a0, a1, 12, col, 22.0)
		# Hub
		node.draw_circle(center, 50.0, Color(0.18, 0.12, 0.06))
		node.draw_arc(center, 50.0, 0.0, TAU, 32, Constants.COLOR_GOLD, 2.0)
		# Ball
		node.draw_circle(center + Vector2(0, -165.0), 10.0, Color.WHITE)
	)
	return node

func _on_new_run() -> void:
	AudioManager.play_sfx("button_click")
	GameManager.start_new_run()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _make_button(label: String, bg_color: Color, text_color: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(400, 72)
	btn.add_theme_font_size_override("font_size", 26)
	btn.add_theme_color_override("font_color", text_color)

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color.darkened(0.1)
	style.corner_radius_top_left     = 10
	style.corner_radius_top_right    = 10
	style.corner_radius_bottom_left  = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color = bg_color.lightened(0.25)
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = bg_color
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", style)
	return btn
