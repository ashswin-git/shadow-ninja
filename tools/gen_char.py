"""Shadow Ninja character pass: larger painted hero pose frames (run, jump cycle, ground
slash, air slash, dash, wall, hurt) and extended oni / Rin attack strips.
Sources: original painted sheets in art_src/ generated for this project
(hero2_*.jpg, oni_attack.jpg, rin_attack.jpg; identity from art_src/hero.jpg)."""
import sys, os, json, math
sys.argv = [sys.argv[0], "__none__"]          # import helpers from gen_ingame without rebuilding it
sys.path.insert(0, os.path.dirname(__file__))
from gen_ingame import *

HERO = os.path.join(SPR, "hero")


def key2(name):
    """Chroma key for dark figures on green: solid interior (no see-through robes), thin blades kept."""
    a = np.asarray(Image.open(os.path.join(SRC, name)).convert("RGB"), np.float32)
    bd = np.concatenate([a[:6].reshape(-1, 3), a[:, :6].reshape(-1, 3), a[:, -6:].reshape(-1, 3)])
    bg = np.median(bd, 0)
    d = np.sqrt(((a - bg) ** 2).sum(-1))
    # green dominance also separates dark navy cloth from a dark green backdrop
    gd = a[..., 1] - np.maximum(a[..., 0], a[..., 2])
    bgd = bg[1] - max(bg[0], bg[2])
    soft = np.clip((d - 40) / 35, 0, 1) * 0.5 + np.clip((bgd - gd - 10) / 25, 0, 1) * 0.5
    soft = np.maximum(soft, np.clip((d - 60) / 30, 0, 1))
    m = soft > 0.5
    m = ndi.binary_opening(m, iterations=1) | (ndi.binary_closing(m, iterations=2) & (soft > 0.3))
    m = ndi.binary_closing(m, iterations=1)
    holes = ndi.binary_fill_holes(m) & ~m
    hl, hn = ndi.label(holes)
    if hn:
        hs = ndi.sum(holes, hl, range(1, hn + 1))
        m = m | np.isin(hl, [i + 1 for i, v in enumerate(hs) if v < 400])   # only pinholes, not gaps under raised blades
    core = ndi.binary_erosion(m, iterations=2)
    alpha = np.where(m, np.maximum(ndi.gaussian_filter(soft, 0.6), core), 0)
    alpha = ndi.gaussian_filter(alpha, 0.5)
    out = a.copy()
    lim = np.maximum(out[..., 0], out[..., 2])
    edge = ndi.binary_dilation(~core, iterations=3)
    spill = (out[..., 1] > lim + 4) & edge
    out[..., 1] = np.where(spill, lim + 4, out[..., 1])
    return np.concatenate([out, (alpha * 255)[..., None]], -1)
os.makedirs(HERO, exist_ok=True)


def retouch(im, head_px):
    """Readability retouch at play size (polish pass): lift navy midtones, a lighter charcoal mask,
    brighter skin/eyes, and a cool rim light on the up/front edges of the body (not the aura)."""
    a = np.asarray(im, np.float32).copy()
    rgb, al = a[..., :3], a[..., 3]
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    solid = al > 200
    aura = (b > r + 45) & (b > 110) & (b > g + 10)
    body = solid & ~aura
    # 1) midtone lift on dark cloth / hair (gamma on the figure only), keeps the silhouette dark
    lift = 255.0 * (rgb / 255.0) ** 0.68
    k = np.clip((120 - lum) / 120, 0, 1)[..., None] * body[..., None]
    rgb = rgb * (1 - 0.85 * k) + lift * (0.85 * k)
    # 2) face: skin pixels near the top of the figure
    ys, xs = np.where(solid)
    top = ys.min() if len(ys) else 0
    skin = solid & (r > 110) & (r > b + 25) & (g > b) & (r > g) & (np.arange(a.shape[0])[:, None] < top + 1.3 * head_px)
    sl, sn = ndi.label(ndi.binary_dilation(skin, iterations=2))
    if sn:
        sz = ndi.sum(skin, sl, range(1, sn + 1)); best = int(np.argmax(sz)) + 1
        if sz[best - 1] > 6:
            cy, cx = ndi.center_of_mass(sl == best)
            yy, xx = np.mgrid[0:a.shape[0], 0:a.shape[1]]
            box = (yy > cy - 0.12 * head_px) & (yy < cy + 0.42 * head_px) & (np.abs(xx - cx) < 0.42 * head_px)
            red = (r > g + 40) & (r > b + 30)
            mask = box & body & (lum < 70) & ~red
            charcoal = np.array([112, 116, 138], np.float32)
            rgb = np.where(mask[..., None], rgb * 0.3 + charcoal * 0.7, rgb)
            rgb = np.where((skin & box)[..., None], np.minimum(rgb * 1.2 + 12, 255), rgb)
            eye = box & solid & (b > 140) & (b > r + 40) & (yy < cy + 0.1 * head_px)
            rgb = np.where(eye[..., None], np.minimum(rgb * 1.2 + 20, 255), rgb)
    # 3) cool rim on the up/front facing edges of the body (light from upper front)
    bm = ndi.gaussian_filter(body.astype(np.float32), 1.6)
    gy, gx = np.gradient(bm)
    nx, ny = -gx, -gy                        # outward normal
    nn = np.sqrt(nx * nx + ny * ny) + 1e-6
    face = np.clip((nx * 0.45 - ny * 0.89) / nn, 0, 1)
    inner = body & ~ndi.binary_erosion(body, iterations=3)
    w = (face * inner * np.clip(nn * 6, 0, 1))[..., None] * 0.75
    rim = np.array([175, 215, 255], np.float32)
    rgb = rgb * (1 - w) + rim * w
    a[..., :3] = np.clip(rgb, 0, 255)
    return Image.fromarray(a.astype(np.uint8), "RGBA")
DISP_H = 120.0          # standing hero height on screen (px at 1280x720); collision stays 28x48
PAD = 3
CORE_PX = {"air": 14, "slashb": 10, "slash": 10}
SHEETS = {  # file, figure count, measured head height (hair top -> scarf) in sheet px
    "core": ("hero2_core.jpg", 6, 61.5), "jump": ("hero2_jump.jpg", 5, 73.5),
    "slash": ("hero2_slash.jpg", 4, 76.5), "air": ("hero2_air.jpg", 5, 56.0),
    "jumpb": ("hero2_jump_b.jpg", 4, 73.0), "slashb": ("hero2_slash_b.jpg", 3, 78.0),
    "dash": ("hero2_dash.jpg", 2, 84.0),
}
FRAMES = {  # frame name -> (sheet, index)
    "idle": ("core", 0), "run1": ("core", 1), "run2": ("core", 2), "run3": ("core", 3), "run4": ("core", 4),
    "wall": ("core", 5),
    "j_crouch": ("jump", 0), "j_launch": ("jumpb", 0), "j_rise": ("jump", 1), "j_tuck": ("jumpb", 1),
    "j_apex": ("jump", 2), "j_fall0": ("jumpb", 2), "j_fall": ("jump", 3), "j_preland": ("jumpb", 3),
    "j_land": ("jump", 4),
    "s_windup": ("slash", 0), "s_high": ("slashb", 0), "s_contact": ("slash", 1), "s_through": ("slashb", 1),
    "s_over": ("slashb", 2), "s_follow": ("slash", 2), "s_recover": ("slash", 3),
    "a_windup": ("air", 0), "a_contact": ("air", 1), "a_down": ("air", 2), "a_follow": ("air", 3),
    "hurt": ("air", 4), "dash": ("dash", 0), "dash_stop": ("dash", 1),
}

def hero():
    crops = {k: components(key2(f), n, core_px=CORE_PX.get(k, 8)) for k, (f, n, _) in SHEETS.items()}
    # wall pose: the painted sheet includes the wall pole; drop long thin vertical columns
    w = crops["core"][5]; al = w[..., 3] > 60
    tall = al.sum(0) > 0.8 * al.shape[0]
    for x in np.where(tall)[0]:
        w[:, max(0, x - 4):x + 5, 3] = 0
    keep = np.where(w[..., 3].max(0) > 10)[0]
    rows = np.where(w[..., 3].max(1) > 10)[0]
    crops["core"][5] = w[rows.min():rows.max() + 1, keep.min():keep.max() + 1]
    base = DISP_H * SS / crops["core"][0].shape[0]
    head_core = SHEETS["core"][2]
    global HEAD_PX
    HEAD_PX = base * head_core
    meta = {}
    for name, (sh, i) in FRAMES.items():
        c = crops[sh][i]
        sc = base * head_core / SHEETS[sh][2]
        im = to_img(c).resize((max(1, round(c.shape[1] * sc)), max(1, round(c.shape[0] * sc))), Image.LANCZOS)
        im = im.filter(ImageFilter.UnsharpMask(1.2, 90, 2))
        im = retouch(im, HEAD_PX)
        ax = body_anchor(c) * sc
        half = int(math.ceil(max(ax, im.width - ax))) + PAD
        H = im.height + PAD * 2
        out = Image.new("RGBA", (half * 2, H), (0, 0, 0, 0))
        out.alpha_composite(im, (int(round(half - ax)), PAD))
        out.save(os.path.join(HERO, name + ".png"), optimize=True)
        meta[name] = out.size
    print("hero frames", len(meta), meta)


def strip2(frames, scales, out_name, pad=3):
    ims, anchors = [], []
    for c, sc in zip(frames, scales):
        im = to_img(c).resize((max(1, round(c.shape[1] * sc)), max(1, round(c.shape[0] * sc))), Image.LANCZOS)
        ims.append(im.filter(ImageFilter.UnsharpMask(1.0, 70, 2))); anchors.append(body_anchor(c) * sc)
    half = int(math.ceil(max(max(a, im.width - a) for im, a in zip(ims, anchors)))) + pad
    H = max(im.height for im in ims) + pad * 2; W = half * 2
    sheet = Image.new("RGBA", (W * len(ims), H), (0, 0, 0, 0))
    for i, (im, a) in enumerate(zip(ims, anchors)):
        sheet.alpha_composite(im, (i * W + int(round(half - a)), H - pad - im.height))
    sheet.save(os.path.join(SPR, out_name), optimize=True)
    print(out_name, dict(frame_w=W, frame_h=H, frames=len(ims)))


def oni():
    old = components(key("enemy_oni.jpg"), 4)
    new = components(key("oni_attack.jpg"), 4, core_px=10)
    sc = ONI_H * SS / old[0].shape[0]
    # attack sheet is drawn ~0.83x the walk sheet (hat width / thrust height): rescale to match
    sc2 = sc * ONI_REL
    # strip: 0 idle, 1-2 walk, 3 thrust (walk sheet) | 4 windup, 5 strike, 6 strike low
    strip2(old + [new[0], new[1], new[2]], [sc] * 4 + [sc2] * 3, "enemy_oni.png")


def rin():
    rin = components(key("boss_rin.jpg"), 4, core_px=22)
    for i in (1, 2):  # previous pose's blade tip leaks in at lower-left: trim it (as gen_ingame)
        c = rin[i]; h = c.shape[0]; ax = body_anchor(c)
        c[int(h * 0.70):, :max(0, int(ax - 0.17 * h)), 3] = 0
        reg = c[int(h * 0.6):, :int(ax)]
        glowpx = (reg[..., 2] > 170) & (reg[..., 2] - reg[..., 0] > 45)
        glowpx = ndi.binary_dilation(glowpx, iterations=3)
        reg[..., 3] = np.where(glowpx, 0, reg[..., 3])
        rin[i] = c[:, np.where(c[..., 3].max(0) > 10)[0].min():]
    cut = components(key("rin_cut.jpg"), 3, core_px=22)
    p2 = components(key("rin_p2.jpg"), 3, core_px=18)
    for c in cut + p2:   # glow trails pick up green from the key: full despill on the new frames
        c[..., 1] = np.minimum(c[..., 1], np.maximum(c[..., 0], c[..., 2]))
        r_, g_, b_ = c[..., 0], c[..., 1], c[..., 2]
        cool = b_ > r_ + 30                      # blue blade glow: no teal cast
        c[..., 1] = np.where(cool, np.minimum(g_, b_ * 0.85), c[..., 1])
        warm = (r_ > b_ + 30) & (c[..., 1] > b_ + 15)   # crimson glow: no yellow-green fringe
        c[..., 1] = np.where(warm, b_ + (c[..., 1] - b_) * 0.3, c[..., 1])
    sc = 150 * SS / rin[0].shape[0]
    # 0 idle, 1 walk | 2 heavy windup, 3 impact, 4 follow-through | 5 iai stance, 6 dash draw-cut, 7 rising crescent
    strip2(rin[:2] + cut + p2, [sc] * 2 + [sc * RIN_CUT_REL] * 3 + [sc * RIN_P2_REL] * 3, "boss_rin.png")

def kitsune():
    kit = components(key("enemy_kitsune.jpg"), 4)
    new = components(key("kitsune_throw.jpg"), 3, core_px=10)
    sc = KIT_H * SS / kit[0].shape[0]
    # 0 idle, 1 idle2, 2 raise, 3 point | 4 windup (cocked), 5 release, 6 follow-through
    strip2(kit + new, [sc] * 4 + [sc * KIT_REL] * 3, "enemy_kitsune.png")

ONI_H = 104.0   # enemy display heights scaled up with the larger hero (collision unchanged)
KIT_H = 94.0
ONI_REL = float(os.environ.get("ONI_REL", "1.2"))
RIN_REL = float(os.environ.get("RIN_REL", "1.05"))
RIN_CUT_REL = float(os.environ.get("RIN_CUT_REL", "1.0"))
RIN_P2_REL = float(os.environ.get("RIN_P2_REL", "1.12"))
KIT_REL = float(os.environ.get("KIT_REL", "0.96"))
HEAD_PX = 40.0
w = set(os.environ.get("ONLY", "hero oni kitsune rin").split())
if "hero" in w: hero()
if "oni" in w: oni()
if "rin" in w: rin()
if "kitsune" in w: kitsune()
