#TODO: add license
@tool
extends EditorPlugin

# TODO:
# - Move tab to the far right? Shouldn't this be already working?

const CONTROL_CONTAINER = CONTAINER_PROJECT_SETTING_TAB_RIGHT
var control: ResourceRemapControl

const ExportPlugin = preload("res://addons/resource_remaps/resource_remaps_export.gd")
var export_plugin: ResourceRemapPlugin

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	control = ResourceRemapControl.new()
	add_control_to_container(CONTROL_CONTAINER, control)

	export_plugin = ExportPlugin.new()
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_control_from_container(CONTROL_CONTAINER, control)
	control.free()
	control = null

	if (export_plugin is EditorExportPlugin):
		remove_export_plugin(export_plugin)
		export_plugin = null
