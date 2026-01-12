extends Control

# Configuración de las 3 páginas de la historia
# Cada página tiene una imagen y un texto
@export var story_pages: Array[Dictionary] = [
	{
		"image": "res://Assets/fondos/intro001.png",
		"text": "Hace mucho tiempo, la ciudad de Felinia era un lugar pacífico...\n\nLos gatos y humanos vivían en armonía, protegidos por valientes bomberos."
	},
	{
		"image": "res://Assets/fondos/1.jpg", 
		"text": "Pero un día, misteriosas llamas comenzaron a aparecer en toda la ciudad...\n\nEran llamas que no podían ser apagadas con agua normal."
	},
	{
		"image": "res://Assets/fondos/story3.png",
		"text": "Un joven bombero llamado Michi descubrió que tenía un don especial...\n\n¡Podía controlar el agua de formas mágicas! Ahora, la esperanza de la ciudad descansa en sus patas."
	}
]

# Escena a la que ir después de la intro (tu nivel o escena de juego)
@export var next_scene: String = "res://Scenes/Levels/level1/level1.tscn"

# Velocidad del efecto de escritura
@export var typing_speed: float = 40.0

# Tiempo de espera después de terminar el texto antes de permitir avanzar
@export var wait_after_text: float = 1.0

var current_page: int = 0
var current_char: int = 0
var is_typing: bool = false
var can_advance: bool = false
var full_text: String = ""

func _ready():
	# Mostrar el cursor del sistema en la intro de historia
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Validar que tengamos páginas configuradas
	if story_pages.is_empty():
		push_error("No hay páginas de historia configuradas!")
		go_to_next_scene()
		return
	
	# Mostrar la primera página
	show_page(0)

func show_page(page_index: int):
	if page_index >= story_pages.size():
		# Ya no hay más páginas, ir a la siguiente escena
		finish_story()
		return
	
	current_page = page_index
	can_advance = false
	
	# Actualizar indicador de página
	$PageIndicator.text = str(current_page + 1) + "/" + str(story_pages.size())
	
	# Fade out de la imagen actual
	if current_page > 0:
		$AnimationPlayer.play("fade_out")
		await $AnimationPlayer.animation_finished
	
	# Cargar nueva imagen
	var page_data = story_pages[current_page]
	var texture = load(page_data["image"])
	if texture:
		$HBoxContainer/StoryImage.texture = texture
	else:
		push_warning("No se pudo cargar la imagen: " + page_data["image"])
	
	# Fade in de la nueva imagen
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	
	# Iniciar texto vacío
	$HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/StoryText.text = ""
	full_text = page_data["text"]
	
	# Iniciar efecto de escritura
	start_typing()

func start_typing():
	is_typing = true
	current_char = 0
	
	while current_char < full_text.length() and is_typing:
		$HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/StoryText.text = full_text.substr(0, current_char + 1)
		current_char += 1
		await get_tree().create_timer(1.0 / typing_speed).timeout
	
	# Cuando termina de escribir
	if is_typing:
		is_typing = false
		$Timer.wait_time = wait_after_text
		$Timer.start()

func _on_timer_timeout():
	can_advance = true

func _input(event):
	# Solo responder a Enter o click de mouse (NO Space)
	if event is InputEventMouseButton and event.is_pressed():
		handle_input()
	elif event is InputEventKey and event.is_pressed() and event.keycode == KEY_ENTER:
		handle_input()

func handle_input():
	if is_typing:
		# Si está escribiendo, mostrar todo el texto inmediatamente
		is_typing = false
		$HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/StoryText.text = full_text
		$Timer.wait_time = wait_after_text
		$Timer.start()
	elif can_advance:
		# Si ya terminó, avanzar a la siguiente página
		advance_page()

func advance_page():
	show_page(current_page + 1)

func finish_story():
	# Fade a negro y cambiar a la escena del juego
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	go_to_next_scene()

func go_to_next_scene():
	# Verificar que el SceneTree esté disponible
	var tree = get_tree()
	if tree == null:
		push_error("SceneTree is null! Cannot change scene.")
		return
	
	# Verificar que next_scene no esté vacío
	if next_scene.is_empty():
		push_error("next_scene is empty! Cannot change scene.")
		return
	
	# Cambiar la escena
	var error = tree.change_scene_to_file(next_scene)
	if error != OK:
		push_error("Failed to load scene: " + next_scene + " Error code: " + str(error))
