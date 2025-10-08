extends "res://tests/helper.gd"

var skip_script


func _init():
	if DisplayServer.get_name() == "headless":
		skip_script = "Skip Input tests when running headless"


func before_all():
	process_tap = false


func test_tap():
	tap_key()
	await get_tree().create_timer(0.25).timeout
	assert_only_signals([])  # assert no TIA signals sent


func test_multitap():
	multitap_key()
	await wait_for_signal(timed_input_action.multitapped, multitap_timeout + .1)
	assert_only_signals(["multitapped"])
	assert_signal_emit_count(timed_input_action, "multitapped", 1)


func test_multitap_timeout():
	multitap_key(multitap_timeout + .1)
	await get_tree().create_timer(0.5).timeout
	assert_only_signals([])  # assert no TIA signals sent


func test_hold():
	hold_key()
	await wait_for_signal(timed_input_action.hold_started, hold_delay * 1.1)
	await wait_for_signal(timed_input_action.hold_finished, hold_delay * 1.2)
	assert_only_signals(["hold_started", "hold_finished"])
	assert_signal_emit_count(timed_input_action, "hold_started", 1)
	assert_signal_emit_count(timed_input_action, "hold_finished", 1)
