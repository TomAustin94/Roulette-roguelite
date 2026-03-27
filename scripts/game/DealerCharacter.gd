## DealerCharacter.gd — Sprite-based dealer NPC.
## Loads PNG textures from assets/sprites/dealer/.
## Falls back to procedural rendering if sprites are missing.
## Speech bubble is always drawn procedurally on top.
class_name DealerCharacter
extends Node2D

# ─── State ────────────────────────────────────────────────────────────────────
enum State { IDLE, SPIN_TENSION, WIN_REACT, LOSS_REACT, BOSS_INTRO }

# ─── Sprite paths (one set per floor; floor 1 sprites are shared fallbacks) ───
const SPRITE_PATHS := {
	"idle":    "res://assets/sprites/dealer/dealer_idle.png",
	"win":     "res://assets/sprites/dealer/dealer_win.png",
	"loss":    "res://assets/sprites/dealer/dealer_loss.png",
	"boss":    "res://assets/sprites/dealer/dealer_boss.png",
	"tension": "res://assets/sprites/dealer/dealer_tension.png",
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
var _state:       State   = State.IDLE
var _floor:       int     = 1
var _t:           float   = 0.0
var _state_timer: float   = 0.0

var _speech_text:  String = ""
var _speech_alpha: float  = 0.0
var _speech_tween: Tween  = null

# ─── Sprite node ──────────────────────────────────────────────────────────────
var _sprite:      Sprite2D = null
var _textures:    Dictionary = {}   # key → ImageTexture
var _using_sprites: bool = false

func _ready() -> void:
	_floor = GameManager.floor_num
	_load_textures()
	_build_sprite()
	GameManager.spin_resolved.connect(_on_spin_resolved)
	GameManager.round_started.connect(_on_round_started)
	GameManager.state_changed.connect(_on_state_changed)
	_delayed_idle_dialogue(randf_range(2.0, 4.5))

func _load_textures() -> void:
	for key in SPRITE_PATHS:
		var path: String = SPRITE_PATHS[key]
		if ResourceLoader.exists(path):
			var tex = load(path) as Texture2D
			if tex:
				_textures[key] = tex
	_using_sprites = _textures.size() > 0

func _build_sprite() -> void:
	if not _using_sprites:
		return
	_sprite = Sprite2D.new()
	_sprite.centered = true
	# Scale sprite to roughly match the procedural character size
	var target_height := 120.0 * char_scale
	var tex: Texture2D = _textures.get("idle")
	if tex and tex.get_height() > 0:
		var s := target_height / tex.get_height()
		_sprite.scale = Vector2(s, s)
	_sprite.position = Vector2(0, -60 * char_scale)
	_sprite.texture = _textures.get("idle")
	add_child(_sprite)

func _set_sprite_state(key: String) -> void:
	if _sprite and _textures.has(key):
		_sprite.texture = _textures[key]
	elif _sprite and _textures.has("idle"):
		_sprite.texture = _textures["idle"]

func _process(delta: float) -> void:
	_t           += delta
	_state_timer -= delta
	if _state_timer <= 0.0 and _state != State.IDLE:
		_enter_idle()
	# Gentle bob animation on the sprite
	if _sprite:
		_sprite.position.y = -60.0 * char_scale + sin(_t * 1.8) * 3.0 * char_scale
	queue_redraw()

# ─── Drawing (speech bubble only when using sprites; full procedural fallback) ─

func _draw() -> void:
	if _using_sprites:
		if _speech_alpha > 0.01:
			_draw_speech_bubble(Vector2.ZERO, char_scale)
	else:
		_draw_procedural()

func _draw_procedural() -> void:
	# Kept as fallback when no sprites are found.
	# Uses a simplified single-colour silhouette so the game still runs.
	var sc  := char_scale
	var col := Color(0.12, 0.08, 0.22)
	var skin := Color(0.85, 0.75, 0.65)
	var acc  := Color(0.82, 0.72, 0.35)
	var bob  := Vector2(0.0, sin(_t * 1.8) * 3.0 * sc)

	# Body
	_fill_rounded_rect(Rect2(-22 * sc + bob.x, -44 * sc + bob.y, 44 * sc, 52 * sc), col, 6 * sc)
	# Head
	draw_circle(bob + Vector2(0, -62 * sc), 22 * sc, skin)
	# Hat brim
	_fill_rounded_rect(Rect2(-26 * sc + bob.x, -88 * sc + bob.y, 52 * sc, 6 * sc), col.darkened(0.25), 2 * sc)
	# Hat crown
	_fill_rounded_rect(Rect2(-16 * sc + bob.x, -116 * sc + bob.y, 32 * sc, 30 * sc), col.darkened(0.15), 3 * sc)
	# Hat band
	draw_rect(Rect2(-16 * sc + bob.x, -94 * sc + bob.y, 32 * sc, 7 * sc), acc)
	# Eyes
	var ey := bob.y - 65 * sc
	draw_circle(Vector2(-8 * sc, ey), 3.5 * sc, Color(0.3, 0.1, 0.55))
	draw_circle(Vector2( 8 * sc, ey), 3.5 * sc, Color(0.3, 0.1, 0.55))

	if _speech_alpha > 0.01:
		_draw_speech_bubble(bob, sc)

func _draw_speech_bubble(bob: Vector2, sc: float) -> void:
	var font  := ThemeDB.fallback_font
	var fsize := int(clamp(12.0 * sc, 10, 15))
	var ts    := font.get_string_size(_speech_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var pad   := 9.0 * sc
	var bw    := ts.x + pad * 2.0
	var bh    := ts.y + pad * 1.4
	var bx    := 30.0 * sc
	var by    := -80.0 * sc + bob.y - bh * 0.5
	var a     := _speech_alpha

	_fill_rounded_rect(Rect2(bx + 2, by + 2, bw, bh), Color(0, 0, 0, 0.28 * a), 7 * sc)
	_fill_rounded_rect(Rect2(bx, by, bw, bh), Color(0.94, 0.91, 0.84, 0.92 * a), 7 * sc)
	var tail := PackedVector2Array([
		Vector2(bx,            by + bh * 0.5),
		Vector2(bx - 8.0 * sc, by + bh * 0.38),
		Vector2(bx - 8.0 * sc, by + bh * 0.62),
	])
	_fill_polygon(tail, Color(0.94, 0.91, 0.84, 0.92 * a))
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
	_state       = State.IDLE
	_state_timer = 9999.0
	_set_sprite_state("idle")
	_delayed_idle_dialogue(randf_range(4.5, 9.0))

func _set_state(s: State) -> void:
	_state = s
	match s:
		State.WIN_REACT:
			_state_timer = 2.8
			_set_sprite_state("win")
			_say("win")
		State.LOSS_REACT:
			_state_timer = 2.8
			_set_sprite_state("loss")
			_say("loss")
		State.SPIN_TENSION:
			_state_timer = 7.0
			_set_sprite_state("tension")
		State.BOSS_INTRO:
			_state_timer = 4.5
			_set_sprite_state("boss")
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
