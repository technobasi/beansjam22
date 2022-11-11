extends Node2D


onready var background := $CanvasLayer/Background
onready var sleepTimer := $SleepTimer
onready var idleSoundPlayer := $IdleSoundPlayer
onready var endGameLabel := $CanvasLayer/EndGame
onready var idleSoundTimer := $IdleSoundTimer

var sleepMeter := 1.0
export(float) var sleepDecay = -1
export(float) var sleepTypeBoost = 1
export(float) var mouseMovementBoost = 0.001
var keywords := {
	"COLA": {
		"value": 10
	},
	"KAFFEE": {
		"value": 15
	},
	"UpUpDownDownLeftRightLeftRightBA" : {
		"value": 100
	}
} 

var sleepMode := {
	"awake": {
		"max": 100,
		"min": 66,
		"color": Color.gold,
		"idleSounds": [
			preload("res://sounds/idle/awake/typing.wav")
		]
	},
	"sleepy": {
		"color": Color.orangered,
		"max": 66,
		"min": 33,
		"idleSounds": [
			preload("res://sounds/idle/sleepy/Yawn.wav")
		]
	},
	"almost_sleeping": {
		"color": Color.darkorange,
		"max": 33,
		"min":0,
		"idleSounds": [
			
		]
	},
	"sleeping": {
		"color": Color.black,
		"max": 0,
		"min": -1,
		"idleSounds": [
			
		]
	}
}

var textBuffer := ""
var startTime: Dictionary 
func _ready() -> void:
	startTime = Time.get_datetime_dict_from_system()
	updateSleepMeter(0)
	
func determineSleepMode() -> String:
	for k in sleepMode:
		if(sleepMeter > sleepMode[k].min && sleepMeter <= sleepMode[k].max):
			return k
	
	if sleepMeter > sleepMode.awake.max:
		return "awake"
	return "oops"

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			textBuffer += OS.get_scancode_string(event.scancode)
			checkTextBufferForKeywords()
			print(textBuffer)
			updateSleepMeter(sleepTypeBoost)
	if event is InputEventMouseMotion:
		updateSleepMeter(mouseMovementBoost)
	if event is InputEventMouseButton:
		updateSleepMeter(sleepTypeBoost)
		
	
func checkTextBufferForKeywords():
	var matchFound: bool = false
	for k in keywords:
		if k in textBuffer:
			sleepMeter+= keywords[k].value
	if(matchFound):
		textBuffer = ""
		
func _on_SleepTimer_timeout():
	updateSleepMeter(sleepDecay)
	if(sleepMeter <= 0.0):
		finishGame()
	
func finishGame() -> void:
	sleepTimer.stop()
	idleSoundPlayer.stop()
	idleSoundTimer.stop()
	var endTime = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
	endGameLabel.text = "Game Jam over!\n Du hast " + str(endTime - Time.get_unix_time_from_datetime_dict(startTime)) + " Sekunden durchgehalten!"
	endGameLabel.show()
	
	
	
func updateSleepMeter(updateValue: float) -> void:
	sleepMeter += updateValue
	print(sleepMeter)
	var sleepModeValue = determineSleepMode()
	background.color = sleepMode[sleepModeValue].color


func _on_IdleSoundTimer_timeout():
	var sleepModeValue = determineSleepMode()
	sleepMode[sleepModeValue].idleSounds.shuffle()
	if(sleepMode[sleepModeValue].idleSounds.size() > 0):
		idleSoundPlayer.stream = sleepMode[sleepModeValue].idleSounds[0]
		idleSoundPlayer.play()

	
