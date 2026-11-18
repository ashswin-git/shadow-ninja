#!/usr/bin/env python3
"""Phase 3 hand-built stages: authored 36x14 chunks (teach / test / twist / set piece)
assembled per stage, emitted to scripts/levels/stage_data.gd. Run after editing.
Legend: # solid  R roof  = one-way plank  F fake wall (secret)  c crumble  . empty
C coin  K checkpoint  P start  E exit portal  ^ spike  T timed spike  Z saw (horiz)  V saw (vert)
m moving platform (horiz, 3 wide)  n lift (vert, 3 wide)  J spring  L rope anchor  l lantern
s switch  G gate (opens for good)  g gate (re-closes after 7 s)  x / y stage enemy slots (roster)
Zones per chunk: ("dark", x0, x1) ("wind", x0, x1, dir) ("water", x0, x1, rows)."""
import os, json
W, H = 36, 14
HT = 34          # tall chunks (vertical / backtracking sections) use 20 extra rows above y = 0
GROUND = ["#" * W] * 2
def ch(rows, zones=(), route=()):
	rows = [r.ljust(W, ".") for r in rows]
	rows = ["." * W] * ((H if len(rows) <= H else HT) - len(rows)) + rows
	assert all(len(r) == W for r in rows), [len(r) for r in rows]
	return {"rows": rows, "zones": list(zones), "route": [list(p) for p in route]}

def tall(cells, route=(), zones=()):
	"""cells: list of (row, col, text) stamped into an empty 34-row chunk with ground."""
	g = [list("." * W) for _ in range(HT - 2)] + [list("#" * W) for _ in range(2)]
	for r, c, t in cells:
		for i, chx in enumerate(t): g[r][c + i] = chx
	return ch(["".join(r) for r in g], zones, route)
C = {}
C["start"] = ch(["....................C.C.C",
                 "..................=======",
                 "..P.........................x",
                 *GROUND])
C["rooftop"] = ch([".........C.C..............C.C",
                   "........RRRRRR...........RRRRRR",
                   "........RRRRRR...........RRRRRR",
                   "...........................y",
                   "...x..........................==",
                   "######RRRRRRRRRR...RRRRRRRRRRRRRRRRR",
                   "######RRRRRRRRRR...RRRRRRRRRRRRRRRRR"])
C["spring_teach"] = ch(["..........................C",
                        "...................######",
                        "...................######",
                        "...................######",
                        "...................######",
                        "...................######",
                        "...................######",
                        "...................######",
                        "..............J....######.......x",
                        *GROUND])
C["spring_test"] = ch(["...........C...........C",
                       "",
                       "", "", "", "", "",
                       ".......J..........J.........C",
                       "#########.....#######......#########",
                       "#########.....#######......#########"])
C["moving_teach"] = ch(["...........mmm",
                        "",
                        "##########..............############",
                        "##########..............############"])
C["moving_test"] = ch(["......................C",
                       "...................=======",
                       "", "", "", "", "",
                       "............nnn",
                       "",
                       "........................^^",
                       "##########...........#######.....###",
                       "##########...........#######.....###"])
C["crumble_teach"] = ch(["...........C...C...C",
                         "",
                         "#########cccccccccccc.......########",
                         "#########...................########"])
C["crumble_test"] = ch(["............................C",
                        ".........................cccc",
                        "",
                        "....................cccc",
                        "",
                        "...............cccc",
                        "",
                        "..........cccc",
                        "#########...................########",
                        "#########...................########"])
C["wind_teach"] = ch(["...........#........#.......C",
                      "...........#...C....#",
                      *GROUND], [("wind", 4, 32, -1)])
C["wind_test"] = ch(["...........C.........C",
                     "..........===.......===",
                     "",
                     "",
                     "######.........###.........#########",
                     "######.........###.........#########"], [("wind", 3, 30, 1)])
C["dark_teach"] = ch(["####################################",
                      "####################################",
                      "", "", "", "",
                      "..............^^.........C",
                      "........l..........l..........l",
                      *GROUND], [("dark", 1, 35)])
C["dark_test"] = ch(["####################################",
                     "####################################",
                     "", "",
                     "...........====.........====",
                     "",
                     "...l.......................y....l",
                     "########.......#######.......#######",
                     "########.......#######.......#######"], [("dark", 1, 35)])
C["water_teach"] = ch([".........................K.C",
                       "......................=========",
                       "",
                       "...............=====",
                       "",
                       "........=====",
                       "",
                       "...=====",
                       "", "",
                       *GROUND], [("water", 2, 31, 10)])
C["water_test"] = ch(["............................C",
                      "..........................=====",
                      "", "", "",
                      ".................nnn",
                      "",
                      "..........cccc",
                      "",
                      "....=====",
                      "",
                      "",
                      *GROUND], [("water", 2, 31, 10)])
C["spikes_teach"] = ch(["...........C.........C",
                        "........TTT......TTTT.......TTT",
                        *GROUND])
C["saw_teach"] = ch(["..............C",
                     "",
                     "..........Z.............Z",
                     *GROUND])
C["saw_spike_test"] = ch([".............C...........C",
                          "...........=====.......=====",
                          "...................V",
                          "",
                          "....TTT.....................TTT",
                          "######.....######.....##############",
                          "######.....######.....##############"])
C["rope_teach"] = ch(["..............L",
                      "", "", "", "", "", "",
                      "",
                      "..........................C",
                      "#########..............#############",
                      "#########..............#############"])
C["rope_test"] = ch([".........L..........L.........C",
                     "", "", "", "", "", "", "", "",
                     "######......................########",
                     "######......................########"])
C["switch_teach"] = ch(["......................#",
                        "......................#",
                        "......................#",
                        "........s.............G",
                        ".......====...........G",
                        "......................G",
                        "......................G",
                        "......................G.......C",
                        *GROUND])
C["switch_test"] = ch(["...........s",
                       "..........====..........#",
                       "........................#",
                       "........................#",
                       "........................g",
                       "........................g",
                       "........................g",
                       "........................g.....C",
                       "......J.................g",
                       *GROUND])
C["arena"] = ch(["..........=====.......=====",
                 "",
                 ".......x.........y.........x.....K",
                 *GROUND])
C["secret"] = ch(["...........##########",
                  "...........##########",
                  "...........##########",
                  "...........#FF.C.C.C#",
                  "...........#FF......#",
                  "...........FF.......#.....x",
                  *GROUND])
C["end"] = ch(["..........C.C.C",
               ".........................y.....E",
               *GROUND])
# ---- Stage-length pass: vertical / backtracking set pieces (34 rows, ground at rows 32-33) ----
# tower: the ground route is walled at col 33; climb the zig-zag planks to the roof and run off right.
_tw = [(29, 10, "====="), (26, 3, "====="), (23, 10, "====="), (20, 3, "====="), (17, 10, "====="),
       (14, 3, "====="), (11, 10, "====="), (8, 16, "#" * 20), (9, 16, "#" * 20),
       (25, 5, "C"), (19, 5, "C"), (13, 5, "C"), (7, 20, "C.C.C"), (7, 30, "y"), (31, 20, "x"), (31, 2, "K")]
_tw += [(r, 33, "#") for r in range(10, 32)]
C["tower"] = tall(_tw, route=[(12, 28), (5, 25), (12, 22), (5, 19), (12, 16), (5, 13), (12, 10), (18, 7), (35, 7)])
# backtrack: the gate ahead (col 30) is opened by a switch up and to the LEFT, back over the route.
_bt = [(29, 24, "====="), (26, 18, "====="), (23, 12, "====="), (20, 6, "====="), (17, 0, "#######"),
       (16, 3, "s"), (16, 5, "C"), (25, 20, "C"), (22, 14, "C"), (19, 8, "C"), (31, 14, "x"), (25, 19, "y"), (31, 2, "K")]
_bt += [(r, 30, "#") for r in range(0, 22)] + [(r, 30, "G") for r in range(22, 32)]
C["backtrack"] = tall(_bt, route=[(26, 31), (26, 28), (20, 25), (14, 22), (8, 19), (3, 16), (8, 31), (35, 31)])
# sky run: high plank route with coins over a lower route with enemies and spikes.
_sk = [(31, 8, "^^^"), (31, 22, "^^^"), (31, 15, "x"), (31, 29, "y"), (28, 2, "====="), (25, 8, "======"),
       (22, 15, "======"), (22, 24, "======"), (25, 31, "====="), (21, 17, "C.C.C"), (21, 26, "C.C")]
C["sky_run"] = tall(_sk)
# climb shaft: springs and planks up to a high ledge, drop down the far side.
_cs = [(31, 2, "J"), (31, 0, "K"), (24, 8, "#######"), (25, 8, "#######"), (23, 10, "C"), (18, 20, "########"),
       (19, 20, "########"), (17, 23, "C.C"), (17, 27, "y"), (31, 30, "x")] + [(r, 16, "#") for r in range(26, 32)]
C["spring_shaft"] = tall(_cs)
for _n, _c in C.items():   # every teaching chunk opens with a checkpoint on its first ledge
	if _n.endswith("_teach") and not any("K" in r for r in _c["rows"]):
		r = list(_c["rows"][-3]); r[2] = "K"; _c["rows"][-3] = "".join(r)
for _n, _c in C.items():   # pad every chunk to the full stage height
	_c["rows"] = ["." * W] * (HT - len(_c["rows"])) + _c["rows"]
STAGES = {  # level -> scenario, base parallax theme, weather, night, roster x/y, chunks (19 each)
	3: ("gion", "snow", "snow", True, ["oni", "crow_scout"],
	    ["start", "rooftop", "moving_teach", "rooftop", "moving_test", "tower", "spring_teach", "arena", "secret",
	     "spring_shaft", "rooftop", "backtrack", "spring_test", "sky_run", "moving_test", "rooftop", "arena", "spring_test", "end"]),
	5: ("bamboo", "forest", "petals", False, ["oni_brute", "kitsune_archer"],
	    ["start", "crumble_teach", "arena", "crumble_test", "tower", "wind_teach", "secret", "wind_test", "arena",
	     "sky_run", "crumble_test", "backtrack", "spring_test", "wind_test", "spring_shaft", "crumble_test", "arena", "wind_test", "end"]),
	6: ("cave", "forest", "rain", True, ["oni", "bomb_monk"],
	    ["start", "dark_teach", "arena", "water_teach", "dark_test", "tower", "secret", "water_test", "moving_teach",
	     "backtrack", "arena", "water_teach", "sky_run", "dark_test", "spring_shaft", "water_test", "arena", "dark_test", "end"]),
	7: ("shrine", "boss", "embers", True, ["shadow_assassin", "kitsune_archer"],
	    ["start", "spikes_teach", "arena", "saw_teach", "tower", "secret", "saw_spike_test", "arena", "spikes_teach",
	     "backtrack", "moving_test", "saw_spike_test", "sky_run", "spring_shaft", "saw_spike_test", "moving_test", "arena", "saw_spike_test", "end"]),
	9: ("canal", "forest", "rain", True, ["oni_brute", "bomb_monk"],
	    ["start", "moving_teach", "rope_teach", "arena", "rope_test", "tower", "secret", "moving_teach", "rope_test",
	     "backtrack", "arena", "moving_test", "sky_run", "rope_test", "spring_shaft", "moving_test", "arena", "rope_test", "end"]),
	10: ("pagoda", "snow", "snow", False, ["shadow_assassin", "crow_scout"],
	     ["start", "switch_teach", "arena", "crumble_teach", "tower", "wind_teach", "switch_test", "secret", "wind_test",
	      "backtrack", "arena", "crumble_test", "sky_run", "switch_test", "spring_shaft", "wind_test", "arena", "crumble_test", "end"]),
	11: ("palace", "boss", "petals", True, ["oni_brute", "shadow_assassin"],
	     ["start", "dark_teach", "switch_teach", "arena", "tower", "saw_spike_test", "rope_test", "secret", "water_test",
	      "backtrack", "dark_test", "spikes_teach", "sky_run", "switch_test", "spring_shaft", "saw_spike_test", "arena", "water_test", "end"]),
}
out = ["## GENERATED by tools/stage_src.py (Phase 3 hand-built stages). Edit the source, re-run.",
       "class_name StageData", "const CHUNK_W := %d" % W, "const CHUNK_H := %d" % HT,
       "const CHUNKS := " + json.dumps(C, indent=None).replace("]], ", "]],\n\t"),
       "const STAGES := {"]
for k, v in STAGES.items():
	out.append('\t%d: {"scenario": "%s", "theme": "%s", "weather": "%s", "night": %s, "roster": %s, "chunks": %s},'
	           % (k, v[0], v[1], v[2], "true" if v[3] else "false", json.dumps(v[4]), json.dumps(v[5])))
out.append("}")
os.makedirs("scripts/levels", exist_ok=True)
open("scripts/levels/stage_data.gd", "w").write("\n".join(out) + "\n")
for k, v in STAGES.items():
	rows = ["".join(C[c]["rows"][r] for c in v[5]) for r in range(HT)]
	coins = sum(r.count("C") for r in rows); en = sum(r.count("x") + r.count("y") for r in rows)
	print("L%d %s: %d cols (%.0f px), coins %d, enemies %d, checkpoints %d" % (k, v[0], len(rows[0]), len(rows[0]) * 32, coins, en, sum(r.count("K") for r in rows)))
