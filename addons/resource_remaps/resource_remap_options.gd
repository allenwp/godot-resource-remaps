@tool
extends Tree

func _init() -> void:
	set_column_title(0, "Path")
	set_column_title(1, "Feature")
	set_column_expand(0, true)
	set_column_clip_content(0, true)
	set_column_expand(1, false)
	set_column_clip_content(1, false)
	set_column_custom_minimum_width(1, 250)
