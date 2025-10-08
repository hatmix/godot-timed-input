extends "res://tests/helper.gd"

var skip_script


func _init():
	if DisplayServer.get_name() == "headless":
		skip_script = "Skip Input tests when running headless"


func before_all():
	process_hold = false


func test_tap():
	tap_key()
	await wait_for_signal(timed_input_action.tapped, hold_delay)
	assert_only_signals(["tapped"])
	assert_signal_emit_count(timed_input_action, "tapped", 1)


func test_multitap():
	multitap_key()
	await wait_for_signal(timed_input_action.multitapped, multitap_timeout * 1.2)
	assert_only_signals(["tapped", "multitapped"])
	assert_signal_emit_count(timed_input_action, "tapped", 1)
	assert_signal_emit_count(timed_input_action, "multitapped", 1)


func test_multitap_timeout():
	multitap_key(multitap_timeout + .1)
	await wait_for_signal(timed_input_action.tapped, multitap_timeout + .1)
	await wait_for_signal(timed_input_action.tapped, multitap_timeout + .1)
	assert_only_signals(["tapped"])
	assert_signal_emit_count(timed_input_action, "tapped", 2)


func test_hold():
	hold_key()
	await wait_for_signal(timed_input_action.tapped, hold_delay * 2)
	assert_only_signals(["tapped"])
	assert_signal_emit_count(timed_input_action, "tapped", 1)
