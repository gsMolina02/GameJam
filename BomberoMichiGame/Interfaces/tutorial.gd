extends Node2D

@onready var player = $Player
@onready var ui_layer = $UILayer

func _t(key: String) -> String:
	if has_node("/root/Localization"):
		return get_node("/root/Localization").translate(key)
	return key

var key_refs: Dictionary = {}
var door_sprite_ref: Sprite2D = null
var door_f_label_ref: Label = null
var door_arrow_ref: Label = null
var door_center: Vector2 = Vector2.ZERO
var door_abierta: bool = false
var tween_f_label_blink: Tween = null
var tween_arrow_bounce: Tween = null

const COLOR_KEY_NORMAL  = Color(0.20, 0.20, 0.30, 1.0)
const COLOR_KEY_PRESSED = Color(0.90, 0.65, 0.05, 1.0)
const COLOR_TEXT_NORMAL  = Color(1.0,  1.0,  1.0,  1.0)
const COLOR_TEXT_PRESSED = Color(0.05, 0.05, 0.05, 1.0)

const CONTROLES = [
	{"action": "up",            "key": "W",         "desc_key": "tutorial.up"},
	{"action": "down",          "key": "S",          "desc_key": "tutorial.down"},
	{"action": "left",          "key": "A",          "desc_key": "tutorial.left"},
	{"action": "right",         "key": "D",          "desc_key": "tutorial.right"},
	{"action": "dash",          "key": "tutorial.space_key", "desc_key": "tutorial.dash"},
	{"action": "attack",        "key": "tutorial.lclick_key", "desc_key": "tutorial.attack"},
	{"action": "switch_weapon", "key": "tutorial.rclick_key", "desc_key": "tutorial.switch_weapon"},
	{"action": "interact",      "key": "F",          "desc_key": "tutorial.interact"},
]

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_configurar_jugador()
	_construir_ui()

func _configurar_jugador():
	if not player:
		return
	if "oxygen_loss_rate" in player:
		player.oxygen_loss_rate = 0.0
	if "oxygen_recovery_rate" in player:
		player.oxygen_recovery_rate = 100.0
	if "enforce_bounds" in player:
		player.enforce_bounds = true
		player.min_x = 40.0
		player.max_x = 860.0
		player.min_y = 40.0
		player.max_y = 860.0

func _construir_ui():
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(root)

	# Fondo semitransparente del area de controles (derecha)
	var panel_bg = ColorRect.new()
	panel_bg.position = Vector2(910, 0)
	panel_bg.size = Vector2(590, 900)
	panel_bg.color = Color(0.06, 0.04, 0.03, 0.92)
	root.add_child(panel_bg)

	# Linea separadora
	var sep = ColorRect.new()
	sep.position = Vector2(906, 0)
	sep.size = Vector2(4, 900)
	sep.color = Color(0.6, 0.35, 0.1, 0.9)
	root.add_child(sep)

	# Texto centrado en el area de juego
	var hint = Label.new()
	hint.text = _t("tutorial.hint")
	hint.position = Vector2(0, 30)
	hint.size = Vector2(900, 40)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 0.85))
	root.add_child(hint)

	# Titulo del panel
	var title = Label.new()
	title.text = _t("tutorial.title")
	title.position = Vector2(910, 25)
	title.size = Vector2(590, 55)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.2, 1.0))
	root.add_child(title)

	# Filas de controles
	var y_inicio = 95
	var altura_fila = 62
	for i in range(CONTROLES.size()):
		_agregar_fila(root, 925, y_inicio + i * altura_fila, CONTROLES[i])

	# Labels de la puerta (en el CanvasLayer para que esten encima)
	_agregar_labels_puerta(root)

	# Boton volver
	var btn_volver = Button.new()
	btn_volver.text = _t("tutorial.back")
	btn_volver.position = Vector2(930, 790)
	btn_volver.size = Vector2(550, 56)
	btn_volver.add_theme_font_size_override("font_size", 22)
	btn_volver.pressed.connect(_on_volver_pressed)
	root.add_child(btn_volver)

	# Puerta como Sprite2D en el mundo Node2D (tamaño real controlado por scale)
	_agregar_sprite_puerta()

func _agregar_fila(parent: Control, x: float, y: float, ctrl: Dictionary):
	var row = HBoxContainer.new()
	row.position = Vector2(x, y)
	row.custom_minimum_size = Vector2(550, 55)
	parent.add_child(row)

	var key_panel = PanelContainer.new()
	key_panel.custom_minimum_size = Vector2(148, 52)

	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_KEY_NORMAL
	style.set_corner_radius_all(7)
	style.set_content_margin_all(4)
	key_panel.add_theme_stylebox_override("panel", style)

	var key_label = Label.new()
	var key_str = ctrl["key"]
	key_label.text = _t(key_str) if key_str.begins_with("tutorial.") else key_str
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 19)
	key_label.add_theme_color_override("font_color", COLOR_TEXT_NORMAL)
	key_panel.add_child(key_label)
	row.add_child(key_panel)

	var arrow = Label.new()
	arrow.text = "  ->  "
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 20)
	arrow.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
	row.add_child(arrow)

	var desc = Label.new()
	desc.text = _t(ctrl["desc_key"])
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 20)
	desc.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	row.add_child(desc)

	key_refs[ctrl["action"]] = {"style": style, "label": key_label}

func _agregar_sprite_puerta():
	# Posicion central de la puerta en el mundo
	var door_cx = 620.0
	var door_cy = 480.0
	var door_w  = 250.0
	var door_h  = 240.0

	var door = Sprite2D.new()
	door.texture = load("res://Assets/fondos/puerta.png")
	var tex_size = door.texture.get_size()
	door.scale = Vector2(door_w / tex_size.x, door_h / tex_size.y)
	door.position = Vector2(door_cx, door_cy)
	add_child(door)

	door_sprite_ref = door
	door_center = Vector2(door_cx, door_cy)

	# Pulso de escala
	var base_scale = door.scale
	var pulse = Vector2(base_scale.x * 1.04, base_scale.y * 1.04)
	var tween_door = create_tween().set_loops()
	tween_door.tween_property(door, "scale", pulse,       0.7).set_ease(Tween.EASE_IN_OUT)
	tween_door.tween_property(door, "scale", base_scale,  0.7).set_ease(Tween.EASE_IN_OUT)

func _agregar_labels_puerta(parent: Control):
	# Coordenadas del centro de la puerta (iguales a _agregar_sprite_puerta)
	var door_cx = 620.0
	var door_cy = 480.0
	var door_h  = 240.0
	var label_w = 130.0

	# "[F] Entrar" encima de la puerta
	var f_label = Label.new()
	f_label.text = _t("door.enter")
	parent.add_child(f_label)
	f_label.position = Vector2(door_cx - label_w / 2.0, door_cy - door_h / 2.0 - 46)
	f_label.size = Vector2(label_w, 36)
	f_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f_label.add_theme_font_size_override("font_size", 18)
	f_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	door_f_label_ref = f_label

	# Flecha rebotante
	var arrow = Label.new()
	arrow.text = "v"
	parent.add_child(arrow)
	arrow.position = Vector2(door_cx - 10, door_cy - door_h / 2.0 - 72)
	arrow.size = Vector2(20, 28)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 22)
	arrow.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	door_arrow_ref = arrow

	# Parpadeo del label (guardado para poder matarlo al abrir la puerta)
	tween_f_label_blink = create_tween().set_loops()
	tween_f_label_blink.tween_property(f_label, "modulate:a", 0.15, 0.55)
	tween_f_label_blink.tween_property(f_label, "modulate:a", 1.0,  0.55)

	# Rebote de la flecha (guardado para poder matarlo al abrir la puerta)
	var pos_orig = arrow.position.y
	tween_arrow_bounce = create_tween().set_loops()
	tween_arrow_bounce.tween_property(arrow, "position:y", pos_orig + 12, 0.45).set_ease(Tween.EASE_IN_OUT)
	tween_arrow_bounce.tween_property(arrow, "position:y", pos_orig,      0.45).set_ease(Tween.EASE_IN_OUT)

func _process(_delta: float):
	for action in key_refs:
		var refs = key_refs[action]
		var presionada = Input.is_action_pressed(action)
		refs["style"].bg_color = COLOR_KEY_PRESSED if presionada else COLOR_KEY_NORMAL
		refs["label"].add_theme_color_override(
			"font_color",
			COLOR_TEXT_PRESSED if presionada else COLOR_TEXT_NORMAL
		)

	if not door_abierta and player and door_sprite_ref:
		var dist = player.position.distance_to(door_center)
		if dist < 140.0 and Input.is_action_just_pressed("interact"):
			_abrir_puerta()

func _abrir_puerta():
	door_abierta = true
	# Matar tweens en loop antes de animar la desaparicion
	if tween_f_label_blink:
		tween_f_label_blink.kill()
	if tween_arrow_bounce:
		tween_arrow_bounce.kill()
	# Puerta se desliza y desaparece
	var tween = create_tween().set_parallel(true)
	tween.tween_property(door_sprite_ref, "position:x", door_sprite_ref.position.x + 120, 0.45).set_ease(Tween.EASE_IN)
	tween.tween_property(door_sprite_ref, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	# [F] Entrar y flecha desaparecen
	if door_f_label_ref:
		create_tween().tween_property(door_f_label_ref, "modulate:a", 0.0, 0.3)
	if door_arrow_ref:
		create_tween().tween_property(door_arrow_ref, "modulate:a", 0.0, 0.3)

func _on_volver_pressed():
	get_tree().change_scene_to_file("res://Interfaces/main_menu.tscn")
