shader_type canvas_item;
// Painted-sprite shading (original): keeps full colour, adds a moonlit rim on the
// lit edges, a gentle stage tint so characters sit in the scene, and the white hit flash.
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 rim_color : source_color = vec4(0.72, 0.86, 1.0, 1.0);
uniform float rim_amt = 0.45;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float lift = 0.0;
// Phase 1 rim outline (0 = off, the default, so enemies/props are unchanged)
uniform float outline_width = 0.0;
uniform vec4 outline_color : source_color = vec4(0.55, 0.8, 1.0, 0.85);
void fragment() {
	vec4 t = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * 2.0;
	float above = texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	float left = texture(TEXTURE, UV - vec2(px.x, 0.0)).a;
	float right = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	float rim = clamp((1.0 - above) + (1.0 - min(left, right)) * 0.6, 0.0, 1.0) * smoothstep(0.4, 0.9, t.a);
	vec3 col = t.rgb * tint.rgb + vec3(lift);
	col = mix(col, rim_color.rgb, rim * rim_amt);
	col = mix(col, vec3(1.0), flash);
	vec4 outc = vec4(col, t.a);
	if (outline_width > 0.0 && t.a < 0.5) {
		vec2 o = TEXTURE_PIXEL_SIZE * outline_width;
		float n = max(max(texture(TEXTURE, UV + vec2(o.x, 0.0)).a, texture(TEXTURE, UV - vec2(o.x, 0.0)).a),
			max(texture(TEXTURE, UV + vec2(0.0, o.y)).a, texture(TEXTURE, UV - vec2(0.0, o.y)).a));
		n = max(n, max(texture(TEXTURE, UV + o).a, texture(TEXTURE, UV - o).a));
		float a = smoothstep(0.2, 0.7, n) * outline_color.a;
		vec3 oc = mix(outline_color.rgb, vec3(1.0), flash);
		outc = vec4(mix(oc, col, t.a), max(t.a, a));
	}
	COLOR = outc * COLOR;
}
