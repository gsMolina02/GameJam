# 🔧 CORRECCIÓN: Error "Cannot call method 'set_input_as_handled' on a null value"

## ❌ **ERROR:**

Al presionar "Sí" en la pantalla de muerte, el juego se cierra con error:

```
Cannot call method 'set_input_as_handled' on a null value.
death_escene.gd:53 @ _unhandled_input()
```

---

## 🔍 **CAUSA DEL PROBLEMA:**

### **Problema 1: `get_viewport()` devuelve null**

Cuando presionas "Sí" para reiniciar:
1. Se llama `queue_free()` → El nodo se marca para eliminación
2. El nodo se elimina del árbol de escena
3. Pero `_unhandled_input()` todavía puede recibir eventos
4. `get_viewport()` devuelve `null` porque el nodo ya no está en el árbol
5. Intentar llamar `null.set_input_as_handled()` → ❌ ERROR

### **Problema 2: Timing de cambio de escena**

El código hacía:
```gdscript
queue_free()  # Elimina el nodo
get_tree().reload_current_scene()  # Inmediatamente recarga
```

Si hay inputs pendientes entre estas dos líneas, causaba el error.

---

## ✅ **SOLUCIÓN APLICADA:**

### **Cambio 1: Verificaciones de Seguridad en _unhandled_input()**

**ANTES:**
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    
    # ...código...
    get_viewport().set_input_as_handled()  # ❌ Puede ser null
```

**AHORA:**
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    # Verificar visibilidad Y que esté en el árbol
    if not visible or not is_inside_tree():
        return
    
    # Verificar que el viewport existe
    var viewport = get_viewport()
    if not viewport:
        return
    
    # ...código...
    viewport.set_input_as_handled()  # ✅ Seguro
```

**Protecciones agregadas:**
1. ✅ `is_inside_tree()` - Verifica que el nodo esté en el árbol de escena
2. ✅ `get_viewport()` guardado en variable y verificado antes de usar
3. ✅ Retorno temprano si algo es null

---

### **Cambio 2: Uso de call_deferred para Cambio de Escena**

**ANTES:**
```gdscript
func _on_yes_pressed() -> void:
    get_tree().paused = false
    queue_free()  # Elimina el nodo
    get_tree().reload_current_scene()  # Inmediatamente recarga
```

**AHORA:**
```gdscript
func _on_yes_pressed() -> void:
    if not is_inside_tree():  # ✅ Verificación de seguridad
        return
    
    get_tree().paused = false
    # Usar call_deferred para evitar problemas durante input
    get_tree().call_deferred("reload_current_scene")  # ✅ Espera al frame siguiente
    queue_free()
```

**Ventajas de `call_deferred`:**
- ⏱️ Espera al siguiente frame para cambiar la escena
- ✅ Permite que el procesamiento de input actual termine
- ✅ Evita conflictos con nodos que se están eliminando

---

### **Cambio 3: Mismo Fix para _on_no_pressed()**

```gdscript
func _on_no_pressed() -> void:
    if not is_inside_tree():  # ✅ Verificación de seguridad
        return
    
    get_tree().paused = false
    get_tree().call_deferred("change_scene_to_file", "res://Interfaces/main_menu.tscn")
    queue_free()
```

---

## 🎯 **FLUJO CORRECTO AHORA:**

### **Cuando presionas "Sí" (Reiniciar):**

1. Usuario presiona "Sí"
2. `_on_yes_pressed()` se ejecuta:
   - ✅ Verifica que esté en el árbol
   - ✅ Despausa el juego
   - ✅ Programa el reload para el siguiente frame
   - ✅ Marca el nodo para eliminación
3. Frame actual termina de procesar
4. Nodo se elimina
5. Siguiente frame: Escena se recarga ✅

### **Si llega input después de eliminar:**

1. Input llega a `_unhandled_input()`
2. ✅ `is_inside_tree()` devuelve `false`
3. ✅ Función retorna inmediatamente
4. ✅ No hay error

---

## ✅ **RESULTADO:**

### **ANTES:**
- Presionar "Sí" → ❌ Error y cierre del juego
- `get_viewport()` devolvía `null` → ❌ Crash

### **AHORA:**
- Presionar "Sí" → ✅ Reinicia correctamente
- Presionar "No" → ✅ Vuelve al menú principal
- Sin errores de null → ✅ Estable

---

## 🧪 **PRUEBA LA CORRECCIÓN:**

1. Abre Godot
2. Ejecuta el juego (F6)
3. Deja que el personaje muera
4. En la pantalla de muerte:
   - **Presiona "Sí"** → ✅ Debe reiniciar sin error
   - **Presiona "No"** → ✅ Debe volver al menú sin error
5. **NO** debe haber mensajes de error en la consola

---

## 📝 **ARCHIVOS MODIFICADOS:**

- ✅ `Scenes/UI/death_escene.gd`
  - Agregadas verificaciones de seguridad
  - Cambiado a `call_deferred()` para cambios de escena
  - Protección contra null en `get_viewport()`

---

**¡PROBLEMA RESUELTO!** 🎉

El juego ahora maneja correctamente el reinicio desde la pantalla de muerte sin errores.
