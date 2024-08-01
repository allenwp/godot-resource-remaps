@tool
extends EditorPlugin

# TODO:
# - Move tab to the far right? Shouldn't this be already working?

const CONTROL_CONTAINER = CONTAINER_PROJECT_SETTING_TAB_RIGHT
var control: ResourceRemapControl
var updating_translations: bool = false
var res_file_open_dialog: EditorFileDialog = null

const ExportPlugin = preload("res://addons/resource_remaps/resource_remaps_export.gd")
var export_plugin: ResourceRemapPlugin = ExportPlugin.new()

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	control = preload("res://addons/resource_remaps/resource_remaps_control.tscn").instantiate()
	add_control_to_container(CONTROL_CONTAINER, control)
	_setup_control()

	if (export_plugin is EditorExportPlugin):
		add_export_plugin(export_plugin as EditorExportPlugin)
		update_resource_remaps()

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_control_from_container(CONTROL_CONTAINER, control)
	control.free()
	control = null

	if (export_plugin is EditorExportPlugin):
		remove_export_plugin(export_plugin as EditorExportPlugin)

func _setup_control() -> void:
	control.res_remap_add_button.pressed.connect(_res_file_open)
	control.resource_remap.cell_selected.connect(_res_select)
	control.resource_remap.button_clicked.connect(_res_delete)

	res_file_open_dialog = EditorFileDialog.new()
	res_file_open_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILES
	res_file_open_dialog.files_selected.connect(_res_add)
	control.add_child(res_file_open_dialog)

# Copied from LocalizationEditor::update_translations()
func update_resource_remaps() -> void:
	if control == null:
		return

	if updating_translations:
		return

	updating_translations = true
	
	var remap_selected: String
	if control.resource_remap.get_selected():
		remap_selected = control.resource_remap.get_selected().get_metadata(0)

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
		
		if key == remap_selected:
			t.select(0)
			control.res_remap_option_add_button.disabled = false

			# TODO

	updating_translations = false

func _res_add(paths: PackedStringArray) -> void:
	pass
	#TODO

func _res_file_open() -> void:
	res_file_open_dialog.popup_centered_clamped()

func _res_select() -> void:
	if updating_translations:
		return
	
	self.call_deferred(&"update_resource_remaps")

func _res_delete(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if updating_translations:
		return
	
	if mouse_button_index != 0:
		return
	
	#TODO

#TODO: call this from somewhere
func connect_filesystem_dock_signals(fs_dock: FileSystemDock) -> void:
	fs_dock.files_moved.connect(_filesystem_files_moved)
	fs_dock.file_removed.connect(_filesystem_files_removed)

func _filesystem_files_moved( old_file: String, new_file: String ) -> void:
	pass
	#TODO

func _filesystem_files_removed( file: String ) -> void:
	pass
	#TODO
