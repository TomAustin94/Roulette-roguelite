## Shop.gd — Between-round mod shop.
## Player can buy up to one mod from 3 random offers, then continue.
extends Control

const OFFER_COUNT := 3

var _mod_offers: Array[Dictionary] = []

func _ready() -> void:
	_mod_offers = ModManager.get_shop_offer(OFFER_COUNT)
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Constants.COLOR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Top decoration strip
	var strip := ColorRect.new()
	strip.color = Color(0.08, 0.12, 0.08)
	strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	strip.custom_minimum_size.y = 6
	add_child(strip)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left",   24)
	margin.add_theme_constant_override("margin_right",  24)
	margin.add_theme_constant_override("margin_top",    36)
	margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	# Header
	var title := _make_label("THE SHOP", 38, Constants.COLOR_GOLD, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var floor_sub := _make_label(
		"Floor %d · Round %d complete" % [GameManager.floor_num, GameManager.round_num - 1 if GameManager.round_num > 1 else GameManager.round_num],
		16, Color(0.65, 0.60, 0.50)
	)
	floor_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(floor_sub)

	var chips_lbl := _make_label("♦ %d chips" % GameManager.chips, 22, Constants.COLOR_GOLD, true)
	chips_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chips_lbl.name = "ChipsLabel"
	vbox.add_child(chips_lbl)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.3, 0.25, 0.1, 0.5))
	vbox.add_child(sep)

	var offer_lbl := _make_label("CHOOSE A MOD  (or skip)", 15, Color(0.6, 0.55, 0.45))
	offer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(offer_lbl)

	# Mod cards
	for mod in _mod_offers:
		var card := _build_mod_card(mod)
		vbox.add_child(card)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Active mods summary
	if ModManager.active_mods.size() > 0:
		var owned_lbl := _make_label("YOUR MODS", 14, Color(0.55, 0.50, 0.40))
		owned_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(owned_lbl)

		var owned_names: Array[String] = []
		for m in ModManager.active_mods:
			owned_names.append(m.get("name", "?"))
		var owned_list := _make_label(", ".join(owned_names), 13, Color(0.65, 0.60, 0.50))
		owned_list.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		owned_list.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(owned_list)

	# Continue button
	var cont_btn := _make_button("CONTINUE →", Constants.COLOR_GREEN.lightened(0.15), Color.WHITE)
	cont_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont_btn.pressed.connect(_on_continue)
	vbox.add_child(cont_btn)

func _build_mod_card(mod: Dictionary) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 120)

	var rarity: String = mod.get("rarity", "common")
	var border_color: Color
	match rarity:
		"legendary": border_color = Color(1.0, 0.75, 0.0)
		"rare":      border_color = Color(0.6, 0.3, 0.9)
		"uncommon":  border_color = Color(0.2, 0.7, 0.4)
		_:           border_color = Color(0.5, 0.5, 0.5)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.14, 0.10)
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	var inner := MarginContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("margin_left",   10)
	inner.add_theme_constant_override("margin_right",  12)
	inner.add_theme_constant_override("margin_top",    10)
	inner.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(inner)
	inner.add_child(hbox)

	# Icon (left edge)
	var icon := ModIcon.new()
	icon.category   = mod.get("category", "utility")
	icon.icon_color = border_color
	icon.custom_minimum_size = Vector2(52, 52)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon)

	# Info vbox
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)

	var name_lbl := _make_label(mod.get("name", "?"), 20, Color.WHITE, true)
	info_vbox.add_child(name_lbl)

	var desc_lbl := _make_label(mod.get("description", ""), 13, Color(0.80, 0.76, 0.68))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_vbox.add_child(desc_lbl)

	var flavor_lbl := _make_label('"%s"' % mod.get("flavor", ""), 11, Color(0.55, 0.50, 0.42))
	flavor_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_vbox.add_child(flavor_lbl)

	# Right: cost + buy button
	var right_vbox := VBoxContainer.new()
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(right_vbox)

	var cost: int = mod.get("cost", 50)
	var cost_lbl := _make_label("♦ %d" % cost, 18, Constants.COLOR_GOLD, true)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_vbox.add_child(cost_lbl)

	var can_afford := GameManager.chips >= cost
	var already_owned: bool = ModManager.has_mod(mod.get("id", "")) and mod.get("unique", false)
	var buy_btn := _make_button(
		"BUY" if (can_afford and not already_owned) else ("OWNED" if already_owned else "CAN'T"),
		Constants.COLOR_GOLD if (can_afford and not already_owned) else Color(0.3, 0.3, 0.3),
		Color.BLACK if can_afford else Color.WHITE
	)
	buy_btn.custom_minimum_size = Vector2(120, 44)
	buy_btn.disabled = not can_afford or already_owned
	buy_btn.pressed.connect(func():
		if GameManager.chips >= cost:
			GameManager._spend_chips(cost)
			ModManager.add_mod_by_id(mod.get("id", ""))
			_refresh_chips_label()
			buy_btn.disabled = true
			buy_btn.text     = "OWNED"
			AudioManager.play_sfx("win")
	)
	right_vbox.add_child(buy_btn)

	# Rarity badge
	var rarity_lbl := _make_label(rarity.to_upper(), 10, border_color)
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_vbox.add_child(rarity_lbl)

	return panel

func _refresh_chips_label() -> void:
	var lbl := find_child("ChipsLabel") as Label
	if lbl:
		lbl.text = "♦ %d chips" % GameManager.chips

func _on_continue() -> void:
	AudioManager.play_sfx("button_click")
	GameManager.leave_shop()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

# ─── Helpers ─────────────────────────────────────────────────────────────────

func _make_label(text: String, fsize: int, color: Color, bold: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", fsize)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _make_button(label: String, bg: Color, text_color: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 60)
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
