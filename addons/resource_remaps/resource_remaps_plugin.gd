@tool
extends EditorPlugin

# TODO:
# - Move tab to the far right? Shouldn't this be already working?

const CONTROL_CONTAINER = CONTAINER_PROJECT_SETTING_TAB_RIGHT
var control: ResourceRemapControl

const ExportPlugin = preload("res://addons/resource_remaps/resource_remaps_export.gd")
var export_plugin: ResourceRemapPlugin = ExportPlugin.new()

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	control = preload("res://addons/resource_remaps/resource_remaps_control.tscn").instantiate()
	add_control_to_container(CONTROL_CONTAINER, control)

	if (export_plugin is EditorExportPlugin):
		add_export_plugin(export_plugin as EditorExportPlugin)
		update_resource_remaps()

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_control_from_container(CONTROL_CONTAINER, control)
	control.free()

	if (export_plugin is EditorExportPlugin):
		remove_export_plugin(export_plugin as EditorExportPlugin)

# Copied from LocalizationEditor::update_translations()
func update_resource_remaps() -> void:
	control.resource_remap.clear()
	control.resource_remap_options.clear()
	var root: TreeItem = control.resource_remap.create_item(null)
	var root2: TreeItem = control.resource_remap_options.create_item(null)
	control.res_remap_option_add_button.disabled = true

	var keys: Array = export_plugin.remap_resource.keys()
	keys.append_array(export_plugin.remap_scene.keys())
	keys.append_array(export_plugin.remap_file.keys())
	keys.sort()

	for key: String in keys:
		var t: TreeItem = control.resource_remap.create_item(root)
		t.set_editable(0, false)
		t.set_text(0, key.replace("res://", ""))
		t.set_tooltip_text(0, key)
		t.set_metadata(0, key)

		var remove_icon: Texture2D = EditorInterface.get_base_control().get_theme_icon(&"Remove", &"EditorIcons")
		t.add_button(0, remove_icon, 0, false, "Remove")

		# Display that it has been removed if this is the case.
		if !FileAccess.file_exists(key):
			t.set_text(0, t.get_text(0) + " Removed")
			t.set_tooltip_text(0, t.get_tooltip_text(0) + " cannot be found.")
