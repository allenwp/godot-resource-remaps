class_name ResourceRemapControl extends VBoxContainer

var translation_list: Tree = null

var translation_res_option_add_button: Button = null
var translation_res_file_open_dialog: EditorFileDialog = null
var translation_res_option_file_open_dialog: EditorFileDialog = null
var translation_remap: Tree = null
var translation_remap_options: Tree = null

var updating_translations: bool = false
var localization_changed: String

func TTR(text: String) -> String:
	# TODO: translate text.
	return text

func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_ENTER_TREE:
			var rfn: PackedStringArray = ResourceLoader.get_recognized_extensions_for_type("Resource")
			for E: String in rfn:
				translation_res_file_open_dialog.add_filter("*." + E)
				translation_res_option_file_open_dialog.add_filter("*." + E)

func _translation_res_file_open() -> void:
	translation_res_file_open_dialog.popup_file_dialog()

func _translation_res_add(p_paths: PackedStringArray) -> void:
	var prev: Variant
	var remaps: Dictionary

	if ProjectSettings.has_setting("internationalization/locale/translation_remaps"):
		remaps = ProjectSettings.get_setting("internationalization/locale/translation_remaps")
		prev = remaps

	for path in p_paths:
		if !remaps.has(path):
			# Don't overwrite with an empty remap array if an array already exists for the given path.
			remaps[path] = PackedStringArray()

	var undo_redo: UndoRedo = UndoRedo.new()
	undo_redo.create_action(TTR("Translation Resource Remap: Add %d Path(s)") % p_paths.size())
	undo_redo.add_do_property(ProjectSettings, "internationalization/locale/translation_remaps", remaps)
	undo_redo.add_undo_property(ProjectSettings, "internationalization/locale/translation_remaps", prev)
	# TODO:
	#undo_redo.add_do_method(self, "update_translations")
	#undo_redo.add_undo_method(self, "update_translations")
	#undo_redo.add_do_method(self, "emit_signal", localization_changed)
	#undo_redo.add_undo_method(self, "emit_signal", localization_changed)
	undo_redo.commit_action()

func _translation_res_option_file_open() -> void:
	translation_res_option_file_open_dialog.popup_file_dialog()

func _translation_res_option_add(p_paths: PackedStringArray) -> void:
	if !ProjectSettings.has_setting("internationalization/locale/translation_remaps"):
		return

	var remaps: Dictionary = ProjectSettings.get_setting("internationalization/locale/translation_remaps")

	var k: TreeItem = translation_remap.get_selected()
	if k == null:
		return

	var key: String = k.get_metadata(0)

	if !remaps.has(key):
		return

	var r: PackedStringArray = remaps[key]
	for path in p_paths:
		r.append(path + ":en")
	remaps[key] = r

	var undo_redo: UndoRedo = UndoRedo.new()
	undo_redo.create_action(TTR("Translation Resource Remap: Add %d Remap(s)") % p_paths.size())
	undo_redo.add_do_property(ProjectSettings, "internationalization/locale/translation_remaps", remaps)
	undo_redo.add_undo_property(ProjectSettings, "internationalization/locale/translation_remaps", ProjectSettings.get_setting("internationalization/locale/translation_remaps"))
	# TODO:
	#undo_redo.add_do_method(self, "update_translations")
	#undo_redo.add_undo_method(self, "update_translations")
	#undo_redo.add_do_method(self, "emit_signal", localization_changed)
	#undo_redo.add_undo_method(self, "emit_signal", localization_changed)
	undo_redo.commit_action()

func _translation_res_select() -> void:
	if updating_translations:
		return
	call_deferred("update_translations")

func _translation_res_option_popup(_p_arrow_clicked: bool) -> void:
	var ed: TreeItem = translation_remap_options.get_edited()
	if ed == null:
		return

	# TODO: For localizaition, this would pop up a whole new dialog for selecting your locale.
	# For resource remaps, this should just be a pre-populated feature drop-down.

func _translation_res_option_selected(p_locale: String) -> void:
	var ed: TreeItem = translation_remap_options.get_edited()
	if ed == null:
		return

	ed.set_text(1, TranslationServer.get_locale_name(p_locale))
	ed.set_tooltip_text(1, p_locale)

	_translation_res_option_changed()

func _translation_res_option_changed() -> void:
	if updating_translations:
		return

	if !ProjectSettings.has_setting("internationalization/locale/translation_remaps"):
		return

	var remaps: Dictionary = ProjectSettings.get_setting("internationalization/locale/translation_remaps")

	var k: TreeItem = translation_remap.get_selected()
	if k == null:
		return
	var ed: TreeItem = translation_remap_options.get_edited()
	if ed == null:
		return

	var key: String = k.get_metadata(0)
	var idx: int = ed.get_metadata(0)
	var path: String = ed.get_metadata(1)
	var locale: String = ed.get_tooltip_text(1)

	if !remaps.has(key):
		return
	var r: PackedStringArray = remaps[key]
	r[idx] = path + ":" + locale
	remaps[key] = r

	updating_translations = true

	var undo_redo: UndoRedo = UndoRedo.new()
	undo_redo.create_action(TTR("Change Resource Remap Language"))
	undo_redo.add_do_property(ProjectSettings, "internationalization/locale/translation_remaps", remaps)
	undo_redo.add_undo_property(ProjectSettings, "internationalization/locale/translation_remaps", ProjectSettings.get_setting("internationalization/locale/translation_remaps"))
	# TODO:
	#undo_redo.add_do_method(self, "update_translations")
	#undo_redo.add_undo_method(self, "update_translations")
	#undo_redo.add_do_method(self, "emit_signal", localization_changed)
	#undo_redo.add_undo_method(self, "emit_signal", localization_changed)
	undo_redo.commit_action()
	updating_translations = false

func _translation_res_delete(p_item: Object, p_column: int, p_button: int, p_mouse_button: int) -> void:
	if updating_translations:
		return

	#TODO:
	#if p_mouse_button != ButtonList.LEFT:
		#return
#
	#if !ProjectSettings.has_setting("internationalization/locale/translation_remaps"):
		#return
#
	#var remaps: Dictionary = ProjectSettings.get_setting("internationalization/locale/translation_remaps")
	#var k: TreeItem = p_item as TreeItem
	#if k == null:
		#return
#
	#var key: String = k.get_metadata(0)
	#if !remaps.has(key):
		#return
#
	#remaps.erase(key)
#
	#var undo_redo: UndoRedo = UndoRedo.get_singleton()
	#undo_redo.create_action(TTR("Remove Resource Remap"))
	#undo_redo.add_do_property(ProjectSettings, "internationalization/locale/translation_remaps", remaps)
	#undo_redo.add_undo_property(ProjectSettings, "internationalization/locale/translation_remaps", ProjectSettings.get_setting("internationalization/locale/translation_remaps"))
	#undo_redo.add_do_method(self, "update_translations")
	#undo_redo.add_undo_method(self, "update_translations")
	#undo_redo.add_do_method(self, "emit_signal", localization_changed)
	#undo_redo.add_undo_method(self, "emit_signal", localization_changed)
	#undo_redo.commit_action()

func _translation_res_option_delete(p_item: Object, p_column: int, p_button: int, p_mouse_button: MouseButton) -> void:
	if updating_translations:
		return

	#TODO:
	#if p_mouse_button != MouseButton.LEFT:
		#return
#
	#if !ProjectSettings.has_setting("internationalization/locale/translation_remaps"):
		#return
#
	#var remaps: Dictionary = ProjectSettings.get_setting("internationalization/locale/translation_remaps")
#
	#var k: TreeItem = translation_remap.get_selected()
	#if k == null:
		#return
	#var ed: TreeItem = p_item as TreeItem
	#if ed == null:
		#return
#
	#var key: String = k.get_metadata(0)
	#var idx: int = ed.get_metadata(0)
#
	#if !remaps.has(key):
		#return
	#var r: PackedStringArray = remaps[key]
	#if idx >= r.size():
		#return
	#r.remove_at(idx)
	#remaps[key] = r
#
	#var undo_redo: UndoRedo = UndoRedo.get_singleton()
	#undo_redo.create_action(TTR("Remove Resource Remap Option"))
	#undo_redo.add_do_property(ProjectSettings, "internationalization/locale/translation_remaps", remaps)
	#undo_redo.add_undo_property(ProjectSettings, "internationalization/locale/translation_remaps", ProjectSettings.get_setting("internationalization/locale/translation_remaps"))
	#undo_redo.add_do_method(self, "update_translations")
	#undo_redo.add_undo_method(self, "update_translations")
	#undo_redo.add_do_method(self, "emit_signal", localization_changed)
	#undo_redo.add_undo_method(self, "emit_signal", localization_changed)
	#undo_redo.commit_action()
#
#func connect_filesystem_dock_signals(p_fs_dock: FileSystemDock) -> void:
	#p_fs_dock.files_moved.connect(_filesystem_files_moved)
	#p_fs_dock.file_removed.connect(_filesystem_file_removed)

func _filesystem_files_moved(p_old_file: String, p_new_file: String) -> void:
	var remaps: Dictionary = {}
	var remaps_changed: bool = false

	if ProjectSettings.has_setting("internationalization/locale/translation_remaps"):
		remaps = ProjectSettings.get_setting("internationalization/locale/translation_remaps")

	# Check for the keys.
	if remaps.has(p_old_file):
		var remapped_files: PackedStringArray = remaps[p_old_file]
		remaps.erase(p_old_file)
		remaps[p_new_file] = remapped_files
		remaps_changed = true
		print_verbose("Changed remap key \"%s\" to \"%s\" due to a moved file." % [p_old_file, p_new_file])

	# Check for the Array elements of the values.
	var remap_keys: Array = remaps.keys()
	for i in range(remap_keys.size()):
		var remapped_files: PackedStringArray = remaps[remap_keys[i]]
		var remapped_files_updated: bool = false

		for j in range(remapped_files.size()):
			var splitter_pos: int = remapped_files[j].rfind(":")
			var res_path: String = remapped_files[j].substr(0, splitter_pos)

			if res_path == p_old_file:
				var locale_name: String = remapped_files[j].substr(splitter_pos + 1)
				# Replace the element at that index.
				remapped_files.insert(j, p_new_file + ":" + locale_name)
				remapped_files.remove_at(j + 1)
				remaps_changed = true
				remapped_files_updated = true
				print_verbose("Changed remap value \"%s\" to \"%s\" of key \"%s\" due to a moved file." % [res_path + ":" + locale_name, remapped_files[j], remap_keys[i]])

		if remapped_files_updated:
			remaps[remap_keys[i]] = remapped_files

	if remaps_changed:
		ProjectSettings.set_setting("internationalization/locale/translation_remaps", remaps)
		update_translations()
		emit_signal("localization_changed")

func _filesystem_file_removed(p_file: String) -> void:
	# Check if the remaps are affected.
	var remaps: Dictionary

	if ProjectSettings.has_setting("internationalization/locale/translation_remaps"):
		remaps = ProjectSettings.get_setting("internationalization/locale/translation_remaps")

	var remaps_changed: bool = remaps.has(p_file)

	if !remaps_changed:
		var remap_keys: Array = remaps.keys()
		for i in range(remap_keys.size()):
			var remapped_files: PackedStringArray = remaps[remap_keys[i]]
			for j in range(remapped_files.size()):
				var splitter_pos: int = remapped_files[j].rfind(":")
				var res_path: String = remapped_files[j].substr(0, splitter_pos)
				if p_file == res_path:
					remaps_changed = true
					print_verbose("Remap value \"%s\" of key \"%s\" has been removed from the file system." % [remapped_files[j], remap_keys[i]])
					break
			if remaps_changed:
				break
	else:
		print_verbose("Remap key \"%s\" has been removed from the file system." % p_file)

	if remaps_changed:
		update_translations()
		emit_signal("localization_changed")

func update_translations() -> void:
	if updating_translations:
		return

	updating_translations = true

	# Update translation remaps.
	var remap_selected: String
	if translation_remap.get_selected():
		remap_selected = translation_remap.get_selected().get_metadata(0)

	translation_remap.clear()
	translation_remap_options.clear()
	var root: TreeItem = translation_remap.create_item()
	var root2: TreeItem = translation_remap_options.create_item()
	translation_remap.set_hide_root(true)
	translation_remap_options.set_hide_root(true)
	translation_res_option_add_button.disabled = true

	if ProjectSettings.has_setting("internationalization/locale/translation_remaps"):
		var remaps: Dictionary = ProjectSettings.get_setting("internationalization/locale/translation_remaps")
		var keys: Array = remaps.keys()
		keys.sort()

		for key:String in keys:
			var t: TreeItem = translation_remap.create_item(root)
			t.set_editable(0, false)
			t.set_text(0, key.replace("res://", ""))
			t.set_tooltip_text(0, key)
			t.set_metadata(0, key)
			var remove_icon: Texture2D = EditorInterface.get_base_control().get_theme_icon(&"Remove", &"EditorIcons")
			t.add_button(0, remove_icon, 0, false, TTR("Remove"))

			# Display that it has been removed if this is the case.
			#TODO
			#if !FileAccess.exists(key):
				#t.set_text(0, t.get_text(0) + " (" + TTR("Removed") + ")")
				#t.set_tooltip_text(0, key + TTR(" cannot be found."))

			if key == remap_selected:
				t.select(0)
				translation_res_option_add_button.disabled = false

				var selected: PackedStringArray = remaps[key]
				for j in range(selected.size()):
					var s2: String = selected[j]
					var qp: int = s2.rfind(":")
					var path: String = s2.substr(0, qp)
					var locale: String = s2.substr(qp + 1, s2.length())

					var t2: TreeItem = translation_remap_options.create_item(root2)
					t2.set_editable(0, false)
					t2.set_text(0, path.replace("res://", ""))
					t2.set_tooltip_text(0, path)
					t2.set_metadata(0, j)
					t2.add_button(0, remove_icon, 0, false, TTR("Remove"))
					t2.set_cell_mode(1, TreeItem.CELL_MODE_CUSTOM)
					t2.set_text(1, TranslationServer.get_locale_name(locale))
					t2.set_editable(1, true)
					t2.set_metadata(1, path)
					t2.set_tooltip_text(1, locale)
#
					## Display that it has been removed if this is the case.
					# TODO:
					#if !FileAccess.exists(path):
						#t2.set_text(0, t2.get_text(0) + " (" + TTR("Removed") + ")")
						# t2.set_tooltip_text(0, str([t2->get_tooltip_text(0), TTR(" cannot be found.")])

	updating_translations = false

func _init() -> void:
	name = TTR("Resource Remaps")
	localization_changed = "localization_changed"

	var translations: TabContainer = TabContainer.new()
	translations.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(translations)

	var tvb: VBoxContainer = VBoxContainer.new()
	tvb.name = TTR("Remaps")
	translations.add_child(tvb)

	var thb: HBoxContainer = HBoxContainer.new()
	var l: Label = Label.new()
	l.text = TTR("Resources:")
	l.theme_type_variation = "HeaderSmall"
	thb.add_child(l)
	tvb.add_child(thb)

	var addtr: Button = Button.new()
	addtr.text = TTR("Add...")
	addtr.pressed.connect(_translation_res_file_open)
	thb.add_child(addtr)

	var tmc: VBoxContainer = VBoxContainer.new()
	tmc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tvb.add_child(tmc)

	translation_remap = Tree.new()
	translation_remap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	translation_remap.cell_selected.connect(_translation_res_select)
	translation_remap.button_clicked.connect(_translation_res_delete)
	tmc.add_child(translation_remap)

	translation_res_file_open_dialog = EditorFileDialog.new()
	translation_res_file_open_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILES
	translation_res_file_open_dialog.files_selected.connect(_translation_res_add)
	add_child(translation_res_file_open_dialog)

	thb = HBoxContainer.new()
	l = Label.new()
	l.text = TTR("Remaps by Locale:")
	l.theme_type_variation = "HeaderSmall"
	thb.add_child(l)
	thb.add_spacer(false)
	tvb.add_child(thb)

	addtr = Button.new()
	addtr.text = TTR("Add...")
	addtr.pressed.connect(_translation_res_option_file_open)
	translation_res_option_add_button = addtr
	thb.add_child(addtr)

	tmc = VBoxContainer.new()
	tmc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tvb.add_child(tmc)

	translation_remap_options = Tree.new()
	translation_remap_options.size_flags_vertical = Control.SIZE_EXPAND_FILL
	translation_remap_options.columns = 2
	translation_remap_options.set_column_title(0, TTR("Path"))
	translation_remap_options.set_column_title(1, TTR("Locale"))
	translation_remap_options.column_titles_visible = true
	translation_remap_options.set_column_expand(0, true)
	translation_remap_options.set_column_clip_content(0, true)
	translation_remap_options.set_column_expand(1, false)
	translation_remap_options.set_column_clip_content(1, false)
	translation_remap_options.set_column_custom_minimum_width(1, 250)
	translation_remap_options.item_edited.connect(_translation_res_option_changed)
	translation_remap_options.button_clicked.connect(_translation_res_option_delete)
	translation_remap_options.custom_popup_edited.connect(_translation_res_option_popup)
	tmc.add_child(translation_remap_options)

	translation_res_option_file_open_dialog = EditorFileDialog.new()
	translation_res_option_file_open_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILES
	translation_res_option_file_open_dialog.files_selected.connect(_translation_res_option_add)
	add_child(translation_res_option_file_open_dialog)
