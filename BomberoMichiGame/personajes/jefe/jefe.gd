extends "res://personajes/personaje_base.gd"

var direccion := Vector2.ZERO
var tiempo_cambio := 0.5
var tiempo_actual := 0.0

var can_shoot := true
var fireball_bounce_scene = preload("res://Scenes/Entities/FireBallBounce.tscn")

func mover_personaje(delta):
	tiempo_actual += delta
	if tiempo_actual > tiempo_cambio:
		direccion = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		tiempo_actual = 0.0
	velocity = direccion * speed
	move_and_slide()
	# Ensure jefe stays inside viewport/world bounds
	_clamp_to_viewport()

func _physics_process(delta):
	mover_personaje(delta)

func _ready():
	print("[Jefe] _ready called")
	# Si hay un Timer llamado AttackTimer en la escena, conéctalo. Si no existe, creamos uno y lo arrancamos.
	if has_node("AttackTimer"):
		$AttackTimer.timeout.connect(_on_AttackTimer_timeout)
		print("[Jefe] Connected existing AttackTimer")
	else:
		var t = Timer.new()
		t.name = "AttackTimer"
		t.wait_time = 3.0
		t.one_shot = false
		add_child(t)
		# Conectar con Callable para mayor seguridad y arrancar explícitamente
		t.timeout.connect(Callable(self, "_on_AttackTimer_timeout"))
		t.start()
		print("[Jefe] Created and started AttackTimer")

func _on_AttackTimer_timeout():
	can_shoot = true
	print("[Jefe] AttackTimer timeout — shooting")
	shoot()

func shoot():
	if not can_shoot:
		return

	var current_scene = get_tree().get_current_scene()
	var target_dir = direccion
	var player = null
	if current_scene:
		player = current_scene.get_node_or_null("personaje_principal")
		if not player:
			player = current_scene.get_node_or_null("personajePrincipal")
		if not player:
			player = current_scene.find_node("personaje_principal", true, false)
		if not player:
			player = current_scene.find_node("personajePrincipal", true, false)
	if player:
		target_dir = (player.global_position - global_position).normalized()

	if target_dir == Vector2.ZERO:
		return

	can_shoot = false
	# Instanciar proyectil rebotador
	var proj = fireball_bounce_scene.instantiate()
	proj.global_position = global_position + target_dir * 50
	proj.set_direction(target_dir)
	var root_scene = get_tree().get_current_scene()
	if root_scene:
		root_scene.add_child(proj)
	else:
		get_parent().add_child(proj)
