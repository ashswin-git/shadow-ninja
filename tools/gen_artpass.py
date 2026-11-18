"""Shadow Ninja commercial art pass. Generates every UI / HUD / touch texture.
Sources: original painted plates in art_src/ (made for this project) and CC0 Kenney
Fantasy UI Borders + UI Pack (third_party/kenney_src). Layout sizes unchanged."""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from artlib import *

UI = os.path.join(ROOT, "assets/ui")
NA2 = os.path.join(ROOT, "assets/na2")
SPR = os.path.join(ROOT, "assets/sprites")
only = set(sys.argv[1:])
def want(k):
    return not only or k in only

# ---------------------------------------------------------------- lacquer disc
def lacquer(mask, base=(16, 18, 30), hi=(70, 80, 120), dome_w=40.0, gloss=0.22, grain=0.05):
    h, w = mask.shape
    hf = heightfield(mask, dome_w, 2.0, dome=True)
    lam, sp = shade(hf, 0.6)
    t = np.clip(0.25 + lam * 0.75, 0, 1)
    n = noise(h, w, 6, 3) - 0.5
    col = np.array(base, np.float32) * (1 - t[..., None]) + np.array(hi, np.float32) * t[..., None]
    col = col * (1 + n[..., None] * grain * 4)
    col = col + sp[..., None] * 160 * gloss
    return np.concatenate([np.clip(col, 0, 255), (mask * 255)[..., None]], -1)


def gloss_cap(w, h, cx, cy, r, alpha=0.20):
    # soft top highlight arc
    m = ss_mask(w, h, lambda d, s: d.ellipse([(cx - r * 0.78) * s, (cy - r * 0.92) * s, (cx + r * 0.78) * s, (cy + r * 0.05) * s], fill=255))
    y = np.linspace(0, 1, h)[:, None]
    fade = np.clip(1.2 - (y * h - (cy - r)) / (r * 1.0), 0, 1)
    m = ndi.gaussian_filter(m, 3) * fade
    return flat(m, (235, 240, 255), alpha)


def rivets(w, h, pts, r=4.0, stops=GOLD):
    acc = blank(w, h)
    m = np.zeros((h, w), np.float32)
    for (x, y) in pts:
        m = np.maximum(m, disc(w, h, x, y, r))
    acc = over(acc, shadow(m, 1, 2, 1.2, 0.6))
    acc = over(acc, metal(m, stops, width=r, dome=True, soft=0.5))
    return acc


def action_disc(S=256):
    c = S / 2
    out = blank(S, S)
    outer = disc(S, S, c, c, 124)
    out = over(out, shadow(outer, 0, 4, 5, 0.55))
    goldring = ring(S, S, c, c, 124, 108)
    face = disc(S, S, c, c, 110)
    out = over(out, lacquer(face, (10, 11, 20), (58, 64, 98), 60))
    # subtle engraved seigaiha-ish concentric rings on face
    wav = np.zeros((S, S), np.float32)
    step = 22
    for row in range(-1, S // (step // 2) + 2):
        for col in range(-1, S // step + 2):
            cx0 = col * step + (step / 2 if row % 2 else 0)
            cy0 = row * step / 2
            for rr in (10, 6.5, 3):
                wav = np.maximum(wav, ring(S, S, cx0, cy0, rr + 0.7, rr - 0.7, 2))
    out = over(out, flat(wav * erode(face, 6), (140, 150, 200), 0.10))
    for rr in [96]:
        rm = ring(S, S, c, c, rr + 0.9, rr - 0.9)
        out = over(out, flat(rm, (150, 160, 200), 0.22))
    out = over(out, metal(goldring, GOLD, width=6, strength=1.2))
    inner = ring(S, S, c, c, 104, 100.5)
    out = over(out, metal(inner, STEEL, width=1.5))
    # 8 gold studs on the ring
    pts = [(c + 116 * math.cos(a), c + 116 * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 9)[:-1] + math.pi / 8]
    out = over(out, rivets(S, S, pts, 4.2))
    out = over(out, gloss_cap(S, S, c, c, 104, 0.16))
    return out


def icon_render(mask, body=STEEL, edge=GOLD, S=128, glow_col=None):
    out = blank(S, S)
    edge_m = dilate(mask, 3.2)
    out = over(out, shadow(edge_m, 2, 4, 3, 0.75))
    if glow_col is not None:
        out = over(out, glow(edge_m, 7, glow_col, 0.9))
    out = over(out, metal(edge_m, edge, width=3, strength=1.1))
    out = over(out, metal(mask, body, width=4.5, strength=1.0))
    return out


def icon_jump(S=128):
    s = S / 128
    pts = [(64, 12), (110, 62), (82, 62), (82, 112), (46, 112), (46, 62), (18, 62)]
    m = poly(S, S, [(x * s, y * s) for x, y in pts])
    notch = poly(S, S, [(46 * s, 112 * s), (64 * s, 96 * s), (82 * s, 112 * s)])
    return np.clip(m - notch, 0, 1)


def icon_slash(S=128):
    def f(d, k):
        d.ellipse([10 * k, 8 * k, 122 * k, 120 * k], fill=255)
        d.ellipse([26 * k, 26 * k, 128 * k, 132 * k], fill=0)
    m = ss_mask(S, S, f)
    # cut lower-right to form crescent blade; add hilt
    cut = poly(S, S, [(64, 128), (128, 128), (128, 60)])
    m = np.clip(m - cut, 0, 1)
    hilt = poly(S, S, [(18, 96), (30, 84), (44, 98), (32, 110)])
    guard = poly(S, S, [(10, 84), (22, 72), (42, 92), (30, 104)])
    return np.clip(np.maximum(m, np.maximum(hilt * 0, guard * 0)), 0, 1)


def icon_dash(S=128):
    m = np.zeros((S, S), np.float32)
    for i, x in enumerate([16, 44]):
        m = np.maximum(m, poly(S, S, [(x, 30), (x + 18, 30), (x + 44, 64), (x + 18, 98), (x, 98), (x + 26, 64)]))
    m = np.maximum(m, poly(S, S, [(74, 22), (96, 22), (124, 64), (96, 106), (74, 106), (100, 64)]))
    return m


def icon_domain(S=128):
    c = S / 2
    m = ring(S, S, c, c, 50, 40)
    def eye(d, k):
        d.ellipse([(c - 30) * k, (c - 17) * k, (c + 30) * k, (c + 17) * k], fill=255)
    e = ss_mask(S, S, eye)
    pupil = disc(S, S, c, c, 10)
    e = np.clip(e - disc(S, S, c, c, 13), 0, 1)
    m = np.maximum(m, np.maximum(e, pupil))
    for a in [0, 90, 180, 270]:
        r = math.radians(a)
        cx, cy = c + 54 * math.cos(r), c + 54 * math.sin(r)
        px, py = -math.sin(r), math.cos(r)
        m = np.maximum(m, poly(S, S, [(cx + 10 * math.cos(r), cy + 10 * math.sin(r)), (cx + px * 7, cy + py * 7), (cx - 8 * math.cos(r), cy - 8 * math.sin(r)), (cx - px * 7, cy - py * 7)]))
    return m


def icon_kunai(S=128):
    m = poly(S, S, [(112, 16), (92, 52), (76, 52), (76, 36)])
    m = np.maximum(m, poly(S, S, [(112, 16), (76, 36), (52, 60), (68, 76), (92, 52)]))
    m = np.maximum(m, poly(S, S, [(56, 64), (64, 72), (30, 106), (22, 98)]))
    m = np.maximum(m, ring(S, S, 20, 108, 13, 7))
    return m


def gear_icon(S=256):
    c = S / 2
    out = blank(S, S)
    outer = disc(S, S, c, c, 124)
    out = over(out, shadow(outer, 0, 3, 4, 0.5))
    out = over(out, lacquer(disc(S, S, c, c, 112), (10, 11, 20), (55, 60, 90), 50))
    out = over(out, metal(ring(S, S, c, c, 124, 110), GOLD, width=5))
    pts = []
    teeth = 8
    for i in range(teeth * 4):
        a = i / (teeth * 4) * 2 * math.pi
        r = 86 if (i % 4) in (0, 1) else 66
        pts.append((c + r * math.cos(a + 0.1), c + r * math.sin(a + 0.1)))
    cog = poly(S, S, pts)
    cog = np.clip(cog - disc(S, S, c, c, 28), 0, 1)
    out = over(out, shadow(cog, 2, 4, 3, 0.7))
    out = over(out, metal(cog, STEEL, width=7, strength=1.3))
    out = over(out, metal(ring(S, S, c, c, 44, 36), GOLD, width=3))
    out = over(out, gloss_cap(S, S, c, c, 110, 0.12))
    return out


def chevron(W=320, H=216):
    # forged arrow pointing right: broad head + fletched tail
    outer = [(304, 108), (196, 16), (150, 16), (190, 80), (60, 80), (20, 44), (40, 108), (20, 172), (60, 136), (190, 136), (150, 200), (196, 200)]
    m = poly(W, H, outer)
    out = blank(W, H)
    out = over(out, shadow(m, 3, 6, 5, 0.65))
    out = over(out, metal(m, GOLD, width=7, strength=1.2))
    inner = erode(m, 9)
    out = over(out, lacquer(inner, (12, 12, 20), (70, 72, 100), 30, 0.25))
    # engraved steel inner arrow from Kenney UI pack decorative arrow (CC0)
    ka = kenney_ui("arrow_decorative_e.png", None, "Grey", "Double")
    a = np.asarray(ka.split()[3], np.float32) / 255.0
    kw, kh = 150, int(150 * a.shape[0] / a.shape[1])
    a = np.asarray(Image.fromarray((a * 255).astype(np.uint8)).resize((kw, kh), Image.LANCZOS), np.float32) / 255.0
    km = np.zeros((H, W), np.float32)
    x0, y0 = 90, 108 - kh // 2
    km[y0:y0 + kh, x0:x0 + kw] = a
    km = km * inner
    out = over(out, metal(km, STEEL, width=3, strength=1.2))
    out = over(out, rivets(W, H, [(176, 30), (176, 186), (44, 108)], 4.5))
    return out


def star(S=48, full=True):
    k = kenney_ui("star.png", None, "Grey", "Double")
    a = np.asarray(k.split()[3].resize((int(S * 0.86), int(S * 0.86)), Image.LANCZOS), np.float32) / 255.0
    m = np.zeros((S, S), np.float32)
    o = (S - a.shape[0]) // 2
    m[o:o + a.shape[0], o:o + a.shape[1]] = a
    out = blank(S, S)
    out = over(out, shadow(m, 1, 2, 1.5, 0.7))
    if full:
        out = over(out, glow(m, 3, (255, 200, 90), 0.5))
        out = over(out, metal(m, GOLD, width=S / 8, strength=1.3, dome=True))
    else:
        out = over(out, metal(m, IRON, width=S / 8, strength=1.0, dome=True))
    return out


def heart(S=64):
    def f(d, k):
        d.ellipse([6 * k, 10 * k, 34 * k, 38 * k], fill=255)
        d.ellipse([30 * k, 10 * k, 58 * k, 38 * k], fill=255)
        d.polygon([(8 * k, 30 * k), (56 * k, 30 * k), (32 * k, 58 * k)], fill=255)
    m = ss_mask(S, S, f)
    out = blank(S, S)
    out = over(out, shadow(m, 1, 2, 2, 0.7))
    out = over(out, metal(m, GOLD, width=3))
    out = over(out, metal(erode(m, 4), CRIMSON, width=9, dome=True, strength=1.3))
    return out


def gem(S=64):
    c = S / 2
    outer = [(c, 4), (S - 8, 20), (S - 8, 44), (c, S - 4), (8, 44), (8, 20)]
    table = [(c, 16), (S - 18, 25), (S - 18, 39), (c, S - 16), (18, 39), (18, 25)]
    out = blank(S, S)
    m = poly(S, S, outer)
    out = over(out, shadow(m, 1, 2, 2, 0.7))
    base = np.array([40, 170, 200], np.float32)
    L = np.array([-0.5, -0.8])
    for i in range(6):
        p = [outer[i], outer[(i + 1) % 6], table[(i + 1) % 6], table[i]]
        mx = sum(q[0] for q in p) / 4 - c
        my = sum(q[1] for q in p) / 4 - c
        nrm = np.array([mx, my]) / (math.hypot(mx, my) + 1e-6)
        b = 0.55 + 0.6 * float(nrm @ L)
        out = over(out, flat(poly(S, S, p), np.clip(base * b + 20, 0, 255)))
    tm = poly(S, S, table)
    out = over(out, flat(tm, (120, 230, 245)))
    y = np.linspace(0, 1, S)[:, None] * np.ones((1, S))
    out = over(out, flat(tm * np.clip(1 - y * 1.8, 0, 1), (240, 255, 255), 0.7))
    edge = np.clip(m - erode(m, 1.2), 0, 1)
    out = over(out, flat(edge, (200, 250, 255), 0.6))
    # sparkle
    sp = poly(S, S, [(22, 20), (24, 26), (30, 28), (24, 30), (22, 36), (20, 30), (14, 28), (20, 26)])
    out = over(out, flat(sp, (255, 255, 255), 0.95))
    return out


def koban(S=64):
    c = S / 2
    m = ss_mask(S, S, lambda d, k: d.ellipse([12 * k, 4 * k, 52 * k, 60 * k], fill=255))
    out = blank(S, S)
    out = over(out, shadow(m, 1, 2, 2, 0.7))
    out = over(out, metal(m, GOLD, width=6, strength=1.2, dome=True))
    # engraved horizontal bands
    bands = np.zeros((S, S), np.float32)
    for y in range(16, 50, 5):
        bands = np.maximum(bands, rect_mask(S, S, 20, y, 44, y + 1.4))
    bands *= erode(m, 6)
    out = over(out, flat(bands, (90, 55, 10), 0.55))
    seal = rect_mask(S, S, 27, 26, 37, 38, 2) * 1.0
    out = over(out, metal(seal, DARKGOLD, width=2))
    return out


def lock_icon(S=48, stops=IRON):
    out = blank(S, S)
    k = S / 48
    shackle = ss_mask(S, S, lambda d, s: (d.rounded_rectangle([13 * k * s, 4 * k * s, 35 * k * s, 30 * k * s], radius=11 * k * s, fill=255), d.rounded_rectangle([18 * k * s, 9 * k * s, 30 * k * s, 30 * k * s], radius=6 * k * s, fill=0)))
    body = rect_mask(S, S, 8 * k, 20 * k, 40 * k, 44 * k, 4 * k)
    out = over(out, shadow(np.maximum(shackle, body), 1, 2, 1.5, 0.8))
    out = over(out, metal(shackle, STEEL, width=2.5 * k, dome=True))
    out = over(out, metal(body, stops, width=3 * k, strength=1.2))
    out = over(out, metal(np.clip(body - erode(body, 2 * k), 0, 1), DARKGOLD, width=1.5 * k))
    kh = ss_mask(S, S, lambda d, s: (d.ellipse([21 * k * s, 26 * k * s, 27 * k * s, 32 * k * s], fill=255), d.polygon([(22.5 * k * s, 30 * k * s), (25.5 * k * s, 30 * k * s), (26.5 * k * s, 38 * k * s), (21.5 * k * s, 38 * k * s)], fill=255)))
    out = over(out, flat(kh, (8, 6, 4), 0.95))
    out = over(out, rivets(S, S, [(12 * k, 24 * k), (36 * k, 24 * k), (12 * k, 40 * k), (36 * k, 40 * k)], 1.4 * k))
    return out


def diamond_node(S=160, kind="stage"):
    c = S / 2
    def dia(r):
        return poly(S, S, [(c, c - r), (c + r, c), (c, c + r), (c - r, c)])
    out = blank(S, S)
    if kind.startswith("boss"):
        R = 74
    else:
        R = 66
    outer = dia(R)
    out = over(out, shadow(outer, 0, 5, 6, 0.75))
    locked = kind.endswith("lock")
    boss = kind.startswith("boss")
    if boss:
        # forged horns behind the setting
        horns = np.maximum(poly(S, S, [(c - 30, c - 50), (c - 64, c - 76), (c - 40, c - 40)]), poly(S, S, [(c + 30, c - 50), (c + 64, c - 76), (c + 40, c - 40)]))
        horns = np.maximum(horns, poly(S, S, [(c - 22, c - 54), (c - 46, c - 78), (c - 50, c - 70), (c - 34, c - 44)]) * 0)
        out = over(out, shadow(horns, 1, 3, 2, 0.7))
        out = over(out, metal(horns, DARKGOLD if not locked else IRON, width=5, strength=1.2))
    out = over(out, metal(outer, (IRON if boss else GOLD) if not locked else IRON, width=6, strength=1.2))
    inset = dia(R - 9)
    out = over(out, metal(np.clip(inset - dia(R - 13), 0, 1), DARKGOLD if not locked else STEEL, width=1.5))
    face = dia(R - 14)
    if locked:
        st = lacquer(face, (14, 14, 18), (60, 60, 70), 26, 0.1, 0.12)
        out = over(out, st)
    else:
        # faceted jewel: sapphire (stage) or blood ruby (boss)
        base = np.array([30, 70, 170], np.float32) if not boss else np.array([120, 10, 18], np.float32)
        r = R - 14
        pts = [(c, c - r), (c + r, c), (c, c + r), (c - r, c)]
        tbl = [(c, c - r * 0.45), (c + r * 0.45, c), (c, c + r * 0.45), (c - r * 0.45, c)]
        Ld = np.array([-0.55, -0.8])
        for i in range(4):
            p = [pts[i], pts[(i + 1) % 4], tbl[(i + 1) % 4], tbl[i]]
            mx = sum(q[0] for q in p) / 4 - c; my = sum(q[1] for q in p) / 4 - c
            nrm = np.array([mx, my]) / (math.hypot(mx, my) + 1e-6)
            b = 0.7 + 0.55 * float(nrm @ Ld)
            out = over(out, flat(poly(S, S, p), np.clip(base * b * 1.3 + 10, 0, 255)))
            # sub facets
            mid = ((pts[i][0] + pts[(i + 1) % 4][0]) / 2, (pts[i][1] + pts[(i + 1) % 4][1]) / 2)
            out = over(out, flat(poly(S, S, [pts[i], mid, tbl[i]]), np.clip(base * (b + 0.15) * 1.3 + 20, 0, 255), 0.6))
        tm = poly(S, S, tbl)
        out = over(out, flat(tm, np.clip(base * 1.1 + 40, 0, 255)))
        y = np.linspace(0, 1, S)[:, None] * np.ones((1, S))
        out = over(out, flat(face * np.clip(0.9 - y * 1.6, 0, 1), (255, 255, 255), 0.35))
        g = glow(tm, 10, tuple((base * 1.6 + 60).clip(0, 255).tolist()), 0.35)
        out = over(out, g)
    if boss:
        # oni face sigil in gold on the boss gem / lock
        if not locked:
            eyes = np.maximum(poly(S, S, [(c - 26, c - 4), (c - 6, c + 2), (c - 22, c + 8)]), poly(S, S, [(c + 26, c - 4), (c + 6, c + 2), (c + 22, c + 8)]))
            out = over(out, glow(eyes, 4, (255, 120, 60), 0.9))
            out = over(out, metal(eyes, GOLD, width=2))
            fangs = np.maximum(poly(S, S, [(c - 12, c + 18), (c - 4, c + 18), (c - 8, c + 32)]), poly(S, S, [(c + 12, c + 18), (c + 4, c + 18), (c + 8, c + 32)]))
            out = over(out, metal(fangs, IVORY, width=2))
        # spikes at left/right tips
        sp = np.maximum(poly(S, S, [(c - R + 2, c - 8), (c - R - 4, c), (c - R + 2, c + 8)]), poly(S, S, [(c + R - 2, c - 8), (c + R + 4, c), (c + R - 2, c + 8)]))
        out = over(out, metal(sp, GOLD if not locked else STEEL, width=2))
    if locked:
        L = lock_icon(64, IRON if not boss else DARKGOLD)
        tmp = blank(S, S)
        tmp[int(c - 32):int(c + 32), int(c - 32):int(c + 32)] = L
        out = over(out, tmp)
    out = over(out, rivets(S, S, [(c, c - R + 5), (c, c + R - 5), (c - R + 5, c), (c + R - 5, c)], 3.2, GOLD if not locked else STEEL))
    return out


def act_arrow(W=80, H=120, left=False):
    ka = kenney_ui("arrow_decorative_e.png", None, "Grey", "Double")
    a = np.asarray(ka.split()[3], np.float32) / 255.0
    pts = [(10, 6), (74, 60), (10, 114), (26, 60)]
    m = poly(W, H, pts)
    out = blank(W, H)
    out = over(out, shadow(m, 2, 4, 3, 0.7))
    out = over(out, metal(m, GOLD, width=6, strength=1.2))
    inner = erode(m, 7)
    out = over(out, lacquer(inner, (40, 6, 10), (150, 30, 30), 14, 0.3))
    out = over(out, rivets(W, H, [(24, 60)], 4))
    if left:
        out = out[:, ::-1]
    return out


def home_icon(S=96):
    c = S / 2
    out = blank(S, S)
    out = over(out, shadow(disc(S, S, c, c, 44), 0, 3, 3, 0.6))
    out = over(out, lacquer(disc(S, S, c, c, 41), (12, 12, 20), (60, 62, 92), 20))
    out = over(out, metal(ring(S, S, c, c, 46, 40), GOLD, width=3))
    # torii-gate glyph = home shrine
    g = rect_mask(S, S, 22, 30, 74, 36, 2)
    g = np.maximum(g, poly(S, S, [(16, 26), (80, 26), (76, 31), (20, 31)]))
    g = np.maximum(g, rect_mask(S, S, 26, 42, 70, 46))
    g = np.maximum(g, rect_mask(S, S, 31, 32, 37, 72))
    g = np.maximum(g, rect_mask(S, S, 59, 32, 65, 72))
    out = over(out, shadow(g, 1, 2, 1.5, 0.8))
    out = over(out, metal(g, CRIMSON, width=2.5, strength=1.2))
    out = over(out, gloss_cap(S, S, c, c, 40, 0.12))
    return out


def portrait_ring(S=128):
    c = S / 2
    out = blank(S, S)
    r = ring(S, S, c, c, 63, 54)
    out = over(out, shadow(r, 0, 2, 3, 0.7))
    out = over(out, metal(r, GOLD, width=4, strength=1.2))
    out = over(out, metal(ring(S, S, c, c, 56, 53.5), STEEL, width=1.2))
    out = over(out, flat(ring(S, S, c, c, 60.5, 59.5), (60, 30, 6), 0.6))
    # four forged diamonds at the cardinal points
    for (x, y) in [(c, 3), (c, S - 3), (3, c), (S - 3, c)]:
        d = poly(S, S, [(x, y - 7), (x + 7, y), (x, y + 7), (x - 7, y)])
        out = over(out, metal(d, CRIMSON if y == 3 else GOLD, width=2.5, dome=True))
    return out


def plate(W, H, border_idx=13, frame=GOLD, base=(12, 13, 20), hi=(50, 54, 80), alpha=0.92, scale=1, double=True, wood=False, inset=0):
    out = blank(W, H)
    body = rect_mask(W, H, inset, inset, W - inset, H - inset, 6)
    out = over(out, shadow(body, 0, 4, 5, 0.6))
    if wood:
        tex = texture_fill(W, H, "wood.jpg", 0.9)
        v = vignette(W, H, 0.5, 2.2)
        tex[..., :3] *= v[..., None]
        out = over(out, masked(tex, body * alpha))
    else:
        out = over(out, masked(lacquer(body, base, hi, max(W, H) * 0.6, 0.12, 0.06), body * alpha))
    fr = kenney_border(border_idx, W - 2 * inset - 8, H - 2 * inset - 8, scale, double)
    fm = np.zeros((H, W), np.float32)
    fm[inset + 4:H - inset - 4, inset + 4:W - inset - 4] = fr
    out = over(out, shadow(fm, 1, 2, 1.5, 0.8))
    out = over(out, metal(fm, frame, width=2.2, strength=1.3))
    return out


# ================================================================ BUILD
if want("touch"):
    save(action_disc(256), f"{UI}/disc_action.png")
    for name, fn, body, edge, gl in [("jump", icon_jump, IVORY, GOLD, None), ("slash", icon_slash, STEEL, GOLD, (255, 80, 60)),
                                     ("dash", icon_dash, STEEL, GOLD, (90, 220, 255)), ("domain", icon_domain, STEEL, GOLD, (110, 150, 255)),
                                     ("kunai", icon_kunai, STEEL, GOLD, None)]:
        save(icon_render(fn(128), body, edge, 128, gl), f"{UI}/btn_{name}.png")
    save(gear_icon(256), f"{UI}/btn_gear.png")
    ch = chevron()
    save(ch, f"{UI}/chev_r.png")
    save(ch[:, ::-1].copy(), f"{UI}/chev_l.png")

if want("hud"):
    save(star(96, True), f"{UI}/star_full.png", (48, 48))
    save(star(96, False), f"{UI}/star_empty.png", (48, 48))
    save(heart(64), f"{UI}/hud_heart.png")
    save(gem(64), f"{UI}/hud_gem.png")
    save(koban(64), f"{UI}/hud_gold.png")
    save(heart(64), f"{UI}/heart_full.png", (48, 48))
    save(koban(64), f"{UI}/coin_icon.png", (48, 48))
    save(portrait_ring(128), f"{UI}/portrait_ring.png")
    save(plate(300, 172, 13, GOLD, alpha=0.9, scale=1), f"{UI}/hud_plate.png")
    save(home_icon(96), f"{UI}/icon_home.png")

if want("select"):
    for k, fn in [("node_diamond", "stage"), ("node_lock", "stage_lock"), ("node_boss", "boss"), ("node_boss_lock", "boss_lock")]:
        save(diamond_node(160, fn), f"{UI}/{k}.png")
    save(lock_icon(96), f"{UI}/lock.png", (48, 48))
    save(act_arrow(80, 120, False), f"{UI}/arrow_act_r.png")
    save(act_arrow(80, 120, True), f"{UI}/arrow_act_l.png")
print("done", only or "all")


# ================================================================ PANELS / BUTTONS
def wood_button(W=400, H=80, gold=False):
    out = blank(W, H)
    body = rect_mask(W, H, 4, 4, W - 4, H - 4, 8)
    out = over(out, shadow(body, 0, 4, 4, 0.7))
    if gold:
        base = lacquer(body, (70, 6, 10), (190, 40, 36), 30, 0.25, 0.05)
    else:
        base = masked(texture_fill(W, H, "wood.jpg", 1.1, (200, 300)), body)
        y = np.linspace(0, 1, H)[:, None]
        shade_v = (1.18 - 0.45 * y)  # top lit
        base[..., :3] *= shade_v[..., None]
    out = over(out, base)
    rim = np.clip(body - erode(body, 4), 0, 1)
    out = over(out, metal(rim, GOLD if gold else DARKGOLD, width=3, strength=1.3))
    fr = kenney_border(0, W - 24, H - 24, 1, False)
    fm = np.zeros((H, W), np.float32); fm[12:H - 12, 12:W - 12] = fr
    out = over(out, flat(ndi.shift(fm, (1, 0), order=1), (0, 0, 0), 0.6))
    out = over(out, metal(fm, GOLD, width=1.2, strength=1.4))
    # top sheen
    sheen = rect_mask(W, H, 10, 7, W - 10, H * 0.45, 6) * np.clip(1 - np.linspace(0, 1, H)[:, None] * 2.2, 0, 1)
    out = over(out, flat(sheen, (255, 240, 210), 0.10))
    # diamond end studs
    for x in (22, W - 22):
        d = poly(W, H, [(x, H / 2 - 9), (x + 9, H / 2), (x, H / 2 + 9), (x - 9, H / 2)])
        out = over(out, shadow(d, 1, 2, 1, 0.6))
        out = over(out, metal(d, GOLD, width=3, dome=True))
    return out


def wood_panel(W=512, H=640):
    out = blank(W, H)
    body = rect_mask(W, H, 6, 6, W - 6, H - 6, 14)
    out = over(out, shadow(body, 0, 8, 10, 0.75))
    tex = texture_fill(W, H, "wood.jpg", 1.05)
    v = vignette(W, H, 0.55, 2.0)
    tex[..., :3] *= v[..., None]
    out = over(out, masked(tex, body))
    band = np.clip(body - erode(body, 16), 0, 1)
    out = over(out, metal(band, IRON, width=6, strength=1.2))
    rim = np.clip(erode(body, 14) - erode(body, 19), 0, 1)
    out = over(out, metal(rim, GOLD, width=2.5, strength=1.3))
    fr = kenney_border(11, W - 70, H - 70, 2, True)
    fm = np.zeros((H, W), np.float32); fm[35:H - 35, 35:W - 35] = fr
    out = over(out, flat(ndi.gaussian_filter(ndi.shift(fm, (2, 1), order=1), 1.2), (0, 0, 0), 0.7))
    out = over(out, metal(fm, GOLD, width=3.0, strength=1.3, dome=True))
    # corner brackets
    for (x, y, sx, sy) in [(6, 6, 1, 1), (W - 6, 6, -1, 1), (6, H - 6, 1, -1), (W - 6, H - 6, -1, -1)]:
        br = poly(W, H, [(x, y), (x + sx * 70, y), (x + sx * 70, y + sy * 16), (x + sx * 16, y + sy * 16), (x + sx * 16, y + sy * 70), (x, y + sy * 70)])
        out = over(out, shadow(br, 2, 3, 2, 0.6))
        out = over(out, metal(br, GOLD, width=4, strength=1.3))
        out = over(out, rivets(W, H, [(x + sx * 9, y + sy * 9), (x + sx * 52, y + sy * 8), (x + sx * 8, y + sy * 52)], 3.4, STEEL))
    # header divider (Kenney CC0)
    dv = kenney_divider(3, 300, 40, True)
    dm = np.zeros((H, W), np.float32); dm[20:60, (W - 300) // 2:(W + 300) // 2] = dv
    out = over(out, metal(dm, GOLD, width=1.5))
    return out


def book_page(W=480, H=640, left=True):
    out = blank(W, H)
    body = rect_mask(W, H, 0, 8, W, H - 8, 4)
    if left:
        tex = texture_fill(W, H, "paper.jpg", 1.0)
        x = np.linspace(0, 1, W)[None, :]
        gut = 1 - 0.45 * np.clip((x - 0.82) / 0.18, 0, 1) ** 1.6
        tex[..., :3] *= gut[..., None]
        tex[..., :3] = tex[..., :3] * 0.9 + np.array([20, 12, 0]) * 0.1
        out = over(out, masked(tex, body))
        ink = (40, 24, 12)
        fr = kenney_border(10, W - 60, H - 76, 2, True)
        fm = np.zeros((H, W), np.float32); fm[38:H - 38, 26:W - 34] = fr
        out = over(out, flat(fm, ink, 0.75))
        dv = kenney_divider(0, 260, 30, True, True)
        for yy in (118, 432):
            dm = np.zeros((H, W), np.float32); dm[yy:yy + 30, (W - 260) // 2 - 4:(W + 260) // 2 - 4] = dv
            out = over(out, flat(dm, ink, 0.55))
        # faint ink-wash mountains at the bottom
        mt = ss_mask(W, H, lambda d, s: d.polygon([(30 * s, (H - 60) * s), (120 * s, (H - 150) * s), (190 * s, (H - 100) * s), (270 * s, (H - 190) * s), (380 * s, (H - 90) * s), (450 * s, (H - 120) * s), (450 * s, (H - 46) * s), (30 * s, (H - 46) * s)], fill=255))
        out = over(out, flat(ndi.gaussian_filter(mt, 3) * body, (60, 50, 40), 0.18))
    else:
        tex = texture_fill(W, H, "wood.jpg", 0.75, (100, 200))
        x = np.linspace(0, 1, W)[None, :]
        gut = 1 - 0.5 * np.clip((0.2 - x) / 0.2, 0, 1) ** 1.6
        tex[..., :3] *= (gut * vignette(W, H, 0.4, 2.5))[..., None]
        out = over(out, masked(tex, body))
        fr = kenney_border(10, W - 60, H - 76, 2, True)
        fm = np.zeros((H, W), np.float32); fm[38:H - 38, 34:W - 26] = fr
        out = over(out, flat(ndi.shift(fm, (2, 1), order=1), (0, 0, 0), 0.6))
        out = over(out, metal(fm, GOLD, width=3.0, strength=1.3, dome=True))
    return out


def book_cover(W=880, H=640):
    out = blank(W, H)
    body = rect_mask(W, H, 6, 6, W - 6, H - 6, 16)
    out = over(out, shadow(body, 0, 10, 14, 0.8))
    out = over(out, lacquer(body, (36, 6, 8), (120, 22, 22), 300, 0.15, 0.08))
    rim = np.clip(body - erode(body, 8), 0, 1)
    out = over(out, metal(rim, GOLD, width=3.5, strength=1.3))
    for (x, y, sx, sy) in [(6, 6, 1, 1), (W - 6, 6, -1, 1), (6, H - 6, 1, -1), (W - 6, H - 6, -1, -1)]:
        br = poly(W, H, [(x, y), (x + sx * 60, y), (x, y + sy * 60)])
        out = over(out, metal(br, GOLD, width=4, strength=1.3))
        out = over(out, rivets(W, H, [(x + sx * 18, y + sy * 18)], 4, STEEL))
    spine = rect_mask(W, H, W / 2 - 14, 10, W / 2 + 14, H - 10, 4)
    out = over(out, metal(spine, IRON, width=6))
    return out


def stage_banner(W=1024, H=112):
    out = blank(W, H)
    body = poly(W, H, [(40, 8), (W - 40, 8), (W - 8, H / 2), (W - 40, H - 8), (40, H - 8), (8, H / 2)])
    out = over(out, shadow(body, 0, 5, 6, 0.7))
    tex = texture_fill(W, H, "wood.jpg", 0.8, (0, 400))
    tex[..., :3] = tex[..., :3] * 0.55 + np.array([40, 22, 6]) * 0.45
    out = over(out, masked(tex, body))
    rim = np.clip(body - erode(body, 6), 0, 1)
    out = over(out, metal(rim, GOLD, width=3.5, strength=1.3))
    inner = np.clip(erode(body, 12) - erode(body, 15), 0, 1)
    out = over(out, metal(inner, GOLD, width=1.4, strength=1.3))
    for x in (34, W - 34):
        d = poly(W, H, [(x, H / 2 - 22), (x + 22, H / 2), (x, H / 2 + 22), (x - 22, H / 2)])
        out = over(out, shadow(d, 1, 3, 2, 0.6))
        out = over(out, metal(d, CRIMSON, width=6, dome=True))
        out = over(out, metal(np.clip(d - erode(d, 3), 0, 1), GOLD, width=2))
    return out


def bar_frame(W, H, bar_x0, bar_y0, bar_x1, bar_y1, wings=True, stops=GOLD, k=1.0):
    out = blank(W, H)
    outer = rect_mask(W, H, bar_x0 - 6 * k, bar_y0 - 6 * k, bar_x1 + 6 * k, bar_y1 + 6 * k, 4 * k)
    hole = rect_mask(W, H, bar_x0, bar_y0, bar_x1, bar_y1, 2 * k)
    fr = np.clip(outer - hole, 0, 1)
    out = over(out, shadow(fr, 0, 3 * k, 3 * k, 0.7))
    out = over(out, metal(fr, stops, width=3 * k, strength=1.3, dome=True))
    cy = (bar_y0 + bar_y1) / 2
    if wings:
        for side in (-1, 1):
            x = bar_x0 - 6 * k if side < 0 else bar_x1 + 6 * k
            P = [(0, -16), (26, -30), (84, -28), (54, -14), (88, -6), (56, 2), (80, 16), (34, 13), (0, 18)]
            pts = [(x + side * px * k, cy + py * k) for px, py in P]
            wm = poly(W, H, pts)
            out = over(out, shadow(wm, 1 * k, 3 * k, 2 * k, 0.7))
            out = over(out, metal(wm, IRON, width=5 * k, strength=1.3))
            out = over(out, metal(np.clip(wm - erode(wm, 3 * k), 0, 1), stops, width=2 * k, dome=True))
            for (fx, fy) in [(40, -20), (62, -2)]:
                f = poly(W, H, [(x + side * (fx - 18) * k, cy + fy * k), (x + side * fx * k, cy + (fy - 3) * k), (x + side * (fx - 4) * k, cy + (fy + 3) * k)])
                out = over(out, metal(f, stops, width=1.5 * k))
            gx = x + side * 16 * k
            gem_m = poly(W, H, [(gx, cy - 11 * k), (gx + 11 * k, cy), (gx, cy + 11 * k), (gx - 11 * k, cy)])
            out = over(out, glow(gem_m, 4 * k, (255, 60, 50), 0.8))
            out = over(out, metal(gem_m, CRIMSON, width=3 * k, dome=True))
    return out


def bar_fill(W, H, top, bot, glowc):
    y = np.linspace(0, 1, H)[:, None] * np.ones((1, W))
    col = np.array(top, np.float32) * (1 - y[..., None]) + np.array(bot, np.float32) * y[..., None]
    col = col * (1 + (noise(H, W, 4, 2) - 0.5)[..., None] * 0.15)
    hl = np.clip(1 - np.abs(y - 0.25) * 5, 0, 1)
    col = col + hl[..., None] * np.array(glowc, np.float32) * 0.5
    return np.concatenate([np.clip(col, 0, 255), np.full((H, W, 1), 255, np.float32)], -1)


def title_frame(W=520, H=340):
    out = blank(W, H)
    body = rect_mask(W, H, 10, 10, W - 10, H - 10, 10)
    lac = lacquer(body, (6, 8, 16), (30, 36, 60), 260, 0.1, 0.05)
    out = over(out, masked(lac, body * 0.62))
    fr = kenney_border(26, W - 20, H - 20, 2, True)
    fm = np.zeros((H, W), np.float32); fm[10:H - 10, 10:W - 10] = fr
    out = over(out, flat(ndi.gaussian_filter(ndi.shift(fm, (3, 2), order=1), 2), (0, 0, 0), 0.8))
    out = over(out, metal(fm, GOLD, width=3.0, strength=1.3, dome=True))
    dv = kenney_divider(5, 340, 36, True)
    dm = np.zeros((H, W), np.float32); dm[H - 62:H - 26, (W - 340) // 2 - 30:(W + 340) // 2 - 30] = dv
    out = over(out, metal(dm, GOLD, width=1.5))
    # crimson hanko seal bottom-right
    seal = rect_mask(W, H, W - 78, H - 78, W - 38, H - 38, 5)
    out = over(out, shadow(seal, 1, 2, 1.5, 0.6))
    out = over(out, metal(seal, CRIMSON, width=3, strength=1.0))
    cxs, cys = W - 58, H - 58
    glyph = ring(W, H, cxs, cys, 13, 10)
    glyph = np.maximum(glyph, poly(W, H, [(cxs, cys - 8), (cxs + 8, cys), (cxs, cys + 8), (cxs - 8, cys)]))
    out = over(out, flat(glyph, (250, 220, 200), 0.85))
    return out


def play_button(W=600, H=128):
    out = blank(W, H)
    body = poly(W, H, [(60, 10), (W - 60, 10), (W - 14, H / 2), (W - 60, H - 10), (60, H - 10), (14, H / 2)])
    out = over(out, shadow(body, 0, 8, 8, 0.8))
    out = over(out, lacquer(body, (60, 4, 8), (205, 40, 36), 60, 0.35, 0.05))
    rim = np.clip(body - erode(body, 8), 0, 1)
    out = over(out, metal(rim, GOLD, width=5, strength=1.3))
    inner = np.clip(erode(body, 16) - erode(body, 19), 0, 1)
    out = over(out, metal(inner, GOLD, width=1.5, strength=1.3))
    for x in (42, W - 42):
        d = poly(W, H, [(x, H / 2 - 26), (x + 26, H / 2), (x, H / 2 + 26), (x - 26, H / 2)])
        out = over(out, shadow(d, 2, 3, 2, 0.6))
        out = over(out, metal(d, GOLD, width=7, dome=True, strength=1.3))
    sheen = poly(W, H, [(70, 18), (W - 70, 18), (W - 46, H * 0.42), (46, H * 0.42)])
    sheen = ndi.gaussian_filter(sheen, 3)
    out = over(out, flat(sheen, (255, 230, 220), 0.16))
    return out


def currency_bar(W=1280, H=56, plates=True):
    out = blank(W, H)
    y = np.linspace(0, 1, H)[:, None] * np.ones((1, W))
    body = np.ones((H, W), np.float32)
    lac = np.zeros((H, W, 4), np.float32)
    lac[..., :3] = (np.array([8, 9, 16]) * (1 - y[..., None]) + np.array([20, 20, 34]) * y[..., None])
    lac[..., 3] = 230 * (1 - 0.15 * y)
    out = over(out, lac)
    trim = rect_mask(W, H, -10, H - 6, W + 10, H - 1)
    out = over(out, metal(trim, GOLD, width=2))
    for x0, x1 in ([(14, 182), (190, 358)] if plates else []):
        p = rect_mask(W, H, x0, 6, x1, H - 10, 14)
        out = over(out, flat(p, (0, 0, 0), 0.55))
        out = over(out, metal(np.clip(p - erode(p, 2), 0, 1), DARKGOLD, width=1.4))
    return out


def framed_painting(src, W, H, crop=None, border_idx=10, plaque=None, darken=1.0, scale=2):
    im = Image.open(os.path.join(SRC, src)).convert("RGB")
    if crop:
        im = im.crop(crop)
    sw, sh = im.size
    sc = max(W / sw, H / sh)
    im = im.resize((int(sw * sc) + 1, int(sh * sc) + 1), Image.LANCZOS)
    ox, oy = (im.width - W) // 2, (im.height - H) // 2
    im = im.crop((ox, oy, ox + W, oy + H))
    a = np.asarray(im, np.float32) * darken
    a = a * vignette(W, H, 0.45, 2.5)[..., None]
    out = np.concatenate([a, np.full((H, W, 1), 255, np.float32)], -1)
    if plaque == "bottom":
        y = np.linspace(0, 1, H)[:, None] * np.ones((1, W))
        g = np.clip((y - 0.62) / 0.3, 0, 1)
        out = over(out, flat(g, (6, 4, 8), 0.85))
        dv = kenney_divider(1, int(W * 0.5), 26, True, True)
        dm = np.zeros((H, W), np.float32); yy = int(H * 0.70); dm[yy:yy + 26, (W - dv.shape[1]) // 2:(W + dv.shape[1]) // 2] = dv
        out = over(out, metal(dm, GOLD, width=1.2))
    if plaque == "top":
        y = np.linspace(0, 1, H)[:, None] * np.ones((1, W))
        g = np.clip((0.3 - y) / 0.25, 0, 1)
        out = over(out, flat(g, (6, 4, 8), 0.8))
    edge = np.ones((H, W), np.float32)
    edge = np.clip(edge - rect_mask(W, H, 7, 7, W - 7, H - 7), 0, 1)
    out = over(out, metal(edge, GOLD, width=3, strength=1.3))
    fr = kenney_border(border_idx, W - 20, H - 20, scale, True)
    fm = np.zeros((H, W), np.float32); fm[10:H - 10, 10:W - 10] = fr
    out = over(out, flat(ndi.gaussian_filter(ndi.shift(fm, (2, 1), order=1), 1.2), (0, 0, 0), 0.75))
    out = over(out, metal(fm, GOLD, width=3.0, strength=1.3, dome=True))
    return out


if want("panels"):
    save(wood_button(400, 80, False), f"{UI}/wood_btn.png")
    save(wood_button(400, 80, True), f"{UI}/wood_btn_gold.png")
    save(wood_panel(512, 640), f"{UI}/wood_panel.png")
    save(book_page(480, 640, True), f"{UI}/book_page_l.png")
    save(book_page(480, 640, False), f"{UI}/book_page_r.png")
    save(book_cover(880, 640), f"{UI}/book_cover.png")
    save(stage_banner(1024, 112), f"{UI}/stage_banner.png", (512, 56))
    save(bar_frame(1440, 120, 180, 36, 1260, 84, True, GOLD, 2.0), f"{UI}/boss_frame.png", (720, 60))
    save(bar_fill(256, 24, (236, 70, 64), (110, 8, 16), (255, 150, 120)), f"{UI}/boss_fill.png")
    save(bar_fill(256, 24, (40, 8, 10), (14, 2, 4), (40, 10, 10)), f"{UI}/boss_bg.png")
    save(bar_frame(520, 60, 40, 16, 480, 44, False, DARKGOLD, 2.0), f"{UI}/domain_frame.png", (260, 30))
    save(bar_fill(128, 16, (140, 220, 255), (30, 90, 200), (220, 245, 255)), f"{UI}/domain_fill.png")
    save(title_frame(520, 340), f"{UI}/title_frame.png")
    save(play_button(600, 128), f"{UI}/play_btn.png")
    save(currency_bar(), f"{UI}/currency_bar.png")
    save(currency_bar(plates=False), f"{UI}/top_strip.png")
    save(plate(960, 520, 11, GOLD, alpha=0.9, scale=2), f"{UI}/meta_plate.png")

if want("paintings"):
    save(framed_painting("tile_skills.jpg", 660, 300, plaque="bottom", border_idx=2), f"{UI}/hub_skills.png")
    save(framed_painting("tile_shop.jpg", 660, 300, plaque="bottom", border_idx=2), f"{UI}/hub_shop.png")
    save(framed_painting("tile_artifact.jpg", 660, 300, plaque="bottom", border_idx=2), f"{UI}/hub_artifact.png")
    save(framed_painting("tile_challenge.jpg", 660, 300, plaque="bottom", border_idx=2), f"{UI}/hub_challenge.png")
    save(framed_painting("gion_bg.jpg", 680, 280, plaque="top", border_idx=26), f"{UI}/hub_story.png")
    save(framed_painting("title_bg.jpg", 960, 360, crop=(0, 120, 1280, 600), border_idx=26), f"{UI}/preview_act1.png")
    save(framed_painting("bamboo_bg.jpg", 960, 360, crop=(0, 160, 1280, 640), border_idx=26), f"{UI}/preview_act2.png")
    save(framed_painting("gion_bg.jpg", 960, 360, crop=(0, 100, 1280, 580), border_idx=26), f"{UI}/preview_act3.png")
print("done2")


# ================================================================ CHARACTER + BACKGROUNDS
def key_src(name):
    return key_green(Image.open(os.path.join(SRC, name)), 45, 35)


def fit(arr, W, H, pad=0, anchor="bottom"):
    a = arr[..., 3] > 8
    ys, xs = np.where(a)
    crop = arr[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    im = to_img(crop)
    sc = min((W - 2 * pad) / im.width, (H - 2 * pad) / im.height)
    im = im.resize((max(1, int(im.width * sc)), max(1, int(im.height * sc))), Image.LANCZOS)
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    x = (W - im.width) // 2
    y = H - pad - im.height if anchor == "bottom" else (H - im.height) // 2
    out.alpha_composite(im, (x, y))
    return out, sc


def player_sprites():
    a = key_src("hero_poses.jpg")
    cuts = {"idle": (20, 230), "run": (236, 490), "jump": (500, 722), "dash": (722, 1066), "wall": (1066, 1228)}
    H0 = None
    res = {}
    # common scale: idle body height -> 60 px
    for k, (x0, x1) in cuts.items():
        sub = a[:, x0:x1].copy()
        if k == "jump":
            sub[:, -6:, 3] = 0
        al = sub[..., 3] > 8
        ys, xs = np.where(al)
        res[k] = sub[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    sc = 60.0 / res["idle"].shape[0]
    CW = 112
    for k, crop in res.items():
        # drop stray specks: keep components bigger than 1% of the pose
        lab, n = ndi.label(crop[..., 3] > 30)
        if n > 1:
            sizes = ndi.sum(np.ones_like(lab), lab, range(1, n + 1))
            keep = np.isin(lab, [i + 1 for i, sz in enumerate(sizes) if sz > 0.01 * sizes.max()])
            crop = crop.copy(); crop[..., 3] *= ndi.binary_dilation(keep, iterations=2)
        im = to_img(crop)
        s_k = min(sc, CW / im.width, 64.0 / im.height)
        im2 = im.resize((max(1, int(im.width * s_k)), max(1, int(im.height * s_k))), Image.LANCZOS)
        im2 = im2.filter(ImageFilter.UnsharpMask(1.2, 60, 2))
        out = Image.new("RGBA", (CW, 64), (0, 0, 0, 0))
        x = (CW - im2.width) // 2
        y = 64 - 2 - im2.height if k != "jump" else (64 - im2.height) // 2 + 2
        out.alpha_composite(im2, (x, max(0, y)))
        out.save(f"{SPR}/player_{k}.png", optimize=True)


def hero_menu():
    a = key_src("hero.jpg")
    im, sc = fit(a, 480, 640, 6)
    im.save(f"{UI}/hero_menu.png", optimize=True)
    return a


def portrait(a):
    # head crop of the painted hero, inside a dark painted roundel
    S = 200
    head = to_img(a).crop((262, 20, 522, 280)).resize((S, S), Image.LANCZOS)
    bg = Image.open(os.path.join(SRC, "title_bg.jpg")).convert("RGB").crop((300, 40, 560, 300)).resize((S, S), Image.LANCZOS).filter(ImageFilter.GaussianBlur(4))
    bgA = np.asarray(bg, np.float32) * 0.55
    bgA = np.concatenate([bgA, np.full((S, S, 1), 255, np.float32)], -1)
    g = glow(disc(S, S, S / 2, S * 0.52, 60), 26, (60, 130, 255), 0.55)
    out = over(bgA, g)
    out = over(out, from_img(head))
    m = disc(S, S, S / 2, S / 2, S / 2 - 1)
    out[..., 3] *= m
    save(out, f"{UI}/portrait.png")


def grade(arr, desat=0.0, contrast=1.0, fog=(0, 0, 0), fog_amt=0.0, bright=1.0):
    rgb = arr[..., :3]
    lum = rgb.mean(-1, keepdims=True)
    rgb = rgb * (1 - desat) + lum * desat
    rgb = (rgb - 128) * contrast + 128
    rgb = rgb * bright
    rgb = rgb * (1 - fog_amt) + np.array(fog, np.float32) * fog_amt
    out = arr.copy(); out[..., :3] = np.clip(rgb, 0, 255)
    return out


def load_rgba(name, W=1280, H=720):
    im = Image.open(os.path.join(SRC, name)).convert("RGB").resize((W, H), Image.LANCZOS)
    return np.concatenate([np.asarray(im, np.float32), np.full((H, W, 1), 255, np.float32)], -1)


def silhouette_layer(name, color, alpha, fill_bottom=True, W=1280, H=720, yshift=0, hscale=1.0):
    im = Image.open(os.path.join(SRC, name)).convert("L").resize((W, int(H * hscale)), Image.LANCZOS)
    m = 1 - np.asarray(im, np.float32) / 255.0
    m = np.clip((m - 0.25) / 0.5, 0, 1)
    full = np.zeros((H, W), np.float32)
    hh = m.shape[0]
    y0 = H - hh + yshift
    full[max(0, y0):min(H, y0 + hh)] = m[max(0, -y0):max(0, -y0) + min(H, y0 + hh) - max(0, y0)]
    if fill_bottom:
        # everything below the first solid ground row is solid (no see-through gap)
        rows = (full > 0.5).mean(1)
        solid = np.where(rows > 0.97)[0]
        if len(solid):
            full[solid[0]:] = 1.0
    out = flat(full, color, alpha)
    # mirror to 2W for perfectly seamless parallax wrap
    return np.concatenate([out, out[:, ::-1]], 1)


def mist_band(W=1280, H=720, color=(220, 230, 240), alpha=0.5, y0=0.55, seed=3):
    x = np.linspace(0, 2 * np.pi, W, endpoint=False)[None, :]
    y = np.linspace(0, 1, H)[:, None]
    r = np.random.default_rng(seed)
    wave = sum(r.uniform(0.3, 1.0) * np.sin(k * x + r.uniform(0, 6.28)) / k ** 0.5 for k in range(1, 9))
    top = y0 + 0.06 * wave
    band = np.clip((y - top) / 0.18, 0, 1) * np.clip((1.02 - y) / 0.12 + 0.4, 0, 1)
    band = band * (0.75 + 0.25 * np.sin(3 * x + 1.0) * np.sin(5 * x))
    return flat(np.clip(band, 0, 1).astype(np.float32), color, alpha)


THEMES = {
    "snow": dict(src="title_bg.jpg", grade=dict(desat=0.15, contrast=0.78, fog=(150, 170, 200), fog_amt=0.22, bright=0.95),
                 mid=(46, 58, 82), mid_a=0.92, near=(10, 12, 20), mist=(215, 228, 242)),
    "forest": dict(src="bamboo_bg.jpg", grade=dict(desat=0.10, contrast=0.85, fog=(170, 190, 180), fog_amt=0.15, bright=0.95),
                   mid=(44, 62, 60), mid_a=0.9, near=(8, 14, 12), mist=(210, 225, 215)),
    "boss": dict(src="boss_bg.jpg", grade=dict(desat=0.0, contrast=0.9, fog=(90, 20, 26), fog_amt=0.10, bright=1.0),
                 mid=(38, 8, 12), mid_a=0.94, near=(10, 2, 4), mist=(160, 50, 50)),
}


def level_layers():
    # skies are per-theme paintings; far/mid/near are shared white silhouettes tinted in code
    for th, cfg in THEMES.items():
        sky = grade(load_rgba(cfg["src"]), **cfg["grade"])
        save(sky, f"{NA2}/{th}_sky.png")
    save(mist_band(color=(255, 255, 255), alpha=1.0, y0=0.52, seed=4), f"{NA2}/shared_far.png")
    save(silhouette_layer("sil_mid.jpg", (255, 255, 255), 1.0, True, yshift=40), f"{NA2}/shared_mid.png")
    save(silhouette_layer("sil_near.jpg", (255, 255, 255), 1.0, False, yshift=10), f"{NA2}/shared_near.png")


def lantern(W=48, H=88):
    out = blank(W, H)
    body = ss_mask(W, H, lambda d, s: d.ellipse([4 * s, 14 * s, (W - 4) * s, (H - 14) * s], fill=255))
    out = over(out, glow(body, 8, (255, 140, 60), 0.6))
    hf = heightfield(body, 16, 2, dome=True)
    lam, sp = shade(hf, 0.5)
    t = np.clip(0.35 + lam * 0.6, 0, 1)
    col = np.array([150, 20, 16], np.float32) * (1 - t[..., None]) + np.array([255, 150, 70], np.float32) * t[..., None]
    out = over(out, np.concatenate([col, (body * 255)[..., None]], -1))
    for y in range(20, H - 16, 7):
        rib = rect_mask(W, H, 0, y, W, y + 1.2) * body
        out = over(out, flat(rib, (90, 10, 8), 0.55))
    caps = np.maximum(rect_mask(W, H, 12, 8, W - 12, 18, 2), rect_mask(W, H, 12, H - 18, W - 12, H - 8, 2))
    out = over(out, metal(caps, IRON, width=2))
    out = over(out, metal(rect_mask(W, H, W / 2 - 1.5, 0, W / 2 + 1.5, 9), IRON, width=1))
    tas = rect_mask(W, H, W / 2 - 2, H - 9, W / 2 + 2, H - 1)
    out = over(out, flat(tas, (60, 8, 6), 0.9))
    return out


if want("sprites"):
    player_sprites()
    save(lantern(48, 88), f"{SPR}/paper_lantern.png", (24, 44))
    save(koban(64), f"{SPR}/coin.png", (32, 32))
if want("hero"):
    a = hero_menu()
    portrait(a)
if want("bg"):
    save(load_rgba("title_bg.jpg"), f"{UI}/menu_bg.png")
    level_layers()
print("done3")
