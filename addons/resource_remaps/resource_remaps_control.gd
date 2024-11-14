# MIT License
#
# Copyright (c) 2024 Allen Pestaluky
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# This class was originally copied from the LocalizationEditor C++ class of Godot.
# Much of the structure and naming follows the names of that class. Original license:
#/**************************************************************************/
#/*  localization_editor.cpp                                               */
#/**************************************************************************/
#/*                         This file is part of:                          */
#/*                             GODOT ENGINE                               */
#/*                        https://godotengine.org                         */
#/**************************************************************************/
#/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
#/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
#/*                                                                        */
#/* Permission is hereby granted, free of charge, to any person obtaining  */
#/* a copy of this software and associated documentation files (the        */
#/* "Software"), to deal in the Software without restriction, including    */
#/* without limitation the rights to use, copy, modify, merge, publish,    */
#/* distribute, sublicense, and/or sell copies of the Software, and to     */
#/* permit persons to whom the Software is furnished to do so, subject to  */
#/* the following conditions:                                              */
#/*                                                                        */
#/* The above copyright notice and this permission notice shall be         */
#/* included in all copies or substantial portions of the Software.        */
#/*                                                                        */
#/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
#/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
#/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
#/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
#/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
#/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
#/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
#/**************************************************************************/

class_name ResourceRemapControl
extends VBoxContainer

const PROJECT_SETTINGS_PROPERTY: StringName = &"resource_remaps"
const UPDATE_METHOD_STR: StringName = &"update_res_remaps"
const UNDO_REDO_METHOD_STR: StringName = &"_undo_redo_callback"

const HANDLE_COL: int = 0
const FEATURE_COL: int = 1
const PATH_COL: int = 2

const TREE_ITEM_DRAG_ID: StringName = &"Resource Remap Tree Item"

var undo_redo: EditorUndoRedoManager

var _save_timer: Timer

var _res_remap_option_add_button: Button = null
var _res_remap_file_open_dialog: EditorFileDialog = null
var _res_remap_option_file_open_dialog: EditorFileDialog = null
## List of resource paths
var _res_remap: Tree = null
## List of remaps for selected resource
var _res_remap_options: ResoureRemapTree = null

var _updating_res_remaps: bool = false
var _recently_added_res_path: String = String()


func _init() -> void:
	name = TTR("Resource Remaps")

	_save_timer = Timer.new()
	_save_timer.wait_time = 1.5 # Matching ProjectSettingsEditor behaviour
	@warning_ignore("return_value_discarded")
	_save_timer.timeout.connect(ProjectSettings.save)
	_save_timer.one_shot = true
	add_child(_save_timer)

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
	@warning_ignore("return_value_discarded")
	thb.add_spacer(false)
	tvb.add_child(thb)

	var addtr: Button = Button.new()
	addtr.text = TTR("Add...")
	@warning_ignore("return_value_discarded")
	addtr.pressed.connect(_res_remap_file_open)
	thb.add_child(addtr)

	var tmc: VBoxContainer = VBoxContainer.new()
	tmc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tvb.add_child(tmc)

	_res_remap = Tree.new()
	_res_remap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	@warning_ignore("return_value_discarded")
	_res_remap.cell_selected.connect(_res_remap_select)
	@warning_ignore("return_value_discarded")
	_res_remap.button_clicked.connect(_res_remap_delete)
	tmc.add_child(_res_remap)

	_res_remap_file_open_dialog = EditorFileDialog.new()
	_res_remap_file_open_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILES
	@warning_ignore("return_value_discarded")
	_res_remap_file_open_dialog.files_selected.connect(_res_remap_add)
	add_child(_res_remap_file_open_dialog)

	thb = HBoxContainer.new()
	l = Label.new()
	l.text = TTR("Remaps by Feature:")
	l.tooltip_text = TTR("From top to bottom, the first remap in this list to match a feature in the export will be used.\nAny resources in this list that are not used will be excluded from the export.")
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	l.theme_type_variation = "HeaderSmall"
	thb.add_child(l)
	@warning_ignore("return_value_discarded")
	thb.add_spacer(false)
	tvb.add_child(thb)

	addtr = Button.new()
	addtr.text = TTR("Add...")
	@warning_ignore("return_value_discarded")
	addtr.pressed.connect(_res_remap_option_file_open)
	_res_remap_option_add_button = addtr
	thb.add_child(addtr)

	tmc = VBoxContainer.new()
	tmc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tvb.add_child(tmc)

	_res_remap_options = ResoureRemapTree.new()
	_res_remap_options.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_res_remap_options.columns = 3
	_res_remap_options.set_column_title(FEATURE_COL, TTR("Feature"))
	_res_remap_options.set_column_title(PATH_COL, TTR("Path"))
	_res_remap_options.column_titles_visible = true
	_res_remap_options.set_column_expand(PATH_COL, true)
	_res_remap_options.set_column_clip_content(FEATURE_COL, true)
	_res_remap_options.set_column_expand(FEATURE_COL, false)
	_res_remap_options.set_column_clip_content(FEATURE_COL, false)
	_res_remap_options.set_column_custom_minimum_width(FEATURE_COL, 220)
	_res_remap_options.set_column_clip_content(HANDLE_COL, true)
	_res_remap_options.set_column_expand(HANDLE_COL, false)
	_res_remap_options.set_column_clip_content(HANDLE_COL, false)
	_res_remap_options.set_column_custom_minimum_width(HANDLE_COL, int(EditorInterface.get_base_control().get_theme_icon(&"TripleBar", &"EditorIcons").get_size().x) + 32)
	@warning_ignore("return_value_discarded")
	_res_remap_options.item_edited.connect(_res_remap_option_changed)
	@warning_ignore("return_value_discarded")
	_res_remap_options.button_clicked.connect(_res_remap_option_delete)
	@warning_ignore("return_value_discarded")
	_res_remap_options.tree_items_reordered.connect(_res_remap_option_reorderd)
	tmc.add_child(_res_remap_options)

	_res_remap_option_file_open_dialog = EditorFileDialog.new()
	_res_remap_option_file_open_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILES
	@warning_ignore("return_value_discarded")
	_res_remap_option_file_open_dialog.files_selected.connect(_res_remap_option_add)
	add_child(_res_remap_option_file_open_dialog)


func _ready() -> void:
	update_res_remaps()


func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_VISIBILITY_CHANGED:
			# Refresh when this view is shown to grab new custom features, etc.
			if visible:
				update_res_remaps()


func _enter_tree() -> void:
	@warning_ignore("return_value_discarded")
	EditorInterface.get_file_system_dock().files_moved.connect(_filesystem_files_moved)

	_res_remap_file_open_dialog.clear_filters()
	var rfn: PackedStringArray = ResourceLoader.get_recognized_extensions_for_type("Resource")
	for E: String in rfn:
		_res_remap_file_open_dialog.add_filter("*." + E)


func _exit_tree() -> void:
	EditorInterface.get_file_system_dock().files_moved.disconnect(_filesystem_files_moved)

#region Debugging Functions
#func duplicate_remaps(remaps: Dictionary) -> Dictionary:
	#var result: Dictionary
	#for path: String in remaps.keys():
		#var old_remap: Array[PackedStringArray] = remaps[path]
		#var new_remap: Array[PackedStringArray]
		#for feature_map: PackedStringArray in old_remap:
			#var new_feature_remap: PackedStringArray
			#for i: int in range(feature_map.size()):
				#var str_copy: String = feature_map[i]
				#new_feature_remap.push_back(str_copy)
			#new_remap.push_back(new_feature_remap)
		#result[path] = new_remap
	#
	#return result
#endregion


func queue_save() -> void:
	_save_timer.start()


func update_res_remaps() -> void:
	if _updating_res_remaps:
		return

	_updating_res_remaps = true

	var features: PackedStringArray
	# Order doesn't matter on the technical side, but I think users would like
	# this ordering:
	_add_custom_features(features)
	features.sort()
	_add_platform_features(features)
	_add_export_features(features)
	# Not including preset features because it's unlikely that anyone would ever want
	# to remap resources based on these features:
	#_add_preset_features(features)

	# Update resource remaps.
	var remap_selected: String
	var should_scroll: bool = false
	if _recently_added_res_path != String():
		remap_selected = _recently_added_res_path
		_recently_added_res_path = String()
		should_scroll = true
	elif _res_remap.get_selected():
		remap_selected = _res_remap.get_selected().get_metadata(0)
	var selected_ti: TreeItem = null

	_res_remap.clear()
	_res_remap_options.clear()
	var root: TreeItem = _res_remap.create_item()
	var root_options: TreeItem = _res_remap_options.create_item()
	_res_remap.set_hide_root(true)
	_res_remap_options.set_hide_root(true)
	_res_remap_option_add_button.disabled = true

	if ProjectSettings.has_setting(PROJECT_SETTINGS_PROPERTY):
		var remaps: Dictionary = ProjectSettings.get_setting(PROJECT_SETTINGS_PROPERTY)
		var keys: Array = remaps.keys()
		keys.sort()

		for key: String in keys: # key is the path in _res_remap
			var t: TreeItem = _res_remap.create_item(root)
			t.set_editable(0, false)
			t.set_text(0, key.replace("res://", ""))
			t.set_tooltip_text(0, key)
			t.set_metadata(0, key) # Used for mataining selection of this tree item
			var remove_icon: Texture2D = EditorInterface.get_base_control().get_theme_icon(&"Remove", &"EditorIcons")
			t.add_button(0, remove_icon, 0, false, TTR("Remove"))

			# Display that it has been removed if this is the case.
			if !FileAccess.file_exists(key):
				t.set_text(0, t.get_text(0) + " " + TTR("(Removed)"))
				t.set_tooltip_text(0, TTR("%s cannot be found.") % key)

			if key == remap_selected:
				t.select(0)
				selected_ti = t
				_res_remap_option_add_button.disabled = false
				_res_remap_option_file_open_dialog.clear_filters()
				_res_remap_option_file_open_dialog.add_filter("*." + key.get_extension())

				var selected: Array[PackedStringArray] = remaps[key]
				for j: int in range(selected.size()):
					var s2: PackedStringArray = selected[j]
					var feature: String = s2[0]
					var path: String = s2[1]

					var available_features: PackedStringArray = features.duplicate()
					for this_remap: PackedStringArray in selected:
						if this_remap[0] != feature:
							var feature_index: int = available_features.find(this_remap[0])
							if feature_index > -1:
								available_features.remove_at(feature_index)
					var this_features_str: String = get_features_range_string(available_features)
					var features_index: int = available_features.find(feature)
					# We're using an unknown feature, so add it onto the start of the list:
					if features_index < 0:
						this_features_str = feature + "," + this_features_str
						features_index = 0

					var t2: TreeItem = _res_remap_options.create_item(root_options)

					t2.set_metadata(HANDLE_COL, j) # Index used for deleting and changing TreeItems in res_remap_option
					var tripple_bar_icon: Texture2D = EditorInterface.get_base_control().get_theme_icon(&"TripleBar", &"EditorIcons")
					t2.set_cell_mode(HANDLE_COL, TreeItem.CELL_MODE_ICON)
					t2.set_icon(HANDLE_COL, tripple_bar_icon)

					t2.set_cell_mode(FEATURE_COL, TreeItem.CELL_MODE_RANGE)
					t2.set_text(FEATURE_COL, this_features_str)
					t2.set_range(FEATURE_COL, features_index)
					t2.set_editable(FEATURE_COL, true)
					t2.set_tooltip_text(FEATURE_COL, feature)
					t2.set_metadata(FEATURE_COL, TREE_ITEM_DRAG_ID) # Used by ResourceRemapTree to determine if this TreeItem can be dropped into the Tree

					t2.set_editable(PATH_COL, false)
					t2.set_text(PATH_COL, path.replace("res://", ""))
					t2.set_tooltip_text(PATH_COL, path)
					t2.add_button(PATH_COL, remove_icon, 0, false, TTR("Remove"))
					t2.set_metadata(PATH_COL, path) # Path is used for saving to project settings when the TreeItems are reordered

					## Display that it has been removed if this is the case.
					if !FileAccess.file_exists(path):
						t2.set_text(PATH_COL, t2.get_text(PATH_COL) + " " + TTR("(Removed)"))
						t2.set_tooltip_text(PATH_COL, TTR("%s cannot be found.") % t2.get_tooltip_text(PATH_COL))

	if should_scroll and selected_ti != null:
		_res_remap.scroll_to_item(selected_ti)

	_updating_res_remaps = false


func TTR(text: String) -> String:
	# text should be translated here
	return text


static func get_features_range_string(features: PackedStringArray) -> String:
	var features_str: String = ""
	for feat: String in features:
		features_str += feat + ","
	return features_str.substr(0, features_str.length() - 1)


static func get_selected_feature_from_rage(ti: TreeItem) -> String:
	var features: PackedStringArray = ti.get_text(FEATURE_COL).split(",")
	return features[clampi(int(ti.get_range(FEATURE_COL)), 0, features.size() - 1)]


func _res_remap_file_open() -> void:
	_res_remap_file_open_dialog.popup_file_dialog()


func _res_remap_add(p_paths: PackedStringArray) -> void:
	var remaps: Dictionary
	var prev_remaps: Dictionary

	if ProjectSettings.has_setting(PROJECT_SETTINGS_PROPERTY):
		var setting: Variant = ProjectSettings.get_setting(PROJECT_SETTINGS_PROPERTY)
		if setting is Dictionary:
			@warning_ignore("unsafe_cast")
			remaps = (setting as Dictionary).duplicate(true)
			@warning_ignore("unsafe_cast")
			prev_remaps = (setting as Dictionary).duplicate(true)

	var added_new_path: bool = false
	for path: String in p_paths:
		if !remaps.has(path):
			# Don't overwrite with an empty remap array if an array already exists for the given path.
			var new_array: Array[PackedStringArray]
			remaps[path] = new_array
			added_new_path = true
			_recently_added_res_path = path

	if added_new_path:
		undo_redo.create_action(TTR("Resource Remaps: Add %d path(s)") % p_paths.size())
		undo_redo.add_do_property(ProjectSettings, PROJECT_SETTINGS_PROPERTY, remaps)
		undo_redo.add_undo_property(ProjectSettings, PROJECT_SETTINGS_PROPERTY, prev_remaps)
		undo_redo.add_do_method(self, UNDO_REDO_METHOD_STR)
		undo_redo.add_undo_method(self, UNDO_REDO_METHOD_STR)
		undo_redo.commit_action()


func _res_remap_option_file_open() -> void:
	_res_remap_option_file_open_dialog.popup_file_dialog()


func _res_remap_option_add(p_paths: PackedStringArray) -> void:
	if !ProjectSettings.has_setting(PROJECT_SETTINGS_PROPERTY):
		return

	var remaps: Dictionary
	var prev_remaps: Dictionary

	var setting: Variant = ProjectSettings.get_setting(PROJECT_SETTINGS_PROPERTY)
	if setting is Dictionary:
		@warning_ignore("unsafe_cast")
		remaps = (setting as Dictionary).duplicate(true)
		@warning_ignore("unsafe_cast")
		prev_remaps = (setting as Dictionary).duplicate(true)

	var k: TreeItem = _res_remap.get_selected()
	if k == null:
		return

	var key: String = k.get_metadata(0) # key is the path in _res_remap

	if !remaps.has(key):
		return

	var r: Array[PackedStringArray] = remaps[key]
	for path: String in p_paths:
		var remap_array: PackedStringArray
		@warning_ignore("return_value_discarded")
		remap_array.append("(not configured)")
		@warning_ignore("return_value_discarded")
		remap_array.append(path)
		r.append(remap_array)
	remaps[key] = r

	undo_redo.create_action(TTR("Resource Remaps: Add %d remap(s)") % p_paths.size())
	undo_redo.add_do_property(ProjectSettings, PROJECT_SETTINGS_PROPERTY, remaps)
	undo_redo.add_undo_property(ProjectSettings, PROJECT_SETTINGS_PROPERTY, prev_remaps)
	undo_redo.add_do_method(self, UNDO_REDO_METHOD_STR)
	undo_redo.add_undo_method(self, UNDO_REDO_METHOD_STR)
	undo_redo.commit_action()


func _res_remap_select() -> void:
	if _updating_res_remaps:
		return
	call_deferred(UPDATE_METHOD_STR)


func _res_remap_option_changed() -> void:
	if _updating_res_remaps:
		return

	if !ProjectSettings.has_setting(PROJECT_SETTINGS_PROPERTY):
		return

	var remaps: Dictionary
	var prev_remaps: Dictionary

	var setting: Variant = ProjectSettings.get_setting(PROJECT_SETTINGS_PROPERTY)
	if setting is Dictionary:
		@warning_ignore("unsafe_cast")
		remaps = (setting as Dictionary).duplicate(true)
		@warning_ignore("unsafe_cast")
		prev_remaps = (setting as Dictionary).duplicate(true)

	var k: TreeItem = _res_remap.get_selected()
	if k == null:
		return
	var ed: TreeItem = _res_remap_options.get_edited()
	if ed == null:
		return

	var key: String = k.get_metadata(0) # key is the path in _res_remap
	var idx: int = ed.get_metadata(HANDLE_COL);
	var new_feature: String = get_selected_feature_from_rage(ed)

	if !remaps.has(key):
		return
	var r: Array[PackedStringArray] = remaps[key]
	r[idx][0] = new_feature
	remaps[key] = r

	undo_redo.create_action(TTR("Resource Remaps: Change remap feature to %s") % new_feature)
	undo_redo.add_do_property(ProjectSettings, PROJECT_SETTINGS_PROPERTY, remaps)
	undo_redo.add_undo_property(ProjectSettings, PROJECT_SETTINGS_PROPERTY, prev_remaps)
	undo_redo.add_do_method(self, UNDO_REDO_METHOD_STR)
	undo_redo.add_undo_method(self, UNDO_REDO_METHOD_STR)
	undo_redo.commit_action()


func _res_remap_delete(p_item: Object, _p_column: int, _p_button: int, p_mouse_button: int) -> void:
	if _updating_res_remaps:
		return

	if p_mouse_button != MOUSE_BUTTON_LEFT:
		return

	if !ProjectSettings.has_setting(PROJECT_SETTINGS_PROPERTY):
		return

	var remaps: Dictionary
	var prev_remaps: Dictionary

	var setting: Variant = ProjectSettings.get_setting(PROJECT_SETTINGS_PROPERTY)
	if setting is Dictionary:
		@warning_ignore("unsafe_cast")
		remaps = (setting as Dictionary).duplicate(true)
		@warning_ignore("unsafe_cast")
		prev_remaps = (setting as Dictionary).duplicate(true)

	var k: TreeItem = p_item as TreeItem
	if k == null:
		return

	var key: String = k.get_metadata(0) # key is the path in _res_remap
	if !remaps.has(key):
		return

	@warning_ignore("return_value_discarded")
	remaps.erase(key)

	undo_redo.create_action(TTR("Resource Remaps: Remove path %s") % key)
	undo_redo.add_do_property(ProjectSettings, PROJECT_SETTINGS_PROPERTY, remaps)
	undo_redo.add_undo_property(ProjectSettings, PROJECT_SETTINGS_PROPERTY, prev_remaps)
	undo_redo.add_do_method(self, UNDO_REDO_METHOD_STR)
	undo_redo.add_undo_method(self, UNDO_REDO_METHOD_STR)
	undo_redo.commit_action()


func _res_remap_option_delete(p_item: Object, _p_column: int, _p_button: int, p_mouse_button: MouseButton) -> void:
	if _updating_res_remaps:
		return

	if p_mouse_button != MOUSE_BUTTON_LEFT:
		return

	if !ProjectSettings.has_setting(PROJECT_SETTINGS_PROPERTY):
		return

	var remaps: Dictionary
	var prev_remaps: Dictionary

	var setting: Variant = ProjectSettings.get_setting(PROJECT_SETTINGS_PROPERTY)
	if setting is Dictionary:
		@warning_ignore("unsafe_cast")
		remaps = (setting as Dictionary).duplicate(true)
		@warning_ignore("unsafe_cast")
		prev_remaps = (setting as Dictionary).duplicate(true)

	var k: TreeItem = _res_remap.get_selected()
	if k == null:
		return
	var ed: TreeItem = p_item as TreeItem
	if ed == null:
		return

	var key: String = k.get_metadata(0) # key is the path in _res_remap
	var idx: int = ed.get_metadata(HANDLE_COL)

	if !remaps.has(key):
		return
	var r: Array[PackedStringArray] = remaps[key]
	r.remove_at(idx)
	remaps[key] = r
	# No need to update other TreeItem metadata because that will be recreated in update_res_remaps()

	undo_redo.create_action(TTR("Resource Remaps: Remove remap for path %s") % str(k.get_metadata(0)))
	undo_redo.add_do_property(ProjectSettings, PROJECT_SETTINGS_PROPERTY, remaps)
	undo_redo.add_undo_property(ProjectSettings, PROJECT_SETTINGS_PROPERTY, prev_remaps)
	undo_redo.add_do_method(self, UNDO_REDO_METHOD_STR)
	undo_redo.add_undo_method(self, UNDO_REDO_METHOD_STR)
	undo_redo.commit_action()


func _res_remap_option_reorderd(_item: TreeItem, _relative_to: TreeItem, _before: bool) -> void:
	if !ProjectSettings.has_setting(PROJECT_SETTINGS_PROPERTY):
		return

	var remaps: Dictionary
	var prev_remaps: Dictionary

	var setting: Variant = ProjectSettings.get_setting(PROJECT_SETTINGS_PROPERTY)
	if setting is Dictionary:
		@warning_ignore("unsafe_cast")
		remaps = (setting as Dictionary).duplicate(true)
		@warning_ignore("unsafe_cast")
		prev_remaps = (setting as Dictionary).duplicate(true)

	var k: TreeItem = _res_remap.get_selected()
	if k == null:
		return

	var key: String = k.get_metadata(0) # key is the path in _res_remap

	if !remaps.has(key):
		return

	var r: Array[PackedStringArray]

	var root: TreeItem = _res_remap_options.get_root()
	for i: int in range(root.get_child_count()):
		var ti: TreeItem = root.get_child(i)
		ti.set_metadata(HANDLE_COL, i)
		var this_remap: PackedStringArray
		@warning_ignore("return_value_discarded")
		this_remap.push_back(get_selected_feature_from_rage(ti))
		@warning_ignore("unsafe_cast", "return_value_discarded")
		this_remap.push_back(ti.get_metadata(PATH_COL) as String)
		r.push_back(this_remap)
	remaps[key] = r

	undo_redo.create_action(TTR("Resource Remaps: Reordered remaps for %s") % key)
	undo_redo.add_do_property(ProjectSettings, PROJECT_SETTINGS_PROPERTY, remaps)
	undo_redo.add_undo_property(ProjectSettings, PROJECT_SETTINGS_PROPERTY, prev_remaps)
	undo_redo.add_do_method(self, UNDO_REDO_METHOD_STR)
	undo_redo.add_undo_method(self, UNDO_REDO_METHOD_STR)
	undo_redo.commit_action()


func _filesystem_files_moved(p_old_file: String, p_new_file: String) -> void:
	var remaps: Dictionary = {}
	var remaps_changed: bool = false

	if ProjectSettings.has_setting(PROJECT_SETTINGS_PROPERTY):
		remaps = ProjectSettings.get_setting(PROJECT_SETTINGS_PROPERTY)

	# Check for the keys.
	if remaps.has(p_old_file):
		var remapped_files: Array[PackedStringArray] = remaps[p_old_file]
		@warning_ignore("return_value_discarded")
		remaps.erase(p_old_file)
		remaps[p_new_file] = remapped_files
		remaps_changed = true
		print_verbose("Changed remap key \"%s\" to \"%s\" due to a moved file." % [p_old_file, p_new_file])

	# Check for the Array elements of the values.
	var remap_keys: Array = remaps.keys()
	for i: int in range(remap_keys.size()):
		var remapped_files: Array[PackedStringArray] = remaps[remap_keys[i]]
		var remapped_files_updated: bool = false

		for j: int in range(remapped_files.size()):
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
		# No undo-redo for this because moving files also doesn't have undo-redo.
		ProjectSettings.set_setting(PROJECT_SETTINGS_PROPERTY, remaps)
		queue_save()
		update_res_remaps()


func _undo_redo_callback() -> void:
	queue_save()
	update_res_remaps()


func _add_string_if_new(value: String, psa: PackedStringArray) -> void:
	if !psa.has(value):
		@warning_ignore("return_value_discarded")
		psa.append(value)


func _add_platform_features(features: PackedStringArray) -> void:
	# This list is based off the default configuration of the Godot editor as of 4.4
	# There are other platform features that may exist for custom editor builds.
	_add_string_if_new("mobile", features);
	_add_string_if_new("android", features);
	_add_string_if_new("ios", features);
	_add_string_if_new("pc", features);
	_add_string_if_new("linux", features);
	_add_string_if_new("macos", features);
	_add_string_if_new("web", features);
	_add_string_if_new("windows", features);

#region Dynamic loading of platform features that requires https://github.com/godotengine/godot/pull/98251 or similar
	#var editor_export: EditorExport = EditorInterface.get_editor_export()
	#for i: int in range(editor_export.get_export_platform_count()):
		#var platform_features: Array[String] = editor_export.get_export_platform(i).get_platform_features()
		#for feature: String in platform_features:
			#_add_string_if_new(feature, features)
#endregion


func _add_export_features(features: PackedStringArray) -> void:
	# Add all of the features that EditorExportPlatform::get_features might add during the export process:
	_add_string_if_new("template", features);
	_add_string_if_new("debug", features);
	_add_string_if_new("template_debug", features);
	_add_string_if_new("release", features);
	_add_string_if_new("template_release", features);
	_add_string_if_new("double", features);
	_add_string_if_new("single", features);


func _add_preset_features(features: PackedStringArray) -> void:
	# This list is based off the default configuration of the Godot editor as of 4.3
	# There are other preset features that may exist for custom editor builds.
	_add_string_if_new("etc2", features);
	_add_string_if_new("astc", features);
	_add_string_if_new("arm64", features);
	_add_string_if_new("bptc", features);
	_add_string_if_new("x86_64", features);
	_add_string_if_new("universal", features);
	_add_string_if_new("nothreads", features);
	_add_string_if_new("wasm32", features);

#region Dynamic loading of preset features that requires https://github.com/godotengine/godot/pull/98251 or similar
	#var editor_export: EditorExport = EditorInterface.get_editor_export()
	#for i: int in range(editor_export.get_export_preset_count()):
		#var preset: EditorExportPreset = editor_export.get_export_preset(i)
		#var preset_features: Array[String] = preset.get_platform().get_preset_features(preset)
		#for feature: String in preset_features:
			#_add_string_if_new(feature, features)
#endregion


func _add_custom_features(features: PackedStringArray) -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load("res://export_presets.cfg")
	if err != OK:
		return

	for section: String in config.get_sections():
		var custom_features: String = config.get_value(section, "custom_features", "")
		for feature: String in custom_features.split(",", false):
			feature = feature.strip_edges()
			if !feature.is_empty():
				_add_string_if_new(feature, features)

#region Minor optimization that requires https://github.com/godotengine/godot/pull/98251 or similar
	#var editor_export: EditorExport = EditorInterface.get_editor_export()
	#for i: int in range(editor_export.get_export_preset_count()):
		#var preset: EditorExportPreset = editor_export.get_export_preset(i)
		#var custom_features: String = preset.get_custom_features()
		#for feature: String in custom_features.split(",", false):
			#feature = feature.strip_edges()
			#if !feature.is_empty():
				#_add_string_if_new(feature, features)
#endregion


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
		var result: bool = data is TreeItem && (data as TreeItem).get_metadata(FEATURE_COL) == TREE_ITEM_DRAG_ID
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
