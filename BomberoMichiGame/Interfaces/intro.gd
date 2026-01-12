extends Control

# Ruta de la imagen de fondo (cámbiala por tu imagen)
@export var background_image_path: String = "res://Assets/fondos/fondo.jpg"

# Título que aparecerá arriba
@export var intro_title: String = "Bombero Michi"

# Texto que aparecerá progresivamente en la intro
@export_multiline var intro_text: String = "En un mundo consumido por las llamas...\n\nUn héroe felino debe levantarse para salvar a su ciudad.\n\nEquipado con su manguera y valentía,\ndeberás enfrentarte a las amenazas ardientes."

# Tamaño de fuente del texto (reduce para textos largos)
@export_range(14, 40) var text_font_size: int = 20

# Velocidad del efecto de máquina de escribir (caracteres por segundo)
@export var typing_speed: float = 40.0

# Tiempo de espera después de que termine el texto antes de ir al menú
@export var wait_after_text: float = 2.5

var current_char: int = 0
var is_typing: bool = false
var can_skip: bool = false

func _ready():
	# Cargar la imagen de fondo
	var texture = load(background_image_path)
	if texture:
		$BackgroundImage.texture = texture
	
	# Establecer el título
	$TextContainer/MarginContainer/VBoxContainer/Title.text = intro_title
	
	# Configurar tamaño de fuente
	$TextContainer/MarginContainer/VBoxContainer/IntroText.add_theme_font_size_override("normal_font_size", text_font_size)
	
	# Iniciar el texto vacío
	$TextContainer/MarginContainer/VBoxContainer/IntroText.text = ""
	
	# Reproducir animación de entrada del recuadro
	$AnimationPlayer.play("fade_in")
	
	# Esperar a que termine la animación de entrada para empezar a escribir
	await get_tree().create_timer(1.0).timeout
	
	# Iniciar el efecto de máquina de escribir
	start_typing()

func start_typing():
	is_typing = true
	can_skip = true
	current_char = 0
	
	# Timer para el efecto de escritura
	while current_char < intro_text.length() and is_typing:
		$TextContainer/MarginContainer/VBoxContainer/IntroText.text = intro_text.substr(0, current_char + 1)
		current_char += 1
		await get_tree().create_timer(1.0 / typing_speed).timeout
	
	# Cuando termina de escribir, iniciar timer para ir al menú
	if is_typing:
		is_typing = false
		$Timer.wait_time = wait_after_text
		$Timer.start()

func _on_timer_timeout():
	# Reproducir animación de salida
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	
	# Cambiar a la escena del menú principal
	get_tree().change_scene_to_file("res://Interfaces/main_menu.tscn")

# Permitir saltar la intro solo con Enter o click de mouse (NO Space)
func _input(event):
	if not can_skip:
		return
		
	if event is InputEventMouseButton and event.is_pressed():
		skip_intro()
	elif event is InputEventKey and event.is_pressed() and event.keycode == KEY_ENTER:
		skip_intro()

func skip_intro():
	if is_typing:
		# Si está escribiendo, mostrar todo el texto inmediatamente
		is_typing = false
		$TextContainer/MarginContainer/VBoxContainer/IntroText.text = intro_text
		$Timer.wait_time = wait_after_text
		$Timer.start()
	else:
		# Si ya terminó de escribir, ir al menú inmediatamente
		get_tree().change_scene_to_file("res://Interfaces/main_menu.tscn")
