# 🔧 CORRECCIÓN: Problema del Dash con Espacio

## ❌ **PROBLEMA:**

Al presionar **ESPACIO** para hacer dash, el juego se **reiniciaba** en lugar de ejecutar el dash.

---

## 🔍 **CAUSA DEL PROBLEMA:**

### **1. Menú de Muerte Capturando Input**

El archivo `Scenes/UI/death_escene.gd` estaba capturando TODOS los inputs, incluso cuando el menú NO era visible.

**Código problemático:**
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    # NO había verificación de visibilidad
    if event.is_action_pressed("ui_accept"):  # ESPACIO activa ui_accept
        _press_selected_button()  # Reinicia el juego
```

Godot por defecto mapea **ESPACIO** a la acción `ui_accept`, entonces:
- Presionas ESPACIO → Se activa `ui_accept`
- El menú de muerte (aunque invisible) detecta el input
- Llama a `_press_selected_button()` → Reinicia el juego

### **2. Fallback a KEY_SPACE**

El código del personaje tenía un fallback que usaba `is_key_pressed(KEY_SPACE)` en lugar de `is_action_just_pressed("ui_shift")`, lo que causaba conflictos.

---

## ✅ **SOLUCIÓN APLICADA:**

### **Cambio 1: death_escene.gd**

**Agregada verificación de visibilidad:**
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    # NO procesar input si el menú no es visible
    if not visible:
        return
    
    # Resto del código...
```

**También cambiado:**
```gdscript
- event.accept()  # Método incorrecto
+ get_viewport().set_input_as_handled()  # Método correcto en Godot 4
```

### **Cambio 2: personaje_principal.gd**

**Eliminado el fallback problemático:**
```gdscript
# ANTES:
var shift_pressed := false
if InputMap.has_action("ui_shift"):
    shift_pressed = Input.is_action_just_pressed("ui_shift")
else:
    # Fallback problemático
    shift_pressed = Input.is_key_pressed(KEY_SPACE) and not Input.is_action_pressed("attack")

# AHORA:
var shift_pressed := false
if InputMap.has_action("ui_shift"):
    shift_pressed = Input.is_action_just_pressed("ui_shift")
# Sin fallback - ui_shift ya está mapeado a ESPACIO en project.godot
```

---

## 🎮 **CONFIGURACIÓN ACTUAL:**

En `project.godot`:
```gdscript
ui_shift={
    "events": [Object(InputEventKey, physical_keycode=32)]  # 32 = ESPACIO
}
```

**ESPACIO** está correctamente mapeado a `ui_shift` para el dash.

---

## ✅ **RESULTADO:**

### **ANTES:**
- Presionar ESPACIO → ❌ Reiniciaba el juego

### **AHORA:**
- Presionar ESPACIO → ✅ Ejecuta el dash
- El menú de muerte SOLO captura input cuando es visible
- No hay conflictos entre acciones

---

## 🎯 **PRUEBA LA CORRECCIÓN:**

1. Abre Godot
2. Ejecuta el juego (F6)
3. Presiona **ESPACIO** mientras te mueves
4. ✅ Deberías hacer un dash en la dirección del movimiento
5. ❌ El juego NO debe reiniciarse

---

## 📝 **MECÁNICA DEL DASH:**

**Cómo funciona ahora:**
- **Tecla:** ESPACIO (mapeado a `ui_shift`)
- **Comportamiento:**
  - Si te estás moviendo (WASD): Dash en esa dirección
  - Si estás quieto: Dash hacia donde mira el personaje
- **Cooldown:** Tiene un tiempo de recarga entre dashes

---

**¡PROBLEMA RESUELTO!** 🎉

Ejecuta el juego y prueba el dash con ESPACIO.
