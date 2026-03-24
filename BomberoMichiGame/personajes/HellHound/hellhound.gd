extends CharacterBody2D

@export var speed: float = 260.0
@export var detection_radius: float = 220.0
@export var target_group: StringName = &"player_main"
@export var run_animation: StringName = &"SabuesoRun"
@export var sprite_faces_right_by_default: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D

var target: Node2D = null

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("hellhound")
	_configure_detection_area()

	if detection_area.body_entered.is_connected(_on_detection_body_entered) == false:
		detection_area.body_entered.connect(_on_detection_body_entered)
	if detection_area.body_exited.is_connected(_on_detection_body_exited) == false:
		detection_area.body_exited.connect(_on_detection_body_exited)

	_sync_detection_shape()
	_play_run()
	target = _find_player()

func _physics_process(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		target = _find_player()

	if target and is_instance_valid(target):
		var dir := (target.global_position - global_position)
		if dir.length() <= detection_radius:
			velocity = dir.normalized() * speed
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_update_facing()

func _on_detection_body_entered(body: Node) -> void:
	if body is Node2D and _is_player(body):
		target = body as Node2D

func _on_detection_body_exited(body: Node) -> void:
	if body == target:
		target = null

func _is_player(node: Node) -> bool:
	if node.is_in_group(target_group):
		return true
	if node.is_in_group("player"):
		return true
	return node.name in ["personajePrincipal", "Player", "player"]

func _find_player() -> Node2D:
	var main_players := get_tree().get_nodes_in_group(target_group)
	if main_players.size() > 0 and main_players[0] is Node2D:
		return main_players[0] as Node2D

	var fallback_players := get_tree().get_nodes_in_group("player")
	if fallback_players.size() > 0 and fallback_players[0] is Node2D:
		return fallback_players[0] as Node2D

	var scene := get_tree().current_scene
	if scene:
		for candidate_name in ["personajePrincipal", "Player", "player"]:
			var n := scene.find_child(candidate_name, true, false)
			if n and n is Node2D:
				return n as Node2D

	return null

func _sync_detection_shape() -> void:
	var shape_node := detection_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return

	var circle := shape_node.shape as CircleShape2D
	if circle:
		circle.radius = detection_radius

func _configure_detection_area() -> void:
	if detection_area == null:
		return

	# Esta area es solo para IA (deteccion), no para hacer dano.
	detection_area.monitoring = true
	detection_area.monitorable = false
	detection_area.collision_layer = 0
	# Detectar cuerpos del jugador en capas comunes (1 y 2).
	detection_area.collision_mask = 1 | 2

	for group_name in ["ataque_minion", "ataque_enemigo", "ataque_jefe", "fuego"]:
		if detection_area.is_in_group(group_name):
			detection_area.remove_from_group(group_name)

func _play_run() -> void:
	if sprite == null:
		return
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(run_animation):
		sprite.play(run_animation)

func _update_facing() -> void:
	if sprite == null:
		return
	if absf(velocity.x) < 1.0:
		return
	# Si el sprite original mira a la izquierda, invertir cuando se mueve a la derecha.
	if sprite_faces_right_by_default:
		sprite.flip_h = velocity.x < 0.0
	else:
		sprite.flip_h = velocity.x > 0.0
