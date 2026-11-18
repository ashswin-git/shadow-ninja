"""Shadow Ninja in-game art pass: painted enemy/boss/player sprite strips, painted
per-stage ground + platform textures, DOMAIN ink/moon/gold effect plates.
Sources: original painted plates in art_src/ generated for this project."""
import sys, os, json, math
sys.path.insert(0, os.path.dirname(__file__))
from artlib import *

SPR = os.path.join(ROOT, "assets/sprites")
ENV = os.path.join(ROOT, "assets/env")
FXD = os.path.join(ROOT, "assets/fx")
os.makedirs(ENV, exist_ok=True); os.makedirs(FXD, exist_ok=True)
only = set(sys.argv[1:])
def want(k): return not only or k in only
DBG = "/tmp/sn/ig"
SS = 1.5  # textures stored at 1.5x display size (phone screens are ~1.5x the 1280x720 viewport)


def key(name, despill_band=True):
    a = np.asarray(Image.open(os.path.join(SRC, name)).convert("RGB"), np.float32)
    bd = np.concatenate([a[:6].reshape(-1, 3), a[:, :6].reshape(-1, 3), a[:, -6:].reshape(-1, 3)])
    bg = np.median(bd, 0)
    d = np.sqrt(((a - bg) ** 2).sum(-1))
    # chroma distance (ignores brightness a bit)
    alpha = np.clip((d - 55) / 45, 0, 1)
    m = alpha > 0.5
    m = ndi.binary_opening(m, iterations=1)
    m = ndi.binary_fill_holes(m) | m
    alpha = np.where(m, np.maximum(alpha, 0.0), 0) * 1.0
    alpha = ndi.gaussian_filter(alpha, 0.7)
    out = a.copy()
    g_dom = np.argmax(bg)
    if bg[1] > bg[0] and bg[1] > bg[2]:
        lim = np.maximum(out[..., 0], out[..., 2])
        edge = ndi.binary_dilation(alpha < 0.98, iterations=7) if despill_band else np.ones_like(m)
        spill = (out[..., 1] > lim + 6) & edge
        out[..., 1] = np.where(spill, lim + 6, out[..., 1])
    else:  # magenta
        lim = out[..., 1]
        edge = ndi.binary_dilation(alpha < 0.98, iterations=4)
        for c in (0, 2):
            out[..., c] = np.where(edge & (out[..., c] > lim + 10), lim + 10, out[..., c])
    return np.concatenate([out, (alpha * 255)[..., None]], -1)


def components(rgba, n, min_frac=0.02, core_px=7):
    m = rgba[..., 3] > 60
    # geodesic split: thick body cores grow back through the mask, so thin swords stay with their owner
    core = ndi.binary_erosion(m, iterations=core_px)
    cl, ck = ndi.label(core)
    cs = ndi.sum(np.ones_like(cl), cl, range(1, ck + 1))
    keep = np.argsort(-cs)[:n] + 1
    lab = np.where(np.isin(cl, keep), cl, 0)
    for _ in range(2000):
        un = m & (lab == 0)
        if not un.any(): break
        grown = ndi.grey_dilation(lab, size=3)
        newl = np.where(un, grown, lab)
        if (newl == lab).all(): break
        lab = newl
    remap = np.zeros(lab.max() + 1, np.int32)
    for j, kk in enumerate(keep): remap[kk] = j + 1
    lab = remap[lab]
    k = n
    sizes = ndi.sum(np.ones_like(lab), lab, range(1, k + 1))
    order = np.argsort(-sizes)
    big = [i + 1 for i in order[:n]]
    cents = {i: ndi.center_of_mass(m, lab, i)[1] for i in range(1, k + 1)}
    groups = {b: [b] for b in big}
    for i in range(1, k + 1):
        if i in big or sizes[i - 1] < min_frac * sizes.max() * 0.1:
            continue
        # attach mid-size pieces (sword tips etc.) to nearest big component by bbox distance
        ys, xs = np.where(lab == i)
        best, bd = None, 1e9
        for b in big:
            yb, xb = np.where(lab == b)
            dd = max(0, xs.min() - xb.max(), xb.min() - xs.max()) + max(0, ys.min() - yb.max(), yb.min() - ys.max())
            if dd < bd: best, bd = b, dd
        if bd < 30: groups[best].append(i)
    big.sort(key=lambda b: cents[b])
    out = []
    for b in big:
        mm = np.isin(lab, groups[b])
        l2, k2 = ndi.label(mm)
        if k2 > 1:
            s2 = ndi.sum(np.ones_like(l2), l2, range(1, k2 + 1))
            mm = np.isin(l2, [j + 1 for j, v in enumerate(s2) if v > 0.004 * s2.max()])
        mm = ndi.binary_dilation(mm, iterations=3)
        ys, xs = np.where(mm)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        crop = rgba[y0:y1, x0:x1].copy()
        crop[..., 3] *= mm[y0:y1, x0:x1]
        out.append(crop)
    return out


def body_anchor(crop):
    """x of the body centre: alpha-mass centroid of the middle torso band, ignoring thin weapons."""
    a = crop[..., 3] > 100
    h = a.shape[0]
    band = a[int(h * 0.25):int(h * 0.7)]
    # weapons are thin: erode away
    band = ndi.binary_erosion(band, iterations=6)
    if band.sum() < 50: band = a[int(h * 0.25):int(h * 0.7)]
    xs = np.where(band)[1]
    return float(np.median(xs))


def strip(name, frames_src, disp_h, out_name, pad=3, ref_h_idx=0, scale_override=None, sharpen=True):
    """frames_src: list of rgba crops. Uniform scale chosen so frame[ref] body height == disp_h * SS."""
    sc = scale_override or (disp_h * SS) / frames_src[ref_h_idx].shape[0]
    ims, anchors = [], []
    for c in frames_src:
        im = to_img(c)
        im = im.resize((max(1, round(im.width * sc)), max(1, round(im.height * sc))), Image.LANCZOS)
        if sharpen: im = im.filter(ImageFilter.UnsharpMask(1.0, 70, 2))
        ims.append(im); anchors.append(body_anchor(c) * sc)
    left = max(a for a in anchors); right = max(im.width - a for im, a in zip(ims, anchors))
    half = int(math.ceil(max(left, right))) + pad
    H = max(im.height for im in ims) + pad * 2
    W = half * 2
    sheet = Image.new("RGBA", (W * len(ims), H), (0, 0, 0, 0))
    for i, (im, a) in enumerate(zip(ims, anchors)):
        sheet.alpha_composite(im, (i * W + int(round(half - a)), H - pad - im.height))
    sheet.save(os.path.join(SPR, out_name), optimize=True)
    meta = dict(frame_w=W, frame_h=H, frames=len(ims), feet_pad=pad, scale=1.0 / SS)
    print(out_name, meta)
    return meta


META = {}
if want("sprites"):
    oni = components(key("enemy_oni.jpg"), 4)
    META["oni"] = strip("oni", oni, 84, "enemy_oni.png")
    kit = components(key("enemy_kitsune.jpg"), 4)
    META["kitsune"] = strip("kitsune", kit, 74, "enemy_kitsune.png", ref_h_idx=0)
    rin = components(key("boss_rin.jpg"), 4, core_px=22)
    for i in (1, 2):  # previous pose's blade tip leaks in at lower-left: trim it
        c = rin[i]; h = c.shape[0]; ax = body_anchor(c)
        c[int(h * 0.70):, :max(0, int(ax - 0.17 * h)), 3] = 0
        reg = c[int(h * 0.6):, :int(ax)]
        glowpx = (reg[..., 2] > 170) & (reg[..., 2] - reg[..., 0] > 45)
        glowpx = ndi.binary_dilation(glowpx, iterations=3)
        reg[..., 3] = np.where(glowpx, 0, reg[..., 3])
        rin[i] = c[:, np.where(c[..., 3].max(0) > 10)[0].min():]
    META["rin"] = strip("rin", rin, 150, "boss_rin.png", ref_h_idx=0)
    for k, v in META.items():
        json.dump(v, open(f"{DBG}/{k}.json", "w"))


def player_frames():
    a = key("hero_poses.jpg"); b = key("hero_run.jpg")
    pa = components(a, 5, core_px=8)
    pb = components(b, 5, core_px=8)
    names = {"idle": pa[0], "jump": pa[2], "dash": pa[3], "wall": pa[4],
             "run": pa[1], "run2": pb[0], "run3": pb[2], "slash": pb[4]}
    sc_a = 68 * SS / pa[0].shape[0]
    # second sheet drawn at a slightly different scale: match head-to-toe height of its first run pose to sheet A's run pose
    sc_b = sc_a * (pa[1].shape[0] / pb[1].shape[0]) * 0.92
    ims, anchors = {}, {}
    for k, c in names.items():
        sc = sc_a if c is not None and any(c is x for x in pa) else sc_b
        im = to_img(c).resize((max(1, round(c.shape[1] * sc)), max(1, round(c.shape[0] * sc))), Image.LANCZOS)
        im = im.filter(ImageFilter.UnsharpMask(1.0, 70, 2))
        ims[k] = im; anchors[k] = body_anchor(c) * sc
    pad = 3
    half = int(math.ceil(max(max(anchors[k], ims[k].width - anchors[k]) for k in ims))) + pad
    H = max(im.height for im in ims.values()) + pad * 2
    for k, im in ims.items():
        out = Image.new("RGBA", (half * 2, H), (0, 0, 0, 0))
        y = H - pad - im.height
        if k in ("jump",): y = H - pad - im.height - 4
        out.alpha_composite(im, (int(round(half - anchors[k])), y))
        out.save(f"{SPR}/player_{k}.png", optimize=True)
    print("player", half * 2, H, pad)
    json.dump(dict(frame_w=half * 2, frame_h=H, feet_pad=pad), open(f"{DBG}/player.json", "w"))


if want("player"):
    player_frames()


def seamless_x(arr, k):
    W = arr.shape[1]
    out = arr[:, :W - k].copy()
    t = np.linspace(0, 1, k)[None, :, None]
    out[:, :k] = arr[:, W - k:] * (1 - t) + arr[:, :k] * t
    return out


def seamless_y(arr, k):
    H = arr.shape[0]
    out = arr[:H - k].copy()
    t = np.linspace(0, 1, k)[:, None, None]
    out[:k] = arr[H - k:] * (1 - t) + arr[:k] * t
    return out


GROUND = {
    # grade: (multiply rgb, fog colour, fog amount) so the ground sits in each stage's light
    "snow": dict(src="ground_snow.jpg", mul=(0.80, 0.86, 0.98), fog=(120, 140, 175), fog_amt=0.10, sink=0.55, body=(0.62, 0.95)),
    "forest": dict(src="ground_forest.jpg", mul=(0.78, 0.88, 0.86), fog=(110, 140, 135), fog_amt=0.12, sink=0.62, body=(0.55, 0.92)),
    "boss": dict(src="ground_boss.jpg", mul=(1.0, 0.92, 0.92), fog=(80, 10, 14), fog_amt=0.06, sink=0.35, body=(0.42, 0.95)),
}


def ground():
    meta = {}
    for t, g in GROUND.items():
        a = key(g["src"], despill_band=True)
        al = a[..., 3] / 255.0
        cov = (al > 0.5).mean(1)
        top = int(np.where(cov > 0.02)[0][0])
        solid = int(np.where(cov > 0.97)[0][0])
        band = a[top:].copy()
        rgb = band[..., :3] * np.array(g["mul"], np.float32)
        rgb = rgb * (1 - g["fog_amt"]) + np.array(g["fog"], np.float32) * g["fog_amt"]
        band[..., :3] = np.clip(rgb, 0, 255)
        # deepen toward the bottom so the band melts into the under-fill
        hh = band.shape[0]
        yy = np.linspace(0, 1, hh)[:, None, None]
        band[..., :3] *= np.clip(1.0 - 0.55 * np.clip((yy - 0.45) / 0.55, 0, 1), 0, 1)
        # walk line: between the cap top and the first fully solid row
        walk = (solid - top) * g["sink"]
        for name, sc, crop_h in (("ground", 0.42 if t == "forest" else 0.5, None), ("plat", 0.30, None)):
            im = to_img(band)
            im = im.resize((round(im.width * sc), round(im.height * sc)), Image.LANCZOS)
            arr = from_img(im)
            arr = seamless_x(arr, int(arr.shape[1] * 0.08))
            # Godot tiles cleanly at power-of-two-ish widths: resample to exact width
            Wt = (448 if t == "forest" else 512) if name == "ground" else 320
            im2 = to_img(arr).resize((Wt, arr.shape[0]), Image.LANCZOS)
            arr = from_img(im2)
            wl = walk * sc
            if name == "ground":
                hcut = min(arr.shape[0], int(wl + (170 if t == "forest" else 196)))
                arr = arr[:hcut].copy()
                tail = arr[-4:, :, :3].reshape(-1, 3).mean(0)
                ff = np.clip((np.arange(hcut) - (hcut - 44)) / 44.0, 0, 1)[:, None, None]
                arr[..., :3] = arr[..., :3] * (1 - ff) + tail * ff
                meta[f"under_{t}"] = [round(float(v) / 255, 3) for v in tail]
            if name == "plat":
                arr = arr[:int(wl + 52)]
                # bottom lip shadow + slight underside darkening
                hh2 = arr.shape[0]; y2 = np.linspace(0, 1, hh2)[:, None]
                arr[..., :3] *= np.clip(1.15 - 0.6 * y2, 0, 1)[..., None]
                arr[-3:, :, :3] *= 0.45
            save(arr, f"{ENV}/{name}_{t}.png")
            meta[f"{name}_{t}"] = dict(w=arr.shape[1], h=arr.shape[0], walk=round(wl, 1))
        # pillar/wall body: solid section, seamless both ways
        b0, b1 = g["body"]
        y0 = int(top + (a.shape[0] - top) * b0); y1 = int(top + (a.shape[0] - top) * b1)
        body = a[y0:y1].copy()
        rgb = body[..., :3] * np.array(g["mul"], np.float32) * 0.85
        body[..., :3] = np.clip(rgb * (1 - g["fog_amt"]) + np.array(g["fog"], np.float32) * g["fog_amt"], 0, 255)
        body[..., 3] = 255
        im = to_img(body); im = im.resize((round(im.width * 0.3), round(im.height * 0.3)), Image.LANCZOS)
        arr = from_img(im); arr = seamless_x(arr, 24); arr = seamless_y(arr, 16)
        hh = max(48, round(arr.shape[0] * 256 / arr.shape[1]))
        arr = from_img(to_img(arr).resize((256, hh), Image.LANCZOS))
        save(arr, f"{ENV}/body_{t}.png")
    json.dump(meta, open(f"{DBG}/ground.json", "w"), indent=1)
    print(json.dumps(meta))


if want("ground"):
    ground()


def enso(S=384, seed=7):
    """Dry-brush ink enso ring, ink-black with indigo sheen. Alpha texture."""
    r_ = np.random.default_rng(seed)
    y, x = np.mgrid[0:S, 0:S].astype(np.float32)
    cx = cy = S / 2
    dx, dy = x - cx, y - cy
    r = np.sqrt(dx * dx + dy * dy)
    th = (np.arctan2(dy, dx) + np.pi * 0.62) % (2 * np.pi)
    u = th / (2 * np.pi)                       # 0..1 along stroke
    R = S * 0.40 + S * 0.012 * np.sin(u * 6.28 * 2 + 1.0)
    wid = S * (0.035 + 0.05 * np.clip(np.sin(np.clip(u, 0, 0.93) / 0.93 * np.pi), 0, 1) ** 0.6)
    wid = wid * np.where(u > 0.93, 0.0, 1.0)
    v = (r - R) / np.maximum(wid, 1e-3)
    body = np.clip(1.0 - np.abs(v), 0, 1)
    body = smooth(np.clip(body * 3.0, 0, 1))
    # dry-brush bristle streaks: noise across v, constant along stroke
    bristle = ndi.gaussian_filter1d(r_.random(512).astype(np.float32), 1.2)
    bristle = (bristle - bristle.min()) / (bristle.max() - bristle.min())
    vi = np.nan_to_num(np.clip((v + 1) * 0.5 * 511, 0, 511)).astype(int)
    dry = np.clip((bristle[vi] - (0.15 + 0.55 * u ** 2.5)) * 4, 0, 1)
    dry = np.maximum(dry, (np.abs(v) < 0.45) * (u < 0.55) * 1.0)
    a = body * dry
    a = ndi.gaussian_filter(a, 0.6)
    # tail flecks
    fl = (r_.random((S, S)) > 0.9975).astype(np.float32)
    fl = ndi.gaussian_filter(ndi.binary_dilation(fl, iterations=2).astype(np.float32), 1.0)
    fl *= np.clip(1 - np.abs(r - R * 1.02) / (S * 0.12), 0, 1) * (u > 0.75)
    a = np.clip(a + fl * 0.9, 0, 1)
    col = np.zeros((S, S, 3), np.float32)
    sheen = np.clip(1 - np.abs(v + 0.35) * 2.5, 0, 1)
    col[:] = (12, 12, 24)
    outer = np.clip(1 - np.abs(v - 0.72) * 3.2, 0, 1)
    col += sheen[..., None] * np.array((34, 40, 78), np.float32)
    col += outer[..., None] * np.array((170, 185, 220), np.float32) * 0.75   # moonlit wet edge
    return np.concatenate([col, (a * 255)[..., None]], -1)


def sigil(S=352):
    """Forged gold moon sigil: double ring, 8 crescents, tick marks, sapphire studs."""
    out = blank(S, S)
    c = S / 2
    m = ring(S, S, c, c, S * 0.47, S * 0.455) + ring(S, S, c, c, S * 0.43, S * 0.405) + ring(S, S, c, c, S * 0.30, S * 0.29)
    ticks = ss_mask(S, S, lambda d, s: [d.line([((c + math.cos(a) * S * 0.405) * s, (c + math.sin(a) * S * 0.405) * s),
                                                  ((c + math.cos(a) * S * 0.375) * s, (c + math.sin(a) * S * 0.375) * s)], fill=255, width=int(2.2 * s))
                                          for a in np.linspace(0, 2 * np.pi, 48, endpoint=False)])
    m = np.clip(m + ticks, 0, 1)
    cres = np.zeros((S, S), np.float32)
    for k in range(8):
        a = k * np.pi / 4 + np.pi / 8
        px, py = c + math.cos(a) * S * 0.355, c + math.sin(a) * S * 0.355
        d1 = disc(S, S, px, py, S * 0.033)
        d2 = disc(S, S, px + math.cos(a + 0.9) * S * 0.016, py + math.sin(a + 0.9) * S * 0.016, S * 0.028)
        cres = np.maximum(cres, np.clip(d1 - d2, 0, 1))
    m = np.clip(m + cres, 0, 1)
    out = over(out, glow(m, 6, (255, 200, 110), 0.55))
    out = over(out, shadow(m, 1, 2, 1.5, 0.6))
    out = over(out, metal(m, GOLD, 2.0, 1.2))
    studs = np.zeros((S, S), np.float32)
    for k in range(4):
        a = k * np.pi / 2
        studs = np.maximum(studs, disc(S, S, c + math.cos(a) * S * 0.44, c + math.sin(a) * S * 0.44, S * 0.022))
    out = over(out, metal(dilate(studs, 2), GOLD, 2.0, 1.0))
    gem = ramp(np.clip(0.2 + shade(heightfield(studs, 4, 1, True), 1.2)[0] * 0.9, 0, 1),
               [(0, (8, 20, 70)), (0.6, (40, 100, 220)), (0.9, (160, 210, 255)), (1, (255, 255, 255))])
    out = over(out, np.concatenate([gem, (studs * 255)[..., None]], -1))
    return out


def moon(S=256):
    y, x = np.mgrid[0:S, 0:S].astype(np.float32)
    r = np.sqrt((x - S / 2) ** 2 + (y - S / 2) ** 2) / (S / 2)
    core = np.clip((0.42 - r) / 0.03, 0, 1)
    halo = np.exp(-((r / 0.55) ** 2) * 2.2) * 0.75
    n = noise(S, S, 18, 3, 5)
    craters = (n - 0.5) * 0.25 * core
    a = np.clip(core * 0.95 + halo * (1 - core), 0, 1)
    col = np.zeros((S, S, 3), np.float32)
    col[:] = (200, 222, 255)
    col = col * (1 - core[..., None]) + (np.array((246, 248, 255)) * (1 + craters[..., None])) * core[..., None]
    return np.concatenate([np.clip(col, 0, 255), (a * 255)[..., None]], -1)


if want("domain"):
    save(enso(), f"{FXD}/domain_enso.png")
    save(sigil(), f"{FXD}/domain_sigil.png")
    save(moon(), f"{FXD}/domain_moon.png")


def _artpass():
    import importlib
    saved = sys.argv; sys.argv = [saved[0], "__none__"]
    try:
        import gen_artpass as ga
    finally:
        sys.argv = saved
    return ga


UI = os.path.join(ROOT, "assets/ui")


def hud_plate2(W=316, H=184):
    """Dense forged HUD plate: black-lacquer wood body, three recessed stat slots,
    double gold Kenney border, corner rivets and a crimson cord knot on the left."""
    ga = _artpass()
    out = blank(W, H)
    body = rect_mask(W, H, 2, 2, W - 2, H - 2, 10)
    out = over(out, shadow(body, 0, 5, 6, 0.65))
    tex = texture_fill(W, H, "wood.jpg", 0.9)
    tex[..., :3] = tex[..., :3] * np.array((0.78, 0.50, 0.42)) + np.array((10, 2, 2))
    tex[..., :3] *= vignette(W, H, 0.55, 2.0)[..., None]
    out = over(out, masked(tex, body * 0.96))
    out = over(out, flat(body, (30, 6, 8), 0.25))
    # recessed slots
    for i in range(3):
        y0 = 16 + i * 52; slot = rect_mask(W, H, 22, y0, W - 24, y0 + 44, 8)
        out = over(out, flat(slot, (6, 7, 18), 0.72))
        inner_sh = np.clip(slot - ndi.shift(slot, (3, 2), order=1), 0, 1)
        out = over(out, flat(inner_sh, (0, 0, 0), 0.8))
        lip = np.clip(ndi.shift(slot, (-1, 0), order=1) - slot, 0, 1)
        out = over(out, flat(np.clip(slot - erode(slot, 1.2), 0, 1), (170, 130, 60), 0.55))
        # icon socket: small gold bezel ring at left of slot
        out = over(out, metal(ring(W, H, 50, y0 + 22, 19, 15.5), GOLD, 1.6, 1.2))
        out = over(out, ga.lacquer(disc(W, H, 50, y0 + 22, 15.5), (8, 8, 16), (40, 44, 70), 20))
    fr = kenney_border(13, W - 8, H - 8, 1, True)
    fm = np.zeros((H, W), np.float32); fm[4:H - 4, 4:W - 4] = fr
    outer = np.clip(rect_mask(W, H, 1, 1, W - 1, H - 1, 10) - rect_mask(W, H, 6, 6, W - 6, H - 6, 7), 0, 1)
    fm = np.clip(fm + outer, 0, 1)
    out = over(out, shadow(fm, 1, 2, 1.5, 0.8))
    out = over(out, metal(fm, GOLD, width=2.4, strength=1.3))
    pts = [(14, 14), (W - 14, 14), (14, H - 14), (W - 14, H - 14)]
    out = over(out, ga.rivets(W, H, pts, 6.0))
    return out


def dpad_base(W=570, H=180):
    """Physical rocker base for the two move chevrons: lacquer pill, gold rim, studs, centre jewel."""
    ga = _artpass()
    out = blank(W, H)
    r = H / 2 - 6
    pill = rect_mask(W, H, 6, 6, W - 6, H - 6, r)
    out = over(out, shadow(pill, 0, 6, 8, 0.6))
    rim = np.clip(pill - rect_mask(W, H, 18, 18, W - 18, H - 18, r - 12), 0, 1)
    face = rect_mask(W, H, 16, 16, W - 16, H - 16, r - 10)
    out = over(out, ga.lacquer(face, (6, 7, 14), (34, 38, 64), 70, 0.10, 0.05))
    # engraved seigaiha band on the face
    wav = np.zeros((H, W), np.float32); step = 30
    for row in range(-1, H // (step // 2) + 2):
        for col in range(-1, W // step + 2):
            cx0 = col * step + (step / 2 if row % 2 else 0); cy0 = row * step / 2
            for rr in (13, 8.5, 4):
                wav = np.maximum(wav, ring(W, H, cx0, cy0, rr + 0.8, rr - 0.8, 2))
    out = over(out, flat(wav * erode(face, 8), (140, 150, 200), 0.09))
    out = over(out, metal(rim, GOLD, width=6, strength=1.2))
    inner = np.clip(rect_mask(W, H, 20, 20, W - 20, H - 20, r - 14) - rect_mask(W, H, 23, 23, W - 23, H - 23, r - 17), 0, 1)
    out = over(out, metal(inner, STEEL, width=1.5))
    # centre divider: vertical gold bar + sapphire
    bar = rect_mask(W, H, W / 2 - 4, 30, W / 2 + 4, H - 30, 3)
    out = over(out, metal(bar, GOLD, 2.0, 1.2))
    g = from_img(to_img(ga.gem(64)).resize((44, 44), Image.LANCZOS))
    gg = blank(W, H); gg[H // 2 - 22:H // 2 + 22, W // 2 - 22:W // 2 + 22] = g
    out = over(out, gg)
    pts = [(W / 2, 12), (W / 2, H - 12), (r + 6, 12 + 2), (W - r - 6, 14), (r + 6, H - 14), (W - r - 6, H - 14)]
    out = over(out, ga.rivets(W, H, pts, 5.0))
    return out


def moon_medallion(S=96):
    ga = _artpass()
    c = S / 2
    out = blank(S, S)
    o = disc(S, S, c, c, c - 3)
    out = over(out, shadow(o, 0, 3, 3, 0.7))
    out = over(out, metal(ring(S, S, c, c, c - 3, c - 12), GOLD, 3.0, 1.2))
    face = disc(S, S, c, c, c - 11)
    out = over(out, ga.lacquer(face, (8, 10, 28), (40, 60, 130), 26))
    cres = np.clip(disc(S, S, c, c, c * 0.48) - disc(S, S, c + c * 0.22, c - c * 0.12, c * 0.42), 0, 1)
    out = over(out, glow(cres, 4, (150, 200, 255), 0.8))
    out = over(out, metal(cres, IVORY, 2.0, 1.1))
    return out


if want("chrome"):
    save(hud_plate2(), f"{UI}/hud_plate.png")
    save(dpad_base(), f"{UI}/dpad_base.png")
    save(moon_medallion(), f"{UI}/domain_medal.png")
