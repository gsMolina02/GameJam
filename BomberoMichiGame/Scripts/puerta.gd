extends Area2D

# Configuración de la puerta
@export_file("*.tscn") var escena_destino: String = ""  # Ruta a la escena destino
@export var nombre_puerta_destino: String = ""  # Nombre de la puerta de destino
@export var offset_spawn: Vector2 = Vector2(50, 0)  # Distancia desde la puerta al aparecer
@export var bloqueada_al_inicio: bool = true  # Bloquear hasta completar habitación

# Estado
var bloqueada: bool = true
var label_interactuar: Label = null

func _t(key: String) -> String:
	if has_node("/root/Localization"):
		return get_node("/root/Localization").translate(key)
	return key

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("puertas")
	add_to_group("localizable")

	label_interactuar = Label.new()
	label_interactuar.text = _t("door.enter")
	label_interactuar.position = Vector2(-30, -50)
	label_interactuar.visible = false
	add_child(label_interactuar)

	bloqueada = bloqueada_al_inicio
	print("Puerta configurada:", name, "-> Destino:", escena_destino)

func update_texts() -> void:
	if label_interactuar:
		label_interactuar.text = _t("door.locked" if bloqueada else "door.enter")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_main"):
		if label_interactuar:
			if bloqueada:
				label_interactuar.text = _t("door.locked")
				label_interactuar.modulate = Color.RED
			else:
				label_interactuar.text = _t("door.enter")
				label_interactuar.modulate = Color.WHITE
			label_interactuar.visible = true
		print("Jugador cerca de la puerta:", name, "Bloqueada:", bloqueada)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player_main"):
		# Ocultar indicador
		if label_interactuar:
			label_interactuar.visible = false

func _physics_process(_delta: float) -> void:
	# Detectar si el jugador está cerca y presiona F
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player_main"):
			if Input.is_action_just_pressed("interact"):
				cambiar_escena(body)
				break

func cambiar_escena(jugador: Node2D) -> void:
	# Verificar si está bloqueada
	if bloqueada:
		print("🔒 Puerta bloqueada - Debes completar la habitación primero")
		return
	
	if escena_destino == "":
		push_error("⚠️ No se configuró 'escena_destino' en la puerta:", name)
		return
	
	print("🚪 Cambiando de escena...")
	print("  Desde:", get_tree().current_scene.scene_file_path)
	print("  Hacia:", escena_destino)
	print("  Puerta destino:", nombre_puerta_destino)
	
	# Guardar estado del jugador
	GameManager.guardar_estado_jugador(jugador)
	GameManager.puerta_origen = nombre_puerta_destino
	GameManager.offset_spawn = offset_spawn
	
	# Auto-guardado: guardar la partida con el nivel destino
	SaveManager.save_game(escena_destino, jugador)
	print("💾 Auto-guardado al entrar a:", escena_destino)
	
	# Cambiar escena
	get_tree().call_deferred("change_scene_to_file", escena_destino)

func desbloquear() -> void:
	"""Desbloquea la puerta cuando se completa la habitación"""
	bloqueada = false
	print("🔓 Puerta desbloqueada:", name)
