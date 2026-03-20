shader_type canvas_item;

// --- CAPTURA DEL MUNDO (NECESARIO PARA EL GRIS) ---
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// --- TUS PARÁMETROS DE NUBES (LOS QUE TE GUSTAN) ---
// Aquí arrastrarás tu imagen "nubes sofocado.png"
uniform sampler2D textura_humo : repeat_enable, filter_linear;
uniform float intensidad : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color_humo : source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform vec2 velocidad = vec2(0.04, 0.01);

void fragment() {
    // 1. OBTENEMOS EL COLOR ORIGINAL DEL JUEGO
    vec4 pantalla = texture(screen_texture, SCREEN_UV);
    
    // 2. APLICAMOS EL EFECTO GRIS (Luminancia)
    // Calculamos el gris basándonos en el color original
    float luminancia = dot(pantalla.rgb, vec3(0.299, 0.587, 0.114));
    vec3 color_gris = vec3(luminancia);
    
    // Mezclamos el color original con el gris según la intensidad
    // (0 = color total, 1 = gris total)
    vec3 pantalla_gris = mix(pantalla.rgb, color_gris * 0.8, intensidad);

    // 3. APLICAMOS TU EFECTO DE NUBES (TU LÓGICA ORIGINAL)
    vec2 uv_movida = SCREEN_UV + (velocidad * TIME);
    float humo_valor = texture(textura_humo, uv_movida).r;
    
    // Mezclamos el resultado gris con el color del humo
    // Usamos 'clamp' y multiplicamos el humo para que sea denso
    vec3 final_rgb = mix(pantalla_gris, color_humo.rgb, clamp(humo_valor * intensidad * 2.0, 0.0, 1.0));
    
    // Mantenemos el alpha original de la pantalla
    COLOR = vec4(final_rgb, pantalla.a);
}