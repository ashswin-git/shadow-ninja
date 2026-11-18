shader_type canvas_item;
// Original NA2-style silhouette: body goes ink-black, only glowing/saturated accents survive,
// plus a cool rim light along top edges. `flash` drives the white hit flash.
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 rim_color : source_color = vec4(0.72, 0.86, 1.0, 1.0);
uniform float keep_sat = 0.55;
uniform float alpha_cut = 0.0;
void fragment() {
	vec4 t = texture(TEXTURE, UV);
	float mx = max(t.r, max(t.g, t.b));
	float mn = min(t.r, min(t.g, t.b));
	float sat = mx > 0.001 ? (mx - mn) / mx : 0.0;
	float keep = smoothstep(keep_sat, keep_sat + 0.2, sat) * smoothstep(0.45, 0.75, mx);
	float above = texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y * 2.0)).a;
	float side = texture(TEXTURE, UV - vec2(TEXTURE_PIXEL_SIZE.x * 2.0, 0.0)).a;
	float rim = clamp((1.0 - above) + (1.0 - side) * 0.5, 0.0, 1.0) * step(0.5, t.a);
	vec3 col = mix(vec3(0.015, 0.015, 0.025), t.rgb, keep);
	col = mix(col, rim_color.rgb, rim * 0.55 * (1.0 - keep));
	col = mix(col, vec3(1.0), flash);
	COLOR = vec4(col, alpha_cut > 0.0 ? step(alpha_cut, t.a) : t.a);
}
