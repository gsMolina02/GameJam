extends Node2D

# Referencias
var music_player: AudioStreamPlayer2D = null
var boss: Node = null
var fuego_node: Node = null

# Configuración
@export var loop_end_time: float = 51.0  # Loopear hasta los 51 segundos
@export var check_interval: float = 0.1  # Revisar cada 0.1 segundos

# Estado
var is_boss_alive: bool = true
var loop_timer: float = 0.0
var last_boss_health: float = -1.0

func _ready() -> void:
	# Obtener referencias
	music_player = get_node_or_null("musicaFondoCasino")
	boss = get_node_or_null("Wall_righ_above/jefe")
	fuego_node = get_node_or_null("TileMapLayers/Fuego")
	
	if not music_player:
		push_error("❌ No se encontró musicaFondoCasino")
		queue_free()
		return
	
	if not boss:
		push_error("❌ No se encontró el jefe")
		queue_free()
		return
	
	# Inicializar referencia de vida del jefe
	if boss.has_meta("vida_actual_jefe") or "vida_actual_jefe" in boss:
		last_boss_health = boss.get("vida_actual_jefe")
	
	print("✓ Boss Music Looper inicializado")
	print("  - Música: %s" % music_player.name)
	print("  - Jefe: %s" % boss.name)
	print("  - Loop hasta: %.1f segundos" % loop_end_time)
	
	# Restaurar estado del jugador
	await get_tree().process_frame
	var jugador = get_tree().get_first_node_in_group("player_main")
	if jugador:
		print("  📥 Restaurando estado del jugador en Casino...")
		GameManager.restaurar_estado_jugador(jugador)
		GameManager.posicionar_jugador_en_puerta(jugador, self)
	else:
		push_warning("⚠️ No se encontró jugador en Casino Boss Level")

func _process(delta: float) -> void:
	if not music_player or not music_player.playing:
		return
	
	loop_timer += delta
	
	# Revisar cada check_interval si el jefe está vivo
	if loop_timer >= check_interval:
		loop_timer = 0.0
		_check_boss_status()
	
	# Si el jefe está vivo, hacer el looping
	if is_boss_alive:
		_handle_music_loop()

func _check_boss_status() -> void:
	"""Verifica si el jefe está vivo"""
	# Si el boss no existe o fue eliminado
	if not is_instance_valid(boss):
		print("💀 Jefe eliminado - finalizando looping")
		is_boss_alive = false
		return
	
	# Verificar salud del jefe
	if boss.has_meta("vida_actual_jefe") or "vida_actual_jefe" in boss:
		var vida = boss.get("vida_actual_jefe")
		
		# Si la vida cambió a 0 o negativo
		if vida <= 0 and last_boss_health > 0:
			print("💀 Jefe derrotado (vida: %.1f) - finalizando looping" % vida)
			is_boss_alive = false
			_on_boss_died()
			return
		
		last_boss_health = vida

func _handle_music_loop() -> void:
	"""Maneja el looping de la música hasta loop_end_time"""
	var current_position = music_player.get_playback_position()
	
	# Si llegó o superó el tiempo de loop, reiniciar
	if current_position >= loop_end_time:
		#print("🔄 Reiniciando música en posición %.2f (superó %.1f secs)" % [current_position, loop_end_time])
		music_player.seek(0.0)

func _on_boss_died() -> void:
	"""Se llama cuando el jefe muere"""
	print("🎊 JEFE DERROTADO - Deteniendo looping de música")
	is_boss_alive = false
	print("✓ La música se reproducirá normalmente hasta el final")
