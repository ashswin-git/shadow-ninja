#!/usr/bin/env python3
"""Phase 5 (APK budget): switch large painted textures to lossy WebP (compress/mode=1).
Keeps lossless: tiles (pixel-exact edges), files < 16 KB, and anything listed in KEEP."""
import glob, os, re
Q = 0.7  # rich art pass: sprites/UI reverted to lossless; only assets/na2 legacy plates stay lossy
KEEP = ("assets/tiles/",)
changed = 0
for imp in glob.glob("assets/**/*.import", recursive=True) + glob.glob("content/**/*.import", recursive=True):
	src = imp[:-7]
	txt = open(imp).read()
	if 'importer="texture"' not in txt or src.startswith(KEEP) or not os.path.exists(src) or os.path.getsize(src) < 16384: continue
	new = re.sub(r"compress/mode=\d", "compress/mode=1", txt)
	new = re.sub(r"compress/lossy_quality=[0-9.]+", "compress/lossy_quality=%s" % Q, new)
	if new != txt: open(imp, "w").write(new); changed += 1
print("lossy:", changed, "textures")
