shader_type canvas_item;

// Aquí está el cambio: usamos hint_screen_texture
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float intensidad : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    // Capturamos el mundo usando la nueva variable
    vec4 color_original = texture(screen_tex, SCREEN_UV);

    // Calculamos el gris (Luminancia)
    float luminancia = dot(color_original.rgb, vec3(0.299, 0.587, 0.114));
    vec3 color_gris = vec3(luminancia);

    // Mezclamos: intensidad 0 = color real, intensidad 1 = gris
vec3 color_final = mix(color_original.rgb, color_gris * 0.8, intensidad);
    COLOR = vec4(color_final, color_original.a);
}