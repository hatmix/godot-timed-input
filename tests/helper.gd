extends GutTest

var _sender
var timed_input_action: TimedInput
var action: String = "ui_left"
var action_key: Key = KEY_LEFT
var multitap_timeout = 0.2
var hold_delay = 0.2
var send_events: bool = true
var emit_signals: bool = true
var process_tap: bool = true
var process_multitap: bool = true
var process_hold: bool = true
var emit_holding_signal: bool = false
var strength_scale: float = 0.1

const SIGNALS = ["tapped", "multitapped", "hold_started", "hold_finished", "holding"]


func before_each():
	reset_sender()
	timed_input_action = new_timed_input_action()
	# short pauses between tests seem to help when testing with fast DELAY times
	await get_tree().create_timer(0.25).timeout
	print("==== BEGIN ===============")


func after_each():
	timed_input_action.free()
	print("==== END ===============")


func new_timed_input_action() -> TimedInput:
	var tia = TimedInput.new()
	tia.action = action
	tia.ACTION_MULTITAP_TIMEOUT = multitap_timeout
	tia.ACTION_HOLD_DELAY = hold_delay
	tia.send_events = send_events
	tia.emit_signals = emit_signals
	tia.process_tap = process_tap
	tia.process_multitap = process_multitap
	tia.process_hold = process_hold
	tia.emit_holding_signal = emit_holding_signal
	tia.strength_scale = strength_scale
	add_child_autofree(tia)
	watch_signals(tia)
	return tia


func reset_sender() -> void:
	if _sender:
		_sender.release_all()
		_sender.clear()
	else:
		_sender = InputSender.new(Input)
	Input.flush_buffered_events()
	await Engine.get_main_loop().physics_frame


# 0.05s was fastest tap I could get during manual testing
func tap_key(duration: float = 0.05) -> Object:
	_sender.key_down(action_key).wait(duration).key_up(action_key)
	await _sender.idle
	await Engine.get_main_loop().physics_frame
	return _sender


func multitap_key(
	pause_between: float = 0,
	tap_duration: float = 0.05,
) -> Object:
	if pause_between == 0:
		pause_between = multitap_timeout / 2
	print("pause between = " + str(pause_between))
	tap_key(tap_duration)
	await Engine.get_main_loop().physics_frame
	await get_tree().create_timer(pause_between).timeout
	await Engine.get_main_loop().physics_frame
	tap_key(tap_duration)
	return _sender


func hold_key(duration: float = hold_delay * 1.1) -> Object:
	_sender.key_down(action_key).wait(duration).key_up(action_key)
	await _sender.idle
	return _sender


func assert_only_signals(signal_names: Array[String]) -> void:
	var remaining_signals = SIGNALS.duplicate()
	for signal_name in signal_names:
		assert_signal_emitted(timed_input_action, signal_name)
		remaining_signals.erase(signal_name)
	for signal_name in remaining_signals:
		assert_signal_not_emitted(timed_input_action, signal_name)
