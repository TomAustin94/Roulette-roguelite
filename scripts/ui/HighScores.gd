## HighScores.gd — Displays top-5 run scores with medal styling.
extends Control

# Medal colours: gold, silver, bronze, then plain
const MEDAL_COLORS: Array[Color] = [
	Color(0.90, 0.75, 0.20),   # 1st — gold
	Color(0.75, 0.75, 0.78),   # 2nd — silver
	Color(0.80, 0.50, 0.22),   # 3rd — bronze
	Color(0.58, 0.55, 0.48),   # 4th
	Color(0.58, 0.55, 0.48),   # 5th
]

const MEDAL_LABELS := ["#1", "#2", "#3", "#4", "#5"]
const CROWN_SYMBOL := "♛"

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

	# ── Content ───────────────────────────────────────────────────────────────
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",  50)
	margin.add_theme_constant_override("margin_right", 50)
	margin.add_theme_constant_override("margin_top",   20)
	margin.add_theme_constant_override("margin_bottom",30)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	# ── Header ────────────────────────────────────────────────────────────────
	var header := Label.new()
	header.text = "HIGH SCORES"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 42)
	header.add_theme_color_override("font_color", Constants.COLOR_GOLD)
	header.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	header.add_theme_constant_override("shadow_offset_x", 3)
	header.add_theme_constant_override("shadow_offset_y", 3)
	vbox.add_child(header)

	var sub := Label.new()
	sub.text = "THE DEVIL'S DEAL  ·  TOP 5 RUNS"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.55, 0.50, 0.38))
	vbox.add_child(sub)

	# ── Column headers ────────────────────────────────────────────────────────
	var col_hdr := _make_column_header()
	vbox.add_child(col_hdr)

	var hdr_sep := HSeparator.new()
	hdr_sep.add_theme_color_override("color", Color(0.35, 0.30, 0.14, 0.5))
	vbox.add_child(hdr_sep)

	# ── Score rows ────────────────────────────────────────────────────────────
	var scores := HighScoreManager.get_scores()

	if scores.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No runs completed yet.\nPlay your first game to record a score."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 18)
		empty_lbl.add_theme_color_override("font_color", Color(0.50, 0.46, 0.36))
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		var empty_gap := Control.new()
		empty_gap.custom_minimum_size = Vector2(0, 60)
		vbox.add_child(empty_gap)
		vbox.add_child(empty_lbl)
	else:
		for i in scores.size():
			var row := _make_score_row(i, scores[i])
			vbox.add_child(row)
			if i < scores.size() - 1:
				var row_sep := HSeparator.new()
				row_sep.add_theme_color_override("color", Color(0.20, 0.18, 0.10, 0.30))
				vbox.add_child(row_sep)

	# ── Spacer ────────────────────────────────────────────────────────────────
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# ── Back button ───────────────────────────────────────────────────────────
	var back_btn := _make_button("← BACK TO MENU", Color(0.08, 0.12, 0.08))
	back_btn.pressed.connect(_on_back)
	vbox.add_child(back_btn)

# ─── Column header row ────────────────────────────────────────────────────────

func _make_column_header() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)

	var headers := [["#",      48,  Color(0.50, 0.46, 0.36)],
	                ["DATE",   140, Color(0.50, 0.46, 0.36)],
	                ["FLOOR",  80,  Color(0.50, 0.46, 0.36)],
	                ["SCORE",  0,   Color(0.50, 0.46, 0.36)],
	                ["RESULT", 90,  Color(0.50, 0.46, 0.36)]]

	for h in headers:
		var lbl := Label.new()
		lbl.text = h[0]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", h[2])
		if h[1] == 0:
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			lbl.custom_minimum_size = Vector2(h[1], 0)
		row.add_child(lbl)

	return row

# ─── Score row ────────────────────────────────────────────────────────────────

func _make_score_row(rank: int, entry: Dictionary) -> Panel:
	var medal_color := MEDAL_COLORS[rank] if rank < MEDAL_COLORS.size() else Color(0.55, 0.50, 0.40)
	var is_first    := (rank == 0)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 70)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.08, 0.85) if is_first else Color(0.05, 0.08, 0.05, 0.50)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		style.set("corner_radius_" + c, 8)
	if is_first:
		for s in ["left","right","top","bottom"]:
			style.set("border_width_" + s, 1)
		style.border_color = Color(medal_color.r, medal_color.g, medal_color.b, 0.50)
	panel.add_theme_stylebox_override("panel", style)

	var inner := MarginContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("margin_left",   10)
	inner.add_theme_constant_override("margin_right",  10)
	inner.add_theme_constant_override("margin_top",    10)
	inner.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(inner)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	inner.add_child(row)

	# Rank / medal
	var rank_col := VBoxContainer.new()
	rank_col.custom_minimum_size = Vector2(48, 0)
	rank_col.add_theme_constant_override("separation", 2)
	row.add_child(rank_col)

	if is_first:
		var crown := Label.new()
		crown.text = CROWN_SYMBOL
		crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		crown.add_theme_font_size_override("font_size", 14)
		crown.add_theme_color_override("font_color", medal_color)
		rank_col.add_child(crown)

	var rank_lbl := Label.new()
	rank_lbl.text = MEDAL_LABELS[rank] if rank < MEDAL_LABELS.size() else "#%d" % (rank + 1)
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_lbl.add_theme_font_size_override("font_size", 15)
	rank_lbl.add_theme_color_override("font_color", medal_color)
	rank_col.add_child(rank_lbl)

	# Date
	var date_lbl := Label.new()
	date_lbl.text = entry.get("date", "—")
	date_lbl.custom_minimum_size = Vector2(140, 0)
	date_lbl.add_theme_font_size_override("font_size", 13)
	date_lbl.add_theme_color_override("font_color", Color(0.58, 0.53, 0.42))
	date_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(date_lbl)

	# Floor reached
	var floor_lbl := Label.new()
	floor_lbl.text = "F%d-R%d" % [entry.get("floor_num", 1), entry.get("round_num", 1)]
	floor_lbl.custom_minimum_size = Vector2(80, 0)
	floor_lbl.add_theme_font_size_override("font_size", 14)
	floor_lbl.add_theme_color_override("font_color", Color(0.72, 0.67, 0.54))
	floor_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(floor_lbl)

	# Score
	var score_lbl := Label.new()
	score_lbl.text = str(entry.get("score", 0))
	score_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_lbl.add_theme_font_size_override("font_size", 22)
	score_lbl.add_theme_color_override("font_color", medal_color)
	score_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(score_lbl)

	# Result (won/lost)
	var result_lbl := Label.new()
	var won: bool = entry.get("won", false)
	result_lbl.text = "WIN" if won else "LOSS"
	result_lbl.custom_minimum_size = Vector2(90, 0)
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	result_lbl.add_theme_font_size_override("font_size", 14)
	result_lbl.add_theme_color_override("font_color",
		Color(0.40, 0.82, 0.42) if won else Color(0.78, 0.35, 0.35))
	result_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(result_lbl)

	return panel

# ─── Navigation ───────────────────────────────────────────────────────────────

func _on_back() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# ─── Button factory ───────────────────────────────────────────────────────────

func _make_button(label: String, bg: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 72)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Constants.COLOR_TEXT)

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
