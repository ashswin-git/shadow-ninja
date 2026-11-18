# High-res original menu hero (same design as gen_art2.py "Hakuro"):
# indigo-black hair, half-face oni-fang mask, crimson scarf, blue aura.
# Drawn at 512px so the title screen is not a scaled-up 64px sprite. CC0, in-repo.
from PIL import Image, ImageDraw, ImageFilter
import math

OUT_PATH = "assets/ui/hero_menu.png"
W = 512
# Work in a 64-unit design space, 8 px per unit.
S = 8
CX, CY = 32, 32  # design-space origin of the 64x64 sprite

def P(pts):
    return [(x * S, y * S) for x, y in pts]

im = Image.new("RGBA", (W, W), (0, 0, 0, 0))
d = ImageDraw.Draw(im)

coat = (28, 30, 46, 255)
coat_dk = (18, 18, 28, 255)
trim = (60, 190, 200, 255)
hair = (34, 30, 72, 255)
hair_hi = (70, 70, 130, 255)
skin = (238, 214, 196, 255)
scarf = (150, 32, 40, 255)
scarf_hi = (196, 48, 58, 255)
outline = (12, 12, 20, 255)
fang = (230, 230, 236, 255)
eye = (90, 200, 255, 255)
mask = (22, 22, 34, 255)
band = (46, 36, 48, 255)
leg = (20, 20, 30, 255)

# Soft blue aura (baked, behind the body)
aura = Image.new("RGBA", (W, W), (0, 0, 0, 0))
ad = ImageDraw.Draw(aura)
for r, a in ((210, 28), (160, 50), (120, 70), (90, 90)):
    ad.ellipse([256 - r, 250 - r + 10, 256 + r, 250 + r + 10], fill=(80, 170, 255, a))
aura = aura.filter(ImageFilter.GaussianBlur(22))

# Coat tails
d.polygon(P([(25, 38), (20, 58), (27, 56), (31, 44)]), fill=coat, outline=outline, width=S)
d.polygon(P([(33, 44), (36, 56), (42, 58), (39, 38)]), fill=coat, outline=outline, width=S)
# Legs
d.polygon(P([(28, 44), (26, 61), (31, 61), (32, 45)]), fill=leg, outline=outline, width=S)
d.polygon(P([(33, 44), (35, 61), (40, 61), (37, 44)]), fill=leg, outline=outline, width=S)
# Torso
d.polygon(P([(24, 24), (40, 24), (41, 46), (23, 46)]), fill=coat, outline=outline, width=S)
# Cyan zipper trim
d.line(P([(32, 26), (32, 46)]), fill=trim, width=S)
# Crimson wrap scarf + tail (more folds at hires)
d.polygon(P([(23, 25), (26, 19), (38, 19), (41, 25), (36, 27), (28, 27)]), fill=scarf, outline=outline, width=S)
d.polygon(P([(26, 22), (30, 20), (36, 20), (38, 23)]), fill=scarf_hi)
d.polygon(P([(26, 24), (16, 30), (19, 33), (29, 26)]), fill=scarf, outline=outline, width=S)
d.polygon(P([(18, 30), (14, 36), (17, 37), (22, 31)]), fill=scarf_hi)
# Right arm hanging
d.line(P([(40, 28), (43, 40)]), fill=coat, width=5 * S)
d.ellipse([40 * S, 38 * S, 47 * S, 45 * S], fill=coat, outline=outline, width=max(1, S // 2))
# Head
hx = 32
d.ellipse([(hx - 8) * S, 7 * S, (hx + 8) * S, 22 * S], fill=skin, outline=outline, width=S)
# Eye band + cyan eyes
d.rectangle([(hx - 8) * S, 11 * S, (hx + 8) * S, 15 * S], fill=band)
d.rectangle([(hx + 1) * S, 12.2 * S, (hx + 3.2) * S, 13.8 * S], fill=eye)
d.rectangle([(hx - 4.2) * S, 12.2 * S, (hx - 2) * S, 13.8 * S], fill=eye)
# Half-face mask over nose/mouth
d.chord([(hx - 8) * S, 8 * S, (hx + 8) * S, 22 * S], 0, 180, fill=mask)
d.rectangle([(hx - 8) * S, 15 * S, (hx + 8) * S, 16 * S], fill=mask)
# Oni fangs
for fx in (hx - 4.2, hx + 2.6):
    d.polygon(P([(fx, 16.6), (fx + 1.5, 20.2), (fx + 3.0, 16.6)]), fill=fang)
# Scarf edge on mask
d.line(P([(hx - 6, 16), (hx + 6, 16)]), fill=scarf, width=S)
# Indigo-black spiky hair, swept back (tall rear spikes — original silhouette)
sp = [
    (hx - 9, 12), (hx - 16, 4), (hx - 8, 6), (hx - 10, -2),
    (hx - 2, 4), (hx, -4), (hx + 4, 4), (hx + 10, 0),
    (hx + 8, 7), (hx + 13, 8), (hx + 8, 11),
]
d.polygon(P(sp), fill=hair, outline=hair_hi, width=max(2, S // 2))
# A couple of extra hair strands at hires for a cleaner silhouette
d.polygon(P([(hx - 6, 6), (hx - 12, 1), (hx - 7, 7)]), fill=hair)
d.polygon(P([(hx + 2, 3), (hx + 6, -3), (hx + 6, 6)]), fill=hair)

# Composite aura behind body
out = Image.new("RGBA", (W, W), (0, 0, 0, 0))
out.alpha_composite(aura)
out.alpha_composite(im)
# Slight unsharp so edges stay crisp when scaled down to ~400px
out = out.filter(ImageFilter.UnsharpMask(radius=1.2, percent=80, threshold=2))
out.save(OUT_PATH)
print("wrote", OUT_PATH, out.size)
