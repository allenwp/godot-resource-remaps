class_name ResoureRemapTree extends Tree

signal tree_items_reordered(item: TreeItem, relative_to: TreeItem, before: bool)

func _get_drag_data(at_position: Vector2) -> Variant:
	# TODO: set_drag_preview
	return get_selected()

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if get_drop_section_at_position(at_position) == -100:
		return false

	# Take some guesses regarding whether this is the sort of tree item we care about
	var result: bool = data is TreeItem && typeof((data as TreeItem).get_metadata(0)) == TYPE_INT  && typeof((data as TreeItem).get_metadata(1)) == TYPE_STRING
	if result:
		drop_mode_flags = DROP_MODE_INBETWEEN
	return result

func _drop_data(at_position: Vector2, data: Variant) -> void:
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
