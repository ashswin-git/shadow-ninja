#!/usr/bin/env python3
"""Phase 3: 32 px tile atlas for the hand-built TileMap stages, cut from the project's own
painted ground art (assets/env/*) and recoloured per act scenario, plus procedural roof
tiles and planks. Original art only. Row = scenario, columns:
0 top A, 1 top B, 2 fill A, 3 fill B, 4 one-way plank, 5 roof top, 6 roof fill, 7 edge-dark fill"""
import os, numpy as np
from PIL import Image, ImageDraw, ImageEnhance
R = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
T = 32
SCEN = [  # name, base env art, rgb multiply, plank colour
	("gion", "snow", (0.78, 0.84, 1.05), (92, 58, 40)),
	("bamboo", "forest", (1.0, 1.05, 0.95), (110, 84, 46)),
	("cave", "forest", (0.62, 0.8, 1.0), (70, 66, 70)),
	("shrine", "boss", (1.15, 0.9, 0.8), (120, 36, 30)),
	("canal", "forest", (0.8, 0.95, 1.0), (96, 70, 48)),
	("pagoda", "snow", (0.95, 1.05, 1.18), (84, 70, 76)),
	("palace", "boss", (0.75, 0.62, 1.0), (60, 30, 52)),
]
def tint(im, m):
	a = np.asarray(im.convert("RGBA")).astype(np.float32)
	a[..., :3] = np.clip(a[..., :3] * np.array(m), 0, 255)
	return Image.fromarray(a.astype(np.uint8), "RGBA")
def roof(top, base):
	im = Image.new("RGBA", (T, T), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
	c = tuple(int(v) for v in base)
	d.rectangle([0, 0, T, T], fill=c + (255,))
	for x in range(0, T, 8):   # rounded kawara tile ribs
		d.rectangle([x, 0, x + 5, T], fill=tuple(min(255, v + 18) for v in c) + (255,))
		d.line([x + 6, 0, x + 6, T], fill=tuple(max(0, v - 25) for v in c) + (255,))
	for y in range(6 if top else 0, T, 10):
		d.line([0, y, T, y], fill=tuple(max(0, v - 30) for v in c) + (255,), width=2)
	if top:
		d.rectangle([0, 0, T, 5], fill=tuple(max(0, v - 10) for v in c) + (255,))
		d.line([0, 0, T, 0], fill=(230, 235, 245, 255) if True else c, width=2)
	return im
def plank(col):
	im = Image.new("RGBA", (T, T), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
	d.rectangle([0, 0, T, 9], fill=col + (255,))
	d.line([0, 1, T, 1], fill=tuple(min(255, v + 45) for v in col) + (255,))
	d.line([0, 9, T, 9], fill=tuple(max(0, v - 40) for v in col) + (255,), width=2)
	d.line([15, 0, 15, 9], fill=tuple(max(0, v - 30) for v in col) + (255,))
	for x in (4, 26): d.rectangle([x, 9, x + 2, 16], fill=tuple(max(0, v - 30) for v in col) + (255,))
	return im
atlas = Image.new("RGBA", (T * 8, T * len(SCEN)), (0, 0, 0, 0))
for r, (name, base, m, pc) in enumerate(SCEN):
	plat = Image.open(os.path.join(R, "assets/env/plat_%s.png" % base)).convert("RGBA")
	body = Image.open(os.path.join(R, "assets/env/body_%s.png" % base)).convert("RGBA")
	ph = plat.height
	tops = [plat.crop((x, 0, x + 40, ph)).resize((T, T), Image.LANCZOS) for x in (40, 160)]
	fills = [body.crop((x, 8, x + T, 8 + T)) for x in (32, 128)]
	fills = [Image.alpha_composite(Image.new("RGBA", (T, T), (20, 20, 26, 255)), f) for f in fills]
	tops = [Image.alpha_composite(fills[i].copy(), t) for i, t in enumerate(tops)]
	dark = ImageEnhance.Brightness(fills[0]).enhance(0.55)
	rbase = np.array(pc) * 0.55 + np.array([30, 34, 44])
	cells = [tint(t, m) for t in tops] + [tint(f, m) for f in fills] + [plank(pc), roof(True, rbase), roof(False, rbase * 0.85), tint(dark, m)]
	for c, im in enumerate(cells): atlas.alpha_composite(im, (c * T, r * T))
atlas.save(os.path.join(R, "assets/tiles/stage_tiles.png"))
print("atlas", atlas.size, [s[0] for s in SCEN])
