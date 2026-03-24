extends Camera2D

@export var map_layers_root_path: NodePath = NodePath("../..")
@export var max_distance: float = 48.0
@export var right_limit_padding: int = 0

var target_distance: float = 0.0
var center_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	center_pos = position
	_apply_map_limits()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var direction = center_pos.direction_to(get_local_mouse_position())
	var target_pos = center_pos + direction * target_distance
	
	target_pos = target_pos.clamp(
		center_pos - Vector2(max_distance, max_distance),
		center_pos + Vector2(max_distance, max_distance)
	)
	
	position = target_pos
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		target_distance = center_pos.distance_to(get_local_mouse_position()) / 2.0

func _apply_map_limits() -> void:
	var layers_root := get_node_or_null(map_layers_root_path)
	if layers_root == null:
		push_warning("No se encontro nodo raiz de capas para limites de camara en: %s" % map_layers_root_path)
		return

	var map_layers: Array[TileMapLayer] = []
	for child in layers_root.get_children():
		if child is TileMapLayer:
			map_layers.append(child)

	if map_layers.is_empty():
		push_warning("No se encontraron TileMapLayer en el nodo: %s" % map_layers_root_path)
		return

	var has_cells := false
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF

	for map_layer in map_layers:
		var used_rect: Rect2i = map_layer.get_used_rect()
		if used_rect.size == Vector2i.ZERO:
			continue

		has_cells = true

		var tile_size: Vector2i = Vector2i(16, 16)
		if map_layer.tile_set:
			tile_size = map_layer.tile_set.tile_size

		var half_tile := Vector2(tile_size) * 0.5
		var first_cell_center_local := map_layer.map_to_local(used_rect.position)
		var last_cell := used_rect.position + used_rect.size - Vector2i.ONE
		var last_cell_center_local := map_layer.map_to_local(last_cell)

		var top_left_world := map_layer.to_global(first_cell_center_local - half_tile)
		var bottom_right_world := map_layer.to_global(last_cell_center_local + half_tile)

		min_x = min(min_x, min(top_left_world.x, bottom_right_world.x))
		min_y = min(min_y, min(top_left_world.y, bottom_right_world.y))
		max_x = max(max_x, max(top_left_world.x, bottom_right_world.x))
		max_y = max(max_y, max(top_left_world.y, bottom_right_world.y))

	if not has_cells:
		push_warning("Ningun TileMapLayer tiene celdas pintadas. No se aplicaron limites de camara.")
		return

	limit_left = int(floor(min_x))
	limit_top = int(floor(min_y))
	limit_right = int(ceil(max_x)) + right_limit_padding
	limit_bottom = int(ceil(max_y))
		
