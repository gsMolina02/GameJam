extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

func _ready() -> void:
	# Por precaución, aseguramos que el árbol no esté pausado
	get_tree().paused = false
	
	# Conectamos la señal que avisa cuando el video termina naturalmente
	video_player.finished.connect(_on_video_finished)

func _input(event: InputEvent) -> void:
	# Detectamos si se presiona una tecla
	if event is InputEventKey and event.pressed:
		# Si la tecla es la 'P', saltamos el video
		if event.keycode == KEY_P:
			_ir_al_menu_principal()

func _on_video_finished() -> void:
	# Se llama automáticamente cuando el .ogv llega al final
	_ir_al_menu_principal()

func _ir_al_menu_principal() -> void:
	# Apagamos el input para evitar que el jugador presione 'P' 
	# varias veces mientras carga la siguiente escena
	set_process_input(false)
	
	print("🎬 Créditos terminados o saltados. Volviendo al menú principal...")
	
	# Transición totalmente limpia. Al hacer esto, la escena de créditos 
	# (y el video) se destruyen de la RAM y carga el menú principal de cero.
	get_tree().change_scene_to_file("res://Interfaces/main_menu.tscn")
