extends CanvasLayer

const HOLD_DELAY_COLOR = Color.YELLOW
const MULTITAP_TIMEOUT_COLOR = Color.ORANGE
const time_format_string = "%.2f"

var signal_entry = load("res://demo/signal_scroll_entry.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%TimeoutLabel.self_modulate = MULTITAP_TIMEOUT_COLOR
	%DelayLabel.self_modulate = HOLD_DELAY_COLOR
	%TimedInput.tapped.connect(_on_tapped)
	%TimedInput.multitapped.connect(_on_multitapped)
	%TimedInput.hold_started.connect(_on_hold_started)
	%TimedInput.hold_finished.connect(_on_hold_finished)
	%TimedInput.holding.connect(_on_holding)
	update_action_timeouts()

	%ScrollContainer.get_v_scroll_bar().changed.connect(_on_scrollbar_changed)
	%Clear.pressed.connect(_clear_scroll)
	%ProcessTap.button_pressed = %TimedInput.process_tap
	%ProcessMultitap.button_pressed = %TimedInput.process_multitap
	%ProcessHold.button_pressed = %TimedInput.process_hold
	%ProcessTap.pressed.connect(func(): %TimedInput.process_tap = %ProcessTap.button_pressed)
	%ProcessMultitap.pressed.connect(
		func(): %TimedInput.process_multitap = %ProcessMultitap.button_pressed
	)
	%ProcessHold.pressed.connect(func(): %TimedInput.process_hold = %ProcessHold.button_pressed)


func _physics_process(_delta) -> void:
	update_timer_ui()


func add_signal_entry(signal_name, param = null) -> void:
	var entry = signal_entry.instantiate()
	entry.visible = false
	entry.set_signal_text(signal_name, param)
	%SignalScroll.add_child(entry)
	#if %SignalScroll.get_child_count() > 6:
	#    %SignalScroll.get_child(0).queue_free()
	entry.visible = true


#func _on_process_tap_button_pressed() -> void:


func _clear_scroll() -> void:
	for child in %SignalScroll.get_children():
		child.free()
	%Clear.release_focus()


func _on_scrollbar_changed() -> void:
	var scrollbar: VScrollBar = %ScrollContainer.get_v_scroll_bar()
	%ScrollContainer.scroll_vertical = scrollbar.max_value


func _on_tapped(duration) -> void:
	add_signal_entry("Tapped", duration)


func _on_multitapped(count) -> void:
	add_signal_entry("Multiapped", count)


func _on_hold_started() -> void:
	add_signal_entry("Hold Started")


func _on_hold_finished(duration) -> void:
	add_signal_entry("Hold Finished", duration)


func _on_holding(duration) -> void:
	%HoldSignalTime.text = time_format_string % duration
	%HoldSignalTimeProgress.value = duration


func update_action_timeouts() -> void:
	%ReleasedTimeProgress.max_value = 2 * %TimedInput.ACTION_MULTITAP_TIMEOUT
	%HoldTimeProgress.max_value = 2 * %TimedInput.ACTION_HOLD_DELAY


func update_timer_ui() -> void:
	var released_time = %TimedInput.released_time
	%ReleasedTime.text = time_format_string % released_time
	%ReleasedTimeProgress.value = released_time
	if released_time >= %TimedInput.ACTION_MULTITAP_TIMEOUT:
		%ReleasedTime.self_modulate = MULTITAP_TIMEOUT_COLOR
		%ReleasedTimeProgress.self_modulate = MULTITAP_TIMEOUT_COLOR
	else:
		%ReleasedTime.self_modulate = Color.WHITE
		%ReleasedTimeProgress.self_modulate = Color.WHITE

	var hold_time = %TimedInput.hold_time
	%HoldTime.text = time_format_string % hold_time
	%HoldTimeProgress.value = hold_time
	if hold_time >= %TimedInput.ACTION_HOLD_DELAY:
		%HoldTime.self_modulate = HOLD_DELAY_COLOR
		%HoldTimeProgress.self_modulate = HOLD_DELAY_COLOR
	else:
		%HoldTime.self_modulate = Color.WHITE
		%HoldTimeProgress.self_modulate = Color.WHITE
