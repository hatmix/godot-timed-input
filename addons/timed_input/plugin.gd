@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("TimedInput", "Node", preload("timed_input.gd"), preload("icon.svg"))


func _exit_tree():
	remove_custom_type("TimedInput")
