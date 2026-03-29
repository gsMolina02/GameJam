# 🔊 Configuración de Sonidos de Asfixia y Recuperación

## ✅ Lo que he implementado:

He actualizado `Scripts/asphyxia_effect.gd` para agregar efectos de sonido automáticos:

### 1. **Sonido de Tos** (`Tos.wav`)
- ✅ Se reproduce **cada 2 segundos** mientras el efecto de asfixia esté activo
- ✅ Se activa cuando **la vida baja de 30%**
- ✅ Se detiene automáticamente cuando la vida vuelve a ser saludable

### 2. **Sonido de Recuperación** (`Tos_recover.wav`)
- ✅ Se reproduce automáticamente cuando **la pantalla vuelve a la normalidad**
- ✅ Reproductor sucinta cuando la salud vuelve a estar encima del 30%

---

## 📋 Cambios realizados:

### En `Scripts/asphyxia_effect.gd`:

1. **Se agregaron nuevas variables:**
   ```gdscript
   @export var cough_sound: AudioStream = preload("res://Assets/SFX/tos/Tos.wav")
   @export var cough_recover_sound: AudioStream = preload("res://Assets/SFX/tos/Tos_recover.wav")
   @export var cough_interval: float = 2.0  # Intervalo entre sonidos
   ```

2. **Se creó un AudioStreamPlayer automáticamente:**
   - En `_ready()` se instancia el reproductor de audio
   - Se asigna al bus "Master" para que respete el volumen general

3. **Se agregó control de estado:**
   - `is_asphyxia_active`: rastrea si el efecto está activo
   - `cough_timer`: controla el intervalo entre sonidos de tos

4. **Se detectan transiciones:**
   - Cuando **entra en asfixia**: suena la tos inmediatamente y cada 2 segundos
   - Cuando **sale de asfixia**: suena el sonido de recuperación

---

## 🎮 Cómo funciona en el juego:

1. **Personaje pierde oxígeno** (vida baja a 30% o menos)
   ↓
2. **Aparece el efecto gris** (visualmente)
3. **Suena "tos"** 🔊 (primer sonido)
4. **Cada 2 segundos suena "tos"** nuevamente 🔊

---

5. **Personaje recupera oxígeno** (vida sube más de 30%)
   ↓
6. **El efecto gris desaparece**
7. **Suena sonido de recuperación** 🔊

---

## 🔧 Parámetros personalizables:

En el editor de Godot, puedes modificar:

- **`oxygen_threshold_start`** (valor actual: 30.0)
  - Valor de oxígeno que activa el efecto
  
- **`cough_interval`** (valor actual: 2.0 segundos)
  - Tiempo entre cada sonido de tos

- **`cough_sound`** (actualmente: `Tos.wav`)
  - Sonido de tos durante la asfixia
  
- **`cough_recover_sound`** (actualmente: `Tos_recover.wav`)
  - Sonido cuando se recupera

Para cambiar estos valores:
1. Abre cualquier escena de nivel (ej: `Scenes/Levels/level1/level1.tscn`)
2. Selecciona el nodo `MundoGrisLayer` en el árbol
3. En el Inspector (derecha), modifica los valores de exportación

---

## ✨ Detalles técnicos:

- Los sonidos se reproducen a través de un `AudioStreamPlayer` creado automáticamente
- El reproductor está asignado al bus "Master" para respetar el volumen del juego
- Los archivos de sonido ya están en: `Assets/SFX/tos/`
  - `Tos.wav` (sonido de tos durante asfixia)
  - `Tos_recover.wav` (sonido de recuperación)
  - `recoverCough.wav` (alternativa disponible)

---

## 🧪 Cómo probar:

1. **En el editor:**
   - Abre un nivel (ej: `Scenes/Levels/level1/level1.tscn`)
   - Presiona Play (F5)

2. **Durante el juego:**
   - Busca fuego para que baje tu oxígeno
   - Cuando llegue a <30%, deberías escuchar la tos
   - Si te acercas a un tanque de oxígeno o el fuego se apaga, debería sonar la recuperación

3. **Debug:**
   - Abre la consola con F8 para ver mensajes:
     - `🔊 Sonido de tos reproducido`
     - `🔊 Sonido de recuperación reproducido`

---

## 📝 Archivos modificados:

- ✅ `Scripts/asphyxia_effect.gd` - Actualizado con sistema de audio

---

## 🎯 Próximos pasos (opcional):

Si deseas agregar sonidos para **otros personajes**:

1. **Para minions/enemigos:**
   - Podrías crear un script similar que emita sonidos cuando reciben daño

2. **Para el jefe:**
   - Agregar sonidos de ataque, daño, muerte

3. **Para el hacha del jugador:**
   - Sonidos de swing, golpe, parry

¡Contáctame si necesitas ayuda con eso!

---

## ⚙️ Solución de problemas:

### No se escuchan los sonidos:
1. Verifica que el volumen del juego esté activado
2. Abre la consola (F8) para ver si aparecen los mensajes `🔊 Sonido...`
3. Verifica que los archivos `Tos.wav` y `Tos_recover.wav` existan en `Assets/SFX/tos/`

### El sonido se escucha continuamente:
1. Reduce el valor de `cough_interval` en el inspector (probablemente está en 0)

### Error: "No se encontró el archivo":
1. Verifica las rutas en el script: `preload("res://Assets/SFX/tos/Tos.wav")`
2. La ruta debe ser relativa a la raíz del proyecto

---

¡Sistema de sonido de asfixia completamente implementado! 🎮🔊
