@tool
extends EditorExportPlugin

var _res_features: PackedStringArray
var _scn_features: PackedStringArray

func _get_name() -> String:
	return "Resource Remaps Export Plugin"

func _get_customization_configuration_hash() -> int:
	return randi() # TODO: This is definitely the wrong way to do this...

func _begin_customize_resources (platform: EditorExportPlatform, features: PackedStringArray) -> bool:
	_res_features = features
	return true

func _end_customize_resources() -> void:
	_res_features.clear()

func _customize_resource(resource: Resource, path: String) -> Resource:
	if (_res_features.has("mobile")):
		if (path == "res://icon-default.svg"):
			return load("res://icon-mobile.svg")

	return null

func _begin_customize_scenes(platform: EditorExportPlatform, features: PackedStringArray) -> bool:
	_scn_features = features
	return true

func _end_customize_scenes() -> void:
	_scn_features.clear()

func _customize_scene(scene:Node, path: String) -> Node:
	if (_scn_features.has("mobile")):
		if (path == "res://default.tscn"):
			# Use GEN_EDIT_STATE_INSTANCE because that's what
			# EditorExportPlatform::_export_customize uses to load a packed scene into a Node.
			return (load("res://mobile.tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	return null
