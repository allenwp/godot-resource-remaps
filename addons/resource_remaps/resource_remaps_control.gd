#TODO: add license and note about being copied from Godot source
# This class was originally copied from the LocalizationEditor C++ class of Godot.
# Much of the structure and naming follows the names of that class.
class_name ResourceRemapControl extends VBoxContainer

var res_remap_option_add_button: Button = null
var res_remap_file_open_dialog: EditorFileDialog = null
var res_remap_option_file_open_dialog: EditorFileDialog = null
## List of resources
var res_remap: Tree = null
## List of remaps for selected resource
var res_remap_options: ResoureRemapTree = null

var updating_res_remaps: bool = false
var recently_added_res_path: String = String()

# FIXME: UndoRedo has been written, but doesn't work. Might be related to [TODO: file bug report]
var undo_redo: UndoRedo = UndoRedo.new()

const handle_col = 0
const feature_col = 1
const path_col = 2

const tree_item_drag_id = "Resource Remap Tree Item"

func TTR(text: String) -> String:
	# TODO: translate text.
	return text

func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_VISIBILITY_CHANGED:
			# Refresh when this view is shown to grab new custom features, etc.
			if visible:
				update_res_remaps()

func _res_remap_file_open() -> void:
	res_remap_file_open_dialog.popup_file_dialog()

func _res_remap_add(p_paths: PackedStringArray) -> void:
	var prev: Variant
	var remaps: Dictionary

	if ProjectSettings.has_setting("resource_remaps"):
		remaps = ProjectSettings.get_setting("resource_remaps")
		prev = remaps

	var added_new_path: bool = false
	for path in p_paths:
		if !remaps.has(path):
			# Don't overwrite with an empty remap array if an array already exists for the given path.
			var new_array: Array[PackedStringArray]
			remaps[path] = new_array
			added_new_path = true
			recently_added_res_path = path

	if added_new_path:
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

	var key: String = k.get_metadata(0) # key is the path in res_remap

	if !remaps.has(key):
		return

	var r: Array[PackedStringArray] = remaps[key]
	for path in p_paths:
		var remap_array: PackedStringArray
		remap_array.append("(not configured)")
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

	var key: String = k.get_metadata(0) # key is the path in res_remap
	var idx: int = ed.get_metadata(handle_col);
	var new_feature: String = get_selected_feature_from_rage(ed)

	if !remaps.has(key):
		return
	var r: Array[PackedStringArray] = remaps[key]
	r[idx][0] = new_feature
	remaps[key] = r

	undo_redo.create_action(TTR("Change Resource Remap Feature"))
	undo_redo.add_do_property(ProjectSettings, "resource_remaps", remaps)
	undo_redo.add_undo_property(ProjectSettings, "resource_remaps", ProjectSettings.get_setting("resource_remaps"))
	undo_redo.add_do_method(update_res_remaps)
	undo_redo.add_undo_method(update_res_remaps)
	undo_redo.commit_action()
	ProjectSettings.save()

func _res_remap_delete(p_item: Object, _p_column: int, _p_button: int, p_mouse_button: int) -> void:
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

	var key: String = k.get_metadata(0) # key is the path in res_remap
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

func _res_remap_option_delete(p_item: Object, _p_column: int, _p_button: int, p_mouse_button: MouseButton) -> void:
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

	var key: String = k.get_metadata(0) # key is the path in res_remap
	var idx: int = ed.get_metadata(handle_col)

	if !remaps.has(key):
		return
	var r: Array[PackedStringArray] = remaps[key]
	r.remove_at(idx)
	remaps[key] = r
	# No need to update other TreeItem metadata because that will be recreated in update_res_remaps()

	undo_redo.create_action(TTR("Remove Resource Remap Option"))
	undo_redo.add_do_property(ProjectSettings, "resource_remaps", remaps)
	undo_redo.add_undo_property(ProjectSettings, "resource_remaps", ProjectSettings.get_setting("resource_remaps"))
	undo_redo.add_do_method(update_res_remaps)
	undo_redo.add_undo_method(update_res_remaps)
	undo_redo.commit_action()
	ProjectSettings.save()

func _res_remap_option_reorderd(_item: TreeItem, _relative_to: TreeItem, _before: bool) -> void:
	if !ProjectSettings.has_setting("resource_remaps"):
		return

	var remaps: Dictionary = ProjectSettings.get_setting("resource_remaps")

	var k: TreeItem = res_remap.get_selected()
	if k == null:
		return

	var key: String = k.get_metadata(0) # key is the path in res_remap

	if !remaps.has(key):
		return

	var r: Array[PackedStringArray]

	var root: TreeItem = res_remap_options.get_root()
	for i: int in range(root.get_child_count()):
		var ti: TreeItem = root.get_child(i)
		ti.set_metadata(handle_col, i)
		var this_remap: PackedStringArray
		this_remap.push_back(get_selected_feature_from_rage(ti))
		@warning_ignore("unsafe_cast")
		this_remap.push_back(ti.get_metadata(path_col) as String)
		r.push_back(this_remap)
	remaps[key] = r

	undo_redo.create_action(TTR("Resource Remap: Reordered remaps for %s") % k)
	undo_redo.add_do_property(ProjectSettings, "resource_remaps", remaps)
	undo_redo.add_undo_property(ProjectSettings, "resource_remaps", ProjectSettings.get_setting("resource_remaps"))
	undo_redo.add_do_method(update_res_remaps)
	undo_redo.add_undo_method(update_res_remaps)
	undo_redo.commit_action()
	ProjectSettings.save()

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
				print_verbose("Changed remap value \"%s\" to \"%s\" of key \"%s\" due to a moved file." % [feature + ":" + res_path, remapped_files[j][0] + ":" + remapped_files[j][1], remap_keys[i]])

		if remapped_files_updated:
			remaps[remap_keys[i]] = remapped_files

	if remaps_changed:
		ProjectSettings.set_setting("resource_remaps", remaps)
		ProjectSettings.save()
		update_res_remaps()

func update_res_remaps() -> void:
	if updating_res_remaps:
		return

	updating_res_remaps = true

	var features: PackedStringArray

	var editor_export: EditorExport = EditorInterface.get_editor_export()
	for i: int in range(editor_export.get_export_platform_count()):
		var platform_features: Array[String] = editor_export.get_export_platform(i).get_platform_features()
		for feature: String in platform_features:
			if !features.has(feature):
				features.append(feature)

	# Add all of the features that EditorExportPlatform::get_features might add during the export process:
	features.append("template");
	features.append("debug");
	features.append("template_debug");
	features.append("release");
	features.append("template_release");
	features.append("double");
	features.append("single");

	for i: int in range(editor_export.get_export_preset_count()):
		var preset: EditorExportPreset = editor_export.get_export_preset(i)
		var preset_features: Array[String] = preset.get_platform().get_preset_features(preset)
		for feature: String in preset_features:
			if !features.has(feature):
				features.append(feature)

	# Put custom features at the end
	for i: int in range(editor_export.get_export_preset_count()):
		var preset: EditorExportPreset = editor_export.get_export_preset(i)
		var custom_features: String = preset.get_custom_features()
		for feature: String in custom_features.split(",", false):
			feature = feature.strip_edges()
			if !feature.is_empty() && !features.has(feature):
				features.append(feature)

	# Update resource remaps.
	var remap_selected: String
	var should_scroll: bool = false
	if recently_added_res_path != String():
		remap_selected = recently_added_res_path
		recently_added_res_path = String()
		should_scroll = true
	elif res_remap.get_selected():
		remap_selected = res_remap.get_selected().get_metadata(0)
	var selected_ti: TreeItem = null

	res_remap.clear()
	res_remap_options.clear()
	var root: TreeItem = res_remap.create_item()
	var root_options: TreeItem = res_remap_options.create_item()
	res_remap.set_hide_root(true)
	res_remap_options.set_hide_root(true)
	res_remap_option_add_button.disabled = true

	if ProjectSettings.has_setting("resource_remaps"):
		var remaps: Dictionary = ProjectSettings.get_setting("resource_remaps")
		var keys: Array = remaps.keys()
		keys.sort()

		for key: String in keys: # key is the path in res_remap
			var t: TreeItem = res_remap.create_item(root)
			t.set_editable(0, false)
			t.set_text(0, key.replace("res://", ""))
			t.set_tooltip_text(0, key)
			t.set_metadata(0, key) # Used for mataining selection of this tree item
			var remove_icon: Texture2D = EditorInterface.get_base_control().get_theme_icon(&"Remove", &"EditorIcons")
			t.add_button(0, remove_icon, 0, false, TTR("Remove"))

			# Display that it has been removed if this is the case.
			if !FileAccess.file_exists(key):
				t.set_text(0, t.get_text(0) + " (" + TTR("Removed") + ")")
				t.set_tooltip_text(0, key + TTR(" cannot be found."))

			if key == remap_selected:
				t.select(0)
				selected_ti = t
				res_remap_option_add_button.disabled = false

				var selected: Array[PackedStringArray] = remaps[key]
				for j in range(selected.size()):
					var s2: PackedStringArray = selected[j]
					var feature: String = s2[0]
					var path: String = s2[1]

					var available_features: PackedStringArray = features.duplicate()
					for this_remap: PackedStringArray in selected:
						if this_remap[0] != feature:
							var feature_index: int = available_features.find(this_remap[0])
							if feature_index > -1:
								available_features.remove_at(feature_index)
					var this_features_str: String = features_range_string(available_features)
					var features_index: int = available_features.find(feature)
					# We're using an unknown feature, so add it onto the start of the list:
					if features_index < 0:
						this_features_str = feature + "," + this_features_str
						features_index = 0

					var t2: TreeItem = res_remap_options.create_item(root_options)

					t2.set_metadata(handle_col, j) # Index used for deleting and changing TreeItems in res_remap_option
					var tripple_bar_icon: Texture2D = EditorInterface.get_base_control().get_theme_icon(&"TripleBar", &"EditorIcons")
					t2.set_cell_mode(handle_col, TreeItem.CELL_MODE_ICON)
					t2.set_icon(handle_col, tripple_bar_icon)

					t2.set_cell_mode(feature_col, TreeItem.CELL_MODE_RANGE)
					t2.set_text(feature_col, this_features_str)
					t2.set_range(feature_col, features_index)
					t2.set_editable(feature_col, true)
					t2.set_tooltip_text(feature_col, feature)
					t2.set_metadata(feature_col, tree_item_drag_id) # Used by ResourceRemapTree to determine if this TreeItem can be dropped into the Tree

					t2.set_editable(path_col, false)
					t2.set_text(path_col, path.replace("res://", ""))
					t2.set_tooltip_text(path_col, path)
					t2.add_button(path_col, remove_icon, 0, false, TTR("Remove"))
					t2.set_metadata(path_col, path) # Path is used for saving to project settings when the TreeItems are reordered

					## Display that it has been removed if this is the case.
					if !FileAccess.file_exists(path):
						t2.set_text(path_col, t2.get_text(path_col) + " (" + TTR("Removed") + ")")
						t2.set_tooltip_text(path_col, t2.get_tooltip_text(path_col) + TTR(" cannot be found."))

	if should_scroll and selected_ti != null:
		res_remap.scroll_to_item(selected_ti)

	updating_res_remaps = false

static func features_range_string(features: PackedStringArray) -> String:
	var features_str: String = ""
	for feat in features:
		features_str += feat + ","
	return features_str.substr(0, features_str.length() - 1)

static func get_selected_feature_from_rage(ti: TreeItem) -> String:
	var features: PackedStringArray = ti.get_text(feature_col).split(",")
	return features[clampi(int(ti.get_range(feature_col)), 0, features.size() - 1)]

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
	l.tooltip_text = TTR("From top to bottom, the first remap in this list to match a feature in the export will be used.\n\nAny resources in this list that are not used will be excluded from the export.")
	l.mouse_filter = Control.MOUSE_FILTER_PASS
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

	res_remap_options = ResoureRemapTree.new()
	res_remap_options.size_flags_vertical = Control.SIZE_EXPAND_FILL
	res_remap_options.columns = 3
	res_remap_options.set_column_title(feature_col, TTR("Feature"))
	res_remap_options.set_column_title(path_col, TTR("Path"))
	res_remap_options.column_titles_visible = true
	res_remap_options.set_column_expand(path_col, true)
	res_remap_options.set_column_clip_content(feature_col, true)
	res_remap_options.set_column_expand(feature_col, false)
	res_remap_options.set_column_clip_content(feature_col, false)
	res_remap_options.set_column_custom_minimum_width(feature_col, 220)
	res_remap_options.set_column_clip_content(handle_col, true)
	res_remap_options.set_column_expand(handle_col, false)
	res_remap_options.set_column_clip_content(handle_col, false)
	res_remap_options.set_column_custom_minimum_width(handle_col, int(EditorInterface.get_base_control().get_theme_icon(&"TripleBar", &"EditorIcons").get_size().x) + 32)
	res_remap_options.item_edited.connect(_res_remap_option_changed)
	res_remap_options.button_clicked.connect(_res_remap_option_delete)
	res_remap_options.tree_items_reordered.connect(_res_remap_option_reorderd)
	tmc.add_child(res_remap_options)

	res_remap_option_file_open_dialog = EditorFileDialog.new()
	res_remap_option_file_open_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILES
	res_remap_option_file_open_dialog.files_selected.connect(_res_remap_option_add)
	add_child(res_remap_option_file_open_dialog)

func _ready() -> void:
	update_res_remaps()

func _enter_tree() -> void:
	EditorInterface.get_file_system_dock().files_moved.connect(_filesystem_files_moved)

	res_remap_file_open_dialog.clear_filters()
	res_remap_option_file_open_dialog.clear_filters()
	var rfn: PackedStringArray = ResourceLoader.get_recognized_extensions_for_type("Resource")
	for E: String in rfn:
		res_remap_file_open_dialog.add_filter("*." + E)
		res_remap_option_file_open_dialog.add_filter("*." + E)

func _exit_tree() -> void:
	EditorInterface.get_file_system_dock().files_moved.disconnect(_filesystem_files_moved)


class ResoureRemapTree:
	extends Tree

	signal tree_items_reordered(item: TreeItem, relative_to: TreeItem, before: bool)

	func _get_drag_data(_at_position: Vector2) -> Variant:
		var ti: TreeItem = get_selected()
		var drag_preview: Control = Control.new()
		var preview_label: Label = Label.new()
		preview_label.position.x = 22 # If you grab the middle of the hanlde, this space aligns the text to be around the same horizontal position
		preview_label.text = ResourceRemapControl.get_selected_feature_from_rage(ti)
		drag_preview.add_child(preview_label)
		set_drag_preview(drag_preview)
		return ti

	func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
		if get_drop_section_at_position(at_position) == -100:
			return false

		@warning_ignore("unsafe_cast")
		var result: bool = data is TreeItem && (data as TreeItem).get_metadata(feature_col) == tree_item_drag_id
		if result:
			drop_mode_flags = DROP_MODE_INBETWEEN
		return result

	func _drop_data(at_position: Vector2, data: Variant) -> void:
		@warning_ignore("unsafe_cast")
		var dropped_item: TreeItem = data as TreeItem
		var drop_selection: int = get_drop_section_at_position(at_position)
		var item: TreeItem = get_item_at_position(at_position)
		if dropped_item == null || item == null:
			return

		if drop_selection < 0:
			dropped_item.move_before(item)
			tree_items_reordered.emit(dropped_item, item, true)
		elif drop_selection > 0:
			dropped_item.move_after(item)
			tree_items_reordered.emit(dropped_item, item, false)
