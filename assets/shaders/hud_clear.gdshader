shader_type canvas_item;
// Fades a parallax silhouette layer out behind the top-left HUD plate so the
// painted plate never sits on top of a tree (screen-space soft mask).
uniform vec2 clear_size = vec2(0.215, 0.165); // fraction of the screen (HUD block ~300x145 px)
uniform float soft = 0.2;
void fragment() {
	vec4 t = texture(TEXTURE, UV) * COLOR;
	vec2 d = max(SCREEN_UV - clear_size, vec2(0.0));
	float inside = 1.0 - smoothstep(0.0, soft, length(d / vec2(1.0, 0.5625)));
	t.a *= 1.0 - inside;
	COLOR = t;
}
