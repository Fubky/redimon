class_name Dungeon
extends RefCounted

const WIDTH = 26
const HEIGHT = 16
const TILE = 40
const DIRS = [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]
const BIOMES = [
	{"name":"苔光森林","tag":"FOREST","desc":"树影之间，新的羁绊正在萌芽。","floor":"b8c697","wall":"69816b","accent":"e7bf73","kind":"forest"},
	{"name":"风眠山地","tag":"HIGHLANDS","desc":"沿着石阶，听山风讲述远方。","floor":"c9c3a7","wall":"858d89","accent":"e5bd81","kind":"mountain"},
	{"name":"潮汐海岛","tag":"ISLAND","desc":"越过浅滩，寻找潮水留下的礼物。","floor":"e7d7ac","wall":"78aeb2","accent":"e79975","kind":"island"},
	{"name":"余烬火山","tag":"VOLCANO","desc":"灰烬之下，仍有温暖的生命。","floor":"b89a88","wall":"675e66","accent":"ec9467","kind":"volcano"},
	{"name":"月晶洞窟","tag":"CAVERN","desc":"萤光照亮石壁，也照亮回家的路。","floor":"aca8bc","wall":"686b88","accent":"a9d3c8","kind":"cave"}
]
var cells: Dictionary = {}
var rooms: Array[Rect2i] = []
var start = Vector2i(3,8)
var stairs = Vector2i(23,8)
var loot: Array[Vector2i] = []
var biome: int = 0
var seed_value: int = 0
var explored: Dictionary = {}

func generate(seed_number: int, style: int) -> void:
	seed_value = seed_number
	biome = style
	cells.clear()
	rooms.clear()
	loot.clear()
	explored.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_number
	# Six jittered rooms in disjoint sectors guarantee space and a connected backbone.
	for row in range(2):
		for col in range(3):
			var room = Rect2i(1 + col * 8 + rng.randi_range(0,1),1 + row * 7 + rng.randi_range(0,1),rng.randi_range(5,7),rng.randi_range(4,6))
			rooms.append(room)
			for x in range(room.position.x,room.end.x):
				for y in range(room.position.y,room.end.y): cells[Vector2i(x,y)] = true
	var order = [0,1,2,5,4,3]
	for i in range(1,order.size()):
		carve(rooms[order[i-1]].get_center(),rooms[order[i]].get_center(),rng.randf() < 0.5)
	carve(rooms[1].get_center(), rooms[4].get_center(),true)
	start = rooms[0].get_center()
	stairs = rooms[5].get_center()
	for i in [1,3,4]: loot.append(rooms[i].position + Vector2i(1,1))

func carve(a: Vector2i, b: Vector2i, horizontal_first: bool) -> void:
	var p = a
	while p != b:
		cells[p] = true
		if horizontal_first and p.x != b.x: p.x += signi(b.x - p.x)
		elif p.y != b.y: p.y += signi(b.y - p.y)
		else: p.x += signi(b.x - p.x)
	cells[b] = true

func room_at(cell: Vector2i) -> int:
	for i in range(rooms.size()):
		if rooms[i].has_point(cell): return i
	return -1

func walkable(p: Vector2i) -> bool: return cells.has(p)

func path(a: Vector2i, b: Vector2i, blocked: Array = []) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not walkable(b) or b in blocked: return result
	var queue: Array[Vector2i] = [a]
	var came = {a:a}
	var index = 0
	while index < queue.size():
		var p = queue[index]
		index += 1
		if p == b: break
		for d in DIRS:
			var n = p + d
			if walkable(n) and not came.has(n) and not n in blocked:
				came[n] = p
				queue.append(n)
	if not came.has(b): return result
	var current = b
	while current != a:
		result.push_front(current)
		current = came[current]
	return result

func reachable(a: Vector2i, budget: int, blocked: Array = []) -> Dictionary:
	var costs = {a:0}
	var queue: Array[Vector2i] = [a]
	var i = 0
	while i < queue.size():
		var p = queue[i]
		i += 1
		if costs[p] >= budget: continue
		for d in DIRS:
			var n = p + d
			if walkable(n) and not costs.has(n) and not n in blocked:
				costs[n] = costs[p] + 1
				queue.append(n)
	return costs

func sight(a: Vector2i, b: Vector2i) -> bool:
	var delta = b - a
	var steps = maxi(absi(delta.x),absi(delta.y))
	for i in range(1,steps):
		var p = Vector2(a).lerp(Vector2(b),float(i)/steps)
		if not walkable(Vector2i(roundi(p.x),roundi(p.y))): return false
	return true

func serialize() -> Dictionary:
	var tiles = []
	var drops = []
	var seen = []
	for p in cells: tiles.append([p.x,p.y])
	for p in loot: drops.append([p.x,p.y])
	for p in explored: seen.append([p.x,p.y])
	return {"seed":seed_value,"biome":biome,"cells":tiles,"loot":drops,"explored":seen,"rooms":rooms.map(func(r): return [r.position.x,r.position.y,r.size.x,r.size.y]),"start":[start.x,start.y],"stairs":[stairs.x,stairs.y]}

static func deserialize(d: Dictionary) -> Dungeon:
	var world = Dungeon.new()
	world.generate(int(d.seed),int(d.biome))
	if d.has("rooms"):
		world.rooms.clear()
		for r in d.rooms: world.rooms.append(Rect2i(int(r[0]),int(r[1]),int(r[2]),int(r[3])))
	world.cells.clear()
	for p in d.cells: world.cells[Vector2i(int(p[0]),int(p[1]))] = true
	world.loot.clear()
	for p in d.loot: world.loot.append(Vector2i(int(p[0]),int(p[1])))
	for p in d.get("explored",[]): world.explored[Vector2i(int(p[0]),int(p[1]))]=true
	world.start = Vector2i(int(d.start[0]),int(d.start[1]))
	world.stairs = Vector2i(int(d.stairs[0]),int(d.stairs[1]))
	return world
