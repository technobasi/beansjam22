extends Node2D


onready var background := $CanvasLayer/Background
onready var sleepTimer := $SleepTimer
onready var endGameLabel := $CanvasLayer/EndGame
onready var idleSoundTimer := $IdleSoundTimer
onready var mainSoundPlayer := $MainSoundPlayer
onready var fullFail := $FullFail
onready var backgroundPlayer := $BackgroundPlayer
onready var eventTimer :=$EventTimer

var sleepMeter := 100.0
var gameOver = false
var textBuffer := ""
var startTime: Dictionary 

export(float) var sleepDecay = -1
export(float) var sleepTypeBoost = 1
export(float) var mouseMovementBoost = 0.001

var events = {
	"PIZZA": {
		"sound": preload("res://sounds/event_trigger/pizza_event_trigger.wav")
	},
	"HELP": {
		"sound": preload("res://sounds/event_trigger/help_event_trigger.wav")
	},
	"COLA": {
		"sound": preload("res://sounds/event_trigger/cola_event_trigger.wav")
	},
	"KAFFEE": {
		"sound": preload("res://sounds/event_trigger/kaffee_event_trigger.wav")
	}
}

var keywords := {
	"COLA": {
		"value": 10,
		"playSound": [
			preload("res://sounds/voicelines/keywords/cola/cola.wav")
		],
		"penalty": {
			"duration": 10,
			"punishment": 5
		}
	},
	"KAFFEE": {
		"value": 15,
		"playSound": [
			preload("res://sounds/voicelines/keywords/kaffee/kaffee.wav")
		],
		"penalty": {
			"duration": 20,
			"punishment": 20
		}
	},
	"HELP": {
		"value": 0,
		"playSound":[
			preload("res://sounds/voicelines/keywords/help/help.wav")
		]
	},
	"HILFE": {
		"value": 0,
		"playSound":[
			preload("res://sounds/voicelines/keywords/help/help.wav")
		]
	},
	"HELFEN": {
		"value": 0,
		"playSound":[
			preload("res://sounds/voicelines/keywords/help/help.wav")
		]
	},
	"UpUpDownDownLeftRightLeftRightBA" : {
		"value": 100,
		"playSound": [
			preload("res://sounds/voicelines/keywords/konami/cheater.wav")
		]
	}
} 

var sleepMode := {
	"awake": {
		"max": 100,
		"min": 66,
		"color": Color.gold,
		"atmo": preload("res://sounds/atmo/awake/typing_awake.wav"),
		"idleSounds": [
			preload("res://sounds/idle/awake/awake1.wav"),
			preload("res://sounds/idle/awake/awake2.wav"),
			preload("res://sounds/idle/awake/awake3.wav"),
			preload("res://sounds/idle/awake/awake4.wav"),
			preload("res://sounds/idle/awake/awake5.wav"),
			preload("res://sounds/idle/awake/awake6.wav"),
		]
	},
	"sleepy": {
		"color": Color.orangered,
		"max": 66,
		"min": 33,
		"idleSounds": [
			preload("res://sounds/idle/sleepy/yawn.wav")
		],
		"atmo": preload("res://sounds/atmo/sleepy/typing_sleepy.wav"),
	},
	"almost_sleeping": {
		"color": Color.darkorange,
		"max": 33,
		"min":0,
		"idleSounds": [
			preload("res://sounds/idle/almost_sleeping/almost_sleeping1.wav"),
			preload("res://sounds/idle/almost_sleeping/almost_sleeping2.wav"),
			preload("res://sounds/idle/almost_sleeping/almost_sleeping3.wav")
		],
		"atmo": preload("res://sounds/atmo/almost_sleeping/typing_almost_sleeping.wav"),
	},
	"sleeping": {
		"color": Color.black,
		"max": 0,
		"min": -1000,
		"idleSounds": [
			
		],
		"atmo": null
	}
}

var CURRENT_STATE = "awake"

func _ready() -> void:
	startTime = Time.get_datetime_dict_from_system()
	updateSleepMeter(0)
	#randomize()
	
func determineSleepMode() -> String:
	var ret = "awake"
	for k in sleepMode:
		if(sleepMeter > sleepMode[k].min && sleepMeter <= sleepMode[k].max):
			ret = k
	
	if sleepMeter > sleepMode.awake.max:
		ret =  "awake"
		
	if(CURRENT_STATE != ret):
		CURRENT_STATE = ret
		changeAtmo()
	return ret
	
func changeAtmo():
	backgroundPlayer.stream = sleepMode[CURRENT_STATE].atmo
	backgroundPlayer.play()
	background.color = sleepMode[CURRENT_STATE].color
	
func _input(event):
	if !gameOver:
		if event is InputEventKey:
			if event.pressed:
				fullFail.add_input()
				textBuffer += OS.get_scancode_string(event.scancode)
				checkTextBufferForKeywords()
				print(textBuffer)
				updateSleepMeter(sleepTypeBoost)
		if event is InputEventMouseMotion:
			updateSleepMeter(mouseMovementBoost)
		if event is InputEventMouseButton:
			updateSleepMeter(sleepTypeBoost)
			fullFail.add_input()
		
	
func checkTextBufferForKeywords():
	var matchFound: bool = false
	for k in keywords:
		if k in textBuffer:
			sleepMeter+= keywords[k].value
			matchFound = true
			if keywords[k].playSound.size() > 0:
				playSound(keywords[k].playSound[0])
			if keywords[k].has("penalty"):
				startPenalty(keywords[k])
	if matchFound:
		textBuffer = ""

func startPenalty(entry):
	var timer = Timer.new()
	add_child(timer)
	timer.autostart = true
	timer.wait_time = entry.penalty.duration
	timer.one_shot = true
	timer.connect("timeout", self,"punishmentTimer",[-entry.penalty.punishment])
	timer.start()
	
func punishmentTimer(punishment: float):
	updateSleepMeter(punishment)
	checkIfGameIsOver()
	
func playSound(sound):
	mainSoundPlayer.stream = sound
	mainSoundPlayer.play()

func checkIfGameIsOver():
	if(sleepMeter <= 0.0):
		finishGame()
		
func _on_SleepTimer_timeout():
	updateSleepMeter(sleepDecay)
	checkIfGameIsOver()
	
func finishGame() -> void:
	sleepTimer.stop()
	idleSoundTimer.stop()
	eventTimer.stop()
	var endTime = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
	endGameLabel.text = "Game Jam over!\n Du hast " + str(endTime - Time.get_unix_time_from_datetime_dict(startTime)) + " Sekunden durchgehalten!"
	endGameLabel.show()
	gameOver = true
	fullFail.play_tutorial_ending()
	
func updateSleepMeter(updateValue: float) -> void:
	sleepMeter += updateValue
	determineSleepMode()



func _on_IdleSoundTimer_timeout():
	var sleepModeValue = determineSleepMode()
	sleepMode[sleepModeValue].idleSounds.shuffle()
	if(sleepMode[sleepModeValue].idleSounds.size() > 0):
		mainSoundPlayer.stream = sleepMode[sleepModeValue].idleSounds[0]
		mainSoundPlayer.play()

func _on_EventTimer_timeout() -> void:
	if(!mainSoundPlayer.playing):
			events.keys().shuffle()
			mainSoundPlayer.stream = events.values()[0].sound
			mainSoundPlayer.play()
			eventTimer.wait_time = randi() * 10
		

