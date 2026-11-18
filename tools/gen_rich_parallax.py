#!/usr/bin/env python3
"""Rich art pass: per-scenario painted parallax plates (original, procedural).
Writes assets/parallax/<key>/{sky,far,mid,near}.webp (q95 sources; imported lossy q0.97)
  sky  1600x900  (drawn at 0.8 -> 1280x720, static)
  far/mid/near 3072x864, seamless horizontally (drawn at 0.8333 -> 2560x720)
Painterly look: periodic fbm texture, atmospheric perspective, rim light, glow lights."""
import os, sys, math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W, H = 3072, 864
SW, SH = 1600, 900
OUT = "assets/parallax"

def C(h):  # hex -> float rgb
    h = h.lstrip("#"); return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])

# ---------------------------------------------------------------- noise
def pnoise(w, h, cells, seed, wrap=True):
    """periodic (in x) smooth value noise in [0,1]"""
    rng = np.random.default_rng(seed)
    gw, gh = max(2, int(cells)), max(2, int(cells * h / w) + 2)
    g = rng.random((gh, gw)).astype(np.float32)
    big = np.tile(g, (1, 3)) if wrap else g
    im = Image.fromarray((big * 255).astype(np.uint8)).resize((w * 3 if wrap else w, h), Image.BICUBIC)
    a = np.asarray(im, np.float32) / 255.0
    return a[:, w:2 * w] if wrap else a

def fbm(w, h, base, seed, oct=5, wrap=True):
    acc = np.zeros((h, w), np.float32); amp = 1.0; tot = 0
    for o in range(oct):
        acc += amp * pnoise(w, h, base * 2 ** o, seed + o * 17, wrap); tot += amp; amp *= 0.5
    return acc / tot

def ridge1d(w, base, seed, oct=6):
    rng = np.random.default_rng(seed); x = np.arange(w); acc = np.zeros(w); amp = 1; tot = 0
    for o in range(oct):
        n = int(base * 2 ** o); v = rng.random(n)
        xs = x * n / w; i0 = np.floor(xs).astype(int); f = xs - i0; f = f * f * (3 - 2 * f)
        acc += amp * (v[i0 % n] * (1 - f) + v[(i0 + 1) % n] * f); tot += amp; amp *= 0.5
    return acc / tot

# ---------------------------------------------------------------- wrapped drawing
class Canvas:
    def __init__(s, w=W, h=H):
        s.w, s.h = w, h; s.m = Image.new("L", (w, h), 0); s.d = ImageDraw.Draw(s.m); s.lights = []
    def poly(s, pts, v=255):
        for o in (-s.w, 0, s.w): s.d.polygon([(x + o, y) for x, y in pts], fill=v)
    def rect(s, x0, y0, x1, y1, v=255):
        for o in (-s.w, 0, s.w): s.d.rectangle([x0 + o, y0, x1 + o, y1], fill=v)
    def ell(s, x0, y0, x1, y1, v=255):
        for o in (-s.w, 0, s.w): s.d.ellipse([x0 + o, y0, x1 + o, y1], fill=v)
    def line(s, pts, wd, v=255):
        for o in (-s.w, 0, s.w): s.d.line([(x + o, y) for x, y in pts], fill=v, width=int(wd))
    def light(s, x, y, r, col, k=1.0): s.lights.append((x % s.w, y, r, col, k))
    def arr(s): return np.asarray(s.m, np.float32) / 255.0

# ---------------------------------------------------------------- motifs
def foliage(c, cx, cy, rx, ry, rng, n=26):
    for k in range(n):
        a = rng.random() * 2 * math.pi; d = rng.random() ** 0.6
        px, py = cx + math.cos(a) * rx * d, cy + math.sin(a) * ry * d * 0.8
        r = (rx + ry) * (0.12 + rng.random() * 0.12)
        c.poly([(px + math.cos(t) * r * (0.7 + 0.5 * rng.random()), py + math.sin(t) * r * 0.55 * (0.7 + 0.5 * rng.random())) for t in np.linspace(0, 2 * math.pi, 9)[:-1]])

def m_ridge(c, base_y, amp, base, seed, oct=6, sharp=1.0, ridged=False):
    r = ridge1d(c.w, base, seed, oct)
    if ridged:
        r2 = 1 - np.abs(ridge1d(c.w, base * 2, seed + 3, oct) * 2 - 1)
        r = np.clip(0.55 * r + 0.6 * r2 ** 1.6, 0, 1); r = (r - r.min()) / (r.max() - r.min() + 1e-6)
    if sharp != 1.0: r = 1 - np.abs(r * 2 - 1) ** sharp if sharp < 1 else r ** sharp
    ys = base_y - r * amp
    pts = [(x, ys[x]) for x in range(0, c.w, 4)] + [(c.w, ys[0]), (c.w, c.h), (0, c.h)]
    c.d.polygon(pts, fill=255)

def roof(c, cx, y, w, h, curl=0.18):
    hw = w / 2; e = w * curl
    pts = [(cx - hw - e * 0.6, y + h * 0.15), (cx - hw, y + h), (cx + hw, y + h), (cx + hw + e * 0.6, y + h * 0.15),
           (cx + hw * 0.55, y + h * 0.35), (cx + hw * 0.25, y), (cx - hw * 0.25, y), (cx - hw * 0.55, y + h * 0.35)]
    c.poly(pts)

def m_house(c, x, ground, w, h, rng, lightcol=None):
    c.rect(x - w / 2, ground - h, x + w / 2, ground + 40)
    roof(c, x, ground - h - h * 0.45, w * 1.25, h * 0.5)
    if rng.random() < 0.5: roof(c, x, ground - h * 1.75, w * 0.8, h * 0.35)
    if lightcol is not None:
        for k in range(rng.integers(1, 3)):
            wx = x - w / 2 + w * (0.25 + 0.5 * rng.random()); wy = ground - h * (0.35 + 0.3 * rng.random())
            c.light(wx, wy, 8 + rng.random() * 8, lightcol, 0.9)

def m_pagoda(c, x, ground, w, tiers, th, lightcol=None):
    y = ground
    for t in range(tiers):
        ww = w * (1 - t * 0.12)
        c.rect(x - ww * 0.32, y - th, x + ww * 0.32, y)
        roof(c, x, y - th - th * 0.35, ww, th * 0.55, 0.22)
        if lightcol is not None: c.light(x, y - th * 0.45, 7, lightcol, 0.8)
        y -= th * 1.05
    c.line([(x, y + th * 0.3), (x, y - th * 1.6)], max(3, w * 0.03))

def m_torii(c, x, ground, w, h):
    pw = w * 0.07
    c.rect(x - w * 0.36 - pw / 2, ground - h, x - w * 0.36 + pw / 2, ground)
    c.rect(x + w * 0.36 - pw / 2, ground - h, x + w * 0.36 + pw / 2, ground)
    c.rect(x - w * 0.45, ground - h * 0.78, x + w * 0.45, ground - h * 0.72)
    c.poly([(x - w * 0.58, ground - h * 1.02), (x - w * 0.5, ground - h * 0.9), (x + w * 0.5, ground - h * 0.9),
            (x + w * 0.58, ground - h * 1.02), (x, ground - h * 0.95)])

def m_pine(c, x, ground, h, rng, w=None):
    w = w or h * 0.42; tiers = 5 + int(rng.integers(0, 3))
    c.rect(x - w * 0.04, ground - h * 0.25, x + w * 0.04, ground)
    for t in range(tiers):
        f = t / tiers; ty = ground - h * (0.18 + f * 0.82); tw = w * (1 - f * 0.8) * (0.85 + rng.random() * 0.3)
        c.poly([(x - tw / 2, ty + h * 0.16), (x + tw / 2, ty + h * 0.16), (x + tw * 0.08, ty - h * 0.05), (x, ty - h * 0.12), (x - tw * 0.08, ty - h * 0.05)])

def m_cedar(c, x, ground, h, rng, w):
    c.rect(x - w / 2, ground - h, x + w / 2, ground)
    for k in range(4):
        by = ground - h * (0.45 + 0.13 * k); bl = w * (2 + rng.random() * 3) * (1 if k % 2 else -1)
        c.line([(x, by), (x + bl, by - w * 1.5)], max(2, w * 0.25))
        foliage(c, x + bl, by - w * 1.8, w * 2.6, w * 1.3, rng, 14)

def m_bamboo(c, x, ground, h, w, rng, lean):
    segs = 10; pts = []
    for i in range(segs + 1):
        f = i / segs; pts.append((x + lean * f * f * h, ground - f * h))
    for i in range(segs):
        (x0, y0), (x1, y1) = pts[i], pts[i + 1]
        c.poly([(x0 - w / 2, y0), (x0 + w / 2, y0), (x1 + w / 2, y1 + 3), (x1 - w / 2, y1 + 3)])
        c.rect(x1 - w * 0.75, y1, x1 + w * 0.75, y1 + max(2, w * 0.25))
        if rng.random() < 0.3 and i > 3:
            d = 1 if rng.random() < 0.5 else -1; L = min(70, w * 4.5)
            for k in range(3):
                ang = (0.25 + k * 0.35) * d
                tx, ty = x1 + d * L * math.cos(ang * 0.6), y1 + L * (0.15 + 0.35 * k)
                mx, my = (x1 + tx) / 2, (y1 + ty) / 2; nx, ny = -(ty - y1), (tx - x1); nl = math.hypot(nx, ny) + 1e-6
                ww = L * 0.09
                c.poly([(x1, y1), (mx + nx / nl * ww, my + ny / nl * ww), (tx, ty), (mx - nx / nl * ww, my - ny / nl * ww)])

def m_willow(c, x, ground, h, rng):
    c.poly([(x - 14, ground), (x + 14, ground), (x + 6, ground - h * 0.6), (x - 6, ground - h * 0.6)])
    cx, cy = x, ground - h * 0.65
    foliage(c, cx, cy - h * 0.08, h * 0.3, h * 0.16, rng, 30)
    for k in range(40):
        sx = cx + (rng.random() - 0.5) * h * 0.7; L = h * (0.25 + rng.random() * 0.5)
        c.line([(sx, cy), (sx + (rng.random() - 0.5) * 20, cy + L)], 3)

def m_boat(c, x, y, w, lightcol=None):
    c.poly([(x - w / 2, y), (x + w / 2, y), (x + w * 0.4, y + w * 0.12), (x - w * 0.42, y + w * 0.12)])
    c.rect(x - w * 0.15, y - w * 0.18, x + w * 0.15, y)
    roof(c, x, y - w * 0.26, w * 0.42, w * 0.1)
    if lightcol is not None: c.light(x + w * 0.42, y - w * 0.15, 10, lightcol, 1.0)

def m_lanterns(c, x0, x1, y, sag, n, col, size=14):
    pts = []
    for i in range(41):
        f = i / 40; pts.append((x0 + (x1 - x0) * f, y + sag * 4 * f * (1 - f)))
    c.line(pts, 2)
    for i in range(1, n + 1):
        f = i / (n + 1); lx = x0 + (x1 - x0) * f; ly = y + sag * 4 * f * (1 - f) + size * 0.8
        c.ell(lx - size * 0.6, ly - size * 0.8, lx + size * 0.6, ly + size * 0.8)
        c.light(lx, ly, size * 1.6, col, 1.0)

def m_arch(c, x, top, w, h, rng):
    """cave arch hanging from the top + stalactites"""
    pts = [(x - w / 2, 0)]
    for i in range(21):
        f = i / 20; pts.append((x - w / 2 + w * f, top + h * math.sin(math.pi * f) ** 0.6 * (0.9 + 0.2 * rng.random())))
    pts.append((x + w / 2, 0)); c.poly(pts)
    for k in range(int(w / 50)):
        sx = x - w / 2 + rng.random() * w; sy = top + h * 0.6 * rng.random(); L = 30 + rng.random() * 120
        c.poly([(sx - 10, sy), (sx + 10, sy), (sx, sy + L)])

def m_rocks(c, base_y, amp, seed, base=8):
    m_ridge(c, base_y, amp, base, seed, 6)

def m_hall(c, x, ground, w, h, lightcol):
    c.rect(x - w / 2, ground - h, x + w / 2, ground + 30)
    roof(c, x, ground - h - h * 0.5, w * 1.3, h * 0.6, 0.2)
    roof(c, x, ground - h * 1.9, w * 0.75, h * 0.45, 0.22)
    for k in range(6):
        c.light(x - w * 0.4 + k * w * 0.16, ground - h * 0.45, 9, lightcol, 0.8)

def m_statue(c, x, ground, h, rng):
    w = h * 0.4
    c.rect(x - w * 0.6, ground - h * 0.15, x + w * 0.6, ground)
    c.poly([(x - w / 2, ground - h * 0.15), (x + w / 2, ground - h * 0.15), (x + w * 0.35, ground - h * 0.75), (x - w * 0.4, ground - h * 0.7)])
    if rng.random() < 0.6: c.ell(x - w * 0.25, ground - h * 0.95, x + w * 0.2, ground - h * 0.7)
    else: c.poly([(x - w * 0.4, ground - h * 0.7), (x + w * 0.2, ground - h * 0.85), (x + w * 0.35, ground - h * 0.75)])

def m_censer(c, x, ground, h, col):
    c.rect(x - 8, ground - h, x + 8, ground)
    c.poly([(x - 34, ground - h), (x + 34, ground - h), (x + 22, ground - h - 30), (x - 22, ground - h - 30)])
    roof(c, x, ground - h - 50, 70, 22)
    c.light(x, ground - h - 15, 26, col, 1.0)

def m_deadtree(c, x, ground, h, rng):
    def br(x0, y0, ang, L, wd, d):
        x1 = x0 + math.cos(ang) * L; y1 = y0 - math.sin(ang) * L
        c.line([(x0, y0), (x1, y1)], wd)
        if d > 0:
            for s in (-1, 1):
                br(x1, y1, ang + s * (0.35 + rng.random() * 0.4), L * (0.6 + rng.random() * 0.2), max(1, wd * 0.65), d - 1)
    br(x, ground, math.pi / 2 + (rng.random() - 0.5) * 0.3, h * 0.38, max(4, h * 0.05), 5)

# ---------------------------------------------------------------- compositing
def shade(mask, base, rng_seed, tex=0.22, top_light=None, rim=None, rim_px=3, grad=(1.0, 0.75), haze=None, haze_amt=0.0):
    h, w = mask.shape
    n = fbm(w, h, 24, rng_seed, 5); n2 = fbm(w, h, 160, rng_seed + 99, 3)
    v = (1 - tex) + tex * 2 * (0.65 * n + 0.35 * n2)
    yy = np.linspace(grad[0], grad[1], h)[:, None]
    rgb = base[None, None, :] * (v * yy)[..., None]
    if rim is not None:
        sh = np.roll(np.roll(mask, rim_px, 0), -rim_px // 2, 1)
        edge = np.clip(mask - sh, 0, 1)
        edge = np.asarray(Image.fromarray((edge * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2)), np.float32) / 255
        rgb = rgb + rim[None, None, :] * edge[..., None] * 0.9
    if haze is not None and haze_amt > 0:
        hz = np.clip((np.arange(h)[:, None] / h - 0.45) / 0.55, 0, 1) * haze_amt
        rgb = rgb * (1 - hz[..., None]) + haze[None, None, :] * hz[..., None]
    return rgb

def add_lights(rgb, alpha, lights, w, h, scale=1.0):
    if not lights: return rgb, alpha
    glow = np.zeros((h, w, 3), np.float32); ga = np.zeros((h, w), np.float32)
    for (x, y, r, col, k) in lights:
        R = int(r * 4 * scale) + 2
        x0, x1 = int(x - R), int(x + R); y0, y1 = max(0, int(y - R)), min(h, int(y + R))
        if y1 <= y0: continue
        yy, xx = np.mgrid[y0:y1, x0:x1]
        d2 = ((xx - x) ** 2 + (yy - y) ** 2) / (r * scale) ** 2
        g = np.exp(-d2 * 0.5) * k * 0.55 + np.exp(-d2 * 4) * k
        xs = np.mod(xx, w)
        np.add.at(glow, (yy, xs), g[..., None] * col[None, None, :])
        np.maximum.at(ga, (yy, xs), np.clip(g * 0.85, 0, 1))
    rgb = rgb + glow
    alpha = np.maximum(alpha, ga)
    return rgb, alpha

def save(rgb, alpha, path):
    rgb = np.clip(rgb, 0, 1)
    arr = np.dstack([rgb, np.clip(alpha, 0, 1)[..., None]]) if alpha is not None else rgb
    Image.fromarray((arr * 255 + 0.5).astype(np.uint8)).save(path.replace(".png", ".webp"), quality=95, method=6)

def soften(mask, r=1.0):
    return np.asarray(Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r)), np.float32) / 255

# ---------------------------------------------------------------- sky
def make_sky(P, seed):
    h, w = SH, SW
    y = np.linspace(0, 1, h)[:, None]
    top, mid, hor = C(P["sky"][0]), C(P["sky"][1]), C(P["sky"][2])
    t1 = np.clip(y / 0.6, 0, 1); t2 = np.clip((y - 0.6) / 0.4, 0, 1)
    sky = (top * (1 - t1)[..., None] + mid * t1[..., None]) * (1 - t2)[..., None] + hor * t2[..., None]
    sky = np.broadcast_to(sky, (h, w, 3)).copy()
    rng = np.random.default_rng(seed)
    if P.get("stars"):
        n = rng.random((h, w)); st = (n > 0.9985) * (1 - y) ** 1.5
        st = np.asarray(Image.fromarray((st * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.7)), np.float32) / 255 * 2.5
        sky += st[..., None] * np.array([0.9, 0.95, 1.0])
    # celestial body
    cx, cy, cr = P["orb"][0] * w, P["orb"][1] * h, P["orb"][2]
    oc = C(P["orb"][3])
    yy, xx = np.mgrid[0:h, 0:w]; d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    glow = np.exp(-(d / (cr * 4.5)) ** 2) * 0.55 + np.exp(-(d / (cr * 12)) ** 2) * 0.25
    sky += glow[..., None] * oc
    disk = np.clip((cr - d) / 2.0, 0, 1)
    tex = fbm(w, h, 60, seed + 5, 4, wrap=False)
    sky = sky * (1 - disk[..., None]) + (oc * (0.86 + 0.28 * tex)[..., None]) * disk[..., None]
    # clouds: horizontally stretched fbm bands
    cl = fbm(w, h, 6, seed + 11, 6, wrap=False)
    cl = np.asarray(Image.fromarray((cl * 255).astype(np.uint8)).resize((w // 3, h)).resize((w, h), Image.BICUBIC), np.float32) / 255
    band = np.exp(-((y - P.get("cloud_y", 0.45)) / 0.22) ** 2)
    ca = np.clip((cl - 0.5) * 3.2, 0, 1) * band * P.get("cloud_amt", 0.6)
    ccol = C(P.get("cloud", P["sky"][1]))
    lit = np.exp(-(d / (cr * 7)) ** 2)[..., None] * oc * 0.5
    sky = sky * (1 - ca[..., None]) + (ccol + lit) * ca[..., None]
    # painterly grain
    g = fbm(w, h, 220, seed + 21, 2, wrap=False)
    sky *= (0.97 + 0.06 * g)[..., None]
    return sky

# ---------------------------------------------------------------- scenario definitions
def build(key, P, seed=1):
    rng = np.random.default_rng(seed)
    os.makedirs(f"{OUT}/{key}", exist_ok=True)
    save(make_sky(P, seed), None, f"{OUT}/{key}/sky.png")
    lc = C(P["light"])
    layers = {}
    for li, name in enumerate(["far", "mid", "near"]):
        c = Canvas()
        P["draw"][name](c, rng, lc)
        m = soften(c.arr(), 0.8 if name != "far" else 1.4)
        base = C(P[name][0]); rimc = C(P[name][1]) if P[name][1] else None
        if name == "far":
            rgb = shade(m, base, seed + li * 7, tex=0.18, rim=rimc, rim_px=2, grad=(1.05, 0.85), haze=C(P["sky"][2]), haze_amt=0.55)
            a = m * P.get("far_a", 0.92)
        elif name == "mid":
            rgb = shade(m, base, seed + li * 7, tex=0.26, rim=rimc, rim_px=3, grad=(1.0, 0.7), haze=C(P["sky"][2]), haze_amt=0.3)
            a = m
        else:
            rgb = shade(m, base, seed + li * 7, tex=0.3, rim=rimc, rim_px=4, grad=(1.0, 0.6))
            a = m
        rgb, a = add_lights(rgb, a, c.lights, W, H)
        save(rgb, a, f"{OUT}/{key}/{name}.png")
    print("built", key)

GROUND = 864  # bottom of plate (plates are drawn from screen top; gameplay floor is ~ 0.8 * 864)

def D_snow_village():
    def far(c, r, lc):
        m_ridge(c, 600, 420, 3, 11, 7, ridged=True)
    def mid(c, r, lc):
        m_ridge(c, 700, 110, 6, 12, 5)
        for x in np.arange(80, W, 200):
            x += r.random() * 120
            if r.random() < 0.55: m_house(c, x, 640 + r.random() * 30, 130 + r.random() * 60, 80 + r.random() * 30, r, lc); c.light(x, 600, 30, lc, 0.25)
            else: m_pine(c, x, 660, 200 + r.random() * 160, r)
        m_pagoda(c, 1500, 640, 170, 4, 70, lc)
    def near(c, r, lc):
        m_ridge(c, 845, 60, 10, 13, 5)
        for x in np.arange(0, W, 330):
            m_pine(c, x + r.random() * 160, 860, 300 + r.random() * 220, r)
        m_torii(c, 2300, 840, 260, 300)
    return dict(sky=["#0b1426", "#2a3d63", "#8a9cc0"], orb=(0.72, 0.2, 46, "#f2f0e6"), stars=True, cloud="#56688c", cloud_amt=0.5,
                light="#ffb860", far=["#7d8db0", "#dfe8ff"], mid=["#3a4b6c", "#cfdcff"], near=["#1c2638", "#e8f0ff"],
                draw=dict(far=far, mid=mid, near=near))

def D_mist_forest():
    def far(c, r, lc):
        m_ridge(c, 600, 360, 4, 21, 6, ridged=True)
        for x in np.arange(0, W, 70): m_pine(c, x + r.random() * 40, 600 + r.random() * 40, 150 + r.random() * 90, r)
    def mid(c, r, lc):
        for x in np.arange(0, W, 150): m_cedar(c, x + r.random() * 80, 760, 640 + r.random() * 100, r, 18 + r.random() * 12)
        m_ridge(c, 760, 40, 8, 22, 4)
        m_torii(c, 1200, 740, 180, 210)
        for x in (1080, 1320): c.light(x, 690, 12, lc, 1.0)
    def near(c, r, lc):
        for x in np.arange(0, W, 760): m_cedar(c, x + r.random() * 300, 864, 900, r, 34 + r.random() * 16)
        m_ridge(c, 850, 50, 12, 23, 5)
    return dict(sky=["#1e2b2a", "#5f7a72", "#c6d4c4"], orb=(0.3, 0.25, 70, "#fff6dc"), stars=False, cloud="#a9bbb0", cloud_amt=0.7, cloud_y=0.55,
                light="#ffcf7a", far=["#9fb3a7", "#f0fff4"], mid=["#3e5a50", "#c8e8c0"], near=["#1a2b25", "#a8d090"],
                draw=dict(far=far, mid=mid, near=near))

def D_gion():
    def far(c, r, lc):
        m_ridge(c, 560, 300, 3, 31, 6, ridged=True)
        m_pagoda(c, 900, 470, 150, 5, 52, lc); m_pagoda(c, 2400, 480, 120, 3, 50, lc)
    def mid(c, r, lc):
        x = 0
        while x < W:
            w = 140 + r.random() * 120; m_house(c, x + w / 2, 680 + r.random() * 40, w, 90 + r.random() * 60, r, lc); x += w + 10
        c.rect(0, 740, W, H)
        for k in range(5):
            x0 = r.random() * W; m_lanterns(c, x0, x0 + 300, 520, 50, 5, lc, 12)
    def near(c, r, lc):
        x = 0
        while x < W:
            w = 180 + r.random() * 120
            if r.random() < 0.7: m_house(c, x + w / 2, 900, w, 60 + r.random() * 40, r, lc)
            x += w + 260 + r.random() * 300
        for k in range(3):
            x0 = r.random() * W; m_lanterns(c, x0, x0 + 420, 560, 70, 6, lc, 16)
    return dict(sky=["#070b1c", "#1c2550", "#6a5a8a"], orb=(0.62, 0.17, 40, "#ffe9c4"), stars=True, cloud="#3a3f70", cloud_amt=0.45,
                light="#ff9a4a", far=["#4c5480", "#c9c2ff"], mid=["#232a4c", "#ffb37a"], near=["#121630", "#ffb880"],
                draw=dict(far=far, mid=mid, near=near))

def D_bamboo():
    def far(c, r, lc):
        m_ridge(c, 620, 340, 4, 41, 6, ridged=True)
        for x in np.arange(0, W, 22): m_bamboo(c, x + r.random() * 12, 760, 500 + r.random() * 260, 6, r, (r.random() - 0.5) * 0.15)
    def mid(c, r, lc):
        for x in np.arange(0, W, 70): m_bamboo(c, x + r.random() * 40, 800, 700 + r.random() * 160, 13, r, (r.random() - 0.5) * 0.2)
        m_ridge(c, 800, 40, 10, 42, 4)
    def near(c, r, lc):
        for x in np.arange(0, W, 520): m_bamboo(c, x + r.random() * 260, 870, 900, 24, r, (r.random() - 0.5) * 0.25)
        m_ridge(c, 860, 40, 14, 43, 5)
    return dict(sky=["#6f9a6a", "#c8d9a0", "#f4ecc8"], orb=(0.25, 0.22, 60, "#fff8e0"), stars=False, cloud="#e6ecd0", cloud_amt=0.5,
                light="#ffe0a0", far=["#a7bf8a", "#f8ffe0"], mid=["#4e7040", "#e4ffb0"], near=["#24381e", "#c8f090"],
                draw=dict(far=far, mid=mid, near=near))

def D_cave():
    def far(c, r, lc):
        m_ridge(c, 760, 300, 5, 51, 6)
        for x in (700, 2100):
            for k in range(14): c.line([(x + k * 6, 0), (x + k * 6 + r.random() * 6, 760)], 3, 120)
            c.light(x + 40, 720, 60, lc, 0.7)
        m_arch(c, W / 2, 0, W * 1.2, 160, r)
    def mid(c, r, lc):
        for x in np.arange(0, W, 900): m_arch(c, x + 300, 0, 800, 260 + r.random() * 120, r)
        m_ridge(c, 820, 130, 6, 52, 5)
        for k in range(12): c.light(r.random() * W, 300 + r.random() * 400, 10, lc, 0.9)
    def near(c, r, lc):
        for x in np.arange(0, W, 1100): m_arch(c, x + 500, 0, 700, 170 + r.random() * 80, r)
        m_ridge(c, 870, 70, 9, 53, 5)
    return dict(sky=["#03080c", "#0e2630", "#1f4a52"], orb=(0.5, -0.4, 10, "#7fe0d0"), stars=False, cloud="#1a3c40", cloud_amt=0.4, cloud_y=0.7,
                light="#6ff0d8", far=["#24484e", "#8af0e0"], mid=["#132a30", "#70d8c8"], near=["#0a161a", "#5fb8b0"],
                draw=dict(far=far, mid=mid, near=near), far_a=0.95)

def D_shrine():
    def far(c, r, lc):
        m_ridge(c, 600, 340, 3, 61, 6, ridged=True)
        m_pagoda(c, 1600, 560, 220, 5, 70, lc)
    def mid(c, r, lc):
        m_ridge(c, 760, 60, 6, 62, 4)
        for x in np.arange(150, W, 520): m_torii(c, x + r.random() * 120, 760, 240, 280)
        for x in np.arange(400, W, 700): m_hall(c, x, 740, 260, 110, lc)
    def near(c, r, lc):
        for x in np.arange(0, W, 600): m_deadtree(c, x + r.random() * 300, 880, 520, r)
        m_ridge(c, 860, 50, 12, 63, 5)
        for k in range(6): c.light(r.random() * W, 800 + r.random() * 50, 30, lc, 0.8)
    return dict(sky=["#1a0604", "#5a1a0e", "#d0602a"], orb=(0.75, 0.3, 50, "#ffb060"), stars=False, cloud="#40150e", cloud_amt=0.7, cloud_y=0.4,
                light="#ff7a2a", far=["#7a3222", "#ffb070"], mid=["#3a120c", "#ff8a40"], near=["#1c0806", "#ff7030"],
                draw=dict(far=far, mid=mid, near=near))

def D_canal():
    def far(c, r, lc):
        m_ridge(c, 560, 300, 3, 71, 6, ridged=True)
        x = 0
        while x < W: w = 90 + r.random() * 90; m_house(c, x + w / 2, 560, w, 60 + r.random() * 40, r, lc); x += w + 30
    def mid(c, r, lc):
        for x in np.arange(100, W, 480): m_willow(c, x + r.random() * 160, 730, 420 + r.random() * 120, r)
        c.rect(0, 730, W, 760)
        for x in np.arange(300, W, 700): m_boat(c, x + r.random() * 200, 760, 220, lc)
        for k in range(18):
            x = r.random() * W; c.light(x, 790 + r.random() * 50, 14, lc, 0.45)
    def near(c, r, lc):
        m_ridge(c, 860, 30, 14, 73, 4)
        for x in np.arange(200, W, 900): m_willow(c, x + r.random() * 300, 870, 760, r)
        m_lanterns(c, 600, 1200, 380, 80, 6, lc, 16)
    return dict(sky=["#050a18", "#16284a", "#3c5878"], orb=(0.35, 0.18, 44, "#e8eeff"), stars=True, cloud="#26385a", cloud_amt=0.5,
                light="#ffb050", far=["#3c4c70", "#a8c0ff"], mid=["#18243e", "#9ab8ff"], near=["#0c1424", "#a0b8f0"],
                draw=dict(far=far, mid=mid, near=near))

def D_pagoda():
    def far(c, r, lc):
        m_ridge(c, 640, 520, 3, 81, 7, ridged=True)
    def mid(c, r, lc):
        m_ridge(c, 740, 200, 5, 82, 6)
        for x in np.arange(400, W, 1000): m_pagoda(c, x + r.random() * 200, 600 + r.random() * 60, 200, 5, 64, None)
        for x in np.arange(0, W, 120): m_pine(c, x + r.random() * 60, 760, 120 + r.random() * 80, r)
    def near(c, r, lc):
        m_ridge(c, 860, 90, 9, 83, 5)
        for x in np.arange(0, W, 380): m_pine(c, x + r.random() * 200, 880, 360 + r.random() * 200, r)
    return dict(sky=["#5c88b8", "#a8c8e8", "#eef4fa"], orb=(0.8, 0.16, 54, "#fffef0"), stars=False, cloud="#f4f8ff", cloud_amt=0.6,
                light="#fff0c0", far=["#c4d4e8", "#ffffff"], mid=["#6e88a8", "#f4faff"], near=["#2e3e56", "#e8f4ff"],
                draw=dict(far=far, mid=mid, near=near), far_a=0.85)

def D_palace():
    def far(c, r, lc):
        m_ridge(c, 560, 280, 3, 91, 6, ridged=True)
        m_hall(c, 1536, 520, 700, 140, lc)
    def mid(c, r, lc):
        m_ridge(c, 760, 40, 6, 92, 4)
        for x in np.arange(200, W, 760): m_hall(c, x + r.random() * 100, 730, 340, 120, lc)
        for k in range(4): x0 = r.random() * W; m_lanterns(c, x0, x0 + 360, 470, 50, 5, lc, 12)
    def near(c, r, lc):
        for x in np.arange(0, W, 700): m_deadtree(c, x + r.random() * 300, 880, 560, r)
        m_ridge(c, 860, 40, 12, 93, 5)
    return dict(sky=["#0c0620", "#2c1a58", "#8a5a9a"], orb=(0.22, 0.2, 52, "#ffe8c0"), stars=True, cloud="#3e2a6a", cloud_amt=0.5,
                light="#ffcc55", far=["#58407a", "#ffd890"], mid=["#2a1a46", "#ffcf70"], near=["#140c26", "#ffc0e0"],
                draw=dict(far=far, mid=mid, near=near))

def D_boss_rin():
    def far(c, r, lc):
        m_ridge(c, 600, 320, 3, 101, 6, ridged=True); m_pagoda(c, 1100, 560, 180, 5, 60, None)
    def mid(c, r, lc):
        for x in np.arange(0, W, 260): m_pine(c, x + r.random() * 120, 760, 300 + r.random() * 200, r)
        m_ridge(c, 770, 50, 8, 102, 4)
    def near(c, r, lc):
        for x in np.arange(0, W, 800): m_deadtree(c, x + r.random() * 300, 880, 600, r)
        m_ridge(c, 865, 40, 12, 103, 5)
    return dict(sky=["#12030a", "#4a0a14", "#b02a26"], orb=(0.5, 0.3, 120, "#ff3a2a"), stars=False, cloud="#2a050a", cloud_amt=0.5,
                light="#ff5a3a", far=["#5a1018", "#ff6050"], mid=["#24060a", "#ff5040"], near=["#120305", "#ff4030"],
                draw=dict(far=far, mid=mid, near=near))

def D_boss_gorrah():
    def far(c, r, lc):
        m_ridge(c, 660, 480, 4, 111, 7, ridged=True)
    def mid(c, r, lc):
        m_ridge(c, 760, 160, 7, 112, 5)
        for x in np.arange(200, W, 500): m_statue(c, x + r.random() * 200, 760, 240 + r.random() * 120, r)
    def near(c, r, lc):
        m_ridge(c, 860, 100, 10, 113, 6)
        for x in np.arange(300, W, 1100): m_statue(c, x, 880, 520, r)
    return dict(sky=["#3a2410", "#8a5a2a", "#e0b070"], orb=(0.7, 0.24, 64, "#fff0c0"), stars=False, cloud="#b08050", cloud_amt=0.8, cloud_y=0.5,
                light="#ffd080", far=["#a87a4a", "#ffe0a0"], mid=["#5a3a1e", "#ffc070"], near=["#2a1a0c", "#e0a060"],
                draw=dict(far=far, mid=mid, near=near))

def D_boss_vey():
    def far(c, r, lc):
        m_ridge(c, 600, 320, 3, 121, 6, ridged=True); m_hall(c, 1500, 560, 520, 120, lc)
    def mid(c, r, lc):
        m_ridge(c, 770, 50, 7, 122, 4)
        for x in np.arange(200, W, 420): m_censer(c, x + r.random() * 120, 770, 160 + r.random() * 60, lc)
    def near(c, r, lc):
        for x in np.arange(0, W, 900): m_deadtree(c, x + r.random() * 300, 880, 520, r)
        m_ridge(c, 865, 40, 12, 123, 5)
    return dict(sky=["#0a0614", "#2e1648", "#7a4a9a"], orb=(0.6, 0.22, 48, "#e0c0ff"), stars=True, cloud="#5a3a7a", cloud_amt=0.8, cloud_y=0.5,
                light="#c080ff", far=["#5a3e7a", "#e0c0ff"], mid=["#2a1a40", "#c890ff"], near=["#140c20", "#b080f0"],
                draw=dict(far=far, mid=mid, near=near))

SCEN = {"snow_village": D_snow_village, "mist_forest": D_mist_forest, "gion": D_gion, "bamboo": D_bamboo, "cave": D_cave,
        "shrine": D_shrine, "canal": D_canal, "pagoda": D_pagoda, "palace": D_palace,
        "boss_rin": D_boss_rin, "boss_gorrah": D_boss_gorrah, "boss_vey": D_boss_vey}

if __name__ == "__main__":
    keys = sys.argv[1:] or list(SCEN)
    for i, k in enumerate(keys): build(k, SCEN[k](), seed=1000 + list(SCEN).index(k) * 13)
