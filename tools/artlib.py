"""Shared helpers for the Shadow Ninja art pass (original + CC0 Kenney chrome).
Procedural materials: forged gold/steel/iron bevels, lacquer discs, faceted gems."""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from scipy import ndimage as ndi
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEN = os.path.join(ROOT, "third_party", "kenney_src")
SRC = os.path.join(ROOT, "art_src")
FONT_SERIF_B = os.path.join(ROOT, "content/original/fonts/SourceSerifPro-Bold.ttf")
rng = np.random.default_rng(7)

GOLD = [(0.0, (28, 14, 3)), (0.28, (88, 52, 12)), (0.48, (156, 106, 34)), (0.66, (210, 162, 72)), (0.82, (244, 212, 136)), (1.0, (255, 248, 220))]
DARKGOLD = [(0.0, (22, 12, 3)), (0.35, (78, 50, 16)), (0.6, (150, 106, 40)), (0.85, (214, 172, 92)), (1.0, (245, 225, 170))]
STEEL = [(0.0, (14, 16, 22)), (0.35, (58, 64, 76)), (0.6, (124, 132, 146)), (0.82, (196, 202, 214)), (1.0, (250, 252, 255))]
IRON = [(0.0, (6, 6, 8)), (0.45, (34, 34, 40)), (0.75, (84, 84, 94)), (1.0, (170, 170, 182))]
IVORY = [(0.0, (60, 52, 40)), (0.4, (150, 140, 120)), (0.7, (222, 214, 194)), (1.0, (255, 252, 240))]
CRIMSON = [(0.0, (30, 2, 4)), (0.4, (110, 10, 16)), (0.7, (186, 30, 34)), (0.9, (236, 92, 80)), (1.0, (255, 200, 180))]


def ramp(t, stops):
    t = np.clip(t, 0, 1)
    out = np.zeros(t.shape + (3,), np.float32)
    xs = [s[0] for s in stops]
    for c in range(3):
        out[..., c] = np.interp(t, xs, [s[1][c] for s in stops])
    return out


def smooth(x):
    x = np.clip(x, 0, 1)
    return x * x * (3 - 2 * x)


def ss_mask(w, h, draw_fn, ss=4):
    """Draw with PIL at ss x, return antialiased float mask (h, w)."""
    im = Image.new("L", (w * ss, h * ss), 0)
    d = ImageDraw.Draw(im)
    draw_fn(d, ss)
    im = im.resize((w, h), Image.LANCZOS)
    return np.asarray(im, np.float32) / 255.0


def noise(h, w, scale=8.0, octaves=3, seed=None):
    r = np.random.default_rng(seed) if seed is not None else rng
    acc = np.zeros((h, w), np.float32)
    amp = 1.0
    tot = 0
    for o in range(octaves):
        s = max(1, int(scale / (2 ** o)))
        n = r.random((h // s + 2, w // s + 2)).astype(np.float32)
        n = np.asarray(Image.fromarray((n * 255).astype(np.uint8)).resize((w + 2 * s, h + 2 * s), Image.BICUBIC), np.float32)[s:s + h, s:s + w] / 255.0
        acc += n * amp
        tot += amp
        amp *= 0.5
    return acc / tot


def heightfield(mask, width=6.0, soft=1.0, dome=False):
    m = mask > 0.5
    d = ndi.distance_transform_edt(m).astype(np.float32)
    if dome:
        h = np.sqrt(np.clip(d / width, 0, 1) * (2 - np.clip(d / width, 0, 1)))
    else:
        h = smooth(d / width)
    if soft > 0:
        h = ndi.gaussian_filter(h, soft)
    return h


def shade(h, strength=1.0, light=(-0.55, -0.75, 0.9), spec_pow=24):
    gy, gx = np.gradient(h)
    nx, ny, nz = -gx * strength * 6, -gy * strength * 6, np.ones_like(h)
    ln = np.sqrt(nx * nx + ny * ny + nz * nz)
    nx, ny, nz = nx / ln, ny / ln, nz / ln
    L = np.array(light, np.float32)
    L = L / np.linalg.norm(L)
    lam = nx * L[0] + ny * L[1] + nz * L[2]
    # blinn spec with view (0,0,1)
    H = L + np.array([0, 0, 1.0])
    H = H / np.linalg.norm(H)
    sp = np.clip(nx * H[0] + ny * H[1] + nz * H[2], 0, 1) ** spec_pow
    return lam, sp


def metal(mask, stops=GOLD, width=5.0, strength=1.0, grain=0.06, soft=0.8, dome=False, base=0.0):
    """Return RGBA float array of a bevelled metal shape."""
    h = heightfield(mask, width, soft, dome)
    lam, sp = shade(h, strength)
    hgt, wid = mask.shape
    n = noise(hgt, wid, 3, 2) - 0.5
    # brushed streaks
    streak = ndi.gaussian_filter(rng.random((hgt, wid)).astype(np.float32), (0.3, 6)) - 0.5
    t = 0.12 + lam * 0.78 + base + n * grain + streak * grain * 1.5 + sp * 0.35
    col = ramp(t, stops)
    col = col + sp[..., None] * 90
    rgba = np.concatenate([np.clip(col, 0, 255), (mask * 255)[..., None]], -1)
    return rgba


def flat(mask, color, alpha=1.0):
    h, w = mask.shape
    c = np.zeros((h, w, 4), np.float32)
    c[..., :3] = color
    c[..., 3] = mask * 255 * alpha
    return c


def over(dst, src):
    """alpha composite float RGBA (0..255) arrays."""
    sa = src[..., 3:4] / 255.0
    da = dst[..., 3:4] / 255.0
    oa = sa + da * (1 - sa)
    oc = (src[..., :3] * sa + dst[..., :3] * da * (1 - sa)) / np.maximum(oa, 1e-6)
    return np.concatenate([oc, oa * 255], -1)


def blank(w, h):
    return np.zeros((h, w, 4), np.float32)


def shadow(mask, dx=3, dy=5, blur=4.0, alpha=0.7, color=(0, 0, 0)):
    m = ndi.shift(mask, (dy, dx), order=1)
    m = ndi.gaussian_filter(m, blur)
    return flat(m, color, alpha)


def glow(mask, blur=8.0, color=(120, 190, 255), alpha=0.8):
    m = ndi.gaussian_filter(mask, blur)
    m = np.clip(m * 1.6, 0, 1)
    return flat(m, color, alpha)


def to_img(arr):
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")


def from_img(im):
    return np.asarray(im.convert("RGBA"), np.float32)


def erode(mask, px):
    m = mask > 0.5
    d = ndi.distance_transform_edt(m)
    return np.clip(d - px + 0.5, 0, 1).astype(np.float32)


def dilate(mask, px):
    m = mask > 0.5
    d = ndi.distance_transform_edt(~m)
    return np.clip(px - d + 0.5, 0, 1).astype(np.float32)


def ring(w, h, cx, cy, r_out, r_in, ss=4):
    def f(d, s):
        d.ellipse([(cx - r_out) * s, (cy - r_out) * s, (cx + r_out) * s, (cy + r_out) * s], fill=255)
        d.ellipse([(cx - r_in) * s, (cy - r_in) * s, (cx + r_in) * s, (cy + r_in) * s], fill=0)
    return ss_mask(w, h, f, ss)


def disc(w, h, cx, cy, r, ss=4):
    return ss_mask(w, h, lambda d, s: d.ellipse([(cx - r) * s, (cy - r) * s, (cx + r) * s, (cy + r) * s], fill=255), ss)


def poly(w, h, pts, ss=4):
    return ss_mask(w, h, lambda d, s: d.polygon([(x * s, y * s) for x, y in pts], fill=255), ss)


def kenney_border(idx, w, h, scale=2, double=True, kind="Border"):
    """9-slice a CC0 Kenney Fantasy UI border to w x h; returns float mask."""
    sub = "Double" if double else "Default"
    folder = os.path.join(KEN, "fantasy-ui-borders/PNG", sub, kind)
    files = sorted(os.listdir(folder))
    im = Image.open(os.path.join(folder, files[idx])).convert("RGBA")
    a = np.asarray(im, np.float32)[..., 3] / 255.0
    S = a.shape[0]
    c = S // 3
    big = np.asarray(Image.fromarray((a * 255).astype(np.uint8)).resize((S * scale * 4, S * scale * 4), Image.NEAREST), np.float32) / 255.0
    C = c * scale * 4
    W4, H4 = w * 4, h * 4
    out = np.zeros((H4, W4), np.float32)
    B = big.shape[0]
    mid = big[C:B - C, C:B - C]
    # corners
    out[:C, :C] = big[:C, :C]
    out[:C, W4 - C:] = big[:C, B - C:]
    out[H4 - C:, :C] = big[B - C:, :C]
    out[H4 - C:, W4 - C:] = big[B - C:, B - C:]
    # edges stretched
    def st(arr, ww, hh):
        return np.asarray(Image.fromarray((arr * 255).astype(np.uint8)).resize((ww, hh), Image.NEAREST), np.float32) / 255.0
    out[:C, C:W4 - C] = st(big[:C, C:B - C], W4 - 2 * C, C)
    out[H4 - C:, C:W4 - C] = st(big[B - C:, C:B - C], W4 - 2 * C, C)
    out[C:H4 - C, :C] = st(big[C:B - C, :C], C, H4 - 2 * C)
    out[C:H4 - C, W4 - C:] = st(big[C:B - C, B - C:], C, H4 - 2 * C)
    res = Image.fromarray((out * 255).astype(np.uint8)).resize((w, h), Image.LANCZOS)
    return np.asarray(res, np.float32) / 255.0


def kenney_divider(idx, w, h, double=True, fade=False):
    sub = "Double" if double else "Default"
    folder = os.path.join(KEN, "fantasy-ui-borders/PNG", sub, "Divider Fade" if fade else "Divider")
    files = sorted(os.listdir(folder))
    im = Image.open(os.path.join(folder, files[idx])).convert("RGBA")
    a = im.split()[3].resize((w, h), Image.LANCZOS)
    return np.asarray(a, np.float32) / 255.0


def kenney_ui(name, size=None, color="Yellow", style="Double"):
    p = os.path.join(KEN, "ui-pack/PNG", color, style, name)
    im = Image.open(p).convert("RGBA")
    if size:
        im = im.resize(size, Image.LANCZOS)
    return im


def texture_fill(w, h, src, dark=1.0, offset=(0, 0)):
    im = Image.open(os.path.join(SRC, src)).convert("RGB")
    sw, sh = im.size
    sc = max(w / sw, h / sh)
    im = im.resize((int(sw * sc) + 1, int(sh * sc) + 1), Image.LANCZOS)
    ox = min(offset[0], im.width - w)
    oy = min(offset[1], im.height - h)
    im = im.crop((ox, oy, ox + w, oy + h))
    a = np.asarray(im, np.float32) * dark
    return np.concatenate([a, np.full((h, w, 1), 255, np.float32)], -1)


def masked(arr, mask):
    out = arr.copy()
    out[..., 3] = out[..., 3] * mask
    return out


def vignette(w, h, strength=0.6, power=2.0):
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    dx = (x - w / 2) / (w / 2)
    dy = (y - h / 2) / (h / 2)
    r = np.sqrt(dx * dx + dy * dy) / 1.414
    return 1 - strength * np.clip(r, 0, 1) ** power


def rect_mask(w, h, x0, y0, x1, y1, r=0, ss=4):
    return ss_mask(w, h, lambda d, s: d.rounded_rectangle([x0 * s, y0 * s, x1 * s, y1 * s], radius=r * s, fill=255), ss)


def save(arr_or_img, path, size=None):
    im = arr_or_img if isinstance(arr_or_img, Image.Image) else to_img(arr_or_img)
    if size:
        im = im.resize(size, Image.LANCZOS)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path, optimize=True)
    return im


def text_mask(w, h, text, size, font=FONT_SERIF_B, cx=None, cy=None, ss=4):
    def f(d, s):
        fnt = ImageFont.truetype(font, size * s)
        d.text(((cx if cx is not None else w / 2) * s, (cy if cy is not None else h / 2) * s), text, font=fnt, fill=255, anchor="mm")
    return ss_mask(w, h, f, ss)


def key_green(im, tol=60, soft=40):
    a = np.asarray(im.convert("RGB"), np.float32)
    bg = np.median(np.concatenate([a[:8].reshape(-1, 3), a[-8:].reshape(-1, 3), a[:, :8].reshape(-1, 3), a[:, -8:].reshape(-1, 3)]), 0)
    d = np.sqrt(((a - bg) ** 2).sum(-1))
    # greenness: g dominant
    gdom = a[..., 1] - np.maximum(a[..., 0], a[..., 2])
    bgg = bg[1] - max(bg[0], bg[2])
    alpha = np.clip((d - tol) / soft, 0, 1)
    alpha = np.maximum(alpha, np.clip((bgg * 0.6 - gdom) / 20.0, 0, 1) * (d > tol * 0.5))
    # despill: clamp green to max(r,b) + small
    out = a.copy()
    lim = np.maximum(out[..., 0], out[..., 2]) + 8
    spill = (out[..., 1] > lim)
    out[..., 1] = np.where(spill, lim, out[..., 1])
    alpha = ndi.binary_opening(alpha > 0.5, iterations=1) * alpha
    alpha = ndi.gaussian_filter(alpha, 0.6)
    rgba = np.concatenate([out, (alpha * 255)[..., None]], -1)
    return rgba
