#!/usr/bin/env python3
"""Rich art pass: original lacquer-and-gold emblem icons for skills, shop items and artifacts.
192x192 RGBA (drawn 4x supersampled), assets/ui/icons/<id>.png"""
import math, os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
S = 768; OUT = "assets/ui/icons"
GOLD = (236, 196, 110); GOLD_D = (150, 104, 40); INK = (24, 16, 20)

def disc(base, seed):
    yy, xx = np.mgrid[0:S, 0:S]; c = S / 2; d = np.hypot(xx - c, yy - c) / (S * 0.46)
    rng = np.random.default_rng(seed)
    n = np.asarray(Image.fromarray((rng.random((24, 24)) * 255).astype(np.uint8)).resize((S, S), Image.BICUBIC), np.float32) / 255
    b = np.array(base, np.float32)
    shade = (1.15 - 0.55 * d) * (0.9 + 0.2 * n)
    hl = np.exp(-(((xx - c * 0.7) / (S * 0.22)) ** 2 + ((yy - c * 0.55) / (S * 0.14)) ** 2)) * 70
    rgb = np.clip(b[None, None, :] * shade[..., None] + hl[..., None], 0, 255)
    a = np.clip((1 - d) * S * 0.05, 0, 1) * 255
    im = Image.fromarray(np.dstack([rgb, a]).astype(np.uint8), "RGBA")
    dr = ImageDraw.Draw(im)
    for w, col in ((26, GOLD_D), (14, GOLD), (4, (255, 236, 170))):
        r = S * 0.46 - 13; dr.ellipse([c - r, c - r, c + r, c + r], outline=col, width=w)
    r = S * 0.38; dr.ellipse([c - r, c - r, c + r, c + r], outline=GOLD_D, width=5)
    return im

def emblem(dr, kind, col=GOLD):
    c = S / 2; L = lambda pts, w: dr.line(pts, fill=col, width=w, joint="curve")
    P = lambda pts: dr.polygon(pts, fill=col)
    E = lambda x0, y0, x1, y1, **k: dr.ellipse([x0, y0, x1, y1], **k)
    def kunai(x, y, ang, s=1.0):
        ca, sa = math.cos(ang), math.sin(ang); R = lambda u, v: (x + u * ca - v * sa, y + u * sa + v * ca)
        P([R(-150 * s, 0), R(30 * s, -36 * s), R(170 * s, 0), R(30 * s, 36 * s)])
        L([R(-150 * s, 0), R(-260 * s, 0)], int(22 * s)); E(*R(-290 * s, -0), *R(-290 * s, 0), outline=col)
        dr.ellipse([R(-300 * s, 0)[0] - 28 * s, R(-300 * s, 0)[1] - 28 * s, R(-300 * s, 0)[0] + 28 * s, R(-300 * s, 0)[1] + 28 * s], outline=col, width=int(12 * s))
    def moon(x, y, r, cut=0.55):
        E(x - r, y - r, x + r, y + r, fill=col); E(x - r + r * cut, y - r - r * 0.15, x + r + r * cut, y + r - r * 0.15, fill=(0, 0, 0, 0))
    if kind == "combo_ink":
        for k in range(3): dr.arc([c - 220 + k * 40, c - 220 + k * 30, c + 220 - k * 40, c + 220 - k * 30], 200 + k * 25, 340 + k * 15, fill=col, width=34 - k * 8)
        E(c + 120, c + 100, c + 190, c + 170, fill=col)
    elif kind == "twin_kunai": kunai(c, c - 70, -0.5); kunai(c, c + 90, -0.5, 0.85)
    elif kind == "moon_finisher":
        moon(c - 30, c, 200); L([(c - 240, c + 200), (c + 240, c - 200)], 26)
    elif kind == "rite_echo":
        for r in (230, 165, 100): dr.ellipse([c - r, c - r, c + r, c + r], outline=col, width=20)
        E(c - 40, c - 40, c + 40, c + 40, fill=col)
    elif kind == "ghost_step":
        for k, (x, y) in enumerate([(c - 140, c + 120), (c - 20, c - 10), (c + 110, c - 140)]):
            colk = tuple(int(v * (0.5 + 0.25 * k)) for v in col[:3])
            dr.ellipse([x - 55, y - 80, x + 55, y + 80], fill=colk)
            for t in range(4): dr.ellipse([x - 60 + t * 32, y - 130, x - 36 + t * 32, y - 100], fill=colk)
    elif kind == "moon_veil":
        moon(c, c - 40, 170, 0.5)
        for k in range(4): dr.arc([c - 250, c - 40 + k * 50, c + 250, c + 200 + k * 50], 200, 340, fill=col, width=16)
    elif kind == "coin_sense":
        E(c - 150, c - 150, c + 150, c + 150, fill=col); dr.rectangle([c - 45, c - 45, c + 45, c + 45], fill=(60, 30, 20))
        for a in range(0, 360, 45):
            x, y = c + math.cos(math.radians(a)) * 240, c + math.sin(math.radians(a)) * 240
            L([(x, y), (c + math.cos(math.radians(a)) * 190, c + math.sin(math.radians(a)) * 190)], 14)
    elif kind == "iron_ward":
        P([(c, c - 230), (c + 190, c - 150), (c + 160, c + 90), (c, c + 240), (c - 160, c + 90), (c - 190, c - 150)])
        dr.polygon([(c, c - 150), (c + 110, c - 100), (c + 95, c + 60), (c, c + 150), (c - 95, c + 60), (c - 110, c - 100)], fill=(70, 30, 26))
        for k in range(3): L([(c - 70 + k * 10, c - 80 + k * 70), (c + 70 - k * 10, c - 80 + k * 70)], 20)
    elif kind == "second_breath":
        for k in range(3):
            pts = [(c - 220 + t * 20, c - 120 + k * 110 + math.sin(t * 0.55 + k) * 40) for t in range(23)]; L(pts, 26 - k * 4)
        E(c + 180, c - 150, c + 250, c - 80, fill=col)
    elif kind == "tea":
        dr.chord([c - 190, c - 160, c + 190, c + 220], 0, 180, fill=col); dr.rectangle([c - 90, c + 150, c + 90, c + 190], fill=col)
        for k in range(3): L([(c - 80 + k * 80, c - 60), (c - 50 + k * 80, c - 150), (c - 80 + k * 80, c - 240)], 14)
    elif kind == "talisman":
        dr.rectangle([c - 110, c - 230, c + 110, c + 230], fill=(240, 226, 196)); dr.rectangle([c - 110, c - 230, c + 110, c + 230], outline=col, width=14)
        for k in range(5): L([(c - 50, c - 160 + k * 70), (c + 50, c - 140 + k * 70)], 22 if k % 2 == 0 else 12)
        E(c - 50, c + 120, c + 50, c + 220, fill=(190, 40, 30))
    elif kind in ("ashen", "crimson", "jade", "moonlit"):
        sc = {"ashen": (120, 150, 210), "crimson": (210, 50, 50), "jade": (70, 190, 120), "moonlit": (210, 225, 255)}[kind]
        E(c - 110, c - 230, c + 110, c - 10, fill=(30, 26, 34)); dr.polygon([(c - 150, c + 240), (c + 150, c + 240), (c + 90, c - 20), (c - 90, c - 20)], fill=(30, 26, 34))
        dr.rectangle([c - 110, c - 150, c + 110, c - 95], fill=sc)
        dr.polygon([(c + 90, c - 140), (c + 260, c - 60), (c + 230, c - 10), (c + 80, c - 100)], fill=sc)
        dr.polygon([(c - 80, c - 30), (c + 80, c - 30), (c + 60, c + 20), (c - 60, c + 20)], fill=sc)
    elif kind == "fox_bell":
        dr.chord([c - 170, c - 170, c + 170, c + 230], 180, 360, fill=col); dr.rectangle([c - 170, c + 25, c + 170, c + 60], fill=col)
        L([(c - 160, c + 60), (c + 160, c + 60)], 24); E(c - 30, c + 70, c + 30, c + 130, fill=col)
        dr.polygon([(c - 120, c - 150), (c - 60, c - 250), (c - 30, c - 150)], fill=col); dr.polygon([(c + 120, c - 150), (c + 60, c - 250), (c + 30, c - 150)], fill=col)
    elif kind == "moon_mirror":
        E(c - 180, c - 200, c + 180, c + 160, fill=col); E(c - 140, c - 160, c + 140, c + 120, fill=(170, 200, 235))
        dr.rectangle([c - 30, c + 150, c + 30, c + 260], fill=col); moon(c, c - 20, 80, 0.45)
    elif kind == "crow_feather":
        L([(c - 200, c + 220), (c + 180, c - 220)], 14)
        for t in range(14):
            f = t / 13; x, y = c - 170 + f * 330, c + 190 - f * 380; w = 120 * math.sin(math.pi * min(1, f * 1.1)) + 10
            dr.polygon([(x, y), (x - w * 0.9, y - w * 0.2), (x - w * 0.5, y + w * 0.35)], fill=(40, 40, 60))
            dr.polygon([(x, y), (x + w * 0.2, y + w * 0.9), (x - w * 0.3, y + w * 0.6)], fill=(55, 55, 80))
    elif kind == "stone_heart":
        P([(c, c + 230), (c - 230, c - 20), (c - 200, c - 160), (c - 90, c - 210), (c, c - 120), (c + 90, c - 210), (c + 200, c - 160), (c + 230, c - 20)])
        L([(c - 60, c - 150), (c + 20, c - 30), (c - 40, c + 60), (c + 30, c + 150)], 12)

BASES = {"BLADE": (120, 28, 30), "SHADOW": (40, 34, 80), "SPIRIT": (24, 80, 70), "shop": (90, 50, 24), "artifact": (30, 60, 100)}
SKILLS = {"combo_ink": "BLADE", "twin_kunai": "BLADE", "moon_finisher": "BLADE", "rite_echo": "SHADOW", "ghost_step": "SHADOW",
          "moon_veil": "SHADOW", "coin_sense": "SPIRIT", "iron_ward": "SPIRIT", "second_breath": "SPIRIT"}
ITEMS = {**SKILLS, **{k: "shop" for k in ("tea", "talisman", "ashen", "crimson", "jade", "moonlit")},
         **{k: "artifact" for k in ("fox_bell", "moon_mirror", "crow_feather", "stone_heart")}}
if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for i, (k, b) in enumerate(ITEMS.items()):
        im = disc(BASES[b], i)
        lay = Image.new("RGBA", (S, S), (0, 0, 0, 0)); emblem(ImageDraw.Draw(lay), k)
        sh = lay.split()[3].filter(ImageFilter.GaussianBlur(10)); shadow = Image.new("RGBA", (S, S), (0, 0, 0, 160)); shadow.putalpha(sh.point(lambda v: v * 0.7))
        im.alpha_composite(shadow, (10, 14)); im.alpha_composite(lay)
        im.resize((192, 192), Image.LANCZOS).save(f"{OUT}/{k}.png", optimize=True)
    print(len(ITEMS), "icons")
