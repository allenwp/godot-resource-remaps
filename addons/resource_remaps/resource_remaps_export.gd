@tool
extends EditorExportPlugin

var _features: PackedStringArray

var remap_resource: Dictionary
var remap_scene: Dictionary
var remap_file: Dictionary

# Commented out to work around godot issue #90364
#func _get_name() -> String:
	#return "Resource Remaps Export Plugin"

func _get_customization_configuration_hash() -> int:
	return randi() # TODO: This is definitely the wrong way to do this...

func _export_begin(features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	print("[Resource Remap] Remapping resources...")

	_features = features

	# Temporary while I figure out the GUI for this:
	remap_resource = {
		"res://icon-default.svg": { "mobile": "res://icon-mobile.svg" },
		"res://noise-pc.png": { "mobile": "res://noise-mobile.png" },
		"res://audio-default.wav": { "mobile": "res://audio-mobile.wav" }
	}
	remap_scene = {
		"res://default.tscn": { "mobile": "res://mobile.tscn" }
	}
	remap_file = {
		"res://default.ogv": { "mobile": "res://mobile.ogv" }
	}

func _begin_customize_resources (_platform: EditorExportPlatform, _f: PackedStringArray) -> bool:
	return true

func _customize_resource(_resource: Resource, path: String) -> Resource:
	if remap_resource.has(path):
		var feature_to_new_path: Dictionary = remap_resource[path]
		for feature: String in feature_to_new_path.keys():
			if _features.has(feature):
				var new_path: String = feature_to_new_path[feature]
				print("[Resource Remap] Resource: ", path, " to: ", new_path)
				return load(new_path)
	return null

func _begin_customize_scenes(_platform: EditorExportPlatform, _f: PackedStringArray) -> bool:
	return true

func _customize_scene(scene: Node, path: String) -> Node:
	if remap_scene.has(path):
		var feature_to_new_path: Dictionary = remap_scene[path]
		for feature: String in feature_to_new_path.keys():
			if _features.has(feature):
				var new_path: String = feature_to_new_path[feature]
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
		var feature_to_new_path: Dictionary = remap_file[path]
		for feature: String in feature_to_new_path.keys():
			if features.has(feature):
				var new_path: String = feature_to_new_path[feature]
				print("[Resource Remap] File: ", path, " to: ", new_path)
				add_file(path, FileAccess.get_file_as_bytes(new_path as String), true)
				break

	# Skip all files that are overrides:
	for feature_to_new_path: Dictionary in remap_resource.values():
		for remapped_path: String in feature_to_new_path.values():
			if remapped_path == path:
				print("[Resource Remap] Skipping resource because it has been remapped: ", path)
				skip()
				return

	for feature_to_new_path: Dictionary in remap_scene.values():
		for remapped_path: String in feature_to_new_path.values():
			if remapped_path == path:
				print("[Resource Remap] Skipping scene because it has been remapped: ", path)
				skip()
				return

	for feature_to_new_path: Dictionary in remap_file.values():
		for remapped_path: String in feature_to_new_path.values():
			if remapped_path == path:
				print("[Resource Remap] Skipping file because it has been remapped: ", path)
				skip()
				return

	## This is just some test code to see what happens when the "base"
	## file path is skipped instead of the remapped file path for
	## CompressedTexture2D. The result is: it crashes.
	#if type == "CompressedTexture2D" && remap_resource.has(path):
		#var feature_to_new_path: Dictionary = remap_resource[path]
		#for feature: String in feature_to_new_path.keys():
			#if features.has(feature):
				#print("[Resource Remap] Skipping resource because it has been remapped: ", path)
				#skip() # skip the root in this case, instead of the new_path
				#return
