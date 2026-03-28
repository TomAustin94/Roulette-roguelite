## Game.gd — Main game scene.
## Hosts the roulette wheel, betting table, HUD, and overlay panels:
##   • DealerIntroPanel — shown between rounds (DEALER_INTRO state)
##   • PausePanel       — triggered by pause button at any time
extends Control

# ─── Child references ─────────────────────────────────────────────────────────
var _hud:         HUD
var _wheel:       RouletteWheel
var _table:       BettingTable
var _spin_btn:    Button
var _clear_btn:   Button
var _chip_bar:    HBoxContainer
var _wheel_panel: Control
var _dealer:      DealerCharacter
var _win_popup:   WinPopup

# Overlay panels
var _dealer_intro_panel: Control
var _pause_panel:        Control

# Dealer-intro label refs (populated in _build_dealer_intro_panel)
var _di_floor_lbl:  Label
var _di_name_lbl:   Label
var _di_target_lbl: Label
var _di_boss_panel: Panel
var _di_boss_lbl:   Label

var _selected_chip: int  = 5
var _paused:        bool = false

# ─── Layout constants ─────────────────────────────────────────────────────────
const HUD_HEIGHT   := 160
const WHEEL_HEIGHT := 310
const BTN_BAR_H    := 160

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_scene()
	_connect_signals()
	_sync_initial_state()

func _sync_initial_state() -> void:
	match GameManager.state:
		GameManager.GameState.DEALER_INTRO:
			_dealer_intro_panel.visible = true
			_refresh_dealer_intro()
			_spin_btn.disabled  = true
			_clear_btn.disabled = true
		GameManager.GameState.BETTING:
			_dealer_intro_panel.visible = false
			_spin_btn.disabled  = false
			_clear_btn.disabled = false
		_:
			_dealer_intro_panel.visible = false

# ─── Scene construction ───────────────────────────────────────────────────────

func _build_scene() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Constants.COLOR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Root VBox
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	add_child(vbox)

	# HUD
	_hud = HUD.new()
	_hud.custom_minimum_size.y = HUD_HEIGHT
	_hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_hud)

	# Wheel panel
	_wheel_panel = Control.new()
	_wheel_panel.custom_minimum_size.y = WHEEL_HEIGHT
	_wheel_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_wheel_panel)

	_wheel = RouletteWheel.new()
	_wheel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wheel_panel.add_child(_wheel)
	_wheel.spin_finished.connect(_on_wheel_spin_finished)

	_dealer = DealerCharacter.new()
	_dealer.char_scale = 0.9
	_dealer.position   = Vector2(140, 220)
	_wheel_panel.add_child(_dealer)

	_win_popup = WinPopup.new()
	_win_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_win_popup.visible = false
	_wheel_panel.add_child(_win_popup)
	_win_popup.dismissed.connect(_on_popup_dismissed)

	# Betting table
	_table = BettingTable.new()
	_table.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_table)
	_table.bet_placed.connect(_on_bet_placed)

	# Bottom action bar
	var bar_wrap := Control.new()
	bar_wrap.custom_minimum_size.y = BTN_BAR_H
	bar_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(bar_wrap)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.03, 0.06, 0.03, 0.95)
	bar_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar_wrap.add_child(bar_bg)

	var btn_bar := VBoxContainer.new()
	btn_bar.add_theme_constant_override("separation", 6)
	btn_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar_wrap.add_child(btn_bar)

	# Chip selector row
	_chip_bar = HBoxContainer.new()
	_chip_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_chip_bar.add_theme_constant_override("separation", 6)
	_chip_bar.custom_minimum_size.y = 76
	_chip_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_bar.add_child(_chip_bar)

	for i in Constants.CHIP_VALUES.size():
		var chip_btn := _make_chip_button(Constants.CHIP_VALUES[i], Constants.CHIP_COLORS[i])
		chip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_chip_bar.add_child(chip_btn)

	# Spin / Clear row
	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 10)
	action_row.custom_minimum_size.y = 78
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_bar.add_child(action_row)

	_clear_btn = _make_action_button("✕ CLEAR", Color(0.5, 0.12, 0.12))
	_clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(_clear_btn)

	_spin_btn = _make_action_button("SPIN", Constants.COLOR_GOLD)
	_spin_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_spin_btn.add_theme_color_override("font_color", Color.BLACK)
	action_row.add_child(_spin_btn)

	_spin_btn.pressed.connect(_on_spin_pressed)
	_clear_btn.pressed.connect(_on_clear_pressed)
	_select_chip(0)

	# ── Dealer intro overlay (full-screen, shown during DEALER_INTRO) ─────────
	_dealer_intro_panel = _build_dealer_intro_panel()
	_dealer_intro_panel.visible = false
	add_child(_dealer_intro_panel)

	# ── Pause overlay ─────────────────────────────────────────────────────────
	_pause_panel = _build_pause_panel()
	_pause_panel.visible = false
	add_child(_pause_panel)

# ─── Dealer Intro Panel ───────────────────────────────────────────────────────

func _build_dealer_intro_panel() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.05, 0.03, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   50)
	margin.add_theme_constant_override("margin_right",  50)
	margin.add_theme_constant_override("margin_top",    60)
	margin.add_theme_constant_override("margin_bottom", 50)
	root.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 28)
	margin.add_child(vbox)

	# Floor / round header
	_di_floor_lbl = Label.new()
	_di_floor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_di_floor_lbl.add_theme_font_size_override("font_size", 24)
	_di_floor_lbl.add_theme_color_override("font_color", Color(0.60, 0.55, 0.42))
	vbox.add_child(_di_floor_lbl)

	# Floor name (large)
	_di_name_lbl = Label.new()
	_di_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_di_name_lbl.add_theme_font_size_override("font_size", 58)
	_di_name_lbl.add_theme_color_override("font_color", Constants.COLOR_GOLD)
	_di_name_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	_di_name_lbl.add_theme_constant_override("shadow_offset_x", 3)
	_di_name_lbl.add_theme_constant_override("shadow_offset_y", 3)
	vbox.add_child(_di_name_lbl)

	# Dealer quote panel
	var quote_panel := _make_dealer_quote_panel()
	vbox.add_child(quote_panel)

	# Objectives row (target / spins / chips)
	var obj_card := _make_objectives_card()
	vbox.add_child(obj_card)

	# Boss rule banner (hidden by default)
	_di_boss_panel = Panel.new()
	_di_boss_panel.visible = false
	_di_boss_panel.custom_minimum_size = Vector2(0, 60)
	_di_boss_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var boss_style := StyleBoxFlat.new()
	boss_style.bg_color = Color(0.32, 0.04, 0.04, 0.92)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		boss_style.set("corner_radius_" + c, 8)
	for s in ["left","right","top","bottom"]:
		boss_style.set("border_width_" + s, 2)
	boss_style.border_color = Constants.COLOR_RED.lightened(0.2)
	_di_boss_panel.add_theme_stylebox_override("panel", boss_style)

	_di_boss_lbl = Label.new()
	_di_boss_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_di_boss_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_di_boss_lbl.add_theme_font_size_override("font_size", 22)
	_di_boss_lbl.add_theme_color_override("font_color", Color(1.0, 0.68, 0.68))
	_di_boss_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_di_boss_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_di_boss_panel.add_child(_di_boss_lbl)
	vbox.add_child(_di_boss_panel)

	# BEGIN ROUND button
	var begin_btn := _make_action_button("BEGIN ROUND", Constants.COLOR_GOLD)
	begin_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	begin_btn.add_theme_color_override("font_color", Color.BLACK)
	begin_btn.add_theme_font_size_override("font_size", 40)
	begin_btn.custom_minimum_size = Vector2(0, 110)
	begin_btn.pressed.connect(_on_begin_round_pressed)
	vbox.add_child(begin_btn)

	return root

func _make_dealer_quote_panel() -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 110)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.94, 0.91, 0.85)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		style.set("corner_radius_" + c, 10)
	panel.add_theme_stylebox_override("panel", style)

	var inner := MarginContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("margin_left",   20)
	inner.add_theme_constant_override("margin_right",  20)
	inner.add_theme_constant_override("margin_top",    14)
	inner.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(inner)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	inner.add_child(vb)

	var quote_lbl := Label.new()
	quote_lbl.name = "QuoteLbl"
	quote_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote_lbl.add_theme_font_size_override("font_size", 26)
	quote_lbl.add_theme_color_override("font_color", Color(0.18, 0.10, 0.06))
	quote_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	quote_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(quote_lbl)

	var attr_lbl := Label.new()
	attr_lbl.text = "— The Dealer"
	attr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	attr_lbl.add_theme_font_size_override("font_size", 20)
	attr_lbl.add_theme_color_override("font_color", Color(0.55, 0.40, 0.28))
	vb.add_child(attr_lbl)

	return panel

func _make_objectives_card() -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(0, 140)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.10, 0.06, 0.95)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		style.set("corner_radius_" + c, 10)
	for s in ["left","right","top","bottom"]:
		style.set("border_width_" + s, 1)
	style.border_color = Color(Constants.COLOR_GOLD.r, Constants.COLOR_GOLD.g, Constants.COLOR_GOLD.b, 0.30)
	card.add_theme_stylebox_override("panel", style)

	var inner := MarginContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("margin_left",   20)
	inner.add_theme_constant_override("margin_right",  20)
	inner.add_theme_constant_override("margin_top",    14)
	inner.add_theme_constant_override("margin_bottom", 14)
	card.add_child(inner)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	inner.add_child(hbox)

	# Each stat column: header + value
	for stat in [
		["TARGET", "TargetValue",  str(GameManager.target),              Constants.COLOR_GOLD],
		["SPINS",  "SpinsValue",   str(GameManager.SPINS_PER_ROUND),     Constants.COLOR_TEXT],
		["CHIPS",  "ChipsValue",   "♦ %d" % GameManager.chips,          Constants.COLOR_GOLD],
	]:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 4)
		hbox.add_child(col)

		var h := Label.new()
		h.text = stat[0]
		h.add_theme_font_size_override("font_size", 18)
		h.add_theme_color_override("font_color", Color(0.58, 0.53, 0.40))
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(h)

		var v := Label.new()
		v.name = stat[1]
		v.text = stat[2]
		v.add_theme_font_size_override("font_size", 42)
		v.add_theme_color_override("font_color", stat[3])
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(v)

	return card

func _refresh_dealer_intro() -> void:
	_di_floor_lbl.text = "FLOOR %d  ·  ROUND %d / %d" % [
		GameManager.floor_num, GameManager.round_num, GameManager.ROUNDS_PER_FLOOR
	]

	var fd := GameManager.get_floor_data(GameManager.floor_num)
	_di_name_lbl.text = fd.get("name", "Floor %d" % GameManager.floor_num)

	# Update dealer quote
	var quote_lbl := _dealer_intro_panel.find_child("QuoteLbl") as Label
	if quote_lbl:
		quote_lbl.text = _get_dealer_intro_quote()

	# Update target (may have changed between rounds)
	var tgt_lbl := _dealer_intro_panel.find_child("TargetValue") as Label
	if tgt_lbl:
		tgt_lbl.text = str(GameManager.target)
	var chips_lbl := _dealer_intro_panel.find_child("ChipsValue") as Label
	if chips_lbl:
		chips_lbl.text = "♦ %d" % GameManager.chips

	# Boss rule
	var boss := GameManager.active_boss_rule
	_di_boss_panel.visible = not boss.is_empty()
	if not boss.is_empty():
		_di_boss_lbl.text = "☠  %s: %s" % [boss.get("name", ""), boss.get("description", "")]

func _get_dealer_intro_quote() -> String:
	var is_boss := GameManager.round_num == GameManager.ROUNDS_PER_FLOOR
	if is_boss:
		match GameManager.floor_num:
			1: return "Zero pays nothing tonight. My rules."
			2: return "The Brotherhood recalibrates the odds."
			3: return "Direct access denied. Outside bets only."
			4: return "The tide rises with every spin."
			5: return "My floor. My deal. My terms."
	match GameManager.floor_num:
		1: return "Welcome. Place your bets and try your luck."
		2: return "The gears are turning. Precision is all."
		3: return "SYSTEM ACTIVE. Awaiting bet input."
		4: return "The depths are patient. Are you?"
		5: return "You came this far. Impressive. Foolish."
	return "The wheel awaits."

# ─── Pause Panel ──────────────────────────────────────────────────────────────

func _build_pause_panel() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# Dim
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	# Centre card
	var card := Panel.new()
	card.anchor_left   = 0.5
	card.anchor_right  = 0.5
	card.anchor_top    = 0.5
	card.anchor_bottom = 0.5
	card.offset_left   = -230.0
	card.offset_right  = 230.0
	card.offset_top    = -300.0
	card.offset_bottom = 300.0
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.05, 0.08, 0.05, 0.98)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		cs.set("corner_radius_" + c, 16)
	for s in ["left","right","top","bottom"]:
		cs.set("border_width_" + s, 2)
	cs.border_color = Color(Constants.COLOR_GOLD.r, Constants.COLOR_GOLD.g, Constants.COLOR_GOLD.b, 0.50)
	card.add_theme_stylebox_override("panel", cs)
	overlay.add_child(card)

	var inner := MarginContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("margin_left",   44)
	inner.add_theme_constant_override("margin_right",  44)
	inner.add_theme_constant_override("margin_top",    44)
	inner.add_theme_constant_override("margin_bottom", 44)
	card.add_child(inner)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	inner.add_child(vbox)

	# PAUSED title
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Constants.COLOR_GOLD)
	vbox.add_child(title)

	# Run snapshot
	var snapshot := _make_pause_snapshot()
	vbox.add_child(snapshot)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.30, 0.25, 0.10, 0.35))
	vbox.add_child(sep)

	# RESUME (gold)
	var resume_btn := _make_action_button("RESUME", Constants.COLOR_GOLD)
	resume_btn.add_theme_color_override("font_color", Color.BLACK)
	resume_btn.add_theme_font_size_override("font_size", 34)
	resume_btn.custom_minimum_size = Vector2(0, 96)
	resume_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resume_btn.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume_btn)

	# SAVE & QUIT
	var sq_btn := _make_action_button("SAVE & QUIT", Color(0.10, 0.16, 0.10))
	sq_btn.add_theme_color_override("font_color", Constants.COLOR_TEXT)
	sq_btn.add_theme_font_size_override("font_size", 28)
	sq_btn.custom_minimum_size = Vector2(0, 82)
	sq_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sq_btn.pressed.connect(_on_save_quit_pressed)
	vbox.add_child(sq_btn)

	var sq_hint := Label.new()
	sq_hint.text = "Progress saved — resume any time"
	sq_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sq_hint.add_theme_font_size_override("font_size", 20)
	sq_hint.add_theme_color_override("font_color", Color(0.48, 0.44, 0.34))
	vbox.add_child(sq_hint)

	# START NEW RUN (danger)
	var nr_btn := _make_action_button("START NEW RUN", Color(0.28, 0.05, 0.05))
	nr_btn.add_theme_color_override("font_color", Constants.COLOR_TEXT)
	nr_btn.add_theme_font_size_override("font_size", 26)
	nr_btn.custom_minimum_size = Vector2(0, 74)
	nr_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nr_btn.pressed.connect(_on_new_run_from_pause)
	vbox.add_child(nr_btn)

	var warn := Label.new()
	warn.text = "Warning: current run will be lost"
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn.add_theme_font_size_override("font_size", 20)
	warn.add_theme_color_override("font_color", Color(0.68, 0.28, 0.28))
	vbox.add_child(warn)

	return overlay

func _make_pause_snapshot() -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 100)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.11, 0.07, 0.80)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		style.set("corner_radius_" + c, 8)
	panel.add_theme_stylebox_override("panel", style)

	var inner := MarginContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("margin_left",   16)
	inner.add_theme_constant_override("margin_right",  16)
	inner.add_theme_constant_override("margin_top",    12)
	inner.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(inner)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	inner.add_child(vb)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	vb.add_child(row)

	var spins_used := GameManager.SPINS_PER_ROUND - GameManager.spins_left
	var info := Label.new()
	info.text = "Floor %d · Round %d · Spin %d/%d" % [
		GameManager.floor_num, GameManager.round_num,
		spins_used, GameManager.SPINS_PER_ROUND
	]
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_font_size_override("font_size", 22)
	info.add_theme_color_override("font_color", Color(0.65, 0.60, 0.47))
	row.add_child(info)

	var chips := Label.new()
	chips.text = "♦ %d" % GameManager.chips
	chips.add_theme_font_size_override("font_size", 28)
	chips.add_theme_color_override("font_color", Constants.COLOR_GOLD)
	row.add_child(chips)

	# Score progress bar
	var score_pct := 0.0
	if GameManager.target > 0:
		score_pct = clampf(float(GameManager.score) / float(GameManager.target), 0.0, 1.0)

	var bar_bg := Panel.new()
	bar_bg.custom_minimum_size = Vector2(0, 14)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bb_style := StyleBoxFlat.new()
	bb_style.bg_color = Color(0.0, 0.0, 0.0, 0.35)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		bb_style.set("corner_radius_" + c, 4)
	bar_bg.add_theme_stylebox_override("panel", bb_style)
	vb.add_child(bar_bg)

	if score_pct > 0.01:
		var bar_fill := Panel.new()
		bar_fill.anchor_left   = 0.0
		bar_fill.anchor_top    = 0.0
		bar_fill.anchor_right  = score_pct
		bar_fill.anchor_bottom = 1.0
		var bf_style := StyleBoxFlat.new()
		bf_style.bg_color = Constants.COLOR_GOLD
		for c in ["top_left","top_right","bottom_left","bottom_right"]:
			bf_style.set("corner_radius_" + c, 4)
		bar_fill.add_theme_stylebox_override("panel", bf_style)
		bar_bg.add_child(bar_fill)

	var score_txt := Label.new()
	score_txt.text = "%d / %d pts" % [GameManager.score, GameManager.target]
	score_txt.add_theme_font_size_override("font_size", 11)
	score_txt.add_theme_color_override("font_color", Color(0.55, 0.50, 0.38))
	vb.add_child(score_txt)

	return panel

# ─── Chip selector ────────────────────────────────────────────────────────────

func _make_chip_button(value: int, color: Color) -> Button:
	var btn := Button.new()
	btn.text = str(value)
	btn.custom_minimum_size = Vector2(0, 70)
	btn.add_theme_font_size_override("font_size", 24)

	var normal := StyleBoxFlat.new()
	normal.bg_color = color.darkened(0.25)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		normal.set("corner_radius_" + c, 37)
	for s in ["left","right","top","bottom"]:
		normal.set("border_width_" + s, 2)
	normal.border_color = color.lightened(0.3)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = color
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", normal)

	btn.pressed.connect(func(): _select_chip(Constants.CHIP_VALUES.find(value)))
	btn.set_meta("chip_value", value)
	return btn

func _select_chip(index: int) -> void:
	_selected_chip       = Constants.CHIP_VALUES[index]
	_table.selected_chip = _selected_chip

	for i in _chip_bar.get_child_count():
		var btn := _chip_bar.get_child(i) as Button
		if not btn:
			continue
		var selected: bool = (btn.get_meta("chip_value", -1) == _selected_chip)
		var style := btn.get_theme_stylebox("normal") as StyleBoxFlat
		if style:
			style.border_color = Constants.COLOR_HIGHLIGHT if selected else Constants.CHIP_COLORS[i].lightened(0.3)
			var w := 3 if selected else 2
			for s in ["left","right","top","bottom"]:
				style.set("border_width_" + s, w)

# ─── Signal connections ───────────────────────────────────────────────────────

func _connect_signals() -> void:
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.spin_resolved.connect(_on_spin_resolved)
	GameManager.round_started.connect(_on_round_started)
	GameManager.round_won.connect(_on_round_won)
	ModManager.mod_triggered.connect(_on_mod_triggered)
	_hud.pause_pressed.connect(_on_pause_pressed)

# ─── Button handlers ──────────────────────────────────────────────────────────

func _on_spin_pressed() -> void:
	if GameManager.state != GameManager.GameState.BETTING or GameManager.current_bets.is_empty():
		return
	AudioManager.play_sfx("spin_start")
	GameManager.start_spin()
	_wheel.spin_to(_pick_winning_number())
	_spin_btn.disabled  = true
	_clear_btn.disabled = true

func _on_clear_pressed() -> void:
	GameManager.clear_all_bets()
	_table.clear_display()
	AudioManager.play_sfx("button_click")

func _on_bet_placed(bet_type: int, bet_data: Dictionary, amount: int) -> void:
	if GameManager.place_bet(bet_type, bet_data, amount):
		_table.refresh_bets(GameManager.current_bets)

func _on_begin_round_pressed() -> void:
	AudioManager.play_sfx("button_click")
	GameManager.start_round()

func _on_pause_pressed() -> void:
	if GameManager.state == GameManager.GameState.SPINNING:
		return  # can't pause mid-spin
	AudioManager.play_sfx("button_click")
	_paused = true
	_pause_panel.visible = true

func _on_resume_pressed() -> void:
	AudioManager.play_sfx("button_click")
	_paused = false
	_pause_panel.visible = false

func _on_save_quit_pressed() -> void:
	AudioManager.play_sfx("button_click")
	SaveManager.save_run()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_new_run_from_pause() -> void:
	AudioManager.play_sfx("button_click")
	SaveManager.delete_save()
	GameManager.start_new_run()
	get_tree().change_scene_to_file("res://scenes/LoreIntro.tscn")

func _on_mod_triggered(_id: String, description: String) -> void:
	_win_popup.show_mod_bonus(description)

# ─── Spin logic ───────────────────────────────────────────────────────────────

func _pick_winning_number() -> int:
	var pool := Constants.WHEEL_NUMBERS.duplicate()
	if GameManager.active_boss_rule.get("id", "") == "no_green":
		pool = pool.filter(func(n: int) -> bool: return n != 0)
	pool.shuffle()
	return pool[0]

# ─── State / signal handlers ──────────────────────────────────────────────────

func _on_wheel_spin_finished(winning_number: int) -> void:
	GameManager.resolve_spin(winning_number)

func _on_spin_resolved(winning_number: int, winnings: int, score_gained: int) -> void:
	_table.clear_display()
	_hud.update_spins(GameManager.spins_left)
	_win_popup.show_result(winning_number, winnings, score_gained)

func _on_popup_dismissed() -> void:
	GameManager.continue_after_result()

func _on_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.DEALER_INTRO:
			_dealer_intro_panel.visible = true
			_refresh_dealer_intro()
			_spin_btn.disabled  = true
			_clear_btn.disabled = true
		GameManager.GameState.BETTING:
			_dealer_intro_panel.visible = false
			_spin_btn.disabled  = false
			_clear_btn.disabled = false
			_table.refresh_bets(GameManager.current_bets)
		GameManager.GameState.SPINNING:
			_spin_btn.disabled  = true
			_clear_btn.disabled = true
		GameManager.GameState.FLOOR_TRANSITION:
			_transition_to("res://scenes/FloorTransition.tscn")
		GameManager.GameState.GAME_OVER, GameManager.GameState.WIN:
			_transition_to("res://scenes/GameOver.tscn")

func _on_round_started(info: Dictionary) -> void:
	_table.disabled_bet_types.clear()
	if info.get("boss_rule", {}).get("id", "") == "outside_only":
		_table.disabled_bet_types = [Constants.BetType.STRAIGHT]
	_table.clear_display()

func _on_round_won() -> void:
	var t := create_tween()
	t.tween_interval(0.8)
	t.tween_callback(func(): GameManager.advance_from_round_win())

# ─── Helpers ─────────────────────────────────────────────────────────────────

func _transition_to(path: String) -> void:
	var packed := load(path) as PackedScene
	if packed:
		get_tree().change_scene_to_packed(packed)

func _make_action_button(label: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 72)
	btn.add_theme_font_size_override("font_size", 30)

	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.15)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		style.set("corner_radius_" + c, 8)
	for s in ["left","right","top","bottom"]:
		style.set("border_width_" + s, 2)
	style.border_color = color.lightened(0.2)
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = color
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", style)
	return btn
