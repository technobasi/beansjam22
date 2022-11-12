extends Node2D


onready var background := $CanvasLayer/Background
onready var sleepTimer := $SleepTimer
onready var endGameLabel := $CanvasLayer/EndGame
onready var idleSoundTimer := $IdleSoundTimer
onready var mainSoundPlayer := $MainSoundPlayer
onready var fullFail := $FullFail
onready var backgroundPlayer := $BackgroundPlayer
onready var eventTimer :=$EventTimer
onready var tween := $Tween

var sleepMeter := 100.0
var gameOver = false
var textBuffer := ""
var startTime: Dictionary
var lastInputTime: int = 0 
var effect
var record_live_index

export(float) var sleepDecay = -1
export(float) var sleepTypeBoost = 1
export(float) var mouseMovementBoost = 0.001
export(float) var microphoneBoost = 0.001
export(int) var DECAY_INCREASE_TIME = 5

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
	"PIZZA": {
		"value": 0,
		"playSound": [
			preload("res://sounds/voicelines/keywords/pizza/pizza.wav")
		]
	},
	"UpUpDownDownLeftRightLeftRightBA" : {
		"value": 100,
		"playSound": [
			preload("res://sounds/voicelines/keywords/konami/cheater.wav")
		]
	},
	"DROGE":{
		"value": 0,
		"playSound": [
			preload("res://sounds/voicelines/keywords/drug/drug.wav")
		]
	},
	"DROGEN":{
		"value": 0,
		"playSound": [
			preload("res://sounds/voicelines/keywords/drug/drug.wav")
		]
	},
	"KOKS":{
		"value": 0,
		"playSound": [
			preload("res://sounds/voicelines/keywords/drug/drug.wav")
		]
	},
	"KOKAIN":{
		"value": 0,
		"playSound": [
			preload("res://sounds/voicelines/keywords/drug/drug.wav")
		]
	},
	"HEROIN":{
		"value": 0,
		"playSound": [
			preload("res://sounds/voicelines/keywords/drug/drug.wav")
		]
	},
	"SPEED":{
		"value": 0,
		"playSound": [
			preload("res://sounds/voicelines/keywords/drug/drug.wav")
		]
	},
	"LSD":{
		"value": 0,
		"playSound": [
			preload("res://sounds/voicelines/keywords/drug/drug.wav")
		]
	},
} 

var sleepMode := {
	"awake": {
		"max": 100,
		"min": 66,
		"color": Color(0.75,0.75,0.75),
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
		"color": Color(0.50,0.50,0.50),
		"max": 66,
		"min": 33,
		"idleSounds": [
			preload("res://sounds/idle/sleepy/yawn.wav"),
			preload("res://sounds/idle/sleepy/yawn2.wav"),
			preload("res://sounds/idle/sleepy/sleepy1.wav"),
			preload("res://sounds/idle/sleepy/sleepy2.wav"),
			preload("res://sounds/idle/sleepy/sleepy3.wav"),
			preload("res://sounds/idle/sleepy/sleepy4.wav"),
			preload("res://sounds/idle/sleepy/sleepy5.wav"),
			preload("res://sounds/idle/sleepy/sleepy6.wav"),
			preload("res://sounds/idle/sleepy/sleepy7.wav")
		],
		"atmo": preload("res://sounds/atmo/sleepy/typing_sleepy.wav"),
	},
	"almost_sleeping": {
		"color": Color(0.20,0.20,0.20),
		"max": 33,
		"min":0,
		"idleSounds": [
			preload("res://sounds/idle/almost_sleeping/almost_sleeping1.wav"),
			preload("res://sounds/idle/almost_sleeping/almost_sleeping2.wav"),
			preload("res://sounds/idle/almost_sleeping/almost_sleeping3.wav"),
			preload("res://sounds/idle/almost_sleeping/almost_sleeping4.wav")
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
	record_live_index = AudioServer.get_bus_index('Record')
	spectrum_analyzer = AudioServer.get_bus_effect_instance(record_live_index, 1)
	sleepTimer.stop()
	idleSoundTimer.stop()
	eventTimer.stop()
	set_process(false)
	set_process_input(false)
	
func _on_StartSzene_game_start() -> void:
	sleepTimer.start()
	idleSoundTimer.start()
	eventTimer.start()
	set_process(true)
	set_process_input(true)
	backgroundPlayer.play()
	startTime = Time.get_datetime_dict_from_system()
	lastInputTime = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
	updateSleepMeter(0)
	randomize()
	
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
	tween.interpolate_property(background,"color",background.color,sleepMode[CURRENT_STATE].color,1,Tween.TRANS_LINEAR)
	tween.start()

const MIN_DB: int = 80
const MAX_SAMPLES: int = 10

var volume_samples: Array = []

var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance

func _process(delta: float) -> void:
	# Get the strength of the 0 - 200hz range of audio
	var magnitude = spectrum_analyzer.get_magnitude_for_frequency_range(
		0,
		200
	).length()

	# Boost the signal and normalize it
	var energy = clamp((MIN_DB + linear2db(magnitude))/MIN_DB, 0, 1)
	if energy > 0:
		print(energy)
		updateSleepMeter(microphoneBoost)
	else:
		var now = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
		if now - lastInputTime > DECAY_INCREASE_TIME:
			sleepDecay *= 2
			lastInputTime = now
			print("sleepDecay increased")
	pass
var lastInput = null
func _input(event):
	if !gameOver:
		if event is InputEventKey:
			if event.pressed:
				fullFail.add_input()
				var currentInput = OS.get_scancode_string(event.scancode)
				textBuffer += currentInput
				checkTextBufferForKeywords()
				print(textBuffer)
				if(currentInput != lastInput):
					updateSleepMeter(sleepTypeBoost)
				lastInput = currentInput
				resetSleepDecay()
				lastInputTime = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
		if event is InputEventMouseMotion:
			updateSleepMeter(mouseMovementBoost)
		if event is InputEventMouseButton:
			if("MOUSE" != lastInput):
				updateSleepMeter(sleepTypeBoost)
			lastInput = "MOUSE"
	
			resetSleepDecay()
			lastInputTime = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
			fullFail.add_input()
			
func resetSleepDecay():
	sleepDecay = -1
	
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
	set_process(false)
	set_process_input(false)
	var endTime = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
	endGameLabel.text = "Game Jam over!\n Du hast " + parse_endTime(endTime) + " durchgehalten!"
	endGameLabel.show()
	gameOver = true
	fullFail.play_tutorial_ending()
	
func parse_endTime(endTime) -> String:
	var timeDiffInSeconds = endTime - Time.get_unix_time_from_datetime_dict(startTime)
	if(timeDiffInSeconds > 60):
		return str(timeDiffInSeconds / 60) + " Minuten & " + str(timeDiffInSeconds % 60) +" Sekunden"
	else:
		return str(timeDiffInSeconds)+ " Sekunden"

func updateSleepMeter(updateValue: float) -> void:
	sleepMeter += updateValue
	determineSleepMode()
	print(sleepMeter)



func _on_IdleSoundTimer_timeout():
	print("idleTimer fired")
	if(!mainSoundPlayer.playing):
		var sleepModeValue = determineSleepMode()
		sleepMode[sleepModeValue].idleSounds.shuffle()
		if(sleepMode[sleepModeValue].idleSounds.size() > 0):
			mainSoundPlayer.stream = sleepMode[sleepModeValue].idleSounds[0]
			mainSoundPlayer.play()
			idleSoundTimer.wait_time = randi() * 10

func _on_EventTimer_timeout() -> void:
	print("randomEvent")
	if(!mainSoundPlayer.playing):
		print("playEvent")
		events.keys().shuffle()
		mainSoundPlayer.stream = events.values()[0].sound
		mainSoundPlayer.play()
		eventTimer.wait_time = randi() * 10
		




