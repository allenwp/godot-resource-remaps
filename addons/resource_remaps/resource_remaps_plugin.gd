@tool
extends EditorPlugin

# TODO:
# - Move tab to the far right? Shouldn't this be already working?

const CONTROL_CONTAINER = CONTAINER_PROJECT_SETTING_TAB_RIGHT
var control: Control

const ExportPlugin = preload("res://addons/resource_remaps/resource_remaps_export.gd")
var export_plugin: Object = ExportPlugin.new()

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	control = preload("res://addons/resource_remaps/resource_remaps_control.tscn").instantiate()
	add_control_to_container(CONTROL_CONTAINER, control)

	if (export_plugin is EditorExportPlugin):
		add_export_plugin(export_plugin as EditorExportPlugin)

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_control_from_container(CONTROL_CONTAINER, control)
	control.free()

	if (export_plugin is EditorExportPlugin):
		remove_export_plugin(export_plugin as EditorExportPlugin)
