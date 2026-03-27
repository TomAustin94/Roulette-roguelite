## LoreIntro.gd — Pre-run atmospheric lore sequence (5 panels).
## SKIP button exits immediately; final panel leads to FloorTransition.
extends Control

const PANELS := [
	{
		"title": "The Year of Our Deal",
		"body":  "They say the Devil runs five casinos at the edge of the world.\n\nNobody who walks in ever walks out the same.",
	},
	{
		"title": "A Debt Unpaid",
		"body":  "You needed something. The kind only the Devil can provide.\n\nThe price? Your soul. The terms? Five floors.",
	},
	{
		"title": "House Rules",
		"body":  "Each floor has a guardian. Each guardian bends the rules.\n\nBreak the target score to advance. Run out of chips — and you're his.",
	},
	{
		"title": "The Wheel",
		"body":  "The roulette wheel does not lie. It does not cheat.\n\nBut the house always sets the odds.",
	},
	{
		"title": "Your Last Chance",
		"body":  "Win back your soul across five floors.\n\nThe Devil is waiting. The wheel is spinning.\n\nAre you ready to deal?",
	},
]

var _current := 0
var _title_lbl:   Label
var _body_lbl:    Label
var _next_btn:    Button
var _panel_lbl:   Label
var _type_tween:  Tween = null

func _ready() -> void:
	_build_ui()
	_show_panel(0)

func _build_ui() -> void:
	# ── Background ────────────────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.04)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── Gold top line ─────────────────────────────────────────────────────────
	var top_line := ColorRect.new()
	top_line.color = Constants.COLOR_GOLD
	top_line.anchor_right = 1.0
	top_line.custom_minimum_size = Vector2(0, 3)
	add_child(top_line)

	# ── SKIP button (top-right) ───────────────────────────────────────────────
	var skip_btn := Button.new()
	skip_btn.text = "SKIP ›"
	skip_btn.custom_minimum_size = Vector2(140, 52)
	skip_btn.anchor_left   = 1.0
	skip_btn.anchor_right  = 1.0
	skip_btn.anchor_top    = 0.0
	skip_btn.anchor_bottom = 0.0
	skip_btn.offset_left   = -150.0
	skip_btn.offset_top    = 8.0
	skip_btn.offset_right  = -10.0
	skip_btn.offset_bottom = 60.0
	skip_btn.add_theme_font_size_override("font_size", 15)
	skip_btn.add_theme_color_override("font_color", Color(0.55, 0.50, 0.38))
	var skip_style := StyleBoxFlat.new()
	skip_style.bg_color = Color(0, 0, 0, 0)
	for s in ["left","right","top","bottom"]:
		skip_style.set("border_width_" + s, 0)
	skip_btn.add_theme_stylebox_override("normal",  skip_style)
	skip_btn.add_theme_stylebox_override("hover",   skip_style)
	skip_btn.add_theme_stylebox_override("pressed", skip_style)
	skip_btn.pressed.connect(_on_skip)
	add_child(skip_btn)

	# ── Panel counter (top-centre) ────────────────────────────────────────────
	_panel_lbl = Label.new()
	_panel_lbl.anchor_left  = 0.5
	_panel_lbl.anchor_right = 0.5
	_panel_lbl.offset_left  = -40.0
	_panel_lbl.offset_top   = 22.0
	_panel_lbl.offset_right = 40.0
	_panel_lbl.offset_bottom = 56.0
	_panel_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel_lbl.add_theme_font_size_override("font_size", 13)
	_panel_lbl.add_theme_color_override("font_color", Color(0.42, 0.38, 0.28))
	add_child(_panel_lbl)

	# ── Centre content ────────────────────────────────────────────────────────
	var content := MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left",   100)
	content.add_theme_constant_override("margin_right",  100)
	content.add_theme_constant_override("margin_top",    110)
	content.add_theme_constant_override("margin_bottom", 170)
	add_child(content)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 40)
	content.add_child(vbox)

	# Decorative diamond
	var diamond := Label.new()
	diamond.text = "✦"
	diamond.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diamond.add_theme_font_size_override("font_size", 26)
	diamond.add_theme_color_override("font_color",
		Color(Constants.COLOR_GOLD.r, Constants.COLOR_GOLD.g, Constants.COLOR_GOLD.b, 0.45))
	vbox.add_child(diamond)

	# Title
	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 34)
	_title_lbl.add_theme_color_override("font_color", Constants.COLOR_GOLD)
	_title_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	_title_lbl.add_theme_constant_override("shadow_offset_x", 2)
	_title_lbl.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(_title_lbl)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.35, 0.30, 0.15, 0.4))
	vbox.add_child(sep)

	# Body
	_body_lbl = Label.new()
	_body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_lbl.add_theme_font_size_override("font_size", 20)
	_body_lbl.add_theme_color_override("font_color", Color(0.82, 0.78, 0.68))
	_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_body_lbl)

	# ── NEXT button (pinned to bottom) ────────────────────────────────────────
	_next_btn = Button.new()
	_next_btn.custom_minimum_size = Vector2(0, 80)
	_next_btn.anchor_left   = 0.0
	_next_btn.anchor_right  = 1.0
	_next_btn.anchor_top    = 1.0
	_next_btn.anchor_bottom = 1.0
	_next_btn.offset_left   = 60.0
	_next_btn.offset_right  = -60.0
	_next_btn.offset_top    = -110.0
	_next_btn.offset_bottom = -30.0
	_next_btn.add_theme_font_size_override("font_size", 24)
	_next_btn.add_theme_color_override("font_color", Color.BLACK)

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Constants.COLOR_GOLD.darkened(0.1)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		btn_style.set("corner_radius_" + c, 10)
	for s in ["left","right","top","bottom"]:
		btn_style.set("border_width_" + s, 2)
	btn_style.border_color = Constants.COLOR_GOLD.lightened(0.25)
	_next_btn.add_theme_stylebox_override("normal", btn_style)
	var hover_style := btn_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Constants.COLOR_GOLD
	_next_btn.add_theme_stylebox_override("hover",   hover_style)
	_next_btn.add_theme_stylebox_override("pressed", btn_style)
	_next_btn.pressed.connect(_on_next)
	add_child(_next_btn)

# ─── Panel logic ──────────────────────────────────────────────────────────────

func _show_panel(idx: int) -> void:
	var data: Dictionary = PANELS[idx]
	_panel_lbl.text  = "%d / %d" % [idx + 1, PANELS.size()]
	_title_lbl.text  = data["title"]
	_body_lbl.text   = ""
	_next_btn.text   = "BEGIN THE DEAL  →" if idx >= PANELS.size() - 1 else "NEXT  →"

	# Typewriter effect
	if _type_tween:
		_type_tween.kill()
	var full: String = data["body"]
	var chars := full.length()
	_type_tween = create_tween()
	_type_tween.tween_method(
		func(v: float): _body_lbl.text = full.substr(0, int(v)),
		0.0, float(chars),
		clampf(chars * 0.028, 0.5, 2.8)
	)

func _on_next() -> void:
	AudioManager.play_sfx("button_click")
	_current += 1
	if _current >= PANELS.size():
		_start_run()
	else:
		_show_panel(_current)

func _on_skip() -> void:
	AudioManager.play_sfx("button_click")
	_start_run()

func _start_run() -> void:
	GameManager.begin_run()
	get_tree().change_scene_to_file("res://scenes/FloorTransition.tscn")
