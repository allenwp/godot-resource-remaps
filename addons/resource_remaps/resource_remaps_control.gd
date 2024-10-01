#TODO: add license and note about being copied from Godot source
class_name ResourceRemapControl extends VBoxContainer

var res_remap_option_add_button: Button = null
var res_remap_file_open_dialog: EditorFileDialog = null
var res_remap_option_file_open_dialog: EditorFileDialog = null
## List of resources
var res_remap: Tree = null
## List of remaps for selected resource
var res_remap_options: Tree = null

var updating_res_remaps: bool = false

var undo_redo: UndoRedo = UndoRedo.new()

func TTR(text: String) -> String:
	# TODO: translate text.
	return text

func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_ENTER_TREE:
			var rfn: PackedStringArray = ResourceLoader.get_recognized_extensions_for_type("Resource")
			for E: String in rfn:
				res_remap_file_open_dialog.add_filter("*." + E)
				res_remap_option_file_open_dialog.add_filter("*." + E)

func _res_remap_file_open() -> void:
	res_remap_file_open_dialog.popup_file_dialog()

func _res_remap_add(p_paths: PackedStringArray) -> void:
	var prev: Variant
	var remaps: Dictionary

	if ProjectSettings.has_setting("resource_remaps"):
		remaps = ProjectSettings.get_setting("resource_remaps")
		prev = remaps

	for path in p_paths:
		if !remaps.has(path):
			# Don't overwrite with an empty remap array if an array already exists for the given path.
			var new_array: Array[PackedStringArray]
			remaps[path] = new_array

	undo_redo.create_action(TTR("Resource Remap: Add %d Path(s)") % p_paths.size())
	undo_redo.add_do_property(ProjectSettings, "resource_remaps", remaps)
	undo_redo.add_undo_property(ProjectSettings, "resource_remaps", prev)
	undo_redo.add_do_method(update_res_remaps)
	undo_redo.add_undo_method(update_res_remaps)
	undo_redo.commit_action()
	ProjectSettings.save()

func _res_remap_option_file_open() -> void:
	res_remap_option_file_open_dialog.popup_file_dialog()

func _res_remap_option_add(p_paths: PackedStringArray) -> void:
	if !ProjectSettings.has_setting("resource_remaps"):
		return

	var remaps: Dictionary = ProjectSettings.get_setting("resource_remaps")

	var k: TreeItem = res_remap.get_selected()
	if k == null:
		return

	var key: String = k.get_metadata(0)

	if !remaps.has(key):
		return

	var r: Array[PackedStringArray] = remaps[key]
	for path in p_paths:
		var remap_array: PackedStringArray
		remap_array.append("pc")
		remap_array.append(path)
		r.append(remap_array)
	remaps[key] = r

	undo_redo.create_action(TTR("Resource Remap: Add %d Remap(s)") % p_paths.size())
	undo_redo.add_do_property(ProjectSettings, "resource_remaps", remaps)
	undo_redo.add_undo_property(ProjectSettings, "resource_remaps", ProjectSettings.get_setting("resource_remaps"))
	undo_redo.add_do_method(update_res_remaps)
	undo_redo.add_undo_method(update_res_remaps)
	undo_redo.commit_action()
	ProjectSettings.save()

func _res_remap_select() -> void:
	if updating_res_remaps:
		return
	call_deferred("update_res_remaps")

func _res_remap_option_changed() -> void:
	if updating_res_remaps:
		return

	if !ProjectSettings.has_setting("resource_remaps"):
		return

	var remaps: Dictionary = ProjectSettings.get_setting("resource_remaps")

	var k: TreeItem = res_remap.get_selected()
	if k == null:
		return
	var ed: TreeItem = res_remap_options.get_edited()
	if ed == null:
		return

	var key: String = k.get_metadata(0)
	var old_feature: String = ed.get_metadata(0)
	var new_feature: String = "TODO: newly selected feature"
	ed.get_range(1)

	if !remaps.has(key):
		return
	var r: Array[PackedStringArray] = remaps[key]
	for i in range(r.size()):
		if r[i][0] == old_feature:
			r[i][0] = new_feature
			break
	remaps[key] = r

	updating_res_remaps = true

	undo_redo.create_action(TTR("Change Resource Remap Language"))
	undo_redo.add_do_property(ProjectSettings, "resource_remaps", remaps)
	undo_redo.add_undo_property(ProjectSettings, "resource_remaps", ProjectSettings.get_setting("resource_remaps"))
	undo_redo.add_do_method(update_res_remaps)
	undo_redo.add_undo_method(update_res_remaps)
	undo_redo.commit_action()
	ProjectSettings.save()

	updating_res_remaps = false

func _res_remap_delete(p_item: Object, p_column: int, p_button: int, p_mouse_button: int) -> void:
	if updating_res_remaps:
		return

	if p_mouse_button != MOUSE_BUTTON_LEFT:
		return

	if !ProjectSettings.has_setting("resource_remaps"):
		return

	var remaps: Dictionary = ProjectSettings.get_setting("resource_remaps")
	var k: TreeItem = p_item as TreeItem
	if k == null:
		return

	var key: String = k.get_metadata(0)
	if !remaps.has(key):
		return

	remaps.erase(key)

	undo_redo.create_action(TTR("Remove Resource Remap"))
	undo_redo.add_do_property(ProjectSettings, "resource_remaps", remaps)
	undo_redo.add_undo_property(ProjectSettings, "resource_remaps", ProjectSettings.get_setting("resource_remaps"))
	undo_redo.add_do_method(update_res_remaps)
	undo_redo.add_undo_method(update_res_remaps)
	undo_redo.commit_action()
	ProjectSettings.save()

func _res_remap_option_delete(p_item: Object, p_column: int, p_button: int, p_mouse_button: MouseButton) -> void:
	if updating_res_remaps:
		return

	if p_mouse_button != MOUSE_BUTTON_LEFT:
		return

	if !ProjectSettings.has_setting("resource_remaps"):
		return

	var remaps: Dictionary = ProjectSettings.get_setting("resource_remaps")

	var k: TreeItem = res_remap.get_selected()
	if k == null:
		return
	var ed: TreeItem = p_item as TreeItem
	if ed == null:
		return

	var key: String = k.get_metadata(0)
	var feature: String = ed.get_metadata(0)

	if !remaps.has(key):
		return
	var r: Array[PackedStringArray] = remaps[key]
	var idx: int = -1
	for i in range(r.size()):
		if r[i][0] == feature:
			idx = i
			break
	if idx < 0:
		return
	r.remove_at(idx)
	remaps[key] = r

	undo_redo.create_action(TTR("Remove Resource Remap Option"))
	undo_redo.add_do_property(ProjectSettings, "resource_remaps", remaps)
	undo_redo.add_undo_property(ProjectSettings, "resource_remaps", ProjectSettings.get_setting("resource_remaps"))
	undo_redo.add_do_method(update_res_remaps)
	undo_redo.add_undo_method(update_res_remaps)
	undo_redo.commit_action()
	ProjectSettings.save()

func connect_filesystem_dock_signals(p_fs_dock: FileSystemDock) -> void:
	p_fs_dock.files_moved.connect(_filesystem_files_moved)
	p_fs_dock.file_removed.connect(_filesystem_file_removed)

func _filesystem_files_moved(p_old_file: String, p_new_file: String) -> void:
	var remaps: Dictionary = {}
	var remaps_changed: bool = false

	if ProjectSettings.has_setting("resource_remaps"):
		remaps = ProjectSettings.get_setting("resource_remaps")

	# Check for the keys.
	if remaps.has(p_old_file):
		var remapped_files: Array[PackedStringArray] = remaps[p_old_file]
		remaps.erase(p_old_file)
		remaps[p_new_file] = remapped_files
		remaps_changed = true
		print_verbose("Changed remap key \"%s\" to \"%s\" due to a moved file." % [p_old_file, p_new_file])

	# Check for the Array elements of the values.
	var remap_keys: Array = remaps.keys()
	for i in range(remap_keys.size()):
		var remapped_files: Array[PackedStringArray] = remaps[remap_keys[i]]
		var remapped_files_updated: bool = false

		for j in range(remapped_files.size()):
			var res_path: String = remapped_files[j][1]

			if res_path == p_old_file:
				var feature: String = remapped_files[j][0]
				# Replace the element at that index.
				remapped_files[j][1] = p_new_file
				remaps_changed = true
				remapped_files_updated = true
				# TODO: not sure if this prints anything useful anymore:
				print_verbose("Changed remap value \"%s\" to \"%s\" of key \"%s\" due to a moved file." % [feature + ":" + res_path, remapped_files[j], remap_keys[i]])

		if remapped_files_updated:
			remaps[remap_keys[i]] = remapped_files

	if remaps_changed:
		ProjectSettings.set_setting("resource_remaps", remaps)
		ProjectSettings.save()
		update_res_remaps()

func _filesystem_file_removed(p_file: String) -> void:
	# Check if the remaps are affected.
	var remaps: Dictionary

	if ProjectSettings.has_setting("resource_remaps"):
		remaps = ProjectSettings.get_setting("resource_remaps")

	var remaps_changed: bool = remaps.has(p_file)

	if !remaps_changed:
		var remap_keys: Array = remaps.keys()
		for i in range(remap_keys.size()):
			var remapped_files: Array[PackedStringArray] = remaps[remap_keys[i]]
			for j in range(remapped_files.size()):
				var res_path: String = remapped_files[j][1]
				if p_file == res_path:
					remaps_changed = true
					# TODO: not sure if this prints anything useful anymore:
					print_verbose("Remap value \"%s\" of key \"%s\" has been removed from the file system." % [remapped_files[j], remap_keys[i]])
					break
			if remaps_changed:
				break
	else:
		print_verbose("Remap key \"%s\" has been removed from the file system." % p_file)

	if remaps_changed:
		update_res_remaps()

func update_res_remaps() -> void:
	if updating_res_remaps:
		return

	updating_res_remaps = true

	# Update resource remaps.
	var remap_selected: String
	if res_remap.get_selected():
		remap_selected = res_remap.get_selected().get_metadata(0)

	res_remap.clear()
	res_remap_options.clear()
	var root: TreeItem = res_remap.create_item()
	var root2: TreeItem = res_remap_options.create_item()
	res_remap.set_hide_root(true)
	res_remap_options.set_hide_root(true)
	res_remap_option_add_button.disabled = true

	if ProjectSettings.has_setting("resource_remaps"):
		var remaps: Dictionary = ProjectSettings.get_setting("resource_remaps")
		var keys: Array = remaps.keys()
		keys.sort()

		for key:String in keys:
			var t: TreeItem = res_remap.create_item(root)
			t.set_editable(0, false)
			t.set_text(0, key.replace("res://", ""))
			t.set_tooltip_text(0, key)
			t.set_metadata(0, key)
			var remove_icon: Texture2D = EditorInterface.get_base_control().get_theme_icon(&"Remove", &"EditorIcons")
			t.add_button(0, remove_icon, 0, false, TTR("Remove"))

			# Display that it has been removed if this is the case.
			if !FileAccess.file_exists(key):
				t.set_text(0, t.get_text(0) + " (" + TTR("Removed") + ")")
				t.set_tooltip_text(0, key + TTR(" cannot be found."))

			if key == remap_selected:
				t.select(0)
				res_remap_option_add_button.disabled = false

				var selected: Array[PackedStringArray] = remaps[key]
				for j in range(selected.size()):
					var s2: PackedStringArray = selected[j]
					var path: String = s2[1]
					var feature: String = s2[0]

					var t2: TreeItem = res_remap_options.create_item(root2)
					t2.set_editable(0, false)
					t2.set_text(0, path.replace("res://", ""))
					t2.set_tooltip_text(0, path)
					t2.set_metadata(0, feature)
					t2.add_button(0, remove_icon, 0, false, TTR("Remove"))
					t2.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
					t2.set_text(1, "feature,ios,pc") # TODO: actually set this up similar to the project settings list
					t2.set_metadata(1, feature)
					t2.set_editable(1, true)
					t2.set_tooltip_text(1, feature)

					## Display that it has been removed if this is the case.
					if !FileAccess.file_exists(path):
						t2.set_text(0, str([t2.get_text(0), " (", TTR("Removed"), ")"]))
						t2.set_tooltip_text(0, str([t2.get_tooltip_text(0), TTR(" cannot be found.")]))

	updating_res_remaps = false

func _init() -> void:
	name = TTR("Resource Remaps")

	var container: MarginContainer = MarginContainer.new()
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(container)

	var tvb: VBoxContainer = VBoxContainer.new()
	tvb.name = TTR("Remaps")
	container.add_child(tvb)

	var thb: HBoxContainer = HBoxContainer.new()
	var l: Label = Label.new()
	l.text = TTR("Resources:")
	l.theme_type_variation = "HeaderSmall"
	thb.add_child(l)
	thb.add_spacer(false)
	tvb.add_child(thb)

	var addtr: Button = Button.new()
	addtr.text = TTR("Add...")
	addtr.pressed.connect(_res_remap_file_open)
	thb.add_child(addtr)

	var tmc: VBoxContainer = VBoxContainer.new()
	tmc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tvb.add_child(tmc)

	res_remap = Tree.new()
	res_remap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	res_remap.cell_selected.connect(_res_remap_select)
	res_remap.button_clicked.connect(_res_remap_delete)
	tmc.add_child(res_remap)

	res_remap_file_open_dialog = EditorFileDialog.new()
	res_remap_file_open_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILES
	res_remap_file_open_dialog.files_selected.connect(_res_remap_add)
	add_child(res_remap_file_open_dialog)

	thb = HBoxContainer.new()
	l = Label.new()
	l.text = TTR("Remaps by Feature:")
	l.theme_type_variation = "HeaderSmall"
	thb.add_child(l)
	thb.add_spacer(false)
	tvb.add_child(thb)

	addtr = Button.new()
	addtr.text = TTR("Add...")
	addtr.pressed.connect(_res_remap_option_file_open)
	res_remap_option_add_button = addtr
	thb.add_child(addtr)

	tmc = VBoxContainer.new()
	tmc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tvb.add_child(tmc)

	res_remap_options = Tree.new()
	res_remap_options.size_flags_vertical = Control.SIZE_EXPAND_FILL
	res_remap_options.columns = 2
	res_remap_options.set_column_title(0, TTR("Path"))
	res_remap_options.set_column_title(1, TTR("Feature"))
	res_remap_options.column_titles_visible = true
	res_remap_options.set_column_expand(0, true)
	res_remap_options.set_column_clip_content(0, true)
	res_remap_options.set_column_expand(1, false)
	res_remap_options.set_column_clip_content(1, false)
	res_remap_options.set_column_custom_minimum_width(1, 250)
	res_remap_options.item_edited.connect(_res_remap_option_changed)
	res_remap_options.button_clicked.connect(_res_remap_option_delete)
	tmc.add_child(res_remap_options)

	res_remap_option_file_open_dialog = EditorFileDialog.new()
	res_remap_option_file_open_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILES
	res_remap_option_file_open_dialog.files_selected.connect(_res_remap_option_add)
	add_child(res_remap_option_file_open_dialog)

func _ready() -> void:
	update_res_remaps()
