class_name TimedInput
extends Node

## Name of action to be timed
@export var action: String : set = _set_action

## How many seconds an action button/key must be held before it is a "hold" instead of a "tap"
@export var ACTION_HOLD_DELAY: float = 0.2

## How many seconds after a tap can the next tap be part of a consecutive chain (multitap)
@export var ACTION_MULTITAP_TIMEOUT: float = 0.2

## When enabled, signals are emitted for the selected TimedInput types
@export var emit_signals: bool = true

## When enabled, InputEventActions are created for the selected TimedInput types
@export var send_events: bool = false : set = _set_send_events

## When enabled, act on "tap" TimedInput type
@export var process_tap: bool = true : set = _set_process_tap

## When enabled, act on "multitap" TimedInput type
@export var process_multitap: bool = true : set = _set_process_multitap

## When enabled, act on "hold_started" and "hold_finished" TimedInput type
@export var process_hold: bool = true : set = _set_process_hold

## When enabled, emit a holding signal with current total time held each physics frame, e.g. for easy progress bar updates.
@export var emit_holding_signal: bool = true

## InputEventAction strength is used for the count of multitaps and duration of holds. Strength has a range of 0.0 to 1.0, so count and duration are multiplied by this scale value to get a valid strength. This is only needed in events as signals pass the actual values.
@export var strength_scale: float = 0.1

const MAX_HOLD_TIME: float = 30.0
const MAX_RELEASED_TIME: float = 30.0

# Default event names
enum ACTION {TAP, MULTITAP, HOLD_STARTED, HOLD_FINISHED}
const SUFFIX = ["_tap", "_multitap", "_hold_started", "_hold_finished"]

# is_holding tracks key/button state
var is_holding: bool = false
var hold_time: float = 0
# is_hold_started is true once hold_time > ACTION_HOLD_DELAY
var is_hold_started: bool = false
var consecutive_count: int = 0
var released_time: float = 0

signal tapped(duration: float)
signal multitapped(count: int)
signal hold_started
signal holding(current_duration: float)
signal hold_finished(total_duration: float)


func _set_action(value: String) -> void:
	for suffix in SUFFIX:
		remove_action_name(action + suffix)
	action = value
	_set_process_tap(process_tap)
	_set_process_multitap(process_multitap)
	_set_process_hold(process_hold)


func _set_process_tap(value: bool) -> void:
	process_tap = value
	var action_name: String = action + SUFFIX[ACTION.TAP]
	if send_events and process_tap:
		ensure_action_name(action_name)
	else:
		remove_action_name(action_name)


func _set_process_multitap(value: bool) -> void:
	process_multitap = value
	var action_name: String = action + SUFFIX[ACTION.TAP]
	if send_events and process_multitap:
		ensure_action_name(action_name)
	else:
		remove_action_name(action_name)


func _set_process_hold(value: bool) -> void:
	process_hold = value
	if send_events and process_hold:
		ensure_action_name(action + SUFFIX[ACTION.HOLD_STARTED])
		ensure_action_name(action + SUFFIX[ACTION.HOLD_FINISHED])
	else:
		remove_action_name(action + SUFFIX[ACTION.HOLD_STARTED])
		remove_action_name(action + SUFFIX[ACTION.HOLD_FINISHED])


func _set_send_events(value: bool) -> void:
	send_events = value
	if send_events:
		_set_process_tap(process_tap)
		_set_process_multitap(process_multitap)
		_set_process_hold(process_hold)
	else:
		for suffix in SUFFIX:
			remove_action_name(action + suffix)


func remove_action_name(action_name: String) -> void:
	if InputMap.has_action(action_name) and InputMap.action_get_events(action_name).size() == 0:
		InputMap.erase_action(action_name)


func ensure_action_name(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)


func send_event(action_name: String, strength: float = 0) -> void:
	var event = InputEventAction.new()
	event.action = action_name
	event.pressed = true
	if strength:
		event.set_strength(strength)
	Input.parse_input_event(event)
	#get_viewport().push_input(event)


func action_tap(hold_time: float):
	#print("[", Time.get_ticks_msec(), "] ", action, " tap")
	if process_tap:
		if send_events:
			send_event(action + "_tap", hold_time / ACTION_HOLD_DELAY )
		if emit_signals:
			tapped.emit(hold_time)


func action_multitap(count: int):
	#print("[", Time.get_ticks_msec(), "] ", action, " multitap ", count)
	if process_multitap:
		if send_events:
			send_event(action + "_multitap", count * strength_scale)
		if emit_signals:
			multitapped.emit(count)


func action_hold_started():
	#print("[", Time.get_ticks_msec(), "] ", action, " hold started")
	if process_hold:
		if send_events:
			send_event(action + "_hold_started")
		if emit_signals:
			hold_started.emit()


func action_hold_finished(duration: float):
	#print("[", Time.get_ticks_msec(), "] ", action, " held for ", duration)
	if process_hold:
		if send_events:
			send_event(action + "_hold_finished", duration * strength_scale)
		if emit_signals:
			hold_finished.emit(duration)


func _ready():
	pass


func _unhandled_input(event):
	# Infinite loop danger without this short-circuit...
	if event is InputEventAction:
		#print(event, ", strength: " + str(event.get_strength()))
		return


	if Input.is_action_just_pressed(action):
		#print("[" + str(Engine.get_frames_drawn()) + "]" + action + " is just pressed")
		#get_tree().root.get_viewport().set_input_as_handled()
		get_viewport().set_input_as_handled()
		hold_time = 0
		is_holding = true


	if Input.is_action_just_released(action):
		#print("[" + str(Engine.get_frames_drawn()) + "]" +  action + " is just released")
		#get_tree().root.get_viewport().set_input_as_handled()
		get_viewport().set_input_as_handled()
		is_holding = false
		if released_time > ACTION_MULTITAP_TIMEOUT:
			consecutive_count = 0
		if is_hold_started:
			action_hold_finished(hold_time)
			is_hold_started = false
		else:
			consecutive_count += 1
			if consecutive_count > 1 and process_multitap:
				action_multitap(consecutive_count)
			else:
				action_tap(hold_time)
		released_time = 0


func _process(delta):
	# tests show released_time tends to need higher resolution than hold_time
	if not is_holding and released_time < MAX_RELEASED_TIME:
		released_time += delta
		#print("released time = ", released_time)


func _physics_process(delta):
	if is_holding and process_hold and hold_time < MAX_HOLD_TIME:
		hold_time += delta
		#print("hold time " + str(hold_time))
		if hold_time >= ACTION_HOLD_DELAY and not is_hold_started:
			action_hold_started()
			is_hold_started = true
		if is_hold_started and emit_signals and emit_holding_signal:
			holding.emit(hold_time)


