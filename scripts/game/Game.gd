## Game.gd — Main game scene. Assembles and orchestrates all gameplay nodes.
## Uses anchor/VBox layout so it works at any screen size.
extends Control

# ─── Child node references ────────────────────────────────────────────────────
var _hud:           HUD
var _wheel:         RouletteWheel
var _table:         BettingTable
var _spin_btn:      Button
var _clear_btn:     Button
var _chip_bar:      HBoxContainer
var _wheel_panel:   Control        # container for wheel + overlays
var _dealer:        DealerCharacter
var _win_popup:     WinPopup

# Current selected chip value
var _selected_chip: int = 5

# ─── Layout ───────────────────────────────────────────────────────────────────
const HUD_HEIGHT   := 195
const WHEEL_HEIGHT := 430
const BTN_BAR_H    := 140

func _ready() -> void:
	_build_scene()
	_connect_signals()
	# Defer so all child _ready() calls finish before signals fire.
	if GameManager.state == GameManager.GameState.MAIN_MENU:
		call_deferred("_deferred_start")
	else:
		# Resuming from a shop/floor-transition — sync UI immediately.
		call_deferred("_sync_initial_state")

func _deferred_start() -> void:
	GameManager.start_new_run()

func _sync_initial_state() -> void:
	# Called when re-entering Game scene mid-run (e.g. after shop).
	_hud.update_spins(GameManager.spins_left)
	_table.clear_display()

func _build_scene() -> void:
	# ── Background ────────────────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = Constants.COLOR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── Root VBox ─────────────────────────────────────────────────────────────
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	add_child(vbox)

	# ── HUD (fixed height) ────────────────────────────────────────────────────
	_hud = HUD.new()
	_hud.custom_minimum_size.y = HUD_HEIGHT
	_hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_hud)

	# ── Wheel panel (fixed height) ────────────────────────────────────────────
	_wheel_panel = Control.new()
	_wheel_panel.custom_minimum_size.y = WHEEL_HEIGHT
	_wheel_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_wheel_panel)

	_wheel = RouletteWheel.new()
	_wheel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wheel_panel.add_child(_wheel)
	_wheel.spin_finished.connect(_on_wheel_spin_finished)

	# ── Dealer character (left side of wheel panel) ───────────────────────────
	_dealer = DealerCharacter.new()
	_dealer.char_scale = 1.15
	# Position: left side of wheel panel, vertically centred
	_dealer.position = Vector2(160, 280)
	_wheel_panel.add_child(_dealer)

	# ── Win popup (centred over wheel, hidden until spin resolves) ────────────
	_win_popup = WinPopup.new()
	_win_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_win_popup.visible = false
	_wheel_panel.add_child(_win_popup)
	_win_popup.dismissed.connect(_on_popup_dismissed)

	# ── Betting table (fills remaining space) ─────────────────────────────────
	_table = BettingTable.new()
	_table.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_table)
	_table.bet_placed.connect(_on_bet_placed)

	# ── Bottom action bar ─────────────────────────────────────────────────────
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.03, 0.06, 0.03, 0.95)
	var btn_bar := VBoxContainer.new()
	btn_bar.custom_minimum_size.y = BTN_BAR_H
	btn_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_bar.add_theme_constant_override("separation", 6)

	var bar_wrap := Control.new()
	bar_wrap.custom_minimum_size.y = BTN_BAR_H
	bar_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_wrap.add_child(bar_bg)
	bar_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar_wrap.add_child(btn_bar)
	btn_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_child(bar_wrap)

	# Chip selector row
	_chip_bar = HBoxContainer.new()
	_chip_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_chip_bar.add_theme_constant_override("separation", 10)
	_chip_bar.custom_minimum_size.y = 68
	btn_bar.add_child(_chip_bar)

	for i in Constants.CHIP_VALUES.size():
		var val := Constants.CHIP_VALUES[i]
		var chip_btn := _make_chip_button(val, Constants.CHIP_COLORS[i])
		_chip_bar.add_child(chip_btn)

	# Spin + Clear row
	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 16)
	action_row.custom_minimum_size.y = 66
	btn_bar.add_child(action_row)

	_clear_btn = _make_button("Clear", Color(0.5, 0.12, 0.12), 130)
	action_row.add_child(_clear_btn)

	_spin_btn = _make_button("SPIN", Constants.COLOR_GOLD, 320)
	_spin_btn.add_theme_color_override("font_color", Color.BLACK)
	action_row.add_child(_spin_btn)

	_spin_btn.pressed.connect(_on_spin_pressed)
	_clear_btn.pressed.connect(_on_clear_pressed)

	_select_chip(0)

func _connect_signals() -> void:
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.spin_resolved.connect(_on_spin_resolved)
	GameManager.round_started.connect(_on_round_started)
	GameManager.round_won.connect(_on_round_won)
	ModManager.mod_triggered.connect(_on_mod_triggered)

func _on_mod_triggered(_id: String, description: String) -> void:
	_win_popup.show_mod_bonus(description)

# ─── Chip selector ────────────────────────────────────────────────────────────

func _make_chip_button(value: int, color: Color) -> Button:
	var btn := Button.new()
	btn.text = str(value)
	btn.custom_minimum_size = Vector2(74, 60)
	btn.add_theme_font_size_override("font_size", 15)

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
		var is_selected := (btn.get_meta("chip_value", -1) == _selected_chip)
		var style := btn.get_theme_stylebox("normal") as StyleBoxFlat
		if style:
			style.border_color       = (Constants.COLOR_HIGHLIGHT if is_selected else Constants.CHIP_COLORS[i].lightened(0.3))
			var w := 3 if is_selected else 2
			for s in ["left","right","top","bottom"]:
				style.set("border_width_" + s, w)

# ─── Button Handlers ─────────────────────────────────────────────────────────

func _on_spin_pressed() -> void:
	if GameManager.state != GameManager.GameState.BETTING:
		return
	if GameManager.current_bets.is_empty():
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

# ─── Spin Logic ───────────────────────────────────────────────────────────────

func _pick_winning_number() -> int:
	var pool := Constants.WHEEL_NUMBERS.duplicate()
	var boss_id := GameManager.active_boss_rule.get("id", "")
	if boss_id == "no_green":
		pool = pool.filter(func(n: int) -> bool: return n != 0)
	pool.shuffle()
	return pool[0]

# ─── State / Signal Handlers ─────────────────────────────────────────────────

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
		GameManager.GameState.BETTING:
			_spin_btn.disabled  = false
			_clear_btn.disabled = false
			_table.refresh_bets(GameManager.current_bets)
		GameManager.GameState.SPINNING:
			_spin_btn.disabled  = true
			_clear_btn.disabled = true
		GameManager.GameState.SHOP:
			_transition_to("res://scenes/Shop.tscn")
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

func _make_button(label: String, color: Color, width: int) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(width, 62)
	btn.add_theme_font_size_override("font_size", 21)

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
