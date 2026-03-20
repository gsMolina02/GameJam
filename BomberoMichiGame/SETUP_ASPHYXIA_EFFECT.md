# Configuración del Efecto de Asfixia (Asphyxia Effect)

## Pasos para implementar el efecto de asfixia:

### 1. Estructura de la Escena
Asegúrate de que tu escena tenga esta estructura:

```
Escena Principal (ej: level1.tscn)
├── HUD (CanvasLayer)
│   ├── RootControl
│   │   ├── OxigenoBar (ProgressBar)
│   │   └── AguaBar (ProgressBar)
├── AsphyxiaEffect (CanvasLayer) ← NUEVO NODO
│   ├── AsFixiaOverlay (Control o ColorRect)
│   └── GrisOverlay (Control o ColorRect)
├── Personaje y otros nodos...
```

### 2. Crear el nodo AsphyxiaEffect

1. **En tu escena principal (level1.tscn o similar):**
   - Añade un nuevo nodo de tipo `CanvasLayer`
   - Renómbralo como `AsphyxiaEffect`
   - Asígale el script: `res://Scripts/asphyxia_effect.gd`
   - Cambia el `layer` a `1` (para que esté encima del juego pero debajo del HUD)

### 3. Crear los Overlays

**Dentro de AsphyxiaEffect, crea dos nodos:**

#### A) AsFixiaOverlay (overlay de humo)
1. Añade un nodo `Control` como hijo de `AsphyxiaEffect`
2. Renómbralo: `AsFixiaOverlay`
3. En sus propiedades:
   - **Anchors Preset:** Full Rect (para que cubra toda la pantalla)
   - **Modulate Alpha:** 0.0 (inicialmente invisible)
4. Configura su apariencia:
   - Opción A: Agrégale una textura de humo (si la tienes)
   - Opción B: Usa un `ColorRect` dentro con color gris oscuro translúcido

#### B) GrisOverlay (capa gris)
1. Añade otro nodo `ColorRect` como hijo de `AsphyxiaEffect`
2. Renómbralo: `GrisOverlay`
3. En sus propiedades:
   - **Anchors Preset:** Full Rect (para que cubra toda la pantalla)
   - **Color:** Color.gray (ej: #888888)
   - **Modulate Alpha:** 0.0 (inicialmente invisible)

### 4. Configuración de Parámetros (Opcional)

En el nodo `AsphyxiaEffect`, en el Inspector:
- **Oxygen Threshold Start:** 30.0 (a qué % de oxígeno comienza el efecto)
- **Max Intensidad:** 1.0 (intensidad máxima del efecto, puede ser 0.5-1.0)
- **Shake Intensity:** 2.0 (intensidad del temblor de la cámara, rango: 1.0-5.0)
- **Shake Threshold:** 20.0 (a qué % de oxígeno comienza el temblor)

### 5. Comportamiento del Efecto

El efecto se comportará así:

```
Oxígeno 100% → Sin efecto (transparente)
Oxígeno 50%  → Sin efecto (transparente)
Oxígeno 30%  → Comienza a oscurecerse (intensidad = 0%)
Oxígeno 20%  → Más oscuro (intensidad = 33%) + COMIENZA EL SHAKE
Oxígeno 10%  → Muy oscuro (intensidad = 66%) + SHAKE INTENSO
Oxígeno 0%   → Pantalla completamente gris (intensidad = 100%) + SHAKE MÁXIMO
```

### 5.1 Efecto de Shake (Temblor)

Cuando el oxígeno baja del 20%, la pantalla comienza a temblar levemente, simulando:
- ❤️ Latidos del corazón acelerados
- 😰 Desesperación del gato
- 🌊 Falta de aire

El temblor se intensifica conforme baja más el oxígeno, siendo dramático a 0%.

**Parámetros del Shake:**
- `shake_intensity`: Magnitud del temblor (2.0 = moderado, 1.0 = suave, 5.0 = agresivo)
- `shake_threshold`: A qué % comienza (20.0 por defecto)

### 6. Personalización Avanzada

Si quieres un efecto más dramático, puedes modificar `asphyxia_effect.gd`:

**Cambiar el umbral:**
```gdscript
@export var oxygen_threshold_start = 50.0  # Comienza a 50% en lugar de 30%
```

**Hacer el efecto más suave:**
```gdscript
intensidad = clamp(intensidad * 0.5, 0.0, max_intensidad)  # Mitad menos intenso
```

**Aumentar intensidad del shake:**
```gdscript
@export var shake_intensity = 5.0  # Temblor más agresivo (default: 2.0)
```

**Cambiar cuándo comienza el shake:**
```gdscript
@export var shake_threshold = 10.0  # Comienza a 10% en lugar de 20%
```

**Hacer el shake más suave:**
```gdscript
shake_amount = clamp(shake_amount, 0.0, 0.5)  # Máximo 50% de intensidad
```

### 7. Verificar que funciona

En la consola (F8) deberías ver mensajes como:
```
HUD: AsphyxiaEffect encontrado
...
AsphyxiaEffect - Oxígeno: 25% | Intensidad: 0.166
AsphyxiaEffect - Oxígeno: 15% | Intensidad: 0.5
💓 SHAKE ACTIVADO - Oxígeno: 20% | Intensidad Shake: 0.0
💓 SHAKE ACTIVADO - Oxígeno: 10% | Intensidad Shake: 0.5
💓 SHAKE ACTIVADO - Oxígeno: 0% | Intensidad Shake: 1.0
```

### ¡Listo! 🎉
El efecto de asfixia debería verse increíble ahora. A medida que baja el oxígeno:
1. **Hasta 30%**: Sin cambios visuales
2. **30% - 20%**: La pantalla comienza a oscurecerse (overlay gris)
3. **20% - 0%**: La pantalla tiembla cada vez más intensamente, simulando pánico
4. **0%**: Pantalla completamente gris + máximo temblor = Game Over visual

### 💡 Pro Tip
Puedes ajustar los parámetros en el Inspector mientras juegas en modo debug para encontrar el balance perfecto entre el efecto visual y la jugabilidad. Algunos valores recomendados:

**Para juego más lento/relajado:**
- `oxygen_threshold_start`: 50.0
- `shake_intensity`: 1.0
- `shake_threshold`: 15.0

**Para juego más intenso/desafiante:**
- `oxygen_threshold_start`: 20.0
- `shake_intensity`: 4.0
- `shake_threshold`: 10.0

¡Que disfrutes tu semifinal! 🎮✨
