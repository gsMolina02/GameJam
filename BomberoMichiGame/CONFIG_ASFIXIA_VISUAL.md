# ✅ CONFIGURACIÓN FINAL DEL EFECTO DE ASFIXIA

## PASO 1: Configurar los Layer (Orden de Dibujo)

### Para el nodo AsphyxiaEffect:
1. Abre tu escena (ej: level1.tscn)
2. En el árbol, busca **AsphyxiaEffect** (CanvasLayer)
3. Selecciónalo
4. En el **Inspector**, busca la propiedad **Layer**
5. Cámbiala de `0` a `10`

✅ **Layer 10** = Se dibuja encima del juego, debajo del HUD

---

### Para el nodo HUD:
1. En el árbol, busca **HUD** (CanvasLayer)
2. Selecciónalo
3. En el **Inspector**, busca la propiedad **Layer**
4. Cámbiala de `1` a `20`

✅ **Layer 20** = Se dibuja encima de TODO (incluyendo la asfixia)

---

### Resultado esperado de Layer:
```
Layer 0:  Juego, enemigos, personaje
Layer 10: Overlay de asfixia (gris y humo)
Layer 20: HUD con barras de oxígeno y agua
```

---

## PASO 2: Configurar los Colores de los Overlays

### Para el nodo GrisOverlay:
1. Expand **AsphyxiaEffect** en el árbol (clic en la flecha)
2. Selecciona **GrisOverlay** (ColorRect)
3. En el **Inspector**, busca **Modulate** (en la sección de Control)
4. Clic en el color → Asegúrate de que sea **BLANCO** (#FFFFFF)
5. Alpha (A) debe ser **255** (100%)
6. Busca **Color** (propiedades del ColorRect)
7. Cámbialo a **BLANCO** (#FFFFFF) también

✅ **Blanco puro** = El modulate.a lo hará gris al cambiar la transparencia

---

### Para el nodo AsFixiaOverlay:
1. Selecciona **AsFixiaOverlay** (Control o ColorRect)
2. Haz los mismos cambios que con GrisOverlay:
   - **Modulate**: Blanco (#FFFFFF)
   - **Color**: Blanco (#FFFFFF)

✅ **Ambos blancos** = Mejor control de transparencia

---

## PASO 3: Verificar el Script

El script ya está actualizado con:
```gdscript
asphyxia_overlay.visible = (intensidad > 0.01)
gris_overlay.visible = (intensidad > 0.01)
```

¿Por qué `0.01` en lugar de `0.0`?
- Evita parpadeos
- Activa la visibilidad apenas hay un poco de intensidad

---

## PRUEBA FINAL

Cuando termines la configuración:
1. Guarda la escena (Ctrl+S)
2. Abre la consola (F8)
3. Ejecuta el juego (F5)
4. Baja el oxígeno hasta 30% (ej: espera a que los enemigos te peguen)
5. Deberías ver cómo la pantalla se oscurece gradualmente

---

## ✨ Resultado Esperado

| Oxígeno | Efecto |
|---------|--------|
| 100%    | Nada (transparente) |
| 50%     | Nada (transparente) |
| 30%     | Comienza a oscurecerse |
| 20%     | Más oscuro + TEMBLOR LEVE |
| 10%     | Muy oscuro + TEMBLOR FUERTE |
| 0%      | PANTALLA GRIS COMPLETA + TEMBLOR MÁXIMO |

---

## 🔧 Si NO ves el efecto:

**Checklist de depuración:**
- [ ] AsphyxiaEffect tiene Layer = 10
- [ ] HUD tiene Layer = 20
- [ ] GrisOverlay es ColorRect (no Node2D)
- [ ] GrisOverlay tiene Modulate = Blanco
- [ ] GrisOverlay tiene Color = Blanco
- [ ] AsFixiaOverlay también tiene todo blanco
- [ ] El script tiene `.visible = (intensidad > 0.01)`
- [ ] Guardaste los cambios (Ctrl+S)
- [ ] Recargaste la escena (F5)

Si aún no funciona, abre la consola (F8) y busca estos mensajes:
- `HUD: AsphyxiaEffect encontrado` (si no aparece, el nodo no se encontró)
- No debería haber errores en rojo

---

¡Listo! Con esto debería funcionar perfectamente. ¿Lo configuraste todo? 🎮✨
