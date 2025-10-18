extends "res://personajes/personaje_base.gd"

var direccion := Vector2.ZERO
var tiempo_cambio := 0.5
var tiempo_actual := 0.0

var can_shoot = true
var fireball_scene = preload("res://Scenes/Entities/FireBall.tscn")

var anim_player: AnimatedSprite2D = null

func _ready():
	$AttackTimer.timeout.connect(_on_AttackTimer_timeout)
	anim_player = $AnimatedSprite2D
	_setup_animation_frames()

func _setup_animation_frames():
	# Busca imágenes en res://Assets/minions/ (carpeta opcional)
	var dir_path = "res://Assets/minions/"
	var fs = DirAccess.open(dir_path)
	if not fs:
		return
	
	var frames = []
	fs.list_dir_begin()
	var fname = fs.get_next()
	while fname != "":
		if not fs.current_is_dir():
			if fname.to_lower().ends_with(".png") or fname.to_lower().ends_with(".webp") or fname.to_lower().ends_with(".jpg"):
				frames.append(dir_path + fname)
		fname = fs.get_next()
	fs.list_dir_end()
	frames.sort()
	if frames.size() == 0:
		return
	var sf = SpriteFrames.new()
	sf.add_animation("walk")
	for f in frames:
		var tex = load(f)
		sf.add_frame("walk", tex)
	anim_player.frames = sf
	anim_player.frames = sf
	anim_player.animation = "walk"
	anim_player.play()
	# Aumenta velocidad por defecto (multiplicador)
	anim_player.speed_scale = 1.5

func _on_AttackTimer_timeout():
	can_shoot = true

func shoot():
	if can_shoot:
		# Determinar objetivo en el momento de disparar
		var target_dir = direccion
		var current_scene = get_tree().get_current_scene()
		var player = null
		if current_scene:
			# Try common node names, prefer the snake_case `personaje_principal`
			player = current_scene.get_node_or_null("personaje_principal")
			if not player:
				player = current_scene.get_node_or_null("personajePrincipal")
			if not player:
				player = current_scene.find_node("personaje_principal", true, false)
			if not player:
				player = current_scene.find_node("personajePrincipal", true, false)
		if player:
			# Calcular dirección desde la posición del minion hacia la posición del player
			target_dir = (player.global_position - global_position).normalized()

		if target_dir == Vector2.ZERO:
			return

		can_shoot = false
		$AttackTimer.start()
		var fireball = fireball_scene.instantiate()
		# Posicionar la bola de fuego justo delante del minion en la dirección calculada
		var offset = target_dir * 100
		fireball.global_position = global_position + offset
		fireball.set_direction(target_dir)
		var root_scene = get_tree().get_current_scene()
		if root_scene:
			root_scene.add_child(fireball)
		else:
			get_parent().add_child(fireball)

func mover_personaje(delta):
	tiempo_actual += delta
	if tiempo_actual > tiempo_cambio:
		direccion = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		tiempo_actual = 0.0
	velocity = direccion * speed
	move_and_slide()
	shoot()
	# Ensure minion stays inside viewport/world bounds
	_clamp_to_viewport()

	# Flip sprite depending on movement direction
	if anim_player:
		if direccion.x < 0:
			anim_player.flip_h = true
		elif direccion.x > 0:
			anim_player.flip_h = false

func _physics_process(delta):
	mover_personaje(delta)
