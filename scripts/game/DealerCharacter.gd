## DealerCharacter.gd — Procedurally drawn dealer NPC.
## Lives in the wheel panel. Reacts to spins, changes per floor.
class_name DealerCharacter
extends Node2D

# ─── State ────────────────────────────────────────────────────────────────────
enum State { IDLE, SPIN_TENSION, WIN_REACT, LOSS_REACT, BOSS_INTRO }

# ─── Floor Style Data ─────────────────────────────────────────────────────────
const FLOOR_STYLES := {
	1: { "name": "Marcus",       "body": Color(0.12,0.08,0.22), "skin": Color(0.85,0.75,0.65), "accent": Color(0.82,0.72,0.35), "eyes": Color(0.30,0.10,0.55), "accessory": "top_hat"  },
	2: { "name": "Ironworth",    "body": Color(0.28,0.18,0.08), "skin": Color(0.72,0.62,0.48), "accent": Color(0.70,0.48,0.18), "eyes": Color(0.62,0.42,0.10), "accessory": "monocle"  },
	3: { "name": "SYST3M",       "body": Color(0.04,0.04,0.14), "skin": Color(0.08,0.75,0.88), "accent": Color(0.00,0.90,1.00), "eyes": Color(0.00,1.00,0.80), "accessory": "visor"    },
	4: { "name": "The Deep One", "body": Color(0.03,0.10,0.20), "skin": Color(0.18,0.52,0.58), "accent": Color(0.28,0.78,0.62), "eyes": Color(0.80,0.90,0.25), "accessory": "tentacles"},
	5: { "name": "Mephistos",    "body": Color(0.24,0.03,0.03), "skin": Color(0.72,0.10,0.10), "accent": Color(1.00,0.38,0.00), "eyes": Color(1.00,0.72,0.00), "accessory": "horns"    },
}

# ─── Dialogue ─────────────────────────────────────────────────────────────────
const DIALOGUE := {
	"idle": {
		1: ["Place your bets.", "The wheel awaits.", "Feeling lucky?", "Take your time."],
		2: ["The gears turn.", "Precision decides all.", "Bet wisely, friend.", "The machine is patient."],
		3: ["INPUT DETECTED.", "AWAITING BET DATA.", "CALCULATING ODDS.", "PROCESSING..."],
		4: ["The depths are patient.", "Bet. Spin. Drown.", "..."],
		5: ["We had a deal.", "Spin. Or forfeit.", "I'm enjoying this."],
	},
	"win": {
		1: ["Well played.", "Fortune smiles tonight.", "Colour me impressed.", "A fine choice."],
		2: ["Calculated!", "Efficiency noted.", "The gears favour you.", "Remarkable."],
		3: ["WIN REGISTERED.", "ANOMALY DETECTED.", "ERROR: PLAYER WON.", "UNEXPECTED."],
		4: ["The tide provides.", "Curious.", "Even the deep is generous.", "Take it."],
		5: ["...Fine.", "Enjoy it while it lasts.", "The house remembers.", "Lucky. For now."],
	},
	"loss": {
		1: ["Better luck next spin.", "The house thanks you.", "As expected.", "Pity."],
		2: ["The odds were never yours.", "Calculated loss.", "The machine is precise.", "Inevitable."],
		3: ["EXPECTED RESULT.", "LOSS PROCESSED.", "HOUSE ADVANTAGE: CONFIRMED.", "AS PREDICTED."],
		4: ["The tide takes all.", "Another offering.", "The deep is pleased.", "As foretold."],
		5: ["Ha.", "Mine.", "Come now, keep trying.", "This is delightful."],
	},
	"boss": {
		1: ["The rules have changed.", "Zero pays nothing. My rules.", "House Advantage tonight."],
		2: ["New parameters loaded.", "The odds recalibrate.", "The Brotherhood decides."],
		3: ["ACCESS RESTRICTED.", "SYSTEM OVERRIDE ACTIVE.", "DIRECT BETS: DENIED."],
		4: ["THE TIDE RISES.", "You cannot outrun the sea.", "Every spin costs more."],
		5: ["My floor. My rules.", "This is where deals end.", "Did you think you'd get here?"],
	},
}

# ─── Public settings ──────────────────────────────────────────────────────────
var char_scale: float = 1.0

# ─── Private state ────────────────────────────────────────────────────────────
var _state: State      = State.IDLE
var _floor: int        = 1
var _t:     float      = 0.0   # continuous time for procedural animation
var _state_timer: float = 0.0
var _expression: String = "neutral"

var _speech_text:  String = ""
var _speech_alpha: float  = 0.0
var _speech_tween: Tween  = null

func _ready() -> void:
	_floor = GameManager.floor_num
	GameManager.spin_resolved.connect(_on_spin_resolved)
	GameManager.round_started.connect(_on_round_started)
	GameManager.state_changed.connect(_on_state_changed)
	_delayed_idle_dialogue(randf_range(2.0, 4.5))

func _process(delta: float) -> void:
	_t           += delta
	_state_timer -= delta
	if _state_timer <= 0.0 and _state != State.IDLE:
		_enter_idle()
	queue_redraw()

# ─── Drawing ──────────────────────────────────────────────────────────────────

func _draw() -> void:
	var s   := FLOOR_STYLES.get(_floor, FLOOR_STYLES[1]) as Dictionary
	var sc  := char_scale
	var bob := Vector2(0.0, sin(_t * 1.8) * 3.0 * sc)

	_draw_body_and_arms(bob, s, sc)
	_draw_head_and_face(bob, s, sc)
	_draw_accessory(bob, s, sc)
	if _speech_alpha > 0.01:
		_draw_speech_bubble(bob, sc)

func _draw_body_and_arms(bob: Vector2, s: Dictionary, sc: float) -> void:
	var body_col:   Color = s.body
	var accent_col: Color = s.accent

	# ── Arms ──────────────────────────────────────────────────────────────────
	var lshoulder := bob + Vector2(-22 * sc, -34 * sc)
	var rshoulder := bob + Vector2( 22 * sc, -34 * sc)
	var lelbow: Vector2; var relbow: Vector2
	var lhand: Vector2;  var rhand: Vector2

	match _state:
		State.WIN_REACT:
			lelbow = lshoulder + Vector2(-20 * sc, -22 * sc)
			relbow = rshoulder + Vector2( 20 * sc, -22 * sc)
			lhand  = lelbow    + Vector2(-10 * sc, -16 * sc)
			rhand  = relbow    + Vector2( 10 * sc, -16 * sc)
		State.LOSS_REACT:
			lelbow = lshoulder + Vector2(-18 * sc,  6 * sc)
			relbow = rshoulder + Vector2( 18 * sc,  6 * sc)
			lhand  = lelbow    + Vector2( -6 * sc, 10 * sc)
			rhand  = relbow    + Vector2(  6 * sc, 10 * sc)
		State.SPIN_TENSION:
			var lean := sin(_t * 4.0) * 2.0 * sc
			lelbow = lshoulder + Vector2(-12 * sc, 12 * sc + lean)
			relbow = rshoulder + Vector2( 12 * sc, 12 * sc - lean)
			lhand  = lelbow    + Vector2( -4 * sc, 14 * sc)
			rhand  = relbow    + Vector2(  4 * sc, 14 * sc)
		State.BOSS_INTRO:
			lelbow = lshoulder + Vector2(-24 * sc, -10 * sc)
			relbow = rshoulder + Vector2( 24 * sc, -10 * sc)
			lhand  = lelbow    + Vector2(-12 * sc,  4 * sc)
			rhand  = relbow    + Vector2( 12 * sc,  4 * sc)
		_:  # IDLE — gentle swing
			var sw := sin(_t * 1.1) * 4.0 * sc
			lelbow = lshoulder + Vector2(-15 * sc, 10 * sc + sw)
			relbow = rshoulder + Vector2( 15 * sc, 10 * sc - sw)
			lhand  = lelbow    + Vector2( -4 * sc, 12 * sc)
			rhand  = relbow    + Vector2(  4 * sc, 12 * sc)

	draw_line(lshoulder, lelbow, body_col, 8 * sc, true)
	draw_line(lelbow,    lhand,  body_col, 6 * sc, true)
	draw_line(rshoulder, relbow, body_col, 8 * sc, true)
	draw_line(relbow,    rhand,  body_col, 6 * sc, true)
	draw_circle(lhand, 5 * sc, accent_col)
	draw_circle(rhand, 5 * sc, accent_col)

	# ── Torso ─────────────────────────────────────────────────────────────────
	_fill_rounded_rect(Rect2(-22 * sc + bob.x, -44 * sc + bob.y, 44 * sc, 52 * sc), body_col, 6 * sc)

	# ── Collar / tie ──────────────────────────────────────────────────────────
	var collar := PackedVector2Array([
		bob + Vector2(-8 * sc, -43 * sc),
		bob + Vector2( 0,      -36 * sc),
		bob + Vector2( 8 * sc, -43 * sc),
	])
	_fill_polygon(collar, accent_col.lightened(0.25))

	if _floor == 3:
		# SYST3M — glowing chest panel
		_fill_rounded_rect(Rect2(-7 * sc + bob.x, -34 * sc + bob.y, 14 * sc, 18 * sc), Color(0.0, 0.4, 0.55), 3 * sc)
		var scan := -30 * sc + bob.y + fmod(_t * 14.0, 16.0) * sc
		draw_line(Vector2(-5 * sc + bob.x, scan), Vector2(5 * sc + bob.x, scan), Color(0.0, 1.0, 0.8, 0.5), sc)
	elif _floor == 5:
		# Devil — flame sigil
		draw_circle(bob + Vector2(0, -24 * sc), 5 * sc, Color(1.0, 0.3, 0.0))
	else:
		# Classic tie
		var tie := PackedVector2Array([
			bob + Vector2( 0,       -36 * sc),
			bob + Vector2(-4 * sc, -26 * sc),
			bob + Vector2( 0,       -8 * sc),
			bob + Vector2( 4 * sc, -26 * sc),
		])
		_fill_polygon(tie, accent_col)

	# ── Neck ──────────────────────────────────────────────────────────────────
	var skin_col: Color = s.skin
	draw_rect(Rect2(-5 * sc + bob.x, -44 * sc + bob.y, 10 * sc, 10 * sc), skin_col)

func _draw_head_and_face(bob: Vector2, s: Dictionary, sc: float) -> void:
	var skin_col: Color = s.skin
	var eye_col:  Color = s.eyes
	var hc := bob + Vector2(0, -62 * sc)   # head centre

	# Head
	draw_circle(hc, 22 * sc, skin_col)

	# ── Eyes ─────────────────────────────────────────────────────────────────
	var ex := 8 * sc
	var ey := hc.y - 3 * sc
	match _expression:
		"happy":
			draw_arc(Vector2(hc.x - ex, ey - 3 * sc), 5 * sc, PI, TAU,        8, eye_col, 2.0 * sc)
			draw_arc(Vector2(hc.x + ex, ey - 3 * sc), 5 * sc, PI, TAU,        8, eye_col, 2.0 * sc)
		"surprised":
			draw_circle(Vector2(hc.x - ex, ey), 5.5 * sc, eye_col)
			draw_circle(Vector2(hc.x + ex, ey), 5.5 * sc, eye_col)
			draw_circle(Vector2(hc.x - ex, ey), 2.5 * sc, Color.BLACK)
			draw_circle(Vector2(hc.x + ex, ey), 2.5 * sc, Color.BLACK)
		"menacing":
			# Inward-angled brows + pupils
			draw_line(Vector2(hc.x - ex - 4 * sc, ey - 4 * sc), Vector2(hc.x - ex + 4 * sc, ey), eye_col, 2.5 * sc)
			draw_line(Vector2(hc.x + ex - 4 * sc, ey),          Vector2(hc.x + ex + 4 * sc, ey - 4 * sc), eye_col, 2.5 * sc)
			draw_circle(Vector2(hc.x - ex, ey + sc), 3.5 * sc, eye_col)
			draw_circle(Vector2(hc.x + ex, ey + sc), 3.5 * sc, eye_col)
			draw_circle(Vector2(hc.x - ex, ey + sc), 1.5 * sc, Color.BLACK)
			draw_circle(Vector2(hc.x + ex, ey + sc), 1.5 * sc, Color.BLACK)
		"smug":
			draw_circle(Vector2(hc.x - ex, ey), 3.5 * sc, eye_col)
			draw_circle(Vector2(hc.x + ex, ey), 4.0 * sc, eye_col)
			draw_circle(Vector2(hc.x - ex, ey), 1.5 * sc, Color.BLACK)
			draw_circle(Vector2(hc.x + ex, ey), 2.0 * sc, Color.BLACK)
		_:  # neutral
			draw_circle(Vector2(hc.x - ex, ey), 3.5 * sc, eye_col)
			draw_circle(Vector2(hc.x + ex, ey), 3.5 * sc, eye_col)
			draw_circle(Vector2(hc.x - ex, ey), 1.5 * sc, Color.BLACK)
			draw_circle(Vector2(hc.x + ex, ey), 1.5 * sc, Color.BLACK)

	# ── Mouth ─────────────────────────────────────────────────────────────────
	var mc := hc + Vector2(0, 8 * sc)
	match _expression:
		"happy":
			draw_arc(mc + Vector2(0, -4 * sc), 6 * sc, 0.15, PI - 0.15, 12, Color(0.12, 0.04, 0.04), 2.0 * sc)
		"smug":
			draw_line(mc + Vector2(-6 * sc, 0), mc + Vector2(4 * sc, -3 * sc), Color(0.12, 0.04, 0.04), 2.0 * sc)
		"surprised":
			draw_circle(mc, 4 * sc, Color(0.12, 0.04, 0.04))
		"menacing":
			var grin := PackedVector2Array([
				mc + Vector2(-7 * sc,  0),
				mc + Vector2(-3 * sc, -4 * sc),
				mc + Vector2( 0,       0),
				mc + Vector2( 3 * sc, -4 * sc),
				mc + Vector2( 7 * sc,  0),
			])
			draw_polyline(grin, Color(0.12, 0.04, 0.04), 2.0 * sc)
		_:
			draw_line(mc + Vector2(-5 * sc, 0), mc + Vector2(5 * sc, 0), Color(0.12, 0.04, 0.04), 1.5 * sc)

func _draw_accessory(bob: Vector2, s: Dictionary, sc: float) -> void:
	var accent: Color = s.accent
	var body:   Color = s.body
	var htop := bob + Vector2(0, -84 * sc)
	var hc   := bob + Vector2(0, -62 * sc)

	match s.get("accessory", ""):
		"top_hat":
			_fill_rounded_rect(Rect2(-26 * sc + bob.x, -88 * sc + bob.y, 52 * sc, 6 * sc), body.darkened(0.25), 2 * sc)
			_fill_rounded_rect(Rect2(-16 * sc + bob.x, -116 * sc + bob.y, 32 * sc, 30 * sc), body.darkened(0.15), 3 * sc)
			draw_rect(Rect2(-16 * sc + bob.x, -94 * sc + bob.y, 32 * sc, 7 * sc), accent)

		"monocle":
			draw_arc(hc + Vector2(8 * sc, -2 * sc), 9 * sc, 0.0, TAU, 24, accent, 2.0)
			draw_line(hc + Vector2(17 * sc, 6 * sc), hc + Vector2(22 * sc, 14 * sc), accent, 1.0)
			# Brass gear on lapel
			var gc := bob + Vector2(-14 * sc, -28 * sc)
			draw_circle(gc, 5 * sc, accent.darkened(0.2))
			for gi in 8:
				var ga := TAU * gi / 8.0
				draw_circle(gc + Vector2(cos(ga), sin(ga)) * 5.5 * sc, 1.5 * sc, accent)

		"visor":
			_fill_rounded_rect(Rect2(-20 * sc + bob.x, -71 * sc + bob.y, 40 * sc, 12 * sc), accent.darkened(0.4), 3 * sc)
			_fill_rounded_rect(Rect2(-18 * sc + bob.x, -70 * sc + bob.y, 36 * sc, 9 * sc),  Color(accent.r, accent.g, accent.b, 0.65), 2 * sc)
			# Scrolling scan line
			var scan_y := -69 * sc + bob.y + fmod(_t * 16.0, 8.0) * sc
			draw_line(Vector2(-17 * sc + bob.x, scan_y), Vector2(17 * sc + bob.x, scan_y),
					  Color(1.0, 1.0, 1.0, 0.45), sc)

		"tentacles":
			for side in [-1, 1]:
				var base := bob + Vector2(side * 18 * sc, -48 * sc)
				var mid  := base + Vector2(side * 14 * sc * cos(_t * 2.0 + side), -12 * sc + sin(_t * 2.0) * 5 * sc)
				var tip  := mid  + Vector2(side * 8  * sc, 10 * sc + cos(_t * 2.6 + side) * 6 * sc)
				draw_line(base, mid, accent, 5 * sc, true)
				draw_line(mid,  tip, accent.darkened(0.2), 3 * sc, true)
				draw_circle(tip, 3 * sc, accent.lightened(0.3))

		"horns":
			for side in [-1, 1]:
				var hbase := bob + Vector2(side * 14 * sc, -82 * sc)
				var hmid  := hbase + Vector2(side * 10 * sc, -14 * sc)
				var htip2 := hmid  + Vector2(side *  5 * sc, -10 * sc)
				draw_line(hbase, hmid,  accent, 6 * sc, true)
				draw_line(hmid,  htip2, accent.darkened(0.1), 4 * sc, true)
				draw_circle(htip2, 2.5 * sc, accent.lightened(0.2))
			# Tail
			var tail := PackedVector2Array([
				bob + Vector2( 20 * sc, 8 * sc),
				bob + Vector2( 32 * sc, 18 * sc + sin(_t * 3.2) * 5 * sc),
				bob + Vector2( 26 * sc, 24 * sc),
			])
			draw_polyline(tail, accent, 3 * sc)

func _draw_speech_bubble(bob: Vector2, sc: float) -> void:
	var font  := ThemeDB.fallback_font
	var fsize := int(clamp(12.0 * sc, 10, 15))
	var ts    := font.get_string_size(_speech_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var pad   := 9.0 * sc
	var bw    := ts.x + pad * 2.0
	var bh    := ts.y + pad * 1.4
	var bx    := 30.0 * sc   # to the right of the character
	var by    := -80.0 * sc + bob.y - bh * 0.5
	var a     := _speech_alpha

	# Shadow
	_fill_rounded_rect(Rect2(bx + 2, by + 2, bw, bh), Color(0, 0, 0, 0.28 * a), 7 * sc)
	# Bubble
	_fill_rounded_rect(Rect2(bx, by, bw, bh), Color(0.94, 0.91, 0.84, 0.92 * a), 7 * sc)
	# Tail
	var tail := PackedVector2Array([
		Vector2(bx,            by + bh * 0.5),
		Vector2(bx - 8.0 * sc, by + bh * 0.38),
		Vector2(bx - 8.0 * sc, by + bh * 0.62),
	])
	_fill_polygon(tail, Color(0.94, 0.91, 0.84, 0.92 * a))
	# Text
	draw_string(font, Vector2(bx + pad, by + pad + ts.y * 0.75),
				_speech_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize,
				Color(0.14, 0.08, 0.06, a))

# ─── Drawing Helpers ─────────────────────────────────────────────────────────

func _fill_rounded_rect(rect: Rect2, color: Color, radius: float) -> void:
	var r  := min(radius, rect.size.x * 0.5, rect.size.y * 0.5)
	var s  := 6
	var pts := PackedVector2Array()
	var corners := [
		Vector2(rect.position.x + r,              rect.position.y + r),
		Vector2(rect.position.x + rect.size.x - r, rect.position.y + r),
		Vector2(rect.position.x + rect.size.x - r, rect.position.y + rect.size.y - r),
		Vector2(rect.position.x + r,              rect.position.y + rect.size.y - r),
	]
	var start_angles := [PI, -PI * 0.5, 0.0, PI * 0.5]
	for i in 4:
		for j in range(s + 1):
			var a := start_angles[i] + (PI * 0.5) * j / s
			pts.append(corners[i] + Vector2(cos(a), sin(a)) * r)
	var colors := PackedColorArray()
	for _i in pts.size():
		colors.append(color)
	draw_polygon(pts, colors)

func _fill_polygon(pts: PackedVector2Array, color: Color) -> void:
	var colors := PackedColorArray()
	for _i in pts.size():
		colors.append(color)
	draw_polygon(pts, colors)

# ─── State Machine ────────────────────────────────────────────────────────────

func _enter_idle() -> void:
	_state      = State.IDLE
	_expression = "neutral" if _floor < 5 else "menacing"
	_state_timer = 9999.0
	_delayed_idle_dialogue(randf_range(4.5, 9.0))

func _set_state(s: State) -> void:
	_state = s
	match s:
		State.WIN_REACT:
			_expression  = "happy"
			_state_timer = 2.8
			_say("win")
		State.LOSS_REACT:
			_expression  = "smug" if _floor < 5 else "menacing"
			_state_timer = 2.8
			_say("loss")
		State.SPIN_TENSION:
			_expression  = "neutral"
			_state_timer = 7.0
		State.BOSS_INTRO:
			_expression  = "menacing"
			_state_timer = 4.5
			_say("boss")
		_:
			_enter_idle()

func _say(category: String) -> void:
	var lines: Array = DIALOGUE.get(category, {}).get(_floor, ["..."])
	_speech_text = lines[randi() % lines.size()]
	if _speech_tween:
		_speech_tween.kill()
	_speech_alpha = 1.0
	_speech_tween = create_tween()
	_speech_tween.tween_interval(3.0)
	_speech_tween.tween_property(self, "_speech_alpha", 0.0, 0.6)

func _delayed_idle_dialogue(delay: float) -> void:
	var t := create_tween()
	t.tween_interval(delay)
	t.tween_callback(func():
		if _state == State.IDLE:
			_say("idle")
			_delayed_idle_dialogue(randf_range(6.0, 12.0))
	)

# ─── Signal Handlers ─────────────────────────────────────────────────────────

func _on_spin_resolved(_number: int, winnings: int, _score: int) -> void:
	_floor = GameManager.floor_num
	if winnings > 0:
		_set_state(State.WIN_REACT)
	else:
		_set_state(State.LOSS_REACT)

func _on_round_started(info: Dictionary) -> void:
	_floor = info.get("floor", 1)
	_enter_idle()
	if info.get("is_boss", false):
		var t := create_tween()
		t.tween_interval(0.9)
		t.tween_callback(func(): _set_state(State.BOSS_INTRO))

func _on_state_changed(new_state: GameManager.GameState) -> void:
	if new_state == GameManager.GameState.SPINNING:
		_set_state(State.SPIN_TENSION)
