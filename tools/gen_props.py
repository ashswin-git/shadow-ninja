"""Polish pass: painted Kyoto props (gold mon coin, iron spike row, stone toro checkpoint lantern)
from the original painted plate art_src/props_kyoto.jpg. Textures are stored at 2x display size;
the scenes draw them at scale 0.5 so collision shapes stay exactly as before."""
import sys, os
sys.argv = [sys.argv[0], "__none__"]
sys.path.insert(0, os.path.dirname(__file__))
from gen_ingame import *

coin, spike, lantern = components(key("props_kyoto.jpg"), 3, core_px=6)

def fit(c, w=None, h=None):
    im = to_img(c)
    sc = (w / im.width) if w else (h / im.height)
    return im.resize((max(1, round(im.width * sc)), max(1, round(im.height * sc))), Image.LANCZOS).filter(ImageFilter.UnsharpMask(1.0, 60, 2))

# coin: 64x64 (32 display)
im = fit(coin, w=60); out = Image.new("RGBA", (64, 64)); out.alpha_composite(im, ((64 - im.width) // 2, (64 - im.height) // 2))
out.save(os.path.join(SPR, "coin.png"), optimize=True)
# spikes: keep the iron spikes and the top plank only (a low trap), 72 px wide (36 display)
h = spike.shape[0]; top = spike[: int(h * 0.72)]
rows = np.where(top[..., 3].max(1) > 10)[0]; top = top[rows.min():rows.max() + 1]
im = fit(top, w=72); im = im.resize((72, round(im.height * 1.25)), Image.LANCZOS); H = im.height   # spikes a bit taller so the hazard reads
out = Image.new("RGBA", (72, H)); out.alpha_composite(im, (0, 0)); out.save(os.path.join(SPR, "spike.png"), optimize=True)
# lantern: 136 px tall (68 display)
im = fit(lantern, h=136); out = Image.new("RGBA", (im.width + 2, 136)); out.alpha_composite(im, (1, 0))
out.save(os.path.join(SPR, "checkpoint.png"), optimize=True)
print("coin 64x64, spike", (72, H), "checkpoint", out.size)
