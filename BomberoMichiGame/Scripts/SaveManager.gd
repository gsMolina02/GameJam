extends Node

# Ruta del archivo de guardado (funciona tanto en editor como en el .exe exportado)
const SAVE_PATH = "user://savegame.json"

# ─────────────────────────────────────────
#  GUARDAR
# ─────────────────────────────────────────
func save_game(scene_path: String, jugador: Node) -> void:
	var data := {
		"scene_path":     scene_path,
		"vida_actual":    jugador.vida_actual    if "vida_actual"    in jugador else 100.0,
		"vida_maxima":    jugador.vida_maxima    if "vida_maxima"    in jugador else 100.0,
		"hose_charge":    jugador.hose_charge    if "hose_charge"    in jugador else 100.0,
		"hose_drain_rate":jugador.hose_drain_rate if "hose_drain_rate" in jugador else 4.0,
		"pos_x":          jugador.global_position.x if "global_position" in jugador else 0.0,
		"pos_y":          jugador.global_position.y if "global_position" in jugador else 0.0,
		"nodos_destruidos": GameManager.nodos_destruidos
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("💾 Partida guardada → escena:", scene_path)
	else:
		push_error("❌ SaveManager: No se pudo escribir el archivo de guardado.")

# ─────────────────────────────────────────
#  CARGAR
# ─────────────────────────────────────────
func load_game() -> Dictionary:
	if not has_save():
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("❌ SaveManager: No se pudo leer el archivo de guardado.")
		return {}

	var text := file.get_as_text()
	file.close()

	var result = JSON.parse_string(text)
	if result is Dictionary:
		print("📂 Partida cargada:", result)
		return result

	push_error("❌ SaveManager: El archivo de guardado está corrupto.")
	return {}

# ─────────────────────────────────────────
#  UTILIDADES
# ─────────────────────────────────────────
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		print("🗑️ Guardado eliminado")
