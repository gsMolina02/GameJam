extends Control

# Ruta de la imagen de fondo (cámbiala por tu imagen)
@export var background_image_path: String = "res://Assets/fondos/fondo.jpg"

# Tamaño de fuente del texto (reduce para textos largos)
@export_range(14, 40) var text_font_size: int = 20

# Velocidad del efecto de máquina de escribir (caracteres por segundo)
@export var typing_speed: float = 40.0

# Tiempo de espera después de que termine el texto antes de ir al menú
@export var wait_after_text: float = 2.5

var current_char: int = 0
var is_typing: bool = false
var can_skip: bool = false

func _t(key: String) -> String:
	if has_node("/root/Localization"):
		return get_node("/root/Localization").translate(key)
	return key

func _ready():
	add_to_group("localizable")

	# Cargar la imagen de fondo
	var texture = load(background_image_path)
	if texture:
		$BackgroundImage.texture = texture

	# Configurar tamaño de fuente
	$TextContainer/MarginContainer/VBoxContainer/IntroText.add_theme_font_size_override("normal_font_size", text_font_size)

	# Iniciar el texto vacío
	$TextContainer/MarginContainer/VBoxContainer/IntroText.text = ""

	# Establecer textos traducidos
	update_texts()

	# Reproducir animación de entrada del recuadro
	$AnimationPlayer.play("fade_in")

	# Esperar a que termine la animación de entrada para empezar a escribir
	await get_tree().create_timer(1.0).timeout

	# Iniciar el efecto de máquina de escribir
	start_typing()

func update_texts() -> void:
	$TextContainer/MarginContainer/VBoxContainer/Title.text = _t("intro.title")

func start_typing():
	is_typing = true
	can_skip = true
	current_char = 0
	var text = _t("intro.text")

	while current_char < text.length() and is_typing:
		$TextContainer/MarginContainer/VBoxContainer/IntroText.text = text.substr(0, current_char + 1)
		current_char += 1
		await get_tree().create_timer(1.0 / typing_speed).timeout

	if is_typing:
		is_typing = false
		$Timer.wait_time = wait_after_text
		$Timer.start()

func _on_timer_timeout():
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://Interfaces/main_menu.tscn")

func _input(event):
	if not can_skip:
		return
	if event is InputEventMouseButton and event.is_pressed():
		skip_intro()
	elif event is InputEventKey and event.is_pressed() and event.keycode == KEY_ENTER:
		skip_intro()

func skip_intro():
	if is_typing:
		is_typing = false
		$TextContainer/MarginContainer/VBoxContainer/IntroText.text = _t("intro.text")
		$Timer.wait_time = wait_after_text
		$Timer.start()
	else:
		get_tree().change_scene_to_file("res://Interfaces/main_menu.tscn")
