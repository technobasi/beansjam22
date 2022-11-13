extends Node2D
class_name TutorialPlayer

export(String) var typeToListenFor: String

var played = false
onready var player := $AudioStreamPlayer2D
func playSound() -> void:
	if !played:
		player.play()
		played = true
	


func _on_Game_first_input(type) -> void:
	if(type == typeToListenFor):
		playSound()
		
func is_playing() -> bool:
	return player.playing
