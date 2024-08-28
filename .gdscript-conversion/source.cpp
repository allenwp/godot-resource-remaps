/**************************************************************************/
/*  localization_editor.h                                                 */
/**************************************************************************/
/*                         This file is part of:                          */
/*                             GODOT ENGINE                               */
/*                        https://godotengine.org                         */
/**************************************************************************/
/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
/*                                                                        */
/* Permission is hereby granted, free of charge, to any person obtaining  */
/* a copy of this software and associated documentation files (the        */
/* "Software"), to deal in the Software without restriction, including    */
/* without limitation the rights to use, copy, modify, merge, publish,    */
/* distribute, sublicense, and/or sell copies of the Software, and to     */
/* permit persons to whom the Software is furnished to do so, subject to  */
/* the following conditions:                                              */
/*                                                                        */
/* The above copyright notice and this permission notice shall be         */
/* included in all copies or substantial portions of the Software.        */
/*                                                                        */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
/**************************************************************************/

/**************************************************************************/
/*  localization_editor.cpp                                               */
/**************************************************************************/
/*                         This file is part of:                          */
/*                             GODOT ENGINE                               */
/*                        https://godotengine.org                         */
/**************************************************************************/
/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
/*                                                                        */
/* Permission is hereby granted, free of charge, to any person obtaining  */
/* a copy of this software and associated documentation files (the        */
/* "Software"), to deal in the Software without restriction, including    */
/* without limitation the rights to use, copy, modify, merge, publish,    */
/* distribute, sublicense, and/or sell copies of the Software, and to     */
/* permit persons to whom the Software is furnished to do so, subject to  */
/* the following conditions:                                              */
/*                                                                        */
/* The above copyright notice and this permission notice shall be         */
/* included in all copies or substantial portions of the Software.        */
/*                                                                        */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
/**************************************************************************/

class LocalizationEditor : public VBoxContainer {
	Tree *translation_list = nullptr;

	EditorLocaleDialog *locale_select = nullptr;

	Button *translation_res_option_add_button = nullptr;
	EditorFileDialog *translation_res_file_open_dialog = nullptr;
	EditorFileDialog *translation_res_option_file_open_dialog = nullptr;
	Tree *translation_remap = nullptr;
	Tree *translation_remap_options = nullptr;

	bool updating_translations = false;
	String localization_changed;
}

void LocalizationEditor::_notification(int p_what) {
	switch (p_what) {
		case NOTIFICATION_ENTER_TREE: {
			List<String> rfn;
			ResourceLoader::get_recognized_extensions_for_type("Resource", &rfn);
			for (const String &E : rfn) {
				translation_res_file_open_dialog->add_filter("*." + E);
				translation_res_option_file_open_dialog->add_filter("*." + E);
			}
		} break;
	}
}

void LocalizationEditor::_translation_delete(Object *p_item, int p_column, int p_button, MouseButton p_mouse_button) {
	if (p_mouse_button != MouseButton::LEFT) {
		return;
	}

	TreeItem *ti = Object::cast_to<TreeItem>(p_item);
	ERR_FAIL_NULL(ti);

	int idx = ti->get_metadata(0);

	PackedStringArray translations = GLOBAL_GET("internationalization/locale/translations");

	ERR_FAIL_INDEX(idx, translations.size());

	translations.remove_at(idx);

	EditorUndoRedoManager *undo_redo = EditorUndoRedoManager::get_singleton();
	undo_redo->create_action(TTR("Remove Translation"));
	undo_redo->add_do_property(ProjectSettings::get_singleton(), "internationalization/locale/translations", translations);
	undo_redo->add_undo_property(ProjectSettings::get_singleton(), "internationalization/locale/translations", GLOBAL_GET("internationalization/locale/translations"));
	undo_redo->add_do_method(this, "update_translations");
	undo_redo->add_undo_method(this, "update_translations");
	undo_redo->add_do_method(this, "emit_signal", localization_changed);
	undo_redo->add_undo_method(this, "emit_signal", localization_changed);
	undo_redo->commit_action();
}

void LocalizationEditor::_translation_res_file_open() {
	translation_res_file_open_dialog->popup_file_dialog();
}

void LocalizationEditor::_translation_res_add(const PackedStringArray &p_paths) {
	Variant prev;
	Dictionary remaps;

	if (ProjectSettings::get_singleton()->has_setting("internationalization/locale/translation_remaps")) {
		remaps = GLOBAL_GET("internationalization/locale/translation_remaps");
		prev = remaps;
	}

	for (int i = 0; i < p_paths.size(); i++) {
		if (!remaps.has(p_paths[i])) {
			// Don't overwrite with an empty remap array if an array already exists for the given path.
			remaps[p_paths[i]] = PackedStringArray();
		}
	}

	EditorUndoRedoManager *undo_redo = EditorUndoRedoManager::get_singleton();
	undo_redo->create_action(vformat(TTR("Translation Resource Remap: Add %d Path(s)"), p_paths.size()));
	undo_redo->add_do_property(ProjectSettings::get_singleton(), "internationalization/locale/translation_remaps", remaps);
	undo_redo->add_undo_property(ProjectSettings::get_singleton(), "internationalization/locale/translation_remaps", prev);
	undo_redo->add_do_method(this, "update_translations");
	undo_redo->add_undo_method(this, "update_translations");
	undo_redo->add_do_method(this, "emit_signal", localization_changed);
	undo_redo->add_undo_method(this, "emit_signal", localization_changed);
	undo_redo->commit_action();
}

void LocalizationEditor::_translation_res_option_file_open() {
	translation_res_option_file_open_dialog->popup_file_dialog();
}

void LocalizationEditor::_translation_res_option_add(const PackedStringArray &p_paths) {
	ERR_FAIL_COND(!ProjectSettings::get_singleton()->has_setting("internationalization/locale/translation_remaps"));

	Dictionary remaps = GLOBAL_GET("internationalization/locale/translation_remaps");

	TreeItem *k = translation_remap->get_selected();
	ERR_FAIL_NULL(k);

	String key = k->get_metadata(0);

	ERR_FAIL_COND(!remaps.has(key));
	PackedStringArray r = remaps[key];
	for (int i = 0; i < p_paths.size(); i++) {
		r.push_back(p_paths[i] + ":" + "en");
	}
	remaps[key] = r;

	EditorUndoRedoManager *undo_redo = EditorUndoRedoManager::get_singleton();
	undo_redo->create_action(vformat(TTR("Translation Resource Remap: Add %d Remap(s)"), p_paths.size()));
	undo_redo->add_do_property(ProjectSettings::get_singleton(), "internationalization/locale/translation_remaps", remaps);
	undo_redo->add_undo_property(ProjectSettings::get_singleton(), "internationalization/locale/translation_remaps", GLOBAL_GET("internationalization/locale/translation_remaps"));
	undo_redo->add_do_method(this, "update_translations");
	undo_redo->add_undo_method(this, "update_translations");
	undo_redo->add_do_method(this, "emit_signal", localization_changed);
	undo_redo->add_undo_method(this, "emit_signal", localization_changed);
	undo_redo->commit_action();
}

void LocalizationEditor::_translation_res_select() {
	if (updating_translations) {
		return;
	}
	callable_mp(this, &LocalizationEditor::update_translations).call_deferred();
}

void LocalizationEditor::_translation_res_option_popup(bool p_arrow_clicked) {
	TreeItem *ed = translation_remap_options->get_edited();
	ERR_FAIL_NULL(ed);

	locale_select->set_locale(ed->get_tooltip_text(1));
	locale_select->popup_locale_dialog();
}

void LocalizationEditor::_translation_res_option_selected(const String &p_locale) {
	TreeItem *ed = translation_remap_options->get_edited();
	ERR_FAIL_NULL(ed);

	ed->set_text(1, TranslationServer::get_singleton()->get_locale_name(p_locale));
	ed->set_tooltip_text(1, p_locale);

	LocalizationEditor::_translation_res_option_changed();
}

void LocalizationEditor::_translation_res_option_changed() {
	if (updating_translations) {
		return;
	}

	if (!ProjectSettings::get_singleton()->has_setting("internationalization/locale/translation_remaps")) {
		return;
	}

	Dictionary remaps = GLOBAL_GET("internationalization/locale/translation_remaps");

	TreeItem *k = translation_remap->get_selected();
	ERR_FAIL_NULL(k);
	TreeItem *ed = translation_remap_options->get_edited();
	ERR_FAIL_NULL(ed);

	String key = k->get_metadata(0);
	int idx = ed->get_metadata(0);
	String path = ed->get_metadata(1);
	String locale = ed->get_tooltip_text(1);

	ERR_FAIL_COND(!remaps.has(key));
	PackedStringArray r = remaps[key];
	r.set(idx, path + ":" + locale);
	remaps[key] = r;

	updating_translations = true;

	EditorUndoRedoManager *undo_redo = EditorUndoRedoManager::get_singleton();
	undo_redo->create_action(TTR("Change Resource Remap Language"));
	undo_redo->add_do_property(ProjectSettings::get_singleton(), "internationalization/locale/translation_remaps", remaps);
	undo_redo->add_undo_property(ProjectSettings::get_singleton(), "internationalization/locale/translation_remaps", GLOBAL_GET("internationalization/locale/translation_remaps"));
	undo_redo->add_do_method(this, "update_translations");
	undo_redo->add_undo_method(this, "update_translations");
	undo_redo->add_do_method(this, "emit_signal", localization_changed);
	undo_redo->add_undo_method(this, "emit_signal", localization_changed);
	undo_redo->commit_action();
	updating_translations = false;
}

void LocalizationEditor::_translation_res_delete(Object *p_item, int p_column, int p_button, MouseButton p_mouse_button) {
	if (updating_translations) {
		return;
	}

	if (p_mouse_button != MouseButton::LEFT) {
		return;
	}

	if (!ProjectSettings::get_singleton()->has_setting("internationalization/locale/translation_remaps")) {
		return;
	}

	Dictionary remaps = GLOBAL_GET("internationalization/locale/translation_remaps");

	TreeItem *k = Object::cast_to<TreeItem>(p_item);

	String key = k->get_metadata(0);
	ERR_FAIL_COND(!remaps.has(key));

	remaps.erase(key);

	EditorUndoRedoManager *undo_redo = EditorUndoRedoManager::get_singleton();
	undo_redo->create_action(TTR("Remove Resource Remap"));
	undo_redo->add_do_property(ProjectSettings::get_singleton(), "internationalization/locale/translation_remaps", remaps);
	undo_redo->add_undo_property(ProjectSettings::get_singleton(), "internationalization/locale/translation_remaps", GLOBAL_GET("internationalization/locale/translation_remaps"));
	undo_redo->add_do_method(this, "update_translations");
	undo_redo->add_undo_method(this, "update_translations");
	undo_redo->add_do_method(this, "emit_signal", localization_changed);
	undo_redo->add_undo_method(this, "emit_signal", localization_changed);
	undo_redo->commit_action();
}

void LocalizationEditor::_translation_res_option_delete(Object *p_item, int p_column, int p_button, MouseButton p_mouse_button) {
	if (updating_translations) {
		return;
	}

	if (p_mouse_button != MouseButton::LEFT) {
		return;
	}

	if (!ProjectSettings::get_singleton()->has_setting("internationalization/locale/translation_remaps")) {
		return;
	}

	Dictionary remaps = GLOBAL_GET("internationalization/locale/translation_remaps");

	TreeItem *k = translation_remap->get_selected();
	ERR_FAIL_NULL(k);
	TreeItem *ed = Object::cast_to<TreeItem>(p_item);
	ERR_FAIL_NULL(ed);

	String key = k->get_metadata(0);
	int idx = ed->get_metadata(0);

	ERR_FAIL_COND(!remaps.has(key));
	PackedStringArray r = remaps[key];
	ERR_FAIL_INDEX(idx, r.size());
	r.remove_at(idx);
	remaps[key] = r;

	EditorUndoRedoManager *undo_redo = EditorUndoRedoManager::get_singleton();
	undo_redo->create_action(TTR("Remove Resource Remap Option"));
	undo_redo->add_do_property(ProjectSettings::get_singleton(), "internationalization/locale/translation_remaps", remaps);
	undo_redo->add_undo_property(ProjectSettings::get_singleton(), "internationalization/locale/translation_remaps", GLOBAL_GET("internationalization/locale/translation_remaps"));
	undo_redo->add_do_method(this, "update_translations");
	undo_redo->add_undo_method(this, "update_translations");
	undo_redo->add_do_method(this, "emit_signal", localization_changed);
	undo_redo->add_undo_method(this, "emit_signal", localization_changed);
	undo_redo->commit_action();
}

void LocalizationEditor::connect_filesystem_dock_signals(FileSystemDock *p_fs_dock) {
	p_fs_dock->connect("files_moved", callable_mp(this, &LocalizationEditor::_filesystem_files_moved));
	p_fs_dock->connect("file_removed", callable_mp(this, &LocalizationEditor::_filesystem_file_removed));
}

void LocalizationEditor::_filesystem_files_moved(const String &p_old_file, const String &p_new_file) {
	// Update remaps if the moved file is a part of them.
	Dictionary remaps;
	bool remaps_changed = false;

	if (ProjectSettings::get_singleton()->has_setting("internationalization/locale/translation_remaps")) {
		remaps = GLOBAL_GET("internationalization/locale/translation_remaps");
	}

	// Check for the keys.
	if (remaps.has(p_old_file)) {
		PackedStringArray remapped_files = remaps[p_old_file];
		remaps.erase(p_old_file);
		remaps[p_new_file] = remapped_files;
		remaps_changed = true;
		print_verbose(vformat("Changed remap key \"%s\" to \"%s\" due to a moved file.", p_old_file, p_new_file));
	}

	// Check for the Array elements of the values.
	Array remap_keys = remaps.keys();
	for (int i = 0; i < remap_keys.size(); i++) {
		PackedStringArray remapped_files = remaps[remap_keys[i]];
		bool remapped_files_updated = false;

		for (int j = 0; j < remapped_files.size(); j++) {
			int splitter_pos = remapped_files[j].rfind(":");
			String res_path = remapped_files[j].substr(0, splitter_pos);

			if (res_path == p_old_file) {
				String locale_name = remapped_files[j].substr(splitter_pos + 1);
				// Replace the element at that index.
				remapped_files.insert(j, p_new_file + ":" + locale_name);
				remapped_files.remove_at(j + 1);
				remaps_changed = true;
				remapped_files_updated = true;
				print_verbose(vformat("Changed remap value \"%s\" to \"%s\" of key \"%s\" due to a moved file.", res_path + ":" + locale_name, remapped_files[j], remap_keys[i]));
			}
		}

		if (remapped_files_updated) {
			remaps[remap_keys[i]] = remapped_files;
		}
	}

	if (remaps_changed) {
		ProjectSettings::get_singleton()->set_setting("internationalization/locale/translation_remaps", remaps);
		update_translations();
		emit_signal("localization_changed");
	}
}

void LocalizationEditor::_filesystem_file_removed(const String &p_file) {
	// Check if the remaps are affected.
	Dictionary remaps;

	if (ProjectSettings::get_singleton()->has_setting("internationalization/locale/translation_remaps")) {
		remaps = GLOBAL_GET("internationalization/locale/translation_remaps");
	}

	bool remaps_changed = remaps.has(p_file);

	if (!remaps_changed) {
		Array remap_keys = remaps.keys();
		for (int i = 0; i < remap_keys.size() && !remaps_changed; i++) {
			PackedStringArray remapped_files = remaps[remap_keys[i]];
			for (int j = 0; j < remapped_files.size() && !remaps_changed; j++) {
				int splitter_pos = remapped_files[j].rfind(":");
				String res_path = remapped_files[j].substr(0, splitter_pos);
				remaps_changed = p_file == res_path;
				if (remaps_changed) {
					print_verbose(vformat("Remap value \"%s\" of key \"%s\" has been removed from the file system.", remapped_files[j], remap_keys[i]));
				}
			}
		}
	} else {
		print_verbose(vformat("Remap key \"%s\" has been removed from the file system.", p_file));
	}

	if (remaps_changed) {
		update_translations();
		emit_signal("localization_changed");
	}
}

void LocalizationEditor::update_translations() {
	if (updating_translations) {
		return;
	}

	updating_translations = true;

	// Update translation remaps.
	String remap_selected;
	if (translation_remap->get_selected()) {
		remap_selected = translation_remap->get_selected()->get_metadata(0);
	}

	translation_remap->clear();
	translation_remap_options->clear();
	root = translation_remap->create_item(nullptr);
	TreeItem *root2 = translation_remap_options->create_item(nullptr);
	translation_remap->set_hide_root(true);
	translation_remap_options->set_hide_root(true);
	translation_res_option_add_button->set_disabled(true);

	if (ProjectSettings::get_singleton()->has_setting("internationalization/locale/translation_remaps")) {
		Dictionary remaps = GLOBAL_GET("internationalization/locale/translation_remaps");
		List<Variant> rk;
		remaps.get_key_list(&rk);
		Vector<String> keys;
		for (const Variant &E : rk) {
			keys.push_back(E);
		}
		keys.sort();

		for (int i = 0; i < keys.size(); i++) {
			TreeItem *t = translation_remap->create_item(root);
			t->set_editable(0, false);
			t->set_text(0, keys[i].replace_first("res://", ""));
			t->set_tooltip_text(0, keys[i]);
			t->set_metadata(0, keys[i]);
			t->add_button(0, get_editor_theme_icon(SNAME("Remove")), 0, false, TTR("Remove"));

			// Display that it has been removed if this is the case.
			if (!FileAccess::exists(keys[i])) {
				t->set_text(0, t->get_text(0) + vformat(" (%s)", TTR("Removed")));
				t->set_tooltip_text(0, vformat(TTR("%s cannot be found."), t->get_tooltip_text(0)));
			}

			if (keys[i] == remap_selected) {
				t->select(0);
				translation_res_option_add_button->set_disabled(false);

				PackedStringArray selected = remaps[keys[i]];
				for (int j = 0; j < selected.size(); j++) {
					const String &s2 = selected[j];
					int qp = s2.rfind(":");
					String path = s2.substr(0, qp);
					String locale = s2.substr(qp + 1, s2.length());

					TreeItem *t2 = translation_remap_options->create_item(root2);
					t2->set_editable(0, false);
					t2->set_text(0, path.replace_first("res://", ""));
					t2->set_tooltip_text(0, path);
					t2->set_metadata(0, j);
					t2->add_button(0, get_editor_theme_icon(SNAME("Remove")), 0, false, TTR("Remove"));
					t2->set_cell_mode(1, TreeItem::CELL_MODE_CUSTOM);
					t2->set_text(1, TranslationServer::get_singleton()->get_locale_name(locale));
					t2->set_editable(1, true);
					t2->set_metadata(1, path);
					t2->set_tooltip_text(1, locale);

					// Display that it has been removed if this is the case.
					if (!FileAccess::exists(path)) {
						t2->set_text(0, t2->get_text(0) + vformat(" (%s)", TTR("Removed")));
						t2->set_tooltip_text(0, vformat(TTR("%s cannot be found."), t2->get_tooltip_text(0)));
					}
				}
			}
		}
	}

	updating_translations = false;
}

void LocalizationEditor::_bind_methods() {
	ClassDB::bind_method(D_METHOD("update_translations"), &LocalizationEditor::update_translations);

	ADD_SIGNAL(MethodInfo("localization_changed"));
}

LocalizationEditor::LocalizationEditor() {
	localization_changed = "localization_changed";

	TabContainer *translations = memnew(TabContainer);
	translations->set_v_size_flags(Control::SIZE_EXPAND_FILL);
	add_child(translations);

	{
		VBoxContainer *tvb = memnew(VBoxContainer);
		tvb->set_name(TTR("Remaps"));
		translations->add_child(tvb);

		HBoxContainer *thb = memnew(HBoxContainer);
		Label *l = memnew(Label(TTR("Resources:")));
		l->set_theme_type_variation("HeaderSmall");
		thb->add_child(l);
		thb->add_spacer();
		tvb->add_child(thb);

		Button *addtr = memnew(Button(TTR("Add...")));
		addtr->connect(SceneStringName(pressed), callable_mp(this, &LocalizationEditor::_translation_res_file_open));
		thb->add_child(addtr);

		VBoxContainer *tmc = memnew(VBoxContainer);
		tmc->set_v_size_flags(Control::SIZE_EXPAND_FILL);
		tvb->add_child(tmc);

		translation_remap = memnew(Tree);
		translation_remap->set_v_size_flags(Control::SIZE_EXPAND_FILL);
		translation_remap->connect("cell_selected", callable_mp(this, &LocalizationEditor::_translation_res_select));
		translation_remap->connect("button_clicked", callable_mp(this, &LocalizationEditor::_translation_res_delete));
		tmc->add_child(translation_remap);

		translation_res_file_open_dialog = memnew(EditorFileDialog);
		translation_res_file_open_dialog->set_file_mode(EditorFileDialog::FILE_MODE_OPEN_FILES);
		translation_res_file_open_dialog->connect("files_selected", callable_mp(this, &LocalizationEditor::_translation_res_add));
		add_child(translation_res_file_open_dialog);

		thb = memnew(HBoxContainer);
		l = memnew(Label(TTR("Remaps by Locale:")));
		l->set_theme_type_variation("HeaderSmall");
		thb->add_child(l);
		thb->add_spacer();
		tvb->add_child(thb);

		addtr = memnew(Button(TTR("Add...")));
		addtr->connect(SceneStringName(pressed), callable_mp(this, &LocalizationEditor::_translation_res_option_file_open));
		translation_res_option_add_button = addtr;
		thb->add_child(addtr);

		tmc = memnew(VBoxContainer);
		tmc->set_v_size_flags(Control::SIZE_EXPAND_FILL);
		tvb->add_child(tmc);

		translation_remap_options = memnew(Tree);
		translation_remap_options->set_v_size_flags(Control::SIZE_EXPAND_FILL);
		translation_remap_options->set_columns(2);
		translation_remap_options->set_column_title(0, TTR("Path"));
		translation_remap_options->set_column_title(1, TTR("Locale"));
		translation_remap_options->set_column_titles_visible(true);
		translation_remap_options->set_column_expand(0, true);
		translation_remap_options->set_column_clip_content(0, true);
		translation_remap_options->set_column_expand(1, false);
		translation_remap_options->set_column_clip_content(1, false);
		translation_remap_options->set_column_custom_minimum_width(1, 250);
		translation_remap_options->connect("item_edited", callable_mp(this, &LocalizationEditor::_translation_res_option_changed));
		translation_remap_options->connect("button_clicked", callable_mp(this, &LocalizationEditor::_translation_res_option_delete));
		translation_remap_options->connect("custom_popup_edited", callable_mp(this, &LocalizationEditor::_translation_res_option_popup));
		tmc->add_child(translation_remap_options);

		translation_res_option_file_open_dialog = memnew(EditorFileDialog);
		translation_res_option_file_open_dialog->set_file_mode(EditorFileDialog::FILE_MODE_OPEN_FILES);
		translation_res_option_file_open_dialog->connect("files_selected", callable_mp(this, &LocalizationEditor::_translation_res_option_add));
		add_child(translation_res_option_file_open_dialog);
	}
}