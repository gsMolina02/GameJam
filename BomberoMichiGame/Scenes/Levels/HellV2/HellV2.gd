extends Node2D

var musica_con_enemigos: AudioStreamPlayer
var musica_sin_enemigos: AudioStreamPlayer2D
var en_transicion: bool = false
var duracion_fade: float = 2.0  # Segundos para el fade
var transicion_realizada: bool = false

func _ready():
	# Obtener referencias de los nodos de música
	musica_con_enemigos = $MusicaFondo
	musica_sin_enemigos = $MusicaFondoSinEnemigos
	
	# Iniciar la música desde el segundo 16
	musica_con_enemigos.play(16)
	musica_sin_enemigos.volume_db = -80  # Empezar silenciado

func _process(delta: float) -> void:
	# Si ya realizamos la transición, no hacer nada
	if transicion_realizada:
		return
	
	# Si estamos en transición, no verificar
	if en_transicion:
		return
	
	# Solo transicionar si no hay enemigos y no hay fuego
	if not _hay_enemigos() and not _hay_fuego():
		_transicionar_musica()

func _hay_enemigos() -> bool:
	"""Verifica si hay enemigos activos en el nivel"""
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	var enemigos_old = get_tree().get_nodes_in_group("enemy")
	return enemigos.size() > 0 or enemigos_old.size() > 0

func _hay_fuego() -> bool:
	"""Verifica si hay fuego activo en el nivel"""
	var fuegos = get_tree().get_nodes_in_group("fuego")
	return fuegos.size() > 0

func _transicionar_musica() -> void:
	"""Realiza la transición de música con fade out/fade in"""
	en_transicion = true
	
	# Crear tweens para el fade out/fade in
	var tween = create_tween()
	tween.set_parallel(true)  # Ejecutar ambas animaciones simultáneamente
	tween.set_trans(Tween.TRANS_LINEAR)
	
	# Fade out de la música actual
	tween.tween_property(musica_con_enemigos, "volume_db", -80, duracion_fade)
	
	# Fade in de la nueva música
	tween.tween_property(musica_sin_enemigos, "volume_db", 0, duracion_fade)
	
	# Cuando termine el fade, empezar la nueva música
	tween.tween_callback(func():
		musica_con_enemigos.stop()
		if not musica_sin_enemigos.playing:
			musica_sin_enemigos.play()
		en_transicion = false
		transicion_realizada = true
	)
