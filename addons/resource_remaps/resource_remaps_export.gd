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

@tool
class_name ResourceRemapPlugin
extends EditorExportPlugin

var _resource_extensions: PackedStringArray = ResourceLoader.get_recognized_extensions_for_type("Resource")
var _features: PackedStringArray
var _remaps: Dictionary


func _get_name() -> String:
	# Name must start with a capital letter earlier than G to work around Godot issue #90364 / 93487
	# This ensures that GDScript files will be passed to _export_file before they are changed to
	# .gdc files.
	#
	# This can be changed to a later letter in the alphabet to allow for customization of resources
	# in a different EditorExportPlugin before they are remapped by this plugin(??)
	return "A Resource Remaps Export Plugin"


func _get_customization_configuration_hash() -> int:
	# I don't have a way to produce a hash, so a random result should ensure this plugin always runs
	return randi()

#region Failed attempt at generating a correct hash
	# This is an attempt at generating a hash, but I expect it won't work because it loads the file
	# data instead of resource data. File data may remain unchanged, but resource data might change.
	# For example, the import settings of a resource may change, which would need a new hash, even
	# though the file data hasn't changed.

	#var hash_context: HashingContext = HashingContext.new()
	## MD5 is 128 bit, so this is probably most suiting given I can only return 64 bits
	#hash_context.start(HashingContext.HASH_MD5)
#
	#for path: String in _remaps.keys():
		#add_file_to_hash(path, hash_context)
		#var this_remap: PackedStringArray = _remaps[path]
		#add_file_to_hash(this_remap[1], hash_context)
#
	#var result: PackedByteArray = hash_context.finish()
	#return result.decode_u64(0)
#
#func add_file_to_hash(path: String, hash_context: HashingContext) -> void:
	#if FileAccess.file_exists(path):
		#var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		#while file.get_position() < file.get_length():
			#var remaining: int = file.get_length() - file.get_position()
			#hash_context.update(file.get_buffer(mini(remaining, 1024)))
#endregion


func _export_begin(features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	print("[Resource Remap] Remapping resources...")
	_features = features
	var remap_settings: Variant = ProjectSettings.get_setting("resource_remaps")
	if typeof(remap_settings) == TYPE_DICTIONARY:
		@warning_ignore("unsafe_cast")
		_remaps = (remap_settings as Dictionary).duplicate(true)


func _export_end() -> void:
	_remaps.clear()


func _export_file(path: String, _type: String, features: PackedStringArray) -> void:
	if _remaps.has(path):
		var is_resource_type: bool = false
		var this_extension:String = path.get_extension()
		for res_extension: String in _resource_extensions:
			if this_extension.nocasecmp_to(res_extension) == 0:
				print_verbose("[Resource Remap Debug] Extension " + this_extension + " matches known resource extension " + res_extension + " for path " + path)
				is_resource_type = true # In this case, the resource will be remapped in either _customize_resource or _customize_scene
				break
		if !is_resource_type:
			var feature_arrays: Array[PackedStringArray] = _remaps[path]
			for feature_array: PackedStringArray in feature_arrays:
				var feature: String = feature_array[0]
				if features.has(feature):
					var new_path: String = feature_array[1]
					print("[Resource Remap] File: ", path, " to: ", new_path)
					add_file(path, FileAccess.get_file_as_bytes(new_path as String), true)
					break

	if (_remaps.has(path)):
		# Do not skip this path, even if it is listed as a new path to remap to.
		# An example of this would be "vr" feature using the default resource as
		# a top-priority override and also having a different resource as the
		# "mobile" feature lower-priority override.
		return

	# Workaround to Godot issue #94045: Don't skip textures that have been remapped to another
	if _type == "AtlasTexture" \
		|| _type == "CompressedCubemap" \
		|| _type == "CompressedCubemapArray" \
		|| _type == "CompressedTexture2D" \
		|| _type == "CompressedTexture2DArray" \
		|| _type == "CompressedTexture3D":
		for feature_arrays: Array[PackedStringArray] in _remaps.values():
			for feature_array: PackedStringArray in feature_arrays:
				var feature: String = feature_array[0]
				if _features.has(feature):
					var new_path: String = feature_array[1]
					if new_path == path:
						print_verbose("[Resource Remap Debug] NOT skipping %s because its imported file is referenced by another resource: %s" % [_type, path])
						return
					else:
						# We've found the first valid feature mapping for this remap and it's not
						# this path. Keep looking...
						break

	# Skip all files that are overrides:
	for feature_arrays: Array[PackedStringArray] in _remaps.values():
		for feature_array: PackedStringArray in feature_arrays:
			var remapped_path: String = feature_array[1]
			if remapped_path == path:
				print_verbose("[Resource Remap Debug] Skipping file because it has been remapped: ", path)
				skip()
				return


func _begin_customize_resources (_platform: EditorExportPlatform, _f: PackedStringArray) -> bool:
	return true


func _customize_resource(_resource: Resource, path: String) -> Resource:
	if _remaps.has(path):
		var feature_arrays: Array[PackedStringArray] = _remaps[path]
		for feature_array: PackedStringArray in feature_arrays:
			var feature: String = feature_array[0]
			if _features.has(feature):
				var new_path: String = feature_array[1]
				print("[Resource Remap] Resource: ", path, " to: ", new_path)
				return load(new_path)
	return null


func _begin_customize_scenes(_platform: EditorExportPlatform, _f: PackedStringArray) -> bool:
	return true


func _customize_scene(scene: Node, path: String) -> Node:
	if _remaps.has(path):
		var feature_arrays:  Array[PackedStringArray] = _remaps[path]
		for feature_array: PackedStringArray in feature_arrays:
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
