class_name StageBuilder
## Phase 3: builds a hand-built stage (StageData) into the Level scene: TileMapLayer terrain
## (solid / one-way planks / roofs), a front layer for secret fake walls, mechanics, enemies,
## coins, checkpoints, exit, weather and day/night ambience.
const T := 32
const BASE_ROW := 8             # tile row of a classic 14-row chunk's top (ground top stays at y = 640)
const ROWS_ABOVE := BASE_ROW - (34 - 14)   # = -12: tall chunks reach 20 rows higher (world top y = -384)
const SCEN_ROW := {"gion": 0, "bamboo": 1, "cave": 2, "shrine": 3, "canal": 4, "pagoda": 5, "palace": 6}
const AMBIENT := {"gion": Color(0.66, 0.72, 0.95), "cave": Color(0.62, 0.7, 0.85), "shrine": Color(0.95, 0.75, 0.7),
	"canal": Color(0.62, 0.72, 0.9), "palace": Color(0.6, 0.58, 0.85)}
const SKY_TINT := {"gion": Color(0.55, 0.62, 0.95), "bamboo": Color(1.0, 1.0, 0.95), "cave": Color(0.45, 0.55, 0.7),
	"shrine": Color(1.1, 0.75, 0.6), "canal": Color(0.55, 0.65, 0.85), "pagoda": Color(0.95, 1.0, 1.1), "palace": Color(0.55, 0.5, 0.85)}

static func has_stage(n: int) -> bool: return StageData.STAGES.has(n)

static func theme_for(n: int) -> String: return StageData.STAGES[n]["theme"]

static func build(lvl: Node, n: int) -> Dictionary:
	var st: Dictionary = StageData.STAGES[n]
	var scen: String = st["scenario"]
	var srow: int = SCEN_ROW[scen]
	var tex: Texture2D = load("res://assets/tiles/stage_tiles.png")
	var names: Array = st["chunks"]
	var rows: Array = []
	for r in range(StageData.CHUNK_H):
		var line := ""
		for c in names: line += StageData.CHUNKS[c]["rows"][r]
		rows.append(line)
	var w: int = rows[0].length()
	# ---- tileset ----
	var ts := TileSet.new(); ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer(); ts.set_physics_layer_collision_layer(0, 1); ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new(); src.texture = tex; src.texture_region_size = Vector2i(T, T)
	var h := T / 2.0
	for col in range(8):
		var ac := Vector2i(col, srow)
		src.create_tile(ac)
	ts.add_source(src, 0)
	for col in range(8):
		var td := src.get_tile_data(Vector2i(col, srow), 0)
		td.add_collision_polygon(0)
		if col == 4:   # one-way plank: thin top
			td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, -h + 10), Vector2(-h, -h + 10)]))
			td.set_collision_polygon_one_way(0, 0, true)
		else:
			td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)]))
	var tm := TileMapLayer.new(); tm.name = "Terrain"; tm.tile_set = ts; tm.add_to_group("World")
	var front := TileMapLayer.new(); front.name = "SecretFront"; front.z_index = 20
	var fts := TileSet.new(); fts.tile_size = Vector2i(T, T)
	var fsrc := TileSetAtlasSource.new(); fsrc.texture = tex; fsrc.texture_region_size = Vector2i(T, T)
	fsrc.create_tile(Vector2i(2, srow)); fts.add_source(fsrc, 0); front.tile_set = fts
	lvl.get_node("World").add_child(tm); lvl.get_node("World").add_child(front)
	# invisible world bounds so nobody can run (or be knocked) off either end of the stage
	for bx in [-16.0, w * T + 16.0]:
		var wb := StaticBody2D.new(); wb.add_to_group("World")
		var wcs := CollisionShape2D.new(); var wr := RectangleShape2D.new(); wr.size = Vector2(32, 2000)
		wcs.shape = wr; wb.add_child(wcs); wb.position = Vector2(bx, 0); lvl.get_node("World").add_child(wb)
	var info := {"width": w * T, "coins": 0, "enemies": 0, "mechanics": {}, "scenario": scen, "chunks": names.size()}
	var region := func(col: int) -> Rect2: return Rect2(col * T, srow * T, T, T)
	var roster: Array = st["roster"]
	var gates_by_chunk := {}
	var switches_by_chunk := {}
	var secret_cells: Array = []
	for r in range(rows.size()):
		var gy := r + ROWS_ABOVE
		for x in range(w):
			var g: String = rows[r][x]
			var cell := Vector2i(x, gy)
			var centre := Vector2(x * T + h, gy * T + h)
			var top := gy * T
			var above: String = rows[r - 1][x] if r > 0 else "."
			var chunk := x / StageData.CHUNK_W
			match g:
				"#": tm.set_cell(cell, 0, Vector2i(x % 2 if above != "#" else 2 + (x * 7 + r) % 2, srow))
				"R": tm.set_cell(cell, 0, Vector2i(5 if above != "R" else 6, srow))
				"=": tm.set_cell(cell, 0, Vector2i(4, srow))
				"F": front.set_cell(cell, 0, Vector2i(2, srow)); secret_cells.append(centre)
				"C": lvl.add_coin(centre); info["coins"] += 1
				"K": lvl.add_checkpoint(Vector2(centre.x, top + T - 32))
				"P": lvl.player.global_position = Vector2(centre.x, top + T - 28); lvl.player.reset_physics_interpolation()
				"E": lvl.add_portal(Vector2(centre.x, top + T - 30))
				"^":
					var tr = load("res://scenes/Trap.tscn").instantiate(); tr.global_position = Vector2(centre.x, top + T - 16)
					lvl.get_node("Traps").add_child(tr)
				"T":
					var sp := Mechanics.TimedSpike.new(); sp.fire = scen in ["shrine", "palace"]
					sp.phase = float(chunk % 2) * 1.3; sp.position = Vector2(centre.x, top + T - 16)
					lvl.get_node("World").add_child(sp); _count(info, "timed_spikes")
				"Z", "V":
					var sw := Mechanics.Saw.new(); sw.position = centre
					sw.travel = Vector2(T * 3, 0) if g == "Z" else Vector2(0, T * 2)
					lvl.get_node("World").add_child(sw); _count(info, "saws")
				"m", "n":
					if x > 0 and rows[r][x - 1] == g: continue
					var mp := Mechanics.MovingPlatform.new(); mp.tex = tex; mp.region = region.call(4)
					mp.width = 3; mp.position = Vector2(centre.x + T, centre.y)
					mp.travel = Vector2(T * 8, 0) if g == "m" else Vector2(0, -T * 6)
					lvl.get_node("World").add_child(mp); _count(info, "moving_platforms")
				"c":
					var cr := Mechanics.Crumble.new(); cr.tex = tex; cr.region = region.call(0); cr.position = centre
					lvl.get_node("World").add_child(cr); _count(info, "crumble_tiles")
				"J":
					var spg := Mechanics.Spring.new(); spg.position = Vector2(centre.x, top + T - 16)
					lvl.get_node("World").add_child(spg); _count(info, "springs")
				"L":
					var rp := Mechanics.Rope.new(); rp.position = centre
					lvl.get_node("World").add_child(rp); _count(info, "ropes")
				"l":
					var ln := Mechanics.Lantern.new(); ln.position = Vector2(centre.x, top + T)
					lvl.get_node("World").add_child(ln); _count(info, "lanterns")
				"s":
					var s := Mechanics.Switch.new(); s.position = centre
					lvl.get_node("World").add_child(s); switches_by_chunk[chunk] = switches_by_chunk.get(chunk, []) + [s]
				"G", "g":
					if r > 0 and rows[r - 1][x] == g: continue
					var n2 := 0
					while r + n2 < rows.size() and rows[r + n2][x] == g: n2 += 1
					var gt := Mechanics.Gate.new(); gt.cells = n2; gt.reclose = g == "g"; gt.tex = tex; gt.region = region.call(7)
					gt.position = centre; lvl.get_node("World").add_child(gt)
					gates_by_chunk[chunk] = gates_by_chunk.get(chunk, []) + [gt]; _count(info, "gates")
				"x", "y":
					var k: String = roster[0 if g == "x" else 1]
					var e = EnemyFactory.make(k)
					e.global_position = Vector2(centre.x, top + T - 28 - (128 if k == "crow_scout" else 0))
					lvl.get_node("Enemies").add_child(e); info["enemies"] += 1
	for c in switches_by_chunk:
		for s in switches_by_chunk[c]: s.gates = gates_by_chunk.get(c, [])
	# zones
	for i in range(names.size()):
		for z in StageData.CHUNKS[names[i]]["zones"]:
			var x0: float = (i * StageData.CHUNK_W + z[1]) * T
			var x1: float = (i * StageData.CHUNK_W + z[2]) * T
			var top_y := ROWS_ABOVE * T
			var hgt := StageData.CHUNK_H * T
			match z[0]:
				"wind":
					var wd := Mechanics.Wind.new(); wd.dir = z[3]; wd.size = Vector2(x1 - x0, hgt)
					wd.position = Vector2((x0 + x1) / 2.0, top_y + hgt / 2.0); lvl.get_node("World").add_child(wd); _count(info, "wind_zones")
				"dark":
					var dz := Mechanics.DarkZone.new(); dz.size = Vector2(x1 - x0, hgt)
					dz.position = Vector2((x0 + x1) / 2.0, top_y + hgt / 2.0); lvl.get_node("World").add_child(dz); _count(info, "dark_rooms")
				"water":
					var wa := Mechanics.Water.new(); wa.x0 = x0; wa.x1 = x1
					wa.bottom = (ROWS_ABOVE + StageData.CHUNK_H - 2) * T; wa.top = wa.bottom - z[3] * T
					lvl.get_node("World").add_child(wa); _count(info, "rising_water")
	if not secret_cells.is_empty(): _secret_reveal(lvl, front, secret_cells)
	info["mechanics"]["switches"] = switches_by_chunk.size()
	return info

static func _count(info: Dictionary, k: String) -> void:
	info["mechanics"][k] = info["mechanics"].get(k, 0) + 1

static func _secret_reveal(lvl: Node, front: TileMapLayer, cells: Array) -> void:
	## fake-wall tiles fade when the hero walks into them (secret alcoves)
	for p in cells:
		var a := Area2D.new(); a.collision_layer = 0; a.collision_mask = 2; a.position = p
		var cs := CollisionShape2D.new(); var sh := RectangleShape2D.new(); sh.size = Vector2(T, T); cs.shape = sh; a.add_child(cs)
		lvl.get_node("World").add_child(a)
		a.body_entered.connect(func(b):
			if b.name == "Player" and front.modulate.a > 0.5:
				front.create_tween().tween_property(front, "modulate:a", 0.25, 0.3)
				FX.toast(lvl, "SECRET FOUND", Color(1, 0.85, 0.4)))
