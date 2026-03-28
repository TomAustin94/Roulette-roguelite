## MainMenu.gd — Title screen for The Devil's Deal.
## Shows a continue-run dialog if a save exists, otherwise shows new-run options.
extends Control

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# ── Background ────────────────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = Constants.COLOR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── Gold top border ───────────────────────────────────────────────────────
	var top_line := ColorRect.new()
	top_line.color = Constants.COLOR_GOLD
	top_line.anchor_right = 1.0
	top_line.custom_minimum_size = Vector2(0, 3)
	add_child(top_line)

	# ── Wheel deco (behind content) ───────────────────────────────────────────
	var deco := _make_wheel_deco()
	add_child(deco)

	# ── Content (margin container → vbox) ────────────────────────────────────
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",  60)
	margin.add_theme_constant_override("margin_right", 60)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	# Space for the wheel graphic
	var deco_space := Control.new()
	deco_space.custom_minimum_size = Vector2(0, 270)
	vbox.add_child(deco_space)

	# ── Title ─────────────────────────────────────────────────────────────────
	var title := Label.new()
	title.text = "THE DEVIL'S DEAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 86)
	title.add_theme_color_override("font_color", Constants.COLOR_GOLD)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	vbox.add_child(title)

	# ── Subtitle ──────────────────────────────────────────────────────────────
	var sub := Label.new()
	sub.text = "ROULETTE  ·  ROGUELITE"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 34)
	sub.add_theme_color_override("font_color", Color(0.65, 0.60, 0.47))
	vbox.add_child(sub)

	# ── Gap ───────────────────────────────────────────────────────────────────
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(gap)

	# ── Continue or new-run section ───────────────────────────────────────────
	if SaveManager.has_save():
		_build_continue_section(vbox)
	else:
		_build_new_run_section(vbox)

	# ── Floor progress dots ───────────────────────────────────────────────────
	var dots := _make_floor_dots()
	vbox.add_child(dots)

	# ── Footer lore ───────────────────────────────────────────────────────────
	var footer := Label.new()
	footer.text = "\"Five floors. One wheel. No mercy.\""
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 30)
	footer.add_theme_color_override("font_color", Color(0.42, 0.38, 0.28))
	vbox.add_child(footer)

# ─── Section builders ─────────────────────────────────────────────────────────

func _build_continue_section(vbox: VBoxContainer) -> void:
	var preview := SaveManager.get_save_preview()

	var wb := Label.new()
	wb.text = "WELCOME BACK"
	wb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wb.add_theme_font_size_override("font_size", 34)
	wb.add_theme_color_override("font_color", Color(0.65, 0.60, 0.47))
	vbox.add_child(wb)

	vbox.add_child(_make_save_card(preview))

	var cont_btn := _make_button("CONTINUE RUN", Constants.COLOR_GOLD, Color.BLACK)
	cont_btn.pressed.connect(_on_continue_run)
	vbox.add_child(cont_btn)

	var new_btn := _make_button("START NEW RUN", Color(0.35, 0.07, 0.07), Constants.COLOR_TEXT)
	new_btn.pressed.connect(_on_new_run)
	vbox.add_child(new_btn)

	var hs_btn := _make_button("HIGH SCORES", Color(0.08, 0.12, 0.08), Constants.COLOR_TEXT)
	hs_btn.pressed.connect(_on_high_scores)
	vbox.add_child(hs_btn)

func _build_new_run_section(vbox: VBoxContainer) -> void:
	var lore := Label.new()
	lore.text = "You made a deal. The Devil dealt.\nWin back your soul — one spin at a time."
	lore.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore.add_theme_font_size_override("font_size", 36)
	lore.add_theme_color_override("font_color", Color(0.68, 0.63, 0.52))
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD
	lore.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(lore)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(gap)

	var play_btn := _make_button("NEW RUN", Constants.COLOR_GOLD, Color.BLACK)
	play_btn.pressed.connect(_on_new_run)
	vbox.add_child(play_btn)

	var hs_btn := _make_button("HIGH SCORES", Color(0.08, 0.12, 0.08), Constants.COLOR_TEXT)
	hs_btn.pressed.connect(_on_high_scores)
	vbox.add_child(hs_btn)

# ─── Save card ────────────────────────────────────────────────────────────────

func _make_save_card(preview: Dictionary) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 120)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.11, 0.07)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		style.set("corner_radius_" + c, 8)
	for s in ["left","right","top","bottom"]:
		style.set("border_width_" + s, 1)
	style.border_color = Color(Constants.COLOR_GOLD.r, Constants.COLOR_GOLD.g, Constants.COLOR_GOLD.b, 0.35)
	panel.add_theme_stylebox_override("panel", style)

	var inner := MarginContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("margin_left", 18)
	inner.add_theme_constant_override("margin_right", 18)
	inner.add_theme_constant_override("margin_top", 12)
	inner.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(inner)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	inner.add_child(hbox)

	var left_vb := VBoxContainer.new()
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.add_theme_constant_override("separation", 4)
	hbox.add_child(left_vb)

	var floor_lbl := Label.new()
	floor_lbl.text = "Floor %d  ·  Round %d" % [preview.get("floor_num", 1), preview.get("round_num", 1)]
	floor_lbl.add_theme_font_size_override("font_size", 36)
	floor_lbl.add_theme_color_override("font_color", Constants.COLOR_TEXT)
	left_vb.add_child(floor_lbl)

	var score_lbl := Label.new()
	score_lbl.text = "Score: %d" % preview.get("total_score", 0)
	score_lbl.add_theme_font_size_override("font_size", 30)
	score_lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.47))
	left_vb.add_child(score_lbl)

	var chips_lbl := Label.new()
	chips_lbl.text = "♦ %d" % preview.get("chips", 0)
	chips_lbl.add_theme_font_size_override("font_size", 44)
	chips_lbl.add_theme_color_override("font_color", Constants.COLOR_GOLD)
	chips_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(chips_lbl)

	return panel

# ─── Floor dots ───────────────────────────────────────────────────────────────

func _make_floor_dots() -> Control:
	var container := HBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 14)
	container.custom_minimum_size = Vector2(0, 28)

	for i in 5:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(22, 22)
		# All dots are dim on the main menu (no run in progress displayed here)
		dot.color = Color(0.28, 0.24, 0.16)
		container.add_child(dot)

	return container

# ─── Wheel deco ───────────────────────────────────────────────────────────────

func _make_wheel_deco() -> Control:
	var node := Control.new()
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	node.draw.connect(func():
		var cx  := node.size.x * 0.5
		var cy  := 295.0
		var ctr := Vector2(cx, cy)

		# Outer glow rings
		for i in 3:
			var r := 166.0 + i * 13.0
			node.draw_arc(ctr, r, 0.0, TAU, 64,
				Color(Constants.COLOR_GOLD.r, Constants.COLOR_GOLD.g, Constants.COLOR_GOLD.b, 0.05 + i * 0.03),
				2.0 + i * 0.5)

		# Sector arcs
		for s in 12:
			var a0 := TAU * s / 12.0 - PI * 0.5
			var a1 := TAU * (s + 0.86) / 12.0 - PI * 0.5
			var col: Color
			if s == 0:
				col = Constants.COLOR_GREEN
			elif s % 2 == 0:
				col = Constants.COLOR_RED
			else:
				col = Color(0.08, 0.08, 0.08)
			col.a = 0.55
			node.draw_arc(ctr, 142.0, a0, a1, 12, col, 24.0)

		# Sector dividers
		for s in 12:
			var a := TAU * s / 12.0 - PI * 0.5
			var p1 := ctr + Vector2(cos(a), sin(a)) * 56.0
			var p2 := ctr + Vector2(cos(a), sin(a)) * 164.0
			node.draw_line(p1, p2,
				Color(Constants.COLOR_GOLD.r, Constants.COLOR_GOLD.g, Constants.COLOR_GOLD.b, 0.11), 1.0)

		# Gold border rings
		node.draw_arc(ctr, 164.0, 0, TAU, 64, Color(0.55, 0.40, 0.12, 0.8), 5.0)
		node.draw_arc(ctr, 157.0, 0, TAU, 64, Color(0.35, 0.24, 0.07, 0.5), 1.5)

		# Hub
		node.draw_circle(ctr, 54.0, Color(0.07, 0.05, 0.03))
		node.draw_arc(ctr, 54.0, 0.0, TAU, 32, Color(0.55, 0.40, 0.12), 2.5)
		node.draw_circle(ctr, 22.0, Color(0.55, 0.40, 0.12))
		node.draw_circle(ctr, 16.0, Color(0.35, 0.24, 0.07))
		node.draw_circle(ctr, 8.0, Constants.COLOR_GOLD)

		# Ball
		node.draw_circle(ctr + Vector2(0.0, -164.0), 10.0, Color.WHITE)
		node.draw_circle(ctr + Vector2(0.0, -164.0), 7.0, Color(0.92, 0.92, 0.92))
	)

	return node

# ─── Button handler ───────────────────────────────────────────────────────────

func _on_new_run() -> void:
	AudioManager.play_sfx("button_click")
	SaveManager.delete_save()
	GameManager.start_new_run()
	get_tree().change_scene_to_file("res://scenes/LoreIntro.tscn")

func _on_continue_run() -> void:
	AudioManager.play_sfx("button_click")
	if SaveManager.load_run():
		GameManager.resume_run()
		get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_high_scores() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().change_scene_to_file("res://scenes/HighScores.tscn")

# ─── Button factory ───────────────────────────────────────────────────────────

func _make_button(label: String, bg_color: Color, text_color: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 110)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 46)
	btn.add_theme_color_override("font_color", text_color)

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color.darkened(0.1)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		style.set("corner_radius_" + c, 10)
	for s in ["left","right","top","bottom"]:
		style.set("border_width_" + s, 2)
	style.border_color = bg_color.lightened(0.25)
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = bg_color
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", style)
	return btn
