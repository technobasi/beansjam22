extends Node2D
class_name FullFail

#*schnarch* *aufwachend* Oh nein wir haben den ganzen Beansjam verschlafen *traurig*
#Beim nächsten mal solltest du dich mehr in die Gespräche einbringen, Tasten hauen und die Maus bewegen.
var tutorial_ending_sound = preload("res://sounds/tutorial/Ending.wav")
onready var streamPlayer = $endPlayer

var atleastOneInput = false

func add_input():
	atleastOneInput = true


func play_tutorial_ending(endTimeInSeconds: int):
	print(endTimeInSeconds)
	if !atleastOneInput || endTimeInSeconds <= 35:
		streamPlayer.stream = tutorial_ending_sound
		streamPlayer.play()
