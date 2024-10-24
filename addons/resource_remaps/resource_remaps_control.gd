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

class_name ResourceRemapControl extends VBoxContainer

var save_timer: Timer

var res_remap_option_add_button: Button = null
var res_remap_file_open_dialog: EditorFileDialog = null
var res_remap_option_file_open_dialog: EditorFileDialog = null
## List of resources
var res_remap: Tree = null
## List of remaps for selected resource
var res_remap_options: ResoureRemapTree = null

var updating_res_remaps: bool = false
var recently_added_res_path: String = String()

var undo_redo: EditorUndoRedoManager

const project_settings_property = &"resource_remaps"
const update_method_str = &"update_res_remaps"
const undo_redo_method_str = &"undo_redo_callback"

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
	var remaps: Dictionary
	var prev_remaps: Dictionary

	if ProjectSettings.has_setting(project_settings_property):
		var setting: Variant = ProjectSettings.get_setting(project_settings_property)
		if setting is Dictionary:
			@warning_ignore("unsafe_cast")
			remaps = (setting as Dictionary).duplicate(true)
			@warning_ignore("unsafe_cast")
			prev_remaps = (setting as Dictionary).duplicate(true)

	var added_new_path: bool = false
	for path in p_paths:
		if !remaps.has(path):
			# Don't overwrite with an empty remap array if an array already exists for the given path.
			var new_array: Array[PackedStringArray]
			remaps[path] = new_array
			added_new_path = true
			recently_added_res_path = path

	if added_new_path:
		undo_redo.create_action(TTR("Resource Remaps: Add %d path(s)") % p_paths.size())
		undo_redo.add_do_property(ProjectSettings, project_settings_property, remaps)
		undo_redo.add_undo_property(ProjectSettings, project_settings_property, prev_remaps)
		undo_redo.add_do_method(self, undo_redo_method_str)
		undo_redo.add_undo_method(self, undo_redo_method_str)
		undo_redo.commit_action()

func _res_remap_option_file_open() -> void:
	res_remap_option_file_open_dialog.popup_file_dialog()

func _res_remap_option_add(p_paths: PackedStringArray) -> void:
	if !ProjectSettings.has_setting(project_settings_property):
		return

	var remaps: Dictionary
	var prev_remaps: Dictionary

	var setting: Variant = ProjectSettings.get_setting(project_settings_property)
	if setting is Dictionary:
		@warning_ignore("unsafe_cast")
		remaps = (setting as Dictionary).duplicate(true)
		@warning_ignore("unsafe_cast")
		prev_remaps = (setting as Dictionary).duplicate(true)

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

	undo_redo.create_action(TTR("Resource Remaps: Add %d remap(s)") % p_paths.size())
	undo_redo.add_do_property(ProjectSettings, project_settings_property, remaps)
	undo_redo.add_undo_property(ProjectSettings, project_settings_property, prev_remaps)
	undo_redo.add_do_method(self, undo_redo_method_str)
	undo_redo.add_undo_method(self, undo_redo_method_str)
	undo_redo.commit_action()

func _res_remap_select() -> void:
	if updating_res_remaps:
		return
	call_deferred(update_method_str)

func _res_remap_option_changed() -> void:
	if updating_res_remaps:
		return

	if !ProjectSettings.has_setting(project_settings_property):
		return

	var remaps: Dictionary
	var prev_remaps: Dictionary

	var setting: Variant = ProjectSettings.get_setting(project_settings_property)
	if setting is Dictionary:
		@warning_ignore("unsafe_cast")
		remaps = (setting as Dictionary).duplicate(true)
		@warning_ignore("unsafe_cast")
		prev_remaps = (setting as Dictionary).duplicate(true)

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

	undo_redo.create_action(TTR("Resource Remaps: Change remap feature to %s") % new_feature)
	undo_redo.add_do_property(ProjectSettings, project_settings_property, remaps)
	undo_redo.add_undo_property(ProjectSettings, project_settings_property, prev_remaps)
	undo_redo.add_do_method(self, undo_redo_method_str)
	undo_redo.add_undo_method(self, undo_redo_method_str)
	undo_redo.commit_action()

func _res_remap_delete(p_item: Object, _p_column: int, _p_button: int, p_mouse_button: int) -> void:
	if updating_res_remaps:
		return

	if p_mouse_button != MOUSE_BUTTON_LEFT:
		return

	if !ProjectSettings.has_setting(project_settings_property):
		return

	var remaps: Dictionary
	var prev_remaps: Dictionary

	var setting: Variant = ProjectSettings.get_setting(project_settings_property)
	if setting is Dictionary:
		@warning_ignore("unsafe_cast")
		remaps = (setting as Dictionary).duplicate(true)
		@warning_ignore("unsafe_cast")
		prev_remaps = (setting as Dictionary).duplicate(true)

	var k: TreeItem = p_item as TreeItem
	if k == null:
		return

	var key: String = k.get_metadata(0) # key is the path in res_remap
	if !remaps.has(key):
		return

	remaps.erase(key)

	undo_redo.create_action(TTR("Resource Remaps: Remove path %s") % key)
	undo_redo.add_do_property(ProjectSettings, project_settings_property, remaps)
	undo_redo.add_undo_property(ProjectSettings, project_settings_property, prev_remaps)
	undo_redo.add_do_method(self, undo_redo_method_str)
	undo_redo.add_undo_method(self, undo_redo_method_str)
	undo_redo.commit_action()

func _res_remap_option_delete(p_item: Object, _p_column: int, _p_button: int, p_mouse_button: MouseButton) -> void:
	if updating_res_remaps:
		return

	if p_mouse_button != MOUSE_BUTTON_LEFT:
		return

	if !ProjectSettings.has_setting(project_settings_property):
		return

	var remaps: Dictionary
	var prev_remaps: Dictionary

	var setting: Variant = ProjectSettings.get_setting(project_settings_property)
	if setting is Dictionary:
		@warning_ignore("unsafe_cast")
		remaps = (setting as Dictionary).duplicate(true)
		@warning_ignore("unsafe_cast")
		prev_remaps = (setting as Dictionary).duplicate(true)

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

	undo_redo.create_action(TTR("Resource Remaps: Remove remap for path %s") % str(k.get_metadata(0)))
	undo_redo.add_do_property(ProjectSettings, project_settings_property, remaps)
	undo_redo.add_undo_property(ProjectSettings, project_settings_property, prev_remaps)
	undo_redo.add_do_method(self, undo_redo_method_str)
	undo_redo.add_undo_method(self, undo_redo_method_str)
	undo_redo.commit_action()

func _res_remap_option_reorderd(_item: TreeItem, _relative_to: TreeItem, _before: bool) -> void:
	if !ProjectSettings.has_setting(project_settings_property):
		return

	var remaps: Dictionary
	var prev_remaps: Dictionary

	var setting: Variant = ProjectSettings.get_setting(project_settings_property)
	if setting is Dictionary:
		@warning_ignore("unsafe_cast")
		remaps = (setting as Dictionary).duplicate(true)
		@warning_ignore("unsafe_cast")
		prev_remaps = (setting as Dictionary).duplicate(true)

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

	undo_redo.create_action(TTR("Resource Remaps: Reordered remaps for %s") % key)
	undo_redo.add_do_property(ProjectSettings, project_settings_property, remaps)
	undo_redo.add_undo_property(ProjectSettings, project_settings_property, prev_remaps)
	undo_redo.add_do_method(self, undo_redo_method_str)
	undo_redo.add_undo_method(self, undo_redo_method_str)
	undo_redo.commit_action()

func _filesystem_files_moved(p_old_file: String, p_new_file: String) -> void:
	var remaps: Dictionary = {}
	var remaps_changed: bool = false

	if ProjectSettings.has_setting(project_settings_property):
		remaps = ProjectSettings.get_setting(project_settings_property)

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
		# No undo-redo for this because moving files also doesn't have undo-redo.
		ProjectSettings.set_setting(project_settings_property, remaps)
		queue_save()
		update_res_remaps()

func undo_redo_callback() -> void:
	queue_save()
	update_res_remaps()

func queue_save() -> void:
	save_timer.start()

func update_res_remaps() -> void:
	if updating_res_remaps:
		return

	updating_res_remaps = true

	var features: PackedStringArray
	# Order doesn't matter on the technical side, but I think users would like
	# this ordering:
	add_custom_features(features)
	add_platform_features(features)
	add_export_features(features)
	# Not including preset features because it's unlikely that anyone would ever want
	# to remap resources based on these features:
	#add_preset_features(features)

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

	if ProjectSettings.has_setting(project_settings_property):
		var remaps: Dictionary = ProjectSettings.get_setting(project_settings_property)
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
				t.set_text(0, t.get_text(0) + " " + TTR("(Removed)"))
				t.set_tooltip_text(0, TTR("%s cannot be found.") % key)

			if key == remap_selected:
				t.select(0)
				selected_ti = t
				res_remap_option_add_button.disabled = false
				res_remap_option_file_open_dialog.clear_filters()
				res_remap_option_file_open_dialog.add_filter("*." + key.get_extension())

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
						t2.set_text(path_col, t2.get_text(path_col) + " " + TTR("(Removed)"))
						t2.set_tooltip_text(path_col, TTR("%s cannot be found.") % t2.get_tooltip_text(path_col))

	if should_scroll and selected_ti != null:
		res_remap.scroll_to_item(selected_ti)

	updating_res_remaps = false

func add_string_if_new(value: String, psa: PackedStringArray) -> void:
	if !psa.has(value):
		psa.append(value)

func add_platform_features(features: PackedStringArray) -> void:
	# This list is based off the default configuration of the Godot editor as of 4.4
	# There are other platform features that may exist for custom editor builds.
	add_string_if_new("mobile", features);
	add_string_if_new("android", features);
	add_string_if_new("ios", features);
	add_string_if_new("pc", features);
	add_string_if_new("linux", features);
	add_string_if_new("macos", features);
	add_string_if_new("web", features);
	add_string_if_new("windows", features);

#region Dynamic loading of platform features that requires https://github.com/godotengine/godot/pull/98251 or similar
	#var editor_export: EditorExport = EditorInterface.get_editor_export()
	#for i: int in range(editor_export.get_export_platform_count()):
		#var platform_features: Array[String] = editor_export.get_export_platform(i).get_platform_features()
		#for feature: String in platform_features:
			#add_string_if_new(feature, features)
#endregion

func add_export_features(features: PackedStringArray) -> void:
	# Add all of the features that EditorExportPlatform::get_features might add during the export process:
	add_string_if_new("template", features);
	add_string_if_new("debug", features);
	add_string_if_new("template_debug", features);
	add_string_if_new("release", features);
	add_string_if_new("template_release", features);
	add_string_if_new("double", features);
	add_string_if_new("single", features);

func add_preset_features(features: PackedStringArray) -> void:
	# This list is based off the default configuration of the Godot editor as of 4.3
	# There are other preset features that may exist for custom editor builds.
	add_string_if_new("etc2", features);
	add_string_if_new("astc", features);
	add_string_if_new("arm64", features);
	add_string_if_new("bptc", features);
	add_string_if_new("x86_64", features);
	add_string_if_new("universal", features);
	add_string_if_new("nothreads", features);
	add_string_if_new("wasm32", features);

#region Dynamic loading of preset features that requires https://github.com/godotengine/godot/pull/98251 or similar
	#var editor_export: EditorExport = EditorInterface.get_editor_export()
	#for i: int in range(editor_export.get_export_preset_count()):
		#var preset: EditorExportPreset = editor_export.get_export_preset(i)
		#var preset_features: Array[String] = preset.get_platform().get_preset_features(preset)
		#for feature: String in preset_features:
			#add_string_if_new(feature, features)
#endregion

func add_custom_features(features: PackedStringArray) -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load("res://export_presets.cfg")
	if err != OK:
		return

	for section: String in config.get_sections():
		var custom_features: String = config.get_value(section, "custom_features", "")
		for feature: String in custom_features.split(",", false):
			feature = feature.strip_edges()
			if !feature.is_empty():
				add_string_if_new(feature, features)

#region Minor optimization that requires https://github.com/godotengine/godot/pull/98251 or similar
	#var editor_export: EditorExport = EditorInterface.get_editor_export()
	#for i: int in range(editor_export.get_export_preset_count()):
		#var preset: EditorExportPreset = editor_export.get_export_preset(i)
		#var custom_features: String = preset.get_custom_features()
		#for feature: String in custom_features.split(",", false):
			#feature = feature.strip_edges()
			#if !feature.is_empty():
				#add_string_if_new(feature, features)
#endregion

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

	save_timer = Timer.new()
	save_timer.wait_time = 1.5 # Matching ProjectSettingsEditor behaviour
	save_timer.timeout.connect(ProjectSettings.save)
	save_timer.one_shot = true
	add_child(save_timer)

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
	l.tooltip_text = TTR("From top to bottom, the first remap in this list to match a feature in the export will be used.\nAny resources in this list that are not used will be excluded from the export.")
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
	var rfn: PackedStringArray = ResourceLoader.get_recognized_extensions_for_type("Resource")
	for E: String in rfn:
		res_remap_file_open_dialog.add_filter("*." + E)

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
