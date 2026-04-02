extends CharacterBody2D

@export var speed: float = 260.0
@export var detection_radius: float = 220.0
@export var attack_radius: float = 70.0
@export var target_group: StringName = &"player_main"
@export var max_health: float = 40.0

@export var idle_animation: StringName = &"SabuesoIdle"
@export var run_animation: StringName = &"SabuesoRun"
@export var attack_idle_animation: StringName = &"SabuesoAtackIdle"
@export var hurt_water_animation: StringName = &"SabuesoDanioAgua"
@export var hurt_axe_animation: StringName = &"SabuesoDanioAxe"
@export var hurt_general_animation: StringName = &"SabuesoDanioGenrl"
@export var death_animation: StringName = &"SabuesoMuert"
@export var hurt_animation_time: float = 0.22
@export var death_queue_free_delay: float = 0.9
@export var sprite_faces_right_by_default: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D

var target: Node2D = null
var _search_cooldown: int = 0
var _deep_search_cooldown: int = 0
var _current_health: float = 0.0
var _is_dead: bool = false
var _anim_lock_timer: float = 0.0
var _locked_animation: StringName = &""

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("hellhound")
	_current_health = max_health
	_configure_detection_area()

	if detection_area.body_entered.is_connected(_on_detection_body_entered) == false:
		detection_area.body_entered.connect(_on_detection_body_entered)
	if detection_area.body_exited.is_connected(_on_detection_body_exited) == false:
		detection_area.body_exited.connect(_on_detection_body_exited)

	_sync_detection_shape()
	_play_animation_if_exists(idle_animation, run_animation)
	target = _find_player()

func _physics_process(delta: float) -> void:
	if _is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _anim_lock_timer > 0.0:
		_anim_lock_timer -= delta
		if _anim_lock_timer <= 0.0:
			_anim_lock_timer = 0.0
			_locked_animation = &""

	if target == null or not is_instance_valid(target):
		# Buscar jugador con escaneo ligero cada 30 frames.
		_search_cooldown -= 1
		if _search_cooldown <= 0:
			target = _find_player()
			_search_cooldown = 30

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
	_update_animation_state()

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
	# Fast path: no crea arrays y funciona bien con muchas instancias.
	var main_player := get_tree().get_first_node_in_group(target_group)
	if main_player and main_player is Node2D:
		return main_player as Node2D

	var fallback_player := get_tree().get_first_node_in_group("player")
	if fallback_player and fallback_player is Node2D:
		return fallback_player as Node2D

	# Deep path: búsqueda por nombre, pero solo cada cierto tiempo para evitar picos.
	_deep_search_cooldown -= 1
	if _deep_search_cooldown <= 0:
		_deep_search_cooldown = 120
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
	_play_animation_if_exists(run_animation, idle_animation)

func _update_animation_state() -> void:
	if sprite == null:
		return

	if _is_dead:
		_play_animation_if_exists(death_animation, idle_animation)
		return

	if _anim_lock_timer > 0.0 and _locked_animation != &"":
		_play_animation_if_exists(_locked_animation, idle_animation)
		return

	if target and is_instance_valid(target) and global_position.distance_to(target.global_position) <= attack_radius:
		_play_animation_if_exists(attack_idle_animation, idle_animation)
	elif velocity.length_squared() > 1.0:
		_play_animation_if_exists(run_animation, idle_animation)
	else:
		_play_animation_if_exists(idle_animation, run_animation)

func _play_animation_if_exists(primary: StringName, fallback: StringName = &"") -> bool:
	if sprite == null or sprite.sprite_frames == null:
		return false

	if primary != &"" and sprite.sprite_frames.has_animation(primary):
		if sprite.animation != primary or not sprite.is_playing():
			sprite.play(primary)
		return true

	if fallback != &"" and sprite.sprite_frames.has_animation(fallback):
		if sprite.animation != fallback or not sprite.is_playing():
			sprite.play(fallback)
		return true

	return false

func _play_temporary_animation(anim_name: StringName, duration: float) -> void:
	if _is_dead:
		return
	if _play_animation_if_exists(anim_name, idle_animation):
		_locked_animation = anim_name
		_anim_lock_timer = max(duration, 0.01)

func take_damage(amount: float, source: StringName = &"general") -> void:
	if _is_dead:
		return

	_current_health -= amount
	if _current_health <= 0.0:
		die()
		return

	match source:
		&"agua", &"water":
			_play_temporary_animation(hurt_water_animation, hurt_animation_time)
		&"hacha", &"axe":
			_play_temporary_animation(hurt_axe_animation, hurt_animation_time)
		_:
			_play_temporary_animation(hurt_general_animation, hurt_animation_time)

func apply_water(amount: float) -> void:
	take_damage(amount, &"agua")

func die() -> void:
	if _is_dead:
		return

	_is_dead = true
	velocity = Vector2.ZERO
	if detection_area:
		detection_area.monitoring = false

	_play_animation_if_exists(death_animation, idle_animation)
	await get_tree().create_timer(death_queue_free_delay).timeout
	if is_inside_tree():
		queue_free()

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
