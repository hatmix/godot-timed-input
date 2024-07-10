extends Label


func set_signal_text(signal_name: String, param: Variant = null) -> void:
	text = "[%d] %s" % [Engine.get_frames_drawn(), signal_name]
	if param:
		text += " (" + format_param(param) + ")"


func format_param(signal_param: Variant) -> String:
	if signal_param is int:
		return str(signal_param)
	if signal_param is float:
		return "%.2f" % signal_param
	return "(none)"


func _ready():
	visible = false


# Called when the node enters the scene tree for the first time.
func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		get_tree().create_tween().tween_property(self, "modulate", Color.WHITE, 0.5)
