@tool
class_name ResourceRemapPlugin extends EditorExportPlugin

var _features: PackedStringArray

var remap_resource: Dictionary
var remap_scene: Dictionary
var remap_file: Dictionary

func _init() -> void:
	# Temporary while I figure out the GUI for this:
	remap_resource = {
		"res://icon-default.svg": [
			["ios", "res://icon-ios.svg"],
			["mobile", "res://icon-mobile.svg"],
		],
		"res://noise-pc.png": [
			["mobile", "res://noise-mobile.png"],
		],
		"res://audio-default.wav": [
			["mobile", "res://audio-mobile.wav"],
		]
	}
	remap_scene = {
		"res://default.tscn": [
			["ios", "res://ios.tscn"],
			["mobile", "res://mobile.tscn"],
		]
	}
	remap_file = {
		"res://default.ogv": [
			["mobile", "res://mobile.ogv"],
		]
	}

func _get_name() -> String:
	# Name must start with a capital letter earlier than G to work around Godot issue #90364 / 93487
	# This ensures that GDScript files will be passed to _export_file before they are changed to
	# .gdc files.
	return "A Resource Remaps Export Plugin"

func _get_customization_configuration_hash() -> int:
	return randi() # TODO: This is definitely the wrong way to do this...

func _export_begin(features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	print("[Resource Remap] Remapping resources...")

	_features = features

func _begin_customize_resources (_platform: EditorExportPlatform, _f: PackedStringArray) -> bool:
	return true

func _customize_resource(_resource: Resource, path: String) -> Resource:
	if remap_resource.has(path):
		var feature_arrays: Array = remap_resource[path]
		for feature_array: Array in feature_arrays:
			var feature: String = feature_array[0]
			if _features.has(feature):
				var new_path: String = feature_array[1]
				print("[Resource Remap] Resource: ", path, " to: ", new_path)
				return load(new_path)
	return null

func _begin_customize_scenes(_platform: EditorExportPlatform, _f: PackedStringArray) -> bool:
	return true

func _customize_scene(scene: Node, path: String) -> Node:
	if remap_scene.has(path):
		var feature_arrays: Array = remap_scene[path]
		for feature_array: Array in feature_arrays:
			var feature: String = feature_array[0]
			if _features.has(feature):
				var new_path: String = feature_array[1]
				var packed_scene: PackedScene = load(new_path as String) as PackedScene
				if packed_scene != null && packed_scene.can_instantiate():
					print("[Resource Remap] Scene: ", path, " to: ", new_path)
					# Use GEN_EDIT_STATE_INSTANCE because that's what
					# EditorExportPlatform::_export_customize uses to load a packed scene into a Node.
					var result: Node = packed_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE);
					scene.free()
					return result
				else:
					printerr("[Resource Remap] Failed Scene: ", path, " to: ", new_path)
	return null

func _export_file(path: String, _type: String, features: PackedStringArray) -> void:
	if remap_file.has(path):
		var feature_arrays: Array = remap_file[path]
		for feature_array: Array in feature_arrays:
			var feature: String = feature_array[0]
			if features.has(feature):
				var new_path: String = feature_array[1]
				print("[Resource Remap] File: ", path, " to: ", new_path)
				add_file(path, FileAccess.get_file_as_bytes(new_path as String), true)
				break

	if (remap_resource.has(path)
		|| remap_scene.has(path)
		|| remap_file.has(path)):
		# Do not skip this path, even if it is listed as a new path to remap to.
		# An example of this would be "vr" feature using the default resource as
		# a top-priority override and also having a different resource as the
		# "mobile" feature lower-priority override.
		return

	# Workaround to Godot issue #94045: Don't skip textures that have been remapped to another
	if _type == "CompressedTexture2D":
		for feature_arrays: Array in remap_resource.values():
			for feature_array: Array in feature_arrays:
				var feature: String = feature_array[0]
				if _features.has(feature):
					var new_path: String = feature_array[1]
					if new_path == path:
						print("[Resource Remap] NOT skipping CompressedTexture2D (.ctex file) because it's referenced by another resource. ", path)
						return
					else:
						# We've found the first valid feature mapping for this remap and it's not
						# this path. Keep looking...
						break

	# Skip all files that are overrides:
	for feature_arrays: Array in remap_resource.values():
		for feature_array: Array in feature_arrays:
			var remapped_path: String = feature_array[1]
			if remapped_path == path:
				print("[Resource Remap] Skipping resource because it has been remapped: ", path)
				skip()
				return

	for feature_arrays: Array in remap_scene.values():
		for feature_array: Array in feature_arrays:
			var remapped_path: String = feature_array[1]
			if remapped_path == path:
				print("[Resource Remap] Skipping scene because it has been remapped: ", path)
				skip()
				return

	for feature_arrays: Array in remap_file.values():
		for feature_array: Array in feature_arrays:
			var remapped_path: String = feature_array[1]
			if remapped_path == path:
				print("[Resource Remap] Skipping file because it has been remapped: ", path)
				skip()
				return
