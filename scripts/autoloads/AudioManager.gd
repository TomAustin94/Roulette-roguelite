## AudioManager.gd — Placeholder audio manager.
## Plays programmatic tones until real audio assets are added.
extends Node

var _sfx_enabled: bool = true

# We use AudioStreamGenerator for synthetic sounds until real assets exist.
var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)

func play_sfx(sfx_name: String) -> void:
	if not _sfx_enabled:
		return
	# Placeholder — extend when audio assets are added.
	match sfx_name:
		"chip_place":
			_beep(880.0, 0.05)
		"spin_start":
			_beep(440.0, 0.15)
		"win":
			_beep(660.0, 0.3)
		"loss":
			_beep(220.0, 0.3)
		"big_win":
			_beep(880.0, 0.5)
		"button_click":
			_beep(600.0, 0.04)

func _beep(freq: float, duration: float) -> void:
	# Generate a simple sine-wave beep via AudioStreamGenerator.
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = duration
	_player.stream = stream
	_player.play()

func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled
