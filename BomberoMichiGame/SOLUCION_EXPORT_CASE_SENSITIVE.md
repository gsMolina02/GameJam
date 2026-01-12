# 🔧 SOLUCIÓN: Error de exportación - Rutas case-sensitive

## ❌ Problema Encontrado

El juego exportado no funcionaba (teclas no respondían) y mostraba este error crítico:

```
SCRIPT ERROR: Parse Error: Preload file "res://Assets/objetos/apuntador.tscn" does not exist.
          at: GDScript::reload (res://personajes/personaje_principal/personaje_principal.gd:126)
ERROR: Failed to load script "res://personajes/personaje_principal/personaje_principal.gd" with error "Parse error".
```

### 🎯 Causa Raíz

**Windows es case-insensitive, pero el juego exportado es case-sensitive.**

En el editor de Godot (Windows):
- ✅ `res://Assets/objetos/apuntador.tscn` funciona
- ✅ `res://Assets/Objetos/apuntador.tscn` funciona (ambas rutas son iguales)

En el juego exportado (.exe):
- ❌ `res://Assets/objetos/apuntador.tscn` NO EXISTE
- ✅ `res://Assets/Objetos/apuntador.tscn` SÍ EXISTE (carpeta real: `Objetos` con O mayúscula)

## ✅ Archivos Corregidos

### 1. `personajes/personaje_principal/personaje_principal.gd` (línea 126)
**Antes:**
```gdscript
var apuntador_scene = preload("res://Assets/objetos/apuntador.tscn")
```

**Después:**
```gdscript
var apuntador_scene = preload("res://Assets/Objetos/apuntador.tscn")
```

### 2. `Assets/Objetos/apuntador.tscn` (línea 2)
**Antes:**
```gdscript
[ext_resource type="Texture2D" path="res://Assets/objetos/apuntador.png" id="1_apuntador"]
```

**Después:**
```gdscript
[ext_resource type="Texture2D" path="res://Assets/Objetos/apuntador.png" id="1_apuntador"]
```

## 📋 Estructura Correcta de Assets/

```
Assets/
├── Objetos/              ← O mayúscula (IMPORTANTE)
│   ├── apuntador.tscn
│   ├── apuntador.png
│   └── ...
├── minions/              ← m minúscula (correcto)
├── musica/               ← m minúscula (correcto)
├── Animación_fuego/      ← A mayúscula
└── ...
```

## 🚀 Próximos Pasos para Exportar

1. **Guarda todos los cambios en Godot**
2. **Limpia la caché:**
   - Cierra Godot
   - Borra la carpeta `.godot` en el proyecto
   - Abre Godot nuevamente (regenerará la caché)

3. **Exporta nuevamente:**
   - Menú: `Project > Export...`
   - Selecciona **Windows Desktop**
   - Verifica que `binary_format/embed_pck` esté en **true**
   - Click en **Export Project**
   - Guarda como `SOFOCADO.exe`

4. **Prueba el ejecutable:**
   - Ejecuta `SOFOCADO.exe`
   - Verifica que el personaje responda a las teclas
   - ✅ No debería mostrar el error de parse

## ⚠️ Advertencias de la Consola (NORMALES)

Estos mensajes son normales y no afectan el juego:

```
WARNING: Your video card drivers seem not to support Vulkan, switching to Direct3D 12.
D3D12 12_0 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce GTX 1660 Ti
WARNING: PSO caching is not implemented yet in the Direct3D 12 driver.
```

Estos otros warnings son esperados:
```
ERROR: Nonexistent signal: 'vida_actualizada'.
⚠ El jugador no tiene la señal weapon_switched
```

**Lo importante:** Ya no debería aparecer el error de parse del apuntador.

## 🎮 Resultado Esperado

Después de la corrección:
- ✅ El personaje principal se carga correctamente
- ✅ Las teclas funcionan (WASD, ESPACIO, click)
- ✅ El cursor personalizado (apuntador) aparece
- ✅ El juego es totalmente jugable

## 📝 Lección Aprendida

**Siempre usa las mayúsculas/minúsculas exactas de los nombres de carpeta en las rutas `res://`**

Godot en Windows perdona estos errores en el editor, pero el juego exportado NO.

---
**Fecha:** 20 de octubre de 2025  
**Corrección aplicada para:** Exportación a itch.io
