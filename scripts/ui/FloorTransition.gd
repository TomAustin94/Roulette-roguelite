## FloorTransition.gd — Atmospheric reveal between floors.
## Shows the next floor's name, subtitle, and lore text before entering.
extends Control

func _ready() -> void:
	_build_ui()
	_animate_in()

func _build_ui() -> void:
	var floor_data := GameManager.get_floor_data(GameManager.floor_num)

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.02)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",  60)
	margin.add_theme_constant_override("margin_right", 60)
	add_child(margin)
	margin.add_child(vbox)

	# Floor number
	var floor_num_lbl := Label.new()
	floor_num_lbl.text = "FLOOR %d" % GameManager.floor_num
	floor_num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floor_num_lbl.add_theme_font_size_override("font_size", 30)
	floor_num_lbl.add_theme_color_override("font_color", Color(0.55, 0.50, 0.40))
	floor_num_lbl.modulate.a = 0.0
	floor_num_lbl.name = "FloorNumLbl"
	vbox.add_child(floor_num_lbl)

	# Floor name
	var name_lbl := Label.new()
	name_lbl.text = floor_data.get("name", "Unknown Floor")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 64)
	name_lbl.add_theme_color_override("font_color", Constants.COLOR_GOLD)
	name_lbl.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	name_lbl.add_theme_constant_override("shadow_offset_x", 3)
	name_lbl.add_theme_constant_override("shadow_offset_y", 3)
	name_lbl.modulate.a = 0.0
	name_lbl.name = "NameLbl"
	vbox.add_child(name_lbl)

	# Subtitle
	var sub_lbl := Label.new()
	sub_lbl.text = floor_data.get("subtitle", "")
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 28)
	sub_lbl.add_theme_color_override("font_color", Color(0.72, 0.68, 0.58))
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	sub_lbl.modulate.a = 0.0
	sub_lbl.name = "SubLbl"
	vbox.add_child(sub_lbl)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.3, 0.25, 0.1, 0.4))
	sep.modulate.a = 0.0
	sep.name = "Sep"
	vbox.add_child(sep)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = floor_data.get("description", "")
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 24)
	desc_lbl.add_theme_color_override("font_color", Color(0.60, 0.55, 0.45))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.modulate.a = 0.0
	desc_lbl.name = "DescLbl"
	vbox.add_child(desc_lbl)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(spacer)

	# Enter button
	var btn := Button.new()
	btn.text = "ENTER THE FLOOR"
	btn.custom_minimum_size = Vector2(380, 90)
	btn.add_theme_font_size_override("font_size", 34)
	btn.modulate.a = 0.0
	btn.name = "EnterBtn"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.55, 0.10, 0.10)
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color = Constants.COLOR_RED.lightened(0.3)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Constants.COLOR_RED
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", style)
	btn.pressed.connect(_on_enter)
	vbox.add_child(btn)

func _animate_in() -> void:
	# Show content elements immediately — no initial blank screen
	var instant_nodes := ["FloorNumLbl", "NameLbl", "SubLbl", "Sep", "DescLbl"]
	for node_name in instant_nodes:
		var node := find_child(node_name)
		if node:
			node.modulate.a = 1.0
	# Fade in just the button with a short delay
	var btn := find_child("EnterBtn")
	if btn:
		var t := create_tween()
		t.tween_interval(0.4)
		t.tween_property(btn, "modulate:a", 1.0, 0.3)

func _on_enter() -> void:
	AudioManager.play_sfx("button_click")
	GameManager.leave_floor_transition()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
