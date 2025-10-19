extends "res://personajes/personaje_base.gd"

var direccion := Vector2.ZERO
var tiempo_cambio := 0.5
var tiempo_actual := 0.0
var tiempo_disparo := 0.0
var tiempo_desde_disparo := 0.0
var FireballScene: PackedScene = null

var can_shoot = true
var fireball_scene = preload("res://Scenes/Entities/FireBall.tscn")

var anim_player: AnimatedSprite2D = null
var max_health: float = 10.0  # Vida máxima del minion (ajustado para 1 segundo con water_pressure = 10)
var health: float = 10.0
var is_being_extinguished: bool = false

func _ready():
	# no se usan disparos en minions ahora, pero conectamos el timer por si se re-activa
	$AttackTimer.timeout.connect(_on_AttackTimer_timeout)
	anim_player = $AnimatedSprite2D
	_setup_animation_frames()
	# Ensure this node is recognized as an enemy for collisions/filters
	add_to_group("enemy")
	add_to_group("minion")
	
	# Conectar señales de colisión si tiene Area2D
	if has_node("HitArea"):
		var hit_area = get_node("HitArea")
		if hit_area.has_signal("body_entered"):
			hit_area.body_entered.connect(_on_hit_area_body_entered)

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
		# Determinar un pequeño offset hacia adelante para que no colisione con el propio minion
		var spawn_offset = 20.0
		var spawn_pos = global_position + target_dir * spawn_offset
		print_debug("Minion shooting from:", global_position)
		print_debug("Target dir:", target_dir, "spawn offset:", spawn_offset)
		# Establecer la dirección correctamente en la instancia (API pública preferida)
		if fireball.has_method("set_direction"):
			fireball.set_direction(target_dir)
		else:
			# Intentar asignar 'direction' si existe
			var existing_dir = fireball.get("direction")
			if existing_dir != null:
				fireball.set("direction", target_dir)
			else:
				# Fallback: asignar 'velocity' usando 'speed' si está definido en la instancia, si no usar 600
				var fb_speed = 600
				var s = fireball.get("speed")
				if s != null:
					fb_speed = s
				fireball.set("velocity", target_dir * fb_speed)
		var root_scene = get_tree().get_current_scene()
		# If the fireball is an Area2D, temporarily disable monitoring to avoid instant self-collision
		var was_area := false
		if fireball is Area2D:
			was_area = true
			# disable monitoring if available
			if fireball.has_method("set"):
				fireball.set("monitoring", false)

		# Add fireball deferred and set position/collision exceptions deferred to avoid instant collision
		if root_scene:
			# Ensure monitoring is off before adding (if supported)
			if was_area and fireball.has_method("set"):
				fireball.set("monitoring", false)
			root_scene.call_deferred("add_child", fireball)
			# set global position, add collision exception and re-enable monitoring on next idle
			fireball.call_deferred("set", "global_position", spawn_pos)
			if fireball.has_method("add_collision_exception_with"):
				fireball.call_deferred("add_collision_exception_with", self)
			if was_area and fireball.has_method("set"):
				fireball.call_deferred("set", "monitoring", true)
		else:
			if was_area and fireball.has_method("set"):
				fireball.set("monitoring", false)
			get_parent().call_deferred("add_child", fireball)
			fireball.call_deferred("set", "global_position", spawn_pos)
			if fireball.has_method("add_collision_exception_with"):
				fireball.call_deferred("add_collision_exception_with", self)
			if was_area and fireball.has_method("set"):
				fireball.call_deferred("set", "monitoring", true)

func mover_personaje(delta):
	tiempo_actual += delta
	if tiempo_actual > tiempo_cambio:
		direccion = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		tiempo_actual = 0.0
	# Proteger en caso de que `speed` sea null (algunas escenas de prueba pueden no exportarlo)
	var spd = speed if speed != null else 200.0
	velocity = direccion * spd
	move_and_slide()
	shoot()
	# Ensure minion stays inside viewport/world bounds
	keep_in_viewport()

	# Flip sprite depending on movement direction
	if anim_player:
		if direccion.x < 0:
			anim_player.flip_h = true
		elif direccion.x > 0:
			anim_player.flip_h = false

func _physics_process(delta):
	mover_personaje(delta)

	# Mantener dentro del viewport
	keep_in_viewport()
	
	# Actualizar efectos visuales si está siendo apagado
	if is_being_extinguished:
		_update_extinguish_effects()

# ==============================
# Damage & Death handling
# ==============================
func take_damage(amount: float) -> void:
	health -= amount
	print("Minion recibiendo daño. Vida restante: ", health, "/", max_health)
	
	# Efectos visuales cuando recibe daño
	if health > 0:
		_flash_damage()
	
	if health <= 0:
		die()

func apply_water(amount: float) -> void:
	"""Aplica agua al minion, apagándolo gradualmente"""
	is_being_extinguished = true
	
	# El agua hace daño al minion
	health -= amount
	
	print("Minion siendo apagado con agua. Vida restante: ", health, "/", max_health)
	
	if health <= 0:
		die()

func _update_extinguish_effects() -> void:
	"""Actualiza efectos visuales mientras el minion se apaga"""
	if anim_player:
		# Hacer el minion más transparente a medida que pierde vida
		var alpha = health / max_health
		anim_player.modulate.a = clamp(alpha, 0.3, 1.0)
		
		# Hacer el minion más pequeño a medida que se apaga
		var scale_factor = 0.7 + (health / max_health) * 0.3
		anim_player.scale = anim_player.scale.normalized() * scale_factor * 0.1

func _flash_damage() -> void:
	"""Efecto de flash cuando recibe daño"""
	if anim_player:
		# Flash rojo al recibir daño
		anim_player.modulate = Color(1.5, 0.5, 0.5, 1.0)
		# Crear un tween para volver al color normal
		var tween = create_tween()
		tween.tween_property(anim_player, "modulate", Color(1, 1, 1, anim_player.modulate.a), 0.15)

func die() -> void:
	"""Minion muere"""
	print("¡Minion eliminado!")
	
	# Llamar al LootManager para posible drop
	if LootManager and LootManager.has_method("al_morir_minion"):
		LootManager.al_morir_minion(global_position)
	
	# Efectos de muerte, sonidos, etc., pueden agregarse aquí
	queue_free()


func _on_hit_area_body_entered(body: Node) -> void:
	"""Cuando el minion colisiona con algo"""
	# Si colisiona con el jugador, causar daño
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(10.0)  # El minion causa 10 de daño
			print_debug("Minion hit player, dealing 10 damage")
		elif body.has_method("die"):
			body.die()
		
		# El minion se destruye al chocar con el jugador
		die()
