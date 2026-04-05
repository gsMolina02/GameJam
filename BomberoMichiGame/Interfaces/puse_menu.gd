extends Control

@onready var lbl_title    = $CenterContainer/PausePanel/VBoxContainer/LblTitle
@onready var btn_continue = $CenterContainer/PausePanel/VBoxContainer/btnContinue
@onready var btn_exit     = $CenterContainer/PausePanel/VBoxContainer/btnExit

var btn_save_exit: Button = null  # Creado programáticamente

# ─── Localización ────────────────────────────────────────────────────────────
func _t(key: String) -> String:
	if has_node("/root/Localization"):
		return get_node("/root/Localization").translate(key)
	return key

# ─── Estilizado de botones ────────────────────────────────────────────────────
func _style_button(btn: Button, col_normal: Color, col_hover: Color, font_col: Color) -> void:
	"""Aplica StyleBoxFlat a un Button para que combine con el estilo del juego."""
	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color             = col_normal
	s_normal.border_color         = col_normal.lightened(0.2)
	s_normal.border_width_left    = 2
	s_normal.border_width_right   = 2
	s_normal.border_width_top     = 2
	s_normal.border_width_bottom  = 2
	s_normal.corner_radius_top_left     = 6
	s_normal.corner_radius_top_right    = 6
	s_normal.corner_radius_bottom_left  = 6
	s_normal.corner_radius_bottom_right = 6
	s_normal.content_margin_left   = 20
	s_normal.content_margin_right  = 20
	s_normal.content_margin_top    = 8
	s_normal.content_margin_bottom = 8

	var s_hover := StyleBoxFlat.new()
	s_hover.bg_color             = col_hover
	s_hover.border_color         = Color.WHITE
	s_hover.border_width_left    = 2
	s_hover.border_width_right   = 2
	s_hover.border_width_top     = 2
	s_hover.border_width_bottom  = 2
	s_hover.corner_radius_top_left     = 6
	s_hover.corner_radius_top_right    = 6
	s_hover.corner_radius_bottom_left  = 6
	s_hover.corner_radius_bottom_right = 6
	s_hover.content_margin_left   = 20
	s_hover.content_margin_right  = 20
	s_hover.content_margin_top    = 8
	s_hover.content_margin_bottom = 8

	btn.add_theme_stylebox_override("normal",  s_normal)
	btn.add_theme_stylebox_override("hover",   s_hover)
	btn.add_theme_stylebox_override("pressed", s_hover)
	btn.add_theme_stylebox_override("focus",   StyleBoxFlat.new())
	btn.add_theme_color_override("font_color",         font_col)
	btn.add_theme_color_override("font_hover_color",   Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 18)


# ─── Inicialización ───────────────────────────────────────────────────────────
func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("localizable")
	add_to_group("pause_menu_ui")  # Para que _toggle_pause_menu() lo encuentre por grupo

	# Asegurar que el CanvasLayer padre procese durante la pausa
	var parent = get_parent()
	if parent and parent is CanvasLayer:
		parent.process_mode = Node.PROCESS_MODE_ALWAYS
		if parent.layer < 30:
			parent.layer = 30

	# ── Panel central: fondo carbón con borde naranja fuego ───────────────────
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color          = Color(0.06, 0.03, 0.01, 0.97)  # Carbón oscuro
	panel_style.border_color      = Color(0.97, 0.45, 0.05, 1.0)   # Naranja fuego
	panel_style.border_width_left   = 3
	panel_style.border_width_right  = 3
	panel_style.border_width_top    = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left     = 14
	panel_style.corner_radius_top_right    = 14
	panel_style.corner_radius_bottom_left  = 14
	panel_style.corner_radius_bottom_right = 14
	panel_style.content_margin_left   = 32
	panel_style.content_margin_right  = 32
	panel_style.content_margin_top    = 28
	panel_style.content_margin_bottom = 28
	$CenterContainer/PausePanel.add_theme_stylebox_override("panel", panel_style)

	# ── Título: naranja fuego, grande ─────────────────────────────────────────
	lbl_title.add_theme_color_override("font_color", Color(0.97, 0.45, 0.05))
	lbl_title.add_theme_font_size_override("font_size", 38)

	# ── Separador: naranja difuso ─────────────────────────────────────────────
	var sep = $CenterContainer/PausePanel/VBoxContainer/HSeparator
	if sep:
		sep.add_theme_color_override("color", Color(0.97, 0.45, 0.05, 0.5))

	# ── Crear botón "Guardar y Salir" entre Continuar y Salir ─────────────────
	btn_save_exit = Button.new()
	btn_save_exit.name = "btnSaveExit"
	btn_save_exit.custom_minimum_size = Vector2(0, 52)

	var vbox = $CenterContainer/PausePanel/VBoxContainer
	vbox.add_child(btn_save_exit)
	# Orden en VBox: LblTitle(0), HSep(1), Continue(2), Exit(3), SaveExit(4 tras add)
	# Mover SaveExit a pos 3 → Title(0), Sep(1), Cont(2), SaveExit(3), Exit(4)
	vbox.move_child(btn_save_exit, 3)

	btn_save_exit.pressed.connect(_on_btn_save_exit_pressed)

	# ── Estilos de botones ────────────────────────────────────────────────────
	# Continuar: azul acerado (igual a botones del menú principal)
	_style_button(btn_continue,  Color(0.23, 0.43, 0.52), Color(0.36, 0.57, 0.67), Color(0.95, 0.95, 0.95))
	# Guardar y Salir: ámbar/cobre
	_style_button(btn_save_exit, Color(0.42, 0.25, 0.03), Color(0.60, 0.38, 0.06), Color(1.0,  0.88, 0.60))
	# Salir al Menú: gris neutro oscuro
	_style_button(btn_exit,      Color(0.16, 0.16, 0.16), Color(0.28, 0.28, 0.28), Color(0.75, 0.75, 0.75))

	update_texts()

# ─── Textos localizados ───────────────────────────────────────────────────────
func update_texts() -> void:
	if lbl_title:     lbl_title.text      = _t("pause.title")
	if btn_continue:  btn_continue.text   = _t("pause.continue")
	if btn_save_exit: btn_save_exit.text  = _t("pause.save_exit")
	if btn_exit:      btn_exit.text       = _t("pause.exit_menu")

# ─── Toggle pausa ─────────────────────────────────────────────────────────────
func toggle_pause() -> void:
	var is_paused := not get_tree().paused
	get_tree().paused = is_paused
	visible = is_paused

	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	var parent = get_parent()
	if parent and parent.name == "MenusLayer":
		parent.visible = is_paused
		if is_paused:
			var death_menu = parent.get_node_or_null("DeathMenu")
			if death_menu:
				death_menu.visible = false

# ─── Botón: Continuar ─────────────────────────────────────────────────────────
func _on_btn_continue_pressed() -> void:
	toggle_pause()

# ─── Botón: Guardar y Salir ───────────────────────────────────────────────────
func _on_btn_save_exit_pressed() -> void:
	var players = get_tree().get_nodes_in_group("player_main")
	var scene_path = get_tree().current_scene.scene_file_path

	if players.size() > 0:
		var jugador = players[0]
		GameManager.guardar_estado_jugador(jugador)
		SaveManager.save_game(scene_path, jugador)
		print("💾 Guardado manual → escena:", scene_path)
	else:
		push_warning("⚠️ No se encontró jugador para guardar")

	get_tree().paused = false
	var parent = get_parent()
	if parent and parent.name == "MenusLayer":
		parent.visible = false
	get_tree().change_scene_to_file("res://Interfaces/main_menu.tscn")

# ─── Botón: Salir al Menú (sin guardar) ──────────────────────────────────────
func _on_btn_exit_pressed() -> void:
	get_tree().paused = false
	var parent = get_parent()
	if parent and parent.name == "MenusLayer":
		parent.visible = false
	get_tree().change_scene_to_file("res://Interfaces/main_menu.tscn")
