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
extends EditorPlugin

const CONTROL_CONTAINER: CustomControlContainer = CONTAINER_PROJECT_SETTING_TAB_RIGHT
var _control: ResourceRemapControl
var _export_plugin: ResourceRemapPlugin


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	_control = ResourceRemapControl.new()
	_control.undo_redo = get_undo_redo()
	add_control_to_container(CONTROL_CONTAINER, _control)

	_export_plugin = ResourceRemapPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	if (_control):
		remove_control_from_container(CONTROL_CONTAINER, _control)
		_control.free()
		_control = null

	if (_export_plugin):
		remove_export_plugin(_export_plugin)
		_export_plugin = null
