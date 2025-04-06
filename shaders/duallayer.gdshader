shader_type canvas_item;

uniform sampler2D normal_texture : hint_normal;
uniform float base_light_intensity = 0.5; // Adjust this to control base brightness

void fragment() {
    vec4 albedo = texture(TEXTURE, UV);
    vec3 normal = texture(normal_texture, UV).rgb * 2.0 - 1.0; // Convert normal map to -1 to 1 range

    vec2 light_pos = vec2(LIGHT_POSITION.x, LIGHT_POSITION.y); // Light position in screen space
    vec2 pixel_pos = SCREEN_UV * SCREEN_PIXEL_SIZE; // Current pixel position in screen space
    vec2 light_dir = normalize(light_pos - pixel_pos); // Direction from pixel to light

    float diffuse = max(dot(normal.xy, light_dir), 0.0); // Normal-based lighting
    float base_light = 1.0; // Simulate flat lighting

    float final_light = mix(base_light, diffuse, base_light_intensity);

    COLOR = albedo * (LIGHT_COLOR * LIGHT_ENERGY * final_light);
}
