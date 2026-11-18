shader_type canvas_item;
// Polish pass: turns the flat white parallax silhouettes (mid / near) into shaded painted layers:
// moonlit rim on top edges, a soft vertical value ramp, brushy mottling, and (near only) the
// screen-space clear-out behind the top-left HUD block (from hud_clear.gdshader).
uniform vec4 rim_color : source_color = vec4(0.75, 0.85, 1.0, 0.8);
uniform float rim_px = 5.0;
uniform float top_lift = 1.45;     // value multiplier at the top of the texture
uniform float bottom_dim = 0.85;   // ... and at the bottom
uniform float mottle = 0.22;
uniform bool hud_clear = false;
uniform vec2 clear_size = vec2(0.215, 0.165);
uniform float soft = 0.2;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	float a = t.a;
	vec2 px = TEXTURE_PIXEL_SIZE;
	float up = texture(TEXTURE, UV - vec2(0.0, rim_px * px.y)).a;
	float up2 = texture(TEXTURE, UV - vec2(rim_px * 0.6 * px.x, rim_px * 0.6 * px.y)).a;
	float rim = clamp(a - min(up, up2), 0.0, 1.0);
	vec3 base = COLOR.rgb * mix(top_lift, bottom_dim, UV.y);
	float n = vnoise(UV * vec2(90.0, 26.0)) * 0.6 + vnoise(UV * vec2(260.0, 70.0)) * 0.4;
	base *= 1.0 - mottle * 0.5 + mottle * n;
	vec3 col = mix(base, rim_color.rgb, rim * rim_color.a);
	float alpha = a * COLOR.a;
	if (hud_clear) {
		vec2 d = max(SCREEN_UV - clear_size, vec2(0.0));
		float inside = 1.0 - smoothstep(0.0, soft, length(d / vec2(1.0, 0.5625)));
		alpha *= 1.0 - inside;
	}
	COLOR = vec4(col, alpha);
}
