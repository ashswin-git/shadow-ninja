shader_type canvas_item;
// Phase 4 ink-wipe transition: a brushy ink edge sweeps left -> right.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float n(vec2 p) {
	vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y);
}
void fragment() {
	float edge = UV.x + (n(vec2(UV.y * 9.0, 1.3)) - 0.5) * 0.18 + (n(UV * 40.0) - 0.5) * 0.04;
	float a = smoothstep(edge - 0.02, edge + 0.02, progress * 1.3 - 0.1);
	COLOR = vec4(COLOR.rgb, a);
}
