extends Node2D
signal game_start

onready var player = $AudioStreamPlayer2D

func _ready() -> void:
	player.play()

func _on_AudioStreamPlayer2D_finished() -> void:
	emit_signal("game_start")
