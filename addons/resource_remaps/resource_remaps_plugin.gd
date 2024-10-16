#TODO: add license
@tool
extends EditorPlugin

# TODO:
# - Undo redo isn't working
# - test file renames, file system removals, etc.
# - Translate GUI text
# - Auto-select newly added resource in first Tree
# - Refresh entire control when the project settings menu is re-opened to get new tags that may have been added in export presets
# - Refresh entire control when files get brought back, not just when they're deleted.

const CONTROL_CONTAINER = CONTAINER_PROJECT_SETTING_TAB_RIGHT
var control: ResourceRemapControl

var export_plugin: ResourceRemapPlugin

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	control = ResourceRemapControl.new()
	add_control_to_container(CONTROL_CONTAINER, control)

	export_plugin = ResourceRemapPlugin.new()
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_control_from_container(CONTROL_CONTAINER, control)
	control.free()
	control = null

	if (export_plugin is EditorExportPlugin):
		remove_export_plugin(export_plugin)
		export_plugin = null
